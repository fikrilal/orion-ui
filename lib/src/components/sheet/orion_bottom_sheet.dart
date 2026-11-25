import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_presets.dart';
import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_style.dart';
import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_theme.dart';
import 'package:orion_ui/src/components/sheet/orion_sheet_controller.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_colors.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Builder callback for sheet content receiving an interactive cooperating [ScrollController].
typedef OrionSheetContentBuilder =
    Widget Function(BuildContext context, ScrollController scrollController);

/// A specialized [ScrollController] that enables cooperative nested scrolling
/// between an inner scrollable widget and its parent [OrionBottomSheet].
class OrionSheetScrollController extends ScrollController {
  OrionSheetScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
  });

  _OrionSheetScrollDelegate? _delegate;

  void _attachDelegate(_OrionSheetScrollDelegate delegate) {
    _delegate = delegate;
  }

  void _detachDelegate() {
    _delegate = null;
  }

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _OrionSheetScrollPosition(
      physics: physics.applyTo(const ClampingScrollPhysics()),
      context: context,
      oldPosition: oldPosition,
      getDelegate: () => _delegate,
    );
  }
}

abstract interface class _OrionSheetScrollDelegate {
  double get currentHeight;
  double get maxDetentHeight;
  double get minDetentHeight;
  bool get isDismissible;
  bool get enableDrag;
  void beginSheetDrag();
  void addPixelDelta(double delta);
  void goBallistic(double velocity);
}

class _OrionSheetScrollPosition extends ScrollPositionWithSingleContext {
  _OrionSheetScrollPosition({
    required super.physics,
    required super.context,
    super.oldPosition,
    required this.getDelegate,
  });

  final _OrionSheetScrollDelegate? Function() getDelegate;

  bool get _listShouldScroll => pixels > 0.0;

  @override
  void applyUserOffset(double delta) {
    final delegate = getDelegate();
    if (delegate == null || !delegate.enableDrag) {
      super.applyUserOffset(delta);
      return;
    }

    // delta > 0: user dragging finger DOWN (scrolling toward offset 0 / pulling sheet down).
    // delta < 0: user dragging finger UP (scrolling further into list / expanding sheet).
    final double sheetH = delegate.currentHeight;
    final double maxH = delegate.maxDetentHeight;

    if (_listShouldScroll) {
      if (delta > 0 && delta > pixels) {
        // Seamless mid-gesture handoff: consume remaining scroll offset to 0,
        // then carry leftover downward delta directly into sheet drag.
        final double overflow = delta - pixels;
        super.applyUserOffset(pixels);
        delegate.beginSheetDrag();
        delegate.addPixelDelta(-overflow);
        return;
      }
      super.applyUserOffset(delta);
      return;
    }

    // Here pixels <= 0.0 (list is resting at the very top).
    if (delta > 0) {
      // Pulling downward at top: delegate moves sheet downward.
      delegate.beginSheetDrag();
      delegate.addPixelDelta(-delta);
    } else if (delta < 0) {
      // Pulling upward at top:
      if (sheetH < maxH - 0.5) {
        // Sheet has not reached top detent yet -> expand sheet first.
        delegate.beginSheetDrag();
        delegate.addPixelDelta(-delta);
      } else {
        // Sheet is at top detent -> scroll the inner list into content.
        super.applyUserOffset(delta);
      }
    }
  }

  @override
  void goBallistic(double velocity) {
    final delegate = getDelegate();
    if (delegate == null || !delegate.enableDrag) {
      super.goBallistic(velocity);
      return;
    }

    // Only user drag activities should drive the bottom sheet.
    // Internal dimension adjustments (applyNewDimensions) and idle events must remain with ScrollPosition.
    if (activity is! DragScrollActivity) {
      super.goBallistic(velocity);
      return;
    }

    // velocity < 0: downward flick (content moving toward 0).
    // velocity > 0: upward flick (content moving forward into list).
    if (_listShouldScroll) {
      super.goBallistic(velocity);
      return;
    }

    final double sheetH = delegate.currentHeight;
    final double maxH = delegate.maxDetentHeight;

    if (velocity > 0 && sheetH >= maxH - 0.5) {
      super.goBallistic(velocity);
      return;
    }

    // Sheet takes the kinetic fling.
    goIdle();
    delegate.goBallistic(velocity);
  }
}

/// A tactile, physics-driven bottom sheet supporting both intrinsic
/// content-sized presentation and multi-snap detents, edge-to-edge or floating
/// card layouts, keyboard avoidance, rubber-banding, and cooperative nested
/// scrolling.
///
/// Sizing modes:
/// - **Multi-detent mode** (`fitContent: false`, default when [detents] is
///   provided): snaps between fractional viewport heights (e.g. `[0.4, 0.85]`).
/// - **Intrinsic fit-content mode** (`fitContent: true`): automatically measures
///   its child height up to [maxHeightFraction] of the available viewport while
///   preserving drag-to-dismiss, top rubber-banding, and keyboard avoidance.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionBottomSheetPresets] for the [variant], the ambient
/// [OrionBottomSheetTheme], and the instance [style].
class OrionBottomSheet extends StatefulWidget {
  const OrionBottomSheet({
    super.key,
    required this.builder,
    this.detents = const <double>[0.4, 0.85],
    this.initialDetentIndex = 0,
    this.fitContent = false,
    this.maxHeightFraction = 0.9,
    this.variant = OrionBottomSheetVariant.edgeToEdge,
    this.title,
    this.subtitle,
    this.header,
    this.showCloseButton = false,
    this.enableDrag = true,
    this.showDragHandle = true,
    this.useSafeArea = true,
    this.controller,
    this.style,
    this.onDetentChanged,
    this.onDismiss,
    this.hasBarrier = false,
    this.barrierDismissible = true,
    this.isDismissible = true,
  }) : assert(
         fitContent || detents.length > 0,
         'detents must not be empty when fitContent is false',
       ),
       assert(
         maxHeightFraction > 0.0 && maxHeightFraction <= 1.0,
         'maxHeightFraction must be between 0.0 and 1.0',
       ),
       assert(
         header == null || (title == null && subtitle == null),
         'Provide either header or title/subtitle, not both.',
       );

  /// Content builder receiving the sheet's cooperating [ScrollController].
  final OrionSheetContentBuilder builder;

  /// Snap detents expressed as fractions (0.1 to 1.0) of available viewport
  /// height. Ignored when [fitContent] is true.
  final List<double> detents;

  /// Index of the initial detent to mount at.
  final int initialDetentIndex;

  /// When true, the sheet sizes itself to its intrinsic content height (capped
  /// at [maxHeightFraction] of available height) instead of fixed [detents].
  final bool fitContent;

  /// Upper height cap as a fraction of available viewport when [fitContent] is true.
  final double maxHeightFraction;

  /// Visual layout variant: [OrionBottomSheetVariant.edgeToEdge] or
  /// [OrionBottomSheetVariant.floating].
  final OrionBottomSheetVariant variant;

  /// Optional plain-text sheet title rendered in the built-in header bar.
  final String? title;

  /// Optional subtitle displayed beneath [title].
  final String? subtitle;

  /// Optional custom header widget rendered between the drag handle and body.
  final Widget? header;

  /// Whether to show a trailing close icon button in the built-in header bar
  /// (requires [title] or [subtitle] and [isDismissible]).
  final bool showCloseButton;

  /// Whether user pointer drags can move the sheet.
  final bool enableDrag;

  /// Whether to display the top rounded pill drag handle.
  final bool showDragHandle;

  /// Whether to apply bottom safe-area insets inside the sheet (and top safe
  /// area clearance for modal presentations).
  final bool useSafeArea;

  /// Optional programmatic controller.
  final OrionSheetController? controller;

  /// Instance-level style overrides.
  final OrionBottomSheetStyle? style;

  /// Callback invoked when the sheet settles on a new detent index.
  final ValueChanged<int>? onDetentChanged;

  /// Callback invoked when the sheet has completely closed/dismissed.
  final VoidCallback? onDismiss;

  /// Whether to render a backdrop barrier scrim behind the sheet.
  final bool hasBarrier;

  /// Whether tapping the barrier scrim triggers sheet dismissal.
  final bool barrierDismissible;

  /// Whether the sheet can be dismissed via downward gestures or barrier taps.
  final bool isDismissible;

  /// Locates the nearest enclosing [OrionBottomSheetState], if any.
  static OrionBottomSheetState? maybeOf(BuildContext context) {
    return context.findAncestorStateOfType<OrionBottomSheetState>();
  }

  /// Dismisses the nearest enclosing modal or inline [OrionBottomSheet] with an
  /// optional typed [result], playing the spring exit animation cleanly.
  static void dismissOf<T>(BuildContext context, [T? result]) {
    final OrionBottomSheetState? state = maybeOf(context);
    if (state != null) {
      state.dismiss(result: result);
    } else {
      Navigator.maybePop<T>(context, result);
    }
  }

  @override
  State<OrionBottomSheet> createState() => OrionBottomSheetState();
}

class OrionBottomSheetState extends State<OrionBottomSheet>
    with SingleTickerProviderStateMixin
    implements _OrionSheetScrollDelegate {
  late final OrionSpringDriver _driver;
  late final OrionSheetScrollController _scrollController;

  List<double> _sortedDetents = const <double>[];
  double _availableHeight = 0.0;
  double _measuredContentHeight = 0.0;
  bool _handleDragging = false;
  bool _contentDragging = false;
  bool _scrollDragging = false;
  int _activeDetentIndex = 0;
  bool _mountedArrival = false;
  bool _isClosing = false;
  bool _dismissCompleted = false;
  Object? _pendingDismissResult;
  void Function(Object? result)? _routeDismissCallback;

  OrionBottomSheetStyle _resolvedStyle = const OrionBottomSheetStyle();
  OrionThemeData _orionTheme = OrionThemeData.fallback;
  ColorScheme _scheme = OrionColors.lightScheme;

  OrionSheetController? _internalController;
  OrionSheetController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionSheetController());

  bool get _isDragging =>
      _handleDragging || _contentDragging || _scrollDragging;

  @override
  double get currentHeight => _driver.value;

  @override
  double get maxDetentHeight {
    if (widget.fitContent) {
      return _fitTargetHeight;
    }
    return _heightForDetent(_sortedDetents.length - 1);
  }

  @override
  double get minDetentHeight {
    if (widget.fitContent) {
      return _fitTargetHeight;
    }
    return _heightForDetent(0);
  }

  double get _fitMaxHeight => _availableHeight * widget.maxHeightFraction;

  double get _fitTargetHeight {
    if (_availableHeight <= 0) return 0.0;
    if (_measuredContentHeight <= 0) {
      return math.min(_availableHeight * 0.4, _fitMaxHeight);
    }
    return _measuredContentHeight.clamp(0.0, _fitMaxHeight);
  }

  @override
  bool get isDismissible => widget.isDismissible;

  @override
  bool get enableDrag => widget.enableDrag;

  @override
  void initState() {
    super.initState();
    _scrollController = OrionSheetScrollController();
    _scrollController._attachDelegate(this);
    _normalizeDetents();
    _activeDetentIndex = widget.fitContent
        ? 0
        : widget.initialDetentIndex.clamp(0, _sortedDetents.length - 1);

    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionBottomSheetPresets.defaultDetentSpring,
    );

    _driver.addListener(_onDriverTick);
    _driver.addStatusListener(_onDriverStatus);
    _attachController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData theme = Theme.of(context);
    _scheme = theme.colorScheme;
    _orionTheme = OrionTheme.of(context);
    _resolvedStyle = _resolveStyle(theme);
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.reducedMotion = reduced;
  }

  @override
  void didUpdateWidget(OrionBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
    if (widget.variant != oldWidget.variant ||
        widget.style != oldWidget.style) {
      _resolvedStyle = _resolveStyle(Theme.of(context));
    }
    _normalizeDetents();
    if (!widget.fitContent) {
      final int clamped = _activeDetentIndex.clamp(
        0,
        _sortedDetents.length - 1,
      );
      if (clamped != _activeDetentIndex) {
        _snapToDetentIndex(clamped);
      } else {
        _onDriverTick();
      }
    } else {
      _onDriverTick();
    }
  }

  @override
  void dispose() {
    _scrollController._detachDelegate();
    _scrollController.dispose();
    _effectiveController.detach();
    _internalController?.dispose();
    _driver.removeListener(_onDriverTick);
    _driver.removeStatusListener(_onDriverStatus);
    _driver.dispose();
    super.dispose();
  }

  void _normalizeDetents() {
    final List<double> list =
        widget.detents.map((d) => d.clamp(0.1, 1.0)).toSet().toList()..sort();
    _sortedDetents = list.isEmpty ? const <double>[0.5] : list;
  }

  void _attachController() {
    _effectiveController.attach(
      onSnapToDetent: (int index) {
        if (widget.fitContent) {
          _snapToFitHeight();
          return;
        }
        final int targetIdx = index.clamp(0, _sortedDetents.length - 1);
        _snapToDetentIndex(targetIdx);
      },
      onSnapToFraction: (double fraction) {
        final double targetH = _availableHeight * fraction.clamp(0.0, 1.0);
        _snapToPixelHeight(targetH);
      },
      onDismiss: (Object? result) => dismiss(result: result),
    );
  }

  void _onDriverTick() {
    if (!mounted) return;
    final double h = _driver.value;
    // Complete dismissal once the sheet is visually offscreen (<= 2 px) rather
    // than waiting ~350 ms for a 650 px critically-damped tail to hit 0.001 px.
    final bool finishedDismiss = _isClosing && h <= 2.0;
    final double fraction = _availableHeight > 0
        ? (h / _availableHeight).clamp(0.0, 1.0)
        : 0.0;
    _effectiveController.updateState(
      height: finishedDismiss ? 0.0 : h,
      fraction: finishedDismiss ? 0.0 : fraction,
      detentIndex: _activeDetentIndex,
      isDismissed: finishedDismiss,
    );
    if (finishedDismiss && !_dismissCompleted) {
      _completeDismissal();
    }
  }

  void _onDriverStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _isClosing &&
        !_dismissCompleted &&
        _driver.value <= 2.0) {
      _completeDismissal();
    }
  }

  void _completeDismissal() {
    if (_dismissCompleted) return;
    _dismissCompleted = true;
    if (_driver.value > 0.0 || _driver.isAnimating) {
      _driver.jumpTo(0.0);
    }
    final Object? result = _pendingDismissResult;
    _pendingDismissResult = null;
    if (_routeDismissCallback != null) {
      _routeDismissCallback!(result);
    } else {
      widget.onDismiss?.call();
    }
  }

  double _heightForDetent(int index) {
    if (_availableHeight <= 0 || _sortedDetents.isEmpty) return 0.0;
    final int idx = index.clamp(0, _sortedDetents.length - 1);
    return _availableHeight * _sortedDetents[idx];
  }

  void _snapToFitHeight({double? velocity}) {
    if (_availableHeight <= 0) return;
    _isClosing = false;
    _dismissCompleted = false;
    _driver.springSpec =
        _resolvedStyle.detentSpring ??
        OrionBottomSheetPresets.defaultDetentSpring;
    _driver.retarget(_fitTargetHeight, velocity: velocity);
  }

  void _snapToDetentIndex(int index, {double? velocity}) {
    if (_availableHeight <= 0) return;
    if (widget.fitContent) {
      _snapToFitHeight(velocity: velocity);
      return;
    }
    _isClosing = false;
    _dismissCompleted = false;
    final int idx = index.clamp(0, _sortedDetents.length - 1);
    final int previousIdx = _activeDetentIndex;
    _activeDetentIndex = idx;
    final double targetH = _heightForDetent(idx);
    _driver.springSpec =
        _resolvedStyle.detentSpring ??
        OrionBottomSheetPresets.defaultDetentSpring;
    _driver.retarget(targetH, velocity: velocity);
    if (previousIdx != idx) {
      widget.onDetentChanged?.call(idx);
    }
  }

  void _snapToPixelHeight(double height, {double? velocity}) {
    if (_availableHeight <= 0) return;
    _isClosing = false;
    _dismissCompleted = false;
    _driver.springSpec =
        _resolvedStyle.detentSpring ??
        OrionBottomSheetPresets.defaultDetentSpring;
    _driver.retarget(height, velocity: velocity);

    if (widget.fitContent) {
      return;
    }

    int nearest = 0;
    double bestDiff = double.infinity;
    for (int i = 0; i < _sortedDetents.length; i++) {
      final double diff = (_heightForDetent(i) - height).abs();
      if (diff < bestDiff) {
        bestDiff = diff;
        nearest = i;
      }
    }
    final int previousIdx = _activeDetentIndex;
    _activeDetentIndex = nearest;
    if (previousIdx != nearest) {
      widget.onDetentChanged?.call(nearest);
    }
  }

  /// Triggers smooth downward dismissal of the sheet, optionally returning
  /// [result] when presented via [showOrionBottomSheet].
  void dismiss({double? velocity, Object? result}) {
    if (_isClosing) return;
    _isClosing = true;
    _pendingDismissResult = result;
    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      _completeDismissal();
      return;
    }
    _driver.springSpec =
        _resolvedStyle.dismissSpring ??
        OrionBottomSheetPresets.defaultDismissSpring;
    _driver.retarget(0.0, velocity: velocity);
  }

  OrionBottomSheetStyle _resolveStyle(ThemeData theme) {
    final OrionBottomSheetTheme sheetTheme =
        theme.extension<OrionBottomSheetTheme>() ??
        OrionBottomSheetTheme.fallback;
    return OrionBottomSheetPresets.resolve(
      scheme: theme.colorScheme,
      variant: widget.variant,
    ).merge(sheetTheme.defaultStyle).merge(widget.style);
  }

  @override
  void beginSheetDrag() {
    _scrollDragging = true;
  }

  @override
  void addPixelDelta(double delta) => _addPixelDelta(delta);

  @override
  void goBallistic(double velocity) {
    _scrollDragging = false;
    _settleOnDetent(velocity: velocity);
  }

  void _addPixelDelta(double deltaH) {
    if (!widget.enableDrag || _availableHeight <= 0) return;
    final double currentH = _driver.value;
    final double maxH = maxDetentHeight;
    final double minH = minDetentHeight;
    final double rubberBand = _resolvedStyle.rubberBandFactor ?? 0.15;

    double effectiveDelta = deltaH;
    if (currentH >= maxH && deltaH > 0) {
      effectiveDelta = deltaH * rubberBand;
    } else if (!widget.isDismissible && currentH <= minH && deltaH < 0) {
      effectiveDelta = deltaH * rubberBand;
    }

    final double candidate = currentH + effectiveDelta;
    final double maxRubberH = maxH + (_availableHeight * 0.16);
    final double clamped;
    if (widget.isDismissible) {
      clamped = candidate.clamp(0.0, maxRubberH);
    } else {
      clamped = candidate.clamp(math.max(0.0, minH - 40.0), maxRubberH);
    }
    _driver.jumpTo(clamped);
  }

  void _settleOnDetent({required double velocity}) {
    if (_availableHeight <= 0) return;
    final double currentH = _driver.value;
    final double minH = minDetentHeight;
    final double dismissThresh = _resolvedStyle.dismissThreshold ?? 96.0;

    // velocity > 0 is upward, velocity < 0 is downward.
    final double hProj = currentH + (velocity * 0.08);

    // 1. Dismiss check (only if dismissible).
    if (widget.isDismissible) {
      final double effectiveThreshold = math.min(dismissThresh, minH * 0.45);
      if (velocity < -650.0 ||
          (currentH < minH - effectiveThreshold) ||
          (hProj < minH * 0.5 && velocity < -150.0)) {
        dismiss(velocity: velocity);
        OrionHaptics.trigger(OrionHapticType.lightImpact);
        return;
      }
    }

    if (widget.fitContent) {
      _snapToFitHeight(velocity: velocity);
      return;
    }

    // 2. Fling upward -> step to higher detent.
    if (velocity > 500.0 && _activeDetentIndex < _sortedDetents.length - 1) {
      _snapToDetentIndex(_activeDetentIndex + 1, velocity: velocity);
      OrionHaptics.trigger(OrionHapticType.selectionClick);
      return;
    }

    // 3. Fling downward -> step to lower detent.
    if (velocity < -500.0 && _activeDetentIndex > 0) {
      _snapToDetentIndex(_activeDetentIndex - 1, velocity: velocity);
      OrionHaptics.trigger(OrionHapticType.selectionClick);
      return;
    }

    // 4. Settle on nearest detent to projected height.
    int bestIdx = 0;
    double bestDistance = double.infinity;
    for (int i = 0; i < _sortedDetents.length; i++) {
      final double targetH = _heightForDetent(i);
      final double dist = (targetH - hProj).abs();
      if (dist < bestDistance) {
        bestDistance = dist;
        bestIdx = i;
      }
    }

    _snapToDetentIndex(bestIdx, velocity: velocity);
  }

  void _onMeasuredContentSize(Size size) {
    if (!widget.fitContent || !mounted) return;
    if ((_measuredContentHeight - size.height).abs() < 0.5) return;
    _measuredContentHeight = size.height;
    if (_availableHeight <= 0 || _isDragging || _isClosing) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isDragging || _isClosing) return;
      if (!_mountedArrival) {
        _mountedArrival = true;
        _snapToFitHeight();
      } else if (_driver.reducedMotion) {
        _driver.jumpTo(_fitTargetHeight);
      } else {
        _snapToFitHeight();
      }
    });
  }

  Widget _buildDragHandle(OrionBottomSheetStyle style) {
    if (!widget.showDragHandle) {
      return const SizedBox(height: OrionSpacing.space12);
    }

    final Size size = style.handleSize ?? const Size(36.0, 5.0);
    final Color color =
        style.handleColor ?? _scheme.onSurfaceVariant.withValues(alpha: 0.35);

    return MouseRegion(
      cursor: widget.enableDrag
          ? SystemMouseCursors.grab
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: widget.enableDrag
            ? (_) => _handleDragging = true
            : null,
        onVerticalDragUpdate: widget.enableDrag
            ? (DragUpdateDetails details) {
                if (!_handleDragging) return;
                final double dy = details.primaryDelta ?? details.delta.dy;
                _addPixelDelta(-dy);
              }
            : null,
        onVerticalDragEnd: widget.enableDrag
            ? (DragEndDetails details) {
                if (!_handleDragging) return;
                _handleDragging = false;
                final double vy =
                    details.primaryVelocity ??
                    details.velocity.pixelsPerSecond.dy;
                _settleOnDetent(velocity: -vy);
              }
            : null,
        onVerticalDragCancel: () {
          _handleDragging = false;
          _settleOnDetent(velocity: 0.0);
        },
        child: Container(
          width: double.infinity,
          constraints: const BoxConstraints(
            minHeight: OrionSizing.minHitTarget,
          ),
          alignment: Alignment.center,
          child: Container(
            width: size.width,
            height: size.height,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(size.height / 2),
            ),
          ),
        ),
      ),
    );
  }

  Widget? _buildHeader(ThemeData theme) {
    if (widget.header != null) {
      return widget.header;
    }
    if (widget.title == null && widget.subtitle == null) {
      return null;
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        OrionSpacing.space16,
        0,
        OrionSpacing.space16,
        OrionSpacing.space12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                if (widget.title != null)
                  Text(
                    widget.title!,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _scheme.onSurface,
                    ),
                  ),
                if (widget.subtitle != null) ...<Widget>[
                  const SizedBox(height: 2.0),
                  Text(
                    widget.subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: _scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.showCloseButton && widget.isDismissible)
            IconButton(
              tooltip: 'Close',
              onPressed: () => dismiss(),
              icon: Icon(
                Icons.close_rounded,
                size: 20,
                color: _scheme.onSurfaceVariant,
              ),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final MediaQueryData media = MediaQuery.of(context);
    final bool isFloating = widget.variant == OrionBottomSheetVariant.floating;
    final EdgeInsets resolvedMargin = isFloating
        ? (_resolvedStyle.floatingMargin ??
                  const EdgeInsets.fromLTRB(
                    OrionSpacing.space16,
                    0,
                    OrionSpacing.space16,
                    OrionSpacing.space16,
                  ))
              .resolve(Directionality.of(context))
        : EdgeInsets.zero;

    final double keyboardInset = widget.hasBarrier
        ? media.viewInsets.bottom
        : 0.0;
    final double bottomSafeInset = widget.useSafeArea && widget.hasBarrier
        ? media.padding.bottom
        : 0.0;
    final double topClearance = widget.useSafeArea && widget.hasBarrier
        ? media.padding.top
        : 0.0;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double verticalMargins =
            resolvedMargin.top +
            resolvedMargin.bottom +
            (isFloating ? bottomSafeInset : 0.0);
        final double maxAvailable = math.max(
          0.0,
          constraints.maxHeight -
              topClearance -
              keyboardInset -
              verticalMargins,
        );

        if (_availableHeight != maxAvailable && maxAvailable > 0) {
          final bool wasMounted = _mountedArrival;
          _availableHeight = maxAvailable;
          if (!wasMounted) {
            if (!widget.fitContent) {
              _mountedArrival = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  _snapToDetentIndex(_activeDetentIndex);
                }
              });
            }
          } else if (!_isDragging && !_isClosing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted && !_isDragging && !_isClosing) {
                final double target = widget.fitContent
                    ? _fitTargetHeight
                    : _heightForDetent(_activeDetentIndex);
                _driver.jumpTo(target);
              }
            });
          }
        }

        final BorderRadius radius =
            _resolvedStyle.borderRadius ??
            (isFloating
                ? BorderRadius.circular(OrionRadii.radius24)
                : const BorderRadius.vertical(
                    top: Radius.circular(OrionRadii.radius24),
                  ));
        final Color bg = _resolvedStyle.backgroundColor ?? _scheme.surface;
        final bool frosted = _resolvedStyle.frosted ?? false;

        final Widget sheetBackdrop = frosted
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _orionTheme.blurSigma,
                  sigmaY: _orionTheme.blurSigma,
                ),
                child: ColoredBox(color: bg.withValues(alpha: 0.72)),
              )
            : ColoredBox(color: bg);

        final Widget innerContent = widget.builder(context, _scrollController);
        final Widget? headerWidget = _buildHeader(theme);

        final Widget contentInteractiveWrapper = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: widget.enableDrag
              ? (_) {
                  if (_scrollController.hasClients) return;
                  _contentDragging = true;
                }
              : null,
          onVerticalDragUpdate: widget.enableDrag
              ? (DragUpdateDetails details) {
                  if (!_contentDragging || _scrollController.hasClients) return;
                  final double dy = details.primaryDelta ?? details.delta.dy;
                  _addPixelDelta(-dy);
                }
              : null,
          onVerticalDragEnd: widget.enableDrag
              ? (DragEndDetails details) {
                  if (!_contentDragging || _scrollController.hasClients) return;
                  _contentDragging = false;
                  final double vy =
                      details.primaryVelocity ??
                      details.velocity.pixelsPerSecond.dy;
                  _settleOnDetent(velocity: -vy);
                }
              : null,
          onVerticalDragCancel: () => _contentDragging = false,
          child: innerContent,
        );

        final Widget handle = _buildDragHandle(_resolvedStyle);

        // Edge-to-edge sheets absorb bottom safe area inside the sheet surface
        // so the background reaches cleanly to the screen edge.
        final double innerBottomPad = !isFloating && keyboardInset == 0
            ? bottomSafeInset
            : 0.0;

        Widget buildSurfaceShell(Widget bodyChild) {
          final double effectiveBorderWidth = _resolvedStyle.borderWidth ?? 0.0;
          final Border? border =
              (_resolvedStyle.borderColor != null && effectiveBorderWidth > 0)
              ? Border.all(
                  color: _resolvedStyle.borderColor!,
                  width: effectiveBorderWidth,
                )
              : null;

          return Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: border,
              boxShadow: _resolvedStyle.shadow ?? OrionThemeData.defaultShadow,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Material(
                type: MaterialType.transparency,
                child: Stack(
                  children: <Widget>[
                    Positioned.fill(child: sheetBackdrop),
                    bodyChild,
                  ],
                ),
              ),
            ),
          );
        }

        // Pre-build the stable sheet content tree outside AnimatedBuilder so
        // animation ticks never rebuild user widgets.
        final Widget stableSheetBody;
        if (widget.fitContent) {
          stableSheetBody = _MeasureSize(
            onChange: _onMeasuredContentSize,
            child: Padding(
              padding: EdgeInsets.only(bottom: innerBottomPad),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  handle,
                  ?headerWidget,
                  Flexible(child: contentInteractiveWrapper),
                ],
              ),
            ),
          );
        } else {
          stableSheetBody = Padding(
            padding: EdgeInsets.only(bottom: innerBottomPad),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                handle,
                ?headerWidget,
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: contentInteractiveWrapper,
                  ),
                ),
              ],
            ),
          );
        }

        final Widget sheetSurface = buildSurfaceShell(stableSheetBody);

        return AnimatedBuilder(
          animation: _driver,
          child: sheetSurface,
          builder: (BuildContext context, Widget? child) {
            final double height = _driver.value;
            final double minH = minDetentHeight;
            final double barrierFraction = minH > 0
                ? (height / minH).clamp(0.0, 1.0)
                : 0.0;

            final Widget? barrier = widget.hasBarrier
                ? Positioned.fill(
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: (widget.barrierDismissible && widget.isDismissible)
                          ? () => dismiss()
                          : null,
                      child: Opacity(
                        opacity: barrierFraction,
                        child: ColoredBox(
                          color:
                              _resolvedStyle.barrierColor ??
                              const Color(0x73000000),
                        ),
                      ),
                    ),
                  )
                : null;

            final double bottomOffset =
                keyboardInset +
                resolvedMargin.bottom +
                (isFloating ? bottomSafeInset : 0.0);

            Widget positionedSheet;
            if (widget.fitContent) {
              // In fitContent mode: translate smoothly when below target height
              // (entrance / dismiss), and stretch container height smoothly when
              // rubber-banding above target height so there is never an open gap
              // beneath the bottom edge.
              final double targetH = _fitTargetHeight;
              final double clampedHeight = math.max(height, targetH);
              final double translateY = height < targetH
                  ? targetH - height
                  : 0.0;

              positionedSheet = Positioned(
                left: resolvedMargin.left,
                right: resolvedMargin.right,
                bottom: bottomOffset,
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: height > targetH ? clampedHeight : 0.0,
                      maxHeight: math.max(_fitMaxHeight, clampedHeight),
                    ),
                    child: child,
                  ),
                ),
              );
            } else {
              // In multi-detent mode: dynamically size the visible sheet box
              // down to minH (so footers, scroll bottoms, and safe areas stay
              // reachable at every detent) and translate smoothly when below
              // minH (entrance / dismiss). Rubber-banding above maxH grows the
              // box height cleanly while keeping its bottom anchored.
              final double layoutHeight = math.max(height, minH);
              final double translateY = height < minH ? minH - height : 0.0;

              positionedSheet = Positioned(
                left: resolvedMargin.left,
                right: resolvedMargin.right,
                bottom: bottomOffset,
                height: layoutHeight,
                child: Transform.translate(
                  offset: Offset(0, translateY),
                  child: child,
                ),
              );
            }

            return Stack(children: <Widget>[?barrier, positionedSheet]);
          },
        );
      },
    );
  }
}

/// Presents an [OrionBottomSheet] as a modal route on the navigator.
///
/// By default, when [detents] is omitted and [fitContent] is not explicitly
/// set, the sheet uses multi-detent mode `[0.5, 0.9]`. Pass `fitContent: true`
/// for intrinsic content-sized sheets (menus, forms, confirmations), or
/// `variant: OrionBottomSheetVariant.floating` for an inset rounded card sheet.
Future<T?> showOrionBottomSheet<T>({
  required BuildContext context,
  required OrionSheetContentBuilder builder,
  List<double> detents = const <double>[0.5, 0.9],
  int initialDetentIndex = 0,
  bool fitContent = false,
  double maxHeightFraction = 0.9,
  OrionBottomSheetVariant variant = OrionBottomSheetVariant.edgeToEdge,
  String? title,
  String? subtitle,
  Widget? header,
  bool showCloseButton = false,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  bool useSafeArea = true,
  bool useRootNavigator = true,
  OrionBottomSheetStyle? style,
  OrionSheetController? controller,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: useRootNavigator).push<T>(
    _OrionBottomSheetRoute<T>(
      builder: builder,
      detents: detents,
      initialDetentIndex: initialDetentIndex,
      fitContent: fitContent,
      maxHeightFraction: maxHeightFraction,
      variant: variant,
      title: title,
      subtitle: subtitle,
      header: header,
      showCloseButton: showCloseButton,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
      useSafeArea: useSafeArea,
      style: style,
      sheetController: controller,
      settings: routeSettings,
    ),
  );
}

class _OrionBottomSheetRoute<T> extends PopupRoute<T> {
  _OrionBottomSheetRoute({
    required this.builder,
    required this.detents,
    required this.initialDetentIndex,
    required this.fitContent,
    required this.maxHeightFraction,
    required this.variant,
    this.title,
    this.subtitle,
    this.header,
    required this.showCloseButton,
    required this.isDismissible,
    required this.enableDrag,
    required this.showDragHandle,
    required this.useSafeArea,
    this.style,
    this.sheetController,
    super.settings,
  });

  final OrionSheetContentBuilder builder;
  final List<double> detents;
  final int initialDetentIndex;
  final bool fitContent;
  final double maxHeightFraction;
  final OrionBottomSheetVariant variant;
  final String? title;
  final String? subtitle;
  final Widget? header;
  final bool showCloseButton;
  final bool isDismissible;
  final bool enableDrag;
  final bool showDragHandle;
  final bool useSafeArea;
  final OrionBottomSheetStyle? style;
  final OrionSheetController? sheetController;

  final GlobalKey<OrionBottomSheetState> _sheetKey =
      GlobalKey<OrionBottomSheetState>();

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get barrierDismissible => false; // Managed by sheet for continuous fade

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss bottom sheet';

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) return;
        if (isDismissible) {
          _sheetKey.currentState?.dismiss(result: result);
        }
      },
      child: _ModalSheetHost<T>(
        sheetKey: _sheetKey,
        onCompleteDismiss: (Object? result) {
          if (navigator?.canPop() ?? false) {
            navigator?.pop<T>(result as T?);
          }
        },
        child: OrionBottomSheet(
          key: _sheetKey,
          builder: builder,
          detents: detents,
          initialDetentIndex: initialDetentIndex,
          fitContent: fitContent,
          maxHeightFraction: maxHeightFraction,
          variant: variant,
          title: title,
          subtitle: subtitle,
          header: header,
          showCloseButton: showCloseButton,
          enableDrag: enableDrag,
          showDragHandle: showDragHandle,
          useSafeArea: useSafeArea,
          style: style,
          controller: sheetController,
          hasBarrier: true,
          barrierDismissible: isDismissible,
          isDismissible: isDismissible,
        ),
      ),
    );
  }
}

/// Wires the route's typed pop callback onto [OrionBottomSheetState] after mount.
class _ModalSheetHost<T> extends StatefulWidget {
  const _ModalSheetHost({
    required this.sheetKey,
    required this.onCompleteDismiss,
    required this.child,
  });

  final GlobalKey<OrionBottomSheetState> sheetKey;
  final void Function(Object? result) onCompleteDismiss;
  final Widget child;

  @override
  State<_ModalSheetHost<T>> createState() => _ModalSheetHostState<T>();
}

class _ModalSheetHostState<T> extends State<_ModalSheetHost<T>> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.sheetKey.currentState?._routeDismissCallback =
          widget.onCompleteDismiss;
    });
  }

  @override
  void didUpdateWidget(_ModalSheetHost<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    widget.sheetKey.currentState?._routeDismissCallback =
        widget.onCompleteDismiss;
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Reports post-layout child [Size] without introducing extra frames when
/// unchanged.
class _MeasureSize extends SingleChildRenderObjectWidget {
  const _MeasureSize({required this.onChange, super.child});

  final ValueChanged<Size> onChange;

  @override
  RenderObject createRenderObject(BuildContext context) =>
      _RenderMeasureSize(onChange);

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderMeasureSize renderObject,
  ) {
    renderObject.onChange = onChange;
  }
}

class _RenderMeasureSize extends RenderProxyBox {
  _RenderMeasureSize(this.onChange);

  ValueChanged<Size> onChange;
  Size? _lastSize;

  @override
  void performLayout() {
    super.performLayout();
    final Size newSize = child?.size ?? Size.zero;
    if (_lastSize != newSize) {
      _lastSize = newSize;
      onChange(newSize);
    }
  }
}
