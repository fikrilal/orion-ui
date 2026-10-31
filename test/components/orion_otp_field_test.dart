import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
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

    testWidgets(
      'obscureText masks semantics value and sets obscured flag without leaking PIN',
      (tester) async {
        final handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionOtpField(
                  length: 4,
                  obscureText: true,
                  delayedObscure: false,
                  semanticLabel: 'Transaction PIN',
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OrionOtpField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '7391');
        await tester.pumpAndSettle();

        final SemanticsNode node = tester.getSemantics(
          find.bySemanticsLabel('Transaction PIN'),
        );
        expect(node.flagsCollection.isObscured, isTrue);
        expect(node.value, '●●●●');
        expect(node.value.contains('7'), isFalse);

        // Hidden TextField also receives obscureText & disables autocorrect/suggestions.
        final TextField tf = tester.widget<TextField>(find.byType(TextField));
        expect(tf.obscureText, isTrue);
        expect(tf.autocorrect, isFalse);
        expect(tf.enableSuggestions, isFalse);
        expect(tf.autofillHints, isNull);

        handle.dispose();
      },
    );

    testWidgets(
      'pasting formatted codes like 123-456 strips separators before length cap',
      (tester) async {
        String completed = '';
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionOtpField(
                  length: 6,
                  onCompleted: (String code) => completed = code,
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.byType(OrionOtpField));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '123-456');
        await tester.pumpAndSettle();

        expect(completed, '123456');
        expect(find.text('6'), findsOneWidget);
      },
    );

    testWidgets(
      'long-press Paste menu and PasteTextIntent paste formatted clipboard codes',
      (tester) async {
        String clipboardText = '123 456';
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          (MethodCall call) async {
            if (call.method == 'Clipboard.getData') {
              return <String, dynamic>{'text': clipboardText};
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

        final OrionOtpController controller = OrionOtpController();
        addTearDown(controller.dispose);
        String completed = '';

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionOtpField(
                  length: 6,
                  controller: controller,
                  onCompleted: (String code) => completed = code,
                ),
              ),
            ),
          ),
        );

        // Long-press shows native Paste button and fills sanitized code.
        await tester.longPress(find.byType(OrionOtpField));
        await tester.pumpAndSettle();

        expect(find.text('Paste'), findsOneWidget);
        await tester.tap(find.text('Paste'));
        await tester.pumpAndSettle();

        expect(controller.value, '123456');
        expect(completed, '123456');

        // PasteTextIntent replaces an already-full wrong code cleanly.
        clipboardText = '654-321';
        final BuildContext tfContext = tester.element(find.byType(TextField));
        Actions.invoke(
          tfContext,
          const PasteTextIntent(SelectionChangedCause.keyboard),
        );
        await tester.pumpAndSettle();

        expect(controller.value, '654321');
        expect(completed, '654321');
      },
    );

    testWidgets(
      'responsive scaling fits 6-digit grouped and 8-digit codes in narrow widths without overflow',
      (tester) async {
        for (final (int len, int? group, double width) in <(int, int?, double)>[
          (6, 3, 240.0),
          (8, 4, 280.0),
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              theme: OrionTheme.light(),
              home: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: width,
                    child: OrionOtpField(
                      length: len,
                      groupLength: group,
                      groupSeparator: const Text('—'),
                    ),
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: '$len slots in $width px must not overflow',
          );
        }
      },
    );

    testWidgets('preserves left-to-right digit order inside RTL locales', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: OrionOtpField(
                  length: 4,
                  controller: OrionOtpController(initialValue: '1234'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final double x1 = tester.getCenter(find.text('1')).dx;
      final double x4 = tester.getCenter(find.text('4')).dx;
      expect(x1, lessThan(x4));
    });

    testWidgets(
      'sanitizes programmatic controller values, handles swap, and clamps on length shrink',
      (tester) async {
        final OrionOtpController c1 = OrionOtpController();
        final OrionOtpController c2 = OrionOtpController(initialValue: '98-76');
        addTearDown(c1.dispose);
        addTearDown(c2.dispose);

        OrionOtpController? activeController;
        int activeLength = 6;
        String? completed;

        late StateSetter setHostState;
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                setHostState = setState;
                return Scaffold(
                  body: Center(
                    child: OrionOtpField(
                      length: activeLength,
                      controller: activeController,
                      onCompleted: (String code) => completed = code,
                    ),
                  ),
                );
              },
            ),
          ),
        );

        // Swap from null (internal controller) to c1.
        setHostState(() => activeController = c1);
        await tester.pumpAndSettle();

        // Write dirty over-long string programmatically -> sanitized & clamped.
        c1.value = '12ab345678';
        await tester.pumpAndSettle();
        expect(c1.value, '123456');
        expect(completed, '123456');

        final TextField tf = tester.widget<TextField>(find.byType(TextField));
        expect(tf.controller!.selection.baseOffset, 6);

        // Shrink length 6 -> 4 clamps value cleanly.
        setHostState(() => activeLength = 4);
        await tester.pumpAndSettle();
        expect(c1.value, '1234');

        // Swap c1 -> c2 syncs c2's sanitized value.
        setHostState(() => activeController = c2);
        await tester.pumpAndSettle();
        expect(c2.value, '9876');
        expect(find.text('9'), findsOneWidget);
        expect(find.text('6'), findsOneWidget);
      },
    );

    testWidgets(
      'toggling delayedObscure off mid-peek masks immediately',
      (tester) async {
        bool delayed = true;
        late StateSetter setHostState;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                setHostState = setState;
                return Scaffold(
                  body: Center(
                    child: OrionOtpField(
                      length: 4,
                      obscureText: true,
                      delayedObscure: delayed,
                      delayedObscureDuration: const Duration(milliseconds: 500),
                    ),
                  ),
                );
              },
            ),
          ),
        );

        await tester.tap(find.byType(OrionOtpField));
        await tester.pump();
        await tester.enterText(find.byType(TextField), '5');
        await tester.pump();
        expect(
          find.byWidgetPredicate((Widget w) => w is Text && w.data == '5'),
          findsOneWidget,
        );

        setHostState(() => delayed = false);
        await tester.pump();
        expect(
          find.byWidgetPredicate((Widget w) => w is Text && w.data == '5'),
          findsNothing,
        );
        expect(find.text('●'), findsOneWidget);
      },
    );

    testWidgets(
      'supports outline, filled, underline variants, placeholder, label, helper, and error',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OrionOtpField(
                    length: 4,
                    variant: OrionOtpVariant.filled,
                    label: 'Security PIN',
                    helper: '4 digits',
                    placeholder: '–',
                  ),
                  SizedBox(height: 16),
                  OrionOtpField(
                    length: 4,
                    variant: OrionOtpVariant.underline,
                    error: 'Code expired',
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Security PIN'), findsOneWidget);
        expect(find.text('4 digits'), findsOneWidget);
        expect(find.text('–'), findsNWidgets(4));
        expect(find.text('Code expired'), findsOneWidget);
      },
    );

    testWidgets(
      'renders disabled visuals, respects readOnly, and invokes onSubmitted',
      (tester) async {
        String submitted = '';
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  OrionOtpField(
                    length: 4,
                    enabled: false,
                    controller: OrionOtpController(initialValue: '42'),
                  ),
                  OrionOtpField(
                    length: 4,
                    readOnly: true,
                    controller: OrionOtpController(initialValue: '12'),
                  ),
                  OrionOtpField(
                    length: 4,
                    digitsOnly: false,
                    onSubmitted: (String value) => submitted = value,
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Disabled digit uses muted 0.38 alpha color.
        final Text disabledDigit = tester.widget<Text>(find.text('4'));
        expect(
          disabledDigit.style?.color,
          OrionColors.lightScheme.onSurface.withValues(alpha: 0.38),
        );

        // ReadOnly field hides caret even when tapped/focused.
        await tester.tap(find.byType(OrionOtpField).at(1));
        await tester.pumpAndSettle();
        final Iterable<Container> readOnlyCarets = tester
            .widgetList<Container>(
              find.descendant(
                of: find.byType(OrionOtpField).at(1),
                matching: find.byType(Container),
              ),
            )
            .where((Container c) => c.constraints?.maxWidth == 2.0);
        expect(readOnlyCarets, isEmpty);

        // Alphanumeric field accepts letters and triggers onSubmitted.
        final Finder alphaTf = find.byType(TextField).at(2);
        await tester.enterText(alphaTf, 'A7B2');
        await tester.testTextInput.receiveAction(TextInputAction.done);
        await tester.pumpAndSettle();
        expect(submitted, 'A7B2');
      },
    );
  });

  group('OrionOtpStyle & Themes', () {
    test('presets reproduce light defaults and provide crisp dark & success roles', () {
      final style = OrionOtpPresets.resolve(scheme: OrionColors.lightScheme);

      expect(style.slotWidth, 42.0);
      expect(style.slotHeight, 52.0);
      expect(style.slotBorderWidth, 1.0);
      expect(style.activeBorderWidth, 2.0);
      expect(style.slotSpacing, 6.0);
      expect(style.groupSpacing, 14.0);
      expect(style.borderColor, OrionColors.lightScheme.outline);
      expect(style.successBorderColor, isNot(OrionColors.lightScheme.primary));

      final darkStyle = OrionOtpPresets.resolve(scheme: OrionColors.darkScheme);
      expect(darkStyle.backgroundColor, OrionColors.darkScheme.surfaceContainer);
      expect(darkStyle.borderColor, OrionColors.darkScheme.outline);
      expect(darkStyle.successBorderColor, isNot(OrionColors.darkScheme.primary));

      final filledStyle = OrionOtpPresets.resolve(
        scheme: OrionColors.lightScheme,
        variant: OrionOtpVariant.filled,
      );
      expect(filledStyle.slotBorderWidth, 0.0);

      final underlineStyle = OrionOtpPresets.resolve(
        scheme: OrionColors.lightScheme,
        variant: OrionOtpVariant.underline,
      );
      expect(underlineStyle.slotBorderRadius, BorderRadius.zero);
    });

    test('style merge overrides only named fields and merges TextStyle', () {
      final base = OrionOtpPresets.resolve(scheme: OrionColors.darkScheme);

      final merged = base.merge(
        OrionOtpStyle.from(
          slotWidth: 50.0,
          textStyle: const TextStyle(fontSize: 24.0),
        ),
      );

      expect(merged.slotWidth, 50.0);
      expect(merged.backgroundColor, base.backgroundColor);
      expect(merged.textStyle?.fontSize, 24.0);
      expect(
        merged.textStyle?.color,
        OrionColors.darkScheme.onSurface,
        reason: 'partial textStyle override preserves inherited dark color',
      );
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
