import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// A pill that reports an independent on or off selection.
///
/// The parent owns [selected]. The chip owns no set, no row, and no wrap: compose
/// those around it, the way the gallery does.
///
/// [OrionPressable] owns the press: it compresses on the press spring and emits
/// [OrionThemeData.selectionHaptic] only once the tap wins the gesture arena. One
/// [OrionSpringDriver] owns the state travel from 0 to 1 on the gentle spring,
/// driving the fill, the hairline, the label color, and the check together, so
/// no surface snaps while the others travel. Selection is not carried by color
/// alone, which is also what separates the chip from [OrionSegmentedControl] and
/// its sliding surface.
class OrionChip extends StatefulWidget {
  /// Creates a controlled chip.
  const OrionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Visible content. A plain `Text` inherits `labelMedium` and the state color.
  final Widget label;

  /// Whether the chip is selected. The parent owns the value.
  final bool selected;

  /// Called with the opposite of [selected]. Null disables the chip.
  final ValueChanged<bool>? onSelected;

  /// Spoken name in place of the visible label.
  final String? semanticLabel;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the chip requests focus on first build.
  final bool autofocus;

  @override
  State<OrionChip> createState() => _OrionChipState();
}

class _OrionChipState extends State<OrionChip>
    with SingleTickerProviderStateMixin {
  static const double _height = OrionSizing.controlHeightSmall;
  static const double _lineWidth = 1;
  static const double _checkSize = OrionSizing.iconSmall;
  static const double _checkGap = OrionSpacing.space8;

  /// Travel spring for the whole 0 to 1 state change.
  ///
  /// [OrionSpringSpec.snappy] is sized for the documented 0.96 to 1.0 press
  /// release. Over a full travel its ~30% overshoot peaks at 1.297, so a cap
  /// would freeze the check mid-pop and the fill would dip on the way back.
  /// [OrionSpringSpec.gentle] peaks at 1.038 and dips to 0.9985.
  static const OrionSpringSpec _travel = OrionSpringSpec.gentle;

  /// The check is 16 pt in a 32 pt pill, so it clears the edge until 1.5. The
  /// travel spring peaks near 1.04; this is a guard, not a shaping cap.
  static const double _checkCeiling = 1.4;

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
  void didUpdateWidget(OrionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selected != oldWidget.selected) {
      _sync();
    }
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  double get _target => widget.selected ? 1 : 0;

  void _sync() {
    if (_driver.reducedMotion) {
      _driver.jumpTo(_target);
    } else {
      _driver.retarget(_target);
    }
  }

  /// Reports the next value. The haptic belongs to [OrionPressable], so the
  /// keyboard path through [ActivateIntent] stays silent.
  void _select() {
    if (widget.onSelected == null) {
      return;
    }
    widget.onSelected!(!widget.selected);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final bool enabled = widget.onSelected != null;
    final BorderRadius radius = BorderRadius.circular(OrionRadii.radiusPill);
    final TextStyle baseStyle =
        theme.textTheme.labelMedium ?? const TextStyle();

    final Color fillIdle = enabled
        ? scheme.secondary
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color fillOn = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color borderIdle = enabled
        ? scheme.outline
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color labelIdle = enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurface.withValues(alpha: 0.38);
    final Color labelOn = enabled
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.38);

    // The check is built once per widget build, so the travel ticker reuses it.
    final Widget check = Icon(Icons.check, size: _checkSize, color: labelOn);

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: widget.selected,
        enabled: enabled,
        label: widget.semanticLabel,
        child: FocusableActionDetector(
          enabled: enabled,
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
          child: OrionPressable(
            onTap: enabled ? _select : null,
            pressedScale: orion.pressScale,
            springSpec: orion.pressSpring,
            releaseSpringSpec: orion.releaseSpring,
            hapticType: orion.selectionHaptic,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                minWidth: OrionSizing.minHitTarget,
                minHeight: OrionSizing.minHitTarget,
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: AnimatedBuilder(
                  animation: _driver,
                  child: check,
                  builder: (BuildContext context, Widget? child) {
                    final double shown = _driver.value.clamp(0.0, 1.0);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(fillIdle, fillOn, shown),
                        borderRadius: radius,
                        border: Border.all(
                          color: Color.lerp(borderIdle, fillOn, shown)!,
                          width: _lineWidth,
                        ),
                        // The halo sits outside the pill so it stays visible
                        // once the fill is primary.
                        boxShadow: _focused && enabled
                            ? <BoxShadow>[
                                BoxShadow(
                                  color: scheme.onSurface,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: SizedBox(
                          height: _height,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: OrionSpacing.space12,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: <Widget>[
                                SizedBox(
                                  width: _checkSize * shown,
                                  height: _checkSize,
                                  child: ClipRect(
                                    child: Transform.scale(
                                      scale: _driver.value.clamp(
                                        0.0,
                                        _checkCeiling,
                                      ),
                                      child: child,
                                    ),
                                  ),
                                ),
                                SizedBox(width: _checkGap * shown),
                                // The label travels with the fill, so it never
                                // snaps to onPrimary over a still-light pill.
                                DefaultTextStyle(
                                  style: baseStyle.copyWith(
                                    color: Color.lerp(
                                      labelIdle,
                                      labelOn,
                                      shown,
                                    ),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: widget.semanticLabel == null
                                      ? widget.label
                                      : ExcludeSemantics(child: widget.label),
                                ),
                              ],
                            ),
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
