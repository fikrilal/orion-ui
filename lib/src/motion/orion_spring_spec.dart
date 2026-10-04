import 'package:flutter/physics.dart';

/// Specification for a natural physical spring.
///
/// Uses [SpringDescription.withDampingRatio] to calculate the damping coefficient
/// from [dampingRatio] ($\zeta$), [stiffness] ($k$), and [mass] ($m$).
///
/// An underdamped spring ($\zeta < 1.0$) produces a subtle, organic release bounce.
/// The analytic overshoot fraction of the travel distance is $\exp(-\pi \zeta / \sqrt{1 - \zeta^2})$.
/// For example, on a $0.04$ scale release ($0.96 \to 1.0$) with $\zeta = 0.36$, the spring
/// overshoots by $\approx 1.2\%$ of scale (peak scale $\approx 1.012$) before settling
/// smoothly at 1.0.
class OrionSpringSpec {
  const OrionSpringSpec({
    this.mass = 1.0,
    required this.stiffness,
    required this.dampingRatio,
  }) : assert(mass > 0, 'mass must be positive'),
       assert(stiffness > 0, 'stiffness must be positive'),
       assert(dampingRatio > 0, 'dampingRatio must be positive');

  /// Mass of the spring object (typically 1.0).
  final double mass;

  /// Spring stiffness coefficient $k$. Higher values respond faster.
  final double stiffness;

  /// Damping ratio $\zeta$.
  /// - $\zeta = 1.0$: Critically damped (no bounce).
  /// - $\zeta < 1.0$: Underdamped (tactile bounce/overshoot).
  /// - $\zeta > 1.0$: Overdamped (sluggish, no bounce).
  final double dampingRatio;

  /// Creates a Flutter [SpringDescription] utilizing the damping ratio formula:
  /// $c = 2 \cdot \zeta \cdot \sqrt{k \cdot m}$.
  SpringDescription toDescription() {
    return SpringDescription.withDampingRatio(
      mass: mass,
      stiffness: stiffness,
      ratio: dampingRatio,
    );
  }

  /// Default snappy spring for buttons, switches, and tactile controls.
  /// Damping ratio 0.36 produces a visible, crisp release bounce of ~1.2%.
  static const snappy = OrionSpringSpec(stiffness: 380.0, dampingRatio: 0.36);

  /// Gentle spring for larger surfaces, cards, and modal sheets.
  /// Damping ratio 0.72 provides a smooth settle with subtle bounce.
  static const gentle = OrionSpringSpec(stiffness: 260.0, dampingRatio: 0.72);

  /// Immediate, highly responsive spring for micro-indicators and badges.
  /// Damping ratio 0.85 settles rapidly without noticeable oscillation.
  static const immediate = OrionSpringSpec(
    stiffness: 500.0,
    dampingRatio: 0.85,
  );

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionSpringSpec &&
        other.mass == mass &&
        other.stiffness == stiffness &&
        other.dampingRatio == dampingRatio;
  }

  @override
  int get hashCode => Object.hash(mass, stiffness, dampingRatio);
}
