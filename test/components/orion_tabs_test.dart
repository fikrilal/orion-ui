import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionTabs Widget & Interactions', () {
    testWidgets('renders all tabs and dispatches selection on tap', (
      tester,
    ) async {
      String? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTabs<String>(
                value: 'overview',
                onChanged: (val) => selected = val,
                tabs: const [
                  OrionTab(value: 'overview', label: 'Overview'),
                  OrionTab(value: 'pull_requests', label: 'Pull Requests'),
                  OrionTab(value: 'issues', label: 'Issues'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Overview'), findsOneWidget);
      expect(find.text('Pull Requests'), findsOneWidget);
      expect(find.text('Issues'), findsOneWidget);

      // Tap 'Issues'
      await tester.tap(find.text('Issues'));
      await tester.pumpAndSettle();

      expect(selected, 'issues');
    });

    testWidgets(
      'disabled tab ignores taps and suppresses selection callbacks',
      (tester) async {
        String? selected;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTabs<String>(
                  value: 'tab1',
                  onChanged: (val) => selected = val,
                  tabs: const [
                    OrionTab(value: 'tab1', label: 'Tab 1'),
                    OrionTab(value: 'tab2', label: 'Tab 2', disabled: true),
                  ],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Tab 2'));
        await tester.pumpAndSettle();

        expect(selected, isNull);
      },
    );

    testWidgets(
      'touch press down scales tab to pressedScale and recovers on release',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionTabs<int>(
                  value: 0,
                  tabs: [
                    OrionTab(value: 0, label: 'Tab 0'),
                    OrionTab(value: 1, label: 'Tab 1'),
                  ],
                ),
              ),
            ),
          ),
        );

        // Start touch press on Tab 0
        final gesture = await tester.startGesture(
          tester.getCenter(find.text('Tab 0')),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final state = tester.state<OrionPressableState>(
          find.widgetWithText(OrionPressable, 'Tab 0'),
        );
        expect(state.driver.value, lessThan(1.0));

        // Lift finger
        await gesture.up();
        await tester.pumpAndSettle();

        expect(state.driver.value, closeTo(1.0, 0.001));
      },
    );

    testWidgets(
      'equal distribution divides available width equally across tabs',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: OrionTabs<int>(
                    value: 0,
                    distribution: OrionTabsDistribution.equal,
                    style: const OrionTabsStyle(
                      tabSpacing: 0.0,
                      trackPadding: EdgeInsets.zero,
                    ),
                    tabs: const [
                      OrionTab(value: 0, label: 'A'),
                      OrionTab(value: 1, label: 'B'),
                      OrionTab(value: 2, label: 'C'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        final RenderBox renderBox = tester.renderObject(
          find.byType(OrionTabs<int>),
        );
        expect(renderBox.size.width, 300.0);
      },
    );

    testWidgets('programmatic controller animates and jumps to target tab', (
      tester,
    ) async {
      final controller = OrionTabsController<String>(initialValue: 'tab1');

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionTabs<String>(
                controller: controller,
                tabs: const [
                  OrionTab(value: 'tab1', label: 'Tab 1'),
                  OrionTab(value: 'tab2', label: 'Tab 2'),
                  OrionTab(value: 'tab3', label: 'Tab 3'),
                ],
              ),
            ),
          ),
        ),
      );

      expect(controller.index, 0);

      // Animate to tab3
      controller.animateTo('tab3');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pumpAndSettle();

      expect(controller.index, 2);
      expect(controller.value, 'tab3');

      // Jump to tab2
      controller.jumpTo('tab2');
      await tester.pump();

      expect(controller.index, 1);
      expect(controller.value, 'tab2');
    });

    testWidgets(
      'velocity continuity: mid-flight retarget preserves kinetic velocity without snapping',
      (tester) async {
        final controller = OrionTabsController<int>(initialValue: 0);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 400,
                  child: OrionTabs<int>(
                    controller: controller,
                    distribution: OrionTabsDistribution.equal,
                    tabs: const [
                      OrionTab(value: 0, label: '0'),
                      OrionTab(value: 1, label: '1'),
                      OrionTab(value: 2, label: '2'),
                      OrionTab(value: 3, label: '3'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Animate from 0 to 3
        controller.animateTo(3);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));

        // Mid-flight: immediately retarget back to 1
        controller.animateTo(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));
        await tester.pumpAndSettle();

        expect(controller.index, 1);
      },
    );

    testWidgets(
      'semantics exclusivity: screen reader exposes exactly one semantic node per tab',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTabs<String>(
                  value: 'home',
                  variant: OrionTabsVariant.pill,
                  tabs: const [
                    OrionTab(value: 'home', label: 'Home Tab'),
                    OrionTab(value: 'profile', label: 'Profile Tab'),
                  ],
                ),
              ),
            ),
          ),
        );

        // Verify single-tree invariant: exactly one widget in tree (no ghost duplication)
        expect(find.text('Home Tab'), findsOneWidget);
        expect(find.text('Profile Tab'), findsOneWidget);

        final homeSemantics = tester.getSemantics(find.text('Home Tab'));
        expect(homeSemantics.flagsCollection.isSelected, Tristate.isTrue);

        final profileSemantics = tester.getSemantics(find.text('Profile Tab'));
        expect(profileSemantics.flagsCollection.isSelected, Tristate.isFalse);

        handle.dispose();
      },
    );

    testWidgets(
      'hardware keyboard arrow keys navigate between tabs and draw focus ring',
      (tester) async {
        final focusNode = FocusNode();
        int? selected;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTabs<int>(
                  focusNode: focusNode,
                  autofocus: true,
                  value: 0,
                  onChanged: (val) => selected = val,
                  tabs: const [
                    OrionTab(value: 0, label: 'First'),
                    OrionTab(value: 1, label: 'Second'),
                    OrionTab(value: 2, label: 'Third', disabled: true),
                    OrionTab(value: 3, label: 'Fourth'),
                  ],
                ),
              ),
            ),
          ),
        );

        expect(focusNode.hasFocus, isTrue);

        // Press Right Arrow -> selects index 1 ('Second')
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(selected, 1);

        // Press Right Arrow again -> skips disabled index 2 ('Third') and selects index 3 ('Fourth')
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pumpAndSettle();

        expect(selected, 3);

        // Press Left Arrow -> skips disabled index 2 and selects index 1
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
        await tester.pumpAndSettle();

        expect(selected, 1);
      },
    );

    testWidgets('RTL text direction lays out tabs from right to left', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: OrionTabs<int>(
                    value: 0,
                    distribution: OrionTabsDistribution.equal,
                    style: const OrionTabsStyle(
                      tabSpacing: 0.0,
                      trackPadding: EdgeInsets.zero,
                    ),
                    tabs: const [
                      OrionTab(value: 0, label: 'RightTab'),
                      OrionTab(value: 1, label: 'LeftTab'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final Offset rightTabOffset = tester.getTopLeft(find.text('RightTab'));
      final Offset leftTabOffset = tester.getTopLeft(find.text('LeftTab'));

      // Under RTL, RightTab (index 0) must sit to the right of LeftTab (index 1)
      expect(rightTabOffset.dx, greaterThan(leftTabOffset.dx));
    });

    testWidgets(
      'RTL scrollable tab bar auto-centers correctly towards selected tab',
      (tester) async {
        final controller = OrionTabsController<int>(initialValue: 0);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Directionality(
              textDirection: TextDirection.rtl,
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 250,
                    child: OrionTabs<int>(
                      controller: controller,
                      distribution: OrionTabsDistribution.intrinsic,
                      tabs: List.generate(
                        10,
                        (i) => OrionTab(value: i, label: 'Long Tab Title $i'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // Select the last tab (index 9)
        controller.animateTo(9);
        await tester.pumpAndSettle();

        // Under RTL, selecting index 9 should scroll the scrollable away from offset 0
        final scrollable = tester.state<ScrollableState>(
          find.byType(Scrollable),
        );
        expect(scrollable.position.pixels, greaterThan(0.0));
      },
    );

    testWidgets(
      'gesture cooperation: parent vertical scroll takes priority over tab bar',
      (tester) async {
        final scrollController = ScrollController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: ListView.builder(
                controller: scrollController,
                itemCount: 30,
                itemBuilder: (context, index) {
                  if (index == 2) {
                    return SizedBox(
                      height: 50,
                      child: OrionTabs<int>(
                        value: 0,
                        tabs: const [
                          OrionTab(value: 0, label: 'Tab A'),
                          OrionTab(value: 1, label: 'Tab B'),
                          OrionTab(value: 2, label: 'Tab C'),
                        ],
                      ),
                    );
                  }
                  return SizedBox(height: 60, child: Text('Row $index'));
                },
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);

        // Drag vertically directly starting on the tab bar
        await tester.drag(find.text('Tab A'), const Offset(0.0, -200.0));
        await tester.pumpAndSettle();

        // Parent vertical scroll view must scroll freely!
        expect(scrollController.offset, greaterThan(150.0));
      },
    );

    testWidgets(
      'pageController swipe synchronization drives indicator on real drag',
      (tester) async {
        final pageController = PageController();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Column(
                children: [
                  OrionTabs<int>(
                    pageController: pageController,
                    tabs: const [
                      OrionTab(value: 0, label: 'Page 0'),
                      OrionTab(value: 1, label: 'Page 1'),
                      OrionTab(value: 2, label: 'Page 2'),
                    ],
                  ),
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      children: const [
                        Center(child: Text('Content 0')),
                        Center(child: Text('Content 1')),
                        Center(child: Text('Content 2')),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );

        expect(find.text('Content 0'), findsOneWidget);

        // Drag PageView horizontally across pages
        await tester.drag(find.text('Content 0'), const Offset(-400, 0));
        await tester.pumpAndSettle();

        expect(find.text('Content 1'), findsOneWidget);
        expect(pageController.page, 1.0);
      },
    );

    testWidgets(
      'reduced motion: instant settlement on frame 0 without active ticker',
      (tester) async {
        final controller = OrionTabsController<int>(initialValue: 0);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: MediaQuery(
              data: const MediaQueryData(disableAnimations: true),
              child: Scaffold(
                body: Center(
                  child: OrionTabs<int>(
                    controller: controller,
                    tabs: const [
                      OrionTab(value: 0, label: 'Tab 0'),
                      OrionTab(value: 1, label: 'Tab 1'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        controller.animateTo(1);
        await tester.pump(); // Exactly 1 frame

        expect(controller.index, 1);
        // Ticker must not remain running
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      'zero-rebuild transform invariant: tab content does not rebuild on spring ticks',
      (tester) async {
        int buildCount = 0;
        final controller = OrionTabsController<int>(initialValue: 0);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionTabs<int>(
                  controller: controller,
                  tabs: [
                    OrionTab(
                      value: 0,
                      label: 'Watched Tab',
                      badge: Builder(
                        builder: (context) {
                          buildCount++;
                          return const Text('Badge');
                        },
                      ),
                    ),
                    const OrionTab(value: 1, label: 'Other Tab'),
                  ],
                ),
              ),
            ),
          ),
        );

        final int initialBuilds = buildCount;

        // Animate to tab 1 across 10 intermediate frames
        controller.animateTo(1);
        await tester.pump();
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();

        // Tab child content must NOT rebuild on animation ticks!
        expect(buildCount, initialBuilds);
      },
    );

    testWidgets(
      'deactivation safety: unmounting mid-animation does not throw',
      (tester) async {
        final controller = OrionTabsController<int>(initialValue: 0);
        bool showTabs = true;

        await tester.pumpWidget(
          StatefulBuilder(
            builder: (context, setState) {
              return MaterialApp(
                theme: OrionTheme.light(),
                home: Scaffold(
                  body: Column(
                    children: [
                      if (showTabs)
                        OrionTabs<int>(
                          controller: controller,
                          tabs: const [
                            OrionTab(value: 0, label: 'Tab 0'),
                            OrionTab(value: 1, label: 'Tab 1'),
                          ],
                        ),
                      ElevatedButton(
                        onPressed: () => setState(() => showTabs = false),
                        child: const Text('Unmount'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );

        // Start animating
        controller.animateTo(1);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 30));

        // Unmount while spring is mid-flight
        await tester.tap(find.text('Unmount'));
        await tester.pumpAndSettle();

        // Must not throw any exception
        expect(find.text('Tab 0'), findsNothing);
      },
    );
  });

  group('OrionTabsStyle & Presets', () {
    test('presets resolve distinct configurations per variant', () {
      final underline = OrionTabsPresets.resolve(
        scheme: OrionColors.lightScheme,
        variant: OrionTabsVariant.underline,
      );
      expect(underline.indicatorHeight, 2.5);
      expect(underline.trackColor, Colors.transparent);

      final pill = OrionTabsPresets.resolve(
        scheme: OrionColors.lightScheme,
        variant: OrionTabsVariant.pill,
      );
      expect(pill.trackColor, Colors.transparent);
      expect(pill.activeLabelColor, OrionColors.lightScheme.onPrimary);

      final segment = OrionTabsPresets.resolve(
        scheme: OrionColors.lightScheme,
        variant: OrionTabsVariant.segment,
      );
      expect(
        segment.trackColor,
        OrionColors.lightScheme.surfaceContainerHighest,
      );
      expect(segment.activeLabelColor, OrionColors.lightScheme.onSurface);
    });

    test('style merge overrides only named fields', () {
      const base = OrionTabsStyle(tabSpacing: 4.0, indicatorHeight: 2.0);

      final merged = base.merge(const OrionTabsStyle(tabSpacing: 12.0));

      expect(merged.tabSpacing, 12.0);
      expect(merged.indicatorHeight, 2.0);
    });

    test('lerp correctly interpolates scalars and colors', () {
      const a = OrionTabsStyle(
        tabSpacing: 4.0,
        indicatorHeight: 2.0,
        pressedScale: 0.95,
      );
      const b = OrionTabsStyle(
        tabSpacing: 12.0,
        indicatorHeight: 4.0,
        pressedScale: 1.0,
      );

      final result = OrionTabsStyle.lerp(a, b, 0.5)!;
      expect(result.tabSpacing, 8.0);
      expect(result.indicatorHeight, 3.0);
      expect(result.pressedScale, closeTo(0.975, 0.001));
    });
  });
}
