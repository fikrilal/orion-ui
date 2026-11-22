import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionPressable', () {
    testWidgets('compresses on pointer down and returns on tap completion', (
      tester,
    ) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onTap: () => tapped = true,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final state = tester.state<OrionPressableState>(
        find.byType(OrionPressable),
      );
      expect(state.driver.value, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(tapped, isTrue);
      expect(state.driver.value, closeTo(1.0, 0.001));
    });

    testWidgets('lifting after deactivation does not throw', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onTap: () {},
                child: const SizedBox(width: 120, height: 120),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      // Deactivate mid-press
      await tester.pumpWidget(const MaterialApp(home: SizedBox.shrink()));
      await tester.pump();

      await gesture.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('pointer move after deactivation while held does not throw', (
      tester,
    ) async {
      var showPressable = true;
      late StateSetter setState;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (context, setter) {
                  setState = setter;
                  return showPressable
                      ? OrionPressable(
                          onTap: () {},
                          child: const SizedBox(width: 100, height: 100),
                        )
                      : const SizedBox(width: 100, height: 100);
                },
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();

      // Deactivate while the pointer is still down and within touch slop.
      setState(() => showPressable = false);
      await tester.pumpAndSettle();
      expect(find.byType(OrionPressable), findsNothing);

      // A sub-slop move replays the cached hit-test path into the
      // deactivated element and must not perform ancestor lookups.
      await gesture.moveBy(const Offset(4, 0));
      await tester.pump();
      expect(tester.takeException(), isNull);

      await gesture.up();
      await tester.pump();
    });

    testWidgets(
      'allows parent ListView to win gesture arena on scroll without firing tap',
      (tester) async {
        var tapped = false;
        final haptics = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            if (methodCall.method == 'HapticFeedback.vibrate') {
              haptics.add(methodCall.arguments.toString());
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

        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ListView.builder(
                itemCount: 20,
                itemBuilder: (context, index) {
                  return OrionPressable(
                    onTap: () => tapped = true,
                    child: Container(
                      height: 80,
                      margin: const EdgeInsets.all(8),
                      color: Colors.blue,
                      child: Text('Item $index'),
                    ),
                  );
                },
              ),
            ),
          ),
        );

        // Drag to scroll the list
        await tester.drag(find.text('Item 0'), const Offset(0, -300));
        await tester.pumpAndSettle();

        // Tap should never have fired because parent ListView won the arena
        expect(tapped, isFalse);
        expect(find.text('Item 0'), findsNothing); // Scrolled off screen
        expect(haptics, isEmpty); // Cancellation stays silent
      },
    );

    testWidgets('fast scroll/drag does not strand spring compressed at 0.96', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ListView.builder(
              itemCount: 20,
              itemBuilder: (context, index) {
                return OrionPressable(
                  onTap: () {},
                  child: Container(
                    height: 80,
                    margin: const EdgeInsets.all(8),
                    color: Colors.blue,
                    child: Text('Item $index'),
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Start touch, drag fast (<100ms) so scrollable wins arena early
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Item 1')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final state = tester.state<OrionPressableState>(
        find.ancestor(
          of: find.text('Item 1'),
          matching: find.byType(OrionPressable),
        ),
      );
      expect(state.driver.target, 0.96);
      expect(state.driver.value, lessThan(1.0)); // Proves compression started

      await gesture.moveBy(const Offset(0, -80));
      await tester.pump(const Duration(milliseconds: 20));
      await gesture.up();
      await tester.pumpAndSettle();

      // Item 1 should have smoothly uncompressed back to 1.0
      expect(state.driver.target, 1.0);
      expect(state.driver.value, closeTo(1.0, 0.001));
    });

    testWidgets('drag beyond touch slop cancels spring before pointer lift', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onTap: () {},
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<OrionPressableState>(
        find.byType(OrionPressable),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));
      expect(state.driver.target, 0.96);

      // Drag beyond touch slop (e.g. 50 px)
      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();

      // Should retarget to 1.0 immediately during drag before lifting
      expect(state.driver.target, 1.0);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.driver.value, 1.0);
    });

    testWidgets('secondary mouse click does not compress pressable', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onTap: () {},
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      // Perform secondary (right) mouse click
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
        kind: PointerDeviceKind.mouse,
        buttons: kSecondaryMouseButton,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final state = tester.state<OrionPressableState>(
        find.byType(OrionPressable),
      );
      expect(state.driver.target, 1.0);
      expect(state.driver.value, 1.0); // Never compressed

      await gesture.up();
      await tester.pumpAndSettle();
      expect(state.driver.target, 1.0);
      expect(state.driver.value, 1.0);
    });

    testWidgets('long press maintains compression throughout hold', (
      tester,
    ) async {
      var longPressed = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onLongPress: () => longPressed = true,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      // Wait past the long press threshold (~500ms)
      await tester.pump(const Duration(milliseconds: 600));

      final state = tester.state<OrionPressableState>(
        find.byType(OrionPressable),
      );
      expect(longPressed, isTrue);
      // Still compressed while finger is down
      expect(state.driver.value, lessThan(1.0));

      await gesture.up();
      await tester.pumpAndSettle();

      // Releases after finger lifts
      expect(state.driver.value, closeTo(1.0, 0.001));
    });

    testWidgets('reports the press lifecycle through onPressedChanged', (
      tester,
    ) async {
      final reported = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onTap: () {},
                onPressedChanged: reported.add,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      expect(reported, <bool>[true]);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(reported, <bool>[true, false]);
    });

    testWidgets('a slop escape reports engagement and then release', (
      tester,
    ) async {
      final reported = <bool>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onTap: () {},
                onPressedChanged: reported.add,
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      expect(reported, <bool>[true]);

      await gesture.moveBy(const Offset(0, 50));
      await tester.pump();
      expect(reported, <bool>[true, false]);

      await gesture.up();
      await tester.pumpAndSettle();
      expect(reported, <bool>[
        true,
        false,
      ], reason: 'the lift after a cancellation adds no duplicate signal');
    });

    testWidgets('release produces a real peak overshoot before settling', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(
                onTap: () {},
                child: const SizedBox(width: 100, height: 100),
              ),
            ),
          ),
        ),
      );

      final state = tester.state<OrionPressableState>(
        find.byType(OrionPressable),
      );
      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      for (var i = 0; i < 20; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(state.driver.value, closeTo(0.96, 0.005));

      await gesture.up();
      var peak = 1.0;
      var frames = 0;
      while (state.driver.isAnimating && frames < 300) {
        await tester.pump(const Duration(milliseconds: 16));
        peak = math.max(peak, state.driver.value);
        frames++;
      }

      // Tight snappy spring (k = 600, zeta = 0.78) snaps back cleanly with a
      // subtle micro-overshoot (~1.0008) rather than wobbling.
      expect(peak, greaterThan(1.0));
      expect(peak, lessThan(1.003));
      expect(state.driver.value, 1.0); // Exact settlement via snapToEnd
    });

    testWidgets(
      'haptics are correctly gated for tap, long press, and cancellations',
      (tester) async {
        final log = <String>[];
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (methodCall) async {
            if (methodCall.method == 'HapticFeedback.vibrate') {
              log.add(methodCall.arguments.toString());
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

        // Test 1: Short tap with only onLongPress set emits zero haptics
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: OrionPressable(
                  onLongPress: () {},
                  child: const SizedBox(width: 100, height: 100),
                ),
              ),
            ),
          ),
        );

        final g1 = await tester.startGesture(
          tester.getCenter(find.byType(OrionPressable)),
        );
        await tester.pump();
        await g1.up();
        await tester.pumpAndSettle();
        expect(log, isEmpty); // No spurious tap haptic

        // Test 2: Long press emits mediumImpact
        final g2 = await tester.startGesture(
          tester.getCenter(find.byType(OrionPressable)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 600));
        expect(log, ['HapticFeedbackType.mediumImpact']);
        await g2.up();
        await tester.pumpAndSettle();

        // Test 3: A plain activation changes no state, so the default is silent
        log.clear();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: OrionPressable(
                  onTap: () {},
                  child: const SizedBox(width: 100, height: 100),
                ),
              ),
            ),
          ),
        );

        final g3 = await tester.startGesture(
          tester.getCenter(find.byType(OrionPressable)),
        );
        await tester.pump();
        await g3.up();
        await tester.pumpAndSettle();
        expect(log, isEmpty);

        // Test 4: A component whose tap is a transition opts in and ticks
        log.clear();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: OrionPressable(
                  onTap: () {},
                  hapticType: OrionHapticType.selectionClick,
                  child: const SizedBox(width: 100, height: 100),
                ),
              ),
            ),
          ),
        );

        final g4 = await tester.startGesture(
          tester.getCenter(find.byType(OrionPressable)),
        );
        await tester.pump();
        await g4.up();
        await tester.pumpAndSettle();
        expect(log, ['HapticFeedbackType.selectionClick']);
      },
    );

    testWidgets('does not rebuild child widget on spring animation frames', (
      tester,
    ) async {
      var childBuildCount = 0;

      final countingChild = Builder(
        builder: (context) {
          childBuildCount++;
          return const SizedBox(width: 100, height: 100);
        },
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: OrionPressable(onTap: () {}, child: countingChild),
            ),
          ),
        ),
      );

      expect(childBuildCount, 1);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionPressable)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 20));

      final state = tester.state<OrionPressableState>(
        find.byType(OrionPressable),
      );
      expect(state.driver.value, lessThan(1.0)); // Proves animation is running

      final transform = tester.widget<Transform>(
        find.descendant(
          of: find.byType(OrionPressable),
          matching: find.byType(Transform),
        ),
      );
      expect(
        transform.transform.entry(0, 0),
        closeTo(state.driver.value, 1e-9),
      );

      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      await gesture.up();
      await tester.pumpAndSettle();

      // Child should have been built only on initial widget insertion
      expect(childBuildCount, 1);
    });

    testWidgets(
      'respects MediaQuery disableAnimations by setting scale immediately',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Builder(
              builder: (context) {
                return MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(disableAnimations: true),
                  child: Scaffold(
                    body: Center(
                      child: OrionPressable(
                        onTap: () {},
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        final gesture = await tester.startGesture(
          tester.getCenter(find.byType(OrionPressable)),
        );
        await tester.pump();

        final state = tester.state<OrionPressableState>(
          find.byType(OrionPressable),
        );
        expect(state.driver.value, 0.96);
        expect(state.driver.isAnimating, isFalse);

        await gesture.up();
        await tester.pump();

        expect(state.driver.value, 1.0);
        expect(state.driver.isAnimating, isFalse);
      },
    );
  });
}
