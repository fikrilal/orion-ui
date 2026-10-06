import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// A box that confirms a boolean and can show an indeterminate middle state.
///
/// The parent owns [value]; null is indeterminate. The box is tap-only: it
/// does not drag, and it does not own a label row.
///
/// One [OrionSpringDriver] drives the fill, the border, and the mark on the
/// travel spring (see `_travel`), which is tuned for the full 0 to 1 state
/// change rather than for a press release. The mark is clipped by the box, so
/// the overshoot cannot paint outside it. A tap emits [OrionThemeData.selectionHaptic]
/// once the tap wins the gesture arena; Enter and Space flip the box silently.
class OrionCheckbox extends StatefulWidget {
  /// Creates a controlled checkbox.
  const OrionCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Whether the box is checked. Null is indeterminate.
  final bool? value;

  /// Called with the opposite of [value]. An indeterminate box reports `true`.
  /// Null disables the box.
  final ValueChanged<bool?>? onChanged;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the box requests focus on first build.
  final bool autofocus;

  /// Spoken name. The checked state is exposed separately.
  final String? semanticLabel;

  @override
  State<OrionCheckbox> createState() => _OrionCheckboxState();
}

class _OrionCheckboxState extends State<OrionCheckbox>
    with SingleTickerProviderStateMixin {
  static const double _boxSize = OrionSizing.iconMedium;
  static const double _markSize = OrionSizing.iconSmall;
  static const double _barWidth = OrionSpacing.space12;
  static const double _barHeight = 2;
  static const double _lineWidth = 2;

  /// Travel spring for the whole 0 to 1 state change.
  ///
  /// [OrionSpringSpec.snappy] is sized for the documented 0.96 to 1.0 press
  /// release, where its ~30% overshoot is 1.2% of scale. Driven over a full
  /// travel that same overshoot peaks at 1.297, so any sane cap holds the mark
  /// still for several frames and the fill dips to 0.91 on the way back.
  /// [OrionSpringSpec.gentle] peaks at 1.038 and dips to 0.9985: one visible
  /// pop, and a fill that never fades below full strength. The switch rides the
  /// same spring for its thumb travel.
  static const OrionSpringSpec _travel = OrionSpringSpec.gentle;

  /// The mark is 16 pt inside a 24 pt box, so it clears the edge until 1.5.
  /// The travel spring peaks near 1.04; this is a guard, not a shaping cap.
  static const double _markCeiling = 1.4;

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
  void didUpdateWidget(OrionCheckbox oldWidget) {
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

  /// The filled end of the travel. Checked and indeterminate are both filled.
  double get _target => widget.value == false ? 0 : 1;

  void _sync() {
    if (_reduceMotion) {
      _driver.jumpTo(_target);
    } else {
      _driver.retarget(_target);
    }
  }

  void _flip({required bool haptic}) {
    if (widget.onChanged == null) {
      return;
    }
    if (haptic) {
      OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
    }
    widget.onChanged!(!(widget.value ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = widget.onChanged != null;
    final bool indeterminate = widget.value == null;
    final BorderRadius radius = BorderRadius.circular(OrionRadii.radius4);

    final Color fillOn = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color borderOff = enabled
        ? scheme.outline
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color markColor = enabled
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.38);

    final Widget mark = indeterminate
        ? SizedBox(
            width: _barWidth,
            height: _barHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: markColor,
                borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
              ),
            ),
          )
        : Icon(Icons.check, size: _markSize, color: markColor);

    return Semantics(
      container: true,
      checked: widget.value ?? false,
      mixed: indeterminate,
      enabled: enabled,
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
              _flip(haptic: false);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _flip(haptic: true) : null,
          child: SizedBox(
            width: OrionSizing.minHitTarget,
            height: OrionSizing.minHitTarget,
            child: Center(
              child: SizedBox.square(
                dimension: _boxSize,
                child: AnimatedBuilder(
                  animation: _driver,
                  child: mark,
                  builder: (BuildContext context, Widget? child) {
                    final double shown = _driver.value.clamp(0.0, 1.0);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(Colors.transparent, fillOn, shown),
                        borderRadius: radius,
                        border: Border.all(
                          color: Color.lerp(borderOff, fillOn, shown)!,
                          width: _lineWidth,
                        ),
                        // The ring sits outside the box so it stays visible
                        // when the fill is already onSurface.
                        boxShadow: _focused && enabled
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: scheme.onSurface,
                                  spreadRadius: _lineWidth,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Center(
                          child: Transform.scale(
                            scale: _driver.value.clamp(0.0, _markCeiling),
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
