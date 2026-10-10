import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpCard(WidgetTester tester, OrionCard card) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: card)),
    ),
  );
}

void main() {
  group('OrionCard', () {
    testWidgets('plain card is a muted panel without a border or shadow', (
      tester,
    ) async {
      await _pumpCard(tester, const OrionCard(child: Text('Card')));

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(OrionCard),
          matching: find.byType(DecoratedBox),
        ),
      );
      final BoxDecoration decoration = box.decoration as BoxDecoration;
      final ColorScheme scheme = Theme.of(
        tester.element(find.byType(OrionCard)),
      ).colorScheme;

      expect(decoration.color, isNull);
      expect(decoration.border, const Border.fromBorderSide(BorderSide.none));
      expect(decoration.boxShadow, isEmpty);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(OrionRadii.radius16),
      );

      final ColoredBox fill = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(OrionCard),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(fill.color, scheme.secondary);
    });

    testWidgets('renders its child without a backdrop filter', (tester) async {
      await _pumpCard(tester, const OrionCard(child: Text('Card')));

      expect(find.text('Card'), findsOneWidget);
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('frosted card clips a static backdrop', (tester) async {
      await _pumpCard(
        tester,
        const OrionCard(frosted: true, child: Text('Card')),
      );

      expect(
        find.descendant(
          of: find.byType(ClipRRect),
          matching: find.byType(BackdropFilter),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(OrionPressable),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
      );
    });

    testWidgets('interactive card fires onTap and keeps the blur static', (
      tester,
    ) async {
      var taps = 0;
      await _pumpCard(
        tester,
        OrionCard(
          frosted: true,
          onTap: () {
            taps++;
          },
          child: const Text('Card'),
        ),
      );

      expect(find.byType(OrionPressable), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OrionPressable),
          matching: find.byType(BackdropFilter),
        ),
        findsNothing,
        reason: 'the frosted backdrop must stay outside the transform path',
      );

      await tester.tap(find.byType(OrionCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });

    testWidgets('applies default padding from the token scale', (tester) async {
      await _pumpCard(tester, const OrionCard(child: Text('Card')));

      final Rect card = tester.getRect(find.byType(OrionCard));
      final Rect label = tester.getRect(find.text('Card'));
      expect(label.left - card.left, OrionSpacing.space16);
      expect(label.top - card.top, OrionSpacing.space16);
    });

    testWidgets('honors padding and radius overrides', (tester) async {
      await _pumpCard(
        tester,
        const OrionCard(
          padding: EdgeInsets.all(24.0),
          radius: 4.0,
          child: Text('Card'),
        ),
      );

      final Rect card = tester.getRect(find.byType(OrionCard));
      final Rect label = tester.getRect(find.text('Card'));
      expect(label.left - card.left, 24.0);
      expect(label.top - card.top, 24.0);

      final ClipRRect clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(OrionCard),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clip.borderRadius, BorderRadius.circular(4.0));
    });

    testWidgets('non-interactive card has no pressable', (tester) async {
      await _pumpCard(tester, const OrionCard(child: Text('Card')));
      expect(find.byType(OrionPressable), findsNothing);
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionCardTheme(
            defaultStyle: OrionCardStyle.from(
              background: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      Future<void> pump(OrionCard card) => tester.pumpWidget(
        MaterialApp(
          theme: themed,
          home: Scaffold(body: Center(child: card)),
        ),
      );

      await pump(const OrionCard(child: Text('Card')));
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(OrionCard),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        const Color(0xFF00AA00),
      );

      await pump(
        const OrionCard(
          style: OrionCardStyle(background: Color(0xFFAA0000)),
          child: Text('Card'),
        ),
      );
      expect(
        tester
            .widget<ColoredBox>(
              find.descendant(
                of: find.byType(OrionCard),
                matching: find.byType(ColoredBox),
              ),
            )
            .color,
        const Color(0xFFAA0000),
      );
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('the padding and radius params win over the instance style', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        const OrionCard(
          padding: EdgeInsets.all(24.0),
          radius: 4.0,
          style: OrionCardStyle(
            padding: EdgeInsets.all(8.0),
            radius: BorderRadius.all(Radius.circular(20)),
          ),
          child: Text('Card'),
        ),
      );

      final Rect card = tester.getRect(find.byType(OrionCard));
      final Rect label = tester.getRect(find.text('Card'));
      expect(label.left - card.left, 24.0);
      expect(label.top - card.top, 24.0);

      final ClipRRect clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(OrionCard),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clip.borderRadius, BorderRadius.circular(4.0));
    });

    testWidgets('a custom blur sigma paints a static clipped backdrop', (
      tester,
    ) async {
      await _pumpCard(
        tester,
        const OrionCard(
          style: OrionCardStyle(blurSigma: 6),
          child: Text('Card'),
        ),
      );

      final BackdropFilter filter = tester.widget<BackdropFilter>(
        find.descendant(
          of: find.byType(ClipRRect),
          matching: find.byType(BackdropFilter),
        ),
      );
      expect(filter.filter, ImageFilter.blur(sigmaX: 6, sigmaY: 6));
    });

    testWidgets('custom press physics reach the pressable', (tester) async {
      var taps = 0;
      await _pumpCard(
        tester,
        OrionCard(
          style: const OrionCardStyle(pressScale: 0.9),
          onTap: () => taps++,
          child: const Text('Card'),
        ),
      );

      expect(
        tester.widget<OrionPressable>(find.byType(OrionPressable)).pressedScale,
        0.9,
      );
      await tester.tap(find.byType(OrionCard));
      await tester.pumpAndSettle();
      expect(taps, 1);
    });
  });

  group('OrionCardStyle', () {
    test('a merge only changes the fields it names', () {
      final OrionCardStyle base = OrionCardStyle.from(
        background: const Color(0xFF111111),
        blurSigma: 8,
      );
      final OrionCardStyle merged = base.merge(
        OrionCardStyle.from(background: const Color(0xFF333333)),
      );

      expect(merged.background, const Color(0xFF333333));
      expect(merged.blurSigma, 8);
    });

    test('presets resolve both faces from the tokens', () {
      final OrionCardStyle opaque = OrionCardPresets.resolve(
        scheme: OrionColors.lightScheme,
        frosted: false,
        blurSigma: 12,
      );
      expect(opaque.background, OrionColors.lightScheme.secondary);
      expect(opaque.border, BorderSide.none);
      expect(opaque.radius, BorderRadius.circular(OrionRadii.radius16));
      expect(opaque.padding, const EdgeInsets.all(OrionSpacing.space16));
      expect(opaque.shadow, isEmpty);
      expect(opaque.blurSigma, isNull);

      final OrionCardStyle frosted = OrionCardPresets.resolve(
        scheme: OrionColors.lightScheme,
        frosted: true,
        blurSigma: 12,
      );
      expect(
        frosted.background,
        OrionColors.lightScheme.surface.withValues(alpha: 0.72),
      );
      expect(frosted.blurSigma, 12);
    });
  });
}
