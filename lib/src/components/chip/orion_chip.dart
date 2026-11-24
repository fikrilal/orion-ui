import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/chip/orion_chip_presets.dart';
import 'package:orion_ui/src/components/chip/orion_chip_style.dart';
import 'package:orion_ui/src/components/chip/orion_chip_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The chip's size step.
enum OrionChipSize { small, medium, large }

/// Key assigned to the trailing remove control when [OrionChip.onDeleted] is set.
const Key orionChipDeleteButtonKey = Key('orion_chip_delete_button');

/// A pill that reports an independent on or off selection, and optionally
/// supports leading/trailing slots or removal.
///
/// The parent owns [selected]. For a managed single- or multi-select row or
/// wrap with optional clear controls, compose [OrionChipGroup].
///
/// [OrionPressable] owns the press: it compresses on the press spring and emits
/// [OrionThemeData.selectionHaptic] only once the tap wins the gesture arena. One
/// [OrionSpringDriver] owns the state travel from 0 to 1 on
/// [OrionChipPresets.defaultSpring], driving the fill, the border, the label
/// color, and the optional checkmark together, so no surface snaps while the
/// others travel.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionChipPresets] for the [size], the ambient [OrionChipTheme],
/// and the [style] passed here. Anything an override does not name falls
/// through, and focus paints a translucent layer over the pill's surface
/// rather than a second concentric edge.
class OrionChip extends StatefulWidget {
  /// Creates a controlled chip.
  ///
  /// Supply either [text] (plain string shorthand) or [label] (custom widget),
  /// not both. Supply either [trailing] or [onDeleted], not both.
  const OrionChip({
    super.key,
    this.text,
    this.label,
    required this.selected,
    required this.onSelected,
    this.leading,
    this.trailing,
    this.onDeleted,
    this.deleteButtonTooltip = 'Remove',
    this.showCheckmark = true,
    this.semanticLabel,
    this.size = OrionChipSize.medium,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(
         (text != null) != (label != null),
         'Provide either text or label, not both.',
       ),
       assert(
         trailing == null || onDeleted == null,
         'Provide either trailing or onDeleted, not both.',
       );

  /// Plain string label shorthand. Rendered with single-line ellipsis inside the
  /// resolved [OrionChipStyle.textStyle].
  final String? text;

  /// Visible content widget. A plain `Text` inherits the stepped label style
  /// and the animated state color.
  final Widget? label;

  /// Whether the chip is selected. The parent owns the value.
  final bool selected;

  /// Called with the opposite of [selected]. Null disables toggling (and
  /// disables the chip entirely when [onDeleted] is also null).
  final ValueChanged<bool>? onSelected;

  /// Optional leading widget (for example an [Icon] or small avatar). Icons
  /// automatically inherit the animated label color and size.
  final Widget? leading;

  /// Optional trailing widget. Mutually exclusive with [onDeleted]. Icons
  /// automatically inherit the animated label color and size.
  final Widget? trailing;

  /// Optional delete callback. When non-null, renders a trailing remove button
  /// that invokes [onDeleted] without toggling selection.
  final VoidCallback? onDeleted;

  /// Tooltip and semantic label for the delete button when [onDeleted] is set.
  final String deleteButtonTooltip;

  /// Whether to animate a leading checkmark in when [selected] is true.
  ///
  /// Set to `false` for single-select choice chips or when you want chip width
  /// to remain constant across selection changes.
  final bool showCheckmark;

  /// Spoken name in place of the visible label.
  final String? semanticLabel;

  /// The size step. Defaults to [OrionChipSize.medium], the 32 pt pill.
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
  /// The check is 16 pt in a 32 pt pill, so it clears the edge until 1.5. The
  /// travel spring peaks near 1.01; this is a guard, not a shaping cap.
  static const double _checkCeiling = 1.4;

  late final OrionSpringDriver _driver;
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: OrionChipPresets.defaultSpring,
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
    _driver.springSpec = style.spring ?? OrionChipPresets.defaultSpring;
  }

  OrionChipStyle _resolve(ThemeData theme) {
    final OrionChipTheme chipTheme =
        theme.extension<OrionChipTheme>() ?? OrionChipTheme.fallback;
    return OrionChipPresets.resolve(
      size: widget.size,
      scheme: theme.colorScheme,
      textTheme: theme.textTheme,
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

  void _delete() {
    if (widget.onDeleted == null) {
      return;
    }
    OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
    widget.onDeleted!();
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionChipStyle style = _resolve(theme);
    final bool canSelect = widget.onSelected != null;
    final bool canDelete = widget.onDeleted != null;
    final bool enabled = canSelect || canDelete;

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
        style.borderColor?.resolve(restingStates) ??
        theme.colorScheme.outlineVariant;
    final Color borderOn =
        style.borderColor?.resolve(filledStates) ?? theme.colorScheme.primary;
    final Color labelIdle =
        style.labelColor?.resolve(restingStates) ??
        theme.colorScheme.onSecondary;
    final Color labelOn =
        style.labelColor?.resolve(filledStates) ?? theme.colorScheme.onPrimary;
    final Color checkColor =
        style.checkColor?.resolve(filledStates) ?? theme.colorScheme.onPrimary;
    final Color focusOverlayColor =
        style.focusOverlayColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.12);
    final Color hoverOverlayColor =
        style.hoverOverlayColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.05);
    final double height = style.height ?? OrionSizing.controlHeightSmall;
    final double borderWidth = style.borderWidth ?? 1;
    final double checkSize = style.checkSize ?? OrionSizing.iconSmall;
    final double checkGap = style.checkGap ?? OrionSpacing.space8;
    final double iconGap = (checkGap * 0.75).clamp(4.0, 8.0);
    final double pressedScale = style.pressedScale ?? orion.pressScale;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final EdgeInsets basePadding =
        (style.padding ??
                const EdgeInsets.symmetric(horizontal: OrionSpacing.space12))
            .resolve(Directionality.of(context));
    final EdgeInsets padding = canDelete
        ? basePadding.copyWith(
            right: (basePadding.right - 4.0).clamp(4.0, double.infinity),
          )
        : basePadding;
    final TextStyle baseStyle =
        style.textStyle ?? theme.textTheme.labelMedium ?? const TextStyle();

    // The check is built once per widget build, so the travel ticker reuses it.
    final Widget? check = widget.showCheckmark
        ? Icon(Icons.check, size: checkSize, color: checkColor)
        : null;
    final Widget labelContent = widget.label ?? Text(widget.text!);

    final Widget detector = FocusableActionDetector(
      enabled: enabled,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      onShowFocusHighlight: (bool focused) {
        if (focused != _focused) {
          setState(() => _focused = focused);
        }
      },
      onShowHoverHighlight: (bool hovered) {
        if (hovered != _hovered) {
          setState(() => _hovered = hovered);
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
        onTap: canSelect ? _select : null,
        pressedScale: pressedScale,
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
                final Color currentLabelColor = Color.lerp(
                  labelIdle,
                  labelOn,
                  shown,
                )!;
                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: Color.lerp(fillIdle, fillOn, shown),
                    borderRadius: radius,
                    border: borderWidth <= 0
                        ? null
                        : Border.all(
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
                                if (widget.showCheckmark) ...<Widget>[
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
                                ],
                                if (widget.leading != null) ...<Widget>[
                                  IconTheme.merge(
                                    data: IconThemeData(
                                      color: currentLabelColor,
                                      size: checkSize,
                                    ),
                                    child: widget.leading!,
                                  ),
                                  SizedBox(width: iconGap),
                                ],
                                // The label travels with the fill, so it never
                                // snaps to onPrimary over a still-light pill.
                                DefaultTextStyle(
                                  style: baseStyle.copyWith(
                                    color: currentLabelColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  child: widget.semanticLabel == null
                                      ? labelContent
                                      : ExcludeSemantics(child: labelContent),
                                ),
                                if (widget.trailing != null) ...<Widget>[
                                  SizedBox(width: iconGap),
                                  IconTheme.merge(
                                    data: IconThemeData(
                                      color: currentLabelColor,
                                      size: checkSize,
                                    ),
                                    child: widget.trailing!,
                                  ),
                                ],
                                if (canDelete) ...<Widget>[
                                  SizedBox(width: iconGap * 0.5),
                                  Semantics(
                                    button: true,
                                    enabled: true,
                                    label: widget.deleteButtonTooltip,
                                    onTap: _delete,
                                    child: Tooltip(
                                      message: widget.deleteButtonTooltip,
                                      child: MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          key: orionChipDeleteButtonKey,
                                          behavior: HitTestBehavior.opaque,
                                          onTap: _delete,
                                          child: SizedBox(
                                            height: height,
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                              child: Center(
                                                child: Icon(
                                                  Icons.close_rounded,
                                                  size: (checkSize * 0.875)
                                                      .clamp(12.0, 18.0),
                                                  color: currentLabelColor
                                                      .withValues(alpha: 0.72),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        // The focus / hover state layer sits over the surface,
                        // inside the clip, so the pill keeps one edge and never
                        // draws a second concentric border.
                        if (_focused && enabled)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ColoredBox(color: focusOverlayColor),
                            ),
                          )
                        else if (_hovered && enabled)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ColoredBox(color: hoverOverlayColor),
                            ),
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
    );

    if (canDelete) {
      return Semantics(
        container: true,
        explicitChildNodes: true,
        button: canSelect,
        selected: widget.selected,
        enabled: enabled,
        label: widget.semanticLabel,
        child: detector,
      );
    }

    return MergeSemantics(
      child: Semantics(
        button: true,
        selected: widget.selected,
        enabled: enabled,
        label: widget.semanticLabel,
        child: detector,
      ),
    );
  }
}
