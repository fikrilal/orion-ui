import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_presets.dart';
import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_style.dart';
import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_theme.dart';
import 'package:orion_ui/src/components/sheet/orion_sheet_controller.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
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

    // delta > 0: user dragging finger DOWN (pulling top downward).
    // delta < 0: user dragging finger UP (pulling content upward).
    final double sheetH = delegate.currentHeight;
    final double maxH = delegate.maxDetentHeight;

    if (_listShouldScroll) {
      super.applyUserOffset(delta);
      return;
    }

    // Here pixels <= 0.0 (list is resting at the very top).
    if (delta > 0) {
      // Pulling downward at top: delegate moves sheet downward.
      delegate.addPixelDelta(-delta);
    } else if (delta < 0) {
      // Pulling upward at top:
      if (sheetH < maxH - 0.5) {
        // Sheet has not reached top detent yet -> expand sheet first.
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

/// A tactile, physics-driven bottom sheet with multi-snap detents, rubber-banding,
/// and cooperative nested scrolling.
///
/// Features:
/// - **Kinetic Detents:** Snaps between fractional viewport heights (e.g. `[0.4, 0.85]`).
/// - **Top Rubber-Banding:** Elastic resistance when pulled above the highest detent.
/// - **Nested Scroll Cooperation:** Pulling the handle moves the sheet; dragging inner list
///   cooperates via [OrionSheetScrollController], moving the sheet when at top rest ($offset \le 0$).
/// - **Static Scrim Blur Isolation:** Frosted backdrops isolate Gaussian blurs on the static scrim,
///   protecting 60/120 FPS frame budgets from GPU raster stalls.
/// - **Zero-Snap Physics:** Continuous single-scalar simulation powered by [OrionSpringDriver].
class OrionBottomSheet extends StatefulWidget {
  const OrionBottomSheet({
    super.key,
    required this.builder,
    this.detents = const <double>[0.4, 0.85],
    this.initialDetentIndex = 0,
    this.enableDrag = true,
    this.showDragHandle = true,
    this.controller,
    this.style,
    this.onDetentChanged,
    this.onDismiss,
    this.hasBarrier = false,
    this.barrierDismissible = true,
    this.isDismissible = true,
  }) : assert(detents.length > 0, 'detents must not be empty');

  /// Content builder receiving the sheet's cooperating [ScrollController].
  final OrionSheetContentBuilder builder;

  /// Snap detents expressed as fractions (0.1 to 1.0) of available viewport height.
  final List<double> detents;

  /// Index of the initial detent to mount at.
  final int initialDetentIndex;

  /// Whether user pointer drags can move the sheet.
  final bool enableDrag;

  /// Whether to display the top rounded pill drag handle.
  final bool showDragHandle;

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
  bool _handleDragging = false;
  bool _contentDragging = false;
  int _activeDetentIndex = 0;
  bool _mountedArrival = false;
  bool _isClosing = false;

  OrionBottomSheetStyle _resolvedStyle = const OrionBottomSheetStyle();
  OrionThemeData _orionTheme = OrionThemeData.fallback;
  ColorScheme _scheme = OrionColors.lightScheme;

  OrionSheetController? _internalController;
  OrionSheetController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionSheetController());

  @override
  double get currentHeight => _driver.value;

  @override
  double get maxDetentHeight => _heightForDetent(_sortedDetents.length - 1);

  @override
  double get minDetentHeight => _heightForDetent(0);

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
    _activeDetentIndex = widget.initialDetentIndex.clamp(
      0,
      _sortedDetents.length - 1,
    );

    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionSpringSpec.gentle,
    );

    _driver.addListener(_onDriverTick);
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
  }

  @override
  void didUpdateWidget(OrionBottomSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
    _normalizeDetents();
    final int clamped = _activeDetentIndex.clamp(0, _sortedDetents.length - 1);
    if (clamped != _activeDetentIndex) {
      _snapToDetentIndex(clamped);
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
      onSnapToDetent: (index) {
        final int targetIdx = index.clamp(0, _sortedDetents.length - 1);
        _snapToDetentIndex(targetIdx);
      },
      onSnapToFraction: (fraction) {
        final double targetH = _availableHeight * fraction.clamp(0.0, 1.0);
        _snapToPixelHeight(targetH);
      },
      onDismiss: dismiss,
    );
  }

  void _onDriverTick() {
    if (!mounted) return;
    final double h = _driver.value;
    final double fraction = _availableHeight > 0
        ? (h / _availableHeight).clamp(0.0, 1.0)
        : 0.0;
    _effectiveController.updateState(
      height: h,
      fraction: fraction,
      detentIndex: _activeDetentIndex,
      isDismissed: _isClosing && h <= 0.01,
    );
  }

  void _onDriverStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.01) {
      widget.onDismiss?.call();
    }
  }

  double _heightForDetent(int index) {
    if (_availableHeight <= 0 || _sortedDetents.isEmpty) return 0.0;
    final int idx = index.clamp(0, _sortedDetents.length - 1);
    return _availableHeight * _sortedDetents[idx];
  }

  void _snapToDetentIndex(int index, {double? velocity}) {
    if (_availableHeight <= 0) return;
    _isClosing = false;
    final int idx = index.clamp(0, _sortedDetents.length - 1);
    final int previousIdx = _activeDetentIndex;
    _activeDetentIndex = idx;
    final double targetH = _heightForDetent(idx);
    _driver.springSpec = _resolvedStyle.detentSpring ?? OrionSpringSpec.gentle;
    _driver.retarget(targetH, velocity: velocity);
    if (previousIdx != idx) {
      widget.onDetentChanged?.call(idx);
    }
  }

  void _snapToPixelHeight(double height, {double? velocity}) {
    if (_availableHeight <= 0) return;
    _isClosing = false;
    _driver.springSpec = _resolvedStyle.detentSpring ?? OrionSpringSpec.gentle;
    _driver.retarget(height, velocity: velocity);

    // Find nearest detent for state reporting
    int nearest = 0;
    double bestDiff = double.infinity;
    for (int i = 0; i < _sortedDetents.length; i++) {
      final diff = (_heightForDetent(i) - height).abs();
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

  /// Triggers smooth downward dismissal of the sheet.
  void dismiss({double? velocity}) {
    _isClosing = true;
    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      widget.onDismiss?.call();
      return;
    }
    _driver.springSpec =
        _resolvedStyle.dismissSpring ??
        const OrionSpringSpec(
          stiffness: 300,
          dampingRatio: 1.0,
          clampOvershoot: true,
        );
    _driver.retarget(0.0, velocity: velocity);
  }

  OrionBottomSheetStyle _resolveStyle(ThemeData theme) {
    final OrionBottomSheetTheme sheetTheme =
        theme.extension<OrionBottomSheetTheme>() ??
        OrionBottomSheetTheme.fallback;
    return OrionBottomSheetPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(sheetTheme.defaultStyle).merge(widget.style);
  }

  @override
  void addPixelDelta(double delta) => _addPixelDelta(delta);

  @override
  void goBallistic(double velocity) => _settleOnDetent(velocity: velocity);

  void _addPixelDelta(double deltaH) {
    if (!widget.enableDrag || _availableHeight <= 0) return;
    final double currentH = _driver.value;
    final double maxH = _heightForDetent(_sortedDetents.length - 1);
    final double minH = _heightForDetent(0);
    final double rubberBand = _resolvedStyle.rubberBandFactor ?? 0.15;

    double effectiveDelta = deltaH;
    if (currentH >= maxH && deltaH > 0) {
      effectiveDelta = deltaH * rubberBand;
    } else if (!widget.isDismissible && currentH <= minH && deltaH < 0) {
      effectiveDelta = deltaH * rubberBand;
    }

    final double candidate = currentH + effectiveDelta;
    final double clamped;
    if (widget.isDismissible) {
      clamped = candidate.clamp(0.0, maxH + (_availableHeight * 0.2));
    } else {
      clamped = candidate.clamp(minH - 40.0, maxH + (_availableHeight * 0.2));
    }
    _driver.jumpTo(clamped);
  }

  void _settleOnDetent({required double velocity}) {
    if (_availableHeight <= 0) return;
    final double currentH = _driver.value;
    final double minH = _heightForDetent(0);
    final double dismissThresh = _resolvedStyle.dismissThreshold ?? 96.0;

    // velocity > 0 is upward, velocity < 0 is downward
    final double hProj = currentH + (velocity * 0.08);

    // 1. Dismiss Check (only if dismissible)
    if (widget.isDismissible) {
      if (velocity < -650.0 ||
          (currentH < minH - dismissThresh) ||
          (hProj < minH * 0.5 && velocity < -150.0)) {
        dismiss(velocity: velocity);
        OrionHaptics.trigger(OrionHapticType.lightImpact);
        return;
      }
    }

    // 2. Fling upward -> step to higher detent
    if (velocity > 500.0 && _activeDetentIndex < _sortedDetents.length - 1) {
      _snapToDetentIndex(_activeDetentIndex + 1, velocity: velocity);
      OrionHaptics.trigger(OrionHapticType.selectionClick);
      return;
    }

    // 3. Fling downward -> step to lower detent
    if (velocity < -500.0 && _activeDetentIndex > 0) {
      _snapToDetentIndex(_activeDetentIndex - 1, velocity: velocity);
      OrionHaptics.trigger(OrionHapticType.selectionClick);
      return;
    }

    // 4. Settle on nearest detent to projected height
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

  Widget _buildDragHandle(OrionBottomSheetStyle style) {
    if (!widget.showDragHandle) {
      return const SizedBox(height: 12.0);
    }

    final Size size = style.handleSize ?? const Size(36.0, 5.0);
    final Color color = style.handleColor ?? Colors.grey;

    return MouseRegion(
      cursor: widget.enableDrag
          ? SystemMouseCursors.grab
          : SystemMouseCursors.basic,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragStart: widget.enableDrag
            ? (_) {
                _handleDragging = true;
              }
            : null,
        onVerticalDragUpdate: widget.enableDrag
            ? (details) {
                if (!_handleDragging) return;
                final double dy = details.primaryDelta ?? details.delta.dy;
                _addPixelDelta(-dy);
              }
            : null,
        onVerticalDragEnd: widget.enableDrag
            ? (details) {
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
          constraints: const BoxConstraints(minHeight: 44.0),
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

  @override
  Widget build(BuildContext context) {
    final MediaQueryData media = MediaQuery.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxAvailable = constraints.maxHeight - media.padding.top;
        if (_availableHeight != maxAvailable && maxAvailable > 0) {
          final bool wasMounted = _mountedArrival;
          _availableHeight = maxAvailable;
          if (!wasMounted) {
            _mountedArrival = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                _snapToDetentIndex(_activeDetentIndex);
              }
            });
          } else if (!_handleDragging && !_contentDragging && !_isClosing) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted &&
                  !_handleDragging &&
                  !_contentDragging &&
                  !_isClosing) {
                _driver.jumpTo(_heightForDetent(_activeDetentIndex));
              }
            });
          }
        }

        final double maxH = _heightForDetent(_sortedDetents.length - 1);

        final BorderRadius radius =
            _resolvedStyle.borderRadius ??
            const BorderRadius.vertical(
              top: Radius.circular(OrionRadii.radius24),
            );
        final Color bg = _resolvedStyle.backgroundColor ?? _scheme.surface;
        final bool frosted = _resolvedStyle.frosted ?? false;

        final Widget sheetBackdrop = frosted
            ? BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: _orionTheme.blurSigma,
                  sigmaY: _orionTheme.blurSigma,
                ),
                child: ColoredBox(color: bg.withValues(alpha: 0.70)),
              )
            : ColoredBox(color: bg);

        final Widget innerContent = widget.builder(context, _scrollController);

        final Widget contentInteractiveWrapper = GestureDetector(
          behavior: HitTestBehavior.translucent,
          onVerticalDragStart: widget.enableDrag
              ? (details) {
                  if (_scrollController.hasClients) return;
                  _contentDragging = true;
                }
              : null,
          onVerticalDragUpdate: widget.enableDrag
              ? (details) {
                  if (!_contentDragging || _scrollController.hasClients) return;
                  final double dy = details.primaryDelta ?? details.delta.dy;
                  _addPixelDelta(-dy);
                }
              : null,
          onVerticalDragEnd: widget.enableDrag
              ? (details) {
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

        final Widget sheetContent = SizedBox(
          height: maxH,
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: radius,
              border: Border.all(
                color: _resolvedStyle.borderColor ?? _scheme.outlineVariant,
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
                    Positioned.fill(child: sheetBackdrop),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildDragHandle(_resolvedStyle),
                        Expanded(
                          child: Align(
                            alignment: Alignment.topCenter,
                            child: contentInteractiveWrapper,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        return AnimatedBuilder(
          animation: _driver,
          child: sheetContent,
          builder: (context, child) {
            final double height = _driver.value;
            final double translateY = (maxH - height).clamp(
              -_availableHeight * 0.3,
              maxH + 10.0,
            );
            final double minH = _heightForDetent(0);
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

            return Stack(
              children: [
                ?barrier,
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: maxH,
                  child: Transform.translate(
                    offset: Offset(0, translateY),
                    child: child,
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Presents an [OrionBottomSheet] as a modal route on the navigator.
Future<T?> showOrionBottomSheet<T>({
  required BuildContext context,
  required OrionSheetContentBuilder builder,
  List<double> detents = const <double>[0.5, 0.9],
  int initialDetentIndex = 0,
  bool isDismissible = true,
  bool enableDrag = true,
  bool showDragHandle = true,
  OrionBottomSheetStyle? style,
  OrionSheetController? controller,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    _OrionBottomSheetRoute<T>(
      builder: builder,
      detents: detents,
      initialDetentIndex: initialDetentIndex,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      showDragHandle: showDragHandle,
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
    required this.isDismissible,
    required this.enableDrag,
    required this.showDragHandle,
    this.style,
    this.sheetController,
    super.settings,
  });

  final OrionSheetContentBuilder builder;
  final List<double> detents;
  final int initialDetentIndex;
  final bool isDismissible;
  final bool enableDrag;
  final bool showDragHandle;
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
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (isDismissible) {
          _sheetKey.currentState?.dismiss();
        }
      },
      child: OrionBottomSheet(
        key: _sheetKey,
        builder: builder,
        detents: detents,
        initialDetentIndex: initialDetentIndex,
        enableDrag: enableDrag,
        showDragHandle: showDragHandle,
        style: style,
        controller: sheetController,
        hasBarrier: true,
        barrierDismissible: isDismissible,
        isDismissible: isDismissible,
        onDismiss: () {
          if (navigator?.canPop() ?? false) {
            navigator?.pop();
          }
        },
      ),
    );
  }
}
