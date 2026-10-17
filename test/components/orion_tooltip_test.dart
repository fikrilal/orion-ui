import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionTooltip Widget & Hover Interaction', () {
    testWidgets('opens on mouse hover and closes on mouse exit', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionTooltip(
                message: 'Helpful context',
                child: Text('Hover Target'),
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Move mouse over target
      await gesture.moveTo(tester.getCenter(find.text('Hover Target')));
      await tester.pump();
      // Wait for cold hover delay (250ms)
      await tester.pump(const Duration(milliseconds: 260));
      await tester.pumpAndSettle();

      expect(find.text('Helpful context'), findsOneWidget);

      // Move mouse away
      await gesture.moveTo(const Offset(10, 10));
      await tester.pump();
      // Leave bridge timer (100ms) + spring close
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(find.text('Helpful context'), findsNothing);
    });

    testWidgets('warm window engine: sibling tooltip opens with 0ms delay', (
      tester,
    ) async {
      OrionTooltipWarmCoordinator.reset();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  OrionTooltip(
                    message: 'First Button',
                    child: Text('Button A'),
                  ),
                  SizedBox(width: 40),
                  OrionTooltip(
                    message: 'Second Button',
                    child: Text('Button B'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);

      // Hover over Button A (cold start: requires 250ms)
      await gesture.moveTo(tester.getCenter(find.text('Button A')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      // Not open yet (100ms < 250ms)
      expect(find.text('First Button'), findsNothing);

      await tester.pump(const Duration(milliseconds: 160));
      await tester.pumpAndSettle();
      expect(find.text('First Button'), findsOneWidget);

      // Move mouse directly to Button B (within 300ms warm window)
      await gesture.moveTo(tester.getCenter(find.text('Button B')));
      await tester
          .pump(); // Enter triggers show() immediately without wait timer
      await tester.pump(
        const Duration(milliseconds: 16),
      ); // Overlay mounts on next frame

      // Button B opens instantly without waiting 250ms!
      expect(find.text('Second Button'), findsOneWidget);

      await tester.pumpAndSettle();
    });

    testWidgets('mobile touch long-press triggers tooltip with auto-dismiss', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionTooltip(
                message: 'Long Press Info',
                triggerMode: OrionTooltipTriggerMode.longPress,
                showDuration: Duration(milliseconds: 500),
                child: Text('Touch Target'),
              ),
            ),
          ),
        ),
      );

      // Long press
      await tester.longPress(find.text('Touch Target'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Long Press Info'), findsOneWidget);

      // Advance clock past showDuration (500ms)
      await tester.pump(const Duration(milliseconds: 600));
      await tester.pumpAndSettle();

      expect(find.text('Long Press Info'), findsNothing);
    });

    testWidgets('dismisses on Escape key event', (tester) async {
      final controller = OrionTooltipController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTooltip(
                controller: controller,
                message: 'Escape Dismissable',
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Escape Dismissable'), findsOneWidget);

      // Send Escape
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Escape Dismissable'), findsNothing);
    });

    testWidgets('tapping outside on barrier dismisses tooltip', (tester) async {
      final controller = OrionTooltipController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTooltip(
                controller: controller,
                message: 'Tap Dismissable',
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Tap Dismissable'), findsOneWidget);

      // Tap outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Tap Dismissable'), findsNothing);
    });

    testWidgets('scroll cooperation: ancestor scroll dismisses tooltip', (
      tester,
    ) async {
      final controller = OrionTooltipController();
      final scrollController = ScrollController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              controller: scrollController,
              itemCount: 40,
              itemBuilder: (context, index) {
                if (index == 2) {
                  return OrionTooltip(
                    controller: controller,
                    message: 'Scroll Target Tooltip',
                    child: Container(
                      height: 50,
                      color: Colors.amber,
                      child: const Text('Item With Tooltip'),
                    ),
                  );
                }
                return SizedBox(height: 50, child: Text('Row $index'));
              },
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();
      expect(find.text('Scroll Target Tooltip'), findsOneWidget);

      // Drag list to scroll
      await tester.drag(find.text('Row 0'), const Offset(0, -100));
      await tester.pumpAndSettle();

      // Tooltip dismissed!
      expect(find.text('Scroll Target Tooltip'), findsNothing);
    });

    testWidgets(
      'passive barrier passes tap to underlying button and dismisses tooltip',
      (tester) async {
        final controller = OrionTooltipController();
        bool buttonPressed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Stack(
                children: [
                  Positioned(
                    top: 10,
                    left: 10,
                    child: ElevatedButton(
                      onPressed: () => buttonPressed = true,
                      child: const Text('Underlying Button'),
                    ),
                  ),
                  Center(
                    child: OrionTooltip(
                      controller: controller,
                      message: 'Open Tooltip',
                      child: const Text('Target'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        controller.show();
        await tester.pumpAndSettle();
        expect(find.text('Open Tooltip'), findsOneWidget);

        // Tap the underlying button through the passive barrier
        await tester.tap(find.text('Underlying Button'));
        await tester.pumpAndSettle();

        expect(buttonPressed, isTrue);
        expect(find.text('Open Tooltip'), findsNothing);
      },
    );

    testWidgets('triggerMode tap toggles tooltip on sequential taps', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionTooltip(
                message: 'Tap Toggled',
                triggerMode: OrionTooltipTriggerMode.tap,
                child: Text('Tap Target'),
              ),
            ),
          ),
        ),
      );

      // First tap opens
      await tester.tap(find.text('Tap Target'));
      await tester.pumpAndSettle();
      expect(find.text('Tap Toggled'), findsOneWidget);

      // Second tap closes
      await tester.tap(find.text('Tap Target'));
      await tester.pumpAndSettle();
      expect(find.text('Tap Toggled'), findsNothing);
    });

    testWidgets('triggerMode hoverOnly ignores touch long-press', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionTooltip(
                message: 'Hover Only Info',
                triggerMode: OrionTooltipTriggerMode.hoverOnly,
                child: Text('Hover Target'),
              ),
            ),
          ),
        ),
      );

      await tester.longPress(find.text('Hover Target'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hover Only Info'), findsNothing);
    });

    testWidgets(
      'velocity continuity: mid-flight hover leave retargets back to zero smoothly',
      (tester) async {
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionTooltip(
                  waitDuration: Duration.zero,
                  message: 'Mid Flight Tooltip',
                  child: Text('Flight Target'),
                ),
              ),
            ),
          ),
        );

        // Hover over target to begin opening
        await gesture.moveTo(tester.getCenter(find.text('Flight Target')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30)); // In flight

        expect(find.text('Mid Flight Tooltip'), findsOneWidget);

        // Immediately move away before open completes
        await gesture.moveTo(Offset.zero);
        await tester
            .pump(); // Dismiss begins immediately with preserved position
        await tester.pump(const Duration(milliseconds: 50));
        await tester.pumpAndSettle();

        expect(find.text('Mid Flight Tooltip'), findsNothing);
      },
    );

    testWidgets(
      'scroll eviction safety: unmounting open tooltip does not throw and clears active count',
      (tester) async {
        OrionTooltipWarmCoordinator.reset();
        final controller = OrionTooltipController();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: ListView.builder(
                controller: scrollController,
                itemCount: 100,
                itemExtent: 80,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return OrionTooltip(
                      controller: controller,
                      message: 'Eviction Candidate',
                      child: Container(
                        height: 80,
                        color: Colors.blue,
                        child: const Text('Top Item'),
                      ),
                    );
                  }
                  return SizedBox(height: 80, child: Text('Row $index'));
                },
              ),
            ),
          ),
        );

        controller.show();
        await tester.pumpAndSettle();
        expect(find.text('Eviction Candidate'), findsOneWidget);
        expect(OrionTooltipWarmCoordinator.isWarm, isTrue);

        // Jump scroll by 1000 pixels so Row 0 is completely unmounted/evicted
        scrollController.jumpTo(1000);
        await tester.pumpAndSettle();

        // Must not throw Looking up a deactivated widget's ancestor is unsafe
        expect(find.text('Eviction Candidate'), findsNothing);
        expect(controller.isOpen, isFalse);
      },
    );

    testWidgets('reduced motion opens and closes immediately without ticking', (
      tester,
    ) async {
      final controller = OrionTooltipController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: OrionTooltip(
                  controller: controller,
                  message: 'Instant Tooltip',
                  child: const Text('Reduced Target'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.show();
      await tester.pump(); // Exactly 1 frame
      expect(find.text('Instant Tooltip'), findsOneWidget);

      controller.hide();
      await tester.pump();
      expect(find.text('Instant Tooltip'), findsNothing);
    });

    testWidgets(
      'zero-rebuild transform invariant: content does not rebuild on ticks',
      (tester) async {
        int buildCount = 0;
        final controller = OrionTooltipController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTooltip(
                  controller: controller,
                  message: 'Ignored Message',
                  richMessage: Builder(
                    builder: (context) {
                      buildCount++;
                      return const Text('Stable Tooltip Content');
                    },
                  ),
                  child: const Text('Build Trigger'),
                ),
              ),
            ),
          ),
        );

        controller.show();
        await tester.pump(); // Frame 0 mount
        final initialBuildCount = buildCount;
        expect(initialBuildCount, 1);

        // Pump 10 frames during spring expansion
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(buildCount, initialBuildCount);
        }
        await tester.pumpAndSettle();

        expect(buildCount, initialBuildCount);
      },
    );

    testWidgets(
      'frosted tooltip renders BackdropFilter inside bubble surface',
      (tester) async {
        final controller = OrionTooltipController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTooltip(
                  controller: controller,
                  style: OrionTooltipStyle.from(frosted: true),
                  message: 'Frosted Tooltip',
                  child: const Text('Frosted Target'),
                ),
              ),
            ),
          ),
        );

        controller.show();
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsOneWidget);
      },
    );

    testWidgets('semantics expose tooltip message', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionTooltip(
                message: 'Accessible Label',
                child: Text('Semantic Target'),
              ),
            ),
          ),
        ),
      );

      final hasTooltipSemantics = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.tooltip == 'Accessible Label',
      );
      expect(hasTooltipSemantics, findsOneWidget);
    });
  });

  group('OrionTooltipStyle & Themes', () {
    test('presets reproduce the light scheme default', () {
      final style = OrionTooltipPresets.resolve(
        scheme: OrionColors.lightScheme,
      );

      expect(style.gap, 6.0);
      expect(style.maxWidth, 260.0);
      expect(style.showArrow, isTrue);
      expect(
        style.springSpec,
        const OrionSpringSpec(stiffness: 480.0, dampingRatio: 0.85),
      );
    });

    test('style merge overrides only named fields', () {
      final base = OrionTooltipStyle.from(
        gap: 8.0,
        backgroundColor: Colors.white,
      );

      final merged = base.merge(
        OrionTooltipStyle.from(backgroundColor: Colors.black),
      );

      expect(merged.gap, 8.0);
      expect(merged.backgroundColor, Colors.black);
    });

    test('lerp correctly handles null values and interpolates scalars', () {
      const a = OrionTooltipStyle(gap: 4.0, maxWidth: 200.0);
      const b = OrionTooltipStyle(gap: 8.0, maxWidth: 300.0);

      final result = OrionTooltipStyle.lerp(a, b, 0.5)!;
      expect(result.gap, 6.0);
      expect(result.maxWidth, 250.0);
    });
  });
}
