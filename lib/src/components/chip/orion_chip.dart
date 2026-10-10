import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/chip/orion_chip_presets.dart';
import 'package:orion_ui/src/components/chip/orion_chip_style.dart';
import 'package:orion_ui/src/components/chip/orion_chip_theme.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The chip's size step.
enum OrionChipSize { small, medium, large }

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
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionChipPresets] for the [size], the ambient [OrionChipTheme],
/// and the [style] passed here. Anything an override does not name falls
/// through, and focus paints a translucent layer over the pill's surface
/// rather than a second concentric edge.
class OrionChip extends StatefulWidget {
  /// Creates a controlled chip.
  const OrionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.semanticLabel,
    this.size = OrionChipSize.medium,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Visible content. A plain `Text` inherits `labelMedium` and the state color.
  final Widget label;

  /// Whether the chip is selected. The parent owns the value.
  final bool selected;

  /// Called with the opposite of [selected]. Null disables the chip.
  final ValueChanged<bool>? onSelected;

  /// Spoken name in place of the visible label.
  final String? semanticLabel;

  /// The size step. Defaults to [OrionChipSize.medium], the shipped pill.
  final OrionChipSize size;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the chip requests focus on first build.
  final bool autofocus;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionChipTheme]. Only the fields set here change.
  final OrionChipStyle? style;

  @override
  State<OrionChip> createState() => _OrionChipState();
}

class _OrionChipState extends State<OrionChip>
    with SingleTickerProviderStateMixin {
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
  void didUpdateWidget(OrionChip oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
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

  void _syncMotion() {
    final OrionChipStyle style = _resolve(Theme.of(context));
    _driver.springSpec = style.spring ?? _travel;
  }

  OrionChipStyle _resolve(ThemeData theme) {
    final OrionChipTheme chipTheme =
        theme.extension<OrionChipTheme>() ?? OrionChipTheme.fallback;
    return OrionChipPresets.resolve(
      size: widget.size,
      scheme: theme.colorScheme,
    ).merge(chipTheme.defaultStyle).merge(widget.style);
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
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionChipStyle style = _resolve(theme);
    final bool enabled = widget.onSelected != null;

    // The selected end of the travel, resolved unconditionally: these are the
    // lerp's endpoints, not the live state, so unselecting animates the fill
    // and label out instead of snapping them on frame 0.
    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_focused) WidgetState.focused,
    };
    final Set<WidgetState> filledStates = <WidgetState>{
      WidgetState.selected,
      ...restingStates,
    };

    final Color fillIdle =
        style.fillColor?.resolve(restingStates) ?? theme.colorScheme.secondary;
    final Color fillOn =
        style.fillColor?.resolve(filledStates) ?? theme.colorScheme.primary;
    final Color borderIdle =
        style.borderColor?.resolve(restingStates) ?? theme.colorScheme.outline;
    final Color borderOn =
        style.borderColor?.resolve(filledStates) ?? theme.colorScheme.primary;
    final Color labelIdle =
        style.labelColor?.resolve(restingStates) ??
        theme.colorScheme.onSurfaceVariant;
    final Color labelOn =
        style.labelColor?.resolve(filledStates) ?? theme.colorScheme.onPrimary;
    final Color checkColor =
        style.checkColor?.resolve(filledStates) ?? theme.colorScheme.onPrimary;
    final Color overlayColor =
        style.focusOverlayColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.12);
    final double height = style.height ?? OrionSizing.controlHeightSmall;
    final double borderWidth = style.borderWidth ?? 1;
    final double checkSize = style.checkSize ?? OrionSizing.iconSmall;
    final double checkGap = style.checkGap ?? OrionSpacing.space8;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final EdgeInsets padding =
        (style.padding ??
                const EdgeInsets.symmetric(horizontal: OrionSpacing.space12))
            .resolve(Directionality.of(context));
    final TextStyle baseStyle =
        theme.textTheme.labelMedium ?? const TextStyle();

    // The check is built once per widget build, so the travel ticker reuses it.
    final Widget check = Icon(Icons.check, size: checkSize, color: checkColor);

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
                          color: Color.lerp(borderIdle, borderOn, shown)!,
                          width: borderWidth,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: radius,
                        child: Stack(
                          children: <Widget>[
                            SizedBox(
                              height: height,
                              child: Padding(
                                padding: padding,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    SizedBox(
                                      width: checkSize * shown,
                                      height: checkSize,
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
                                    SizedBox(width: checkGap * shown),
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
                                          : ExcludeSemantics(
                                              child: widget.label,
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // The focus state layer sits over the surface,
                            // inside the clip, so the pill keeps one edge and
                            // focus never draws a second one.
                            if (_focused && enabled)
                              Positioned.fill(
                                child: ColoredBox(color: overlayColor),
                              ),
                          ],
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
