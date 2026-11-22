import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:orion_ui/src/components/button/orion_button_presets.dart';
import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/components/button/orion_button_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Tactile, physics-driven button with async in-flight locking.
///
/// The button compresses through [OrionPressable] and owns everything the
/// headless primitive intentionally does not: async in-flight locking,
/// opt-in debounce, loading and disabled states, and keyboard activation.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in preset for the [variant] and [size], the ambient
/// [OrionButtonTheme], and the [style] passed here. Anything an override does
/// not name falls through, so a call site can tune one value - including the
/// press physics - without restating the rest.
///
/// When [onPressed] returns a [Future], the button enters a loading state for
/// the lifetime of that future and ignores further presses. [isLoading] forces
/// that same state from outside. Synchronous actions never show the loading
/// state on their own.
class OrionButton extends StatefulWidget {
  const OrionButton({
    super.key,
    this.label,
    this.child,
    this.onPressed,
    this.onLongPress,
    this.variant = OrionButtonVariant.solid,
    this.size = OrionButtonSize.medium,
    this.style,
    this.leading,
    this.trailing,
    this.loadingIndicator,
    this.loadingLabel,
    this.loadingChild,
    this.debounce = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.focusNode,
    this.autofocus = false,
    this.cursor,
    this.onHover,
    this.semanticLabel,
  }) : assert(
         (label != null) != (child != null),
         'Provide either label or child, not both.',
       ),
       assert(
         loadingLabel == null || loadingChild == null,
         'Provide either loadingLabel or loadingChild, not both.',
       );

  /// Plain text label rendered with single-line ellipsis defaults.
  ///
  /// Mutually exclusive with [child]; use [child] when you need custom layout.
  final String? label;

  /// Custom label content; inherits the size's text style and state color.
  ///
  /// Mutually exclusive with [label].
  final Widget? child;

  /// Action to run on press. Returning a [Future] locks the button until it
  /// completes; null disables the button.
  final FutureOr<void> Function()? onPressed;

  /// Called when the button is held. Recognition also fires the impact haptic.
  final VoidCallback? onLongPress;

  /// Visual treatment; picks the preset the other layers build on.
  final OrionButtonVariant variant;

  /// Control height and text style; picks the preset the other layers build on.
  final OrionButtonSize size;

  /// Instance-level overrides, merged over the preset and the ambient
  /// [OrionButtonTheme]. Only the fields set here change.
  final OrionButtonStyle? style;

  /// Optional leading slot; replaced by the loading indicator while pending.
  final Widget? leading;

  /// Optional trailing slot.
  final Widget? trailing;

  /// Replaces the default spinner while loading.
  final Widget? loadingIndicator;

  /// Plain text label shown while loading; mutually exclusive with [loadingChild].
  final String? loadingLabel;

  /// Replaces [child] or [label] while loading; the leading slot is still the indicator.
  final Widget? loadingChild;

  /// When true, ignores presses that arrive within the double-tap window of
  /// the previous accepted press.
  final bool debounce;

  /// Forces the loading spinner and ignores presses.
  ///
  /// Use this when a parent owns the pending state. A [Future] returned from
  /// [onPressed] still locks the button without this flag.
  final bool isLoading;

  /// Stretches the painted button to the parent's width.
  ///
  /// Ignored when the parent width is unbounded, such as a [Row] that does not
  /// wrap this button in [Expanded].
  final bool isExpanded;

  /// Optional focus node for the button.
  final FocusNode? focusNode;

  /// Whether the button requests focus on first build.
  final bool autofocus;

  /// Mouse cursor override; otherwise a click cursor while enabled.
  final MouseCursor? cursor;

  /// Called with the hover highlight state on pointer enter and exit.
  final ValueChanged<bool>? onHover;

  /// Optional semantics label overriding the child's text.
  final String? semanticLabel;

  @override
  State<OrionButton> createState() => _OrionButtonState();
}

class _OrionButtonState extends State<OrionButton> {
  bool _pending = false;
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;
  DateTime? _lastAcceptedPress;

  bool get _hasAction => widget.onPressed != null;

  bool get _loading => widget.isLoading || _pending;

  bool get _canPress => _hasAction && !_loading;

  void _press() {
    unawaited(_handlePress());
  }

  Future<void> _handlePress() async {
    if (!_canPress) {
      return;
    }

    final DateTime now = DateTime.now();
    final DateTime? lastPress = _lastAcceptedPress;
    if (widget.debounce &&
        lastPress != null &&
        now.difference(lastPress) < kDoubleTapTimeout) {
      return;
    }

    final FutureOr<void> result = widget.onPressed!.call();
    _lastAcceptedPress = now;
    if (result is! Future<void>) {
      return;
    }

    setState(() => _pending = true);
    try {
      await result;
    } finally {
      if (mounted) {
        setState(() => _pending = false);
      }
    }
  }

  /// Mirrors the pressable's compression lifecycle into [WidgetState.pressed].
  ///
  /// The disable path reaches here from the pressable's `didUpdateWidget`,
  /// which runs inside the build phase; marking this element dirty then would
  /// throw, so that one case lands as a post-frame callback instead.
  void _onPressedChanged(bool pressed) {
    if (!mounted || _pressed == pressed) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _onPressedChanged(pressed);
      });
      return;
    }
    setState(() => _pressed = pressed);
  }

  /// Tracks hover through a direct [MouseRegion]: the pointer's presence is a
  /// real state for styling, not a keyboard-focus highlight that the platform
  /// highlight mode should gate.
  void _setHovered(bool value) {
    if (!mounted) {
      return;
    }
    if (_hovered != value) {
      setState(() => _hovered = value);
    }
    widget.onHover?.call(value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionButtonTheme buttonTheme =
        theme.extension<OrionButtonTheme>() ?? OrionButtonTheme.fallback;

    final OrionButtonStyle style = OrionButtonPresets.resolve(
      variant: widget.variant,
      size: widget.size,
      scheme: scheme,
      textTheme: theme.textTheme,
      theme: orion,
    ).merge(buttonTheme.styleFor(widget.variant)).merge(widget.style);

    final Set<WidgetState> states = <WidgetState>{
      if (!_hasAction) WidgetState.disabled,
      if (_focused) WidgetState.focused,
      if (_hovered) WidgetState.hovered,
      if (_pressed) WidgetState.pressed,
    };

    final double pressedScale = style.pressedScale ?? orion.pressScale;
    final OrionSpringSpec pressSpring = style.pressSpring ?? orion.pressSpring;
    final OrionSpringSpec releaseSpring =
        style.releaseSpring ?? orion.releaseSpring;
    final OrionHapticType tapHaptic = style.hapticType ?? orion.selectionHaptic;
    final OrionHapticType impactHaptic =
        style.impactHapticType ?? orion.impactHaptic;

    final Widget pressable = MergeSemantics(
      child: Semantics(
        button: true,
        enabled: _canPress,
        label: widget.semanticLabel,
        child: OrionPressable(
          onTap: _canPress ? _press : null,
          onLongPress: widget.onLongPress,
          pressedScale: pressedScale,
          springSpec: pressSpring,
          releaseSpringSpec: releaseSpring,
          hapticType: tapHaptic,
          impactHapticType: impactHaptic,
          cursor: widget.cursor,
          onPressedChanged: _onPressedChanged,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              final bool expand =
                  widget.isExpanded && constraints.hasBoundedWidth;
              final Widget effectiveLabel =
                  widget.child ?? _defaultLabel(widget.label!);
              final Widget? effectiveLoadingLabel =
                  widget.loadingChild ??
                  (widget.loadingLabel == null
                      ? null
                      : _defaultLabel(widget.loadingLabel!));
              final Widget visual = _buttonFace(
                style: style,
                states: states,
                scheme: scheme,
                expand: expand,
                loading: _loading,
                label: effectiveLabel,
                loadingChild: effectiveLoadingLabel,
                loadingIndicator: widget.loadingIndicator,
                leading: widget.leading,
                trailing: widget.trailing,
              );
              return ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: math.max(
                    style.minWidth ?? 0.0,
                    OrionSizing.minHitTarget,
                  ),
                  minHeight: OrionSizing.minHitTarget,
                ),
                child: expand
                    ? visual
                    : Center(
                        widthFactor: 1.0,
                        heightFactor: 1.0,
                        child: visual,
                      ),
              );
            },
          ),
        ),
      ),
    );

    return MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: FocusableActionDetector(
        enabled: _canPress,
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (bool value) {
          if (value != _focused) {
            setState(() => _focused = value);
          }
        },
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (ActivateIntent intent) {
              _press();
              return null;
            },
          ),
        },
        child: pressable,
      ),
    );
  }
}

Widget _buttonFace({
  required OrionButtonStyle style,
  required Set<WidgetState> states,
  required ColorScheme scheme,
  required bool expand,
  required bool loading,
  required Widget label,
  required Widget? loadingChild,
  required Widget? loadingIndicator,
  required Widget? leading,
  required Widget? trailing,
}) {
  final Color? background = style.background?.resolve(states);
  final Color foreground =
      style.foreground?.resolve(states) ?? scheme.onSurface;
  final BorderSide? border = style.border?.resolve(states);
  final List<BoxShadow>? shadow = style.shadow?.resolve(states);
  final BorderRadius radius = style.borderRadius ?? BorderRadius.zero;
  final double height = style.height ?? OrionSizing.controlHeightMedium;
  final EdgeInsetsGeometry padding =
      style.padding ??
      const EdgeInsets.symmetric(horizontal: OrionSpacing.space16);
  final TextStyle textStyle = style.textStyle ?? const TextStyle();
  final double gap = style.gap ?? OrionSpacing.space8;

  return DecoratedBox(
    decoration: BoxDecoration(
      color: background,
      borderRadius: radius,
      border: border == null ? null : Border.fromBorderSide(border),
      boxShadow: shadow,
    ),
    child: SizedBox(
      height: height,
      width: expand ? double.infinity : null,
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            if (loading)
              _LeadingSlot(
                gap: gap,
                child:
                    loadingIndicator ??
                    SizedBox.square(
                      dimension: OrionSizing.iconSmall,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.0,
                        color: foreground,
                      ),
                    ),
              )
            else if (leading != null)
              _LeadingSlot(
                gap: gap,
                child: _tint(foreground, style.iconSize, leading),
              ),
            DefaultTextStyle(
              style: textStyle.copyWith(color: foreground),
              child: loading ? (loadingChild ?? label) : label,
            ),
            if (trailing != null)
              Padding(
                padding: EdgeInsets.only(left: gap),
                child: _tint(foreground, style.iconSize, trailing),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _defaultLabel(String text) {
  return Flexible(
    child: Text(
      text,
      textAlign: TextAlign.center,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );
}

Widget _tint(Color color, double? size, Widget child) {
  return IconTheme.merge(
    data: IconThemeData(color: color, size: size),
    child: child,
  );
}

class _LeadingSlot extends StatelessWidget {
  const _LeadingSlot({required this.child, required this.gap});

  final Widget child;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: gap),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: OrionSizing.iconMedium,
          minHeight: OrionSizing.iconMedium,
        ),
        child: Center(child: child),
      ),
    );
  }
}
