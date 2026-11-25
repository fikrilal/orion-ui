import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionPopover Widget & Physics', () {
    testWidgets('opens on trigger tap and closes on outside tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionPopover(
                trigger: const Text('Open Popover'),
                content: const Text('Popover Body Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Popover Body Content'), findsNothing);

      // Tap trigger to open
      await tester.tap(find.text('Open Popover'));
      await tester.pumpAndSettle();

      expect(find.text('Popover Body Content'), findsOneWidget);

      // Tap outside (at top-left corner) to dismiss
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Popover Body Content'), findsNothing);
    });

    testWidgets(
      'programmatically opens and closes via OrionPopoverController',
      (tester) async {
        final controller = OrionPopoverController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionPopover(
                  controller: controller,
                  trigger: const Text('Controller Trigger'),
                  content: const Text('Controlled Body'),
                ),
              ),
            ),
          ),
        );

        expect(controller.isOpen, isFalse);

        controller.show();
        await tester.pumpAndSettle();

        expect(controller.isOpen, isTrue);
        expect(find.text('Controlled Body'), findsOneWidget);

        controller.hide();
        await tester.pumpAndSettle();

        expect(controller.isOpen, isFalse);
        expect(find.text('Controlled Body'), findsNothing);
      },
    );

    testWidgets('dismisses on Escape key event', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionPopover(
                trigger: const Text('Escape Trigger'),
                content: const Text('Escape Body'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Escape Trigger'));
      await tester.pumpAndSettle();
      expect(find.text('Escape Body'), findsOneWidget);

      // Send Escape key
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Escape Body'), findsNothing);
    });

    testWidgets('reduced motion opens and closes immediately without ticking', (
      tester,
    ) async {
      final controller = OrionPopoverController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: OrionPopover(
                  controller: controller,
                  trigger: const Text('Reduced Trigger'),
                  content: const Text('Reduced Body'),
                ),
              ),
            ),
          ),
        ),
      );

      controller.show();
      await tester.pump(); // Exactly 1 frame
      expect(find.text('Reduced Body'), findsOneWidget);

      controller.hide();
      await tester.pump();
      expect(find.text('Reduced Body'), findsNothing);
    });

    testWidgets('does not rebuild content on animation ticks', (tester) async {
      var buildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionPopover(
                trigger: const Text('Rebuild Trigger'),
                content: Builder(
                  builder: (context) {
                    buildCount++;
                    return const Text('Isolated Body');
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Open popover
      await tester.tap(find.text('Rebuild Trigger'));
      await tester.pump(); // First frame where overlay builds child

      final initialBuildCount = buildCount;
      expect(initialBuildCount, 1);

      // Pump 10 consecutive frames during spring expansion
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();

      // Child was not rebuilt on tick frames
      expect(buildCount, initialBuildCount);
    });

    testWidgets(
      'frosted popover renders BackdropFilter inside popover surface',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionPopover(
                  style: OrionPopoverStyle.from(frosted: true),
                  trigger: const Text('Frosted Trigger'),
                  content: const Text('Frosted Content'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Frosted Trigger'));
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsOneWidget);
      },
    );

    testWidgets('showArrow: true renders OrionPopoverArrowPainter', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionPopover(
                showArrow: true,
                trigger: const Text('Arrow Trigger'),
                content: const Text('Arrow Content'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Arrow Trigger'));
      await tester.pumpAndSettle();

      final arrowFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is OrionPopoverArrowPainter,
      );
      expect(arrowFinder, findsOneWidget);
    });

    testWidgets('triggerBuilder opens popover with active OrionButton', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionPopover(
                triggerBuilder: (context, controller) => OrionButton(
                  variant: OrionButtonVariant.solid,
                  onPressed: controller.toggle,
                  child: const Text('Active Button Trigger'),
                ),
                content: const Text('Button Opened Content'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Button Opened Content'), findsNothing);

      await tester.tap(find.text('Active Button Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Button Opened Content'), findsOneWidget);
    });

    testWidgets(
      'auto-flips to top and opens smoothly when trigger is at bottom of screen',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: OrionPopover(
                    placement: OrionPopoverPlacement.bottomCenter,
                    trigger: const Text('Bottom Trigger'),
                    content: const SizedBox(
                      height: 150,
                      width: 200,
                      child: Text('Flipped Content'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Bottom Trigger'));
        await tester.pumpAndSettle();

        expect(find.text('Flipped Content'), findsOneWidget);

        final triggerBox = tester.getRect(find.text('Bottom Trigger'));
        final contentBox = tester.getRect(find.text('Flipped Content'));

        // Popover should be above the trigger
        expect(contentBox.bottom, lessThan(triggerBox.top));
      },
    );

    testWidgets('real pointer press gesture on trigger button', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionPopover(
                triggerBuilder: (context, controller) => OrionButton(
                  variant: OrionButtonVariant.solid,
                  onPressed: controller.toggle,
                  child: const Text('Pointer Trigger'),
                ),
                content: const Text('Pointer Content'),
              ),
            ),
          ),
        ),
      );

      // Perform real pointer down gesture
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Pointer Trigger')),
      );
      await tester.pump(const Duration(milliseconds: 30));

      // Lift pointer
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Pointer Content'), findsOneWidget);
    });

    testWidgets(
      'scroll cooperation: drag inside parent scrollable moves list while popover remains closed',
      (tester) async {
        final controller = OrionPopoverController();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: ListView.builder(
                controller: scrollController,
                itemCount: 50,
                itemBuilder: (context, index) {
                  if (index == 2) {
                    return OrionPopover(
                      controller: controller,
                      trigger: Container(
                        height: 60,
                        color: Colors.amber,
                        alignment: Alignment.center,
                        child: const Text('Scrollable Trigger'),
                      ),
                      content: const Text('Hidden Popover Content'),
                    );
                  }
                  return SizedBox(height: 60, child: Text('Item $index'));
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(scrollController.offset, 0.0);
        expect(controller.isOpen, isFalse);

        // Drag upward on the trigger item
        await tester.drag(
          find.text('Scrollable Trigger'),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        // List scrolled and popover never opened
        expect(scrollController.offset, greaterThan(0.0));
        expect(controller.isOpen, isFalse);
        expect(find.text('Hidden Popover Content'), findsNothing);
      },
    );

    testWidgets(
      'dismissOnScroll: dismisses open popover when ancestor scrollable scrolls',
      (tester) async {
        final controller = OrionPopoverController();
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: ListView.builder(
                controller: scrollController,
                itemCount: 50,
                itemBuilder: (context, index) {
                  if (index == 2) {
                    return OrionPopover(
                      controller: controller,
                      trigger: const Text('Open From List'),
                      content: const Text('Floating Body From List'),
                    );
                  }
                  return SizedBox(height: 50, child: Text('Row $index'));
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Open the popover
        await tester.tap(find.text('Open From List'));
        await tester.pumpAndSettle();

        expect(controller.isOpen, isTrue);
        expect(find.text('Floating Body From List'), findsOneWidget);

        // Now scroll the page
        await tester.drag(find.text('Row 0'), const Offset(0, -100));
        await tester.pumpAndSettle();

        // Popover dismissed on scroll
        expect(controller.isOpen, isFalse);
        expect(find.text('Floating Body From List'), findsNothing);
      },
    );

    testWidgets(
      'dismissOnScroll: dragging outside on barrier dismisses popover',
      (tester) async {
        final controller = OrionPopoverController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionPopover(
                  controller: controller,
                  trigger: const Text('Center Trigger'),
                  content: const Text('Center Popover Body'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Center Trigger'));
        await tester.pumpAndSettle();

        expect(controller.isOpen, isTrue);
        expect(find.text('Center Popover Body'), findsOneWidget);

        // Pan/drag outside on the barrier
        await tester.dragFrom(const Offset(20, 20), const Offset(0, 100));
        await tester.pumpAndSettle();

        // Popover dismissed
        expect(controller.isOpen, isFalse);
        expect(find.text('Center Popover Body'), findsNothing);
      },
    );

    testWidgets(
      'dismissOnScroll: scrolling inside popover content does not dismiss it',
      (tester) async {
        final controller = OrionPopoverController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionPopover(
                  controller: controller,
                  trigger: const Text('Scrollable Content Trigger'),
                  content: SizedBox(
                    height: 100,
                    width: 150,
                    child: ListView.builder(
                      itemCount: 20,
                      itemBuilder: (context, index) => Text('Inner Row $index'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Scrollable Content Trigger'));
        await tester.pumpAndSettle();

        expect(controller.isOpen, isTrue);
        expect(find.text('Inner Row 0'), findsOneWidget);

        // Scroll inside the popover list
        await tester.drag(find.text('Inner Row 0'), const Offset(0, -60));
        await tester.pumpAndSettle();

        // Popover remains open!
        expect(controller.isOpen, isTrue);
        expect(find.text('Inner Row 2'), findsOneWidget);
      },
    );

    test('shouldRelayout detects all configuration property changes', () {
      final delegate = OrionPopoverLayoutDelegate(
        triggerRect: const Rect.fromLTWH(0, 0, 50, 50),
        viewportPadding: const EdgeInsets.all(12.0),
        preferredPlacement: OrionPopoverPlacement.bottomStart,
        gap: 8.0,
        autoFlip: true,
        showArrow: false,
        arrowSize: const Size(14, 7),
        onLayoutResolved: (_) {},
      );

      // Same properties -> false
      expect(
        delegate.shouldRelayout(
          OrionPopoverLayoutDelegate(
            triggerRect: const Rect.fromLTWH(0, 0, 50, 50),
            viewportPadding: const EdgeInsets.all(12.0),
            preferredPlacement: OrionPopoverPlacement.bottomStart,
            gap: 8.0,
            autoFlip: true,
            showArrow: false,
            arrowSize: const Size(14, 7),
            onLayoutResolved: (_) {},
          ),
        ),
        isFalse,
      );

      // Changed viewportPadding -> true
      expect(
        delegate.shouldRelayout(
          OrionPopoverLayoutDelegate(
            triggerRect: const Rect.fromLTWH(0, 0, 50, 50),
            viewportPadding: const EdgeInsets.all(16.0),
            preferredPlacement: OrionPopoverPlacement.bottomStart,
            gap: 8.0,
            autoFlip: true,
            showArrow: false,
            arrowSize: const Size(14, 7),
            onLayoutResolved: (_) {},
          ),
        ),
        isTrue,
      );

      // Changed showArrow -> true
      expect(
        delegate.shouldRelayout(
          OrionPopoverLayoutDelegate(
            triggerRect: const Rect.fromLTWH(0, 0, 50, 50),
            viewportPadding: const EdgeInsets.all(12.0),
            preferredPlacement: OrionPopoverPlacement.bottomStart,
            gap: 8.0,
            autoFlip: true,
            showArrow: true,
            arrowSize: const Size(14, 7),
            onLayoutResolved: (_) {},
          ),
        ),
        isTrue,
      );

      // Changed arrowSize -> true
      expect(
        delegate.shouldRelayout(
          OrionPopoverLayoutDelegate(
            triggerRect: const Rect.fromLTWH(0, 0, 50, 50),
            viewportPadding: const EdgeInsets.all(12.0),
            preferredPlacement: OrionPopoverPlacement.bottomStart,
            gap: 8.0,
            autoFlip: true,
            showArrow: false,
            arrowSize: const Size(18, 9),
            onLayoutResolved: (_) {},
          ),
        ),
        isTrue,
      );
    });

    testWidgets(
      'dynamic style updates take effect immediately without theme change',
      (tester) async {
        bool frosted = false;
        double borderWidth = 1.0;
        late StateSetter setHostState;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                setHostState = setState;
                return Scaffold(
                  body: Center(
                    child: OrionPopover(
                      style: OrionPopoverStyle.from(
                        frosted: frosted,
                        borderWidth: borderWidth,
                      ),
                      trigger: const Text('Dynamic Trigger'),
                      content: const Text('Dynamic Body'),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.text('Dynamic Trigger'));
        await tester.pumpAndSettle();
        expect(find.byType(BackdropFilter), findsNothing);

        // Update style dynamically -> frosted blur appears immediately.
        setHostState(() {
          frosted = true;
          borderWidth = 0.0;
        });
        await tester.pumpAndSettle();
        expect(find.byType(BackdropFilter), findsOneWidget);

        // borderWidth: 0 omits foreground border cleanly.
        final Iterable<DecoratedBox> foregroundBorders = tester
            .widgetList<DecoratedBox>(find.byType(DecoratedBox))
            .where(
              (DecoratedBox b) =>
                  b.position == DecorationPosition.foreground &&
                  (b.decoration as BoxDecoration).border != null,
            );
        expect(foregroundBorders, isEmpty);
      },
    );

    testWidgets(
      'closing releases barrier immediately and allows zero-cooldown reopen',
      (tester) async {
        final OrionPopoverController controller = OrionPopoverController();
        addTearDown(controller.dispose);
        int outsideCount = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  ElevatedButton(
                    onPressed: () => outsideCount++,
                    child: const Text('Outside Target'),
                  ),
                  const SizedBox(height: 24),
                  OrionPopover(
                    controller: controller,
                    triggerBuilder:
                        (BuildContext context, OrionPopoverController c) =>
                            ElevatedButton(
                              onPressed: c.toggle,
                              child: const Text('Zero Cooldown Trigger'),
                            ),
                    content: const Text('Zero Cooldown Body'),
                  ),
                ],
              ),
            ),
          ),
        );

        await tester.tap(find.text('Zero Cooldown Trigger'));
        await tester.pumpAndSettle();
        expect(controller.isOpen, isTrue);

        // Begin closing, pump only 16 ms (mid-exit), and verify logical state
        // is already false and an outside target can be tapped immediately.
        controller.hide();
        await tester.pump(const Duration(milliseconds: 16));
        expect(controller.isOpen, isFalse);

        await tester.tap(find.text('Outside Target'));
        expect(outsideCount, 1);

        // Immediately reopen mid-close without waiting for exit tail.
        controller.show();
        await tester.pumpAndSettle();
        expect(controller.isOpen, isTrue);
        expect(find.text('Zero Cooldown Body'), findsOneWidget);
      },
    );

    testWidgets('respects status bar padding and keyboard viewInsets', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(400, 600),
              padding: EdgeInsets.only(top: 50, bottom: 34),
              viewInsets: EdgeInsets.only(bottom: 260),
              disableAnimations: true,
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: OrionPopover(
                    placement: OrionPopoverPlacement.topCenter,
                    autoFlip: false,
                    trigger: const Text('Top Safe Trigger'),
                    content: const SizedBox(
                      width: 160,
                      height: 80,
                      child: Text('Safe Body'),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Top Safe Trigger'));
      await tester.pump();

      final Rect bodyRect = tester.getRect(find.text('Safe Body'));
      expect(
        bodyRect.top,
        greaterThanOrEqualTo(58.0),
        reason: 'popover must stay below status bar padding',
      );
    });
  });

  group('OrionPopoverStyle & Themes', () {
    test('presets provide crisp elevated light and dark defaults', () {
      final style = OrionPopoverPresets.resolve(
        scheme: OrionColors.lightScheme,
      );

      expect(style.borderWidth, 1.0);
      expect(style.gap, 8.0);
      expect(style.minWidth, 140.0);
      expect(style.backgroundColor, OrionColors.lightScheme.surfaceContainer);
      expect(style.borderColor, OrionColors.lightScheme.outlineVariant);
      expect(style.borderRadius, BorderRadius.circular(14.0));
      expect(style.padding, const EdgeInsets.all(6.0));
      expect(
        style.springSpec,
        const OrionSpringSpec(stiffness: 520.0, dampingRatio: 0.86),
      );
      expect(
        style.dismissSpringSpec,
        const OrionSpringSpec(
          stiffness: 620.0,
          dampingRatio: 1.0,
          clampOvershoot: true,
        ),
      );

      final darkStyle = OrionPopoverPresets.resolve(
        scheme: OrionColors.darkScheme,
      );
      expect(
        darkStyle.backgroundColor,
        OrionColors.darkScheme.surfaceContainer,
      );
      expect(darkStyle.backgroundColor, isNot(OrionColors.darkScheme.surface));
      expect(darkStyle.borderColor, OrionColors.darkScheme.outlineVariant);
    });

    test(
      'style merge overrides only named fields and theme lerp interpolates',
      () {
        final base = OrionPopoverStyle.from(
          borderWidth: 2.0,
          backgroundColor: Colors.white,
        );

        final merged = base.merge(
          OrionPopoverStyle.from(backgroundColor: Colors.blue),
        );

        expect(merged.borderWidth, 2.0);
        expect(merged.backgroundColor, Colors.blue);

        final themeA = OrionPopoverTheme(
          defaultStyle: OrionPopoverStyle.from(gap: 4.0),
        );
        final themeB = OrionPopoverTheme(
          defaultStyle: OrionPopoverStyle.from(gap: 12.0),
        );
        final lerped = themeA.lerp(themeB, 0.5);
        expect(lerped.defaultStyle?.gap, 8.0);
      },
    );
  });
}
