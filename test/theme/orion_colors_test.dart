import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

double _contrastRatio(Color a, Color b) {
  final luminanceA = a.computeLuminance();
  final luminanceB = b.computeLuminance();
  final lighter = luminanceA > luminanceB ? luminanceA : luminanceB;
  final darker = luminanceA > luminanceB ? luminanceB : luminanceA;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectTextAa(ColorScheme scheme) {
  expect(
    _contrastRatio(scheme.onSurface, scheme.surface),
    greaterThanOrEqualTo(4.5),
    reason: 'body text on surface must meet WCAG AA',
  );
  expect(
    _contrastRatio(scheme.onPrimary, scheme.primary),
    greaterThanOrEqualTo(4.5),
    reason: 'text on brand fills must meet WCAG AA',
  );
}

void main() {
  group('OrionColors', () {
    test('light scheme uses the shadcn neutral tokens and keeps text AA', () {
      final ColorScheme scheme = OrionColors.lightScheme;

      expect(scheme.brightness, Brightness.light);
      expect(scheme.surface, const Color(0xFFFFFFFF));
      expect(scheme.onSurface, const Color(0xFF0A0A0A));
      expect(scheme.primary, const Color(0xFF171717));
      expect(scheme.onPrimary, const Color(0xFFFAFAFA));
      expect(scheme.secondary, const Color(0xFFF5F5F5));
      expect(scheme.onSurfaceVariant, const Color(0xFF737373));
      expect(scheme.outline, const Color(0xFFE5E5E5));
      expect(scheme.error, const Color(0xFFE7000B));
      _expectTextAa(scheme);
    });

    test('dark scheme uses the shadcn neutral tokens and keeps text AA', () {
      final ColorScheme scheme = OrionColors.darkScheme;

      expect(scheme.brightness, Brightness.dark);
      expect(scheme.surface, const Color(0xFF0A0A0A));
      expect(scheme.onSurface, const Color(0xFFFAFAFA));
      expect(scheme.surfaceContainer, const Color(0xFF171717));
      expect(scheme.surfaceContainerHighest, const Color(0xFF262626));
      expect(scheme.onSurfaceVariant, const Color(0xFFA1A1A1));
      expect(scheme.primary, const Color(0xFFE5E5E5));
      expect(scheme.onPrimary, const Color(0xFF171717));
      expect(scheme.secondary, const Color(0xFF262626));
      expect(scheme.error, const Color(0xFFFF6467));
      expect(scheme.outline, const Color(0x26FFFFFF));
      expect(scheme.outlineVariant, const Color(0x1AFFFFFF));
      _expectTextAa(scheme);
    });

    test('light and dark surfaces differ', () {
      expect(
        OrionColors.lightScheme.surface,
        isNot(OrionColors.darkScheme.surface),
      );
    });
  });
}
