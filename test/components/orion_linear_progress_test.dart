import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpBar(
  WidgetTester tester, {
  double? value,
  double? bufferedValue,
  String? semanticLabel,
  bool disableAnimations = false,
  double width = 300,
  OrionProgressStyle? style,
  ThemeData? theme,
}) {
  final Widget bar = SizedBox(
    width: width,
    child: OrionLinearProgress(
      value: value,
      bufferedValue: bufferedValue,
      semanticLabel: semanticLabel,
      style: style,
    ),
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

double _fillScale(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find
        .descendant(
          of: find.byType(OrionLinearProgress),
          matching: find.byType(Transform),
        )
        .first,
  );
  return transform.transform.entry(0, 0);
}

List<Color> _colors(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OrionLinearProgress),
          matching: find.byType(DecoratedBox),
        ),
      )
      .map((DecoratedBox box) => (box.decoration as BoxDecoration).color!)
      .toList();
}

List<double> _sweepStarts(WidgetTester tester) {
  return tester
      .widgetList<Align>(
        find.descendant(
          of: find.byType(OrionLinearProgress),
          matching: find.byType(Align),
        ),
      )
      .map((Align align) => (align.alignment as AlignmentDirectional).start)
      .toList();
}

List<Rect> _sweepSegments(WidgetTester tester) {
  return tester
      .widgetList<PositionedDirectional>(
        find.descendant(
          of: find.byType(OrionLinearProgress),
          matching: find.byType(PositionedDirectional),
        ),
      )
      .map(
        (PositionedDirectional segment) =>
            Rect.fromLTWH(segment.start!, 0, segment.width!, 0),
      )
      .toList();
}

void main() {
  group('OrionLinearProgress', () {
    testWidgets('fills to the clamped value', (tester) async {
      await _pumpBar(tester, value: 0.4);
      expect(_fillScale(tester), closeTo(0.4, 0.001));

      await _pumpBar(tester, value: 1.4);
      await tester.pumpAndSettle();
      expect(_fillScale(tester), 1.0);

      await _pumpBar(tester, value: -0.5);
      await tester.pumpAndSettle();
      expect(_fillScale(tester), 0.0);
    });

    testWidgets('paints the buffered layer between track and fill', (
      tester,
    ) async {
      await _pumpBar(tester, value: 0.5, bufferedValue: 0.8);

      final ThemeData theme = Theme.of(
        tester.element(find.byType(OrionLinearProgress)),
      );
      expect(_colors(tester), <Color>[
        theme.colorScheme.secondary,
        theme.colorScheme.primary.withValues(alpha: 0.24),
        theme.colorScheme.primary,
      ]);

      final Finder layers = find.descendant(
        of: find.byType(OrionLinearProgress),
        matching: find.byType(DecoratedBox),
      );
      expect(tester.getSize(layers.at(1)).width, closeTo(240, 0.01));
    });

    testWidgets('flows one bar through the track without blinking', (
      tester,
    ) async {
      await _pumpBar(tester);
      // The loop opens on an empty track for a single frame.
      expect(_sweepSegments(tester), isEmpty);
      expect(
        find.descendant(
          of: find.byType(OrionLinearProgress),
          matching: find.byType(Transform),
        ),
        findsNothing,
        reason: 'the indeterminate state paints the sweep, not the fill',
      );

      // The first bar grows out of the leading edge.
      await tester.pump(const Duration(milliseconds: 250));
      List<Rect> segments = _sweepSegments(tester);
      expect(segments, isNotEmpty);
      expect(segments.first.left, lessThan(1));

      // Through a whole loop at least one bar is on the track, in bounds.
      for (int frame = 0; frame < 14; frame++) {
        await tester.pump(const Duration(milliseconds: 150));
        segments = _sweepSegments(tester);
        expect(
          segments,
          isNotEmpty,
          reason: 'the track is never empty once the loop is running',
        );
        for (final Rect segment in segments) {
          expect(segment.left, greaterThanOrEqualTo(0));
          expect(segment.width, greaterThan(0));
          expect(segment.right, lessThanOrEqualTo(300.01));
        }
      }
    });

    testWidgets('rests static under reduced motion', (tester) async {
      await _pumpBar(tester, disableAnimations: true);
      expect(_sweepStarts(tester), <double>[0.0]);

      await tester.pump(const Duration(milliseconds: 500));
      expect(_sweepStarts(tester), <double>[0.0]);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('carries the percentage in semantics', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, value: 0.4, semanticLabel: 'Uploading');

      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionLinearProgress),
      );
      expect(node.label, 'Uploading');
      expect(node.value, '40%');

      await _pumpBar(tester);
      expect(
        tester.getSemantics(find.byType(OrionLinearProgress)).value,
        isEmpty,
        reason: 'an indeterminate bar carries no value',
      );
      handle.dispose();
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

      await _pumpBar(tester, value: 1, theme: themed);
      expect(_colors(tester).last, const Color(0xFF00AA00));

      await _pumpBar(
        tester,
        value: 1,
        theme: themed,
        style: OrionProgressStyle.from(fillColor: const Color(0xFFAA0000)),
      );
      expect(_colors(tester).last, const Color(0xFFAA0000));
    });

    testWidgets('rejects an unbounded width', (tester) async {
      final List<Object> errors = <Object>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details.exception);
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Row(children: const <Widget>[OrionLinearProgress(value: 0.5)]),
        ),
      );
      FlutterError.onError = previous;
      expect(errors.whereType<AssertionError>(), isNotEmpty);
    });

    testWidgets('animates bufferedValue smoothly instead of snapping', (
      tester,
    ) async {
      await _pumpBar(tester, value: 0.2, bufferedValue: 0.2);
      await _pumpBar(tester, value: 0.2, bufferedValue: 0.8);
      await tester.pump(const Duration(milliseconds: 16));

      final Finder layers = find.descendant(
        of: find.byType(OrionLinearProgress),
        matching: find.byType(DecoratedBox),
      );
      final double midWidth = tester.getSize(layers.at(1)).width;
      expect(midWidth, greaterThan(60.0));
      expect(midWidth, lessThan(240.0));

      await tester.pumpAndSettle();
      expect(tester.getSize(layers.at(1)).width, closeTo(240.0, 0.1));
    });

    testWidgets(
      'resets determinate spring when returning from indeterminate so it advances forward',
      (tester) async {
        await _pumpBar(tester, value: 0.9);
        await tester.pumpAndSettle();
        expect(_fillScale(tester), closeTo(0.9, 0.001));

        // Switch to indeterminate, then back to 0.2.
        await _pumpBar(tester, value: null);
        await tester.pump(const Duration(milliseconds: 100));

        await _pumpBar(tester, value: 0.2);
        await tester.pump(const Duration(milliseconds: 16));

        final double scale = _fillScale(tester);
        expect(scale, greaterThan(0.0));
        expect(
          scale,
          lessThanOrEqualTo(0.2),
          reason: 'must animate forward from 0 -> 0.2, not backward from 0.9',
        );
        await tester.pumpAndSettle();
        expect(_fillScale(tester), closeTo(0.2, 0.001));
      },
    );

    testWidgets(
      'guards NaN values, supports tones, pill sweep caps, and semanticValue override',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: OrionLinearProgress(
                    value: double.nan,
                    bufferedValue: double.nan,
                    tone: OrionProgressTone.error,
                    semanticValue: 'Retrying',
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(_fillScale(tester), 0.0);
        expect(_colors(tester).last, OrionColors.lightScheme.error);
        expect(
          tester.getSemantics(find.byType(OrionLinearProgress)).value,
          'Retrying',
        );

        // Indeterminate sweep lines inherit the pill borderRadius.
        await _pumpBar(tester);
        await tester.pump(const Duration(milliseconds: 250));
        final Iterable<DecoratedBox> sweepBoxes = tester
            .widgetList<PositionedDirectional>(
              find.descendant(
                of: find.byType(OrionLinearProgress),
                matching: find.byType(PositionedDirectional),
              ),
            )
            .map((PositionedDirectional p) => p.child as DecoratedBox);
        expect(sweepBoxes, isNotEmpty);
        for (final DecoratedBox box in sweepBoxes) {
          expect(
            (box.decoration as BoxDecoration).borderRadius,
            BorderRadius.circular(OrionRadii.radiusPill),
          );
        }
        handle.dispose();
      },
    );
  });
}
