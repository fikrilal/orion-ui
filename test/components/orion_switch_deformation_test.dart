import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool value,
  bool enabled = true,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: OrionSwitch(
            value: value,
            onChanged: enabled ? (bool _) {} : null,
          ),
        ),
      ),
    ),
  );
}

Finder get _thumb => find.descendant(
  of: find.byType(OrionSwitch),
  matching: find.byType(Transform),
);

Matrix4 _matrix(WidgetTester tester) =>
    tester.widget<Transform>(_thumb).transform;

void main() {
  testWidgets('a held thumb squashes and stretches, and recovers', (
    tester,
  ) async {
    await _pump(tester, value: false);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSwitch)),
    );
    await tester.pumpAndSettle();
    expect(_matrix(tester).entry(0, 0), closeTo(1.18, 0.01));
    expect(_matrix(tester).entry(1, 1), closeTo(0.88, 0.01));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(_matrix(tester).entry(0, 0), closeTo(1, 0.001));
    expect(_matrix(tester).entry(1, 1), closeTo(1, 0.001));
  });

  testWidgets('the stretch does not move the edge the thumb rests on', (
    tester,
  ) async {
    for (final bool value in <bool>[false, true]) {
      await _pump(tester, value: value);
      await tester.pumpAndSettle();

      final double size = tester.getSize(_thumb).width;
      final double restLeft = tester.getTopLeft(_thumb).dx;
      final double restOffset = _matrix(tester).entry(0, 3);
      // The edge the thumb hugs: its left when off, its right when on.
      final double before = value
          ? restLeft + size + restOffset
          : restLeft + restOffset;

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionSwitch)),
      );
      await tester.pumpAndSettle();

      // Painted edge = layout edge + translate, widened by half the growth on that side.
      final Matrix4 pressed = _matrix(tester);
      final double growth = ((pressed.entry(0, 0) - 1) * size) / 2;
      final double after = value
          ? restLeft + size + pressed.entry(0, 3) + growth
          : restLeft + pressed.entry(0, 3) - growth;

      expect(
        after,
        closeTo(before, 0.5),
        reason:
            'a widening thumb must stay pinned to its side, not drift inward',
      );

      await gesture.up();
      await tester.pumpAndSettle();
    }
  });

  testWidgets('reduced motion lands the deformation in the same frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OrionTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: Center(
              child: OrionSwitch(value: false, onChanged: (bool _) {}),
            ),
          ),
        ),
      ),
    );

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSwitch)),
    );
    await tester.pump();
    expect(
      _matrix(tester).entry(0, 0),
      closeTo(1.18, 0.01),
      reason: 'motion is off, so the thumb must arrive rather than climb',
    );

    await gesture.up();
    await tester.pump();
    expect(_matrix(tester).entry(0, 0), closeTo(1, 0.001));
  });

  testWidgets('a disabled switch does not deform', (tester) async {
    await _pump(tester, value: false, enabled: false);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSwitch)),
    );
    await tester.pumpAndSettle();

    expect(_matrix(tester).entry(0, 0), closeTo(1, 0.001));
    expect(_matrix(tester).entry(1, 1), closeTo(1, 0.001));

    await gesture.up();
    await tester.pumpAndSettle();
  });
}
