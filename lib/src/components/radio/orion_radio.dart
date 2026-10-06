import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// A circle that marks the one chosen option in a group.
///
/// The parent owns [value] and the group itself; this widget is one choice, not
/// a set. It only ever reports `true`, because a radio cannot be switched off
/// by activating it.
///
/// It is tap-only: it does not drag, and it does not own a label row. The dot
/// rides the travel spring (see `_travel`), which is tuned for the full 0 to 1
/// state change rather than for a press release. The dot is clipped by the
/// circle, so the overshoot cannot paint outside it. A tap emits
/// [OrionThemeData.selectionHaptic] once the tap wins the gesture arena; Enter and
/// Space select silently.
///
/// The mark and the shape both differ from [OrionCheckbox] on purpose: the two
/// controls share a form, so a filled box with a check and a ring with a dot
/// stay distinguishable at a glance.
class OrionRadio extends StatefulWidget {
  /// Creates a controlled radio.
  const OrionRadio({
    super.key,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
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

  @override
  State<OrionRadio> createState() => _OrionRadioState();
}

class _OrionRadioState extends State<OrionRadio>
    with SingleTickerProviderStateMixin {
  static const double _boxSize = OrionSizing.iconMedium;

  /// Half the small icon: an 8 pt dot inside a 24 pt circle leaves a 6 pt gap
  /// on each side, which is the proportion that reads as a radio.
  static const double _dotSize = OrionSizing.iconSmall * 0.5;
  static const double _lineWidth = 2;

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
  bool _reduceMotion = false;
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
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reduceMotion) {
          return;
        }
        _driver.jumpTo(_target);
      });
    }
  }

  @override
  void didUpdateWidget(OrionRadio oldWidget) {
    super.didUpdateWidget(oldWidget);
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
    if (_reduceMotion) {
      _driver.jumpTo(_target);
    } else {
      _driver.retarget(_target);
    }
  }

  /// Reports the choice. The value is always `true`; see the class docs.
  void _select({required bool haptic}) {
    if (widget.onChanged == null) {
      return;
    }
    if (haptic) {
      OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
    }
    widget.onChanged!(true);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = widget.onChanged != null;

    final Color ringOff = enabled
        ? scheme.outline
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color ringOn = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color dotColor = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.38);

    // Built once per widget build, so the ticker only rescales it.
    final Widget dot = SizedBox.square(
      dimension: _dotSize,
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
              _select(haptic: false);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _select(haptic: true) : null,
          child: SizedBox(
            width: OrionSizing.minHitTarget,
            height: OrionSizing.minHitTarget,
            child: Center(
              child: SizedBox.square(
                dimension: _boxSize,
                child: AnimatedBuilder(
                  animation: _driver,
                  child: dot,
                  builder: (BuildContext context, Widget? child) {
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Color.lerp(
                            ringOff,
                            ringOn,
                            _driver.value.clamp(0.0, 1.0),
                          )!,
                          width: _lineWidth,
                        ),
                        // The ring sits outside the circle so it stays visible
                        // when the hairline is already primary.
                        boxShadow: _focused && enabled
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: scheme.onSurface,
                                  spreadRadius: _lineWidth,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipOval(
                        child: Center(
                          child: Transform.scale(
                            scale: _driver.value.clamp(0.0, _dotCeiling),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
