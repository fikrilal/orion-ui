import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  const OrionNavigationDestination({required this.icon, required this.label});

  /// Icon shown above [label]. It inherits the destination color.
  final Widget icon;

  /// Short name of the destination.
  final String label;
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
class OrionNavigationBar extends StatefulWidget {
  /// Creates a controlled navigation bar.
  const OrionNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onChanged,
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
  static const double _maxWidth = 360;
  static const double _minHeight = 64;
  static const double _hideSlide = 8;
  static const double _hideScale = 0.98;

  /// Hide must settle without ringing back into view.
  static const OrionSpringSpec _hideMotion = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  late final OrionSpringDriver _selection;
  late final OrionSpringDriver _visibility;
  late double _origin;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _origin = _selectionTarget;
    _selection = OrionSpringDriver(vsync: this, initialValue: _origin);
    _visibility = OrionSpringDriver(
      vsync: this,
      initialValue: widget.visible ? 1 : 0,
      springSpec: _hideMotion,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // The selection indicator travels between destinations. The theme's press spring is
    // zeta 0.36, which overshoots a lateral move by nearly a third and reads as a wobble
    // past the destination, so travel runs on the immediate spec instead.
    _selection.springSpec = OrionSpringSpec.immediate;
    final bool becameReduced = reduce && !_selection.reducedMotion;
    _selection.reducedMotion = reduce;
    _visibility.reducedMotion = reduce;
    if (becameReduced) {
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
    _selection.dispose();
    _visibility.dispose();
    super.dispose();
  }

  double get _selectionTarget {
    final double last = (widget.destinations.length - 1).toDouble();
    final double raw = widget.dragPosition ?? widget.selectedIndex.toDouble();
    return raw.clamp(0.0, math.max(0.0, last));
  }

  void _debugValidate() {
    assert(widget.destinations.length >= 2, 'at least two destinations');
    assert(
      widget.selectedIndex >= 0 &&
          widget.selectedIndex < widget.destinations.length,
      'selectedIndex must match a destination',
    );
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
    _origin = _selection.value;
    _selection.retarget(target);
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

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = widget.onChanged != null;
    final BorderRadius radius = BorderRadius.circular(OrionRadii.radiusPill);
    final TextStyle textStyle = theme.textTheme.labelSmall ?? const TextStyle();
    final Color hairline = scheme.outlineVariant.a < 1
        ? scheme.outlineVariant
        : scheme.outlineVariant.withValues(alpha: 0.22);

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
          final double barWidth = constraints.hasBoundedWidth
              ? math.min(constraints.maxWidth, _maxWidth)
              : _maxWidth;
          final double slotWidth =
              (barWidth - OrionSpacing.space4 * 2) / widget.destinations.length;
          final double direction =
              Directionality.of(context) == TextDirection.rtl ? -1 : 1;
          return Align(
            alignment: Alignment.bottomCenter,
            child: SizedBox(
              width: barWidth,
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[
                  _selection,
                  _visibility,
                ]),
                builder: (BuildContext context, Widget? child) {
                  final double shown = _visibility.value.clamp(0.0, 1.0);
                  return IgnorePointer(
                    ignoring: !widget.visible,
                    child: ExcludeSemantics(
                      excluding: !widget.visible,
                      child: Opacity(
                        opacity: shown,
                        child: Transform.translate(
                          offset: Offset(0, (1 - shown) * _hideSlide),
                          child: Transform.scale(
                            scale: _hideScale + (1 - _hideScale) * shown,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                borderRadius: radius,
                                boxShadow: <BoxShadow>[
                                  BoxShadow(
                                    color: scheme.shadow.withValues(
                                      alpha: 0.14,
                                    ),
                                    blurRadius: OrionSpacing.space24,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: scheme.surface,
                                  borderRadius: radius,
                                  border: Border.all(
                                    color: _focused && enabled
                                        ? scheme.onSurface
                                        : hairline,
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
                                      constraints: const BoxConstraints(
                                        minHeight: _minHeight,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(
                                          OrionSpacing.space4,
                                        ),
                                        child: Stack(
                                          children: <Widget>[
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
                                                    color: scheme.onSurface
                                                        .withValues(
                                                          alpha: enabled
                                                              ? 0.08
                                                              : 0.04,
                                                        ),
                                                    borderRadius: radius,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            Row(
                                              children: <Widget>[
                                                for (
                                                  var index = 0;
                                                  index <
                                                      widget
                                                          .destinations
                                                          .length;
                                                  index++
                                                )
                                                  Expanded(
                                                    child: _DestinationButton(
                                                      destination: widget
                                                          .destinations[index],
                                                      factor: _factor(index),
                                                      selected:
                                                          index ==
                                                          widget.selectedIndex,
                                                      enabled:
                                                          enabled &&
                                                          widget.visible,
                                                      textStyle: textStyle,
                                                      scheme: scheme,
                                                      onTap:
                                                          enabled &&
                                                              widget.visible
                                                          ? () => _select(
                                                              index,
                                                              haptic: true,
                                                            )
                                                          : null,
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
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
    required this.textStyle,
    required this.scheme,
    required this.onTap,
  });

  static const double _iconSize = 20;

  final OrionNavigationDestination destination;
  final double factor;
  final bool selected;
  final bool enabled;
  final TextStyle textStyle;
  final ColorScheme scheme;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final OrionThemeData orion = OrionTheme.of(context);
    final double shown = enabled ? factor.clamp(0.0, 1.0) : 0;
    final Color foreground = enabled
        ? Color.lerp(scheme.onSurfaceVariant, scheme.primary, shown)!
        : scheme.onSurface.withValues(alpha: 0.38);
    final FontWeight weight =
        FontWeight.lerp(FontWeight.w500, FontWeight.w700, shown) ??
        FontWeight.w500;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: OrionPressable(
        onTap: onTap,
        pressedScale: orion.pressScale,
        springSpec: orion.pressSpring,
        releaseSpringSpec: orion.releaseSpring,
        hapticType: OrionHapticType.none,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OrionSpacing.space8,
            vertical: OrionSpacing.space8,
          ),
          child: Transform.scale(
            scale: 0.98 + (0.02 * shown),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconTheme.merge(
                  data: IconThemeData(color: foreground, size: _iconSize),
                  child: destination.icon,
                ),
                const SizedBox(height: OrionSpacing.space4),
                Text(
                  destination.label,
                  maxLines: 1,
                  softWrap: false,
                  overflow: TextOverflow.fade,
                  textAlign: TextAlign.center,
                  style: textStyle.copyWith(
                    color: foreground,
                    fontWeight: weight,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
