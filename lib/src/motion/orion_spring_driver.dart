import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Drives a continuous scalar value with a retargetable [SpringSimulation].
///
/// The driver owns its ticker and its simulation, so retargeting in flight re-anchors
/// the physics without restarting the clock: a target that moves every frame is
/// followed rather than fought. A retarget may also carry the velocity of the gesture
/// that produced it, which is what lets a release continue the finger's motion instead
/// of starting from rest.
///
/// Reduced motion is an explicit input rather than a global read: the widget that knows
/// the [MediaQuery] tells the driver once, and the driver lands immediately.
///
/// The simulation itself is continuous - retargeting inherits the current value and
/// velocity - so mid-flight reversals neither snap nor truncate.
class OrionSpringDriver extends Animation<double>
    with AnimationLocalListenersMixin, AnimationLocalStatusListenersMixin {
  OrionSpringDriver({
    required TickerProvider vsync,
    OrionSpringSpec springSpec = OrionSpringSpec.gentle,
    double initialValue = 1.0,
  }) : _springSpec = springSpec,
       _value = initialValue,
       _target = initialValue,
       _startValue = initialValue {
    _ticker = vsync.createTicker(_tick);
  }

  late final Ticker _ticker;
  OrionSpringSpec _springSpec;
  double _value;
  double _target;
  double _startValue;
  double _velocity = 0;
  SpringSimulation? _simulation;
  Duration _simulationStart = Duration.zero;
  Duration _lastTick = Duration.zero;
  AnimationStatus _status = AnimationStatus.completed;
  bool _reducedMotion = false;

  /// The active spring specification governing stiffness and damping.
  OrionSpringSpec get springSpec => _springSpec;
  set springSpec(OrionSpringSpec value) {
    if (_springSpec == value) {
      return;
    }
    _springSpec = value;
    if (isAnimating) {
      retarget(_target);
    }
  }

  /// The current destination value toward which the spring is moving.
  double get target => _target;

  @override
  double get value => _value;

  /// Current instantaneous velocity of the spring, in value units per second.
  double get velocity => _velocity;

  @override
  AnimationStatus get status => _status;

  @override
  bool get isAnimating => _ticker.isActive;

  /// Whether motion is disabled. Every retarget then lands in the same frame.
  bool get reducedMotion => _reducedMotion;
  set reducedMotion(bool value) {
    if (_reducedMotion == value) {
      return;
    }
    _reducedMotion = value;
    if (_reducedMotion && isAnimating) {
      _settleAt(_target);
    }
  }

  /// Retargets the spring simulation to [newTarget].
  ///
  /// Pass [velocity] - in value units per second, the sign pointing toward increasing
  /// value - to hand over the motion of the gesture that caused the retarget. Without
  /// it the simulation inherits the velocity it already has, which is what keeps a
  /// mid-flight retarget continuous.
  void retarget(double newTarget, {double? velocity}) {
    _target = newTarget;
    if (velocity != null) {
      _velocity = velocity;
    }
    if (_reducedMotion) {
      _settleAt(newTarget);
      return;
    }
    _startValue = _value;
    _simulation = SpringSimulation(
      _springSpec.toDescription(),
      _value,
      newTarget,
      _velocity,
      snapToEnd: true,
    );
    if (_ticker.isActive) {
      // Continue the running clock rather than restarting it: the new simulation starts
      // at t = 0 on the next frame, so a per-frame retarget loses no time at all.
      _simulationStart = _lastTick;
    } else {
      // A ticker's elapsed time restarts from zero, so the clock has to as well.
      _lastTick = Duration.zero;
      _simulationStart = Duration.zero;
      _setStatus(AnimationStatus.forward);
      _ticker.start();
    }
  }

  /// Immediately sets the value to [forcedValue] without animating.
  ///
  /// A silent reposition: value listeners hear about the new value, but the status does
  /// not change, because the driver has not arrived anywhere - a drag calls this on every
  /// update, and a status notification per move would read as a completed animation.
  void jumpTo(double forcedValue) {
    _ticker.stop();
    _simulation = null;
    _target = forcedValue;
    _value = forcedValue;
    _velocity = 0;
    notifyListeners();
  }

  /// Stops the simulation where it is, keeping the current value and target.
  void stop() {
    if (!_ticker.isActive) {
      return;
    }
    _ticker.stop();
    _simulation = null;
    _velocity = 0;
    // Interrupted, not arrived: the status lands silently, and only a real arrival
    // announces itself. `jumpTo` differs: it leaves the status alone entirely.
    _status = AnimationStatus.completed;
  }

  void dispose() {
    _ticker.dispose();
  }

  // The driver animates only when it is retargeted, so it has no lazy-listener work to
  // do when the first listener arrives.
  @override
  void didRegisterListener() {}

  @override
  void didUnregisterListener() {}

  void _settleAt(double settled) {
    _ticker.stop();
    _simulation = null;
    _target = settled;
    _value = settled;
    _velocity = 0;
    _setStatus(AnimationStatus.completed);
    notifyListeners();
  }

  /// Announces a status only when it actually changes, so a retarget that finds the
  /// driver already running does not re-announce `forward`.
  void _setStatus(AnimationStatus status) {
    if (_status == status) {
      return;
    }
    _status = status;
    notifyStatusListeners(_status);
  }

  void _tick(Duration elapsed) {
    final SpringSimulation? simulation = _simulation;
    if (simulation == null) {
      return;
    }
    _lastTick = elapsed;
    final double t =
        (elapsed - _simulationStart).inMicroseconds /
        Duration.microsecondsPerSecond;
    _velocity = simulation.dx(t);
    double next = simulation.x(t);
    if (_springSpec.clampOvershoot) {
      next = _startValue <= _target
          ? next.clamp(double.negativeInfinity, _target)
          : next.clamp(_target, double.infinity);
    }
    _value = next;
    if (simulation.isDone(t) || next == _target) {
      _settleAt(_target);
      return;
    }
    notifyListeners();
  }
}
