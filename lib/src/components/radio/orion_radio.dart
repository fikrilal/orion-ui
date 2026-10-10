import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/radio/orion_radio_presets.dart';
import 'package:orion_ui/src/components/radio/orion_radio_style.dart';
import 'package:orion_ui/src/components/radio/orion_radio_theme.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The circle's size step.
enum OrionRadioSize { small, medium, large }

/// A circle that marks the one chosen option in a group.
///
/// The parent owns [value] and the group itself; this widget is one choice, not
/// a set. It only ever reports `true`, because a radio cannot be switched off
/// by activating it.
///
/// It is tap-only: it does not drag, and it does not own a label row. The dot
/// rides the travel spring, which is tuned for the full 0 to 1 state change
/// rather than for a press release. The dot is clipped by the circle, so the
/// overshoot cannot paint outside it. A tap emits
/// [OrionThemeData.selectionHaptic] once the tap wins the gesture arena; Enter
/// and Space select silently.
///
/// The mark and the shape both differ from [OrionCheckbox] on purpose: the two
/// controls share a form, so a filled box with a check and a ring with a dot
/// stay distinguishable at a glance. The interior stays transparent by default
/// - [OrionRadioStyle.fillColor] is the opt-in for a filled radio.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionRadioPresets] for the [size], the ambient [OrionRadioTheme],
/// and the [style] passed here. Anything an override does not name falls
/// through. [error] rides the same machinery: it only changes colours, and
/// validation stays the host's.
class OrionRadio extends StatefulWidget {
  /// Creates a controlled radio.
  const OrionRadio({
    super.key,
    required this.value,
    required this.onChanged,
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

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the radio requests focus on first build.
  final bool autofocus;

  /// Spoken name. The selected state is exposed separately.
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
  /// Travel spring for the whole 0 to 1 state change.
  ///
  /// [OrionSpringSpec.snappy] is sized for the documented 0.96 to 1.0 press
  /// release, so over a full travel its ~30% overshoot peaks at 1.297 and any
  /// sane cap holds the dot still for several frames.
  /// [OrionSpringSpec.gentle] peaks at 1.038: one visible pop. The checkbox
  /// mark and the chip check ride the same spring.
  static const OrionSpringSpec _travel = OrionSpringSpec.gentle;

  /// The dot is 8 pt inside a 24 pt circle, so it clears the edge until 2.5.
  /// The travel spring peaks near 1.04; this is a guard, not a shaping cap.
  static const double _dotCeiling = 1.4;

  late final OrionSpringDriver _driver;
  bool _focused = false;

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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionRadioStyle style = _resolve(theme);
    final bool enabled = widget.onChanged != null;

    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (widget.error) WidgetState.error,
    };
    final Set<WidgetState> selectedStates = <WidgetState>{
      ...restingStates,
      if (widget.value) WidgetState.selected,
    };

    final Color ringRest =
        style.ringColor?.resolve(restingStates) ?? scheme.outline;
    final Color ringOn =
        style.ringColor?.resolve(selectedStates) ?? scheme.primary;
    final Color dotColor =
        style.dotColor?.resolve(selectedStates) ?? scheme.primary;
    final Color fill =
        style.fillColor?.resolve(selectedStates) ?? Colors.transparent;
    final double circle = style.size ?? OrionSizing.iconMedium;
    final double dotSize = style.dotSize ?? OrionSizing.iconSmall * 0.5;
    final double borderWidth = style.borderWidth ?? 2;
    final Color overlay =
        style.focusOverlayColor ?? scheme.onSurface.withValues(alpha: 0.12);

    // Built once per widget build, so the ticker only rescales it.
    final Widget dot = SizedBox.square(
      dimension: dotSize,
      child: DecoratedBox(
        decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
      ),
    );

    return Semantics(
      container: true,
      checked: widget.value,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      label: widget.semanticLabel,
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
        // Every other control in the kit gets its press feedback and its cue from
        // [OrionPressable]; these two hand-rolled a bare tap and a direct haptic.
        child: OrionPressable(
          behavior: HitTestBehavior.opaque,
          hapticType: OrionTheme.of(context).selectionHaptic,
          onTap: enabled ? _select : null,
          child: SizedBox(
            width: OrionSizing.minHitTarget,
            height: OrionSizing.minHitTarget,
            child: Center(
              child: AnimatedBuilder(
                animation: _driver,
                child: dot,
                builder: (BuildContext context, Widget? child) {
                  final double shown = _driver.value.clamp(0.0, 1.0);
                  return Stack(
                    alignment: Alignment.center,
                    children: <Widget>[
                      // The overlay sits under the circle, so the ring stays
                      // legible and focus never draws a second ring.
                      if (_focused && enabled)
                        SizedBox.square(
                          dimension: circle + OrionSpacing.space16,
                          child: ClipOval(child: ColoredBox(color: overlay)),
                        ),
                      SizedBox.square(
                        dimension: circle,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Color.lerp(ringRest, ringOn, shown)!,
                              width: borderWidth,
                            ),
                          ),
                          child: ClipOval(
                            child: ColoredBox(
                              // The interior is transparent by default; a fill
                              // colour rides the same travel as the ring.
                              color: Color.lerp(
                                Colors.transparent,
                                fill,
                                shown,
                              )!,
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
          ),
        ),
      ),
    );
  }
}
