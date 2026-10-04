import 'package:flutter/animation.dart';
import 'package:flutter/physics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Drives a continuous scalar value using retargetable [SpringSimulation].
///
/// Unlike fixed-duration curves, retargeting an [OrionSpringDriver] mid-flight
/// starts a new simulation from the exact current position and ongoing velocity,
/// guaranteeing zero position snapping or velocity truncation.
class OrionSpringDriver extends Animation<double> {
  OrionSpringDriver({
    required TickerProvider vsync,
    OrionSpringSpec springSpec = OrionSpringSpec.snappy,
    double initialValue = 1.0,
  }) : _springSpec = springSpec,
       _currentTarget = initialValue {
    _controller = AnimationController.unbounded(
      value: initialValue,
      vsync: vsync,
    );
  }

  late final AnimationController _controller;
  OrionSpringSpec _springSpec;
  double _currentTarget;

  /// The active spring specification governing stiffness and damping.
  OrionSpringSpec get springSpec => _springSpec;
  set springSpec(OrionSpringSpec value) {
    if (_springSpec != value) {
      _springSpec = value;
      if (isAnimating) {
        retarget(_currentTarget);
      }
    }
  }

  /// The current destination value toward which the spring is moving.
  double get target => _currentTarget;

  @override
  double get value => _controller.value;

  /// Current instantaneous velocity of the spring simulation.
  double get velocity => _controller.velocity;

  @override
  AnimationStatus get status => _controller.status;

  @override
  bool get isAnimating => _controller.isAnimating;

  @override
  void addListener(VoidCallback listener) => _controller.addListener(listener);

  @override
  void removeListener(VoidCallback listener) =>
      _controller.removeListener(listener);

  @override
  void addStatusListener(AnimationStatusListener listener) =>
      _controller.addStatusListener(listener);

  @override
  void removeStatusListener(AnimationStatusListener listener) =>
      _controller.removeStatusListener(listener);

  /// Retargets the spring simulation to [newTarget].
  ///
  /// The new simulation seamlessly inherits the current value and current velocity.
  void retarget(double newTarget) {
    _currentTarget = newTarget;

    final currentPosition = _controller.value;
    final currentVelocity = _controller.velocity;

    // Build continuous simulation starting from exact current state with snapToEnd
    final simulation = SpringSimulation(
      _springSpec.toDescription(),
      currentPosition,
      newTarget,
      currentVelocity,
      snapToEnd: true,
    );

    _controller.animateWith(simulation);
  }

  /// Immediately sets value to [forcedValue] without animation.
  /// Used when animations are disabled or for initial resets.
  void jumpTo(double forcedValue) {
    _currentTarget = forcedValue;
    _controller.stop();
    _controller.value = forcedValue;
  }

  /// Stops any running simulation.
  void stop() {
    _controller.stop();
  }

  void dispose() {
    _controller.dispose();
  }
}
