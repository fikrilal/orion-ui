import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FlutterView, ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
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
  /// Pointer hover and keyboard focus on desktop/web, and long-press on touch
  /// devices (default).
  hoverAndLongPress,

  /// Desktop/web pointer hover and keyboard focus only.
  hoverOnly,

  /// Long-press on touch devices (plus keyboard focus).
  longPress,

  /// Immediate tap toggle (works even when wrapping interactive buttons, plus
  /// keyboard focus).
  tap,

  /// Manual control strictly via [OrionTooltipController].
  manual,
}

class _WarmWindowNotifier extends ValueNotifier<bool> {
  _WarmWindowNotifier(super.value, {required this.onNoListeners});

  final VoidCallback onNoListeners;

  bool get isObserved => hasListeners;

  @override
  void removeListener(VoidCallback listener) {
    super.removeListener(listener);
    if (!hasListeners) {
      onNoListeners();
    }
  }
}

/// Global warm window coordinator shared across all [OrionTooltip] instances.
///
/// Tracks active tooltips so gliding across sibling triggers in a toolbar
/// immediately hands off from the previous tooltip to the next with zero
/// overlap and 0 ms wait delay within [warmWindow].
abstract final class OrionTooltipWarmCoordinator {
  /// Duration in milliseconds after the last tooltip closes during which
  /// sibling tooltips open immediately without waiting for `waitDuration`.
  static const int warmWindowMs = 300;

  /// Warm window cooldown duration.
  static const Duration warmWindow = Duration(milliseconds: warmWindowMs);

  static final Stopwatch _stopwatch = Stopwatch()..start();
  static final Set<Object> _activeTokens = <Object>{};
  static final Map<Object, VoidCallback> _dismissCallbacks =
      <Object, VoidCallback>{};
  static final List<Object> _legacyTokens = <Object>[];

  static int? _lastHiddenStopwatchUs;
  static Duration? _lastHiddenFrameTs;
  static Timer? _uiCooldownTimer;

  static final _WarmWindowNotifier _warmNotifier = _WarmWindowNotifier(
    false,
    onNoListeners: _cancelUiTimer,
  );

  /// Reactive listenable reflecting whether the global warm window is active.
  ///
  /// Only schedules a UI cooldown timer while at least one listener is attached.
  static ValueListenable<bool> get listenable => _warmNotifier;

  static Duration? _currentFrameTimeStamp() {
    try {
      return SchedulerBinding.instance.currentSystemFrameTimeStamp;
    } catch (_) {
      return null;
    }
  }

  static void _cancelUiTimer() {
    _uiCooldownTimer?.cancel();
    _uiCooldownTimer = null;
  }

  static void _scheduleUiCooldownIfObserved() {
    _cancelUiTimer();
    if (!_warmNotifier.isObserved) return;
    _uiCooldownTimer = Timer(warmWindow, () {
      _uiCooldownTimer = null;
      if (_activeTokens.isEmpty && !isWarm) {
        _warmNotifier.value = false;
      }
    });
  }

  /// Whether a tooltip is currently open or closed within [warmWindow].
  static bool get isWarm {
    if (_activeTokens.isNotEmpty) return true;
    final int? hiddenUs = _lastHiddenStopwatchUs;
    if (hiddenUs == null) return false;

    int elapsedMs = (_stopwatch.elapsedMicroseconds - hiddenUs) ~/ 1000;
    final Duration? lastFrame = _lastHiddenFrameTs;
    final Duration? nowFrame = _currentFrameTimeStamp();
    if (lastFrame != null && nowFrame != null) {
      final int frameMs = (nowFrame - lastFrame).inMilliseconds;
      if (frameMs < 0) {
        // Test binding restarted between test cases.
        _lastHiddenStopwatchUs = null;
        _lastHiddenFrameTs = null;
        _warmNotifier.value = false;
        return false;
      }
      if (frameMs > elapsedMs) {
        elapsedMs = frameMs;
      }
    }

    final bool warm = elapsedMs < warmWindowMs;
    if (!warm && _warmNotifier.value) {
      _warmNotifier.value = false;
    }
    return warm;
  }

  /// Registers [token] as an active tooltip, optionally dismissing any other
  /// coordinated tooltip immediately so siblings never overlap.
  static void registerActive(
    Object token, {
    required VoidCallback onForceDismiss,
    bool dismissOthers = true,
  }) {
    _cancelUiTimer();

    if (dismissOthers && _dismissCallbacks.isNotEmpty) {
      final List<MapEntry<Object, VoidCallback>> others = _dismissCallbacks
          .entries
          .where((MapEntry<Object, VoidCallback> e) => !identical(e.key, token))
          .toList(growable: false);
      for (final MapEntry<Object, VoidCallback> entry in others) {
        entry.value();
      }
    }

    _activeTokens.add(token);
    _dismissCallbacks[token] = onForceDismiss;
    _warmNotifier.value = true;
  }

  /// Unregisters [token] when the tooltip closes or disposes, starting the
  /// [warmWindow] cooldown once no tooltips remain active.
  static void unregisterActive(Object token) {
    final bool removed = _activeTokens.remove(token);
    _dismissCallbacks.remove(token);
    if (!removed) return;

    if (_activeTokens.isEmpty) {
      _lastHiddenStopwatchUs = _stopwatch.elapsedMicroseconds;
      _lastHiddenFrameTs = _currentFrameTimeStamp();
      _scheduleUiCooldownIfObserved();
    }
  }

  /// Marks an anonymous tooltip as opened (legacy helper).
  static void markOpened() {
    _cancelUiTimer();
    final Object token = Object();
    _legacyTokens.add(token);
    _activeTokens.add(token);
    _warmNotifier.value = true;
  }

  /// Marks the most recent anonymous tooltip as hidden (legacy helper).
  static void markHidden() {
    if (_legacyTokens.isNotEmpty) {
      final Object token = _legacyTokens.removeLast();
      unregisterActive(token);
    } else if (_activeTokens.isEmpty) {
      _lastHiddenStopwatchUs = _stopwatch.elapsedMicroseconds;
      _lastHiddenFrameTs = _currentFrameTimeStamp();
      _scheduleUiCooldownIfObserved();
    }
  }

  /// Resets the warm window coordinator state (primarily for automated testing).
  @visibleForTesting
  static void reset() {
    _cancelUiTimer();
    _activeTokens.clear();
    _dismissCallbacks.clear();
    _legacyTokens.clear();
    _lastHiddenStopwatchUs = null;
    _lastHiddenFrameTs = null;
    _warmNotifier.value = false;
  }
}

/// A physics-driven micro-contextual tooltip surface.
///
/// Features:
/// - Directional emergence anchored to the trigger edge with crisp spring
///   motion (`0.94 -> 1.0` scale, `4 pt` directional glide, smooth close fade).
/// - Global Warm Window Engine with single-active-tooltip handoff: sibling
///   tooltips entered within `300 ms` dismiss the prior tooltip and open at
///   `0 ms` with zero visual overlap.
/// - Safe-area, soft-keyboard, RTL (`start`/`end`), and narrow-screen
///   cross-axis fallback positioning.
/// - Seamless rounded-tip caret arrow with border-seam bridging and soft shadow.
/// - Works reliably over interactive buttons (`OrionButton`, `IconButton`),
///   keyboard focus (`Tab` + `Escape`), hover-over-tooltip inspection, and
///   rich custom content with automatic foreground `DefaultTextStyle`/`IconTheme`.
class OrionTooltip extends StatefulWidget {
  const OrionTooltip({
    super.key,
    required this.message,
    required this.child,
    this.richMessage,
    this.placement = OrionTooltipPlacement.top,
    this.triggerMode = OrionTooltipTriggerMode.hoverAndLongPress,
    this.tone = OrionTooltipTone.inverted,
    this.waitDuration = const Duration(milliseconds: 250),
    this.showDuration,
    this.autoFlip = true,
    this.showArrow,
    this.enabled = true,
    this.dismissOnTapOutside = true,
    this.dismissOnScroll = true,
    this.excludeFromSemantics = false,
    this.onOpen,
    this.onClose,
    this.controller,
    this.style,
  });

  /// Plain text message displayed inside the tooltip bubble (and exposed to
  /// screen readers unless [excludeFromSemantics] is `true`).
  final String message;

  /// Optional rich text or custom widget subtree rendered instead of [message].
  ///
  /// Automatically wrapped in [DefaultTextStyle] and [IconTheme] matching the
  /// resolved tooltip foreground color.
  final Widget? richMessage;

  /// The anchor target widget that triggers the tooltip.
  final Widget child;

  /// Preferred placement relative to the trigger (`top`, `bottom`, `left`,
  /// `right`, `start`, or `end`).
  final OrionTooltipPlacement placement;

  /// Interaction mode driving tooltip emergence.
  final OrionTooltipTriggerMode triggerMode;

  /// Visual surface tone (`inverted` dark/light pill or `surface` elevated card).
  final OrionTooltipTone tone;

  /// Delay duration before showing on cold pointer hover.
  final Duration waitDuration;

  /// Optional auto-dismiss duration when triggered by touch.
  ///
  /// When `null`:
  /// - Long-press triggers auto-dismiss after `1800 ms`.
  /// - Tap triggers stay open until toggled, tapped outside, scrolled, or
  ///   dismissed with `Escape`.
  ///
  /// Passing [Duration.zero] explicitly disables auto-dismiss for all touch
  /// triggers.
  final Duration? showDuration;

  /// Whether to auto-flip opposite (or fall back across axes on narrow screens)
  /// when colliding with viewport, safe-area, or keyboard boundaries.
  final bool autoFlip;

  /// Overrides [OrionTooltipStyle.showArrow] for this tooltip instance.
  final bool? showArrow;

  /// Whether the tooltip can open. When `false`, gestures and controller calls
  /// are ignored and any open tooltip closes.
  final bool enabled;

  /// Whether tapping outside the tooltip and trigger dismisses it.
  final bool dismissOnTapOutside;

  /// Whether scrolling an ancestor scrollable dismisses the tooltip.
  final bool dismissOnScroll;

  /// Whether to omit the tooltip from the trigger's semantics node.
  final bool excludeFromSemantics;

  /// Called when the tooltip transitions from closed to open.
  final VoidCallback? onOpen;

  /// Called when the tooltip finishes closing.
  final VoidCallback? onClose;

  /// Optional programmatic controller.
  final OrionTooltipController? controller;

  /// Instance style overrides.
  final OrionTooltipStyle? style;

  @override
  State<OrionTooltip> createState() => OrionTooltipState();
}

class OrionTooltipState extends State<OrionTooltip>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  static const Duration _defaultLongPressShowDuration = Duration(
    milliseconds: 1800,
  );
  static const Duration _hoverLeaveBridgeDuration = Duration(milliseconds: 140);

  final GlobalKey _triggerKey = GlobalKey();
  final GlobalKey _panelKey = GlobalKey();
  final OverlayPortalController _portalController = OverlayPortalController();

  late final OrionSpringDriver _driver;
  OrionTooltipController? _internalController;
  OrionTooltipController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionTooltipController());

  OrionTooltipResolvedLayout? _resolvedLayout;
  Rect? _lastTriggerRect;
  bool _isShowing = false;
  bool _isClosing = false;
  bool _openedByHover = false;
  bool _openedByFocus = false;

  // Passive tap tracking so triggerMode.tap works even over OrionButton/IconButton.
  int? _tapPointer;
  Offset? _tapDownGlobal;
  bool _tapCancelled = false;
  bool _suppressNextFocus = false;

  Timer? _waitTimer;
  Timer? _autoDismissTimer;
  Timer? _leaveTimer;
  ScrollNotificationObserverState? _scrollNotificationObserver;

  bool get _canShow =>
      widget.enabled &&
      (widget.richMessage != null || widget.message.isNotEmpty);

  bool get _enableHover =>
      widget.triggerMode == OrionTooltipTriggerMode.hoverAndLongPress ||
      widget.triggerMode == OrionTooltipTriggerMode.hoverOnly;

  bool get _enableLongPress =>
      widget.triggerMode == OrionTooltipTriggerMode.hoverAndLongPress ||
      widget.triggerMode == OrionTooltipTriggerMode.longPress;

  bool get _enableTap => widget.triggerMode == OrionTooltipTriggerMode.tap;

  bool get _enableFocus => widget.triggerMode != OrionTooltipTriggerMode.manual;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: const OrionSpringSpec(stiffness: 480.0, dampingRatio: 0.85),
    );
    _driver.addStatusListener(_onDriverStatus);
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
    _attachController(_effectiveController);
  }

  @override
  void didChangeMetrics() {
    if (!mounted || !_isShowing) return;
    _resolvedLayout = null;
    setState(() {});
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (_isShowing &&
        !_isClosing &&
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
      final OrionTooltipController? previous =
          oldWidget.controller ?? _internalController;
      previous?.updateOpenState(false, notify: false);
      previous?.detach();
      if (oldWidget.controller == null && widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      }
      _attachController(_effectiveController);
      _effectiveController.updateOpenState(
        _isShowing && !_isClosing,
        notify: false,
      );
    }

    if (widget.triggerMode != oldWidget.triggerMode) {
      _waitTimer?.cancel();
      _leaveTimer?.cancel();
      _autoDismissTimer?.cancel();
      _tapPointer = null;
      _tapDownGlobal = null;
      _tapCancelled = false;
    }

    if (widget.placement != oldWidget.placement ||
        widget.autoFlip != oldWidget.autoFlip ||
        widget.showArrow != oldWidget.showArrow ||
        widget.tone != oldWidget.tone ||
        widget.style != oldWidget.style ||
        widget.message != oldWidget.message) {
      _resolvedLayout = null;
    }

    if (!_canShow && _isShowing) {
      _waitTimer?.cancel();
      _leaveTimer?.cancel();
      _autoDismissTimer?.cancel();
      _isClosing = false;
      _isShowing = false;
      _openedByHover = false;
      _openedByFocus = false;
      _driver.jumpTo(0.0);
      _effectiveController.updateOpenState(false, notify: false);
      OrionTooltipWarmCoordinator.unregisterActive(this);
      SchedulerBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isShowing && _portalController.isShowing) {
          _portalController.hide();
        }
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _waitTimer?.cancel();
    _autoDismissTimer?.cancel();
    _leaveTimer?.cancel();
    _scrollNotificationObserver?.removeListener(_handleScrollNotification);
    _scrollNotificationObserver = null;
    OrionTooltipWarmCoordinator.unregisterActive(this);
    _effectiveController.updateOpenState(false, notify: false);
    _effectiveController.detach();
    _internalController?.dispose();
    _driver.removeStatusListener(_onDriverStatus);
    _driver.dispose();
    super.dispose();
  }

  void _attachController(OrionTooltipController controller) {
    controller.attach(
      onShow: () {
        _openedByHover = false;
        _openedByFocus = false;
        show(immediate: true);
      },
      onHide: hide,
    );
  }

  void _onDriverStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.01) {
      _isClosing = false;
      _isShowing = false;
      if (_portalController.isShowing) {
        _portalController.hide();
      }
      widget.onClose?.call();
    }
  }

  RenderBox? _findOverlayBox() {
    final OverlayState? overlay = Overlay.maybeOf(context);
    final RenderObject? ro = overlay?.context.findRenderObject();
    return ro is RenderBox && ro.hasSize ? ro : null;
  }

  Rect? _measureTriggerRect([RenderBox? overlayBox]) {
    final BuildContext? currentContext = _triggerKey.currentContext;
    if (currentContext == null || !currentContext.mounted) return null;
    final RenderBox? box = currentContext.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final Offset offset = box.localToGlobal(Offset.zero, ancestor: overlayBox);
    return offset & box.size;
  }

  EdgeInsets _resolveViewportPadding(
    BuildContext overlayContext,
    RenderBox? overlayBox,
  ) {
    final OverlayState? overlay = Overlay.maybeOf(context);
    final FlutterView? view = View.maybeOf(overlayContext);
    final double dpr = view != null && view.devicePixelRatio > 0
        ? view.devicePixelRatio
        : 1.0;

    final MediaQueryData localMedia = MediaQuery.of(overlayContext);
    final MediaQueryData? overlayMedia = overlay != null
        ? MediaQuery.maybeOf(overlay.context)
        : null;

    // Only apply raw FlutterView safe-area/IME insets along edges where the
    // enclosing Overlay actually touches the physical screen boundary.
    final Offset overlayOrigin =
        overlayBox?.localToGlobal(Offset.zero) ?? Offset.zero;
    final Size overlaySize = overlayBox?.size ?? localMedia.size;
    final Size viewLogicalSize = view != null
        ? view.physicalSize / dpr
        : localMedia.size;

    final bool touchesLeft = overlayOrigin.dx <= 1.0;
    final bool touchesTop = overlayOrigin.dy <= 1.0;
    final bool touchesRight =
        (overlayOrigin.dx + overlaySize.width) >= (viewLogicalSize.width - 1.0);
    final bool touchesBottom =
        (overlayOrigin.dy + overlaySize.height) >=
        (viewLogicalSize.height - 1.0);

    final double viewLeft = view != null && touchesLeft
        ? view.padding.left / dpr
        : 0.0;
    final double viewTop = view != null && touchesTop
        ? view.padding.top / dpr
        : 0.0;
    final double viewRight = view != null && touchesRight
        ? view.padding.right / dpr
        : 0.0;
    final double viewBottom = view != null && touchesBottom
        ? view.padding.bottom / dpr
        : 0.0;
    final double viewInsetBottom = view != null && touchesBottom
        ? view.viewInsets.bottom / dpr
        : 0.0;

    final double safeLeft = math.max(
      localMedia.padding.left,
      math.max(overlayMedia?.padding.left ?? 0.0, viewLeft),
    );
    final double safeTop = math.max(
      localMedia.padding.top,
      math.max(overlayMedia?.padding.top ?? 0.0, viewTop),
    );
    final double safeRight = math.max(
      localMedia.padding.right,
      math.max(overlayMedia?.padding.right ?? 0.0, viewRight),
    );
    final double safeBottom = math.max(
      math.max(localMedia.padding.bottom, overlayMedia?.padding.bottom ?? 0.0),
      math.max(
        viewBottom,
        math.max(
          localMedia.viewInsets.bottom,
          math.max(overlayMedia?.viewInsets.bottom ?? 0.0, viewInsetBottom),
        ),
      ),
    );

    return EdgeInsets.fromLTRB(
      safeLeft + 8.0,
      safeTop + 8.0,
      safeRight + 8.0,
      safeBottom + 8.0,
    );
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
    if (!widget.dismissOnScroll) return;
    if (!_isShowing || _isClosing) return;

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

  void _handleCoordinatorDismiss() {
    if (!mounted) return;
    hide(immediate: true);
  }

  /// Opens the tooltip.
  void show({bool immediate = false}) {
    if (!_canShow) return;
    _leaveTimer?.cancel();
    if (_isShowing && !_isClosing) return;

    final bool isWarm = OrionTooltipWarmCoordinator.isWarm;
    if (immediate || isWarm || widget.waitDuration == Duration.zero) {
      _waitTimer?.cancel();
      _displayTooltip();
    } else {
      _waitTimer?.cancel();
      _waitTimer = Timer(widget.waitDuration, _displayTooltip);
    }
  }

  void _displayTooltip() {
    if (!mounted || !_canShow) return;
    final RenderBox? overlayBox = _findOverlayBox();
    final Rect? rect = _measureTriggerRect(overlayBox);
    if (rect == null) return;

    final bool wasOpen = _isShowing && !_isClosing;
    _lastTriggerRect = rect;
    _resolvedLayout = null;
    _isShowing = true;
    _isClosing = false;

    final bool participateInWarmHandoff =
        widget.triggerMode != OrionTooltipTriggerMode.manual;
    OrionTooltipWarmCoordinator.registerActive(
      this,
      onForceDismiss: _handleCoordinatorDismiss,
      dismissOthers: participateInWarmHandoff,
    );

    _effectiveController.updateOpenState(true);
    if (!_portalController.isShowing) {
      _portalController.show();
    }
    if (!wasOpen) {
      widget.onOpen?.call();
    }

    final ThemeData theme = Theme.of(context);
    final OrionTooltipStyle style = _resolveStyle(theme);

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
  ///
  /// Pass `immediate: true` to snap closed on the current frame (used for
  /// warm-window sibling handoffs and reduced motion).
  void hide({bool immediate = false}) {
    _waitTimer?.cancel();
    _autoDismissTimer?.cancel();
    _leaveTimer?.cancel();

    if (!_isShowing || (_isClosing && !immediate)) return;

    _openedByHover = false;
    _openedByFocus = false;
    _effectiveController.updateOpenState(false);
    OrionTooltipWarmCoordinator.unregisterActive(this);

    if (!mounted || immediate || _driver.reducedMotion) {
      _isClosing = false;
      _isShowing = false;
      _driver.jumpTo(0.0);
      if (mounted && _portalController.isShowing) {
        _portalController.hide();
      }
      if (mounted) {
        widget.onClose?.call();
      }
      return;
    }

    _isClosing = true;
    final ThemeData theme = Theme.of(context);
    final OrionTooltipStyle style = _resolveStyle(theme);

    _driver.springSpec =
        style.dismissSpringSpec ??
        const OrionSpringSpec(
          stiffness: 520.0,
          dampingRatio: 1.0,
          clampOvershoot: true,
        );
    _driver.retarget(0.0);
  }

  void _scheduleHide() {
    _waitTimer?.cancel();
    _leaveTimer?.cancel();
    if (!_isShowing || _isClosing) return;
    _leaveTimer = Timer(_hoverLeaveBridgeDuration, hide);
  }

  void _handleHoverEnter() {
    if (!_canShow) return;
    _openedByHover = true;
    show();
  }

  void _handleHoverExit() {
    _waitTimer?.cancel();
    if (_openedByHover) {
      _scheduleHide();
    }
  }

  void _handleLongPressTrigger() {
    if (!_canShow) return;
    _openedByHover = false;
    _openedByFocus = false;
    OrionHaptics.trigger(OrionHapticType.selectionClick);
    show(immediate: true);

    final Duration autoHide =
        widget.showDuration ?? _defaultLongPressShowDuration;
    _autoDismissTimer?.cancel();
    if (autoHide > Duration.zero) {
      _autoDismissTimer = Timer(autoHide, hide);
    }
  }

  void _handleTapTrigger() {
    if (!_canShow) return;
    if (_isShowing && !_isClosing) {
      hide();
      return;
    }
    _openedByHover = false;
    _openedByFocus = false;
    OrionHaptics.trigger(OrionHapticType.selectionClick);
    show(immediate: true);

    final Duration? autoHide = widget.showDuration;
    _autoDismissTimer?.cancel();
    if (autoHide != null && autoHide > Duration.zero) {
      _autoDismissTimer = Timer(autoHide, hide);
    }
  }

  void _handleFocusChange(bool hasFocus) {
    if (!_enableFocus || !_canShow) return;
    if (hasFocus) {
      if (_suppressNextFocus) return;
      if (FocusManager.instance.highlightMode !=
          FocusHighlightMode.traditional) {
        return;
      }
      _openedByHover = false;
      _openedByFocus = true;
      show(immediate: true);
    } else if (_openedByFocus) {
      hide();
    }
  }

  void _onTriggerPointerDown(PointerDownEvent event) {
    _suppressNextFocus = true;
    if (!_canShow) return;

    if (_enableHover &&
        !_enableTap &&
        event.kind == PointerDeviceKind.mouse &&
        _isShowing &&
        !_isClosing) {
      hide();
      return;
    }

    if (!_enableTap) return;
    if (event.kind == PointerDeviceKind.mouse &&
        (event.buttons & kPrimaryMouseButton) == 0) {
      return;
    }
    _tapPointer = event.pointer;
    _tapDownGlobal = event.position;
    _tapCancelled = false;
  }

  void _onTriggerPointerMove(PointerMoveEvent event) {
    if (_tapPointer != event.pointer || _tapCancelled) return;
    if (_tapDownGlobal != null &&
        (event.position - _tapDownGlobal!).distance > kTouchSlop) {
      _tapCancelled = true;
    }
  }

  void _onTriggerPointerUp(PointerUpEvent event) {
    Future<void>.microtask(() => _suppressNextFocus = false);
    if (_tapPointer != event.pointer) return;
    final bool cancelled = _tapCancelled;
    _tapPointer = null;
    _tapDownGlobal = null;
    _tapCancelled = false;
    if (cancelled || !_enableTap || !_canShow) return;

    final RenderBox? overlayBox = _findOverlayBox();
    final Rect? triggerRect = _measureTriggerRect(overlayBox);
    if (triggerRect != null) {
      final Offset releaseLocal = overlayBox != null
          ? overlayBox.globalToLocal(event.position)
          : event.position;
      if (!triggerRect.inflate(8.0).contains(releaseLocal)) {
        return;
      }
    }
    _handleTapTrigger();
  }

  void _onTriggerPointerCancel(PointerCancelEvent event) {
    Future<void>.microtask(() => _suppressNextFocus = false);
    if (_tapPointer != event.pointer) return;
    _tapPointer = null;
    _tapDownGlobal = null;
    _tapCancelled = false;
  }

  OrionTooltipStyle _resolveStyle(ThemeData theme) {
    final OrionTooltipTheme tooltipTheme =
        theme.extension<OrionTooltipTheme>() ?? OrionTooltipTheme.fallback;
    return OrionTooltipPresets.resolve(
      scheme: theme.colorScheme,
      tone: widget.tone,
    ).merge(tooltipTheme.defaultStyle).merge(widget.style);
  }

  Alignment _inferredOrigin(OrionTooltipPlacement physicalPlacement) {
    return switch (physicalPlacement) {
      OrionTooltipPlacement.top => Alignment.bottomCenter,
      OrionTooltipPlacement.bottom => Alignment.topCenter,
      OrionTooltipPlacement.left => Alignment.centerRight,
      OrionTooltipPlacement.right => Alignment.centerLeft,
      OrionTooltipPlacement.start ||
      OrionTooltipPlacement.end => Alignment.bottomCenter,
    };
  }

  Widget _buildOverlay(BuildContext overlayContext) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = scheme.brightness == Brightness.dark;
    final OrionThemeData orionTheme = OrionTheme.of(context);
    final OrionTooltipTheme tooltipTheme =
        theme.extension<OrionTooltipTheme>() ?? OrionTooltipTheme.fallback;
    final OrionTooltipStyle style = _resolveStyle(theme);
    final TextDirection textDirection = Directionality.of(context);

    final RenderBox? overlayBox = _findOverlayBox();
    final Rect? measuredRect = _measureTriggerRect(overlayBox);
    if (measuredRect != null) {
      _lastTriggerRect = measuredRect;
    }
    final Rect triggerRect =
        measuredRect ?? _lastTriggerRect ?? const Rect.fromLTWH(0, 0, 0, 0);

    final bool showArrow = widget.showArrow ?? style.showArrow ?? true;
    final Size arrowSize = style.arrowSize ?? const Size(10.0, 5.0);
    final double gap = style.gap ?? 6.0;

    final Size viewportSize = overlayBox?.size ?? MediaQuery.sizeOf(context);
    final EdgeInsets viewportPadding = _resolveViewportPadding(
      overlayContext,
      overlayBox,
    );

    final BorderRadius radius =
        style.borderRadius ?? BorderRadius.circular(OrionRadii.radius8);
    final double maxCornerRadius = math.max(
      math.max(radius.topLeft.x, radius.topRight.x),
      math.max(radius.bottomLeft.x, radius.bottomRight.x),
    );
    final double arrowEdgeInset = math.max(6.0, maxCornerRadius);

    final Color bg = style.backgroundColor ?? scheme.inverseSurface;
    final bool frosted = style.frosted ?? false;
    final Color effectiveFill = frosted
        ? bg.withValues(alpha: isDark ? 0.80 : 0.84)
        : bg;

    final bool callerSetBorderWidth =
        widget.style?.borderWidth != null ||
        tooltipTheme.defaultStyle?.borderWidth != null;
    final double effectiveBorderWidth =
        (frosted && !callerSetBorderWidth && (style.borderWidth ?? 0.0) == 0.0)
        ? 0.75
        : (style.borderWidth ?? 0.0);
    final Color effectiveBorderColor =
        (frosted &&
            widget.style?.borderColor == null &&
            tooltipTheme.defaultStyle?.borderColor == null &&
            widget.tone == OrionTooltipTone.inverted)
        ? (isDark ? const Color(0x24000000) : const Color(0x2EFFFFFF))
        : (style.borderColor ?? Colors.transparent);

    final List<BoxShadow> shadows = style.shadow ?? const <BoxShadow>[];

    final double availableWidth = math.max(
      40.0,
      viewportSize.width - viewportPadding.horizontal,
    );
    final double effectiveMaxWidth = math.min(
      style.maxWidth ?? 260.0,
      availableWidth,
    );

    final TextStyle effectiveTextStyle =
        style.textStyle ??
        TextStyle(
          fontSize: 12.0,
          fontWeight: FontWeight.w500,
          height: 1.35,
          letterSpacing: -0.1,
          color: widget.tone == OrionTooltipTone.surface
              ? scheme.onSurface
              : scheme.onInverseSurface,
        );

    final Widget surfaceBackdrop = frosted
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: orionTheme.blurSigma,
              sigmaY: orionTheme.blurSigma,
            ),
            child: ColoredBox(color: effectiveFill),
          )
        : ColoredBox(color: effectiveFill);

    final Widget rawContent =
        widget.richMessage ?? Text(widget.message, style: effectiveTextStyle);

    final Widget styledContent = DefaultTextStyle.merge(
      style: effectiveTextStyle,
      child: IconTheme.merge(
        data: IconThemeData(
          color: effectiveTextStyle.color,
          size: (effectiveTextStyle.fontSize ?? 12.0) + 2.0,
        ),
        child: rawContent,
      ),
    );

    final Widget cardSurface = Container(
      key: _panelKey,
      constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: shadows.isEmpty ? null : shadows,
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: radius,
          border: effectiveBorderWidth > 0 && effectiveBorderColor.a > 0
              ? Border.all(
                  color: effectiveBorderColor,
                  width: effectiveBorderWidth,
                )
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
                  padding:
                      style.padding ??
                      const EdgeInsets.symmetric(
                        horizontal: 10.0,
                        vertical: 6.0,
                      ),
                  child: styledContent,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    final Widget panel;
    if (showArrow) {
      final OrionTooltipArrowPainter arrowPainter = OrionTooltipArrowPainter(
        color: effectiveFill,
        borderColor: effectiveBorderColor,
        borderWidth: effectiveBorderWidth,
        arrowSize: arrowSize,
        arrowEdgeInset: arrowEdgeInset,
        triggerRect: triggerRect,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: widget.placement,
        autoFlip: widget.autoFlip,
        gap: gap,
        textDirection: textDirection,
        isDark: isDark,
        hasShadow: shadows.isNotEmpty,
      );
      panel = CustomPaint(
        painter: arrowPainter,
        foregroundPainter: _OrionTooltipArrowForegroundPainter(arrowPainter),
        child: cardSurface,
      );
    } else {
      panel = cardSurface;
    }

    final Widget hoverablePanel = _enableHover
        ? MouseRegion(
            onEnter: (_) {
              if (_openedByHover) {
                _leaveTimer?.cancel();
              }
            },
            onExit: (_) {
              if (_openedByHover) {
                _scheduleHide();
              }
            },
            child: panel,
          )
        : panel;

    final OrionTooltipPlacement fallbackPhysical =
        OrionTooltipGeometry.resolvePhysicalPlacement(
          widget.placement,
          textDirection: textDirection,
        );

    return Stack(
      children: <Widget>[
        // Passive non-blocking click-away barrier
        if (widget.dismissOnTapOutside)
          Positioned.fill(
            child: Listener(
              behavior: HitTestBehavior.translucent,
              onPointerDown: (PointerDownEvent event) {
                final Rect? currentTrigger =
                    _measureTriggerRect(_findOverlayBox()) ?? _lastTriggerRect;
                if (currentTrigger != null &&
                    currentTrigger.contains(event.localPosition)) {
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
              arrowEdgeInset: arrowEdgeInset,
              textDirection: textDirection,
              onLayoutResolved: (OrionTooltipResolvedLayout layout) {
                if (_resolvedLayout != layout) {
                  _resolvedLayout = layout;
                }
              },
            ),
            child: AnimatedBuilder(
              animation: _driver,
              builder: (BuildContext context, Widget? child) {
                final double progress = _driver.value;
                final double scale = 0.94 + (0.06 * progress);
                final double opacity = _isClosing
                    ? progress.clamp(0.0, 1.0)
                    : (progress * 2.2).clamp(0.0, 1.0);
                final OrionTooltipPlacement activePlacement =
                    _resolvedLayout?.placement ?? fallbackPhysical;
                final Alignment origin =
                    _resolvedLayout?.transformOrigin ??
                    _inferredOrigin(activePlacement);
                final double travel = (1.0 - progress.clamp(0.0, 1.0)) * 4.0;

                final Offset translation = switch (activePlacement) {
                  OrionTooltipPlacement.top => Offset(0.0, travel),
                  OrionTooltipPlacement.bottom => Offset(0.0, -travel),
                  OrionTooltipPlacement.left => Offset(travel, 0.0),
                  OrionTooltipPlacement.right => Offset(-travel, 0.0),
                  OrionTooltipPlacement.start ||
                  OrionTooltipPlacement.end => Offset(0.0, travel),
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
              child: hoverablePanel,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget trigger = KeyedSubtree(key: _triggerKey, child: widget.child);

    if (_enableLongPress) {
      trigger = GestureDetector(
        behavior: HitTestBehavior.translucent,
        onLongPress: _handleLongPressTrigger,
        child: trigger,
      );
    }

    if (_enableTap || _enableHover || _enableFocus) {
      trigger = Listener(
        behavior: _enableTap
            ? HitTestBehavior.opaque
            : HitTestBehavior.translucent,
        onPointerDown: _onTriggerPointerDown,
        onPointerMove: _onTriggerPointerMove,
        onPointerUp: _onTriggerPointerUp,
        onPointerCancel: _onTriggerPointerCancel,
        child: trigger,
      );
    }

    if (_enableHover) {
      trigger = MouseRegion(
        onEnter: (_) => _handleHoverEnter(),
        onExit: (_) => _handleHoverExit(),
        child: trigger,
      );
    }

    if (_enableFocus) {
      trigger = Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onFocusChange: _handleFocusChange,
        child: trigger,
      );
    }

    if (!widget.excludeFromSemantics && _canShow && widget.message.isNotEmpty) {
      trigger = Semantics(tooltip: widget.message, child: trigger);
    }

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: _buildOverlay,
      child: trigger,
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
    this.arrowEdgeInset = 8.0,
    this.textDirection = TextDirection.ltr,
  });

  final Rect triggerRect;
  final EdgeInsets viewportPadding;
  final OrionTooltipPlacement preferredPlacement;
  final double gap;
  final bool autoFlip;
  final bool showArrow;
  final Size arrowSize;
  final double arrowEdgeInset;
  final TextDirection textDirection;
  final ValueChanged<OrionTooltipResolvedLayout> onLayoutResolved;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) {
    return constraints.loosen();
  }

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    final OrionTooltipResolvedLayout layout = OrionTooltipGeometry.resolve(
      triggerRect: triggerRect,
      tooltipSize: childSize,
      viewportSize: size,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      gap: gap,
      autoFlip: autoFlip,
      showArrow: showArrow,
      arrowSize: arrowSize,
      arrowEdgeInset: arrowEdgeInset,
      textDirection: textDirection,
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
        arrowSize != oldDelegate.arrowSize ||
        arrowEdgeInset != oldDelegate.arrowEdgeInset ||
        textDirection != oldDelegate.textDirection;
  }
}

/// Paints the directional pointing caret arrow for [OrionTooltip], including a
/// soft elevation shadow behind the card and a seamless rounded-tip foreground
/// fill + hairline border bridge.
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
    this.borderColor = Colors.transparent,
    this.borderWidth = 0.0,
    this.arrowEdgeInset = 8.0,
    this.textDirection = TextDirection.ltr,
    this.isDark = false,
    this.hasShadow = true,
  });

  final Color color;
  final Color borderColor;
  final double borderWidth;
  final Size arrowSize;
  final double arrowEdgeInset;
  final Rect triggerRect;
  final Size viewportSize;
  final EdgeInsets viewportPadding;
  final OrionTooltipPlacement preferredPlacement;
  final bool autoFlip;
  final double gap;
  final TextDirection textDirection;
  final bool isDark;
  final bool hasShadow;

  OrionTooltipResolvedLayout _resolveLayout(Size size) {
    return OrionTooltipGeometry.resolve(
      triggerRect: triggerRect,
      tooltipSize: size,
      viewportSize: viewportSize,
      viewportPadding: viewportPadding,
      preferredPlacement: preferredPlacement,
      gap: gap,
      autoFlip: autoFlip,
      showArrow: true,
      arrowSize: arrowSize,
      arrowEdgeInset: arrowEdgeInset,
      textDirection: textDirection,
    );
  }

  Path _buildFillPath(
    OrionTooltipResolvedLayout layout,
    Size size, {
    required double overlap,
  }) {
    final Offset arrowOffset = layout.arrowOffset!;
    final double x = arrowOffset.dx;
    final double y = arrowOffset.dy;
    final double w = arrowSize.width;
    final double h = arrowSize.height;
    final double tipCurve = math.min(1.25, math.min(w * 0.2, h * 0.35));

    final Path path = Path();
    switch (layout.placement) {
      case OrionTooltipPlacement.top:
        // Bottom edge of tooltip, pointing down toward trigger.
        final double baseY = size.height;
        final double tipY = baseY + h;
        final double midX = x + (w / 2.0);
        path
          ..moveTo(x, baseY - overlap)
          ..lineTo(x, baseY)
          ..lineTo(midX - tipCurve, tipY - tipCurve)
          ..quadraticBezierTo(midX, tipY, midX + tipCurve, tipY - tipCurve)
          ..lineTo(x + w, baseY)
          ..lineTo(x + w, baseY - overlap)
          ..close();

      case OrionTooltipPlacement.bottom:
        // Top edge of tooltip, pointing up toward trigger.
        final double tipY = -h;
        final double midX = x + (w / 2.0);
        path
          ..moveTo(x, overlap)
          ..lineTo(x, 0.0)
          ..lineTo(midX - tipCurve, tipY + tipCurve)
          ..quadraticBezierTo(midX, tipY, midX + tipCurve, tipY + tipCurve)
          ..lineTo(x + w, 0.0)
          ..lineTo(x + w, overlap)
          ..close();

      case OrionTooltipPlacement.left:
        // Right edge of tooltip, pointing right toward trigger.
        final double baseX = size.width;
        final double tipX = baseX + h;
        final double midY = y + (w / 2.0);
        path
          ..moveTo(baseX - overlap, y)
          ..lineTo(baseX, y)
          ..lineTo(tipX - tipCurve, midY - tipCurve)
          ..quadraticBezierTo(tipX, midY, tipX - tipCurve, midY + tipCurve)
          ..lineTo(baseX, y + w)
          ..lineTo(baseX - overlap, y + w)
          ..close();

      case OrionTooltipPlacement.right:
        // Left edge of tooltip, pointing left toward trigger.
        final double tipX = -h;
        final double midY = y + (w / 2.0);
        path
          ..moveTo(overlap, y)
          ..lineTo(0.0, y)
          ..lineTo(tipX + tipCurve, midY - tipCurve)
          ..quadraticBezierTo(tipX, midY, tipX + tipCurve, midY + tipCurve)
          ..lineTo(0.0, y + w)
          ..lineTo(overlap, y + w)
          ..close();

      case OrionTooltipPlacement.start:
      case OrionTooltipPlacement.end:
        break;
    }
    return path;
  }

  Path _buildBorderPath(OrionTooltipResolvedLayout layout, Size size) {
    final Offset arrowOffset = layout.arrowOffset!;
    final double x = arrowOffset.dx;
    final double y = arrowOffset.dy;
    final double w = arrowSize.width;
    final double h = arrowSize.height;
    final double tipCurve = math.min(1.25, math.min(w * 0.2, h * 0.35));

    final Path path = Path();
    switch (layout.placement) {
      case OrionTooltipPlacement.top:
        final double baseY = size.height;
        final double tipY = baseY + h;
        final double midX = x + (w / 2.0);
        path
          ..moveTo(x, baseY)
          ..lineTo(midX - tipCurve, tipY - tipCurve)
          ..quadraticBezierTo(midX, tipY, midX + tipCurve, tipY - tipCurve)
          ..lineTo(x + w, baseY);

      case OrionTooltipPlacement.bottom:
        final double tipY = -h;
        final double midX = x + (w / 2.0);
        path
          ..moveTo(x, 0.0)
          ..lineTo(midX - tipCurve, tipY + tipCurve)
          ..quadraticBezierTo(midX, tipY, midX + tipCurve, tipY + tipCurve)
          ..lineTo(x + w, 0.0);

      case OrionTooltipPlacement.left:
        final double baseX = size.width;
        final double tipX = baseX + h;
        final double midY = y + (w / 2.0);
        path
          ..moveTo(baseX, y)
          ..lineTo(tipX - tipCurve, midY - tipCurve)
          ..quadraticBezierTo(tipX, midY, tipX - tipCurve, midY + tipCurve)
          ..lineTo(baseX, y + w);

      case OrionTooltipPlacement.right:
        final double tipX = -h;
        final double midY = y + (w / 2.0);
        path
          ..moveTo(0.0, y)
          ..lineTo(tipX + tipCurve, midY - tipCurve)
          ..quadraticBezierTo(tipX, midY, tipX + tipCurve, midY + tipCurve)
          ..lineTo(0.0, y + w);

      case OrionTooltipPlacement.start:
      case OrionTooltipPlacement.end:
        break;
    }
    return path;
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (!hasShadow) return;
    final OrionTooltipResolvedLayout layout = _resolveLayout(size);
    if (layout.arrowOffset == null) return;

    final Path shadowPath = _buildFillPath(layout, size, overlap: 1.0);
    canvas.drawPath(
      shadowPath.shift(const Offset(0, 2)),
      Paint()
        ..color = Color(isDark ? 0x38000000 : 0x14000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0),
    );
  }

  void paintForeground(Canvas canvas, Size size) {
    final OrionTooltipResolvedLayout layout = _resolveLayout(size);
    if (layout.arrowOffset == null) return;

    // For opaque fills, overlap slightly inside the card edge to cover any
    // subpixel seam or card border stroke. For translucent frosted fills, stay
    // flush so alpha does not double-blend over the blurred interior.
    final double overlap = color.a < 1.0
        ? 0.0
        : math.max(1.5, borderWidth + 0.75);

    final Path fillPath = _buildFillPath(layout, size, overlap: overlap);
    canvas.drawPath(fillPath, Paint()..color = color);

    if (borderWidth > 0 && borderColor.a > 0) {
      final Path borderPath = _buildBorderPath(layout, size);
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
  bool shouldRepaint(OrionTooltipArrowPainter oldDelegate) {
    return color != oldDelegate.color ||
        borderColor != oldDelegate.borderColor ||
        borderWidth != oldDelegate.borderWidth ||
        arrowSize != oldDelegate.arrowSize ||
        arrowEdgeInset != oldDelegate.arrowEdgeInset ||
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

class _OrionTooltipArrowForegroundPainter extends CustomPainter {
  const _OrionTooltipArrowForegroundPainter(this.arrowPainter);

  final OrionTooltipArrowPainter arrowPainter;

  @override
  void paint(Canvas canvas, Size size) {
    arrowPainter.paintForeground(canvas, size);
  }

  @override
  bool shouldRepaint(_OrionTooltipArrowForegroundPainter oldDelegate) =>
      arrowPainter.shouldRepaint(oldDelegate.arrowPainter);
}
