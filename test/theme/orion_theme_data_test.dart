import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionThemeData', () {
    test('fallback exposes the documented defaults', () {
      const data = OrionThemeData.fallback;

      expect(data.pressScale, 0.96);
      expect(data.pressSpring, OrionSpringSpec.snappy);
      expect(data.releaseSpring, OrionSpringSpec.snappy);
      expect(data.tapHaptic, OrionHapticType.selectionClick);
      expect(data.longPressHaptic, OrionHapticType.mediumImpact);
      expect(data.controlRadius, OrionRadii.radius12);
      expect(data.surfaceRadius, OrionRadii.radius24);
      expect(data.blurSigma, 12.0);
      expect(data.shadow, isNotEmpty);
    });

    test('copyWith replaces only the provided fields', () {
      const base = OrionThemeData.fallback;
      final copy = base.copyWith(pressScale: 0.9, blurSigma: 20.0);

      expect(copy.pressScale, 0.9);
      expect(copy.blurSigma, 20.0);
      expect(copy.controlRadius, base.controlRadius);
      expect(copy.surfaceRadius, base.surfaceRadius);
      expect(copy.shadow, base.shadow);
      expect(copy.pressSpring, base.pressSpring);
    });

    test('lerp endpoints match the inputs and interpolates numerically', () {
      const a = OrionThemeData.fallback;
      final b = a.copyWith(
        pressScale: 0.8,
        blurSigma: 4.0,
        shadow: const [
          BoxShadow(color: Color(0xFF000000), blurRadius: 4.0),
          BoxShadow(color: Color(0x33000000), blurRadius: 1.0),
        ],
      );

      expect(a.lerp(b, 0.0), a);
      expect(a.lerp(b, 1.0), b);

      final mid = a.lerp(b, 0.5);
      expect(mid.pressScale, closeTo(0.88, 1e-9));
      expect(mid.blurSigma, closeTo(8.0, 1e-9));
      expect(a.lerp(b, 0.49).pressSpring, a.pressSpring);
      expect(a.lerp(b, 0.5).pressSpring, b.pressSpring);
    });

    test('lerp scales away shadows beyond the shorter list', () {
      const a = OrionThemeData.fallback; // two shadows
      final b = a.copyWith(
        shadow: const [BoxShadow(color: Color(0xFF000000), blurRadius: 4.0)],
      );

      final mid = a.lerp(b, 0.5);
      expect(mid.shadow, hasLength(2));
      expect(mid.shadow.first.blurRadius, closeTo(8.0, 1e-9));
      expect(mid.shadow.last.blurRadius, closeTo(1.0, 1e-9));
    });

    test('equality and hashCode are value-based', () {
      const a = OrionThemeData.fallback;
      const b = OrionThemeData.fallback;

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(a.copyWith(pressScale: 0.9))));
    });

    test('asserts guard invalid token values', () {
      expect(
        () => OrionThemeData(pressScale: 0.0),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => OrionThemeData(blurSigma: -1.0),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
