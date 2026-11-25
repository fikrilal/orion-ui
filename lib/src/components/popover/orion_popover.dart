import 'dart:math' as math;
import 'dart:ui' show FlutterView, ImageFilter;

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
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';

/// Builder callback for trigger widget receiving the [OrionPopoverController].
typedef OrionPopoverTriggerBuilder =
    Widget Function(BuildContext context, OrionPopoverController controller);

/// Builder callback for popover content receiving the active [OrionSpringDriver].
typedef OrionPopoverContentBuilder =
    Widget Function(BuildContext context, OrionSpringDriver driver);

/// Computes safe viewport insets including status bar, home indicator, and
/// soft-keyboard [MediaQueryData.viewInsets] so popovers and menus never clip
/// behind chrome.
EdgeInsets resolveOrionPopoverViewportPadding(BuildContext context) {
  final MediaQueryData media = MediaQuery.of(context);
  final FlutterView? view = View.maybeOf(context);
  final double viewBottomInset = view != null
      ? view.viewInsets.bottom / view.devicePixelRatio
      : media.viewInsets.bottom;
  final double effectiveBottom = math.max(
    media.padding.bottom,
    math.max(media.viewInsets.bottom, viewBottomInset),
  );
  return EdgeInsets.fromLTRB(
    math.max(12.0, media.padding.left + 8.0),
    math.max(12.0, media.padding.top + 8.0),
    math.max(12.0, media.padding.right + 8.0),
    math.max(12.0, effectiveBottom + 8.0),
  );
}

/// Shared floating card surface with static frosted-blur isolation and seamless
/// optional beak arrow, used by both [OrionPopover] and `showOrionMenu`.
class OrionPopoverSurface extends StatelessWidget {
  const OrionPopoverSurface({
    super.key,
    required this.panelKey,
    required this.style,
    required this.scheme,
    required this.orionTheme,
    required this.showArrow,
    required this.triggerRect,
    required this.viewportSize,
    required this.viewportPadding,
    required this.preferredPlacement,
    required this.autoFlip,
    required this.textDirection,
    required this.child,
  });

  final GlobalKey panelKey;
  final OrionPopoverStyle style;
  final ColorScheme scheme;
  final OrionThemeData orionTheme;
  final bool showArrow;
  final Rect triggerRect;
  final Size viewportSize;
  final EdgeInsets viewportPadding;
  final OrionPopoverPlacement preferredPlacement;
  final bool autoFlip;
  final TextDirection textDirection;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final BorderRadius radius =
        style.borderRadius ?? BorderRadius.circular(14.0);
    final Color bg = style.backgroundColor ?? scheme.surfaceContainer;
    final Color borderColor = style.borderColor ?? scheme.outlineVariant;
    final double borderWidth = style.borderWidth ?? 1.0;
    final bool frosted = style.frosted ?? false;
    final List<BoxShadow> shadows = style.shadow ?? const <BoxShadow>[];
    final Size arrowSize = style.arrowSize ?? const Size(14.0, 7.0);
    final double gap = style.gap ?? 8.0;
    final Color effectiveFill = frosted
        ? bg.withValues(alpha: isDark ? 0.78 : 0.82)
        : bg;

    final Widget surfaceBackdrop = frosted
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: orionTheme.blurSigma,
              sigmaY: orionTheme.blurSigma,
            ),
            child: ColoredBox(color: effectiveFill),
          )
        : ColoredBox(color: effectiveFill);

    final Widget cardSurface = Container(
      key: panelKey,
      constraints: BoxConstraints(
        minWidth: style.minWidth ?? 140.0,
        maxWidth: style.maxWidth ?? 320.0,
        minHeight: style.minHeight ?? 0.0,
        maxHeight: style.maxHeight ?? double.infinity,
      ),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: borderWidth > 0
              ? Border.all(color: borderColor, width: borderWidth)
              : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: surfaceBackdrop),
                Padding(
                  padding: style.padding ?? const EdgeInsets.all(6.0),
                  child: child,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (!showArrow) {
      return cardSurface;
    }

    final OrionPopoverArrowPainter arrowPainter = OrionPopoverArrowPainter(
      color: effectiveFill,
      borderColor: borderColor,
      borderWidth: borderWidth,
      arrowSize: arrowSize,
      triggerRect: triggerRect,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      autoFlip: autoFlip,
      gap: gap,
      textDirection: textDirection,
      isDark: isDark,
      hasShadow: shadows.isNotEmpty,
    );

    return CustomPaint(
      painter: arrowPainter,
      foregroundPainter: _OrionPopoverArrowForegroundPainter(arrowPainter),
      child: cardSurface,
    );
  }
}

/// Shared anchored spring reveal/dismiss motion wrapper for [OrionPopover] and
/// `showOrionMenu`.
Widget buildOrionPopoverMotion({
  required OrionSpringDriver driver,
  required bool Function() isClosing,
  required OrionPopoverResolvedLayout? Function() resolvedLayout,
  required OrionPopoverPlacement preferredPlacement,
  required TextDirection textDirection,
  required Widget child,
}) {
  Alignment inferredInitialOrigin() {
    final bool rtl = textDirection == TextDirection.rtl;
    return switch (preferredPlacement) {
      OrionPopoverPlacement.bottomStart =>
        rtl ? Alignment.topRight : Alignment.topLeft,
      OrionPopoverPlacement.bottomCenter => Alignment.topCenter,
      OrionPopoverPlacement.bottomEnd =>
        rtl ? Alignment.topLeft : Alignment.topRight,
      OrionPopoverPlacement.topStart =>
        rtl ? Alignment.bottomRight : Alignment.bottomLeft,
      OrionPopoverPlacement.topCenter => Alignment.bottomCenter,
      OrionPopoverPlacement.topEnd =>
        rtl ? Alignment.bottomLeft : Alignment.bottomRight,
    };
  }

  return AnimatedBuilder(
    animation: driver,
    child: child,
    builder: (BuildContext context, Widget? staticChild) {
      final double progress = driver.value;
      final bool closing = isClosing();
      // Crisp 0.95 -> 1.0 micro-scale anchored to the trigger edge.
      final double scale = 0.95 + (0.05 * progress);
      // Fast opacity ramp on open (sharp immediately) and direct smooth fade
      // on close (no sluggish 100%-opaque shrink tail).
      final double opacity = closing
          ? progress.clamp(0.0, 1.0)
          : (progress * 2.2).clamp(0.0, 1.0);
      final OrionPopoverResolvedLayout? layout = resolvedLayout();
      final Alignment origin =
          layout?.transformOrigin ?? inferredInitialOrigin();
      final bool isTop =
          layout?.isTop ??
          (preferredPlacement == OrionPopoverPlacement.topStart ||
              preferredPlacement == OrionPopoverPlacement.topCenter ||
              preferredPlacement == OrionPopoverPlacement.topEnd);

      final double translateY =
          (1.0 - progress.clamp(0.0, 1.0)) * (isTop ? 5.0 : -5.0);

      final Widget contentWidget = opacity < 1.0
          ? Opacity(opacity: opacity, child: staticChild)
          : staticChild!;

      return Transform.translate(
        offset: Offset(0, translateY),
        child: Transform.scale(
          scale: scale,
          alignment: origin,
          child: contentWidget,
        ),
      );
    },
  );
}

/// A tactile, physics-driven popover floating surface.
///
/// Features:
/// - **Anchor-Aware Transform Origin:** Blossoms outward from the trigger position.
/// - **Viewport Collision Avoidance:** Automatically flips or clamps inside
///   safe-area and keyboard insets, respecting RTL directionality.
/// - **Single Continuous Spring:** Powered by [OrionSpringDriver] with instant
///   mid-flight reversal and zero close-tail reopen cooldown.
/// - **Static Blur Isolation:** Frosted glass option (`frosted: true`) isolates
///   Gaussian blur inside the popover surface without re-rasterizing the screen.
/// - **Keyboard & Accessibility:** Dismissible via outside tap, Escape key, or
///   Back button, restoring trigger focus on close.
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
    this.onKeyEvent,
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

  /// Optional keyboard handler attached to the open popover's focus node.
  /// Runs before the built-in Escape-to-dismiss check.
  final FocusOnKeyEventCallback? onKeyEvent;

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
  final FocusNode _overlayFocusNode = FocusNode(debugLabel: 'OrionPopover');

  late final OrionSpringDriver _driver;
  OrionPopoverController? _internalController;
  OrionPopoverController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionPopoverController());

  OrionPopoverResolvedLayout? _resolvedLayout;
  Rect? _lastTriggerRect;
  FocusNode? _previousFocus;
  bool _isClosing = false;
  bool _isShowing = false;

  ScrollNotificationObserverState? _scrollNotificationObserver;

  /// Whether the popover is currently animating closed.
  bool get isClosing => _isClosing;

  /// Latest resolved layout for content that adapts to flipped placements.
  OrionPopoverResolvedLayout? get resolvedLayout => _resolvedLayout;

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
    _attachController(_effectiveController);
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
  void didUpdateWidget(OrionPopover oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      final OrionPopoverController? previous =
          oldWidget.controller ?? _internalController;
      previous?.detach();
      if (oldWidget.controller == null && widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _attachController(_effectiveController);
      _effectiveController.updateOpenState(_isShowing && !_isClosing);
    }

    if (widget.placement != oldWidget.placement ||
        widget.showArrow != oldWidget.showArrow ||
        widget.autoFlip != oldWidget.autoFlip ||
        widget.style != oldWidget.style) {
      _resolvedLayout = null;
    }
  }

  @override
  void dispose() {
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
    _effectiveController.detach();
    _internalController?.dispose();
    _overlayFocusNode.dispose();
    _driver.removeListener(_onDriverTick);
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
    if (!_isShowing || _isClosing) return;

    // Do not dismiss if the scroll originated from inside the popover's own content.
    final BuildContext? notifContext = notification.context;
    if (notifContext != null && _isInsidePopover(notifContext)) {
      return;
    }

    // Dismiss only on genuine scrolling, ignoring layout/dimension metrics updates.
    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0.0) {
      hide();
    } else if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      hide();
    }
  }

  void _attachController(OrionPopoverController controller) {
    controller.attach(onShow: show, onHide: hide);
  }

  OrionPopoverStyle _resolveStyle(ThemeData theme) {
    final OrionPopoverTheme popoverTheme =
        theme.extension<OrionPopoverTheme>() ?? OrionPopoverTheme.fallback;
    return OrionPopoverPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(popoverTheme.defaultStyle).merge(widget.style);
  }

  void _finishClose() {
    if (!_isClosing) return;
    _isClosing = false;
    _isShowing = false;
    _driver.stop();
    if (_portalController.isShowing) {
      _portalController.hide();
    }
    _effectiveController.updateOpenState(false);
    _restoreFocus();
    widget.onClose?.call();
  }

  void _restoreFocus() {
    final FocusNode? target = _previousFocus;
    _previousFocus = null;
    if (target == null || !target.canRequestFocus) return;
    final FocusNode? current = FocusManager.instance.primaryFocus;
    if (current == null ||
        current == _overlayFocusNode ||
        _overlayFocusNode.hasFocus) {
      target.requestFocus();
    }
  }

  void _onDriverTick() {
    if (_isClosing && _driver.value <= 0.02) {
      _finishClose();
    }
  }

  void _onDriverStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.02) {
      _finishClose();
    }
  }

  Rect? _measureTriggerRect() {
    final RenderBox? box =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final RenderObject? overlayObj = Overlay.maybeOf(
      context,
    )?.context.findRenderObject();
    final Offset globalOffset = box.localToGlobal(
      Offset.zero,
      ancestor: overlayObj,
    );
    return globalOffset & box.size;
  }

  /// Opens the popover.
  void show() {
    if (_isShowing && !_isClosing) return;
    final Rect? rect = _measureTriggerRect();
    if (rect == null) return;

    final FocusNode? currentFocus = FocusManager.instance.primaryFocus;
    if (currentFocus != null && currentFocus != _overlayFocusNode) {
      _previousFocus = currentFocus;
    }

    _lastTriggerRect = rect;
    _resolvedLayout = null;
    _isClosing = false;
    _isShowing = true;

    final OrionPopoverStyle style = _resolveStyle(Theme.of(context));
    _effectiveController.updateOpenState(true);
    widget.onOpen?.call();
    if (!_portalController.isShowing) {
      _portalController.show();
    } else {
      setState(() {});
    }

    if (_driver.reducedMotion) {
      _driver.jumpTo(1.0);
      return;
    }

    _driver.springSpec =
        style.springSpec ??
        const OrionSpringSpec(stiffness: 520.0, dampingRatio: 0.86);
    _driver.retarget(1.0);
    OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
  }

  /// Closes the popover.
  void hide() {
    if (!_isShowing || _isClosing) return;
    _isClosing = true;
    // Flip logical open state immediately so callers and trigger toggles never
    // hit an invisible reopen cooldown during the exit animation.
    _effectiveController.updateOpenState(false);

    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      _finishClose();
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
    // Rebuild overlay immediately so the barrier becomes IgnorePointer on the
    // very first closing frame.
    if (mounted) {
      setState(() {});
    }
  }

  /// Toggles the popover between open and closed.
  void toggle() {
    if (_isShowing && !_isClosing) {
      hide();
    } else {
      show();
    }
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    final KeyEventResult? custom = widget.onKeyEvent?.call(node, event);
    if (custom != null && custom != KeyEventResult.ignored) {
      return custom;
    }
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      hide();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  Widget _buildOverlay(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orionTheme = OrionTheme.of(context);
    final OrionPopoverStyle style = _resolveStyle(theme);
    final TextDirection textDirection = Directionality.of(context);

    final Rect triggerRect =
        _measureTriggerRect() ??
        _lastTriggerRect ??
        const Rect.fromLTWH(0, 0, 0, 0);

    final bool showArrow = widget.showArrow ?? style.showArrow ?? false;
    final Size arrowSize = style.arrowSize ?? const Size(14.0, 7.0);
    final double gap = style.gap ?? 8.0;

    final Size viewportSize = MediaQuery.sizeOf(context);
    final EdgeInsets viewportPadding = resolveOrionPopoverViewportPadding(
      context,
    );

    // Initial pre-layout estimate so Frame 0 has a matching origin & direction.
    final Size estimatedSize = Size(
      style.minWidth ?? 140.0,
      style.minHeight ?? 120.0,
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
      textDirection: textDirection,
    );

    final Widget panel = OrionPopoverSurface(
      panelKey: _panelKey,
      style: style,
      scheme: scheme,
      orionTheme: orionTheme,
      showArrow: showArrow,
      triggerRect: triggerRect,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: widget.placement,
      autoFlip: widget.autoFlip,
      textDirection: textDirection,
      child: widget.builder?.call(context, _driver) ?? widget.content!,
    );

    return Focus(
      focusNode: _overlayFocusNode,
      autofocus: !_isClosing,
      onKeyEvent: _handleKeyEvent,
      child: PopScope(
        canPop: _isClosing,
        onPopInvokedWithResult: (bool didPop, Object? _) {
          if (didPop) return;
          hide();
        },
        child: Stack(
          children: <Widget>[
            // Outside dismissal barrier; releases pointer events immediately on
            // close so rapid re-taps never feel blocked.
            if (widget.dismissOnTapOutside || widget.dismissOnScroll)
              Positioned.fill(
                child: IgnorePointer(
                  ignoring: _isClosing,
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: widget.dismissOnTapOutside ? hide : null,
                    onPanStart: widget.dismissOnScroll ? (_) => hide() : null,
                  ),
                ),
              ),

            // Measured and positioned popover panel
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isClosing,
                child: CustomSingleChildLayout(
                  delegate: OrionPopoverLayoutDelegate(
                    triggerRect: triggerRect,
                    viewportPadding: viewportPadding,
                    preferredPlacement: widget.placement,
                    gap: gap,
                    autoFlip: widget.autoFlip,
                    showArrow: showArrow,
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
    this.textDirection = TextDirection.ltr,
  });

  final Rect triggerRect;
  final EdgeInsets viewportPadding;
  final OrionPopoverPlacement preferredPlacement;
  final double gap;
  final bool autoFlip;
  final bool showArrow;
  final Size arrowSize;
  final TextDirection textDirection;
  final ValueChanged<OrionPopoverResolvedLayout> onLayoutResolved;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen().deflate(viewportPadding);
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final OrionPopoverResolvedLayout layout = OrionPopoverGeometry.resolve(
      triggerRect: triggerRect,
      popoverSize: childSize,
      viewportSize: size,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      gap: gap,
      autoFlip: autoFlip,
      showArrow: showArrow,
      arrowSize: arrowSize,
      textDirection: textDirection,
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
        arrowSize != oldDelegate.arrowSize ||
        textDirection != oldDelegate.textDirection;
  }
}

/// Paints the pointed caret beak behind the popover card (including soft
/// elevation shadow); paired with [_OrionPopoverArrowForegroundPainter] to
/// bridge the border seam cleanly.
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
    this.textDirection = TextDirection.ltr,
    this.isDark = false,
    this.hasShadow = true,
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
  final TextDirection textDirection;
  final bool isDark;
  final bool hasShadow;

  (bool isPointingUp, double x, double tipY) _geometry(Size size) {
    final OrionPopoverResolvedLayout layout = OrionPopoverGeometry.resolve(
      triggerRect: triggerRect,
      popoverSize: size,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      gap: gap,
      autoFlip: autoFlip,
      showArrow: true,
      arrowSize: arrowSize,
      textDirection: textDirection,
    );
    final bool isPointingUp = !layout.isTop;
    final Offset arrowOffset =
        layout.arrowOffset ??
        Offset(
          (size.width - arrowSize.width) / 2.0,
          isPointingUp ? -arrowSize.height : size.height,
        );
    final double tipY = isPointingUp
        ? arrowOffset.dy
        : arrowOffset.dy + arrowSize.height;
    return (isPointingUp, arrowOffset.dx, tipY);
  }

  Path _buildArrowPath({
    required bool isPointingUp,
    required double x,
    required double baseY,
    required double tipY,
    required double overlap,
  }) {
    final double midX = x + arrowSize.width / 2.0;
    final double endX = x + arrowSize.width;
    const double tipCurve = 1.5;
    final double dir = isPointingUp ? -1.0 : 1.0;

    return Path()
      ..moveTo(x, baseY - dir * overlap)
      ..lineTo(x, baseY)
      ..lineTo(midX - tipCurve, tipY - dir * tipCurve)
      ..quadraticBezierTo(midX, tipY, midX + tipCurve, tipY - dir * tipCurve)
      ..lineTo(endX, baseY)
      ..lineTo(endX, baseY - dir * overlap)
      ..close();
  }

  Path _buildBorderPath({
    required bool isPointingUp,
    required double x,
    required double baseY,
    required double tipY,
  }) {
    final double midX = x + arrowSize.width / 2.0;
    final double endX = x + arrowSize.width;
    const double tipCurve = 1.5;
    final double dir = isPointingUp ? -1.0 : 1.0;

    return Path()
      ..moveTo(x, baseY)
      ..lineTo(midX - tipCurve, tipY - dir * tipCurve)
      ..quadraticBezierTo(midX, tipY, midX + tipCurve, tipY - dir * tipCurve)
      ..lineTo(endX, baseY);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final (bool isPointingUp, double x, double tipY) = _geometry(size);
    final double baseY = isPointingUp ? 0.0 : size.height;

    if (hasShadow) {
      final Path shadowPath = _buildArrowPath(
        isPointingUp: isPointingUp,
        x: x,
        baseY: baseY,
        tipY: tipY,
        overlap: 1.0,
      );
      canvas.drawPath(
        shadowPath.shift(const Offset(0, 2)),
        Paint()
          ..color = Color(isDark ? 0x38000000 : 0x14000000)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0),
      );
    }
  }

  void paintForeground(Canvas canvas, Size size) {
    final (bool isPointingUp, double x, double tipY) = _geometry(size);
    final double baseY = isPointingUp ? 0.0 : size.height;
    final double overlap = color.a < 1.0
        ? 0.5
        : math.max(1.5, borderWidth + 0.75);

    final Path fillPath = _buildArrowPath(
      isPointingUp: isPointingUp,
      x: x,
      baseY: baseY,
      tipY: tipY,
      overlap: overlap,
    );
    canvas.drawPath(fillPath, Paint()..color = color);

    if (borderWidth > 0 && borderColor.a > 0) {
      final Path borderPath = _buildBorderPath(
        isPointingUp: isPointingUp,
        x: x,
        baseY: baseY,
        tipY: tipY,
      );
      canvas.drawPath(
        borderPath,
        Paint()
          ..color = borderColor
          ..strokeWidth = borderWidth
          ..style = PaintingStyle.stroke
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
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
        gap != oldDelegate.gap ||
        textDirection != oldDelegate.textDirection ||
        isDark != oldDelegate.isDark ||
        hasShadow != oldDelegate.hasShadow;
  }
}

class _OrionPopoverArrowForegroundPainter extends CustomPainter {
  const _OrionPopoverArrowForegroundPainter(this.arrowPainter);

  final OrionPopoverArrowPainter arrowPainter;

  @override
  void paint(Canvas canvas, Size size) {
    arrowPainter.paintForeground(canvas, size);
  }

  @override
  bool shouldRepaint(_OrionPopoverArrowForegroundPainter oldDelegate) =>
      arrowPainter.shouldRepaint(oldDelegate.arrowPainter);
}
