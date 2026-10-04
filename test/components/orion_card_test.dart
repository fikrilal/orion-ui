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
  });
}
