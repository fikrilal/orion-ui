import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import 'package:orion_ui/src/components/toast/orion_toast_card.dart';
import 'package:orion_ui/src/components/toast/orion_toast_controller.dart';
import 'package:orion_ui/src/components/toast/orion_toast_data.dart';
import 'package:orion_ui/src/components/toast/orion_toast_presets.dart';
import 'package:orion_ui/src/components/toast/orion_toast_style.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Distance between stacked toasts while the stack rests collapsed.
const double _collapsedStep = 12.0;

/// Fallback height used before a card reports its laid-out measurement.
const double _unmeasuredHeight = 56.0;

/// Vertical travel distance for a newly mounted card's entrance spring.
const double _entranceTravel = 16.0;

/// Top-level toast notification stack host.
///
/// Mount this widget at the root of the app (e.g. inside `MaterialApp.builder`)
/// or wrap any screen subtree. Listens to [controller] (defaulting to
/// [OrionToastController.instance]) and renders active toasts in an interactive
/// perspective stack that lifts above the keyboard, expands smoothly on hover,
/// hold, or mobile tap, collapses on outside tap, and supports both horizontal
/// and anchor-edge vertical swipe dismissal.
class OrionToaster extends StatefulWidget {
  const OrionToaster({
    super.key,
    this.child,
    this.controller,
    this.position = OrionToastPosition.bottomCenter,
    this.maxVisible = 3,
    this.gap = 10.0,
    this.showCloseButtons = true,
    this.showProgressBar = false,
    this.richColors = false,
    this.edgeOffset,
    this.style,
  });

  /// Optional app subtree wrapped by this toaster overlay.
  final Widget? child;

  /// Optional scoped controller. Defaults to [OrionToastController.instance].
  final OrionToastController? controller;

  /// Placement anchor on screen (supports center and corner placements).
  final OrionToastPosition position;

  /// Maximum visible toasts shown simultaneously in the stack.
  final int maxVisible;

  /// Vertical separation gap when the stack is expanded.
  final double gap;

  /// Default close button visibility on dismissible toasts.
  final bool showCloseButtons;

  /// Default subtle auto-dismiss countdown progress bar visibility.
  final bool showProgressBar;

  /// Default semantic surface/border tinting for typed statuses.
  final bool richColors;

  /// Distance from the SafeArea top/bottom edge. Defaults to `12` for top
  /// anchors and `16` for bottom anchors.
  final double? edgeOffset;

  /// Global style overrides for the toast stack.
  final OrionToastStyle? style;

  @override
  State<OrionToaster> createState() => _OrionToasterState();
}

class _DepartingEntry {
  const _DepartingEntry({
    required this.data,
    required this.tierIndex,
    required this.expandedOffset,
  });

  final OrionToastData data;
  final int tierIndex;
  final double expandedOffset;
}

class _OrionToasterState extends State<OrionToaster>
    with WidgetsBindingObserver {
  final OverlayPortalController _portalController = OverlayPortalController();
  final Set<int> _pointers = <int>{};
  final List<_DepartingEntry> _departing = <_DepartingEntry>[];
  final Map<String, double> _lastMeasuredHeights = <String, double>{};

  late OrionToastController _controller;
  List<OrionToastData> _shown = <OrionToastData>[];
  bool _hovered = false;
  bool _pinnedExpanded = false;
  bool _expanded = false;
  bool _holdingPause = false;
  Timer? _holdThresholdTimer;
  bool _holdExceededTapThreshold = false;
  String? _lastAnnouncement;
  FlutterView? _view;
  bool _supportsAnnounce = false;
  TextDirection _textDirection = TextDirection.ltr;

  List<OrionToastData> get _visibleToasts {
    final List<OrionToastData> all = _controller.toasts;
    final int cap = math.max(1, widget.maxVisible);
    return all.length > cap ? all.sublist(all.length - cap) : all;
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = widget.controller ?? OrionToastController.instance;
    _controller.addListener(_onToastsChanged);
    _shown = _visibleToasts;
    if (_shown.isNotEmpty) {
      _portalController.show();
    }
  }

  @override
  void didChangeMetrics() {
    if (!mounted) return;
    if (_shown.isNotEmpty || _departing.isNotEmpty) {
      setState(() {});
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _view = View.maybeOf(context);
    _supportsAnnounce = MediaQuery.supportsAnnounceOf(context);
    _textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }

  @override
  void didUpdateWidget(OrionToaster oldWidget) {
    super.didUpdateWidget(oldWidget);
    final OrionToastController nextController =
        widget.controller ?? OrionToastController.instance;
    if (nextController != _controller) {
      _releaseOwnPause();
      _controller.removeListener(_onToastsChanged);
      _controller = nextController;
      _controller.addListener(_onToastsChanged);
      _departing.clear();
      _pointers.clear();
      _hovered = false;
      _pinnedExpanded = false;
      _expanded = false;
      _shown = _visibleToasts;
      _syncPortal();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _holdThresholdTimer?.cancel();
    _holdThresholdTimer = null;
    _controller.removeListener(_onToastsChanged);
    _releaseOwnPause();
    super.dispose();
  }

  void _releaseOwnPause() {
    if (_holdingPause) {
      _holdingPause = false;
      _controller.resumeTimers();
    }
  }

  void _syncPortal() {
    final bool hasWork = _shown.isNotEmpty || _departing.isNotEmpty;
    if (hasWork && !_portalController.isShowing) {
      _portalController.show();
    } else if (!hasWork && _portalController.isShowing) {
      _portalController.hide();
    }
  }

  double _rememberedOffsetFor(int tier, List<OrionToastData> prevReversed) {
    if (!_expanded) {
      return tier * _collapsedStep;
    }
    double offset = 0.0;
    for (int i = 0; i < tier; i++) {
      offset +=
          (_lastMeasuredHeights[prevReversed[i].id] ?? _unmeasuredHeight) +
          widget.gap;
    }
    return offset;
  }

  void _onToastsChanged() {
    if (!mounted) return;
    final List<OrionToastData> visible = _visibleToasts;
    final Set<String> live = <String>{
      for (final OrionToastData toast in _controller.toasts) toast.id,
    };

    final List<OrionToastData> prevReversed = _shown.reversed.toList();
    for (int tier = 0; tier < prevReversed.length; tier++) {
      final OrionToastData was = prevReversed[tier];
      if (!live.contains(was.id) &&
          !_departing.any((_DepartingEntry d) => d.data.id == was.id)) {
        _departing.add(
          _DepartingEntry(
            data: was,
            tierIndex: tier,
            expandedOffset: _rememberedOffsetFor(tier, prevReversed),
          ),
        );
      }
    }
    // Re-shown while departing: reclaim card cleanly.
    _departing.removeWhere((_DepartingEntry d) => live.contains(d.data.id));
    _shown = visible;

    if (_controller.toasts.isEmpty) {
      _pointers.clear();
      _hovered = false;
      _pinnedExpanded = false;
      _expanded = false;
      _holdingPause = false;
    } else if (_shown.length <= 1 && _pinnedExpanded) {
      _pinnedExpanded = false;
    }

    _syncInteractionState(notifySetState: false);
    _syncPortal();
    setState(() {});
    _announceLatest();
  }

  void _onDeparted(String id) {
    if (!mounted) return;
    setState(() {
      _departing.removeWhere((_DepartingEntry d) => d.data.id == id);
      _syncPortal();
    });
  }

  void _announceLatest() {
    final List<OrionToastData> toasts = _controller.toasts;
    if (toasts.isEmpty) {
      _lastAnnouncement = null;
      return;
    }
    final OrionToastData latest = toasts.last;
    final String spoken =
        latest.description == null || latest.description!.isEmpty
        ? latest.title
        : '${latest.title}, ${latest.description}';
    final String stamp = '${latest.id}\u0000$spoken';
    if (stamp == _lastAnnouncement) {
      return;
    }
    _lastAnnouncement = stamp;
    if (_view == null || !_supportsAnnounce) {
      return;
    }
    SemanticsService.sendAnnouncement(_view!, spoken, _textDirection);
  }

  void _syncInteractionState({bool notifySetState = true}) {
    final bool hasToasts = _shown.isNotEmpty;
    final bool shouldPause =
        hasToasts && (_hovered || _pinnedExpanded || _pointers.isNotEmpty);
    if (shouldPause && !_holdingPause) {
      _holdingPause = true;
      _controller.pauseTimers();
    } else if (!shouldPause && _holdingPause) {
      _holdingPause = false;
      _controller.resumeTimers();
    }

    final bool nextExpanded = shouldPause && _shown.length > 1;
    if (nextExpanded != _expanded) {
      _expanded = nextExpanded;
      if (notifySetState && mounted) {
        setState(() {});
      }
    } else if (notifySetState && mounted) {
      // Ensure cards receive updated `paused` prop for progress bar sync.
      setState(() {});
    }
  }

  void _onPointerDown(PointerDownEvent event) {
    if (_pointers.isEmpty) {
      _holdThresholdTimer?.cancel();
      _holdExceededTapThreshold = false;
      _holdThresholdTimer = Timer(const Duration(milliseconds: 250), () {
        _holdExceededTapThreshold = true;
      });
    }
    _pointers.add(event.pointer);
    _syncInteractionState();
  }

  void _onPointerUp(PointerUpEvent event) => _releasePointer(event.pointer);

  void _onPointerCancel(PointerCancelEvent event) =>
      _releasePointer(event.pointer);

  void _releasePointer(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.isNotEmpty) {
      return;
    }
    _holdThresholdTimer?.cancel();
    _holdThresholdTimer = null;
    _syncInteractionState();
  }

  void _requestPinExpand() {
    if (_shown.length <= 1 || _pinnedExpanded) return;
    _pinnedExpanded = true;
    _syncInteractionState();
  }

  void _collapsePinned() {
    if (!_pinnedExpanded) return;
    _pinnedExpanded = false;
    _syncInteractionState();
  }

  void _handleCardTap(OrionToastData toast, {required int tierIndex}) {
    // A quick tap (< 250ms) on a collapsed multi-toast stack pins it open so
    // touch users can lift their finger and read, swipe, or tap actions on any
    // stacked card. A longer hold-to-peek (>= 250ms) collapses cleanly on lift.
    if (!_pinnedExpanded &&
        _shown.length > 1 &&
        !_holdExceededTapThreshold &&
        (tierIndex > 0 || toast.onTap == null)) {
      _requestPinExpand();
      return;
    }
    toast.onTap?.call();
  }

  Widget _buildStackWidget(BuildContext context, {required bool inOverlay}) {
    final bool isTop = widget.position.isTop;
    final List<OrionToastData> visibleToasts = _visibleToasts;
    final OverlayState? overlay = inOverlay ? Overlay.maybeOf(context) : null;
    final double dpr = _view != null && _view!.devicePixelRatio > 0
        ? _view!.devicePixelRatio
        : 1.0;

    final double localInset = MediaQuery.viewInsetsOf(context).bottom;
    final double overlayInset = overlay != null
        ? MediaQuery.viewInsetsOf(overlay.context).bottom
        : 0.0;
    final double viewInset = inOverlay && _view != null
        ? _view!.viewInsets.bottom / dpr
        : 0.0;
    final double keyboardInset = isTop
        ? 0.0
        : math.max(localInset, math.max(overlayInset, viewInset));

    // When rendered inside OverlayPortal, the overlay starts at physical (0, 0)
    // even if an enclosing Scaffold stripped MediaQuery.padding for AppBar or
    // bottomNavigationBar. Resolve the unstripped safe-area insets directly.
    final EdgeInsets localPad = MediaQuery.paddingOf(context);
    final EdgeInsets overlayPad = overlay != null
        ? MediaQuery.paddingOf(overlay.context)
        : EdgeInsets.zero;
    final double viewTop = inOverlay && _view != null
        ? _view!.padding.top / dpr
        : 0.0;
    final double viewBottom = inOverlay && _view != null
        ? _view!.padding.bottom / dpr
        : 0.0;
    final double viewLeft = inOverlay && _view != null
        ? _view!.padding.left / dpr
        : 0.0;
    final double viewRight = inOverlay && _view != null
        ? _view!.padding.right / dpr
        : 0.0;

    final double safeTop = inOverlay
        ? math.max(localPad.top, math.max(overlayPad.top, viewTop))
        : localPad.top;
    final double safeBottom = keyboardInset > 0.0
        ? 0.0
        : (inOverlay
              ? math.max(
                  localPad.bottom,
                  math.max(overlayPad.bottom, viewBottom),
                )
              : localPad.bottom);
    final double safeLeft = inOverlay
        ? math.max(localPad.left, math.max(overlayPad.left, viewLeft))
        : localPad.left;
    final double safeRight = inOverlay
        ? math.max(localPad.right, math.max(overlayPad.right, viewRight))
        : localPad.right;

    final double edgePad = widget.edgeOffset ?? (isTop ? 12.0 : 16.0);
    final ThemeData theme = Theme.of(context);
    final OrionToastStyle baseStyle = OrionToastPresets.resolveFor(
      theme,
      status: OrionToastStatus.neutral,
      richColors: widget.richColors,
      stackStyle: widget.style,
    );
    final double maxStackWidth = math.max(160.0, baseStyle.maxWidth ?? 380.0);

    return Padding(
      padding: EdgeInsets.only(
        top: isTop ? safeTop + edgePad : 0.0,
        bottom: isTop ? 0.0 : keyboardInset + safeBottom + edgePad,
        left: safeLeft + 16.0,
        right: safeRight + 16.0,
      ),
      child: Align(
        alignment: widget.position.alignment,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxStackWidth),
          child: TapRegion(
            onTapOutside: (_) => _collapsePinned(),
            child: MouseRegion(
              onEnter: (_) {
                if (!_hovered) {
                  _hovered = true;
                  _syncInteractionState();
                }
              },
              onExit: (_) {
                if (_hovered) {
                  _hovered = false;
                  _syncInteractionState();
                }
              },
              child: Listener(
                // Defer to children so tapping cards and peek strips pauses/
                // expands cleanly without swallowing touches on empty areas.
                behavior: HitTestBehavior.deferToChild,
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                child: _ToastStackLayout(
                  toasts: visibleToasts,
                  departing: _departing,
                  expanded: _expanded,
                  paused: _controller.isPaused,
                  position: widget.position,
                  gap: widget.gap,
                  showCloseButtons: widget.showCloseButtons,
                  showProgressBar: widget.showProgressBar,
                  richColors: widget.richColors,
                  style: widget.style,
                  onHeightsUpdated: (Map<String, double> heights) {
                    _lastMeasuredHeights
                      ..clear()
                      ..addAll(heights);
                  },
                  onCardTap: _handleCardTap,
                  onRequestExpand: _requestPinExpand,
                  onDismiss: (String id, OrionToastDismissReason reason) =>
                      _controller.dismiss(id, reason),
                  onDeparted: _onDeparted,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool hasOverlay = Overlay.maybeOf(context) != null;
    final bool hasWork = _visibleToasts.isNotEmpty || _departing.isNotEmpty;

    if (hasOverlay) {
      return OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (BuildContext context) => hasWork
            ? _buildStackWidget(context, inOverlay: true)
            : const SizedBox.shrink(),
        child: widget.child ?? const SizedBox.shrink(),
      );
    }

    final Widget stackWidget = hasWork
        ? _buildStackWidget(context, inOverlay: false)
        : const SizedBox.shrink();
    if (widget.child == null) {
      return stackWidget;
    }

    return Stack(
      children: <Widget>[
        widget.child!,
        Positioned.fill(
          child: IgnorePointer(ignoring: !hasWork, child: stackWidget),
        ),
      ],
    );
  }
}

class _ToastStackLayout extends StatefulWidget {
  const _ToastStackLayout({
    required this.toasts,
    required this.departing,
    required this.expanded,
    required this.paused,
    required this.position,
    required this.gap,
    required this.showCloseButtons,
    required this.showProgressBar,
    required this.richColors,
    required this.style,
    required this.onHeightsUpdated,
    required this.onCardTap,
    required this.onRequestExpand,
    required this.onDismiss,
    required this.onDeparted,
  });

  final List<OrionToastData> toasts;
  final List<_DepartingEntry> departing;
  final bool expanded;
  final bool paused;
  final OrionToastPosition position;
  final double gap;
  final bool showCloseButtons;
  final bool showProgressBar;
  final bool richColors;
  final OrionToastStyle? style;
  final ValueChanged<Map<String, double>> onHeightsUpdated;
  final void Function(OrionToastData toast, {required int tierIndex}) onCardTap;
  final VoidCallback onRequestExpand;
  final OrionToastDismissCallback onDismiss;
  final ValueChanged<String> onDeparted;

  @override
  State<_ToastStackLayout> createState() => _ToastStackLayoutState();
}

class _ToastStackLayoutState extends State<_ToastStackLayout> {
  final Map<String, double> _heights = <String, double>{};
  double _reserve = 0.0;

  double _offsetOf(int tier, List<OrionToastData> reversed) {
    if (!widget.expanded) {
      return tier * _collapsedStep;
    }
    double offset = 0.0;
    for (int i = 0; i < tier; i++) {
      offset += (_heights[reversed[i].id] ?? _unmeasuredHeight) + widget.gap;
    }
    return offset;
  }

  @override
  void didUpdateWidget(_ToastStackLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    final Set<String> drawn = <String>{
      ...widget.toasts.map((OrionToastData t) => t.id),
      ...widget.departing.map((_DepartingEntry d) => d.data.id),
    };
    _heights.removeWhere((String id, double _) => !drawn.contains(id));
  }

  void _measure(String id, double height) {
    if (_heights[id] == height) return;
    setState(() {
      _heights[id] = height;
      widget.onHeightsUpdated(_heights);
    });
  }

  @override
  Widget build(BuildContext context) {
    final bool isTop = widget.position.isTop;
    final List<OrionToastData> reversed = widget.toasts.reversed.toList();

    double extent = 0.0;
    for (int tier = 1; tier < reversed.length; tier++) {
      final double offset = _offsetOf(tier, reversed);
      if (offset > extent) {
        extent = offset;
      }
    }
    _reserve = widget.departing.isEmpty ? extent : math.max(_reserve, extent);
    final double frontHeight = reversed.isNotEmpty
        ? (_heights[reversed.first.id] ?? _unmeasuredHeight)
        : _unmeasuredHeight;

    // Give the Stack itself the full vertical band (front card + peek/expanded
    // travel) so Flutter's hit-testing reaches every translated peek strip and
    // expanded card directly without blocking taps outside the cards.
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: frontHeight + _reserve),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        children: <Widget>[
          // Departing cards render behind live cards at their remembered depth
          // so exiting toasts never flash on top of active ones.
          for (final _DepartingEntry leaving in widget.departing)
            _ToastStackItem(
              key: ValueKey<String>(leaving.data.id),
              data: leaving.data,
              tierIndex: leaving.tierIndex,
              expandedOffset: leaving.expandedOffset,
              expanded: widget.expanded,
              paused: widget.paused,
              isTop: isTop,
              showCloseButton: widget.showCloseButtons,
              showProgressBar: widget.showProgressBar,
              richColors: widget.richColors,
              style: widget.style,
              departing: true,
              onDismiss: widget.onDismiss,
              onExited: () => widget.onDeparted(leaving.data.id),
              onMeasured: (double height) => _measure(leaving.data.id, height),
            ),
          // Live cards painted back-to-front (newest at tierIndex 0 on top).
          for (int i = reversed.length - 1; i >= 0; i--)
            _ToastStackItem(
              key: ValueKey<String>(reversed[i].id),
              data: reversed[i],
              tierIndex: i,
              expandedOffset: _offsetOf(i, reversed),
              expanded: widget.expanded,
              paused: widget.paused,
              isTop: isTop,
              showCloseButton: widget.showCloseButtons,
              showProgressBar: widget.showProgressBar,
              richColors: widget.richColors,
              style: widget.style,
              onCardTap: () => widget.onCardTap(reversed[i], tierIndex: i),
              onRequestExpand: widget.onRequestExpand,
              onDismiss: widget.onDismiss,
              onMeasured: (double height) => _measure(reversed[i].id, height),
            ),
        ],
      ),
    );
  }
}

class _ToastStackItem extends StatefulWidget {
  const _ToastStackItem({
    super.key,
    required this.data,
    required this.tierIndex,
    required this.expandedOffset,
    required this.expanded,
    required this.paused,
    required this.isTop,
    required this.showCloseButton,
    required this.showProgressBar,
    required this.richColors,
    required this.style,
    required this.onDismiss,
    required this.onMeasured,
    this.departing = false,
    this.onExited,
    this.onCardTap,
    this.onRequestExpand,
  });

  final OrionToastData data;
  final int tierIndex;
  final double expandedOffset;
  final bool expanded;
  final bool paused;
  final bool isTop;
  final bool showCloseButton;
  final bool showProgressBar;
  final bool richColors;
  final OrionToastStyle? style;
  final OrionToastDismissCallback onDismiss;
  final ValueChanged<double> onMeasured;
  final bool departing;
  final VoidCallback? onExited;
  final VoidCallback? onCardTap;
  final VoidCallback? onRequestExpand;

  @override
  State<_ToastStackItem> createState() => _ToastStackItemState();
}

class _ToastStackItemState extends State<_ToastStackItem>
    with TickerProviderStateMixin {
  late final OrionSpringDriver _yDriver;
  late final OrionSpringDriver _scaleDriver;
  late final OrionSpringDriver _opacityDriver;
  OrionSpringSpec _stackSpring = OrionToastPresets.defaultStackSpring;
  bool _entered = false;

  double get _targetY {
    if (widget.departing) {
      return _yDriver.value;
    }
    final double sign = widget.isTop ? 1.0 : -1.0;
    final double offset = widget.expanded
        ? widget.expandedOffset
        : widget.tierIndex * _collapsedStep;
    return sign * offset;
  }

  double get _targetScale {
    if (widget.departing) {
      return _scaleDriver.value;
    }
    if (widget.expanded) {
      return 1.0;
    }
    return (1.0 - (widget.tierIndex * 0.06)).clamp(0.82, 1.0);
  }

  double get _targetOpacity {
    if (widget.departing) {
      return _opacityDriver.value;
    }
    if (widget.expanded) {
      return 1.0;
    }
    return switch (widget.tierIndex) {
      0 => 1.0,
      1 => 0.90,
      2 => 0.76,
      _ => 0.0,
    };
  }

  @override
  void initState() {
    super.initState();
    _yDriver = OrionSpringDriver(
      vsync: this,
      initialValue: _targetY,
      springSpec: _stackSpring,
    );
    _scaleDriver = OrionSpringDriver(
      vsync: this,
      initialValue: _targetScale,
      springSpec: _stackSpring,
    );
    _opacityDriver = OrionSpringDriver(
      vsync: this,
      initialValue: _targetOpacity,
      springSpec: _stackSpring,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final OrionToastStyle style = OrionToastPresets.resolveFor(
      Theme.of(context),
      status: widget.data.status,
      richColors: widget.richColors,
      stackStyle: widget.style,
      instanceStyle: widget.data.style,
    );
    _stackSpring = style.stackSpring ?? OrionToastPresets.defaultStackSpring;
    final OrionSpringSpec mountSpring =
        style.mountSpring ?? OrionToastPresets.defaultMountSpring;
    _scaleDriver.springSpec = _stackSpring;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _yDriver.reducedMotion = reduced;
    _scaleDriver.reducedMotion = reduced;
    _opacityDriver.reducedMotion = reduced;

    if (_entered) {
      return;
    }
    _entered = true;
    _yDriver
      ..springSpec = mountSpring
      ..jumpTo(_targetY + (widget.isTop ? -_entranceTravel : _entranceTravel));
    _scaleDriver
      ..springSpec = mountSpring
      ..jumpTo(0.95);
    _opacityDriver
      ..springSpec = mountSpring
      ..jumpTo(0.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _yDriver.retarget(_targetY);
      _scaleDriver.retarget(_targetScale);
      _opacityDriver.retarget(_targetOpacity);
    });
  }

  @override
  void didUpdateWidget(_ToastStackItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bool moved = _yDriver.target != _targetY;
    final bool scaled = _scaleDriver.target != _targetScale;
    final bool faded = _opacityDriver.target != _targetOpacity;
    if (!moved && !scaled && !faded) {
      return;
    }
    if (moved) {
      _yDriver
        ..springSpec = _stackSpring
        ..retarget(_targetY);
    }
    if (scaled) {
      _scaleDriver
        ..springSpec = _stackSpring
        ..retarget(_targetScale);
    }
    if (faded) {
      _opacityDriver
        ..springSpec = _stackSpring
        ..retarget(_targetOpacity);
    }
  }

  @override
  void dispose() {
    _yDriver.dispose();
    _scaleDriver.dispose();
    _opacityDriver.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final double? height = context.size?.height;
      if (height != null) {
        widget.onMeasured(height);
      }
    });

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[
        _yDriver,
        _scaleDriver,
        _opacityDriver,
      ]),
      child: OrionToastCard(
        data: widget.data,
        isTop: widget.isTop,
        showCloseButton: widget.showCloseButton,
        showProgressBar: widget.showProgressBar,
        richColors: widget.richColors,
        paused: widget.paused,
        style: widget.style,
        departing: widget.departing,
        onCardTap: widget.onCardTap,
        onRequestExpand: widget.onRequestExpand,
        onDismiss: widget.onDismiss,
        onExited: widget.onExited,
      ),
      builder: (BuildContext context, Widget? child) {
        final double y = _yDriver.value;
        final double scale = _scaleDriver.value;
        final double opacity = _opacityDriver.value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0.0, y),
          child: Transform.scale(
            scale: scale,
            alignment: widget.isTop
                ? Alignment.topCenter
                : Alignment.bottomCenter,
            child: Opacity(opacity: opacity, child: child),
          ),
        );
      },
    );
  }
}
