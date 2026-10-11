import 'dart:ui' show ImageFilter;
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

/// A tactile, anchored dropdown menu component.
///
/// Wraps an [OrionPopover] with structured [OrionMenuItem] rows, tactile
/// [OrionPressable] item feedback, destructive styling, and optional cascading entry.
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

  /// The ordered list of menu items and dividers to render.
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
  OrionPopoverController? _internalController;
  OrionPopoverController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionPopoverController());

  @override
  void dispose() {
    _internalController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return OrionPopover(
      controller: _effectiveController,
      placement: widget.placement,
      style: widget.style,
      showArrow: widget.showArrow,
      autoFlip: widget.autoFlip,
      dismissOnScroll: widget.dismissOnScroll,
      onOpen: widget.onOpen,
      onClose: widget.onClose,
      trigger: widget.trigger,
      triggerBuilder: widget.triggerBuilder,
      builder: (context, driver) => OrionMenuList(
        items: widget.items,
        cascade: widget.cascade,
        animation: driver,
        onItemSelected: (_) => _effectiveController.hide(),
      ),
    );
  }
}

/// The body content list rendering a column of [OrionMenuItem]s.
class OrionMenuList extends StatelessWidget {
  const OrionMenuList({
    super.key,
    required this.items,
    this.onItemSelected,
    this.cascade = false,
    this.animation,
  });

  /// The list of items to render.
  final List<OrionMenuItem> items;

  /// Callback when any actionable item is tapped, passing optional item value.
  final ValueChanged<dynamic>? onItemSelected;

  /// Whether items enter with cascading animation.
  final bool cascade;

  /// Optional parent animation driving cascading item entrance.
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final List<Widget> children = <Widget>[];

    for (int i = 0; i < items.length; i++) {
      final item = items[i];

      if (item.isDivider) {
        children.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: OrionSpacing.space4),
            child: Divider(
              height: 1.0,
              thickness: 1.0,
              color: scheme.outlineVariant.withValues(alpha: 0.35),
            ),
          ),
        );
        continue;
      }

      final Widget row = _OrionMenuItemRow(
        item: item,
        index: i,
        cascade: cascade,
        animation: animation,
        onTap: () {
          onItemSelected?.call(item.value);
          item.onTap?.call();
        },
      );

      children.add(row);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

class _OrionMenuItemRow extends StatelessWidget {
  const _OrionMenuItemRow({
    required this.item,
    required this.onTap,
    this.index = 0,
    this.cascade = false,
    this.animation,
  });

  final OrionMenuItem item;
  final VoidCallback onTap;
  final int index;
  final bool cascade;
  final Animation<double>? animation;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

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

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space12,
        vertical: OrionSpacing.space8,
      ),
      child: Row(
        children: [
          if (item.leading != null) ...[
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
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontSize: 14.0,
                    fontWeight: FontWeight.w500,
                    color: foregroundColor,
                  ),
                ),
                if (item.subtitle != null) ...[
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
          if (item.trailing != null) ...[
            const SizedBox(width: OrionSpacing.space8),
            DefaultTextStyle(
              style: TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w400,
                color: subtitleColor,
              ),
              child: item.trailing!,
            ),
          ],
        ],
      ),
    );

    final Widget rowContent = OrionPressable(
      pressedScale: 0.98,
      onTap: item.enabled ? onTap : null,
      hapticType: OrionHapticType.selectionClick,
      child: Container(
        constraints: const BoxConstraints(minHeight: 44.0),
        alignment: Alignment.centerLeft,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(OrionRadii.radius8),
        ),
        child: content,
      ),
    );

    if (!cascade || animation == null) {
      return rowContent;
    }

    return AnimatedBuilder(
      animation: animation!,
      child: rowContent,
      builder: (context, child) {
        final double t = animation!.value;
        final double stagger = (index * 0.04).clamp(0.0, 0.4);
        final double itemProgress = ((t - stagger) / (1.0 - stagger)).clamp(
          0.0,
          1.0,
        );
        final double itemTranslateY = (1.0 - itemProgress) * -4.0;
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
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
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
  late final OrionSpringDriver _driver;
  OrionPopoverResolvedLayout? _resolvedLayout;
  bool _isClosing = false;
  T? _dismissResult;
  ScrollNotificationObserverState? _scrollNotificationObserver;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec:
          widget.style?.springSpec ??
          const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.82),
    );
    _driver.addStatusListener(_onDriverStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_driver.reducedMotion) {
          _driver.jumpTo(1.0);
        } else {
          _driver.retarget(1.0);
          OrionHaptics.trigger(OrionHapticType.selectionClick);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.reducedMotion = reduced;

    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void dispose() {
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
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

    // Dismiss only on genuine scrolling, ignoring layout/dimension metrics updates
    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0.0) {
      _dismiss();
    } else if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      _dismiss();
    }
  }

  void _onDriverStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.01) {
      if (widget.route.isCurrent) {
        Navigator.of(context).pop(_dismissResult);
      }
    }
  }

  void _dismiss([T? result]) {
    if (_isClosing) return;
    _isClosing = true;
    _dismissResult = result;

    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      if (widget.route.isCurrent) {
        Navigator.of(context).pop(result);
      }
      return;
    }

    _driver.springSpec =
        widget.style?.dismissSpringSpec ??
        const OrionSpringSpec(
          stiffness: 380.0,
          dampingRatio: 1.0,
          clampOvershoot: true,
        );
    _driver.retarget(0.0);
  }

  Alignment _inferredInitialOrigin() {
    return switch (widget.placement) {
      OrionPopoverPlacement.bottomStart => Alignment.topLeft,
      OrionPopoverPlacement.bottomCenter => Alignment.topCenter,
      OrionPopoverPlacement.bottomEnd => Alignment.topRight,
      OrionPopoverPlacement.topStart => Alignment.bottomLeft,
      OrionPopoverPlacement.topCenter => Alignment.bottomCenter,
      OrionPopoverPlacement.topEnd => Alignment.bottomRight,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final orionTheme = OrionTheme.of(context);

    final OrionPopoverTheme popoverTheme =
        theme.extension<OrionPopoverTheme>() ?? OrionPopoverTheme.fallback;
    final OrionPopoverStyle resolvedStyle = OrionPopoverPresets.resolve(
      scheme: scheme,
    ).merge(popoverTheme.defaultStyle).merge(widget.style);

    final BorderRadius radius =
        resolvedStyle.borderRadius ??
        BorderRadius.circular(OrionRadii.radius12);
    final Color bg = resolvedStyle.backgroundColor ?? scheme.surface;
    final bool frosted = resolvedStyle.frosted ?? false;
    final Size arrowSize = resolvedStyle.arrowSize ?? const Size(14.0, 7.0);

    final MediaQueryData media = MediaQuery.of(context);
    final Size viewportSize = media.size;
    const EdgeInsets viewportPadding = EdgeInsets.all(12.0);

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
      gap: resolvedStyle.gap ?? 8.0,
      autoFlip: widget.autoFlip,
      showArrow: widget.showArrow,
      arrowSize: arrowSize,
    );

    final Widget surfaceBackdrop = frosted
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: orionTheme.blurSigma,
              sigmaY: orionTheme.blurSigma,
            ),
            child: ColoredBox(color: bg.withValues(alpha: 0.70)),
          )
        : ColoredBox(color: bg);

    final Widget menuCard = Container(
      key: _panelKey,
      constraints: BoxConstraints(
        minWidth: resolvedStyle.minWidth ?? 140.0,
        maxWidth: resolvedStyle.maxWidth ?? 320.0,
        minHeight: resolvedStyle.minHeight ?? 0.0,
        maxHeight: resolvedStyle.maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color:
              resolvedStyle.borderColor ??
              scheme.outlineVariant.withValues(alpha: 0.35),
          width: resolvedStyle.borderWidth ?? 1.0,
        ),
        boxShadow: resolvedStyle.shadow ?? OrionThemeData.defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Material(
          type: MaterialType.transparency,
          child: Stack(
            children: [
              Positioned.fill(child: surfaceBackdrop),
              Padding(
                padding:
                    resolvedStyle.padding ??
                    const EdgeInsets.all(OrionSpacing.space8),
                child: OrionMenuList(
                  items: widget.items,
                  cascade: widget.cascade,
                  animation: _driver,
                  onItemSelected: (val) => _dismiss(val as T?),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final Widget panel;
    if (widget.showArrow) {
      panel = CustomPaint(
        painter: OrionPopoverArrowPainter(
          color: frosted ? bg.withValues(alpha: 0.70) : bg,
          borderColor:
              resolvedStyle.borderColor ??
              scheme.outlineVariant.withValues(alpha: 0.35),
          borderWidth: resolvedStyle.borderWidth ?? 1.0,
          arrowSize: arrowSize,
          triggerRect: widget.anchorRect,
          viewportSize: viewportSize,
          viewportPadding: viewportPadding,
          preferredPlacement: widget.placement,
          autoFlip: widget.autoFlip,
          gap: resolvedStyle.gap ?? 8.0,
        ),
        child: menuCard,
      );
    } else {
      panel = menuCard;
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          _dismiss();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          _dismiss();
        },
        child: Stack(
          children: [
            // Barrier
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _dismiss(),
                onPanStart: widget.dismissOnScroll ? (_) => _dismiss() : null,
              ),
            ),

            // Popover positioned panel
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: OrionPopoverLayoutDelegate(
                  triggerRect: widget.anchorRect,
                  viewportPadding: const EdgeInsets.all(12.0),
                  preferredPlacement: widget.placement,
                  gap: resolvedStyle.gap ?? 8.0,
                  autoFlip: widget.autoFlip,
                  showArrow: widget.showArrow,
                  arrowSize: arrowSize,
                  onLayoutResolved: (OrionPopoverResolvedLayout layout) {
                    if (_resolvedLayout?.offset != layout.offset ||
                        _resolvedLayout?.transformOrigin !=
                            layout.transformOrigin) {
                      _resolvedLayout = layout;
                    }
                  },
                ),
                child: AnimatedBuilder(
                  animation: _driver,
                  builder: (context, child) {
                    final double progress = _driver.value;
                    // Crisp 0.94 -> 1.0 micro-scale to eliminate "balloon from thin air" feel
                    final double scale = 0.94 + (0.06 * progress);
                    // Fast opacity ramp
                    final double opacity = (progress * 2.0).clamp(0.0, 1.0);
                    final Alignment origin =
                        _resolvedLayout?.transformOrigin ??
                        _inferredInitialOrigin();

                    final bool isTop = _resolvedLayout != null
                        ? (_resolvedLayout!.placement ==
                                  OrionPopoverPlacement.topStart ||
                              _resolvedLayout!.placement ==
                                  OrionPopoverPlacement.topCenter ||
                              _resolvedLayout!.placement ==
                                  OrionPopoverPlacement.topEnd)
                        : (widget.placement == OrionPopoverPlacement.topStart ||
                              widget.placement ==
                                  OrionPopoverPlacement.topCenter ||
                              widget.placement == OrionPopoverPlacement.topEnd);

                    // Organic 6pt directional glide from trigger anchor
                    final double translateY =
                        (1.0 - progress.clamp(0.0, 1.0)) * (isTop ? 6.0 : -6.0);

                    final Widget contentWidget = opacity < 1.0
                        ? Opacity(opacity: opacity, child: child)
                        : child!;

                    return Transform.translate(
                      offset: Offset(0, translateY),
                      child: Transform.scale(
                        scale: scale,
                        alignment: origin,
                        child: contentWidget,
                      ),
                    );
                  },
                  child: panel,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
