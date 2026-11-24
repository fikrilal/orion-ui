import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required bool value,
  bool enabled = true,
  TextDirection textDirection = TextDirection.ltr,
  OrionSwitchStyle? style,
  bool disableAnimations = false,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Directionality(
        textDirection: textDirection,
        child: MediaQuery(
          data: MediaQueryData(disableAnimations: disableAnimations),
          child: Scaffold(
            body: Center(
              child: OrionSwitch(
                value: value,
                style: style,
                onChanged: enabled ? (bool _) {} : null,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Finder get _thumb => find.descendant(
  of: find.byType(OrionSwitch),
  matching: find.byKey(orionSwitchThumbKey),
);

Finder get _track => find.descendant(
  of: find.byType(OrionSwitch),
  matching: find.byKey(orionSwitchTrackKey),
);

void main() {
  testWidgets('a held thumb elongates into a capsule and recovers on release', (
    tester,
  ) async {
    await _pump(tester, value: false);

    final Rect rest = tester.getRect(_thumb);
    expect(rest.width, closeTo(24.0, 0.01));
    expect(rest.height, closeTo(24.0, 0.01));

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSwitch)),
    );
    await tester.pumpAndSettle();

    final Rect held = tester.getRect(_thumb);
    expect(held.width, closeTo(24.0 * 1.18, 0.2));
    expect(held.height, closeTo(24.0 * 0.88, 0.2));

    await gesture.up();
    await tester.pumpAndSettle();

    final Rect recovered = tester.getRect(_thumb);
    expect(recovered.width, closeTo(24.0, 0.05));
    expect(recovered.height, closeTo(24.0, 0.05));
  });

  testWidgets(
    'capsule elongation stays pinned to its resting edge in LTR and RTL',
    (tester) async {
      for (final TextDirection dir in TextDirection.values) {
        for (final bool value in <bool>[false, true]) {
          await _pump(tester, value: value, textDirection: dir);
          await tester.pumpAndSettle();

          final Rect before = tester.getRect(_thumb);
          final bool pinnedLeft = dir == TextDirection.ltr ? !value : value;
          final double edgeBefore = pinnedLeft ? before.left : before.right;

          final TestGesture gesture = await tester.startGesture(
            tester.getCenter(find.byType(OrionSwitch)),
          );
          await tester.pumpAndSettle();

          final Rect held = tester.getRect(_thumb);
          expect(held.width, greaterThan(before.width));
          final double edgeAfter = pinnedLeft ? held.left : held.right;

          expect(
            edgeAfter,
            closeTo(edgeBefore, 0.2),
            reason:
                'a widening capsule must stay pinned to its resting edge ($dir, value=$value)',
          );

          await gesture.up();
          await tester.pumpAndSettle();
        }
      }
    },
  );

  testWidgets('reduced motion lands capsule elongation in the same frame', (
    tester,
  ) async {
    await _pump(tester, value: false, disableAnimations: true);

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.byType(OrionSwitch)),
    );
    await tester.pump();
    expect(
      tester.getRect(_thumb).width,
      closeTo(24.0 * 1.18, 0.2),
      reason: 'motion is off, so the capsule must arrive immediately',
    );

    await gesture.up();
    await tester.pump();
    expect(tester.getRect(_thumb).width, closeTo(24.0, 0.05));
  });

  testWidgets(
    'a disabled switch does not deform, and disabling mid-press releases it',
    (tester) async {
      await _pump(tester, value: false, enabled: false);

      final TestGesture disabledGesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionSwitch)),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(_thumb).width, closeTo(24.0, 0.05));
      await disabledGesture.up();
      await tester.pumpAndSettle();

      // Hold while enabled, then disable mid-hold: capsule must relax cleanly.
      await _pump(tester, value: false, enabled: true);
      final TestGesture holdGesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionSwitch)),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(_thumb).width, greaterThan(26.0));

      await _pump(tester, value: false, enabled: false);
      await tester.pumpAndSettle();
      expect(tester.getRect(_thumb).width, closeTo(24.0, 0.05));
      await holdGesture.up();
    },
  );

  testWidgets(
    'style retunes capsule elongation and clamps extreme stretch inside track',
    (tester) async {
      await _pump(
        tester,
        value: false,
        style: OrionSwitchStyle.from(pressStretch: 0.5, pressSquish: 0.25),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionSwitch)),
      );
      await tester.pumpAndSettle();
      expect(tester.getRect(_thumb).width, closeTo(24.0 * 1.5, 0.2));
      expect(tester.getRect(_thumb).height, closeTo(24.0 * 0.75, 0.2));
      await gesture.up();
      await tester.pumpAndSettle();

      // Extreme stretch clamps safely to track inner width without overflowing.
      await _pump(
        tester,
        value: false,
        style: OrionSwitchStyle.from(pressStretch: 5.0),
      );
      final TestGesture extremeGesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionSwitch)),
      );
      await tester.pumpAndSettle();
      final Rect trackRect = tester.getRect(_track);
      final Rect thumbRect = tester.getRect(_thumb);
      expect(thumbRect.left, greaterThanOrEqualTo(trackRect.left));
      expect(thumbRect.right, lessThanOrEqualTo(trackRect.right));
      await extremeGesture.up();
      await tester.pumpAndSettle();
    },
  );
}
