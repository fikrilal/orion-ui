import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pump(WidgetTester tester, int value) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(child: OrionCounter(value: value)),
      ),
    ),
  );
}

List<Matrix4> _digits(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(OrionCounter),
        matching: find.byType(Transform),
      ),
    )
    .map((Transform t) => t.transform)
    .toList();

/// The tallest contiguous band of the readout covered by painted digits. A pivot that
/// resolves below the visible row drags the digit out of its window and leaves a blank
/// band, which this measures directly rather than trusting the matrix.
double _coveredFraction(WidgetTester tester) {
  final Rect window = tester.getRect(find.byType(OrionCounter));
  final List<List<double>> bands = <List<double>>[];
  for (final Element element
      in find
          .descendant(
            of: find.byType(OrionCounter),
            matching: find.byType(Text),
          )
          .evaluate()) {
    final RenderBox box = element.renderObject! as RenderBox;
    final Rect painted = box.localToGlobal(Offset.zero) & box.size;
    final Rect overlap = painted.intersect(window);
    if (!overlap.isEmpty) {
      bands.add(<double>[overlap.top, overlap.bottom]);
    }
  }
  bands.sort((List<double> a, List<double> b) => a[0].compareTo(b[0]));
  double covered = 0;
  double top = double.nan;
  double bottom = double.nan;
  for (final List<double> band in bands) {
    if (top.isNaN) {
      top = band[0];
      bottom = band[1];
    } else if (band[0] <= bottom + 0.01) {
      if (band[1] > bottom) {
        bottom = band[1];
      }
    } else {
      covered += bottom - top;
      top = band[0];
      bottom = band[1];
    }
  }
  if (!top.isNaN) {
    covered += bottom - top;
  }
  return covered / window.height;
}

void main() {
  testWidgets('a rolling digit squashes and recovers', (tester) async {
    await _pump(tester, 0);
    await tester.pumpAndSettle();
    for (final Matrix4 m in _digits(tester)) {
      expect(m.entry(0, 0), closeTo(1, 0.001));
      expect(m.entry(1, 1), closeTo(1, 0.001));
    }

    // Change the value and catch the column mid-roll.
    await _pump(tester, 5);
    await tester.pump(const Duration(milliseconds: 16));

    final List<Matrix4> rolling = _digits(tester);
    expect(
      rolling.any((Matrix4 m) => m.entry(1, 1) < 0.999),
      isTrue,
      reason: 'a digit in flight should squash, or travel reads as a slide',
    );
    expect(
      rolling.any((Matrix4 m) => m.entry(0, 0) > 1.001),
      isTrue,
      reason: 'squashing vertically should widen horizontally',
    );

    await tester.pumpAndSettle();
    for (final Matrix4 m in _digits(tester)) {
      expect(m.entry(0, 0), closeTo(1, 0.001));
      expect(m.entry(1, 1), closeTo(1, 0.001));
    }
  });

  testWidgets('a rolling window is never left blank by the squash', (
    tester,
  ) async {
    await _pump(tester, 0);
    await tester.pumpAndSettle();
    expect(_coveredFraction(tester), greaterThan(0.99));

    await _pump(tester, 1);
    for (int frame = 0; frame < 20; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        _coveredFraction(tester),
        greaterThan(0.9),
        reason:
            'a squash pivoting off the visible row empties part of the window',
      );
    }
  });
}
