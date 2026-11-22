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
      'snappy preset produces a tight, crisp response (~2% travel overshoot)',
      () {
        final spec = OrionSpringSpec.snappy;
        expect(spec.stiffness, 600.0);
        expect(spec.dampingRatio, 0.78);

        // Analytic overshoot ratio = exp(-pi * zeta / sqrt(1 - zeta^2))
        final zeta = spec.dampingRatio;
        final overshootRatio = math.exp(
          -math.pi * zeta / math.sqrt(1 - zeta * zeta),
        );
        expect(overshootRatio, closeTo(0.02, 0.005));
      },
    );

    test('presets have expected physical parameters', () {
      expect(OrionSpringSpec.snappy.stiffness, 600.0);
      expect(OrionSpringSpec.snappy.dampingRatio, 0.78);

      expect(OrionSpringSpec.gentle.stiffness, 260.0);
      // Recalibrated into the band production references use for travel.
      expect(OrionSpringSpec.gentle.dampingRatio, 0.8);

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
