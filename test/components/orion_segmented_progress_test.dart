import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  required int count,
  required double value,
  bool disableAnimations = false,
  double width = 300,
  OrionProgressStyle? style,
  ThemeData? theme,
}) {
  final Widget bar = SizedBox(
    width: width,
    child: OrionSegmentedProgress(count: count, value: value, style: style),
  );
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: disableAnimations
              ? MediaQuery(
                  data: const MediaQueryData(disableAnimations: true),
                  child: bar,
                )
              : bar,
        ),
      ),
    ),
  );
}

List<double> _scales(WidgetTester tester) {
  return tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(OrionSegmentedProgress),
          matching: find.byType(Transform),
        ),
      )
      .map((Transform transform) => transform.transform.entry(0, 0))
      .toList();
}

List<Color> _fillColors(WidgetTester tester) {
  return tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(OrionSegmentedProgress),
          matching: find.byType(Transform),
        ),
      )
      .map(
        (Transform transform) =>
            ((transform.child! as DecoratedBox).decoration as BoxDecoration)
                .color!,
      )
      .toList();
}

void main() {
  group('OrionSegmentedProgress', () {
    testWidgets('fills whole segments up to the value', (tester) async {
      await _pumpBar(tester, count: 4, value: 2);

      expect(_scales(tester), <double>[1, 1, 0, 0]);
    });

    testWidgets('fills the next segment by the fraction', (tester) async {
      await _pumpBar(tester, count: 4, value: 1.5);

      final List<double> scales = _scales(tester);
      expect(scales[0], 1);
      expect(scales[1], closeTo(0.5, 0.01));
      expect(scales[2], 0);
      expect(scales[3], 0);
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      await _pumpBar(tester, count: 4, value: 0, disableAnimations: true);
      expect(_scales(tester), <double>[0, 0, 0, 0]);

      await _pumpBar(tester, count: 4, value: 2, disableAnimations: true);
      await tester.pump();

      expect(_scales(tester), <double>[1, 1, 0, 0]);
    });

    testWidgets('slides the fill instead of jumping', (tester) async {
      await _pumpBar(tester, count: 4, value: 0);
      await _pumpBar(tester, count: 4, value: 2);
      await tester.pump(const Duration(milliseconds: 16));

      final List<double> scales = _scales(tester);
      final double filled = scales.fold<double>(0, (sum, scale) => sum + scale);
      expect(filled, greaterThan(0.05));
      expect(filled, lessThan(2));
      await tester.pumpAndSettle();
    });

    testWidgets('does not pull the fill back on the way to a step', (
      tester,
    ) async {
      await _pumpBar(tester, count: 4, value: 0);
      await _pumpBar(tester, count: 4, value: 1);

      double previous = 0.0;
      for (int frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double filled = _scales(
          tester,
        ).fold<double>(0, (double sum, double scale) => sum + scale);
        expect(filled, greaterThanOrEqualTo(previous));
        expect(filled, lessThanOrEqualTo(1));
        previous = filled;
        if (filled == 1) {
          break;
        }
      }
      expect(previous, 1);
    });

    testWidgets('does not light the next segment while stepping back', (
      tester,
    ) async {
      await _pumpBar(tester, count: 4, value: 2);
      await tester.pumpAndSettle();
      await _pumpBar(tester, count: 4, value: 1);

      double previous = 2.0;
      for (int frame = 0; frame < 60; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final List<double> scales = _scales(tester);
        expect(scales[2], 0);
        expect(scales[3], 0);
        final double filled = scales.fold<double>(
          0,
          (double sum, double scale) => sum + scale,
        );
        expect(filled, lessThanOrEqualTo(previous));
        expect(filled, greaterThanOrEqualTo(1));
        previous = filled;
        if (filled == 1) {
          break;
        }
      }
      expect(previous, 1);
    });

    testWidgets('keeps a straight leading edge', (tester) async {
      await _pumpBar(tester, count: 4, value: 1.5);

      final Iterable<DecoratedBox> fills = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(OrionSegmentedProgress),
              matching: find.byType(Transform),
            ),
          )
          .map((Transform transform) => transform.child)
          .whereType<DecoratedBox>();

      expect(fills, isNotEmpty);
      for (final DecoratedBox fill in fills) {
        expect((fill.decoration as BoxDecoration).borderRadius, isNull);
      }
    });

    testWidgets('rejects a count below 1', (tester) async {
      await _pumpBar(tester, count: 0, value: 0);
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('rejects a value outside 0 through count', (tester) async {
      await _pumpBar(tester, count: 3, value: 4);
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('rejects an unbounded width', (tester) async {
      final List<Object> errors = <Object>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details.exception);
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: const <Widget>[
              OrionSegmentedProgress(count: 3, value: 1),
            ],
          ),
        ),
      );
      FlutterError.onError = previous;
      expect(errors.whereType<AssertionError>(), isNotEmpty);
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionProgressTheme(
            defaultStyle: OrionProgressStyle.from(
              fillColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpBar(tester, count: 2, value: 1, theme: themed);
      expect(_fillColors(tester), <Color>[
        const Color(0xFF00AA00),
        const Color(0xFF00AA00),
      ]);

      await _pumpBar(
        tester,
        count: 2,
        value: 1,
        theme: themed,
        style: OrionProgressStyle.from(fillColor: const Color(0xFFAA0000)),
      );
      expect(_fillColors(tester), <Color>[
        const Color(0xFFAA0000),
        const Color(0xFFAA0000),
      ]);
    });

    testWidgets('a style retunes the height and the gap', (tester) async {
      await _pumpBar(
        tester,
        count: 3,
        value: 1,
        style: OrionProgressStyle.from(height: 16, gap: 12),
      );

      expect(tester.getSize(find.byType(OrionSegmentedProgress)).height, 16);

      final Finder clips = find.descendant(
        of: find.byType(OrionSegmentedProgress),
        matching: find.byType(ClipRRect),
      );
      expect(clips, findsNWidgets(3));
      expect(
        tester.getRect(clips.at(1)).left - tester.getRect(clips.at(0)).right,
        12,
      );
    });

    testWidgets(
      'clamps gap cleanly on narrow widths, formats clean float semantics, and supports tones',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 120,
                  child: OrionSegmentedProgress(
                    count: 20,
                    value: 1.333333333,
                    tone: OrionProgressTone.success,
                    style: OrionProgressStyle.from(gap: 12),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(
          tester.getSemantics(find.byType(OrionSegmentedProgress)).value,
          '1.3 of 20',
        );
        expect(
          _fillColors(tester).first,
          OrionProgressStyle.resolveToneColor(
            scheme: OrionColors.lightScheme,
            tone: OrionProgressTone.success,
          ),
        );
        handle.dispose();
      },
    );
  });

  group('OrionProgressStyle', () {
    test('a merge only changes the fields it names and theme lerp interpolates', () {
      const OrionProgressStyle base = OrionProgressStyle(
        trackColor: Color(0xFF111111),
        fillColor: Color(0xFF222222),
        height: 8,
      );
      final OrionProgressStyle merged = base.merge(
        OrionProgressStyle.from(fillColor: const Color(0xFF333333)),
      );

      expect(merged.fillColor, const Color(0xFF333333));
      expect(merged.trackColor, const Color(0xFF111111));
      expect(merged.height, 8);

      final OrionProgressTheme a = OrionProgressTheme(
        defaultStyle: OrionProgressStyle.from(height: 4, gap: 4),
      );
      final OrionProgressTheme b = OrionProgressTheme(
        defaultStyle: OrionProgressStyle.from(height: 12, gap: 12),
      );
      final OrionProgressTheme lerped = a.lerp(b, 0.5);
      expect(lerped.defaultStyle?.height, 8.0);
      expect(lerped.defaultStyle?.gap, 8.0);
    });

    test('defaults reproduce the shipped geometry', () {
      final OrionProgressStyle style = OrionProgressStyle.defaults(
        scheme: OrionColors.lightScheme,
        height: 8,
      );

      expect(style.trackColor, OrionColors.lightScheme.secondary);
      expect(style.fillColor, OrionColors.lightScheme.primary);
      expect(style.gap, OrionSpacing.space4);
      expect(style.height, 8);
      expect(
        style.spring,
        const OrionSpringSpec(stiffness: 380, dampingRatio: 1),
      );
    });
  });
}
