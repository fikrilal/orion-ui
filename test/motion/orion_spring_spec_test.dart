import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionSpringSpec', () {
    test('creates valid SpringDescription with damping ratio', () {
      const spec = OrionSpringSpec(
        mass: 1.0,
        stiffness: 380.0,
        dampingRatio: 0.36,
      );

      final desc = spec.toDescription();
      expect(desc.mass, 1.0);
      expect(desc.stiffness, 380.0);
      // Damping coefficient c = 2 * ratio * sqrt(mass * stiffness)
      // c = 2 * 0.36 * sqrt(380) = 0.72 * 19.49358874... ≈ 14.035
      expect(desc.damping, closeTo(14.035, 0.01));
    });

    test(
      'snappy preset produces calibrated organic bounce (~1.2% peak overshoot)',
      () {
        final spec = OrionSpringSpec.snappy;
        expect(spec.stiffness, 380.0);
        expect(spec.dampingRatio, 0.36);

        // Analytic overshoot ratio = exp(-pi * zeta / sqrt(1 - zeta^2))
        final zeta = spec.dampingRatio;
        final overshootRatio = math.exp(
          -math.pi * zeta / math.sqrt(1 - zeta * zeta),
        );
        // For a 0.04 scale travel (0.96 -> 1.0), overshoot is 0.04 * ratio
        final scaleOvershoot = 0.04 * overshootRatio;

        expect(scaleOvershoot, closeTo(0.0119, 0.002)); // ~1.2% visible bounce
      },
    );

    test('presets have expected physical parameters', () {
      expect(OrionSpringSpec.snappy.stiffness, 380.0);
      expect(OrionSpringSpec.snappy.dampingRatio, 0.36);

      expect(OrionSpringSpec.gentle.stiffness, 260.0);
      expect(OrionSpringSpec.gentle.dampingRatio, 0.72);

      expect(OrionSpringSpec.immediate.stiffness, 500.0);
      expect(OrionSpringSpec.immediate.dampingRatio, 0.85);
    });

    test('equality and hashCode are value-based', () {
      const spec1 = OrionSpringSpec(
        mass: 1.0,
        stiffness: 380.0,
        dampingRatio: 0.36,
      );
      const spec2 = OrionSpringSpec(
        mass: 1.0,
        stiffness: 380.0,
        dampingRatio: 0.36,
      );
      const spec3 = OrionSpringSpec(
        mass: 1.0,
        stiffness: 300.0,
        dampingRatio: 0.36,
      );

      expect(spec1, equals(spec2));
      expect(spec1.hashCode, equals(spec2.hashCode));
      expect(spec1, isNot(equals(spec3)));
    });
  });
}
