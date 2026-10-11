import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionOtpField Widget & Slots', () {
    testWidgets('renders requested number of slots', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(body: Center(child: OrionOtpField(length: 4))),
        ),
      );

      // Verify 4 slots rendered
      expect(find.byType(OrionOtpField), findsOneWidget);
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(OrionOtpField),
          matching: find.byType(Container),
        ),
      );
      // There are 4 slot containers
      expect(
        containers.where((c) => c.constraints?.maxWidth == 42.0).length,
        4,
      );
    });

    testWidgets('typing updates visual slots and invokes onChanged', (
      tester,
    ) async {
      String latestValue = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionOtpField(
                length: 4,
                onChanged: (val) => latestValue = val,
              ),
            ),
          ),
        ),
      );

      // Tap to focus
      await tester.tap(find.byType(OrionOtpField));
      await tester.pumpAndSettle();

      // Enter digits
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      expect(latestValue, '1234');
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('onCompleted fires when final slot is filled', (tester) async {
      String completedCode = '';

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionOtpField(
                length: 6,
                onCompleted: (code) => completedCode = code,
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OrionOtpField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '12345');
      await tester.pumpAndSettle();
      expect(completedCode, isEmpty);

      await tester.enterText(find.byType(TextField), '123456');
      await tester.pumpAndSettle();
      expect(completedCode, '123456');
    });

    testWidgets(
      'obscureText: true masks digits immediately when delayedObscure is false',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionOtpField(
                  length: 4,
                  obscureText: true,
                  delayedObscure: false,
                  obscureCharacter: '●',
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OrionOtpField));
        await tester.pumpAndSettle();

        await tester.enterText(find.byType(TextField), '42');
        await tester.pumpAndSettle();

        expect(find.text('4'), findsNothing);
        expect(find.text('2'), findsNothing);
        expect(find.text('●'), findsNWidgets(2));
      },
    );

    testWidgets('delayedObscure: true displays digit briefly then masks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionOtpField(
                length: 4,
                obscureText: true,
                delayedObscure: true,
                delayedObscureDuration: Duration(milliseconds: 300),
                obscureCharacter: '●',
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(OrionOtpField));
      await tester.pumpAndSettle();

      // Enter digit '7'
      await tester.enterText(find.byType(TextField), '7');
      await tester.pump(); // Immediate frame

      // Raw digit is visible inside the slot Text widget
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == '7'),
        findsOneWidget,
      );
      expect(find.text('●'), findsNothing);

      // Advance clock past delayedObscureDuration
      await tester.pump(const Duration(milliseconds: 350));

      // Now masked to bullet dot
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data == '7'),
        findsNothing,
      );
      expect(find.text('●'), findsOneWidget);
    });

    testWidgets('groupLength and groupSeparator render between slot groups', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionOtpField(
                length: 6,
                groupLength: 3,
                groupSeparator: Text('-', style: TextStyle(fontSize: 20)),
              ),
            ),
          ),
        ),
      );

      expect(find.text('-'), findsOneWidget);
    });

    testWidgets('accessibility semantics announce OTP label and value', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(body: Center(child: OrionOtpField(length: 6))),
        ),
      );

      await tester.tap(find.byType(OrionOtpField));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), '8899');
      await tester.pumpAndSettle();

      expect(
        find.bySemanticsLabel(RegExp(r'One-time passcode, 6 digits')),
        findsOneWidget,
      );

      handle.dispose();
    });
  });

  group('OrionOtpController Programmatic Control', () {
    testWidgets('controller value updates text and visual slots', (
      tester,
    ) async {
      final controller = OrionOtpController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionOtpField(length: 4, controller: controller),
            ),
          ),
        ),
      );

      expect(controller.value, '');

      // Update via controller
      controller.value = '9876';
      await tester.pumpAndSettle();

      expect(find.text('9'), findsOneWidget);
      expect(find.text('8'), findsOneWidget);
      expect(find.text('7'), findsOneWidget);
      expect(find.text('6'), findsOneWidget);

      // Clear via controller
      controller.clear();
      await tester.pumpAndSettle();

      expect(controller.value, '');
      expect(find.text('9'), findsNothing);
    });

    testWidgets('controller focus and unfocus manage keyboard focus', (
      tester,
    ) async {
      final controller = OrionOtpController();
      final focusNode = FocusNode();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionOtpField(
                length: 4,
                controller: controller,
                focusNode: focusNode,
              ),
            ),
          ),
        ),
      );

      expect(focusNode.hasFocus, isFalse);

      controller.focus();
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isTrue);

      controller.unfocus();
      await tester.pumpAndSettle();
      expect(focusNode.hasFocus, isFalse);
    });

    testWidgets('controller.shake() animates horizontal displacement', (
      tester,
    ) async {
      final controller = OrionOtpController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionOtpField(length: 4, controller: controller),
            ),
          ),
        ),
      );

      // Trigger shake
      controller.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Transform.translate has non-zero offset during shake
      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final hasDisplacement = transforms.any(
        (t) => t.transform.getTranslation().x != 0.0,
      );
      expect(hasDisplacement, isTrue);

      await tester.pumpAndSettle();
    });

    testWidgets(
      'scrollable parent wins arena during drag gesture without focus',
      (tester) async {
        final scrollController = ScrollController();
        final focusNode = FocusNode();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: ListView.builder(
                controller: scrollController,
                itemCount: 30,
                itemBuilder: (context, index) {
                  if (index == 2) {
                    return OrionOtpField(length: 4, focusNode: focusNode);
                  }
                  return SizedBox(height: 80, child: Text('Row $index'));
                },
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);
        expect(focusNode.hasFocus, isFalse);

        // Drag vertically starting directly on the OTP field
        await tester.drag(find.byType(OrionOtpField), const Offset(0, -200));
        await tester.pumpAndSettle();

        // Parent scrollable moved
        expect(scrollController.offset, greaterThan(0.0));
        // Field did not claim focus from the scroll
        expect(focusNode.hasFocus, isFalse);
      },
    );

    testWidgets('reduced motion disables spring shake', (tester) async {
      final controller = OrionOtpController();

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Center(
                child: OrionOtpField(length: 4, controller: controller),
              ),
            ),
          ),
        ),
      );

      controller.shake();
      await tester.pump(); // Frame 0

      final transforms = tester.widgetList<Transform>(find.byType(Transform));
      final hasDisplacement = transforms.any(
        (t) => t.transform.getTranslation().x != 0.0,
      );
      expect(hasDisplacement, isFalse);
    });

    testWidgets('reduced motion keeps active slot caret visible statically', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: const Scaffold(
              body: Center(child: OrionOtpField(length: 4, autoFocus: true)),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Active slot caret bar should have opacity 1.0 (visible, not 0.0)
      final opacities = tester.widgetList<Opacity>(
        find.descendant(
          of: find.byType(OrionOtpField),
          matching: find.byType(Opacity),
        ),
      );
      final caretOpacity = opacities.where((o) => o.opacity == 1.0);
      expect(caretOpacity, isNotEmpty);
    });

    testWidgets('deactivation safety: unmounting mid-shake does not throw', (
      tester,
    ) async {
      final controller = OrionOtpController();
      bool show = true;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: show
                    ? OrionOtpField(length: 4, controller: controller)
                    : const SizedBox.shrink(),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => show = false),
                ),
              );
            },
          ),
        ),
      );

      // Start shake
      controller.shake();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Remove from tree mid-flight
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.byType(OrionOtpField), findsNothing);
    });

    testWidgets('filled slots do not render last slot as active', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(child: OrionOtpField(length: 4, autoFocus: true)),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '1234');
      await tester.pumpAndSettle();

      // No caret bar should be visible when all slots are full
      final containers = tester.widgetList<Container>(
        find.descendant(
          of: find.byType(OrionOtpField),
          matching: find.byType(Container),
        ),
      );
      // All 4 slot containers are filled; none should show the caret container of width 2
      final carets = containers.where((c) => c.constraints?.maxWidth == 2.0);
      expect(carets, isEmpty);
    });

    testWidgets('didUpdateWidget updates external focusNode', (tester) async {
      final node1 = FocusNode();
      final node2 = FocusNode();
      FocusNode activeNode = node1;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: StatefulBuilder(
            builder: (context, setState) {
              return Scaffold(
                body: OrionOtpField(length: 4, focusNode: activeNode),
                floatingActionButton: FloatingActionButton(
                  onPressed: () => setState(() => activeNode = node2),
                ),
              );
            },
          ),
        ),
      );

      expect(node1.hasFocus, isFalse);
      expect(node2.hasFocus, isFalse);

      // Swap to node2
      await tester.tap(find.byType(FloatingActionButton));
      await tester.pumpAndSettle();

      node2.requestFocus();
      await tester.pumpAndSettle();
      expect(node2.hasFocus, isTrue);

      node1.dispose();
      node2.dispose();
    });

    testWidgets('renders MouseRegion with text cursor', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(body: Center(child: OrionOtpField(length: 4))),
        ),
      );

      final regions = tester.widgetList<MouseRegion>(find.byType(MouseRegion));
      expect(regions.any((r) => r.cursor == SystemMouseCursors.text), isTrue);
    });
  });

  group('OrionOtpStyle & Themes', () {
    test('presets reproduce the light scheme defaults', () {
      final style = OrionOtpPresets.resolve(scheme: OrionColors.lightScheme);

      expect(style.slotWidth, 42.0);
      expect(style.slotHeight, 52.0);
      expect(style.slotBorderWidth, 1.0);
      expect(style.activeBorderWidth, 2.0);
      expect(style.slotSpacing, 6.0);
      expect(style.groupSpacing, 14.0);
    });

    test('style merge overrides only named fields', () {
      final base = OrionOtpStyle.from(
        slotWidth: 40.0,
        backgroundColor: Colors.white,
      );

      final merged = base.merge(OrionOtpStyle.from(slotWidth: 50.0));

      expect(merged.slotWidth, 50.0);
      expect(merged.backgroundColor, Colors.white);
    });

    test('lerp correctly handles null values and interpolates scalars', () {
      const a = OrionOtpStyle(slotWidth: 40.0, slotHeight: 50.0);
      const b = OrionOtpStyle(slotWidth: 50.0, slotHeight: 60.0);

      final result = OrionOtpStyle.lerp(a, b, 0.5)!;
      expect(result.slotWidth, 45.0);
      expect(result.slotHeight, 55.0);
      expect(result.slotSpacing, isNull);
      expect(result.groupSpacing, isNull);
    });
  });
}
