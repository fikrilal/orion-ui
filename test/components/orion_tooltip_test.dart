import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  setUp(OrionTooltipWarmCoordinator.reset);

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
      // Leave bridge timer (140ms) + spring close
      await tester.pump(const Duration(milliseconds: 160));
      await tester.pumpAndSettle();

      expect(find.text('Helpful context'), findsNothing);
    });

    testWidgets(
      'warm window engine: sibling tooltip opens with 0ms delay and immediately dismisses prior sibling',
      (tester) async {
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

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        // Hover over Button A (cold start: requires 250ms)
        await gesture.moveTo(tester.getCenter(find.text('Button A')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));
        expect(find.text('First Button'), findsNothing);

        await tester.pump(const Duration(milliseconds: 160));
        await tester.pumpAndSettle();
        expect(find.text('First Button'), findsOneWidget);

        // Move mouse directly to Button B (within 300ms warm window)
        await gesture.moveTo(tester.getCenter(find.text('Button B')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));

        // Button B opens instantly and Button A is dismissed with zero overlap!
        expect(find.text('Second Button'), findsOneWidget);
        expect(find.text('First Button'), findsNothing);

        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'warm window does not leak active count on mid-close re-entry and cools down after 300ms',
      (tester) async {
        final controller = OrionTooltipController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTooltip(
                  controller: controller,
                  message: 'Leak Check',
                  child: const Text('Target'),
                ),
              ),
            ),
          ),
        );

        controller.show();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));
        expect(OrionTooltipWarmCoordinator.isWarm, isTrue);

        // Start closing, then immediately reopen mid-flight
        controller.hide();
        await tester.pump(const Duration(milliseconds: 20));
        controller.show();
        await tester.pumpAndSettle();
        expect(OrionTooltipWarmCoordinator.isWarm, isTrue);

        // Close cleanly and advance past 300ms warm window
        controller.hide();
        await tester.pumpAndSettle();
        await tester.pump(const Duration(milliseconds: 350));

        expect(OrionTooltipWarmCoordinator.isWarm, isFalse);
      },
    );

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

    testWidgets(
      'showDuration: Duration.zero disables long-press auto-dismiss',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionTooltip(
                  message: 'Persistent Long Press',
                  triggerMode: OrionTooltipTriggerMode.longPress,
                  showDuration: Duration.zero,
                  child: Text('Hold Target'),
                ),
              ),
            ),
          ),
        );

        await tester.longPress(find.text('Hold Target'));
        await tester.pumpAndSettle();
        expect(find.text('Persistent Long Press'), findsOneWidget);

        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Persistent Long Press'), findsOneWidget);
      },
    );

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

      await tester.drag(find.text('Row 0'), const Offset(0, -100));
      await tester.pumpAndSettle();

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

      // First tap opens and stays open past 2s by default
      await tester.tap(find.text('Tap Target'));
      await tester.pumpAndSettle();
      expect(find.text('Tap Toggled'), findsOneWidget);

      await tester.pump(const Duration(seconds: 2));
      expect(find.text('Tap Toggled'), findsOneWidget);

      // Second tap closes
      await tester.tap(find.text('Tap Target'));
      await tester.pumpAndSettle();
      expect(find.text('Tap Toggled'), findsNothing);
    });

    testWidgets(
      'triggerMode tap works over interactive OrionButton without losing gesture arena',
      (tester) async {
        int pressCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTooltip(
                  message: 'Button Tap Tooltip',
                  triggerMode: OrionTooltipTriggerMode.tap,
                  child: OrionButton(
                    onPressed: () => pressCount++,
                    child: const Text('Interactive Button'),
                  ),
                ),
              ),
            ),
          ),
        );

        // First tap opens tooltip AND triggers OrionButton
        await tester.tap(find.text('Interactive Button'));
        await tester.pumpAndSettle();
        expect(find.text('Button Tap Tooltip'), findsOneWidget);
        expect(pressCount, 1);

        // Second tap toggles tooltip closed AND triggers OrionButton
        await tester.tap(find.text('Interactive Button'));
        await tester.pumpAndSettle();
        expect(find.text('Button Tap Tooltip'), findsNothing);
        expect(pressCount, 2);
      },
    );

    testWidgets(
      'triggerMode manual and tap tooltips are not dismissed by mouse hover exit',
      (tester) async {
        final controller = OrionTooltipController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTooltip(
                  controller: controller,
                  triggerMode: OrionTooltipTriggerMode.manual,
                  dismissOnTapOutside: false,
                  message: 'Manual Pinned Tooltip',
                  child: const Text('Manual Target'),
                ),
              ),
            ),
          ),
        );

        controller.show();
        await tester.pumpAndSettle();
        expect(find.text('Manual Pinned Tooltip'), findsOneWidget);

        // Sweep mouse over the tooltip panel and away
        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);

        await gesture.moveTo(
          tester.getCenter(find.text('Manual Pinned Tooltip')),
        );
        await tester.pump();
        await gesture.moveTo(const Offset(5, 5));
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pumpAndSettle();

        expect(find.text('Manual Pinned Tooltip'), findsOneWidget);

        // Outside tap is also ignored when dismissOnTapOutside is false
        await tester.tapAt(const Offset(5, 5));
        await tester.pumpAndSettle();
        expect(find.text('Manual Pinned Tooltip'), findsOneWidget);
      },
    );

    testWidgets('keyboard focus opens tooltip and blur hides it', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic,
      );

      final focusNode = FocusNode();
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTooltip(
                message: 'Keyboard Tooltip',
                child: ElevatedButton(
                  focusNode: focusNode,
                  onPressed: () {},
                  child: const Text('Focus Target'),
                ),
              ),
            ),
          ),
        ),
      );

      focusNode.requestFocus();
      await tester.pumpAndSettle();
      expect(find.text('Keyboard Tooltip'), findsOneWidget);

      focusNode.unfocus();
      await tester.pumpAndSettle();
      expect(find.text('Keyboard Tooltip'), findsNothing);
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

        await gesture.moveTo(tester.getCenter(find.text('Flight Target')));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));

        expect(find.text('Mid Flight Tooltip'), findsOneWidget);

        await gesture.moveTo(Offset.zero);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 160));
        await tester.pumpAndSettle();

        expect(find.text('Mid Flight Tooltip'), findsNothing);
      },
    );

    testWidgets(
      'scroll eviction safety: unmounting open tooltip with controller listener does not throw',
      (tester) async {
        OrionTooltipWarmCoordinator.reset();
        final controller = OrionTooltipController();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: _ControllerListenerHost(
              controller: controller,
              child: Scaffold(
                body: ListView.builder(
                  controller: scrollController,
                  itemCount: 100,
                  itemExtent: 80,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return OrionTooltip(
                        controller: controller,
                        dismissOnScroll: false,
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
          ),
        );

        controller.show();
        await tester.pumpAndSettle();
        expect(find.text('Eviction Candidate'), findsOneWidget);
        expect(OrionTooltipWarmCoordinator.isWarm, isTrue);

        // Jump scroll by 1000 pixels so Row 0 is completely unmounted/evicted
        scrollController.jumpTo(1000);
        await tester.pumpAndSettle();

        expect(find.text('Eviction Candidate'), findsNothing);
        expect(controller.isOpen, isFalse);
      },
    );

    testWidgets('controller.toggle() mid-close immediately reopens tooltip', (
      tester,
    ) async {
      final controller = OrionTooltipController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTooltip(
                controller: controller,
                message: 'Toggle Mid Close',
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);

      // Start close animation
      controller.hide();
      expect(controller.isOpen, isFalse);
      await tester.pump(const Duration(milliseconds: 16));

      // Toggle during close tail should reopen immediately
      controller.toggle();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(find.text('Toggle Mid Close'), findsOneWidget);
    });

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
      await tester.pump();
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
        await tester.pump();
        final initialBuildCount = buildCount;
        expect(initialBuildCount, 1);

        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
          expect(buildCount, initialBuildCount);
        }
        await tester.pumpAndSettle();

        expect(buildCount, initialBuildCount);
      },
    );

    testWidgets(
      'richMessage inherits high-contrast DefaultTextStyle and IconTheme for inverted and surface tones',
      (tester) async {
        final invertedCtrl = OrionTooltipController();
        final surfaceCtrl = OrionTooltipController();
        Color? invertedTextColor;
        Color? invertedIconColor;
        Color? surfaceTextColor;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OrionTooltip(
                    controller: invertedCtrl,
                    message: 'Inverted Rich',
                    richMessage: Builder(
                      builder: (context) {
                        invertedTextColor = DefaultTextStyle.of(
                          context,
                        ).style.color;
                        invertedIconColor = IconTheme.of(context).color;
                        return const Text('Inverted Rich Text');
                      },
                    ),
                    child: const Text('Trigger 1'),
                  ),
                  const SizedBox(height: 24),
                  OrionTooltip(
                    controller: surfaceCtrl,
                    tone: OrionTooltipTone.surface,
                    message: 'Surface Rich',
                    richMessage: Builder(
                      builder: (context) {
                        surfaceTextColor = DefaultTextStyle.of(
                          context,
                        ).style.color;
                        return const Text('Surface Rich Text');
                      },
                    ),
                    child: const Text('Trigger 2'),
                  ),
                ],
              ),
            ),
          ),
        );

        invertedCtrl.show();
        await tester.pumpAndSettle();
        expect(invertedTextColor, OrionColors.lightScheme.onInverseSurface);
        expect(invertedIconColor, OrionColors.lightScheme.onInverseSurface);

        surfaceCtrl.show();
        await tester.pumpAndSettle();
        expect(surfaceTextColor, OrionColors.lightScheme.onSurface);
      },
    );

    testWidgets(
      'enabled: false and empty message prevent tooltip from opening, and onOpen/onClose fire',
      (tester) async {
        final controller = OrionTooltipController();
        int openCount = 0;
        int closeCount = 0;
        bool enabled = false;

        Widget buildApp() => MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTooltip(
                controller: controller,
                enabled: enabled,
                onOpen: () => openCount++,
                onClose: () => closeCount++,
                message: 'Guarded Tooltip',
                child: const Text('Target'),
              ),
            ),
          ),
        );

        await tester.pumpWidget(buildApp());
        controller.show();
        await tester.pumpAndSettle();
        expect(find.text('Guarded Tooltip'), findsNothing);
        expect(openCount, 0);

        // Enable -> opens and invokes onOpen
        enabled = true;
        await tester.pumpWidget(buildApp());
        controller.show();
        await tester.pumpAndSettle();
        expect(find.text('Guarded Tooltip'), findsOneWidget);
        expect(openCount, 1);

        // Close -> invokes onClose
        controller.hide();
        await tester.pumpAndSettle();
        expect(find.text('Guarded Tooltip'), findsNothing);
        expect(closeCount, 1);
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

    testWidgets('showArrow: false omits OrionTooltipArrowPainter', (
      tester,
    ) async {
      final controller = OrionTooltipController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTooltip(
                controller: controller,
                showArrow: false,
                message: 'No Arrow',
                child: const Text('Target'),
              ),
            ),
          ),
        ),
      );

      controller.show();
      await tester.pumpAndSettle();

      final arrowFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is OrionTooltipArrowPainter,
      );
      expect(arrowFinder, findsNothing);
    });

    testWidgets(
      'respects safe-area top padding so top tooltip flips below status bar',
      (tester) async {
        final controller = OrionTooltipController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(400, 800),
                padding: EdgeInsets.only(top: 48),
              ),
              child: Scaffold(
                body: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 52),
                    child: OrionTooltip(
                      controller: controller,
                      placement: OrionTooltipPlacement.top,
                      message: 'Status Bar Safe',
                      child: const SizedBox(
                        width: 100,
                        height: 36,
                        child: Text('Top Trigger'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        controller.show();
        await tester.pumpAndSettle();

        final Rect triggerRect = tester.getRect(find.text('Top Trigger'));
        final Rect tooltipRect = tester.getRect(find.text('Status Bar Safe'));
        // Flipped below trigger instead of clipping behind the 48px status bar
        expect(tooltipRect.top, greaterThan(triggerRect.bottom));
      },
    );

    testWidgets('semantics expose tooltip message unless excluded', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OrionTooltip(
                  message: 'Accessible Label',
                  child: Text('Semantic Target'),
                ),
                OrionTooltip(
                  message: 'Excluded Label',
                  excludeFromSemantics: true,
                  child: Text('Excluded Target'),
                ),
              ],
            ),
          ),
        ),
      );

      final hasAccessible = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.tooltip == 'Accessible Label',
      );
      final hasExcluded = find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.tooltip == 'Excluded Label',
      );
      expect(hasAccessible, findsOneWidget);
      expect(hasExcluded, findsNothing);
    });
  });

  group('OrionTooltipStyle & Themes', () {
    test('presets reproduce the light scheme default and surface tone', () {
      final inverted = OrionTooltipPresets.resolve(
        scheme: OrionColors.lightScheme,
      );
      expect(inverted.gap, 6.0);
      expect(inverted.maxWidth, 260.0);
      expect(inverted.showArrow, isTrue);
      expect(inverted.borderWidth, 0.0);
      expect(
        inverted.springSpec,
        const OrionSpringSpec(stiffness: 480.0, dampingRatio: 0.85),
      );

      final darkSurface = OrionTooltipPresets.resolve(
        scheme: OrionColors.darkScheme,
        tone: OrionTooltipTone.surface,
      );
      expect(
        darkSurface.backgroundColor,
        OrionColors.darkScheme.surfaceContainerHighest,
      );
      expect(darkSurface.borderWidth, 1.0);
      expect(darkSurface.textStyle?.color, OrionColors.darkScheme.onSurface);
    });

    test(
      'style merge overrides named fields and merges partial textStyle without dropping preset color',
      () {
        final base = OrionTooltipStyle.from(
          gap: 8.0,
          backgroundColor: Colors.black,
          textStyle: const TextStyle(
            fontSize: 12.0,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        );

        final merged = base.merge(
          OrionTooltipStyle.from(
            backgroundColor: Colors.grey,
            textStyle: const TextStyle(fontSize: 14.0),
          ),
        );

        expect(merged.gap, 8.0);
        expect(merged.backgroundColor, Colors.grey);
        expect(merged.textStyle?.fontSize, 14.0);
        expect(merged.textStyle?.color, Colors.white);
        expect(merged.textStyle?.fontWeight, FontWeight.w500);
      },
    );

    test('lerp correctly handles null values and interpolates scalars', () {
      const a = OrionTooltipStyle(gap: 4.0, maxWidth: 200.0, borderWidth: 0.0);
      const b = OrionTooltipStyle(gap: 8.0, maxWidth: 300.0, borderWidth: 2.0);

      final result = OrionTooltipStyle.lerp(a, b, 0.5)!;
      expect(result.gap, 6.0);
      expect(result.maxWidth, 250.0);
      expect(result.borderWidth, 1.0);

      expect(OrionTooltipStyle.lerp(null, b, 0.0), isNull);
      expect(OrionTooltipStyle.lerp(null, b, 1.0), equals(b));
    });
  });
}

class _ControllerListenerHost extends StatefulWidget {
  const _ControllerListenerHost({
    required this.controller,
    required this.child,
  });

  final OrionTooltipController controller;
  final Widget child;

  @override
  State<_ControllerListenerHost> createState() =>
      _ControllerListenerHostState();
}

class _ControllerListenerHostState extends State<_ControllerListenerHost> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
