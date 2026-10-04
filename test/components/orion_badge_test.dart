import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpBadge(WidgetTester tester, OrionBadge badge) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: badge)),
    ),
  );
}

DecoratedBox _badgeDecoration(WidgetTester tester) {
  return tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(OrionBadge),
      matching: find.byType(DecoratedBox),
    ),
  );
}

DefaultTextStyle _badgeTextStyle(WidgetTester tester) {
  return tester.widget<DefaultTextStyle>(
    find.descendant(
      of: find.byType(OrionBadge),
      matching: find.byType(DefaultTextStyle),
    ),
  );
}

void main() {
  group('OrionBadge', () {
    testWidgets('renders a pill with ambient labelSmall typography', (
      tester,
    ) async {
      await _pumpBadge(tester, const OrionBadge(child: Text('New')));

      expect(find.text('New'), findsOneWidget);

      final BoxDecoration decoration =
          _badgeDecoration(tester).decoration as BoxDecoration;
      expect(
        decoration.borderRadius,
        BorderRadius.circular(OrionRadii.radiusPill),
      );

      final ThemeData theme = Theme.of(tester.element(find.byType(OrionBadge)));
      expect(
        _badgeTextStyle(tester).style,
        theme.textTheme.labelSmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    });

    testWidgets('honors color overrides', (tester) async {
      await _pumpBadge(
        tester,
        const OrionBadge(
          backgroundColor: Color(0xFF123456),
          foregroundColor: Color(0xFFABCDEF),
          child: Text('New'),
        ),
      );

      final BoxDecoration decoration =
          _badgeDecoration(tester).decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFF123456));
      expect(_badgeTextStyle(tester).style.color, const Color(0xFFABCDEF));
    });

    testWidgets('uses the token padding scale', (tester) async {
      await _pumpBadge(tester, const OrionBadge(child: Text('New')));

      final Rect badge = tester.getRect(find.byType(OrionBadge));
      final Rect label = tester.getRect(find.text('New'));
      expect(label.left - badge.left, OrionSpacing.space8);
      expect(label.top - badge.top, OrionSpacing.space4);
    });
  });
}
