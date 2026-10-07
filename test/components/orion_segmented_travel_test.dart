import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

const List<OrionSegment<String>> _segments = <OrionSegment<String>>[
  OrionSegment(value: 'a', label: Text('A')),
  OrionSegment(value: 'b', label: Text('B')),
  OrionSegment(value: 'c', label: Text('C')),
];

Future<void> _pump(WidgetTester tester, String value) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 300,
            child: OrionSegmentedControl<String>(
              segments: _segments,
              value: value,
              onChanged: (String _) {},
            ),
          ),
        ),
      ),
    ),
  );
}

/// The furthest any transform has travelled horizontally: the indicator's position,
/// since the pressables only scale.
double _furthest(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(OrionSegmentedControl<String>),
        matching: find.byType(Transform),
      ),
    )
    .map((Transform t) => t.transform.entry(0, 3))
    .fold(0, (double a, double b) => b > a ? b : a);

void main() {
  testWidgets('the indicator travels to its segment without overshooting', (
    tester,
  ) async {
    await _pump(tester, 'a');
    await tester.pumpAndSettle();

    await _pump(tester, 'c');
    final List<double> samples = <double>[];
    for (int frame = 0; frame < 24; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      samples.add(_furthest(tester));
    }
    await tester.pumpAndSettle();
    final double settled = _furthest(tester);

    for (int i = 1; i < samples.length; i++) {
      expect(
        samples[i],
        greaterThanOrEqualTo(samples[i - 1] - 0.5),
        reason:
            'a visible wobble means the indicator bounced past its segment; the '
            'half-pixel tolerance is the spring settling, not motion',
      );
    }
    expect(
      samples.reduce((double a, double b) => a > b ? a : b),
      lessThanOrEqualTo(settled + 2),
      reason:
          'a travel spring settles within a pixel or two; the press spring at '
          'zeta 0.36 would carry it roughly 45 px past the segment',
    );
    expect(settled, greaterThan(0));
  });
}
