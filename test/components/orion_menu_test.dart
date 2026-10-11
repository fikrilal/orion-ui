import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionMenu Widget & Items', () {
    testWidgets('renders items and dividers and executes onTap callback', (
      tester,
    ) async {
      var itemTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionMenu(
                trigger: const Text('Menu Trigger'),
                items: [
                  OrionMenuItem(
                    leading: const Icon(Icons.copy),
                    title: 'Copy',
                    subtitle: 'Copy to clipboard',
                    trailing: const Text('⌘C'),
                    onTap: () => itemTapped = true,
                  ),
                  const OrionMenuItem.divider(),
                  const OrionMenuItem(
                    leading: Icon(Icons.delete),
                    title: 'Delete',
                    destructive: true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Copy'), findsNothing);

      // Open menu
      await tester.tap(find.text('Menu Trigger'));
      await tester.pumpAndSettle();

      expect(find.text('Copy'), findsOneWidget);
      expect(find.text('Copy to clipboard'), findsOneWidget);
      expect(find.text('⌘C'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
      expect(find.byType(Divider), findsOneWidget);

      // Tap Copy item
      await tester.tap(find.text('Copy'));
      await tester.pumpAndSettle();

      expect(itemTapped, isTrue);
      expect(find.text('Copy'), findsNothing); // Closed on selection
    });

    testWidgets('disabled menu item does not invoke callback', (tester) async {
      var disabledTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionMenu(
                trigger: const Text('Menu Trigger'),
                items: [
                  OrionMenuItem(
                    title: 'Disabled Item',
                    enabled: false,
                    onTap: () => disabledTapped = true,
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Menu Trigger'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Disabled Item'));
      await tester.pumpAndSettle();

      expect(disabledTapped, isFalse);
    });

    testWidgets('destructive item renders in error color', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionMenu(
                trigger: const Text('Destructive Trigger'),
                items: const [
                  OrionMenuItem(title: 'Remove File', destructive: true),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Destructive Trigger'));
      await tester.pumpAndSettle();

      final textWidget = tester.widget<Text>(find.text('Remove File'));
      expect(textWidget.style?.color, OrionColors.lightScheme.error);
    });

    testWidgets('showOrionMenu presents modal route and returns on select', (
      tester,
    ) async {
      var selected = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionMenu<void>(
                    context: context,
                    anchorRect: const Rect.fromLTWH(100, 200, 80, 40),
                    items: [
                      OrionMenuItem(
                        title: 'Modal Item',
                        onTap: () => selected = true,
                      ),
                    ],
                  );
                },
                child: const Text('Open Modal Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal Menu'));
      await tester.pumpAndSettle();

      expect(find.text('Modal Item'), findsOneWidget);

      await tester.tap(find.text('Modal Item'));
      await tester.pumpAndSettle();

      expect(selected, isTrue);
      expect(find.text('Modal Item'), findsNothing);
    });

    testWidgets('showOrionMenu with showArrow renders arrow painter', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionMenu<void>(
                    context: context,
                    anchorRect: const Rect.fromLTWH(100, 200, 80, 40),
                    showArrow: true,
                    items: [const OrionMenuItem(title: 'Arrow Modal Item')],
                  );
                },
                child: const Text('Open Arrow Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Arrow Menu'));
      await tester.pumpAndSettle();

      final arrowFinder = find.byWidgetPredicate(
        (w) => w is CustomPaint && w.painter is OrionPopoverArrowPainter,
      );
      expect(arrowFinder, findsOneWidget);
    });

    testWidgets('menu item press feedback with real pointer down', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionMenu(
                trigger: const Text('Press Menu Trigger'),
                items: [OrionMenuItem(title: 'Pressable Item', onTap: () {})],
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Press Menu Trigger'));
      await tester.pumpAndSettle();

      // Start pointer on item
      final gesture = await tester.startGesture(
        tester.getCenter(find.text('Pressable Item')),
      );
      await tester.pump(const Duration(milliseconds: 40));

      // OrionPressable compresses to 0.98
      final pressableFinder = find.byType(OrionPressable);
      expect(pressableFinder, findsOneWidget);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('showOrionMenu returns typed value on animated dismiss', (
      tester,
    ) async {
      String? returnedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedValue = await showOrionMenu<String>(
                    context: context,
                    anchorRect: const Rect.fromLTWH(100, 200, 80, 40),
                    items: [
                      const OrionMenuItem(
                        title: 'Select Item',
                        value: 'selected_val',
                      ),
                    ],
                  );
                },
                child: const Text('Open Typed Menu'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Typed Menu'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Select Item'));
      await tester.pumpAndSettle();

      expect(returnedValue, 'selected_val');
      expect(find.text('Select Item'), findsNothing);
    });

    testWidgets(
      'single-line menu row satisfies minimum 44 pt accessibility height',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionMenu(
                  trigger: const Text('Touch Target Trigger'),
                  items: const [OrionMenuItem(title: 'Single Line Item')],
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Touch Target Trigger'));
        await tester.pumpAndSettle();

        final rowFinder = find.byType(OrionPressable);
        expect(rowFinder, findsOneWidget);

        final RenderBox rowBox = tester.renderObject(rowFinder);
        expect(rowBox.size.height, greaterThanOrEqualTo(44.0));
      },
    );

    testWidgets(
      'scroll cooperation: drag inside parent scrollable moves list while menu remains closed',
      (tester) async {
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
                    return OrionMenu(
                      trigger: Container(
                        height: 60,
                        color: Colors.blue,
                        alignment: Alignment.center,
                        child: const Text('Scrollable Menu Trigger'),
                      ),
                      items: const [OrionMenuItem(title: 'Menu Item')],
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

        // Drag list upward across the menu trigger
        await tester.drag(
          find.text('Scrollable Menu Trigger'),
          const Offset(0, -200),
        );
        await tester.pumpAndSettle();

        // List scrolls and menu remains closed
        expect(scrollController.offset, greaterThan(0.0));
        expect(find.text('Menu Item'), findsNothing);
      },
    );

    testWidgets(
      'dismissOnScroll: dragging on barrier dismisses modal showOrionMenu',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showOrionMenu<void>(
                      context: context,
                      anchorRect: const Rect.fromLTWH(100, 200, 80, 40),
                      items: const [OrionMenuItem(title: 'Modal Item')],
                    );
                  },
                  child: const Text('Open Menu For Scroll'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Menu For Scroll'));
        await tester.pumpAndSettle();

        expect(find.text('Modal Item'), findsOneWidget);

        // Drag outside on the barrier
        await tester.dragFrom(const Offset(20, 20), const Offset(0, 100));
        await tester.pumpAndSettle();

        expect(find.text('Modal Item'), findsNothing);
      },
    );
  });
}
