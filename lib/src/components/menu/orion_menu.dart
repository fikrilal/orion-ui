import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/menu/orion_menu_item.dart';
import 'package:orion_ui/src/components/popover/orion_popover.dart';
import 'package:orion_ui/src/components/popover/orion_popover_controller.dart';
import 'package:orion_ui/src/components/popover/orion_popover_geometry.dart';
import 'package:orion_ui/src/components/popover/orion_popover_presets.dart';
import 'package:orion_ui/src/components/popover/orion_popover_style.dart';
import 'package:orion_ui/src/components/popover/orion_popover_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

int _nextInteractiveIndex(
  List<OrionMenuItem> items,
  int current, {
  required int step,
}) {
  if (items.isEmpty) return -1;
  final int count = items.length;
  int index = current;
  for (int tries = 0; tries < count; tries++) {
    if (index < 0 || index >= count) {
      index = step > 0 ? 0 : count - 1;
    } else {
      index = (index + step + count) % count;
    }
    if (items[index].isInteractive) {
      return index;
    }
  }
  return -1;
}

int _edgeInteractiveIndex(List<OrionMenuItem> items, {required bool fromStart}) {
  if (fromStart) {
    for (int i = 0; i < items.length; i++) {
      if (items[i].isInteractive) return i;
    }
  } else {
    for (int i = items.length - 1; i >= 0; i--) {
      if (items[i].isInteractive) return i;
    }
  }
  return -1;
}

/// A tactile, anchored dropdown menu component.
///
/// Wraps an [OrionPopover] with structured [OrionMenuItem] rows, hover/pressed
/// pill highlights, tactile [OrionPressable] feedback, destructive styling,
/// section headers, selected checkmarks, full keyboard navigation, and
/// optional cascading entry.
class OrionMenu extends StatefulWidget {
  const OrionMenu({
    super.key,
    this.trigger,
    this.triggerBuilder,
    required this.items,
    this.placement = OrionPopoverPlacement.bottomStart,
    this.style,
    this.controller,
    this.showArrow,
    this.autoFlip = true,
    this.cascade = false,
    this.dismissOnScroll = true,
    this.onOpen,
    this.onClose,
  }) : assert(
         trigger != null || triggerBuilder != null,
         'Either trigger or triggerBuilder must be provided',
       );

  /// The trigger widget that opens this menu when tapped.
  final Widget? trigger;

  /// Optional trigger builder receiving the popover's [OrionPopoverController].
  final OrionPopoverTriggerBuilder? triggerBuilder;

  /// The ordered list of menu items, headers, and dividers to render.
  final List<OrionMenuItem> items;

  /// Preferred placement relative to the trigger.
  final OrionPopoverPlacement placement;

  /// Style overrides for the popover container.
  final OrionPopoverStyle? style;

  /// Optional programmatic controller.
  final OrionPopoverController? controller;

  /// Whether to show the pointed caret arrow toward the trigger.
  final bool? showArrow;

  /// Whether to auto-flip if constrained by screen boundaries.
  final bool autoFlip;

  /// Whether menu items enter with a staggered cascading reveal animation.
  final bool cascade;

  /// Whether scrolling ancestor scrollables or dragging outside dismisses the menu.
  final bool dismissOnScroll;

  /// Callback invoked when the menu starts opening.
  final VoidCallback? onOpen;

  /// Callback invoked when the menu finishes closing.
  final VoidCallback? onClose;

  @override
  State<OrionMenu> createState() => _OrionMenuState();
}

class _OrionMenuState extends State<OrionMenu> {
  final GlobalKey<OrionPopoverState> _popoverKey =
      GlobalKey<OrionPopoverState>();
  final ValueNotifier<int> _highlightedIndex = ValueNotifier<int>(-1);

  OrionPopoverController? _internalController;
  OrionPopoverController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionPopoverController());

  @override
  void dispose() {
    _highlightedIndex.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _activateItem(OrionMenuItem item) {
    if (!item.isInteractive) return;
    if (item.closeOnTap) {
      _effectiveController.hide();
    }
    item.onTap?.call();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _highlightedIndex.value = _nextInteractiveIndex(
        widget.items,
        _highlightedIndex.value,
        step: 1,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _highlightedIndex.value = _nextInteractiveIndex(
        widget.items,
        _highlightedIndex.value,
        step: -1,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _highlightedIndex.value = _edgeInteractiveIndex(
        widget.items,
        fromStart: true,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _highlightedIndex.value = _edgeInteractiveIndex(
        widget.items,
        fromStart: false,
      );
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space) &&
        event is KeyDownEvent) {
      final int idx = _highlightedIndex.value;
      if (idx >= 0 && idx < widget.items.length) {
        _activateItem(widget.items[idx]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    return OrionPopover(
      key: _popoverKey,
      controller: _effectiveController,
      placement: widget.placement,
      style: widget.style,
      showArrow: widget.showArrow,
      autoFlip: widget.autoFlip,
      dismissOnScroll: widget.dismissOnScroll,
      onKeyEvent: _handleKeyEvent,
      onOpen: () {
        _highlightedIndex.value = -1;
        widget.onOpen?.call();
      },
      onClose: () {
        _highlightedIndex.value = -1;
        widget.onClose?.call();
      },
      trigger: widget.trigger,
      triggerBuilder: widget.triggerBuilder,
      builder: (BuildContext context, OrionSpringDriver driver) {
        final OrionPopoverState? popoverState = _popoverKey.currentState;
        return ValueListenableBuilder<int>(
          valueListenable: _highlightedIndex,
          builder: (BuildContext context, int highlighted, Widget? _) {
            return OrionMenuList(
              items: widget.items,
              cascade: widget.cascade,
              animation: driver,
              isClosing: popoverState?.isClosing ?? false,
              isTopPlacement: popoverState?.resolvedLayout?.isTop ?? false,
              highlightedIndex: highlighted,
              onHoverIndexChanged: (int idx) {
                if (_highlightedIndex.value != idx) {
                  _highlightedIndex.value = idx;
                }
              },
              onItemSelected: (dynamic _) {},
              onItemActivated: _activateItem,
            );
          },
        );
      },
    );
  }
}

/// The scrollable body content list rendering a column of [OrionMenuItem]s.
class OrionMenuList extends StatelessWidget {
  const OrionMenuList({
    super.key,
    required this.items,
    this.onItemSelected,
    this.onItemActivated,
    this.cascade = false,
    this.animation,
    this.isClosing = false,
    this.isTopPlacement = false,
    this.highlightedIndex = -1,
    this.onHoverIndexChanged,
  });

  /// The list of items, headers, and dividers to render.
  final List<OrionMenuItem> items;

  /// Callback when any actionable item is tapped, passing optional item value.
  final ValueChanged<dynamic>? onItemSelected;

  /// Optional item-level activation handler (receives full [OrionMenuItem]).
  /// When provided, replaces default `onItemSelected` + `item.onTap` dispatch.
  final ValueChanged<OrionMenuItem>? onItemActivated;

  /// Whether items enter with cascading animation.
  final bool cascade;

  /// Optional parent animation driving cascading item entrance.
  final Animation<double>? animation;

  /// Whether the enclosing popover/menu is currently animating closed.
  final bool isClosing;

  /// Whether the enclosing menu opened above its trigger (reverses cascade slide).
  final bool isTopPlacement;

  /// Index currently highlighted by keyboard navigation or pointer hover.
  final int highlightedIndex;

  /// Optional callback fired when pointer hover enters or leaves an item row.
  final ValueChanged<int>? onHoverIndexChanged;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final List<Widget> children = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      final OrionMenuItem item = items[i];

      if (item.isDivider) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: OrionSpacing.space4,
              vertical: OrionSpacing.space4,
            ),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
              color: scheme.outlineVariant,
            ),
          ),
        );
        continue;
      }

      if (item.isHeader) {
        children.add(
          Padding(
            padding: EdgeInsets.fromLTRB(
              OrionSpacing.space12,
              i == 0 ? OrionSpacing.space4 : OrionSpacing.space8,
              OrionSpacing.space12,
              OrionSpacing.space4,
            ),
            child: Text(
              item.title,
              style: TextStyle(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.4,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        );
        continue;
      }

      final Widget row = _OrionMenuItemRow(
        item: item,
        index: i,
        cascade: cascade && !isClosing,
        isTopPlacement: isTopPlacement,
        animation: animation,
        highlighted: i == highlightedIndex,
        onHoverChanged: (bool hovered) {
          if (onHoverIndexChanged == null) return;
          if (hovered) {
            onHoverIndexChanged!(i);
          } else if (highlightedIndex == i) {
            onHoverIndexChanged!(-1);
          }
        },
        onTap: () {
          if (onItemActivated != null) {
            onItemActivated!(item);
          } else {
            onItemSelected?.call(item.value);
            item.onTap?.call();
          }
        },
      );

      children.add(row);
    }

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }
}

class _OrionMenuItemRow extends StatefulWidget {
  const _OrionMenuItemRow({
    required this.item,
    required this.onTap,
    this.index = 0,
    this.cascade = false,
    this.isTopPlacement = false,
    this.animation,
    this.highlighted = false,
    this.onHoverChanged,
  });

  final OrionMenuItem item;
  final VoidCallback onTap;
  final int index;
  final bool cascade;
  final bool isTopPlacement;
  final Animation<double>? animation;
  final bool highlighted;
  final ValueChanged<bool>? onHoverChanged;

  @override
  State<_OrionMenuItemRow> createState() => _OrionMenuItemRowState();
}

class _OrionMenuItemRowState extends State<_OrionMenuItemRow> {
  bool _hovered = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final OrionMenuItem item = widget.item;

    final Color foregroundColor;
    if (!item.enabled) {
      foregroundColor = scheme.onSurface.withValues(alpha: 0.38);
    } else if (item.destructive) {
      foregroundColor = scheme.error;
    } else {
      foregroundColor = scheme.onSurface;
    }

    final Color subtitleColor = item.enabled
        ? (item.destructive
              ? scheme.error.withValues(alpha: 0.75)
              : scheme.onSurfaceVariant)
        : scheme.onSurface.withValues(alpha: 0.38);

    final bool activeHighlight = item.enabled && (_hovered || widget.highlighted);
    final bool activePress = item.enabled && _pressed;

    final Color rowBackground;
    if (activePress) {
      rowBackground = item.destructive
          ? scheme.error.withValues(alpha: isDark ? 0.22 : 0.14)
          : scheme.onSurface.withValues(alpha: isDark ? 0.13 : 0.095);
    } else if (activeHighlight) {
      rowBackground = item.destructive
          ? scheme.error.withValues(alpha: isDark ? 0.14 : 0.08)
          : scheme.onSurface.withValues(alpha: isDark ? 0.08 : 0.055);
    } else {
      rowBackground = Colors.transparent;
    }

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space12,
        vertical: OrionSpacing.space8,
      ),
      child: Row(
        children: <Widget>[
          if (item.leading != null) ...<Widget>[
            IconTheme(
              data: IconThemeData(color: foregroundColor, size: 18.0),
              child: item.leading!,
            ),
            const SizedBox(width: OrionSpacing.space12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: item.selected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
                if (item.subtitle != null) ...<Widget>[
                  const SizedBox(height: 2.0),
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      fontSize: 12.0,
                      fontWeight: FontWeight.w400,
                      color: subtitleColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (item.trailing != null) ...<Widget>[
            const SizedBox(width: OrionSpacing.space8),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
                color: subtitleColor,
              ),
              child: IconTheme(
                data: IconThemeData(color: subtitleColor, size: 16.0),
                child: item.trailing!,
              ),
            ),
          ],
          if (item.selected) ...<Widget>[
            const SizedBox(width: OrionSpacing.space8),
            Icon(
              Icons.check_rounded,
              size: 16.0,
              color: item.enabled
                  ? (item.destructive ? scheme.error : scheme.primary)
                  : scheme.onSurface.withValues(alpha: 0.38),
            ),
          ],
        ],
      ),
    );

    final Widget rowContent = Semantics(
      container: true,
      button: true,
      enabled: item.enabled,
      selected: item.selected,
      child: MouseRegion(
        onEnter: (_) {
          if (!item.enabled) return;
          if (!_hovered) setState(() => _hovered = true);
          widget.onHoverChanged?.call(true);
        },
        onExit: (_) {
          if (_hovered) setState(() => _hovered = false);
          widget.onHoverChanged?.call(false);
        },
        child: OrionPressable(
          pressedScale: orion.pressScale,
          springSpec: orion.pressSpring,
          releaseSpringSpec: orion.releaseSpring,
          onTap: item.enabled ? widget.onTap : null,
          hapticType: orion.selectionHaptic,
          onPressedChanged: item.enabled
              ? (bool pressed) {
                  if (_pressed != pressed) {
                    setState(() => _pressed = pressed);
                  }
                }
              : null,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: rowBackground,
              borderRadius: BorderRadius.circular(OrionRadii.radius8),
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 44.0),
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                child: content,
              ),
            ),
          ),
        ),
      ),
    );

    if (!widget.cascade || widget.animation == null) {
      return rowContent;
    }

    return AnimatedBuilder(
      animation: widget.animation!,
      child: rowContent,
      builder: (BuildContext context, Widget? child) {
        final double t = widget.animation!.value;
        final double stagger = (widget.index * 0.04).clamp(0.0, 0.35);
        final double itemProgress = ((t - stagger) / (1.0 - stagger)).clamp(
          0.0,
          1.0,
        );
        final double itemTranslateY =
            (1.0 - itemProgress) * (widget.isTopPlacement ? 4.0 : -4.0);
        final double itemOpacity = (itemProgress * 1.8).clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, itemTranslateY),
          child: Opacity(opacity: itemOpacity, child: child),
        );
      },
    );
  }
}

/// Imperatively presents an anchored menu on the navigator stack.
Future<T?> showOrionMenu<T>({
  required BuildContext context,
  required Rect anchorRect,
  required List<OrionMenuItem> items,
  OrionPopoverPlacement placement = OrionPopoverPlacement.bottomStart,
  OrionPopoverStyle? style,
  bool showArrow = false,
  bool autoFlip = true,
  bool cascade = false,
  bool dismissOnScroll = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _OrionMenuRoute<T>(
      anchorRect: anchorRect,
      items: items,
      placement: placement,
      style: style,
      showArrow: showArrow,
      autoFlip: autoFlip,
      cascade: cascade,
      dismissOnScroll: dismissOnScroll,
      settings: routeSettings,
    ),
  );
}

class _OrionMenuRoute<T> extends PopupRoute<T> {
  _OrionMenuRoute({
    required this.anchorRect,
    required this.items,
    required this.placement,
    required this.style,
    required this.showArrow,
    required this.autoFlip,
    this.cascade = false,
    this.dismissOnScroll = true,
    super.settings,
  });

  final Rect anchorRect;
  final List<OrionMenuItem> items;
  final OrionPopoverPlacement placement;
  final OrionPopoverStyle? style;
  final bool showArrow;
  final bool autoFlip;
  final bool cascade;
  final bool dismissOnScroll;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss menu';

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _OrionModalMenuOverlay<T>(
      route: this,
      anchorRect: anchorRect,
      items: items,
      placement: placement,
      style: style,
      showArrow: showArrow,
      autoFlip: autoFlip,
      cascade: cascade,
      dismissOnScroll: dismissOnScroll,
    );
  }
}

class _OrionModalMenuOverlay<T> extends StatefulWidget {
  const _OrionModalMenuOverlay({
    required this.route,
    required this.anchorRect,
    required this.items,
    required this.placement,
    required this.style,
    required this.showArrow,
    required this.autoFlip,
    this.cascade = false,
    this.dismissOnScroll = true,
  });

  final _OrionMenuRoute<T> route;
  final Rect anchorRect;
  final List<OrionMenuItem> items;
  final OrionPopoverPlacement placement;
  final OrionPopoverStyle? style;
  final bool showArrow;
  final bool autoFlip;
  final bool cascade;
  final bool dismissOnScroll;

  @override
  State<_OrionModalMenuOverlay<T>> createState() =>
      _OrionModalMenuOverlayState<T>();
}

class _OrionModalMenuOverlayState<T> extends State<_OrionModalMenuOverlay<T>>
    with SingleTickerProviderStateMixin {
  final GlobalKey _panelKey = GlobalKey();
  final ValueNotifier<int> _highlightedIndex = ValueNotifier<int>(-1);
  late final OrionSpringDriver _driver;
  OrionPopoverResolvedLayout? _resolvedLayout;
  bool _isClosing = false;
  bool _didStart = false;
  T? _dismissResult;
  ScrollNotificationObserverState? _scrollNotificationObserver;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: const OrionSpringSpec(stiffness: 520.0, dampingRatio: 0.86),
    );
    _driver.addListener(_onDriverTick);
    _driver.addStatusListener(_onDriverStatus);
  }

  OrionPopoverStyle _resolveStyle(ThemeData theme) {
    final OrionPopoverTheme popoverTheme =
        theme.extension<OrionPopoverTheme>() ?? OrionPopoverTheme.fallback;
    return OrionPopoverPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(popoverTheme.defaultStyle).merge(widget.style);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.reducedMotion = reduced;

    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);

    if (!_didStart) {
      _didStart = true;
      final OrionPopoverStyle style = _resolveStyle(Theme.of(context));
      if (reduced) {
        _driver.jumpTo(1.0);
      } else {
        _driver.springSpec =
            style.springSpec ??
            const OrionSpringSpec(stiffness: 520.0, dampingRatio: 0.86);
        _driver.retarget(1.0);
        OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
      }
    }
  }

  @override
  void dispose() {
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
    _highlightedIndex.dispose();
    _driver.removeListener(_onDriverTick);
    _driver.removeStatusListener(_onDriverStatus);
    _driver.dispose();
    super.dispose();
  }

  bool _isInsideMenu(BuildContext notifContext) {
    if (!notifContext.mounted) return false;
    final BuildContext? panelContext = _panelKey.currentContext;
    if (panelContext == null || !panelContext.mounted) return false;
    final RenderObject? panelRenderObject = panelContext.findRenderObject();
    if (panelRenderObject == null) return false;
    final RenderObject? notifRenderObject = notifContext.findRenderObject();
    if (notifRenderObject == null) return false;

    RenderObject? current = notifRenderObject;
    while (current != null) {
      if (current == panelRenderObject) return true;
      current = current.parent;
    }
    return false;
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (!widget.dismissOnScroll || _isClosing) return;

    final BuildContext? notifContext = notification.context;
    if (notifContext != null && _isInsideMenu(notifContext)) {
      return;
    }

    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0.0) {
      _dismiss();
    } else if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dismiss();
    }
  }

  void _finishPop() {
    if (!mounted) return;
    _driver.stop();
    if (widget.route.isCurrent) {
      Navigator.of(context).pop(_dismissResult);
    }
  }

  void _onDriverTick() {
    if (_isClosing && _driver.value <= 0.02) {
      _finishPop();
    }
  }

  void _onDriverStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.02) {
      _finishPop();
    }
  }

  void _dismiss([T? result]) {
    if (_isClosing) return;
    _isClosing = true;
    _dismissResult = result;

    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      _finishPop();
      return;
    }

    final OrionPopoverStyle style = _resolveStyle(Theme.of(context));
    _driver.springSpec =
        style.dismissSpringSpec ??
        const OrionSpringSpec(
          stiffness: 620.0,
          dampingRatio: 1.0,
          clampOvershoot: true,
        );
    _driver.retarget(0.0);
    if (mounted) {
      setState(() {});
    }
  }

  void _activateItem(OrionMenuItem item) {
    if (!item.isInteractive) return;
    final T? typedValue = item.value is T ? item.value as T : null;
    if (item.closeOnTap) {
      _dismiss(typedValue);
    }
    item.onTap?.call();
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.escape && event is KeyDownEvent) {
      _dismiss();
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      _highlightedIndex.value = _nextInteractiveIndex(
        widget.items,
        _highlightedIndex.value,
        step: 1,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _highlightedIndex.value = _nextInteractiveIndex(
        widget.items,
        _highlightedIndex.value,
        step: -1,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _highlightedIndex.value = _edgeInteractiveIndex(
        widget.items,
        fromStart: true,
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _highlightedIndex.value = _edgeInteractiveIndex(
        widget.items,
        fromStart: false,
      );
      return KeyEventResult.handled;
    }
    if ((key == LogicalKeyboardKey.enter ||
            key == LogicalKeyboardKey.numpadEnter ||
            key == LogicalKeyboardKey.space) &&
        event is KeyDownEvent) {
      final int idx = _highlightedIndex.value;
      if (idx >= 0 && idx < widget.items.length) {
        _activateItem(widget.items[idx]);
        return KeyEventResult.handled;
      }
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orionTheme = OrionTheme.of(context);
    final OrionPopoverStyle resolvedStyle = _resolveStyle(theme);
    final TextDirection textDirection = Directionality.of(context);

    final Size arrowSize = resolvedStyle.arrowSize ?? const Size(14.0, 7.0);
    final double gap = resolvedStyle.gap ?? 8.0;
    final Size viewportSize = MediaQuery.sizeOf(context);
    final EdgeInsets viewportPadding = resolveOrionPopoverViewportPadding(
      context,
    );

    final Size estimatedSize = Size(
      resolvedStyle.minWidth ?? 140.0,
      resolvedStyle.minHeight ?? 120.0,
    );
    _resolvedLayout ??= OrionPopoverGeometry.resolve(
      triggerRect: widget.anchorRect,
      popoverSize: estimatedSize,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: widget.placement,
      gap: gap,
      autoFlip: widget.autoFlip,
      showArrow: widget.showArrow,
      arrowSize: arrowSize,
      textDirection: textDirection,
    );

    final Widget panel = OrionPopoverSurface(
      panelKey: _panelKey,
      style: resolvedStyle,
      scheme: scheme,
      orionTheme: orionTheme,
      showArrow: widget.showArrow,
      triggerRect: widget.anchorRect,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: widget.placement,
      autoFlip: widget.autoFlip,
      textDirection: textDirection,
      child: ValueListenableBuilder<int>(
        valueListenable: _highlightedIndex,
        builder: (BuildContext context, int highlighted, Widget? _) {
          return OrionMenuList(
            items: widget.items,
            cascade: widget.cascade,
            animation: _driver,
            isClosing: _isClosing,
            isTopPlacement: _resolvedLayout?.isTop ?? false,
            highlightedIndex: highlighted,
            onHoverIndexChanged: (int idx) {
              if (_highlightedIndex.value != idx) {
                _highlightedIndex.value = idx;
              }
            },
            onItemActivated: _activateItem,
          );
        },
      ),
    );

    return Focus(
      autofocus: !_isClosing,
      onKeyEvent: _handleKeyEvent,
      child: PopScope(
        canPop: _isClosing,
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (didPop) return;
          _dismiss();
        },
        child: Stack(
          children: <Widget>[
            // Barrier releases pointer events immediately while closing.
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isClosing,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _dismiss(),
                  onPanStart: widget.dismissOnScroll
                      ? (_) => _dismiss()
                      : null,
                ),
              ),
            ),

            // Popover positioned panel
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isClosing,
                child: CustomSingleChildLayout(
                  delegate: OrionPopoverLayoutDelegate(
                    triggerRect: widget.anchorRect,
                    viewportPadding: viewportPadding,
                    preferredPlacement: widget.placement,
                    gap: gap,
                    autoFlip: widget.autoFlip,
                    showArrow: widget.showArrow,
                    arrowSize: arrowSize,
                    textDirection: textDirection,
                    onLayoutResolved: (OrionPopoverResolvedLayout layout) {
                      if (_resolvedLayout?.offset != layout.offset ||
                          _resolvedLayout?.transformOrigin !=
                              layout.transformOrigin ||
                          _resolvedLayout?.placement != layout.placement) {
                        _resolvedLayout = layout;
                      }
                    },
                  ),
                  child: buildOrionPopoverMotion(
                    driver: _driver,
                    isClosing: () => _isClosing,
                    resolvedLayout: () => _resolvedLayout,
                    preferredPlacement: widget.placement,
                    textDirection: textDirection,
                    child: panel,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
