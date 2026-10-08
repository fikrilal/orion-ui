import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpBadge(WidgetTester tester, Widget badge, {ThemeData? theme}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(body: Center(child: badge)),
    ),
  );
}

DecoratedBox _badgeDecoration(WidgetTester tester) {
  return tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(OrionBadge),
          matching: find.byType(DecoratedBox),
        )
        .first,
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

double _badgeScale(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byType(OrionBadge),
          matching: find.byType(Transform),
        )
        .first,
  );
  return transform.transform.getMaxScaleOnAxis();
}

void main() {
  group('OrionBadge', () {
    testWidgets('renders a pill with ambient labelSmall typography', (
      tester,
    ) async {
      await _pumpBadge(tester, const OrionBadge(child: Text('New')));

      expect(find.text('New'), findsOneWidget);

      final ThemeData theme = Theme.of(tester.element(find.byType(OrionBadge)));
      final BoxDecoration decoration =
          _badgeDecoration(tester).decoration as BoxDecoration;
      expect(decoration.color, theme.colorScheme.surfaceContainerHighest);
      expect(
        decoration.borderRadius,
        BorderRadius.circular(OrionRadii.radiusPill),
      );
      expect(decoration.border, isNull);
      expect(
        _badgeTextStyle(tester).style,
        theme.textTheme.labelSmall!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
    });

    testWidgets('variants paint the scheme pairs', (tester) async {
      final ThemeData theme = OrionTheme.light();

      await _pumpBadge(
        tester,
        const OrionBadge(
          variant: OrionBadgeVariant.primary,
          child: Text('New'),
        ),
        theme: theme,
      );
      expect(
        (_badgeDecoration(tester).decoration as BoxDecoration).color,
        theme.colorScheme.primary,
      );
      expect(_badgeTextStyle(tester).style.color, theme.colorScheme.onPrimary);

      await _pumpBadge(
        tester,
        const OrionBadge(variant: OrionBadgeVariant.error, child: Text('New')),
        theme: theme,
      );
      expect(
        (_badgeDecoration(tester).decoration as BoxDecoration).color,
        theme.colorScheme.error,
      );
      expect(_badgeTextStyle(tester).style.color, theme.colorScheme.onError);

      await _pumpBadge(
        tester,
        const OrionBadge(
          variant: OrionBadgeVariant.outline,
          child: Text('New'),
        ),
        theme: theme,
      );
      final BoxDecoration outline =
          _badgeDecoration(tester).decoration as BoxDecoration;
      expect(outline.color, theme.colorScheme.surface);
      expect(
        outline.border,
        Border.fromBorderSide(BorderSide(color: theme.colorScheme.outline)),
      );
    });

    testWidgets('the theme extension layers under the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionBadgeTheme(
            defaultStyle: OrionBadgeStyle.from(
              background: const Color(0xFF00AA00),
            ),
            variantStyles: <OrionBadgeVariant, OrionBadgeStyle>{
              OrionBadgeVariant.error: OrionBadgeStyle.from(
                background: const Color(0xFF0000AA),
              ),
            },
          ),
        ],
      );

      await _pumpBadge(
        tester,
        const OrionBadge(variant: OrionBadgeVariant.error, child: Text('New')),
        theme: themed,
      );
      expect(
        (_badgeDecoration(tester).decoration as BoxDecoration).color,
        const Color(0xFF0000AA),
        reason: 'the variant entry beats the default style',
      );

      await _pumpBadge(
        tester,
        OrionBadge(
          variant: OrionBadgeVariant.error,
          style: OrionBadgeStyle.from(background: const Color(0xFFAA0000)),
          child: const Text('New'),
        ),
        theme: themed,
      );
      expect(
        (_badgeDecoration(tester).decoration as BoxDecoration).color,
        const Color(0xFFAA0000),
        reason: 'the instance style beats the theme',
      );
    });

    testWidgets('a zero-width border removes an inherited outline', (
      tester,
    ) async {
      await _pumpBadge(
        tester,
        OrionBadge(
          variant: OrionBadgeVariant.outline,
          style: OrionBadgeStyle.from(border: BorderSide.none),
          child: const Text('New'),
        ),
      );
      expect(
        (_badgeDecoration(tester).decoration as BoxDecoration).border,
        isNull,
      );
    });

    testWidgets('the dot paints a bare circle with no content', (tester) async {
      await _pumpBadge(
        tester,
        const OrionBadge.dot(variant: OrionBadgeVariant.primary),
      );

      expect(
        find.descendant(
          of: find.byType(OrionBadge),
          matching: find.byType(Text),
        ),
        findsNothing,
      );
      final BoxDecoration decoration =
          _badgeDecoration(tester).decoration as BoxDecoration;
      expect(decoration.shape, BoxShape.circle);
      expect(
        decoration.color,
        Theme.of(tester.element(find.byType(OrionBadge))).colorScheme.primary,
      );
      final Size size = tester.getSize(find.byType(OrionBadge));
      expect(size.width, 8);
      expect(size.height, 8);
    });

    testWidgets('the count caps its display but announces the true value', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBadge(
        tester,
        const OrionBadge.count(value: 128, maxCount: 99),
      );

      expect(find.text('99+'), findsOneWidget);
      expect(tester.getSemantics(find.byType(OrionBadge)).label, '128');
      expect(
        _badgeTextStyle(tester).style.fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );

      await _pumpBadge(tester, const OrionBadge.count(value: 12));
      expect(find.text('12'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a count change pops the pill and settles back', (
      tester,
    ) async {
      await _pumpBadge(tester, const OrionBadge.count(value: 3));
      expect(_badgeScale(tester), 1.0);

      await _pumpBadge(tester, const OrionBadge.count(value: 4));
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        _badgeScale(tester),
        greaterThan(1.0),
        reason: 'the pill pops past its rest scale',
      );

      await tester.pumpAndSettle();
      expect(_badgeScale(tester), closeTo(1.0, 0.0001));
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('reduced motion lands a count change in one frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Center(child: OrionBadge.count(value: 3)),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Center(child: OrionBadge.count(value: 400)),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('400'), findsOneWidget);
      expect(_badgeScale(tester), 1.0);
      expect(
        tester.binding.hasScheduledFrame,
        isFalse,
        reason: 'nothing is left animating',
      );
    });

    testWidgets('size changes padding and type', (tester) async {
      await _pumpBadge(
        tester,
        const OrionBadge(size: OrionBadgeSize.small, child: Text('New')),
      );
      expect(
        tester.getRect(find.text('New')).left -
            tester.getRect(find.byType(OrionBadge)).left,
        OrionSpacing.space4,
      );

      await _pumpBadge(
        tester,
        const OrionBadge(size: OrionBadgeSize.large, child: Text('New')),
      );
      await tester.pumpAndSettle();
      final ThemeData theme = Theme.of(tester.element(find.byType(OrionBadge)));
      expect(
        _badgeTextStyle(tester).style,
        theme.textTheme.labelMedium!.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
      final Rect badge = tester.getRect(find.byType(OrionBadge));
      final Rect label = tester.getRect(find.text('New'));
      expect(label.left - badge.left, OrionSpacing.space12);
      expect(label.top - badge.top, OrionSpacing.space8);
    });

    testWidgets('uses the token padding scale', (tester) async {
      await _pumpBadge(tester, const OrionBadge(child: Text('New')));

      final Rect badge = tester.getRect(find.byType(OrionBadge));
      final Rect label = tester.getRect(find.text('New'));
      expect(label.left - badge.left, OrionSpacing.space8);
      expect(label.top - badge.top, OrionSpacing.space4);
    });
  });

  group('OrionBadgeStyle', () {
    test('a merge only changes the fields it names', () {
      const OrionBadgeStyle base = OrionBadgeStyle(
        background: Color(0xFF111111),
        foreground: Color(0xFF222222),
        dotSize: 8,
      );
      final OrionBadgeStyle merged = base.merge(
        OrionBadgeStyle.from(background: const Color(0xFF333333)),
      );

      expect(merged.background, const Color(0xFF333333));
      expect(merged.foreground, const Color(0xFF222222));
      expect(merged.dotSize, 8);
    });
  });
}
