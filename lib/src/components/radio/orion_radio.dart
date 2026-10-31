import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/radio/orion_radio_presets.dart';
import 'package:orion_ui/src/components/radio/orion_radio_style.dart';
import 'package:orion_ui/src/components/radio/orion_radio_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The circle's size step.
enum OrionRadioSize { small, medium, large }

/// A circle that marks the one chosen option in a group.
///
/// The parent owns [value] and the group itself (or use `OrionRadioGroup` for a
/// managed typed group with keyboard arrow navigation and form validation).
/// This widget only ever reports `true`, because a radio cannot be switched off
/// by activating it.
///
/// Pass optional [label] and [subtitle] to render a clickable label row where
/// tapping anywhere along the text selects the radio without duplicating screen
/// reader announcements.
///
/// The dot rides a crisp spring (`k = 520, zeta = 0.80`), matching
/// `OrionCheckbox` side-by-side. The dot is clipped by the circle, so spring
/// overshoot cannot paint outside it. A tap emits
/// [OrionThemeData.selectionHaptic] once the tap wins the gesture arena when
/// selecting an unselected radio; retapping an already-selected radio and
/// activating via Enter or Space stay silent.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionRadioPresets] for the [size], the ambient [OrionRadioTheme],
/// and the [style] passed here. Anything an override does not name falls
/// through. [error] rides the same machinery: it only changes colours, and
/// validation stays the host's (or `OrionRadioGroup`'s).
class OrionRadio extends StatefulWidget {
  /// Creates a controlled radio.
  const OrionRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.size = OrionRadioSize.medium,
    this.error = false,
    this.style,
  });

  /// Whether this option is the chosen one.
  final bool value;

  /// Called with `true` when this option is chosen. Never called with `false`.
  /// Null disables the radio.
  final ValueChanged<bool>? onChanged;

  /// Optional clickable text label displayed beside the radio.
  final String? label;

  /// Optional supporting description displayed beneath [label].
  final String? subtitle;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the radio requests focus on first build.
  final bool autofocus;

  /// Spoken name. Defaults to [label] when provided; the selected state is
  /// exposed separately.
  final String? semanticLabel;

  /// The size step. Defaults to [OrionRadioSize.medium], the shipped circle.
  final OrionRadioSize size;

  /// Paints the error role: the ring and the dot take the scheme's error
  /// colour. The circle does not validate anything.
  final bool error;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionRadioTheme]. Only the fields set here change.
  final OrionRadioStyle? style;

  @override
  State<OrionRadio> createState() => _OrionRadioState();
}

class _OrionRadioState extends State<OrionRadio>
    with SingleTickerProviderStateMixin {
  static const OrionSpringSpec _travel = OrionRadioPresets.defaultSpring;

  /// Guard ceiling for dot scale overshoot.
  static const double _dotCeiling = 1.4;

  late final OrionSpringDriver _driver;
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: _travel,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion) {
          return;
        }
        _driver.jumpTo(_target);
      });
    }
  }

  @override
  void didUpdateWidget(OrionRadio oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (widget.value != oldWidget.value) {
      _sync();
    }
    if (widget.onChanged == null && (_hovered || _focused)) {
      _hovered = false;
      _focused = false;
    }
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  double get _target => widget.value ? 1 : 0;

  void _sync() {
    if (_driver.reducedMotion) {
      _driver.jumpTo(_target);
    } else {
      _driver.retarget(_target);
    }
  }

  void _syncMotion() {
    final OrionRadioStyle style = _resolve(Theme.of(context));
    _driver.springSpec = style.spring ?? _travel;
  }

  OrionRadioStyle _resolve(ThemeData theme) {
    final OrionRadioTheme radioTheme =
        theme.extension<OrionRadioTheme>() ?? OrionRadioTheme.fallback;
    return OrionRadioPresets.resolve(
      size: widget.size,
      scheme: theme.colorScheme,
    ).merge(radioTheme.defaultStyle).merge(widget.style);
  }

  /// Reports the choice. The value is always `true`; see the class docs.
  void _select() {
    if (widget.onChanged == null) {
      return;
    }
    widget.onChanged!(true);
  }

  /// Handles taps on the optional label/subtitle area outside the circle.
  void _handleLabelTap() {
    if (widget.onChanged == null) {
      return;
    }
    if (!widget.value) {
      final OrionHapticType haptic = OrionTheme.of(context).selectionHaptic;
      if (haptic != OrionHapticType.none) {
        OrionHaptics.trigger(haptic);
      }
    }
    _select();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionRadioStyle style = _resolve(theme);
    final bool enabled = widget.onChanged != null;
    final bool hasLabel = widget.label != null || widget.subtitle != null;

    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (widget.error) WidgetState.error,
      if (_hovered && enabled) WidgetState.hovered,
      if (_focused && enabled) WidgetState.focused,
    };
    // The filled end of the travel, resolved unconditionally: these are the
    // lerp's endpoints, not the live state, so deselecting animates the ring
    // and interior out instead of snapping them on frame 0.
    final Set<WidgetState> filledStates = <WidgetState>{
      WidgetState.selected,
      ...restingStates,
    };

    final Color ringRest =
        style.ringColor?.resolve(restingStates) ?? scheme.outline;
    final Color ringOn =
        style.ringColor?.resolve(filledStates) ?? scheme.primary;
    final Color dotColor =
        style.dotColor?.resolve(filledStates) ?? scheme.primary;
    final Color fillRest =
        style.fillColor?.resolve(restingStates) ?? Colors.transparent;
    final Color fillOn =
        style.fillColor?.resolve(filledStates) ?? Colors.transparent;
    final double circle = math.max(0.0, style.size ?? OrionSizing.iconMedium);
    final double dotSize = math.max(
      0.0,
      style.dotSize ?? OrionSizing.iconSmall * 0.5,
    );
    final double borderWidth = math.max(0.0, style.borderWidth ?? 2);
    final double pressedScale = (style.pressedScale ?? 0.90).clamp(0.5, 1.0);
    final Color focusOverlay =
        style.focusOverlayColor ?? scheme.onSurface.withValues(alpha: 0.12);
    final Color hoverOverlay =
        style.hoverOverlayColor ?? scheme.onSurface.withValues(alpha: 0.05);
    final double hitTarget = math.max(OrionSizing.minHitTarget, circle);

    // Built once per widget build, so the ticker only rescales it.
    final Widget dot = SizedBox.square(
      dimension: dotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
    );

    final Widget circleTarget = SizedBox(
      width: hitTarget,
      height: hitTarget,
      child: Center(
        child: AnimatedBuilder(
          animation: _driver,
          child: dot,
          builder: (BuildContext context, Widget? child) {
            final double shown = _driver.value.clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: <Widget>[
                // The overlay sits under the circle, so the ring stays legible
                // and focus never draws a second ring.
                if ((_focused || _hovered) && enabled)
                  SizedBox.square(
                    dimension: circle + OrionSpacing.space16,
                    child: ClipOval(
                      child: ColoredBox(
                        color: _focused ? focusOverlay : hoverOverlay,
                      ),
                    ),
                  ),
                SizedBox.square(
                  dimension: circle,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: borderWidth > 0
                          ? Border.all(
                              color: Color.lerp(ringRest, ringOn, shown)!,
                              width: borderWidth,
                            )
                          : null,
                    ),
                    child: ClipOval(
                      child: ColoredBox(
                        // The interior is transparent by default; custom resting
                        // and selected fills interpolate smoothly together.
                        color: Color.lerp(fillRest, fillOn, shown)!,
                        child: Center(
                          child: Transform.scale(
                            scale: _driver.value.clamp(0.0, _dotCeiling),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final Widget pressableCircle = OrionPressable(
      behavior: HitTestBehavior.opaque,
      pressedScale: pressedScale,
      hapticType: widget.value
          ? OrionHapticType.none
          : OrionTheme.of(context).selectionHaptic,
      onTap: enabled ? _select : null,
      child: circleTarget,
    );

    Widget interactiveChild;
    if (!hasLabel) {
      interactiveChild = pressableCircle;
    } else {
      final Color labelColor = !enabled
          ? scheme.onSurface.withValues(alpha: 0.38)
          : widget.error
          ? scheme.error
          : scheme.onSurface;
      final Color subtitleColor = !enabled
          ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
          : scheme.onSurfaceVariant;
      final double labelTopPadding = math.max(0.0, (hitTarget - 24.0) / 2.0);

      // Wrap the whole row in a tap target so clicking the text selects the
      // radio, while keeping the 0.90 tactile dip isolated to the circle.
      interactiveChild = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _handleLabelTap : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.subtitle != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: <Widget>[
            pressableCircle,
            const SizedBox(width: OrionSpacing.space4),
            Flexible(
              child: Padding(
                padding: widget.subtitle != null
                    ? EdgeInsets.only(top: labelTopPadding)
                    : EdgeInsets.zero,
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (widget.label != null)
                        Text(
                          widget.label!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (widget.subtitle != null) ...<Widget>[
                        const SizedBox(height: 2.0),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      checked: widget.value,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      label: widget.semanticLabel ?? widget.label,
      child: MouseRegion(
        onEnter: (_) {
          if (mounted && enabled && !_hovered) {
            setState(() => _hovered = true);
          }
        },
        onExit: (_) {
          if (mounted && _hovered) {
            setState(() => _hovered = false);
          }
        },
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onShowFocusHighlight: (bool focused) {
            if (focused != _focused) {
              setState(() => _focused = focused);
            }
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                _select();
                return null;
              },
            ),
          },
          child: interactiveChild,
        ),
      ),
    );
  }
}
