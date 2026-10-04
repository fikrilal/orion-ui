import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpButton(WidgetTester tester, OrionButton button) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  group('OrionButton', () {
    testWidgets('invokes a synchronous action on tap', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('locks while an async action is in flight', (tester) async {
      var calls = 0;
      final completer = Completer<void>();
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {
            calls++;
            return completer.future;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      expect(calls, 1);

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      expect(calls, 1, reason: 'presses while pending are ignored');

      completer.complete();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();
      expect(calls, 2, reason: 'the lock releases after completion');
    });

    testWidgets('shows a progress indicator while pending without resizing', (
      tester,
    ) async {
      final completer = Completer<void>();
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () => completer.future,
          leading: const Icon(Icons.add),
          child: const Text('Save'),
        ),
      );

      final Size before = tester.getSize(find.byType(OrionButton));

      await tester.tap(find.byType(OrionButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(OrionButton)), before);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('leading and trailing icons use the button foreground', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {},
          leading: const Icon(Icons.download),
          trailing: const Icon(Icons.arrow_forward),
          child: const Text('Save'),
        ),
      );

      final Color foreground = OrionButtonStyle.resolve(
        variant: OrionButtonVariant.solid,
        size: OrionButtonSize.medium,
        scheme: Theme.of(tester.element(find.byType(OrionButton))).colorScheme,
        theme: OrionTheme.of(tester.element(find.byType(OrionButton))),
        textTheme: Theme.of(tester.element(find.byType(OrionButton))).textTheme,
        enabled: true,
        focused: false,
      ).foreground;

      for (final icon in [Icons.download, Icons.arrow_forward]) {
        expect(
          IconTheme.of(tester.element(find.byIcon(icon))).color,
          foreground,
        );
      }
    });

    testWidgets('isLoading shows a spinner and ignores taps', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          isLoading: true,
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('isExpanded fills a bounded width and stays safe in a row', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: OrionButton(
                  isExpanded: true,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(OrionButton),
                matching: find.byType(DecoratedBox),
              ),
            )
            .width,
        320,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                OrionButton(
                  isExpanded: true,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(OrionButton),
                matching: find.byType(DecoratedBox),
              ),
            )
            .width,
        lessThan(320),
      );
    });

    testWidgets('debounce suppresses presses inside the double-tap window', (
      tester,
    ) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          debounce: true,
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('without debounce both quick presses run', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      expect(calls, 2);
    });

    testWidgets('disabled button ignores taps and reports disabled semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpButton(tester, const OrionButton(child: Text('Save')));

      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionPressable),
      );
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('keeps a 44 pt hit target for every size', (tester) async {
      for (final OrionButtonSize size in OrionButtonSize.values) {
        await _pumpButton(
          tester,
          OrionButton(size: size, onPressed: () {}, child: const Text('Hi')),
        );

        final Rect rect = tester.getRect(find.byType(OrionButton));
        expect(rect.height, greaterThanOrEqualTo(OrionSizing.minHitTarget));
        expect(rect.width, greaterThanOrEqualTo(OrionSizing.minHitTarget));
      }
    });

    testWidgets('activates with Enter and Space when focused', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          autofocus: true,
          onPressed: () {
            calls++;
          },
          child: const Text('Go'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Focus.of(tester.element(find.byType(OrionPressable))).hasFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(calls, 2);
    });

    testWidgets('builds every variant with its label', (tester) async {
      for (final OrionButtonVariant variant in OrionButtonVariant.values) {
        await _pumpButton(
          tester,
          OrionButton(
            variant: variant,
            onPressed: () {},
            child: const Text('V'),
          ),
        );

        expect(find.text('V'), findsOneWidget);
      }
    });
  });

  group('OrionButtonStyle', () {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
    );
    final TextTheme textTheme = ThemeData().textTheme;
    const OrionThemeData orion = OrionThemeData.fallback;

    OrionButtonStyle resolve(
      OrionButtonVariant variant, {
      bool enabled = true,
      bool focused = false,
      OrionButtonSize size = OrionButtonSize.medium,
    }) {
      return OrionButtonStyle.resolve(
        variant: variant,
        size: size,
        scheme: scheme,
        theme: orion,
        textTheme: textTheme,
        enabled: enabled,
        focused: focused,
      );
    }

    test('solid fills with primary and onPrimary', () {
      final OrionButtonStyle style = resolve(OrionButtonVariant.solid);
      expect(style.background, scheme.primary);
      expect(style.foreground, scheme.onPrimary);
      expect(style.border, isNull);
    });

    test('bordered stays transparent with an outline border', () {
      final OrionButtonStyle style = resolve(OrionButtonVariant.bordered);
      expect(style.background, isNull);
      expect(style.border?.color, scheme.outline);
    });

    test('glow adds a primary-tinted shadow', () {
      final OrionButtonStyle style = resolve(OrionButtonVariant.glow);
      expect(style.background, scheme.primary);
      expect(style.shadow, isNotEmpty);
    });

    test('flat has no background or border', () {
      final OrionButtonStyle style = resolve(OrionButtonVariant.flat);
      expect(style.background, isNull);
      expect(style.border, isNull);
    });

    test('sizes map to control heights and text styles', () {
      expect(
        resolve(OrionButtonVariant.solid, size: OrionButtonSize.small).height,
        OrionSizing.controlHeightSmall,
      );
      expect(
        resolve(OrionButtonVariant.solid, size: OrionButtonSize.medium).height,
        OrionSizing.controlHeightMedium,
      );
      expect(
        resolve(OrionButtonVariant.solid, size: OrionButtonSize.large).height,
        OrionSizing.controlHeightLarge,
      );
      expect(
        resolve(OrionButtonVariant.flat, size: OrionButtonSize.small).textStyle,
        textTheme.labelMedium,
      );
      expect(
        resolve(OrionButtonVariant.flat, size: OrionButtonSize.large).textStyle,
        textTheme.titleMedium,
      );
    });

    test('disabled uses Material disabled opacities', () {
      final OrionButtonStyle style = resolve(
        OrionButtonVariant.solid,
        enabled: false,
      );
      expect(style.background, scheme.onSurface.withValues(alpha: 0.12));
      expect(style.foreground, scheme.onSurface.withValues(alpha: 0.38));
    });

    test('focus adds a 2 pt ring for every variant', () {
      for (final OrionButtonVariant variant in OrionButtonVariant.values) {
        final OrionButtonStyle style = resolve(variant, focused: true);
        expect(style.border?.width, 2.0, reason: variant.name);
      }
    });

    test('focus is ignored while disabled', () {
      final OrionButtonStyle enabled = resolve(OrionButtonVariant.bordered);
      final OrionButtonStyle disabled = resolve(
        OrionButtonVariant.bordered,
        enabled: false,
        focused: true,
      );
      expect(disabled.border?.width, enabled.border?.width);
    });
  });
}
