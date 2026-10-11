import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/popover/orion_popover_controller.dart';
import 'package:orion_ui/src/components/popover/orion_popover_geometry.dart';
import 'package:orion_ui/src/components/popover/orion_popover_presets.dart';
import 'package:orion_ui/src/components/popover/orion_popover_style.dart';
import 'package:orion_ui/src/components/popover/orion_popover_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_colors.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Builder callback for trigger widget receiving the [OrionPopoverController].
typedef OrionPopoverTriggerBuilder =
    Widget Function(BuildContext context, OrionPopoverController controller);

/// Builder callback for popover content receiving the active [OrionSpringDriver].
typedef OrionPopoverContentBuilder =
    Widget Function(BuildContext context, OrionSpringDriver driver);

/// A tactile, physics-driven popover floating surface.
///
/// Features:
/// - **Anchor-Aware Transform Origin:** Blossoms outward from the trigger position.
/// - **Viewport Collision Avoidance:** Automatically flips or clamps to prevent clipping.
/// - **Single Continuous Spring:** Powered by [OrionSpringDriver] with zero position snaps.
/// - **Static Blur Isolation:** Frosted glass option (`frosted: true`) isolates Gaussian
///   blur inside the popover surface without re-rasterizing app background.
/// - **Keyboard & Accessibility:** Dismissible via outside tap, Escape key, or Back button.
class OrionPopover extends StatefulWidget {
  const OrionPopover({
    super.key,
    this.trigger,
    this.triggerBuilder,
    this.content,
    this.builder,
    this.placement = OrionPopoverPlacement.bottomStart,
    this.style,
    this.controller,
    this.showArrow,
    this.autoFlip = true,
    this.dismissOnTapOutside = true,
    this.dismissOnScroll = true,
    this.onOpen,
    this.onClose,
  }) : assert(
         trigger != null || triggerBuilder != null,
         'Either trigger or triggerBuilder must be provided',
       ),
       assert(
         content != null || builder != null,
         'Either content or builder must be provided',
       );

  /// Trigger widget that opens the popover.
  final Widget? trigger;

  /// Optional trigger builder receiving the popover's [OrionPopoverController].
  final OrionPopoverTriggerBuilder? triggerBuilder;

  /// Body widget rendered inside the floating popover surface.
  final Widget? content;

  /// Optional builder receiving the popover's [OrionSpringDriver].
  final OrionPopoverContentBuilder? builder;

  /// Preferred placement relative to the trigger.
  final OrionPopoverPlacement placement;

  /// Style overrides for geometry, surface, and spring motion.
  final OrionPopoverStyle? style;

  /// Optional programmatic controller.
  final OrionPopoverController? controller;

  /// Whether to render a pointed caret beak toward the trigger.
  final bool? showArrow;

  /// Whether to flip to the opposite side if constrained by viewport bounds.
  final bool autoFlip;

  /// Whether tapping outside the popover dismisses it.
  final bool dismissOnTapOutside;

  /// Whether scrolling ancestor scrollables or dragging outside dismisses the popover.
  final bool dismissOnScroll;

  /// Callback invoked when the popover starts opening.
  final VoidCallback? onOpen;

  /// Callback invoked when the popover has completely closed.
  final VoidCallback? onClose;

  @override
  State<OrionPopover> createState() => OrionPopoverState();
}

class OrionPopoverState extends State<OrionPopover>
    with SingleTickerProviderStateMixin {
  final GlobalKey _triggerKey = GlobalKey();
  final GlobalKey _panelKey = GlobalKey();
  final OverlayPortalController _portalController = OverlayPortalController();

  late final OrionSpringDriver _driver;
  OrionPopoverController? _internalController;
  OrionPopoverController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionPopoverController());

  OrionPopoverResolvedLayout? _resolvedLayout;
  Rect? _lastTriggerRect;
  bool _isClosing = false;

  OrionPopoverStyle _resolvedStyle = const OrionPopoverStyle();
  OrionThemeData _orionTheme = OrionThemeData.fallback;
  ColorScheme _scheme = OrionColors.lightScheme;
  ScrollNotificationObserverState? _scrollNotificationObserver;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.82),
    );
    _driver.addStatusListener(_onDriverStatus);
    _attachController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final theme = Theme.of(context);
    _scheme = theme.colorScheme;
    _orionTheme = OrionTheme.of(context);
    _resolvedStyle = _resolveStyle(theme);
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.reducedMotion = reduced;

    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollNotificationObserver?.addListener(_handleScrollNotification);
  }

  @override
  void didUpdateWidget(OrionPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
  }

  @override
  void dispose() {
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
    _effectiveController.detach();
    _internalController?.dispose();
    _driver.removeStatusListener(_onDriverStatus);
    _driver.dispose();
    super.dispose();
  }

  bool _isInsidePopover(BuildContext notifContext) {
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
    if (!widget.dismissOnScroll) return;
    if (!_effectiveController.isOpen || _isClosing) return;

    // Do not dismiss if the scroll originated from inside the popover's own content
    final BuildContext? notifContext = notification.context;
    if (notifContext != null && _isInsidePopover(notifContext)) {
      return;
    }

    // Dismiss only on genuine scrolling, ignoring layout/dimension metrics updates
    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0.0) {
      hide();
    } else if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      hide();
    }
  }

  void _attachController() {
    _effectiveController.attach(onShow: show, onHide: hide);
  }

  OrionPopoverStyle _resolveStyle(ThemeData theme) {
    final OrionPopoverTheme popoverTheme =
        theme.extension<OrionPopoverTheme>() ?? OrionPopoverTheme.fallback;
    return OrionPopoverPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(popoverTheme.defaultStyle).merge(widget.style);
  }

  void _onDriverStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.01) {
      _isClosing = false;
      _portalController.hide();
      _effectiveController.updateOpenState(false);
      widget.onClose?.call();
    }
  }

  Rect? _measureTriggerRect() {
    final RenderBox? box =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final Offset globalOffset = box.localToGlobal(Offset.zero);
    return globalOffset & box.size;
  }

  /// Opens the popover.
  void show() {
    if (_effectiveController.isOpen && !_isClosing) return;
    final Rect? rect = _measureTriggerRect();
    if (rect == null) return;
    _lastTriggerRect = rect;
    _isClosing = false;

    _effectiveController.updateOpenState(true);
    widget.onOpen?.call();
    _portalController.show();

    if (_driver.reducedMotion) {
      _driver.jumpTo(1.0);
      return;
    }

    _driver.springSpec =
        _resolvedStyle.springSpec ??
        const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.82);
    _driver.retarget(1.0);
    OrionHaptics.trigger(OrionHapticType.selectionClick);
  }

  /// Closes the popover.
  void hide() {
    if (!_effectiveController.isOpen || _isClosing) return;
    _isClosing = true;

    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      _portalController.hide();
      _effectiveController.updateOpenState(false);
      widget.onClose?.call();
      return;
    }

    _driver.springSpec =
        _resolvedStyle.dismissSpringSpec ??
        const OrionSpringSpec(
          stiffness: 380.0,
          dampingRatio: 1.0,
          clampOvershoot: true,
        );
    _driver.retarget(0.0);
  }

  /// Toggles the popover between open and closed.
  void toggle() {
    if (_effectiveController.isOpen && !_isClosing) {
      hide();
    } else {
      show();
    }
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

  Widget _buildOverlay(BuildContext context) {
    final Rect triggerRect =
        _measureTriggerRect() ??
        _lastTriggerRect ??
        const Rect.fromLTWH(0, 0, 0, 0);

    final bool showArrow =
        widget.showArrow ?? _resolvedStyle.showArrow ?? false;
    final Size arrowSize = _resolvedStyle.arrowSize ?? const Size(14.0, 7.0);
    final double gap = _resolvedStyle.gap ?? 8.0;

    final MediaQueryData media = MediaQuery.of(context);
    final Size viewportSize = media.size;
    const EdgeInsets viewportPadding = EdgeInsets.all(12.0);

    // Initial pre-layout estimate so Frame 0 never has an inverted or uninitialized origin
    final Size estimatedSize = Size(
      _resolvedStyle.minWidth ?? 140.0,
      _resolvedStyle.minHeight ?? 120.0,
    );
    _resolvedLayout ??= OrionPopoverGeometry.resolve(
      triggerRect: triggerRect,
      popoverSize: estimatedSize,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: widget.placement,
      gap: gap,
      autoFlip: widget.autoFlip,
      showArrow: showArrow,
      arrowSize: arrowSize,
    );

    final BorderRadius radius =
        _resolvedStyle.borderRadius ??
        BorderRadius.circular(OrionRadii.radius12);
    final Color bg = _resolvedStyle.backgroundColor ?? _scheme.surface;
    final bool frosted = _resolvedStyle.frosted ?? false;

    // Static blur isolation: BackdropFilter is strictly isolated to the popover's
    // own surface container, never scaling or diffusing the full app screen.
    final Widget surfaceBackdrop = frosted
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: _orionTheme.blurSigma,
              sigmaY: _orionTheme.blurSigma,
            ),
            child: ColoredBox(color: bg.withValues(alpha: 0.70)),
          )
        : ColoredBox(color: bg);

    final Widget cardSurface = Container(
      key: _panelKey,
      constraints: BoxConstraints(
        minWidth: _resolvedStyle.minWidth ?? 140.0,
        maxWidth: _resolvedStyle.maxWidth ?? 320.0,
        minHeight: _resolvedStyle.minHeight ?? 0.0,
        maxHeight: _resolvedStyle.maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color:
              _resolvedStyle.borderColor ??
              _scheme.outlineVariant.withValues(alpha: 0.35),
          width: _resolvedStyle.borderWidth ?? 1.0,
        ),
        boxShadow: _resolvedStyle.shadow ?? OrionThemeData.defaultShadow,
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
                    _resolvedStyle.padding ??
                    const EdgeInsets.all(OrionSpacing.space8),
                child:
                    widget.builder?.call(context, _driver) ?? widget.content!,
              ),
            ],
          ),
        ),
      ),
    );

    final Widget panel;
    if (showArrow) {
      panel = CustomPaint(
        painter: OrionPopoverArrowPainter(
          color: frosted ? bg.withValues(alpha: 0.70) : bg,
          borderColor:
              _resolvedStyle.borderColor ??
              _scheme.outlineVariant.withValues(alpha: 0.35),
          borderWidth: _resolvedStyle.borderWidth ?? 1.0,
          arrowSize: arrowSize,
          triggerRect: triggerRect,
          viewportSize: viewportSize,
          viewportPadding: viewportPadding,
          preferredPlacement: widget.placement,
          autoFlip: widget.autoFlip,
          gap: gap,
        ),
        child: cardSurface,
      );
    } else {
      panel = cardSurface;
    }

    return Focus(
      autofocus: true,
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          hide();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          hide();
        },
        child: Stack(
          children: [
            // Outside dismissal barrier
            if (widget.dismissOnTapOutside || widget.dismissOnScroll)
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: widget.dismissOnTapOutside ? hide : null,
                  onPanStart: widget.dismissOnScroll ? (_) => hide() : null,
                ),
              ),

            // Measured and positioned popover panel
            Positioned.fill(
              child: CustomSingleChildLayout(
                delegate: OrionPopoverLayoutDelegate(
                  triggerRect: triggerRect,
                  viewportPadding: const EdgeInsets.all(12.0),
                  preferredPlacement: widget.placement,
                  gap: gap,
                  autoFlip: widget.autoFlip,
                  showArrow: showArrow,
                  arrowSize: arrowSize,
                  onLayoutResolved: (layout) {
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
                    // Fast opacity ramp (fully opaque by 50% travel) so surface is sharp and legible
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

  @override
  Widget build(BuildContext context) {
    final Widget triggerWidget;
    if (widget.triggerBuilder != null) {
      triggerWidget = widget.triggerBuilder!(context, _effectiveController);
    } else {
      triggerWidget = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: toggle,
        child: widget.trigger,
      );
    }

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: _buildOverlay,
      child: KeyedSubtree(key: _triggerKey, child: triggerWidget),
    );
  }
}

class OrionPopoverLayoutDelegate extends SingleChildLayoutDelegate {
  OrionPopoverLayoutDelegate({
    required this.triggerRect,
    required this.viewportPadding,
    required this.preferredPlacement,
    required this.gap,
    required this.autoFlip,
    required this.showArrow,
    required this.arrowSize,
    required this.onLayoutResolved,
  });

  final Rect triggerRect;
  final EdgeInsets viewportPadding;
  final OrionPopoverPlacement preferredPlacement;
  final double gap;
  final bool autoFlip;
  final bool showArrow;
  final Size arrowSize;
  final ValueChanged<OrionPopoverResolvedLayout> onLayoutResolved;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().deflate(viewportPadding);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final layout = OrionPopoverGeometry.resolve(
      triggerRect: triggerRect,
      popoverSize: childSize,
      viewportSize: size,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      gap: gap,
      autoFlip: autoFlip,
      showArrow: showArrow,
      arrowSize: arrowSize,
    );
    onLayoutResolved(layout);
    return layout.offset;
  }

  @override
  bool shouldRelayout(OrionPopoverLayoutDelegate oldDelegate) {
    return triggerRect != oldDelegate.triggerRect ||
        preferredPlacement != oldDelegate.preferredPlacement ||
        gap != oldDelegate.gap ||
        autoFlip != oldDelegate.autoFlip ||
        viewportPadding != oldDelegate.viewportPadding ||
        showArrow != oldDelegate.showArrow ||
        arrowSize != oldDelegate.arrowSize;
  }
}

class OrionPopoverArrowPainter extends CustomPainter {
  const OrionPopoverArrowPainter({
    required this.color,
    required this.borderColor,
    required this.borderWidth,
    required this.arrowSize,
    required this.triggerRect,
    required this.viewportSize,
    required this.viewportPadding,
    required this.preferredPlacement,
    required this.autoFlip,
    required this.gap,
  });

  final Color color;
  final Color borderColor;
  final double borderWidth;
  final Size arrowSize;
  final Rect triggerRect;
  final Size viewportSize;
  final EdgeInsets viewportPadding;
  final OrionPopoverPlacement preferredPlacement;
  final bool autoFlip;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = OrionPopoverGeometry.resolve(
      triggerRect: triggerRect,
      popoverSize: size,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      gap: gap,
      autoFlip: autoFlip,
      showArrow: true,
      arrowSize: arrowSize,
    );

    final bool isPointingUp =
        layout.placement == OrionPopoverPlacement.bottomStart ||
        layout.placement == OrionPopoverPlacement.bottomCenter ||
        layout.placement == OrionPopoverPlacement.bottomEnd;

    final Offset arrowOffset =
        layout.arrowOffset ??
        Offset(
          (size.width - arrowSize.width) / 2.0,
          isPointingUp ? -arrowSize.height : size.height,
        );
    final double x = arrowOffset.dx;
    final double y = arrowOffset.dy;

    final Paint fillPaint = Paint()..color = color;
    final Paint borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final Path path = Path();
    if (isPointingUp) {
      path.moveTo(x + (arrowSize.width / 2), y);
      path.lineTo(x + arrowSize.width, 0);
      path.lineTo(x, 0);
      path.close();

      canvas.drawPath(path, fillPaint);

      final Path borderPath = Path()
        ..moveTo(x, 0)
        ..lineTo(x + (arrowSize.width / 2), y)
        ..lineTo(x + arrowSize.width, 0);
      canvas.drawPath(borderPath, borderPaint);
    } else {
      path.moveTo(x, size.height);
      path.lineTo(x + arrowSize.width, size.height);
      path.lineTo(x + (arrowSize.width / 2), y + arrowSize.height);
      path.close();

      canvas.drawPath(path, fillPaint);

      final Path borderPath = Path()
        ..moveTo(x, size.height)
        ..lineTo(x + (arrowSize.width / 2), y + arrowSize.height)
        ..lineTo(x + arrowSize.width, size.height);
      canvas.drawPath(borderPath, borderPaint);
    }
  }

  @override
  bool shouldRepaint(OrionPopoverArrowPainter oldDelegate) {
    return color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        arrowSize != oldDelegate.arrowSize ||
        triggerRect != oldDelegate.triggerRect ||
        viewportSize != oldDelegate.viewportSize ||
        viewportPadding != oldDelegate.viewportPadding ||
        preferredPlacement != oldDelegate.preferredPlacement ||
        autoFlip != oldDelegate.autoFlip ||
        gap != oldDelegate.gap;
  }
}
