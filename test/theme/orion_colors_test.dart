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

void _expectAaPairs(ColorScheme scheme) {
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
  expect(
    _contrastRatio(scheme.outline, scheme.surface),
    greaterThanOrEqualTo(3.0),
    reason: 'boundaries must meet the 3:1 non-text contrast rule',
  );
}

void main() {
  group('OrionColors', () {
    test('light scheme meets WCAG AA for exposed role pairs', () {
      _expectAaPairs(OrionColors.lightScheme);
    });

    test('dark scheme meets WCAG AA for exposed role pairs', () {
      _expectAaPairs(OrionColors.darkScheme);
    });

    test('schemes are derived per brightness from the neutral seed', () {
      expect(OrionColors.lightScheme.brightness, Brightness.light);
      expect(OrionColors.darkScheme.brightness, Brightness.dark);
      expect(
        OrionColors.lightScheme.surface,
        isNot(OrionColors.darkScheme.surface),
      );
    });
  });
}
