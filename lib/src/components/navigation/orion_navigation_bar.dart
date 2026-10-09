import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/navigation/orion_navigation_bar_style.dart';
import 'package:orion_ui/src/components/navigation/orion_navigation_bar_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One destination in an [OrionNavigationBar].
class OrionNavigationDestination {
  /// Creates a destination with an icon and a short label.
  const OrionNavigationDestination({
    required this.icon,
    required this.label,
    this.badge,
  });

  /// Icon shown above [label]. It inherits the destination color.
  final Widget icon;

  /// Short name of the destination.
  final String label;

  /// Optional badge content - a count or a mark, typically - shown in a chip
  /// at the icon's top-right. The bar themes the chip with its cut-out ring;
  /// the host owns the content and its semantics.
  final Widget? badge;
}

/// How an [OrionNavigationBar] presents its destination labels.
enum OrionNavigationLabelMode {
  /// Every destination shows its icon above its label, and the capsule fills
  /// the space it is given up to the style's maximum width.
  all,

  /// Destinations are icons only, and the capsule hugs them: a natural width
  /// and a shorter fallback height.
  none,

  /// Destinations rest as icons; the selected one expands into a pill that
  /// reveals its label, the label-on-select pattern. The capsule reserves one
  /// label's width, so it never resizes as the selection moves.
  selected,
}

/// The weight a selected label renders at: the style's own when it is already
/// bold, else bold.
FontWeight _activeWeight(TextStyle style) {
  final FontWeight base = style.fontWeight ?? FontWeight.w500;
  return base.value >= FontWeight.w700.value ? base : FontWeight.w700;
}

/// A floating capsule of destinations.
///
/// The parent owns [selectedIndex]. The selection travels on the immediate travel
/// spec rather than the press spring, whose overshoot is a third of the travel.
/// While a pager
/// is moving, [dragPosition] is the fractional page and the pill follows it.
/// A jump of more than one destination does not select the tabs in between.
/// The bar does not own routes or the safe area. Place it over the screen,
/// inset from the edges.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionNavigationBarStyle.defaults], the ambient
/// [OrionNavigationTheme], and the [style] passed here. Anything an override
/// does not name falls through.
class OrionNavigationBar extends StatefulWidget {
  /// Creates a controlled navigation bar.
  const OrionNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onChanged,
    this.onLongPress,
    this.style,
    this.dragPosition,
    this.visible = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Destinations from the leading edge. At least two.
  final List<OrionNavigationDestination> destinations;

  /// Index of the selected destination.
  final int selectedIndex;

  /// Called with the tapped or keyed index, including a retap of the current
  /// destination. Null disables the bar.
  final ValueChanged<int>? onChanged;

  /// Called with the index when a destination is long-pressed. Null disables
  /// the long press while a plain tap still selects. Silent, like the
  /// reference's tab bar; menus are the host's.
  final ValueChanged<int>? onLongPress;

  /// Instance-level overrides, merged over the defaults and the ambient
  /// [OrionNavigationTheme]. Only the fields set here change.
  final OrionNavigationBarStyle? style;

  /// Fractional page while a finger is dragging a pager. Null lets the pill
  /// spring to [selectedIndex]. Do not feed this from a programmatic page
  /// animation, or a multi-tab jump will select the tabs in between.
  final double? dragPosition;

  /// Whether the capsule is shown. Hiding fades it, scales it to 0.98, and
  /// slides it down by 8 pt.
  final bool visible;

  /// Optional focus node for arrow-key movement.
  final FocusNode? focusNode;

  /// Whether the bar requests focus on first build.
  final bool autofocus;

  @override
  State<OrionNavigationBar> createState() => _OrionNavigationBarState();
}

class _OrionNavigationBarState extends State<OrionNavigationBar>
    with TickerProviderStateMixin {
  late final OrionSpringDriver _selection;
  late final OrionSpringDriver _visibility;

  /// Relaxes the displayed factors from the last pair flip to the new theory,
  /// so an interrupted jump hands over without a snap.
  late final AnimationController _relax;

  /// The factors the last hand-off started from, one per destination.
  late List<double> _blendFrom;
  late double _origin;
  bool _focused = false;
  bool _reduced = false;

  /// The capsule's minimum height; a label-less bar hugs its icons with the
  /// shorter one.
  static const double _defaultMinHeight = 64;
  static const double _iconOnlyMinHeight = 52;

  @override
  void initState() {
    super.initState();
    _origin = _selectionTarget;
    _selection = OrionSpringDriver(vsync: this, initialValue: _origin);
    _visibility = OrionSpringDriver(
      vsync: this,
      initialValue: widget.visible ? 1 : 0,
    );
    _relax = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1,
    );
    _blendFrom = _settledFactors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = _reduced && !_selection.reducedMotion;
    // Both travels are lateral or chrome; the drivers own reduced motion, so a
    // retarget settles in the same frame when the platform asked for none.
    _selection.reducedMotion = _reduced;
    _visibility.reducedMotion = _reduced;
    if (becameReduced) {
      _relax.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_selection.reducedMotion) {
          return;
        }
        _origin = _selectionTarget;
        _selection.jumpTo(_origin);
        _visibility.jumpTo(widget.visible ? 1 : 0);
      });
    }
  }

  @override
  void didUpdateWidget(OrionNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (_blendFrom.length != widget.destinations.length) {
      _blendFrom = _settledFactors();
      _relax.value = 1;
    }
    _syncSelection();
    _syncVisibility();
    if (oldWidget.visible && !widget.visible && _focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.visible) {
          FocusManager.instance.primaryFocus?.unfocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _relax.dispose();
    _selection.dispose();
    _visibility.dispose();
    super.dispose();
  }

  double get _selectionTarget {
    final double last = (widget.destinations.length - 1).toDouble();
    final double raw = widget.dragPosition ?? widget.selectedIndex.toDouble();
    return raw.clamp(0.0, math.max(0.0, last));
  }

  /// The relaxed progress the displayed factors blend by.
  double get _handoff => Curves.easeOutCubic.transform(_relax.value);

  List<double> _settledFactors() {
    final int count = widget.destinations.length;
    final List<double> factors = List<double>.filled(count, 0);
    final int index = widget.selectedIndex.clamp(0, math.max(0, count - 1));
    factors[index] = 1;
    return factors;
  }

  void _debugValidate() {
    assert(widget.destinations.length >= 2, 'at least two destinations');
    assert(
      widget.selectedIndex >= 0 &&
          widget.selectedIndex < widget.destinations.length,
      'selectedIndex must match a destination',
    );
  }

  OrionNavigationBarStyle _resolve(ThemeData theme) {
    final OrionNavigationTheme navigationTheme =
        theme.extension<OrionNavigationTheme>() ??
        OrionNavigationTheme.fallback;
    return OrionNavigationBarStyle.defaults(
      scheme: theme.colorScheme,
      labelStyle: theme.textTheme.labelSmall,
    ).merge(navigationTheme.defaultStyle).merge(widget.style);
  }

  void _syncMotion() {
    final OrionNavigationBarStyle style = _resolve(Theme.of(context));
    _selection.springSpec = style.selectionSpring ?? OrionSpringSpec.immediate;
    _visibility.springSpec =
        style.hideSpring ??
        const OrionSpringSpec(stiffness: 380, dampingRatio: 1);
  }

  void _syncSelection() {
    final double target = _selectionTarget;
    if (widget.dragPosition != null || _selection.reducedMotion) {
      _origin = target;
      _selection.jumpTo(target);
      return;
    }
    if (_selection.target == target) {
      return;
    }
    _captureHandoff();
    _origin = _selection.value;
    _selection.retarget(target);
  }

  /// Captures what is on screen and relaxes toward the new factor theory, so a
  /// pair flip - a retarget mid-jump, a new jump - cannot snap.
  void _captureHandoff() {
    final List<double> theory = <double>[
      for (var index = 0; index < widget.destinations.length; index++)
        _factor(index),
    ];
    final double handoff = _handoff;
    _blendFrom = <double>[
      for (var index = 0; index < theory.length; index++)
        _blendFrom[index] + (theory[index] - _blendFrom[index]) * handoff,
    ];
    if (_selection.reducedMotion) {
      _relax.value = 1;
    } else {
      _relax.forward(from: 0);
    }
  }

  void _syncVisibility() {
    final double target = widget.visible ? 1 : 0;
    if (_visibility.reducedMotion) {
      _visibility.jumpTo(target);
      return;
    }
    if (_visibility.target == target) {
      return;
    }
    _visibility.retarget(target);
  }

  void _select(int index, {required bool haptic}) {
    if (widget.onChanged == null) {
      return;
    }
    if (haptic) {
      OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
    }
    widget.onChanged!(index);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.visible || event is! KeyDownEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      _ => 0,
    };
    if (delta == 0) {
      return KeyEventResult.ignored;
    }
    final int next = widget.selectedIndex + delta;
    if (next < 0 || next >= widget.destinations.length) {
      return KeyEventResult.handled;
    }
    _select(next, haptic: false);
    return KeyEventResult.handled;
  }

  double _factor(int index) {
    final int last = widget.destinations.length - 1;
    final int from = _origin.round().clamp(0, last);
    final int to = _selection.target.round().clamp(0, last);
    final bool longJump = widget.dragPosition == null && (from - to).abs() > 1;
    if (!longJump) {
      final double distance = (index - _selection.value).abs();
      if (distance >= 1) {
        return 0;
      }
      return 1 - distance;
    }

    final double span = (to - from).toDouble();
    final double t = ((_selection.value - from) / span).clamp(0.0, 1.0);
    if (index == from) {
      return 1 - t;
    }
    if (index == to) {
      return t;
    }
    return 0;
  }

  double _labelWidth(String label, TextStyle style) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: Directionality.of(context),
      // The live layout applies the ambient text scale; the reserve must too,
      // or a scaled device overflows the measured room.
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  Widget _destinationButton(
    int index, {
    required double factor,
    required bool enabled,
    required TextStyle labelStyle,
    required double iconSize,
    required OrionNavigationBarStyle style,
    required ColorScheme scheme,
    required Color badgeRing,
    required EdgeInsets itemPadding,
    required OrionNavigationLabelMode labelMode,
    required double labelScale,
    required Color? pillColor,
    required BorderRadius pillRadius,
  }) {
    final OrionNavigationDestination destination = widget.destinations[index];
    final bool itemEnabled = enabled && widget.visible;
    final Set<WidgetState> statesOff = <WidgetState>{
      if (!itemEnabled) WidgetState.disabled,
    };
    final Set<WidgetState> statesOn = <WidgetState>{
      WidgetState.selected,
      if (!itemEnabled) WidgetState.disabled,
    };
    return _DestinationButton(
      destination: destination,
      factor: factor,
      selected: index == widget.selectedIndex,
      enabled: itemEnabled,
      labelStyle: labelStyle,
      iconSize: iconSize,
      scheme: scheme,
      colorOff:
          style.destinationColor?.resolve(statesOff) ?? scheme.onSurfaceVariant,
      colorOn: style.destinationColor?.resolve(statesOn) ?? scheme.primary,
      badgeStyle:
          style.badge ?? OrionNavigationBadgeStyle.defaults(scheme: scheme),
      badgeRing: badgeRing,
      itemPadding: itemPadding,
      labelMode: labelMode,
      labelScale: labelScale,
      pillColor: pillColor,
      pillRadius: pillRadius,
      reduced: _reduced,
      onTap: itemEnabled ? () => _select(index, haptic: true) : null,
      onLongPress: itemEnabled && widget.onLongPress != null
          ? () => widget.onLongPress!(index)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionNavigationBarStyle style = _resolve(theme);
    final bool enabled = widget.onChanged != null;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final TextStyle labelStyle =
        style.labelStyle ?? theme.textTheme.labelSmall ?? const TextStyle();
    final double iconSize = style.iconSize ?? 20;
    final OrionNavigationLabelMode labelMode =
        style.labelMode ?? OrionNavigationLabelMode.all;
    final Color background = style.background ?? scheme.surface;
    final Color hairline = style.borderColor ?? scheme.outlineVariant;
    final Color focusRing = style.focusRingColor ?? scheme.onSurface;
    final double hideSlide = style.hideSlide ?? 8;
    final double hideScale = style.hideScale ?? 0.98;
    final EdgeInsets padding =
        (style.padding ?? const EdgeInsets.all(OrionSpacing.space4)).resolve(
          Directionality.of(context),
        );
    final Color selectColor =
        style.selectionColor?.resolve(<WidgetState>{
          if (!enabled) WidgetState.disabled,
        }) ??
        scheme.onSurface.withValues(alpha: enabled ? 0.08 : 0.04);

    return Focus(
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: enabled && widget.visible,
      onFocusChange: (bool focused) {
        if (focused != _focused) {
          setState(() => _focused = focused);
        }
      },
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int count = widget.destinations.length;
          final bool labelled = labelMode == OrionNavigationLabelMode.all;
          final bool expands = labelMode == OrionNavigationLabelMode.selected;
          // The item's insets: a lone icon breathes more than a labelled one,
          // mostly sideways so the capsule stays dense vertically.
          final EdgeInsets itemPadding = labelled
              ? const EdgeInsets.all(OrionSpacing.space8)
              : const EdgeInsets.symmetric(
                  horizontal: OrionSpacing.space20,
                  vertical: OrionSpacing.space12,
                );
          final double maxWidth = style.maxWidth ?? 360;
          final double available = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : maxWidth;
          final double iconSlot = iconSize + itemPadding.horizontal;

          // The label allocation per destination in the expanding mode: the
          // gap, the label at the weight it will render at, and a hair of
          // slack so the live layout can never overflow the reserve.
          final TextStyle activeLabelStyle = labelStyle.copyWith(
            fontWeight: _activeWeight(labelStyle),
          );
          final List<double> labelAdds = expands
              ? <double>[
                  for (final OrionNavigationDestination destination
                      in widget.destinations)
                    OrionSpacing.space8 +
                        _labelWidth(destination.label, activeLabelStyle) +
                        1,
                ]
              : const <double>[];
          final double widest = labelAdds.isEmpty
              ? 0
              : labelAdds.reduce(math.max);

          // A labelled bar fills; an icon-only one hugs its icons; the
          // expanding one reserves a label's width so it never resizes with
          // the selection.
          final double naturalWidth = labelled
              ? maxWidth
              : padding.horizontal + count * iconSlot + widest;
          final double barWidth = labelled
              ? math.min(available, maxWidth)
              : math.min(available, math.min(maxWidth, naturalWidth));

          // How much of the reserved label room each slot may claim; below 1,
          // an unusually narrow window squeezes the labels proportionally.
          final double labelRoom =
              barWidth - padding.horizontal - count * iconSlot;
          final double labelScale = !expands || widest <= 0
              ? 1
              : (labelRoom / widest).clamp(0.0, 1.0);

          final double slotWidth = (barWidth - padding.horizontal) / count;
          final double direction =
              Directionality.of(context) == TextDirection.rtl ? -1 : 1;

          Widget button(int index, double factor) => _destinationButton(
            index,
            factor: factor,
            enabled: enabled,
            labelStyle: labelStyle,
            iconSize: iconSize,
            style: style,
            scheme: scheme,
            badgeRing: style.badge?.ringColor ?? background,
            itemPadding: itemPadding,
            labelMode: labelMode,
            labelScale: expands ? labelScale : 1,
            pillColor: expands ? selectColor : null,
            pillRadius: radius,
          );

          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: barWidth,
              child: AnimatedBuilder(
                animation: _visibility,
                builder: (BuildContext context, Widget? child) {
                  final double shown = _visibility.value.clamp(0.0, 1.0);
                  return IgnorePointer(
                    ignoring: !widget.visible,
                    child: ExcludeSemantics(
                      excluding: !widget.visible,
                      child: Opacity(
                        opacity: shown,
                        child: Transform.translate(
                          offset: Offset(0, (1 - shown) * hideSlide),
                          child: Transform.scale(
                            scale: hideScale + (1 - hideScale) * shown,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                // The chrome is static: it must not rebuild on selection
                // ticks. Only the stack below follows the drivers.
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: radius,
                    boxShadow: <BoxShadow>[
                      BoxShadow(
                        color: scheme.shadow.withValues(alpha: 0.14),
                        blurRadius: OrionSpacing.space24,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: radius,
                      border: Border.all(
                        color: _focused && enabled ? focusRing : hairline,
                        width: _focused && enabled ? 2 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: MouseRegion(
                        cursor: enabled
                            ? SystemMouseCursors.click
                            : MouseCursor.defer,
                        child: ConstrainedBox(
                          constraints: BoxConstraints(
                            minHeight:
                                style.minHeight ??
                                (labelled
                                    ? _defaultMinHeight
                                    : _iconOnlyMinHeight),
                          ),
                          child: Padding(
                            padding: padding,
                            child: AnimatedBuilder(
                              animation: Listenable.merge(<Listenable>[
                                _selection,
                                _relax,
                              ]),
                              builder: (BuildContext context, Widget? child) {
                                final double handoff = _handoff;
                                final List<double> factors = <double>[
                                  for (var index = 0; index < count; index++)
                                    _blendFrom[index] +
                                        (_factor(index) - _blendFrom[index]) *
                                            handoff,
                                ];
                                return Stack(
                                  children: <Widget>[
                                    // The expanding mode gives each slot its
                                    // own pill; the other modes share one
                                    // sliding pill.
                                    if (!expands)
                                      PositionedDirectional(
                                        start: 0,
                                        top: 0,
                                        bottom: 0,
                                        width: slotWidth,
                                        child: Transform.translate(
                                          offset: Offset(
                                            direction *
                                                _selection.value *
                                                slotWidth,
                                            0,
                                          ),
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              color: selectColor,
                                              borderRadius: radius,
                                            ),
                                          ),
                                        ),
                                      ),
                                    Row(
                                      // Centered, so a short label's reserved
                                      // slack splits evenly instead of all
                                      // landing past the last destination.
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: <Widget>[
                                        for (
                                          var index = 0;
                                          index < count;
                                          index++
                                        )
                                          if (expands)
                                            SizedBox(
                                              width:
                                                  iconSlot +
                                                  labelAdds[index] *
                                                      factors[index] *
                                                      labelScale,
                                              child: button(
                                                index,
                                                factors[index],
                                              ),
                                            )
                                          else
                                            Expanded(
                                              child: button(
                                                index,
                                                factors[index],
                                              ),
                                            ),
                                      ],
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DestinationButton extends StatelessWidget {
  const _DestinationButton({
    required this.destination,
    required this.factor,
    required this.selected,
    required this.enabled,
    required this.labelStyle,
    required this.iconSize,
    required this.scheme,
    required this.colorOff,
    required this.colorOn,
    required this.badgeStyle,
    required this.badgeRing,
    required this.itemPadding,
    required this.labelMode,
    required this.labelScale,
    required this.pillColor,
    required this.pillRadius,
    required this.reduced,
    required this.onTap,
    required this.onLongPress,
  });

  final OrionNavigationDestination destination;
  final double factor;
  final bool selected;
  final bool enabled;
  final TextStyle labelStyle;
  final double iconSize;
  final ColorScheme scheme;
  final Color colorOff;
  final Color colorOn;
  final OrionNavigationBadgeStyle badgeStyle;
  final Color badgeRing;
  final EdgeInsets itemPadding;
  final OrionNavigationLabelMode labelMode;
  final double labelScale;
  final Color? pillColor;
  final BorderRadius pillRadius;
  final bool reduced;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final OrionThemeData orion = OrionTheme.of(context);
    // The layout follows the selection factor whatever the interactivity: a
    // disabled bar mutes through the resolved colours, it does not drop its
    // labels, its pill, or its slot widths.
    final double shown = factor.clamp(0.0, 1.0);
    final Color foreground = Color.lerp(colorOff, colorOn, shown) ?? colorOff;
    final FontWeight baseWeight = labelStyle.fontWeight ?? FontWeight.w500;
    final FontWeight weight =
        FontWeight.lerp(baseWeight, _activeWeight(labelStyle), shown) ??
        baseWeight;
    final Set<WidgetState> badgeStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (selected) WidgetState.selected,
    };
    final bool alwaysLabels = labelMode == OrionNavigationLabelMode.all;
    final bool expands = labelMode == OrionNavigationLabelMode.selected;
    final bool labelVisible = alwaysLabels || (expands && shown > 0);

    final Widget iconStack = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        IconTheme.merge(
          data: IconThemeData(color: foreground, size: iconSize),
          child: destination.icon,
        ),
        PositionedDirectional(
          top: -6,
          end: -8,
          child: _NavigationBadge(
            badge: destination.badge,
            reduced: reduced,
            fill: badgeStyle.fill?.resolve(badgeStates) ?? scheme.primary,
            ink: badgeStyle.ink?.resolve(badgeStates) ?? scheme.onPrimary,
            textStyle: badgeStyle.textStyle ?? labelStyle,
            height: badgeStyle.height ?? 16,
            minWidth: badgeStyle.minWidth ?? 16,
            padding:
                badgeStyle.padding ??
                const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
            ring: badgeRing,
          ),
        ),
      ],
    );
    final Widget label = Text(
      destination.label,
      maxLines: 1,
      softWrap: false,
      overflow: TextOverflow.fade,
      textAlign: TextAlign.center,
      style: labelStyle.copyWith(color: foreground, fontWeight: weight),
    );

    final Widget content;
    if (alwaysLabels) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconStack,
          const SizedBox(height: OrionSpacing.space4),
          label,
        ],
      );
    } else if (expands) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconStack,
          // The label's room follows the selection factor, so the slot grows
          // into the label and the text arrives with it.
          if (shown > 0)
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: shown * labelScale,
                // Without it the align expands to the incoming max height and
                // the whole capsule stretches with it.
                heightFactor: 1,
                child: Opacity(
                  opacity: shown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      const SizedBox(width: OrionSpacing.space8),
                      label,
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      content = iconStack;
    }

    final Widget body = Padding(
      padding: itemPadding,
      child: Transform.scale(scale: 0.98 + (0.02 * shown), child: content),
    );
    // The expanding mode gives each slot its own pill, fading with the
    // selection factor; the other modes leave the pill to the bar.
    final Widget slot = pillColor == null
        ? body
        : DecoratedBox(
            decoration: BoxDecoration(
              color: Color.lerp(Colors.transparent, pillColor, shown),
              borderRadius: pillRadius,
            ),
            child: body,
          );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      // A destination whose label is not on screen keeps its spoken name; one
      // that shows its label would otherwise announce it twice.
      label: labelVisible ? null : destination.label,
      child: OrionPressable(
        onTap: onTap,
        onLongPress: onLongPress,
        pressedScale: orion.pressScale,
        springSpec: orion.pressSpring,
        releaseSpringSpec: orion.releaseSpring,
        hapticType: OrionHapticType.none,
        // The reference's tab bar fires no haptic on a long press, so the
        // pressable's impact default is silenced too.
        impactHapticType: OrionHapticType.none,
        child: slot,
      ),
    );
  }
}

/// The destination badge: a chip at the icon's top-right, ringed in the bar's
/// own surface so it reads as cut out of the icon beneath it. It scales in
/// when it appears, keeps its chip mounted while it scales out, and lands
/// instantly under reduced motion.
class _NavigationBadge extends StatefulWidget {
  const _NavigationBadge({
    required this.badge,
    required this.reduced,
    required this.fill,
    required this.ink,
    required this.textStyle,
    required this.height,
    required this.minWidth,
    required this.padding,
    required this.ring,
  });

  final Widget? badge;
  final bool reduced;
  final Color fill;
  final Color ink;
  final TextStyle textStyle;
  final double height;
  final double minWidth;
  final EdgeInsetsGeometry padding;
  final Color ring;

  @override
  State<_NavigationBadge> createState() => _NavigationBadgeState();
}

class _NavigationBadgeState extends State<_NavigationBadge> {
  /// The last presented badge content, kept mounted while the chip scales out
  /// so a dismissal animates instead of vanishing.
  Widget? _last;

  @override
  void initState() {
    super.initState();
    _last = widget.badge;
  }

  @override
  void didUpdateWidget(_NavigationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badge != null) {
      _last = widget.badge;
    }
  }

  Widget _chip(Widget content) {
    return Container(
      constraints: BoxConstraints(
        minWidth: widget.minWidth,
        minHeight: widget.height,
      ),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.fill,
        borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
        border: Border.all(color: widget.ring, width: 1.33),
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: DefaultTextStyle(
          style: widget.textStyle.copyWith(color: widget.ink),
          child: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool present = widget.badge != null;
    final Widget? content = widget.badge ?? _last;
    if (widget.reduced) {
      return present && content != null
          ? _chip(content)
          : const SizedBox.shrink();
    }
    final Widget chip = content == null
        ? const SizedBox.shrink()
        : _chip(content);
    // An implicit scale cannot animate a badge that is not there, so the
    // wrapper stays mounted and the chip rides the scale in and out.
    return AnimatedScale(
      scale: present ? 1 : 0,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      onEnd: () {
        if (!present && _last != null) {
          setState(() => _last = null);
        }
      },
      child: chip,
    );
  }
}
