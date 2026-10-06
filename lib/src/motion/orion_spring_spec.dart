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
    this.clampOvershoot = false,
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

  /// Whether the value must not pass its target, for the cases where passing it would
  /// read as a mistake rather than as life: a dismissal, an exit, or anything that
  /// moves a layout edge. The spring still decelerates; it just stops at the target.
  final bool clampOvershoot;

  /// Creates a Flutter [SpringDescription] utilizing the damping ratio formula:
  /// $c = 2 \cdot \zeta \cdot \sqrt{k \cdot m}$.
  SpringDescription toDescription() {
    return SpringDescription.withDampingRatio(
      mass: mass,
      stiffness: stiffness,
      ratio: dampingRatio,
    );
  }

  /// Press spring for the release of a held control, where the travel is a few percent
  /// of the scale. Damping ratio 0.36 is deliberately bouncy: on a 0.04 scale release
  /// it peaks near 1.012, which reads as tactility rather than as wobble.
  ///
  /// Do not use it for travel. Over a full 0 to 1 change the same ratio peaks near
  /// 1.30, and a spring that overshoots its target by a third has to be clamped or
  /// damped by hand at every call site.
  static const snappy = OrionSpringSpec(stiffness: 380.0, dampingRatio: 0.36);

  /// Travel spring for surfaces that move a visible distance: rows, sheets, tracks.
  ///
  /// Damping ratio 0.8 sits inside the band production references use for movement
  /// (0.8 to 1.0 across the Reanimated and Skia components in `.reference/`), and peaks
  /// near 1.015 of the travel - enough to feel physical, not enough to read as bounce.
  static const gentle = OrionSpringSpec(stiffness: 260.0, dampingRatio: 0.8);

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
        other.dampingRatio == dampingRatio &&
        other.clampOvershoot == clampOvershoot;
  }

  @override
  int get hashCode =>
      Object.hash(mass, stiffness, dampingRatio, clampOvershoot);
}
