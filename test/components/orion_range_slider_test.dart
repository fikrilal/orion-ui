import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

const double _rangeWidth = 220;
const double _thumbSize = 20;

void main() {
  group('OrionRangeSlider', () {
    testWidgets(
      'drags start and end thumbs independently with lifecycle hooks',
      (tester) async {
        RangeValues values = const RangeValues(0.2, 0.8);
        RangeValues? started;
        RangeValues? ended;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: _rangeWidth,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return OrionRangeSlider(
                        values: values,
                        onChangeStart: (RangeValues v) => started = v,
                        onChanged: (RangeValues v) =>
                            setState(() => values = v),
                        onChangeEnd: (RangeValues v) => ended = v,
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        final Rect box = tester.getRect(find.byType(OrionRangeSlider));
        final double travel = box.width - _thumbSize;

        // Drag start thumb from 0.2 to 0.4.
        final TestGesture startDrag = await tester.startGesture(
          Offset(box.left + _thumbSize / 2 + travel * 0.2, box.center.dy),
        );
        await startDrag.moveBy(Offset(travel * 0.2, 0));
        await tester.pumpAndSettle();
        expect(started, const RangeValues(0.2, 0.8));
        expect(values.start, closeTo(0.4, 0.02));
        expect(values.end, closeTo(0.8, 0.02));
        await startDrag.up();
        await tester.pumpAndSettle();
        expect(ended?.start, closeTo(0.4, 0.02));

        // Drag end thumb from 0.8 to 0.6.
        final TestGesture endDrag = await tester.startGesture(
          Offset(box.left + _thumbSize / 2 + travel * 0.8, box.center.dy),
        );
        await endDrag.moveBy(Offset(-travel * 0.2, 0));
        await tester.pumpAndSettle();
        expect(values.start, closeTo(0.4, 0.02));
        expect(values.end, closeTo(0.6, 0.02));
        await endDrag.up();
        await tester.pumpAndSettle();
        expect(ended?.end, closeTo(0.6, 0.02));
      },
    );

    testWidgets('breaks ties by drag direction when thumbs are stacked', (
      tester,
    ) async {
      RangeValues values = const RangeValues(0.5, 0.5);

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: _rangeWidth,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return OrionRangeSlider(
                      values: values,
                      onChanged: (RangeValues v) => setState(() => values = v),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final Rect box = tester.getRect(find.byType(OrionRangeSlider));
      final double travel = box.width - _thumbSize;

      // Drag right from stacked center pulls end thumb right.
      final TestGesture rightDrag = await tester.startGesture(box.center);
      await rightDrag.moveBy(Offset(travel * 0.25, 0));
      await tester.pumpAndSettle();
      await rightDrag.up();
      await tester.pumpAndSettle();
      expect(values.start, closeTo(0.5, 0.02));
      expect(values.end, closeTo(0.75, 0.02));

      // Reset to stacked center and drag left -> pulls start thumb left.
      values = const RangeValues(0.5, 0.5);
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: _rangeWidth,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return OrionRangeSlider(
                      values: values,
                      onChanged: (RangeValues v) => setState(() => values = v),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final TestGesture leftDrag = await tester.startGesture(box.center);
      await leftDrag.moveBy(Offset(-travel * 0.25, 0));
      await tester.pumpAndSettle();
      await leftDrag.up();
      await tester.pumpAndSettle();
      expect(values.start, closeTo(0.25, 0.02));
      expect(values.end, closeTo(0.5, 0.02));
    });

    testWidgets('enforces minSpan and snaps steps on release with haptics', (
      tester,
    ) async {
      final List<String> haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments.toString());
          }
          return null;
        },
      );
      addTearDown(() {
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        );
      });

      RangeValues values = const RangeValues(20, 80);

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: _rangeWidth,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return OrionRangeSlider(
                      min: 0,
                      max: 100,
                      step: 10,
                      minSpan: 20,
                      showTicks: true,
                      values: values,
                      onChanged: (RangeValues v) => setState(() => values = v),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final Rect box = tester.getRect(find.byType(OrionRangeSlider));
      final double travel = box.width - _thumbSize;

      // Try dragging start thumb past end (80) -> clamped at 60 (80 - 20).
      final TestGesture drag = await tester.startGesture(
        Offset(box.left + _thumbSize / 2 + travel * 0.2, box.center.dy),
      );
      await drag.moveBy(Offset(travel * 0.75, 0));
      await tester.pumpAndSettle();
      await drag.up();
      await tester.pumpAndSettle();

      expect(values.start, 60);
      expect(values.end, 80);
      expect(haptics, isNotEmpty);
    });

    testWidgets(
      'supports independent keyboard navigation and semantics per thumb',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        final FocusNode startNode = FocusNode();
        final FocusNode endNode = FocusNode();
        addTearDown(() {
          startNode.dispose();
          endNode.dispose();
        });

        RangeValues values = const RangeValues(20, 80);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: _rangeWidth,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return OrionRangeSlider(
                        min: 0,
                        max: 100,
                        step: 10,
                        minSpan: 10,
                        values: values,
                        startFocusNode: startNode,
                        endFocusNode: endNode,
                        startSemanticLabel: 'Min price',
                        endSemanticLabel: 'Max price',
                        semanticFormatter: (double v) => '\$${v.round()}',
                        onChanged: (RangeValues v) =>
                            setState(() => values = v),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );

        startNode.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(values, const RangeValues(30, 80));

        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(values, const RangeValues(70, 80));

        endNode.requestFocus();
        await tester.pump();
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(values, const RangeValues(70, 100));

        final SemanticsNode minSem = tester.getSemantics(
          find.bySemanticsLabel('Min price'),
        );
        expect(minSem.flagsCollection.isSlider, isTrue);
        expect(minSem.value, r'$70');

        final SemanticsNode maxSem = tester.getSemantics(
          find.bySemanticsLabel('Max price'),
        );
        expect(maxSem.flagsCollection.isSlider, isTrue);
        expect(maxSem.value, r'$100');
        handle.dispose();
      },
    );

    testWidgets(
      'supports RTL, floating bubbles, allowTrackTap, disabled, and NaN safety',
      (tester) async {
        RangeValues values = const RangeValues(20, 80);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: Center(
                  child: SizedBox(
                    width: _rangeWidth,
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return OrionRangeSlider(
                          min: 0,
                          max: 100,
                          values: values,
                          allowTrackTap: true,
                          showValueIndicator: OrionSliderValueIndicator.always,
                          valueLabelBuilder: (double v) => '\$${v.round()}',
                          onChanged: (RangeValues v) =>
                              setState(() => values = v),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        expect(find.text(r'$20'), findsOneWidget);
        expect(find.text(r'$80'), findsOneWidget);

        // Tap near right edge in RTL (close to start=20 -> moves start near 0).
        final Rect box = tester.getRect(find.byType(OrionRangeSlider));
        await tester.tapAt(Offset(box.right - 12, box.center.dy));
        await tester.pumpAndSettle();
        expect(values.start, lessThan(10));

        // Disabled & NaN safety.
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: SizedBox(
                  width: _rangeWidth,
                  child: OrionRangeSlider(
                    values: RangeValues(double.nan, double.nan),
                    onChanged: null,
                  ),
                ),
              ),
            ),
          ),
        );
        expect(tester.takeException(), isNull);
        final SemanticsHandle handle = tester.ensureSemantics();
        final SemanticsNode node = tester.getSemantics(
          find.bySemanticsLabel('Minimum'),
        );
        expect(node.flagsCollection.isEnabled, Tristate.isFalse);
        handle.dispose();
      },
    );
  });
}
