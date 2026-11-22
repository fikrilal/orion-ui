import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionBottomSheet Widget & Detent Snapping', () {
    testWidgets('mounts at initial detent height', (tester) async {
      final controller = OrionSheetController();
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              controller: controller,
              detents: const [0.4, 0.8],
              initialDetentIndex: 0,
              builder: (context, controller) => const Text('Sheet Content'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final sheetFinder = find.byType(OrionBottomSheet);
      expect(sheetFinder, findsOneWidget);
      expect(find.text('Sheet Content'), findsOneWidget);

      // Height should be approximately 40% of screen height (600 * 0.4 = 240)
      expect(controller.currentHeight, closeTo(240.0, 1.0));
      expect(controller.currentFraction, closeTo(0.4, 0.01));
    });

    testWidgets('controller snaps between detents and expands/collapses', (
      tester,
    ) async {
      final controller = OrionSheetController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              controller: controller,
              detents: const [0.3, 0.6, 0.9],
              initialDetentIndex: 0,
              builder: (context, scroll) => const Text('Controlled Sheet'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(controller.currentDetentIndex, 0);

      // Expand to top detent
      controller.expand();
      await tester.pumpAndSettle();
      expect(controller.currentDetentIndex, 2);

      // Collapse back to lowest detent
      controller.collapse();
      await tester.pumpAndSettle();
      expect(controller.currentDetentIndex, 0);

      // Snap to middle detent (index 1)
      controller.snapToDetent(1);
      await tester.pumpAndSettle();
      expect(controller.currentDetentIndex, 1);
    });

    testWidgets(
      'dragging upward past highest detent applies rubber-band resistance',
      (tester) async {
        final controller = OrionSheetController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                detents: const [0.5, 0.8],
                initialDetentIndex: 1,
                builder: (context, scroll) => const Text('Rubberband Sheet'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final double topHeight = controller.currentHeight;

        // Start drag from handle upward by 100 pt
        final sheetClip = find.byType(ClipRRect);
        final gesture = await tester.startGesture(
          tester.getTopLeft(sheetClip) + const Offset(50, 10),
        );
        await gesture.moveBy(const Offset(0, -100));
        await tester.pump();

        // With rubber-band factor 0.15, height should grow much less than 100 pt
        final double rubberBandedHeight = controller.currentHeight;
        expect(rubberBandedHeight, greaterThan(topHeight));
        expect(
          rubberBandedHeight - topHeight,
          lessThan(30),
        ); // 100 * 0.15 = 15 pt

        // Releasing springs back cleanly to topHeight
        await gesture.up();
        await tester.pumpAndSettle();
        expect(controller.currentHeight, closeTo(topHeight, 0.1));
      },
    );

    testWidgets('dragging downward past dismiss threshold fires onDismiss', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              detents: const [0.4, 0.8],
              initialDetentIndex: 0,
              onDismiss: () => dismissed = true,
              builder: (context, scroll) => const Text('Dismiss Sheet'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Drag downward by 200 pt from the visible content
      final dismissText = find.text('Dismiss Sheet');
      await tester.drag(dismissText, const Offset(0, 200));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('fast downward fling triggers dismissal', (tester) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              detents: const [0.5, 0.9],
              initialDetentIndex: 0,
              onDismiss: () => dismissed = true,
              builder: (context, scroll) => const Text('Fling Sheet'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Fling down with high velocity
      await tester.fling(
        find.text('Fling Sheet'),
        const Offset(0, 100),
        1000.0,
      );
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('barrier tap dismisses sheet when barrierDismissible is true', (
      tester,
    ) async {
      var dismissed = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              hasBarrier: true,
              barrierDismissible: true,
              detents: const [0.5],
              onDismiss: () => dismissed = true,
              builder: (context, scroll) => const Text('Barrier Sheet'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap near top of screen (in the barrier area)
      await tester.tapAt(const Offset(200, 50));
      await tester.pumpAndSettle();

      expect(dismissed, isTrue);
    });

    testWidgets('reduced motion settles detents immediately without ticking', (
      tester,
    ) async {
      final controller = OrionSheetController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                detents: const [0.4, 0.8],
                initialDetentIndex: 0,
                builder: (context, scroll) =>
                    const Text('Reduced Motion Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();
      expect(find.text('Reduced Motion Sheet'), findsOneWidget);

      controller.expand();
      await tester.pump();
      expect(controller.currentDetentIndex, 1);
    });

    testWidgets('modal showOrionBottomSheet pushes and pops on dismiss', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionBottomSheet<void>(
                    context: context,
                    builder: (ctx, scroll) => const Text('Modal Content'),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Content'), findsOneWidget);

      // Dismiss modal by tapping barrier
      await tester.tapAt(const Offset(200, 30));
      await tester.pumpAndSettle();

      expect(find.text('Modal Content'), findsNothing);
    });
    testWidgets('does not rebuild content on animation ticks', (tester) async {
      var buildCount = 0;
      final controller = OrionSheetController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              controller: controller,
              detents: const [0.4, 0.8],
              initialDetentIndex: 0,
              builder: (context, scroll) {
                return Builder(
                  builder: (context) {
                    buildCount++;
                    return const Text('Isolated Content');
                  },
                );
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final initialCount = buildCount;

      // Expand to detent 1, pumping 10 intermediate frames
      controller.expand();
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
      }
      await tester.pumpAndSettle();

      // Content child is not rebuilt on animation ticks
      expect(buildCount, initialCount);
    });

    testWidgets(
      'inner scroll handover: dragging up expands sheet before list scrolls',
      (tester) async {
        final controller = OrionSheetController();
        late ScrollController innerScroll;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                detents: const [0.4, 0.8],
                initialDetentIndex: 0,
                builder: (context, scroll) {
                  innerScroll = scroll;
                  return ListView.builder(
                    controller: scroll,
                    itemCount: 100,
                    itemBuilder: (context, index) =>
                        SizedBox(height: 50, child: Text('Item $index')),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(controller.currentDetentIndex, 0);
        expect(innerScroll.offset, 0.0);
        expect(controller.currentHeight, closeTo(240.0, 1.0));

        // Drag upward by 150 pt from the list content
        await tester.drag(find.text('Item 2'), const Offset(0, -150));
        await tester.pump();

        // Sheet expanded, but inner list stayed at offset 0
        expect(controller.currentHeight, greaterThan(240.0));
        expect(innerScroll.offset, 0.0);

        // Settle to max detent
        await tester.pumpAndSettle();
        expect(controller.currentDetentIndex, 1);
        expect(controller.currentHeight, closeTo(480.0, 1.0));
        expect(innerScroll.offset, 0.0);

        // Now that sheet is at max detent, dragging upward scrolls the list
        await tester.drag(find.text('Item 2'), const Offset(0, -100));
        await tester.pumpAndSettle();

        expect(innerScroll.offset, greaterThan(0.0));
        expect(controller.currentHeight, closeTo(480.0, 1.0));

        // Drag downward to scroll list back to top
        final double scrolledOffset = innerScroll.offset;
        await tester.drag(find.text('Item 4'), Offset(0, scrolledOffset + 50));
        await tester.pumpAndSettle();

        expect(innerScroll.offset, 0.0);
      },
    );

    testWidgets('tap on inner list item executes without interrupting sheet', (
      tester,
    ) async {
      final controller = OrionSheetController();
      var tappedItem = -1;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              controller: controller,
              detents: const [0.4, 0.8],
              initialDetentIndex: 0,
              builder: (context, scroll) => ListView(
                controller: scroll,
                children: [
                  for (int i = 0; i < 5; i++)
                    ListTile(
                      title: Text('Tile $i'),
                      onTap: () => tappedItem = i,
                    ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final double restingHeight = controller.currentHeight;

      // Tap Tile 1
      await tester.tap(find.text('Tile 1'));
      await tester.pumpAndSettle();

      expect(tappedItem, 1);
      expect(controller.currentHeight, restingHeight);
      expect(controller.currentDetentIndex, 0);
    });

    testWidgets('horizontal gesture does not move sheet vertically', (
      tester,
    ) async {
      final controller = OrionSheetController();
      double sliderVal = 0.5;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              controller: controller,
              detents: const [0.5, 0.9],
              initialDetentIndex: 0,
              builder: (context, scroll) => StatefulBuilder(
                builder: (context, setState) => Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: OrionSlider(
                    value: sliderVal,
                    min: 0.0,
                    max: 1.0,
                    onChanged: (v) => setState(() => sliderVal = v),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final double restingHeight = controller.currentHeight;

      // Drag horizontally on slider thumb
      final sliderFinder = find.byType(OrionSlider);
      await tester.drag(sliderFinder, const Offset(80, 0));
      await tester.pumpAndSettle();

      expect(sliderVal, greaterThan(0.5));
      expect(controller.currentHeight, closeTo(restingHeight, 0.1));
    });

    testWidgets(
      'isDismissible: false prevents dismissal on downward drags and barrier taps',
      (tester) async {
        var dismissed = false;
        final controller = OrionSheetController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                hasBarrier: true,
                isDismissible: false,
                detents: const [0.4, 0.8],
                initialDetentIndex: 0,
                onDismiss: () => dismissed = true,
                builder: (context, scroll) =>
                    const Text('Non-dismissible Sheet'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final double minH = controller.currentHeight;

        // Drag down hard
        await tester.drag(
          find.text('Non-dismissible Sheet'),
          const Offset(0, 300),
        );
        await tester.pumpAndSettle();

        expect(dismissed, isFalse);
        expect(controller.currentHeight, closeTo(minH, 1.0));

        // Tap barrier
        await tester.tapAt(const Offset(200, 30));
        await tester.pumpAndSettle();

        expect(dismissed, isFalse);
        expect(controller.currentHeight, closeTo(minH, 1.0));
      },
    );

    testWidgets('frosted sheet renders acrylic BackdropFilter on sheet surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionBottomSheet(
              hasBarrier: true,
              detents: const [0.5],
              style: OrionBottomSheetStyle.from(frosted: true),
              builder: (context, scroll) => const Text('Modal Blur Sheet'),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Exactly one BackdropFilter in the tree, located inside the sheet surface
      final blurFilters = find.byType(BackdropFilter);
      expect(blurFilters, findsOneWidget);

      final clipFinder = find.byType(ClipRRect);
      expect(
        find.descendant(of: clipFinder, matching: find.byType(BackdropFilter)),
        findsOneWidget,
      );
    });

    testWidgets(
      'inline frosted sheet renders BackdropFilter for canvas diffusion',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                hasBarrier: false,
                detents: const [0.5],
                style: OrionBottomSheetStyle.from(frosted: true),
                builder: (context, scroll) => const Text('Inline Blur Sheet'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Inline sheet with frosted=true renders its acrylic BackdropFilter
        expect(find.byType(BackdropFilter), findsOneWidget);
      },
    );

    testWidgets(
      'initialDetentIndex > 0 with inner scrollable mounts at requested detent without resetting to 0',
      (tester) async {
        final controller = OrionSheetController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                detents: const [0.3, 0.7],
                initialDetentIndex: 1,
                builder: (context, scroll) => ListView.builder(
                  controller: scroll,
                  itemCount: 50,
                  itemBuilder: (context, index) =>
                      ListTile(title: Text('Item $index')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Must mount and settle at Detent 1 (70% height = 420 pt on 600 pt screen)
        expect(controller.currentDetentIndex, 1);
        expect(controller.currentFraction, closeTo(0.7, 0.01));
        expect(controller.currentHeight, closeTo(420.0, 1.0));
      },
    );

    testWidgets(
      'reduced motion dismissal immediately calls onDismiss and pops modal route',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Builder(
                  builder: (context) => ElevatedButton(
                    onPressed: () {
                      showOrionBottomSheet<void>(
                        context: context,
                        builder: (ctx, scroll) =>
                            const Text('Reduced Modal Content'),
                      );
                    },
                    child: const Text('Open Modal'),
                  ),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Modal'));
        await tester.pump();
        expect(find.text('Reduced Modal Content'), findsOneWidget);

        // Tap barrier to dismiss under reduced motion
        await tester.tapAt(const Offset(200, 30));
        await tester.pump();

        // Modal route is popped immediately
        expect(find.text('Reduced Modal Content'), findsNothing);
      },
    );

    testWidgets(
      'drag handle hit target satisfies minimum 44 pt accessibility height',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                detents: const [0.5],
                builder: (context, scroll) => const Text('Handle Target Test'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final handleFinder = find.descendant(
          of: find.byType(MouseRegion),
          matching: find.byType(GestureDetector),
        );
        expect(handleFinder, findsOneWidget);

        final RenderBox handleBox = tester.renderObject(handleFinder);
        expect(handleBox.size.height, greaterThanOrEqualTo(44.0));
      },
    );

    testWidgets(
      'downward dismiss without onDismiss still marks controller as dismissed',
      (tester) async {
        final controller = OrionSheetController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                isDismissible: true,
                detents: const [0.4, 0.8],
                initialDetentIndex: 0,
                builder: (context, scroll) => const Text('No OnDismiss Sheet'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        // Drag down hard past dismiss threshold
        await tester.drag(
          find.text('No OnDismiss Sheet'),
          const Offset(0, 300),
        );
        await tester.pumpAndSettle();

        // Controller reflects dismissed state and height rests at 0
        expect(controller.isDismissed, isTrue);
        expect(controller.currentHeight, closeTo(0.0, 0.01));
      },
    );

    testWidgets(
      'onDetentChanged only fires when transitioning to a different detent',
      (tester) async {
        final transitions = <int>[];
        final controller = OrionSheetController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                detents: const [0.4, 0.8],
                initialDetentIndex: 0,
                onDetentChanged: (idx) => transitions.add(idx),
                builder: (context, scroll) =>
                    const Text('Transition Test Sheet'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        // Clear initial mount transition
        transitions.clear();

        // Slight drag release that snaps back to Detent 0
        await tester.drag(
          find.text('Transition Test Sheet'),
          const Offset(0, -10),
        );
        await tester.pumpAndSettle();

        // No spurious event emitted because detent remained at 0
        expect(transitions, isEmpty);

        // Move to Detent 1
        controller.expand();
        await tester.pumpAndSettle();
        expect(transitions, [1]);
      },
    );

    testWidgets(
      'didUpdateWidget reclamps active detent index when detents list shrinks',
      (tester) async {
        final controller = OrionSheetController();
        var detents = const <double>[0.3, 0.6, 0.9];

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: StatefulBuilder(
              builder: (context, setState) {
                return Scaffold(
                  floatingActionButton: FloatingActionButton(
                    onPressed: () => setState(() {
                      detents = const <double>[0.3, 0.6];
                    }),
                    child: const Icon(Icons.refresh),
                  ),
                  body: OrionBottomSheet(
                    controller: controller,
                    detents: detents,
                    initialDetentIndex: 2,
                    builder: (context, scroll) => const Text('Shrinking Sheet'),
                  ),
                );
              },
            ),
          ),
        );

        await tester.pumpAndSettle();
        expect(controller.currentDetentIndex, 2);

        // Shrink detents from 3 to 2 items
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Controller index reclamps to 1 (highest index in 2-element list)
        expect(controller.currentDetentIndex, 1);
      },
    );

    testWidgets(
      'fitContent sizes sheet to intrinsic content height and stays draggable',
      (tester) async {
        final controller = OrionSheetController();
        var dismissed = false;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                fitContent: true,
                title: 'Quick Actions',
                subtitle: 'Choose an option below',
                onDismiss: () => dismissed = true,
                builder: (context, scroll) => const Padding(
                  padding: EdgeInsets.all(16),
                  child: SizedBox(height: 100, child: Text('Compact Body')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        expect(find.text('Quick Actions'), findsOneWidget);
        expect(find.text('Choose an option below'), findsOneWidget);
        expect(find.text('Compact Body'), findsOneWidget);
        // Should fit tightly around handle + header + 132px body, well below 600px viewport.
        expect(controller.currentHeight, greaterThan(180));
        expect(controller.currentHeight, lessThan(340));

        await tester.drag(find.text('Compact Body'), const Offset(0, 220));
        await tester.pumpAndSettle();
        expect(dismissed, isTrue);
      },
    );

    testWidgets(
      'floating variant applies outer inset margin and all-round border radius',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                fitContent: true,
                variant: OrionBottomSheetVariant.floating,
                builder: (context, scroll) => const SizedBox(
                  height: 120,
                  child: Center(child: Text('Floating Sheet')),
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final Rect screen = tester.getRect(find.byType(Scaffold));
        final Rect card = tester.getRect(find.byType(ClipRRect));
        expect(card.left - screen.left, closeTo(OrionSpacing.space16, 1.5));
        expect(screen.right - card.right, closeTo(OrionSpacing.space16, 1.5));
        expect(screen.bottom - card.bottom, closeTo(OrionSpacing.space16, 1.5));
      },
    );

    testWidgets(
      'showOrionBottomSheet returns typed result via OrionBottomSheet.dismissOf',
      (tester) async {
        String? picked;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () async {
                    picked = await showOrionBottomSheet<String>(
                      context: context,
                      fitContent: true,
                      variant: OrionBottomSheetVariant.floating,
                      title: 'Pick Theme',
                      showCloseButton: true,
                      builder: (ctx, scroll) => Padding(
                        padding: const EdgeInsets.all(16),
                        child: OrionButton(
                          label: 'Select Dark',
                          onPressed: () =>
                              OrionBottomSheet.dismissOf(ctx, 'dark'),
                        ),
                      ),
                    );
                  },
                  child: const Text('Open Picker'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Picker'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Select Dark'));
        await tester.pumpAndSettle();

        expect(picked, 'dark');
        expect(find.text('Pick Theme'), findsNothing);
      },
    );

    testWidgets(
      'bottom of sheet content stays reachable at lower detent without clipping off-screen',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                detents: const [0.4, 0.85],
                initialDetentIndex: 0,
                builder: (context, scroll) => Column(
                  children: <Widget>[
                    const Expanded(child: Center(child: Text('Top Area'))),
                    Container(
                      height: 44,
                      alignment: Alignment.center,
                      child: const Text('Pinned Footer'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();

        final Rect screen = tester.getRect(find.byType(Scaffold));
        final Rect footer = tester.getRect(find.text('Pinned Footer'));
        expect(footer.bottom, lessThanOrEqualTo(screen.bottom));
      },
    );

    testWidgets(
      'rubber-banding above max detent keeps bottom anchored without leaving a gap',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                detents: const [0.5, 0.8],
                initialDetentIndex: 1,
                builder: (context, scroll) => const Text('Anchored Sheet'),
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final Rect screen = tester.getRect(find.byType(Scaffold));

        final TestGesture gesture = await tester.startGesture(
          tester.getTopLeft(find.byType(ClipRRect)) + const Offset(50, 10),
        );
        await gesture.moveBy(const Offset(0, -120));
        await tester.pump();

        final Rect sheet = tester.getRect(find.byType(ClipRRect));
        expect(sheet.bottom, closeTo(screen.bottom, 1.5));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'continuous downward scroll past top hands off seamlessly to sheet drag',
      (tester) async {
        final controller = OrionSheetController();
        late ScrollController innerScroll;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionBottomSheet(
                controller: controller,
                detents: const [0.4, 0.8],
                initialDetentIndex: 1,
                builder: (context, scroll) {
                  innerScroll = scroll;
                  return ListView.builder(
                    controller: scroll,
                    itemCount: 40,
                    itemBuilder: (context, index) =>
                        SizedBox(height: 48, child: Text('Row $index')),
                  );
                },
              ),
            ),
          ),
        );

        await tester.pumpAndSettle();
        final double maxH = controller.currentHeight;

        // Scroll slightly into list first.
        await tester.drag(find.text('Row 2'), const Offset(0, -40));
        await tester.pumpAndSettle();
        expect(innerScroll.offset, greaterThan(0));

        // Now drag down in ONE continuous gesture (stepped like a real finger)
        // far enough to hit 0 AND pull sheet down.
        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.text('Row 2')),
        );
        for (int i = 0; i < 6; i++) {
          await gesture.moveBy(const Offset(0, 30));
          await tester.pump(const Duration(milliseconds: 16));
        }

        expect(innerScroll.offset, 0.0);
        expect(controller.currentHeight, lessThan(maxH));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('modal sheet lifts cleanly above soft keyboard viewInsets', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 600),
              viewInsets: EdgeInsets.only(bottom: 200),
            ),
            child: Scaffold(
              body: OrionBottomSheet(
                hasBarrier: true,
                fitContent: true,
                builder: (context, scroll) => const SizedBox(
                  height: 120,
                  child: Center(child: Text('Keyboard Aware')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final Rect card = tester.getRect(find.byType(ClipRRect));
      expect(card.bottom, closeTo(400.0, 2.0));
    });
  });

  group('OrionBottomSheetStyle & Themes', () {
    test('presets reproduce the light scheme default', () {
      final style = OrionBottomSheetPresets.resolve(
        scheme: OrionColors.lightScheme,
      );

      expect(style.borderWidth, 0.0);
      expect(style.borderColor, isNull);
      expect(style.rubberBandFactor, 0.15);
      expect(style.dismissThreshold, 96.0);
      expect(style.detentSpring, OrionBottomSheetPresets.defaultDetentSpring);
      expect(style.dismissSpring, OrionBottomSheetPresets.defaultDismissSpring);
      expect(style.dismissSpring?.clampOvershoot, isTrue);

      final floating = OrionBottomSheetPresets.resolve(
        scheme: OrionColors.lightScheme,
        variant: OrionBottomSheetVariant.floating,
      );
      expect(
        floating.borderRadius,
        BorderRadius.circular(OrionRadii.radius24),
      );
    });

    test('style merge overrides only named fields', () {
      final base = OrionBottomSheetStyle.from(
        borderWidth: 2.0,
        backgroundColor: Colors.white,
      );

      final merged = base.merge(
        OrionBottomSheetStyle.from(backgroundColor: Colors.blue),
      );

      expect(merged.borderWidth, 2.0);
      expect(merged.backgroundColor, Colors.blue);
    });
  });
}
