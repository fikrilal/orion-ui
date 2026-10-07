import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pump(WidgetTester tester, {bool enabled = true}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: OrionSlider(
            value: 0.5,
            onChanged: enabled ? (double _) {} : null,
          ),
        ),
      ),
    ),
  );
}

/// The thumb is the last [Transform] inside the slider: the track fill comes first.
double _scale(WidgetTester tester) => tester
    .widgetList<Transform>(
      find.descendant(
        of: find.byType(OrionSlider),
        matching: find.byType(Transform),
      ),
    )
    .last
    .transform
    .entry(0, 0);

void main() {
  testWidgets('the thumb lifts while dragging and settles back', (
    tester,
  ) async {
    await _pump(tester);
    expect(_scale(tester), closeTo(1, 0.001));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSlider)),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(
      _scale(tester),
      closeTo(1.2, 0.01),
      reason: 'a held continuous control should look picked up',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1, 0.001));
  });

  testWidgets('a cancelled drag drops the lift too', (tester) async {
    await _pump(tester);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSlider)),
    );
    await gesture.moveBy(const Offset(20, 0));
    await tester.pumpAndSettle();
    expect(_scale(tester), greaterThan(1.05));

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1, 0.001));
  });

  testWidgets('disabling the slider mid-drag drops the lift', (tester) async {
    await _pump(tester);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSlider)),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pumpAndSettle();
    expect(_scale(tester), closeTo(1.2, 0.01));

    // The parent disables the control while the finger is still down: a disabled
    // slider's recognizer delivers no end or cancel, so nothing else can drop it.
    await _pump(tester, enabled: false);
    await gesture.up();
    await tester.pumpAndSettle();

    expect(_scale(tester), closeTo(1, 0.001));
  });

  testWidgets('a disabled slider does not lift', (tester) async {
    await _pump(tester, enabled: false);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSlider)),
    );
    await gesture.moveBy(const Offset(40, 0));
    await tester.pumpAndSettle();

    expect(_scale(tester), closeTo(1, 0.001));
    await gesture.up();
    await tester.pumpAndSettle();
  });
}
