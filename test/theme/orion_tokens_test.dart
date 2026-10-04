import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionSpacing', () {
    test('sits on the 4 pt grid and ascends', () {
      const steps = <double>[
        OrionSpacing.space4,
        OrionSpacing.space8,
        OrionSpacing.space12,
        OrionSpacing.space16,
        OrionSpacing.space20,
        OrionSpacing.space24,
        OrionSpacing.space32,
        OrionSpacing.space40,
        OrionSpacing.space48,
      ];

      for (final step in steps) {
        expect(step % 4, 0);
      }
      for (var i = 1; i < steps.length; i++) {
        expect(steps[i], greaterThan(steps[i - 1]));
      }
    });
  });

  group('OrionRadii', () {
    test('mirrors the host application radius scale', () {
      expect(OrionRadii.radius4, 4.0);
      expect(OrionRadii.radius8, 8.0);
      expect(OrionRadii.radius12, 12.0);
      expect(OrionRadii.radius24, 24.0);
      expect(OrionRadii.radiusPill, 999.0);
    });
  });

  group('OrionSizing', () {
    test('mirrors host control and icon sizes', () {
      expect(OrionSizing.controlHeightSmall, 32.0);
      expect(OrionSizing.controlHeightMedium, 40.0);
      expect(OrionSizing.controlHeightLarge, 48.0);
      expect(OrionSizing.iconSmall, 16.0);
      expect(OrionSizing.iconMedium, 24.0);
      expect(OrionSizing.iconLarge, 32.0);
    });

    test('keeps the 44 pt minimum hit target', () {
      expect(OrionSizing.minHitTarget, 44.0);
    });
  });
}
