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
const double _collapsedStep = 14.0;

/// Height assumed for a card that has not been laid out yet.
const double _unmeasuredHeight = 64.0;

/// Travel the newest card enters from.
const double _entranceTravel = 16.0;

/// Top-level toast notification stack host.
///
/// Mount this widget at the root of the app (e.g. inside [MaterialApp.builder])
/// or over any stack view. It listens to [OrionToastController.instance] and
/// renders active toasts in an interactive 3D perspective stack.
class OrionToaster extends StatefulWidget {
  const OrionToaster({
    super.key,
    this.child,
    this.position = OrionToastPosition.bottomCenter,
    this.maxVisible = 3,
    this.gap = 12.0,
    this.style,
  });

  /// Optional app subtree wrapped by this toaster overlay.
  final Widget? child;

  /// Placement anchor on screen.
  final OrionToastPosition position;

  /// Maximum visible toasts shown simultaneously in the stack.
  final int maxVisible;

  /// Vertical separation gap when the stack is expanded.
  final double gap;

  /// Global style overrides for the toast stack.
  final OrionToastStyle? style;

  @override
  State<OrionToaster> createState() => _OrionToasterState();
}

class _OrionToasterState extends State<OrionToaster> {
  final OrionToastController _controller = OrionToastController.instance;
  final OverlayPortalController _portalController = OverlayPortalController();
  final Set<int> _pointers = <int>{};
  final List<OrionToastData> _departing = <OrionToastData>[];

  /// What the stack was last told to show, so a card that leaves the window can
  /// be told apart from a card the host has dropped.
  List<OrionToastData> _shown = <OrionToastData>[];
  bool _expanded = false;
  String? _lastAnnouncement;
  FlutterView? _view;
  bool _supportsAnnounce = false;
  TextDirection _textDirection = TextDirection.ltr;

  /// The toasts the stack shows, newest last.
  List<OrionToastData> get _visibleToasts {
    final List<OrionToastData> all = _controller.toasts;
    return all.length > widget.maxVisible
        ? all.sublist(all.length - widget.maxVisible)
        : all;
  }

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onToastsChanged);
    _shown = _visibleToasts;
    if (_shown.isNotEmpty) {
      _portalController.show();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Cached here, where ancestor lookups are allowed: the announcement runs from
    // a controller notification, which can arrive while the element is merely
    // deactivated, and the framework forbids looking anything up there.
    _view = View.maybeOf(context);
    _supportsAnnounce = MediaQuery.supportsAnnounceOf(context);
    _textDirection = Directionality.maybeOf(context) ?? TextDirection.ltr;
  }

  @override
  void dispose() {
    _controller.removeListener(_onToastsChanged);
    super.dispose();
  }

  void _syncPortal() {
    final bool hasWork = _shown.isNotEmpty || _departing.isNotEmpty;
    if (hasWork && !_portalController.isShowing) {
      _portalController.show();
    } else if (!hasWork && _portalController.isShowing) {
      _portalController.hide();
    }
  }

  void _onToastsChanged() {
    if (!mounted) return;
    final List<OrionToastData> visible = _visibleToasts;
    final Set<String> live = <String>{
      for (final OrionToastData toast in _controller.toasts) toast.id,
    };

    // A card that was on screen when its toast was dropped keeps its place for
    // one last glide; the stack stays mounted until that glide lands.
    for (final OrionToastData was in _shown) {
      if (!live.contains(was.id) &&
          !_departing.any((OrionToastData d) => d.id == was.id)) {
        _departing.add(was);
      }
    }
    // Shown again while it was still leaving: it takes its card back.
    _departing.removeWhere((OrionToastData d) => live.contains(d.id));
    _shown = visible;

    if (_controller.toasts.isEmpty) {
      // The stack is gone: any finger that was holding it can no longer report
      // its release, so the hold state cannot outlive the cards.
      _pointers.clear();
      _expanded = false;
    }
    _syncPortal();
    setState(() {});
    _announceLatest();
  }

  void _onDeparted(String id) {
    setState(() {
      _departing.removeWhere((OrionToastData d) => d.id == id);
      _syncPortal();
    });
  }

  /// Speaks the front toast whenever it arrives or its message changes.
  ///
  /// Counting arrivals alone would keep an in-place update silent, and the
  /// update is the point: a loading toast that resolves to success is the same
  /// toast carrying a new message.
  ///
  /// Everything it needs is cached in [didChangeDependencies]: this runs from a
  /// controller notification, which can arrive while the element is deactivated
  /// and no ancestor may be looked up.
  void _announceLatest() {
    final List<OrionToastData> toasts = _controller.toasts;
    if (toasts.isEmpty) {
      _lastAnnouncement = null;
      return;
    }
    final OrionToastData latest = toasts.last;
    final String spoken = latest.description == null
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

  void _onPointerDown(PointerDownEvent event) {
    _pointers.add(event.pointer);
    _controller.pauseTimers();
    if (!_expanded) {
      setState(() => _expanded = true);
    }
  }

  void _onPointerUp(PointerUpEvent event) => _releasePointer(event.pointer);

  void _onPointerCancel(PointerCancelEvent event) =>
      _releasePointer(event.pointer);

  /// Collapses the stack and resumes timers once the last finger is off it.
  ///
  /// A release can arrive after the toaster has left the tree - the framework
  /// still delivers to the hit test route the finger went down on - so the
  /// timers are handed back first, and the rebuild is guarded.
  void _releasePointer(int pointer) {
    _pointers.remove(pointer);
    if (_pointers.isNotEmpty) {
      return;
    }
    _controller.resumeTimers();
    if (!mounted) {
      return;
    }
    if (_expanded) {
      setState(() => _expanded = false);
    }
  }

  Widget _buildStackWidget(BuildContext context) {
    final bool isTop = widget.position == OrionToastPosition.topCenter;
    final List<OrionToastData> visibleToasts = _visibleToasts;

    return SafeArea(
      child: Align(
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        child: Padding(
          padding: isTop
              ? const EdgeInsets.only(top: 48, left: 16, right: 16)
              : const EdgeInsets.only(bottom: 32, left: 16, right: 16),
          child: MouseRegion(
            onEnter: (_) {
              _controller.pauseTimers();
              if (!_expanded) {
                setState(() => _expanded = true);
              }
            },
            onExit: (_) {
              _controller.resumeTimers();
              if (_expanded) {
                setState(() => _expanded = false);
              }
            },
            child: Listener(
              // The stack owns its whole band, peek strips included: a tap on the
              // visible edge of a card behind the front one expands the stack
              // instead of falling through to whatever the app has underneath.
              behavior: HitTestBehavior.opaque,
              onPointerDown: _onPointerDown,
              onPointerUp: _onPointerUp,
              onPointerCancel: _onPointerCancel,
              child: _ToastStackLayout(
                toasts: visibleToasts,
                departing: _departing,
                expanded: _expanded,
                position: widget.position,
                gap: widget.gap,
                style: widget.style,
                onDismiss: (String id) => _controller.dismiss(id),
                onDeparted: _onDeparted,
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
    // The stack stays mounted while a dropped card is still gliding out, so the
    // exit is seen through to the end instead of being cut with the queue.
    final bool hasWork = _visibleToasts.isNotEmpty || _departing.isNotEmpty;

    if (hasOverlay) {
      return OverlayPortal(
        controller: _portalController,
        overlayChildBuilder: (BuildContext context) =>
            hasWork ? _buildStackWidget(context) : const SizedBox.shrink(),
        child: widget.child ?? const SizedBox.shrink(),
      );
    }

    final Widget stackWidget = hasWork
        ? _buildStackWidget(context)
        : const SizedBox.shrink();
    if (widget.child == null) {
      return stackWidget;
    }

    return Stack(
      children: [
        widget.child!,
        Positioned.fill(
          child: IgnorePointer(ignoring: !hasWork, child: stackWidget),
        ),
      ],
    );
  }
}

/// Lays the visible toasts out as a depth stack.
///
/// Spacing comes from the height each card actually laid out at, reported back
/// after the frame: an estimate cannot know how many lines a message wrapped to,
/// and a card that is taller than the estimate hides the one behind it.
class _ToastStackLayout extends StatefulWidget {
  const _ToastStackLayout({
    required this.toasts,
    required this.departing,
    required this.expanded,
    required this.position,
    required this.gap,
    required this.style,
    required this.onDismiss,
    required this.onDeparted,
  });

  /// The toasts this stack shows, oldest first.
  final List<OrionToastData> toasts;

  /// Toasts the host has dropped whose cards are still gliding out. They hold
  /// the depth they had; the stack only keeps them on screen.
  final List<OrionToastData> departing;

  final bool expanded;
  final OrionToastPosition position;
  final double gap;
  final OrionToastStyle? style;
  final ValueChanged<String> onDismiss;

  /// Invoked when a departing card has finished leaving.
  final ValueChanged<String> onDeparted;

  @override
  State<_ToastStackLayout> createState() => _ToastStackLayoutState();
}

class _ToastStackLayoutState extends State<_ToastStackLayout> {
  final Map<String, double> _heights = <String, double>{};

  /// The deepest band the stack has needed, so the reserved area does not shrink
  /// out from under a card that is still leaving.
  double _reserve = 0;

  /// How far behind the front card tier [tier] sits, in the direction the stack
  /// grows (the sign of that direction belongs to the item, which knows the
  /// anchor).
  double _offsetOf(int tier, List<OrionToastData> reversed) {
    if (!widget.expanded) {
      return tier * _collapsedStep;
    }
    double offset = 0;
    for (int i = 0; i < tier; i++) {
      offset += (_heights[reversed[i].id] ?? _unmeasuredHeight) + widget.gap;
    }
    return offset;
  }

  @override
  void didUpdateWidget(_ToastStackLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Measurements only matter for what is drawn: a toast that has been gone for
    // a while must not be remembered forever.
    final Set<String> drawn = <String>{
      ...widget.toasts.map((OrionToastData t) => t.id),
      ...widget.departing.map((OrionToastData t) => t.id),
    };
    _heights.removeWhere((String id, double _) => !drawn.contains(id));
  }

  void _measure(String id, double height) {
    if (_heights[id] == height) {
      return;
    }
    setState(() => _heights[id] = height);
  }

  @override
  Widget build(BuildContext context) {
    final bool isTop = widget.position == OrionToastPosition.topCenter;
    final List<OrionToastData> reversed = widget.toasts.reversed.toList();

    double extent = 0;
    for (int tier = 1; tier < reversed.length; tier++) {
      final double offset = _offsetOf(tier, reversed);
      if (offset > extent) {
        extent = offset;
      }
    }
    _reserve = widget.departing.isEmpty ? extent : math.max(_reserve, extent);

    return Padding(
      // Reserve the band the cards behind the front one travel through, so the
      // interactive area of the stack covers what the user can see of it.
      padding: isTop
          ? EdgeInsets.only(bottom: _reserve)
          : EdgeInsets.only(top: _reserve),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
        children: [
          for (int i = reversed.length - 1; i >= 0; i--)
            _ToastStackItem(
              key: ValueKey<String>(reversed[i].id),
              data: reversed[i],
              tierIndex: i,
              expandedOffset: _offsetOf(i, reversed),
              expanded: widget.expanded,
              isTop: isTop,
              style: widget.style,
              onDismiss: widget.onDismiss,
              onMeasured: (double height) => _measure(reversed[i].id, height),
            ),
          for (final OrionToastData leaving in widget.departing)
            _ToastStackItem(
              key: ValueKey<String>(leaving.id),
              data: leaving,
              tierIndex: 0,
              expandedOffset: 0,
              expanded: widget.expanded,
              isTop: isTop,
              style: widget.style,
              departing: true,
              onDismiss: widget.onDismiss,
              onExited: () => widget.onDeparted(leaving.id),
              onMeasured: (double height) => _measure(leaving.id, height),
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
    required this.isTop,
    required this.style,
    required this.onDismiss,
    required this.onMeasured,
    this.departing = false,
    this.onExited,
  });

  final OrionToastData data;
  final int tierIndex;

  /// How far behind the front card this one sits while the stack is expanded.
  final double expandedOffset;
  final bool expanded;
  final bool isTop;
  final OrionToastStyle? style;
  final ValueChanged<String> onDismiss;

  /// Reports this card's laid-out height, which the stack spaces itself by.
  final ValueChanged<double> onMeasured;

  /// Whether the host has dropped this toast and is only waiting for the card.
  /// A departing card holds the depth it had: it is leaving, not shuffling.
  final bool departing;

  /// Invoked when a [departing] card has finished leaving.
  final VoidCallback? onExited;

  @override
  State<_ToastStackItem> createState() => _ToastStackItemState();
}

class _ToastStackItemState extends State<_ToastStackItem>
    with TickerProviderStateMixin {
  static const OrionSpringSpec _fallbackStack = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 0.95,
  );
  static const OrionSpringSpec _fallbackMount = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 0.85,
  );

  late final OrionSpringDriver _yDriver;
  late final OrionSpringDriver _scaleDriver;
  late final OrionSpringDriver _opacityDriver;
  OrionSpringSpec _stackSpring = _fallbackStack;
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
    return (1.0 - (widget.tierIndex * 0.07)).clamp(0.8, 1.0);
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
      2 => 0.75,
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
      stackStyle: widget.style,
      instanceStyle: widget.data.style,
    );
    _stackSpring = style.stackSpring ?? _fallbackStack;
    _scaleDriver.springSpec = _stackSpring;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _yDriver.reducedMotion = reduced;
    _scaleDriver.reducedMotion = reduced;
    _opacityDriver.reducedMotion = reduced;

    if (_entered) {
      return;
    }
    _entered = true;
    // The newest card is the one the user has to notice, so it travels in from
    // just outside its resting place instead of appearing already at rest.
    _yDriver
      ..springSpec = style.mountSpring ?? _fallbackMount
      ..jumpTo(_targetY + (widget.isTop ? -_entranceTravel : _entranceTravel));
    _opacityDriver
      ..springSpec = style.mountSpring ?? _fallbackMount
      ..jumpTo(0.0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _yDriver.retarget(_targetY);
      _opacityDriver.retarget(_targetOpacity);
    });
  }

  @override
  void didUpdateWidget(_ToastStackItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Targets are compared rather than widget fields: a height measured after
    // the last build, a flipped anchor and a tier change all have to reach the
    // springs, and none of them are a field of this widget.
    final bool moved = _yDriver.target != _targetY;
    final bool scaled = _scaleDriver.target != _targetScale;
    final bool faded = _opacityDriver.target != _targetOpacity;
    if (!moved && !scaled && !faded) {
      return;
    }
    // Past its entrance, stack travel is travel: it runs on the stack spring.
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
    // Hand the laid-out height back once the frame is done, so the stack can
    // space the expanded column by real card heights.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
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
        style: widget.style,
        departing: widget.departing,
        onDismiss: widget.onDismiss,
        onExited: widget.onExited,
      ),
      builder: (BuildContext context, Widget? child) {
        final double y = _yDriver.value;
        final double scale = _scaleDriver.value;
        final double opacity = _opacityDriver.value.clamp(0.0, 1.0);

        return Transform.translate(
          offset: Offset(0, y),
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
