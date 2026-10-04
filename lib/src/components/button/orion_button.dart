import 'dart:async';

import 'package:flutter/gestures.dart' show kDoubleTapTimeout;
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Tactile, physics-driven button with async in-flight locking.
///
/// The button compresses through [OrionPressable] and owns everything the
/// headless primitive intentionally does not: async in-flight locking,
/// opt-in debounce, loading and disabled states, and keyboard activation.
///
/// When [onPressed] returns a [Future], the button enters a loading state for
/// the lifetime of that future and ignores further presses. [isLoading] forces
/// that same state from outside. Synchronous actions never show the loading
/// state on their own.
class OrionButton extends StatefulWidget {
  const OrionButton({
    super.key,
    required this.child,
    this.onPressed,
    this.variant = OrionButtonVariant.solid,
    this.size = OrionButtonSize.medium,
    this.leading,
    this.trailing,
    this.debounce = false,
    this.isLoading = false,
    this.isExpanded = false,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Label content; inherits the size's text style and state color.
  final Widget child;

  /// Action to run on press. Returning a [Future] locks the button until it
  /// completes; null disables the button.
  final FutureOr<void> Function()? onPressed;

  /// Visual treatment.
  final OrionButtonVariant variant;

  /// Control height and text style.
  final OrionButtonSize size;

  /// Optional leading slot; replaced by a progress indicator while pending.
  final Widget? leading;

  /// Optional trailing slot.
  final Widget? trailing;

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

  /// Optional semantics label overriding the child's text.
  final String? semanticLabel;

  @override
  State<OrionButton> createState() => _OrionButtonState();
}

class _OrionButtonState extends State<OrionButton> {
  bool _pending = false;
  bool _focused = false;
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionButtonStyle style = OrionButtonStyle.resolve(
      variant: widget.variant,
      size: widget.size,
      scheme: scheme,
      theme: orion,
      textTheme: theme.textTheme,
      enabled: _hasAction,
      focused: _focused,
    );

    final Widget pressable = MergeSemantics(
      child: Semantics(
        button: true,
        enabled: _canPress,
        label: widget.semanticLabel,
        child: OrionPressable(
          onTap: _canPress ? _press : null,
          pressedScale: orion.pressScale,
          springSpec: orion.pressSpring,
          releaseSpringSpec: orion.releaseSpring,
          hapticType: orion.tapHaptic,
          longPressHapticType: orion.longPressHaptic,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final bool expand =
                  widget.isExpanded && constraints.hasBoundedWidth;
              final Widget visual = _buttonFace(
                style: style,
                expand: expand,
                loading: _loading,
                label: widget.child,
                leading: widget.leading,
                trailing: widget.trailing,
              );
              return ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: OrionSizing.minHitTarget,
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

    return FocusableActionDetector(
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
    );
  }
}

Widget _buttonFace({
  required OrionButtonStyle style,
  required bool expand,
  required bool loading,
  required Widget label,
  required Widget? leading,
  required Widget? trailing,
}) {
  return DecoratedBox(
    decoration: BoxDecoration(
      color: style.background,
      borderRadius: style.radius,
      border: style.border == null
          ? null
          : Border.fromBorderSide(style.border!),
      boxShadow: style.shadow,
    ),
    child: SizedBox(
      height: style.height,
      width: expand ? double.infinity : null,
      child: Padding(
        padding: style.padding!,
        child: Row(
          mainAxisSize: expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (loading)
              _LeadingSlot(
                child: SizedBox.square(
                  dimension: OrionSizing.iconSmall,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.0,
                    color: style.foreground,
                  ),
                ),
              )
            else if (leading != null)
              _LeadingSlot(child: _tint(style.foreground, leading!)),
            DefaultTextStyle(
              style: (style.textStyle ?? const TextStyle()).copyWith(
                color: style.foreground,
              ),
              child: label,
            ),
            if (trailing != null)
              Padding(
                padding: const EdgeInsets.only(left: OrionSpacing.space8),
                child: _tint(style.foreground, trailing!),
              ),
          ],
        ),
      ),
    ),
  );
}

Widget _tint(Color color, Widget child) {
  return IconTheme.merge(
    data: IconThemeData(color: color),
    child: child,
  );
}

class _LeadingSlot extends StatelessWidget {
  const _LeadingSlot({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: OrionSpacing.space8),
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
