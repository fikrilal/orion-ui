import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

@immutable
class _MarkerExtension extends ThemeExtension<_MarkerExtension> {
  const _MarkerExtension(this.value);

  final int value;

  @override
  _MarkerExtension copyWith({int? value}) =>
      _MarkerExtension(value ?? this.value);

  @override
  _MarkerExtension lerp(ThemeExtension<_MarkerExtension>? other, double t) =>
      this;

  @override
  bool operator ==(Object other) =>
      other is _MarkerExtension && other.value == value;

  @override
  int get hashCode => value.hashCode;
}

void main() {
  group('OrionTheme', () {
    testWidgets('of returns the fallback when nothing is registered', (
      tester,
    ) async {
      late OrionThemeData resolved;
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              resolved = OrionTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, OrionThemeData.fallback);
    });

    testWidgets('maybeOf returns null when nothing is registered', (
      tester,
    ) async {
      OrionThemeData? absent;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              absent = OrionTheme.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(absent, isNull);
    });

    testWidgets('maybeOf returns registered data', (tester) async {
      const custom = OrionThemeData(pressScale: 0.9);
      OrionThemeData? present;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.apply(ThemeData(), data: custom),
          home: Builder(
            builder: (context) {
              present = OrionTheme.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(present, custom);
    });

    testWidgets('context.orion resolves the registered tokens', (tester) async {
      const custom = OrionThemeData(pressScale: 0.88);
      late OrionThemeData resolved;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.apply(ThemeData(), data: custom),
          home: Builder(
            builder: (context) {
              resolved = context.orion;
              return const SizedBox.shrink();
            },
          ),
        ),
      );

      expect(resolved, custom);
    });

    test('apply preserves other extensions and replaces Orion data', () {
      final base = ThemeData().copyWith(
        extensions: const [
          _MarkerExtension(7),
          OrionThemeData(pressScale: 0.5),
        ],
      );

      final applied = OrionTheme.apply(
        base,
        data: const OrionThemeData(pressScale: 0.8),
      );

      expect(applied.extension<_MarkerExtension>()?.value, 7);
      expect(applied.extension<OrionThemeData>()?.pressScale, 0.8);
      expect(applied.extensions.values.whereType<OrionThemeData>().length, 1);
    });

    test('apply without data preserves an existing Orion theme', () {
      const custom = OrionThemeData(pressScale: 0.7);

      final reapplied = OrionTheme.apply(
        OrionTheme.apply(ThemeData(), data: custom),
      );

      expect(reapplied.extension<OrionThemeData>(), custom);
      expect(reapplied.extensions.values.whereType<OrionThemeData>().length, 1);
    });

    test('apply without data installs the fallback when none exists', () {
      final applied = OrionTheme.apply(ThemeData());

      expect(applied.extension<OrionThemeData>(), OrionThemeData.fallback);
    });

    test('light and dark build resolvable default themes', () {
      final light = OrionTheme.light();
      final dark = OrionTheme.dark();

      expect(light.brightness, Brightness.light);
      expect(dark.brightness, Brightness.dark);
      expect(light.extension<OrionThemeData>(), OrionThemeData.fallback);
      expect(dark.extension<OrionThemeData>(), OrionThemeData.fallback);
      expect(light.colorScheme.brightness, Brightness.light);
      expect(dark.colorScheme.brightness, Brightness.dark);
    });
  });
}
