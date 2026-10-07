import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pump(WidgetTester tester, {required bool expanded}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 320,
            child: OrionAccordion(
              expanded: expanded,
              onExpandedChanged: (bool _) {},
              header: const Text('Details'),
              child: const SizedBox(height: 120, child: Text('Panel')),
            ),
          ),
        ),
      ),
    ),
  );
}

double _extent(WidgetTester tester) =>
    tester.getSize(find.byType(OrionAccordion)).height;

void main() {
  testWidgets('a collapsing panel never grows on its way shut', (tester) async {
    await _pump(tester, expanded: true);
    await tester.pumpAndSettle();
    final double open = _extent(tester);

    await _pump(tester, expanded: false);
    double previous = open;
    for (int frame = 0; frame < 24; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
      final double now = _extent(tester);
      expect(
        now,
        lessThanOrEqualTo(previous + 0.01),
        reason: 'a shut panel that bounces back open reads as a mistake',
      );
      previous = now;
    }
    await tester.pumpAndSettle();

    // And it lands exactly where a panel that was never open sits.
    final double settled = _extent(tester);
    await _pump(tester, expanded: false);
    await tester.pumpAndSettle();
    expect(settled, closeTo(_extent(tester), 0.01));
  });
}
