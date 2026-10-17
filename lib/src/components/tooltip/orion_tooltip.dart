import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/tooltip/orion_tooltip_controller.dart';
import 'package:orion_ui/src/components/tooltip/orion_tooltip_geometry.dart';
import 'package:orion_ui/src/components/tooltip/orion_tooltip_presets.dart';
import 'package:orion_ui/src/components/tooltip/orion_tooltip_style.dart';
import 'package:orion_ui/src/components/tooltip/orion_tooltip_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Supported trigger gesture modes for an [OrionTooltip].
enum OrionTooltipTriggerMode {
  /// Pointer hover on desktop/web, and long-press on mobile touch (default).
  hoverAndLongPress,

  /// Desktop/web pointer hover only.
  hoverOnly,

  /// Long-press only on mobile touch devices.
  longPress,

  /// Immediate tap on mobile touch devices.
  tap,

  /// Manual control strictly via [OrionTooltipController].
  manual,
}

/// Global warm window coordinator shared across all [OrionTooltip] instances.
///
/// Once any tooltip has opened or recently closed, any sibling tooltip hovered
/// within the [warmWindowMs] opens instantly with 0ms delay.
abstract final class OrionTooltipWarmCoordinator {
  static int _lastHiddenAt = 0;
  static int _activeCount = 0;
  static const int warmWindowMs = 300;

  static bool get isWarm {
    if (_activeCount > 0) return true;
    if (_lastHiddenAt == 0) return false;
    final int now = DateTime.now().millisecondsSinceEpoch;
    return (now - _lastHiddenAt) < warmWindowMs;
  }

  static void markOpened() {
    _activeCount++;
  }

  static void markHidden() {
    if (_activeCount > 0) _activeCount--;
    _lastHiddenAt = DateTime.now().millisecondsSinceEpoch;
  }

  /// Resets the warm window coordinator state (primarily for automated testing).
  @visibleForTesting
  static void reset() {
    _lastHiddenAt = 0;
    _activeCount = 0;
  }
}

/// A physics-driven micro-contextual tooltip surface.
///
/// Features:
/// - Directional emergence: blossoms out of the trigger anchor with normalized
///   alignment scaling ($0.94 \to 1.0$) and a $4\text{ pt}$ directional rise.
/// - Global Warm Window Engine: sibling tooltips entered within $300\text{ ms}$
///   open instantly with 0ms wait delay, making toolbar sweeps fast and responsive.
/// - Autonomous Caret Beak: vector arrow painted dynamically toward trigger anchor.
/// - Static frosted blur isolation option (`frosted: true`).
/// - Non-blocking pass-through overlay that dismisses on outside touch, scroll,
///   or Escape key without consuming parent gestures.
/// - WCAG 2.1 AA accessible hover, focus, and semantics support.
class OrionTooltip extends StatefulWidget {
  const OrionTooltip({
    super.key,
    required this.message,
    required this.child,
    this.richMessage,
    this.placement = OrionTooltipPlacement.top,
    this.triggerMode = OrionTooltipTriggerMode.hoverAndLongPress,
    this.waitDuration = const Duration(milliseconds: 250),
    this.showDuration = const Duration(milliseconds: 1800),
    this.autoFlip = true,
    this.controller,
    this.style,
  });

  /// Plain text message displayed inside the tooltip bubble.
  final String message;

  /// Optional rich text or custom widget subtree.
  final Widget? richMessage;

  /// The anchor target widget that triggers the tooltip.
  final Widget child;

  /// Preferred placement relative to the trigger (top, bottom, left, right).
  final OrionTooltipPlacement placement;

  /// Interaction mode driving tooltip emergence.
  final OrionTooltipTriggerMode triggerMode;

  /// Delay duration before showing on cold hover.
  final Duration waitDuration;

  /// Auto-dismiss timer duration when triggered by mobile touch.
  final Duration showDuration;

  /// Whether to auto-flip opposite when colliding with viewport boundaries.
  final bool autoFlip;

  /// Programmatic controller.
  final OrionTooltipController? controller;

  /// Instance style overrides.
  final OrionTooltipStyle? style;

  @override
  State<OrionTooltip> createState() => OrionTooltipState();
}

class OrionTooltipState extends State<OrionTooltip>
    with SingleTickerProviderStateMixin {
  final GlobalKey _triggerKey = GlobalKey();
  final GlobalKey _panelKey = GlobalKey();
  final OverlayPortalController _portalController = OverlayPortalController();

  late final OrionSpringDriver _driver;
  OrionTooltipController? _internalController;
  OrionTooltipController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionTooltipController());

  OrionTooltipResolvedLayout? _resolvedLayout;
  Rect? _lastTriggerRect;
  bool _isClosing = false;
  Timer? _waitTimer;
  Timer? _autoDismissTimer;
  Timer? _leaveTimer;
  ScrollNotificationObserverState? _scrollNotificationObserver;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: const OrionSpringSpec(stiffness: 480.0, dampingRatio: 0.85),
    );
    _driver.addStatusListener(_onDriverStatus);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _attachController();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (_effectiveController.isOpen &&
        event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.escape) {
      hide();
      return true;
    }
    return false;
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
  void didUpdateWidget(OrionTooltip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _waitTimer?.cancel();
    _autoDismissTimer?.cancel();
    _leaveTimer?.cancel();
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
    if (_effectiveController.isOpen) {
      _effectiveController.updateOpenState(false);
      OrionTooltipWarmCoordinator.markHidden();
    }
    _effectiveController.detach();
    _internalController?.dispose();
    _driver.removeStatusListener(_onDriverStatus);
    _driver.dispose();
    super.dispose();
  }

  void _attachController() {
    _effectiveController.attach(
      onShow: () => show(immediate: true),
      onHide: hide,
    );
  }

  void _onDriverStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.01) {
      _isClosing = false;
      _portalController.hide();
      _effectiveController.updateOpenState(false);
      OrionTooltipWarmCoordinator.markHidden();
    }
  }

  Rect? _measureTriggerRect() {
    final BuildContext? currentContext = _triggerKey.currentContext;
    if (currentContext == null || !currentContext.mounted) return null;
    final RenderBox? box = currentContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final Offset globalOffset = box.localToGlobal(Offset.zero);
    return globalOffset & box.size;
  }

  bool _isInsideTooltip(BuildContext notifContext) {
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
    if (!_effectiveController.isOpen || _isClosing) return;

    final BuildContext? notifContext = notification.context;
    if (notifContext != null && _isInsideTooltip(notifContext)) {
      return;
    }

    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0.0) {
      hide();
    } else if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      hide();
    }
  }

  /// Opens the tooltip.
  void show({bool immediate = false}) {
    _leaveTimer?.cancel();
    if (_effectiveController.isOpen && !_isClosing) return;

    final bool isWarm = OrionTooltipWarmCoordinator.isWarm;
    if (immediate || isWarm || widget.waitDuration == Duration.zero) {
      _displayTooltip();
    } else {
      _waitTimer?.cancel();
      _waitTimer = Timer(widget.waitDuration, _displayTooltip);
    }
  }

  void _displayTooltip() {
    if (!mounted) return;
    final Rect? rect = _measureTriggerRect();
    if (rect == null) return;
    _lastTriggerRect = rect;
    _isClosing = false;

    _effectiveController.updateOpenState(true);
    _portalController.show();
    OrionTooltipWarmCoordinator.markOpened();

    final theme = Theme.of(context);
    final style = _resolveStyle(theme);

    if (_driver.reducedMotion) {
      _driver.jumpTo(1.0);
      return;
    }

    _driver.springSpec =
        style.springSpec ??
        const OrionSpringSpec(stiffness: 480.0, dampingRatio: 0.85);
    _driver.retarget(1.0);
  }

  /// Closes the tooltip.
  void hide() {
    _waitTimer?.cancel();
    _autoDismissTimer?.cancel();
    _leaveTimer?.cancel();
    if (!_effectiveController.isOpen || _isClosing) return;
    _isClosing = true;

    if (!mounted) {
      _effectiveController.updateOpenState(false);
      OrionTooltipWarmCoordinator.markHidden();
      return;
    }

    final theme = Theme.of(context);
    final style = _resolveStyle(theme);

    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      _portalController.hide();
      _effectiveController.updateOpenState(false);
      OrionTooltipWarmCoordinator.markHidden();
      return;
    }

    _driver.springSpec =
        style.dismissSpringSpec ??
        const OrionSpringSpec(
          stiffness: 420.0,
          dampingRatio: 1.0,
          clampOvershoot: true,
        );
    _driver.retarget(0.0);
  }

  void _scheduleHide() {
    _waitTimer?.cancel();
    _leaveTimer?.cancel();
    _leaveTimer = Timer(const Duration(milliseconds: 100), hide);
  }

  void _handleTouchTrigger() {
    if (widget.triggerMode == OrionTooltipTriggerMode.tap &&
        _effectiveController.isOpen &&
        !_isClosing) {
      hide();
      return;
    }
    OrionHaptics.trigger(OrionHapticType.selectionClick);
    show(immediate: true);
    _autoDismissTimer?.cancel();
    _autoDismissTimer = Timer(widget.showDuration, hide);
  }

  OrionTooltipStyle _resolveStyle(ThemeData theme) {
    final OrionTooltipTheme tooltipTheme =
        theme.extension<OrionTooltipTheme>() ?? OrionTooltipTheme.fallback;
    return OrionTooltipPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(tooltipTheme.defaultStyle).merge(widget.style);
  }

  Widget _buildOverlay(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final orionTheme = OrionTheme.of(context);
    final style = _resolveStyle(theme);

    final Rect triggerRect =
        _measureTriggerRect() ??
        _lastTriggerRect ??
        const Rect.fromLTWH(0, 0, 0, 0);

    final bool showArrow = style.showArrow ?? true;
    final Size arrowSize = style.arrowSize ?? const Size(10.0, 5.0);
    final double gap = style.gap ?? 6.0;

    final MediaQueryData media = MediaQuery.of(context);
    final Size viewportSize = media.size;
    const EdgeInsets viewportPadding = EdgeInsets.all(8.0);

    final BorderRadius radius =
        style.borderRadius ?? BorderRadius.circular(OrionRadii.radius8);
    final Color bg = style.backgroundColor ?? scheme.inverseSurface;
    final bool frosted = style.frosted ?? false;

    // Initial pre-layout estimate
    final Size estimatedSize = const Size(80.0, 32.0);
    _resolvedLayout ??= OrionTooltipGeometry.resolve(
      triggerRect: triggerRect,
      tooltipSize: estimatedSize,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: widget.placement,
      gap: gap,
      autoFlip: widget.autoFlip,
      showArrow: showArrow,
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

    final Widget content =
        widget.richMessage ??
        Text(
          widget.message,
          style:
              style.textStyle ??
              TextStyle(
                fontSize: 12.0,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.1,
                color: scheme.onInverseSurface,
              ),
        );

    final Widget cardSurface = Container(
      key: _panelKey,
      constraints: BoxConstraints(maxWidth: style.maxWidth ?? 260.0),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: style.shadow ?? OrionThemeData.defaultShadow,
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
                    style.padding ??
                    const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space12,
                      vertical: OrionSpacing.space4,
                    ),
                child: content,
              ),
            ],
          ),
        ),
      ),
    );

    final Widget panel;
    if (showArrow) {
      panel = CustomPaint(
        painter: OrionTooltipArrowPainter(
          color: frosted ? bg.withValues(alpha: 0.70) : bg,
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

    return Stack(
      children: [
        // Outside barrier (translucent, passive non-blocking click-away)
        Positioned.fill(
          child: Listener(
            behavior: HitTestBehavior.translucent,
            onPointerDown: (event) {
              if (_lastTriggerRect != null &&
                  _lastTriggerRect!.contains(event.position)) {
                return;
              }
              hide();
            },
          ),
        ),

        // Positioned Tooltip Bubble
        Positioned.fill(
          child: CustomSingleChildLayout(
            delegate: OrionTooltipLayoutDelegate(
              triggerRect: triggerRect,
              viewportPadding: viewportPadding,
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
                final double scale = 0.94 + (0.06 * progress);
                final double opacity = (progress * 2.0).clamp(0.0, 1.0);
                final Alignment origin =
                    _resolvedLayout?.transformOrigin ?? Alignment.bottomCenter;

                final Offset translation = switch (_resolvedLayout?.placement ??
                    widget.placement) {
                  OrionTooltipPlacement.top => Offset(
                    0.0,
                    (1.0 - progress.clamp(0.0, 1.0)) * 4.0,
                  ),
                  OrionTooltipPlacement.bottom => Offset(
                    0.0,
                    -(1.0 - progress.clamp(0.0, 1.0)) * 4.0,
                  ),
                  OrionTooltipPlacement.left => Offset(
                    (1.0 - progress.clamp(0.0, 1.0)) * 4.0,
                    0.0,
                  ),
                  OrionTooltipPlacement.right => Offset(
                    -(1.0 - progress.clamp(0.0, 1.0)) * 4.0,
                    0.0,
                  ),
                };

                final Widget contentWidget = opacity < 1.0
                    ? Opacity(opacity: opacity, child: child)
                    : child!;

                return Transform.translate(
                  offset: translation,
                  child: Transform.scale(
                    scale: scale,
                    alignment: origin,
                    child: contentWidget,
                  ),
                );
              },
              child: MouseRegion(
                onEnter: (_) => _leaveTimer?.cancel(),
                onExit: (_) => _scheduleHide(),
                child: panel,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = KeyedSubtree(key: _triggerKey, child: widget.child);

    // Apply gesture and mouse listeners based on triggerMode
    final bool enableHover =
        widget.triggerMode == OrionTooltipTriggerMode.hoverAndLongPress ||
        widget.triggerMode == OrionTooltipTriggerMode.hoverOnly;

    final bool enableLongPress =
        widget.triggerMode == OrionTooltipTriggerMode.hoverAndLongPress ||
        widget.triggerMode == OrionTooltipTriggerMode.longPress;

    final bool enableTap = widget.triggerMode == OrionTooltipTriggerMode.tap;

    if (enableHover) {
      trigger = MouseRegion(
        onEnter: (_) => show(),
        onExit: (_) => _scheduleHide(),
        child: trigger,
      );
    }

    if (enableLongPress || enableTap) {
      trigger = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onLongPress: enableLongPress ? _handleTouchTrigger : null,
        onTap: enableTap ? _handleTouchTrigger : null,
        child: trigger,
      );
    }

    return Semantics(
      tooltip: widget.message,
      child: OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: _buildOverlay,
        child: trigger,
      ),
    );
  }
}

class OrionTooltipLayoutDelegate extends SingleChildLayoutDelegate {
  const OrionTooltipLayoutDelegate({
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
  final OrionTooltipPlacement preferredPlacement;
  final double gap;
  final bool autoFlip;
  final bool showArrow;
  final Size arrowSize;
  final ValueChanged<OrionTooltipResolvedLayout> onLayoutResolved;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final layout = OrionTooltipGeometry.resolve(
      triggerRect: triggerRect,
      tooltipSize: childSize,
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
  bool shouldRelayout(OrionTooltipLayoutDelegate oldDelegate) {
    return triggerRect != oldDelegate.triggerRect ||
        viewportPadding != oldDelegate.viewportPadding ||
        preferredPlacement != oldDelegate.preferredPlacement ||
        gap != oldDelegate.gap ||
        autoFlip != oldDelegate.autoFlip ||
        showArrow != oldDelegate.showArrow ||
        arrowSize != oldDelegate.arrowSize;
  }
}

/// Paints the directional pointing caret arrow for [OrionTooltip].
class OrionTooltipArrowPainter extends CustomPainter {
  const OrionTooltipArrowPainter({
    required this.color,
    required this.arrowSize,
    required this.triggerRect,
    required this.viewportSize,
    required this.viewportPadding,
    required this.preferredPlacement,
    required this.autoFlip,
    required this.gap,
  });

  final Color color;
  final Size arrowSize;
  final Rect triggerRect;
  final Size viewportSize;
  final EdgeInsets viewportPadding;
  final OrionTooltipPlacement preferredPlacement;
  final bool autoFlip;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final layout = OrionTooltipGeometry.resolve(
      triggerRect: triggerRect,
      tooltipSize: size,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      gap: gap,
      autoFlip: autoFlip,
      showArrow: true,
      arrowSize: arrowSize,
    );

    if (layout.arrowOffset == null) return;

    final Offset arrowOffset = layout.arrowOffset!;
    final double x = arrowOffset.dx;
    final double y = arrowOffset.dy;

    final Paint fillPaint = Paint()..color = color;
    final Path path = Path();

    switch (layout.placement) {
      case OrionTooltipPlacement.top:
        // Arrow is at bottom edge of tooltip, pointing down toward trigger
        path.moveTo(x, size.height);
        path.lineTo(x + arrowSize.width, size.height);
        path.lineTo(x + (arrowSize.width / 2.0), y + arrowSize.height);
        path.close();
        canvas.drawPath(path, fillPaint);

      case OrionTooltipPlacement.bottom:
        // Arrow is at top edge of tooltip, pointing up toward trigger
        path.moveTo(x + (arrowSize.width / 2.0), y);
        path.lineTo(x + arrowSize.width, 0);
        path.lineTo(x, 0);
        path.close();
        canvas.drawPath(path, fillPaint);

      case OrionTooltipPlacement.left:
        // Arrow is at right edge of tooltip, pointing right toward trigger
        path.moveTo(size.width, y);
        path.lineTo(size.width, y + arrowSize.width);
        path.lineTo(x + arrowSize.height, y + (arrowSize.width / 2.0));
        path.close();
        canvas.drawPath(path, fillPaint);

      case OrionTooltipPlacement.right:
        // Arrow is at left edge of tooltip, pointing left toward trigger
        path.moveTo(0, y);
        path.lineTo(0, y + arrowSize.width);
        path.lineTo(x, y + (arrowSize.width / 2.0));
        path.close();
        canvas.drawPath(path, fillPaint);
    }
  }

  @override
  bool shouldRepaint(OrionTooltipArrowPainter oldDelegate) {
    return color != oldDelegate.color ||
        arrowSize != oldDelegate.arrowSize ||
        triggerRect != oldDelegate.triggerRect ||
        viewportSize != oldDelegate.viewportSize ||
        viewportPadding != oldDelegate.viewportPadding ||
        preferredPlacement != oldDelegate.preferredPlacement ||
        autoFlip != oldDelegate.autoFlip ||
        gap != oldDelegate.gap;
  }
}
