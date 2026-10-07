import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// An unopinionated, headless tactile gesture wrapper driven by spring physics.
///
/// Features:
/// - **One Retargeted Spring:** Uses [OrionSpringDriver] to smoothly compress to
///   [pressedScale] and return to `1.0` without position snapping or velocity truncation.
/// - **Scroll-First Cooperation:** Uses a passive [Listener] to provide visual compression
///   immediately on touch, while allowing parent [Scrollable] widgets to win the gesture
///   arena on scroll without delay or resistance. Raw pointer up ensures the spring always
///   returns to `1.0` even on fast flicks where the tap recognizer was rejected early.
/// - **Success-Only Execution:** Action callbacks ([onTap]) and tactile haptics fire
///   strictly when the tap cleanly wins the arena. Gesture cancellation restores the spring
///   to `1.0` silently with zero haptic feedback.
/// - **Rebuild Isolation:** Ticker frame updates only modify the render-level [Transform.scale]
///   around the pre-built [child], never triggering widget rebuilds per frame.
///
/// Tracking is single-pointer: a concurrent second pointer replaces the tracked
/// origin, and either pointer's lift or cancel ends the compression.
class OrionPressable extends StatefulWidget {
  const OrionPressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.pressedScale = 0.96,
    this.springSpec = OrionSpringSpec.snappy,
    this.releaseSpringSpec,
    this.hapticType = OrionHapticType.none,
    this.impactHapticType = OrionHapticType.mediumImpact,
    this.behavior = HitTestBehavior.opaque,
    this.cursor,
  }) : assert(
         pressedScale > 0.0 && pressedScale <= 1.0,
         'pressedScale must be between 0.0 and 1.0',
       );

  /// The widget subtree wrapped by this pressable.
  ///
  /// This child is held stable and is never rebuilt on ticker animation frames.
  final Widget child;

  /// Callback executed when a tap cleanly finishes in the gesture arena.
  final VoidCallback? onTap;

  /// Optional callback executed on long press.
  final VoidCallback? onLongPress;

  /// The target scale when pressed down (default 0.96).
  final double pressedScale;

  /// The physical spring specification governing compression on pointer down.
  final OrionSpringSpec springSpec;

  /// Optional spring specification governing release on pointer up / cancel.
  ///
  /// If null, [springSpec] is used symmetrically for both down and up.
  final OrionSpringSpec? releaseSpringSpec;

  /// The tactile haptic feedback triggered upon tap completion.
  ///
  /// Defaults to [OrionHapticType.none]: an activation that changes no state should not
  /// tick, which is the platform's own habit - iOS haptics mark a transition, not a tap.
  /// A component whose tap *is* a transition (a switch flipping, a chip choosing, a
  /// detent crossing) opts in by passing one.
  final OrionHapticType hapticType;

  /// The tactile haptic feedback triggered upon long-press recognition.
  final OrionHapticType impactHapticType;

  /// How this gesture detector behaves during hit testing.
  final HitTestBehavior behavior;

  /// Mouse cursor shown when hovering over this pressable on desktop/web.
  final MouseCursor? cursor;

  @override
  State<OrionPressable> createState() => OrionPressableState();
}

class OrionPressableState extends State<OrionPressable>
    with SingleTickerProviderStateMixin {
  /// The underlying physical spring driver.
  @visibleForTesting
  late final OrionSpringDriver driver;

  bool _isPointerDown = false;
  bool _isLongPressing = false;
  Offset? _pointerDownPosition;
  DeviceGestureSettings? _gestureSettings;

  bool get _isEnabled => widget.onTap != null || widget.onLongPress != null;

  @override
  void initState() {
    super.initState();
    driver = OrionSpringDriver(
      vsync: this,
      springSpec: widget.springSpec,
      initialValue: 1.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    driver.reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _gestureSettings = MediaQuery.maybeGestureSettingsOf(context);
  }

  @override
  void didUpdateWidget(OrionPressable oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.springSpec != oldWidget.springSpec) {
      driver.springSpec = widget.springSpec;
    }
    if (!_isEnabled && driver.target != 1.0) {
      _releaseToRest();
    }
  }

  @override
  void dispose() {
    driver.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_isEnabled) return;
    // Filter non-primary mouse clicks (right click, middle click on desktop/web)
    if (event.kind == PointerDeviceKind.mouse &&
        event.buttons != kPrimaryButton) {
      return;
    }

    _isPointerDown = true;
    _pointerDownPosition = event.position;
    driver.springSpec = widget.springSpec;
    driver.retarget(widget.pressedScale);
  }

  void _onPointerMove(PointerMoveEvent event) {
    if (!mounted ||
        !_isPointerDown ||
        _pointerDownPosition == null ||
        _isLongPressing) {
      return;
    }

    final slop = computeHitSlop(event.kind, _gestureSettings);
    if ((event.position - _pointerDownPosition!).distance > slop) {
      _isPointerDown = false;
      _pointerDownPosition = null;
      _releaseToRest();
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    _pointerDownPosition = null;
    if (!mounted) return;
    _isPointerDown = false;
    _releaseToRest();
  }

  void _onPointerCancel(PointerCancelEvent event) {
    _pointerDownPosition = null;
    if (!mounted) return;
    _isPointerDown = false;
    _releaseToRest();
  }

  void _onTap() {
    if (widget.onTap == null) return;

    _releaseToRest();
    OrionHaptics.trigger(widget.hapticType);
    widget.onTap!();
  }

  void _onTapCancel() {
    // If a long-press is possible and the pointer is still held down,
    // do not uncompress; the long-press recognizer is handling the hold.
    if (widget.onLongPress != null && _isPointerDown) {
      return;
    }
    _releaseToRest();
  }

  void _onLongPressStart(LongPressStartDetails details) {
    if (widget.onLongPress == null) return;

    _isLongPressing = true;
    OrionHaptics.trigger(widget.impactHapticType);
    widget.onLongPress!();
  }

  void _onLongPressEnd(LongPressEndDetails details) {
    _isPointerDown = false;
    _isLongPressing = false;
    _pointerDownPosition = null;
    _releaseToRest();
  }

  void _onLongPressCancel() {
    _isPointerDown = false;
    _isLongPressing = false;
    _pointerDownPosition = null;
    _releaseToRest();
  }

  /// Releases the compression, on the release spec where one is given. A tap and a
  /// cancel both land here, so the release cannot differ by how the gesture ended.
  ///
  /// No velocity is handed over: a press either releases at rest, or is cancelled after
  /// the pointer has already left the target, so there is no gesture motion to continue.
  void _releaseToRest() {
    if (!mounted) return;
    driver.springSpec = widget.releaseSpringSpec ?? widget.springSpec;
    driver.retarget(1.0);
  }

  @override
  Widget build(BuildContext context) {
    final effectiveCursor =
        widget.cursor ??
        (_isEnabled ? SystemMouseCursors.click : MouseCursor.defer);

    return MouseRegion(
      cursor: effectiveCursor,
      child: Listener(
        behavior: widget.behavior,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: GestureDetector(
          behavior: widget.behavior,
          onTap: widget.onTap != null ? _onTap : null,
          onTapCancel: _isEnabled ? _onTapCancel : null,
          onLongPressStart: widget.onLongPress != null
              ? _onLongPressStart
              : null,
          onLongPressEnd: widget.onLongPress != null ? _onLongPressEnd : null,
          onLongPressCancel: widget.onLongPress != null
              ? _onLongPressCancel
              : null,
          child: AnimatedBuilder(
            animation: driver,
            // Pre-built child reference is passed here to ensure zero per-frame rebuilds.
            child: widget.child,
            builder: (context, child) {
              return Transform.scale(
                scale: driver.value,
                alignment: Alignment.center,
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}
