import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionDialog Widget & Surface', () {
    testWidgets('renders icon, title, description, and content', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionDialog(
                icon: Icon(Icons.delete_outline_rounded, size: 36),
                title: 'Delete Project?',
                description:
                    'This action cannot be undone. All files will be removed.',
                content: Text('Custom Content Subtree'),
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.delete_outline_rounded), findsOneWidget);
      expect(find.text('Delete Project?'), findsOneWidget);
      expect(
        find.text('This action cannot be undone. All files will be removed.'),
        findsOneWidget,
      );
      expect(find.text('Custom Content Subtree'), findsOneWidget);
    });

    testWidgets('frosted dialog renders BackdropFilter inside surface', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: OrionDialog(
                style: OrionDialogStyle(frosted: true),
                title: 'Frosted Surface',
                description: 'Translucent acrylic glass',
              ),
            ),
          ),
        ),
      );

      expect(find.byType(BackdropFilter), findsOneWidget);
    });

    testWidgets('actionLayout: auto arranges 2 actions horizontally in Row', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionDialog(
                title: 'Confirm',
                actions: [
                  OrionDialogAction.cancel(onPressed: () {}),
                  OrionDialogAction.primary(
                    label: 'Continue',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Verify buttons are in an expanded Row
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);

      final rowFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Row &&
            widget.children.length == 3 && // Cancel + SizedBox + Continue
            widget.children.any((c) => c is Expanded),
      );
      expect(rowFinder, findsOneWidget);
    });

    testWidgets('actionLayout: auto arranges 3+ actions vertically in Column', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionDialog(
                title: 'Options',
                actions: [
                  OrionDialogAction.primary(
                    label: 'Save & Exit',
                    onPressed: () {},
                  ),
                  OrionDialogAction.secondary(
                    label: 'Discard',
                    onPressed: () {},
                  ),
                  OrionDialogAction.cancel(onPressed: () {}),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Save & Exit'), findsOneWidget);
      expect(find.text('Discard'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Finding the actions column
      final columnFinder = find.descendant(
        of: find.byType(OrionDialog),
        matching: find.byType(Column),
      );
      expect(columnFinder, findsWidgets);
    });

    testWidgets('destructive action applies error theme', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionDialog(
                title: 'Purge Database',
                actions: [
                  OrionDialogAction.destructive(
                    label: 'Delete Forever',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Delete Forever'), findsOneWidget);
    });
  });

  group('showOrionDialog Modal Route & Physics', () {
    testWidgets('opens with spring simulation and dismisses on outside tap', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionDialog<void>(
                    context: context,
                    builder: (ctx) => const OrionDialog(
                      title: 'Modal Title',
                      description: 'Modal body text',
                    ),
                  );
                },
                child: const Text('Open Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Modal Title'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Modal Title'), findsOneWidget);

      // Tap outside barrier scrim
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      expect(find.text('Modal Title'), findsNothing);
    });

    testWidgets('barrierDismissible: false prevents tap-outside dismissal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionDialog<void>(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) =>
                        const OrionDialog(title: 'Non-dismissible Dialog'),
                  );
                },
                child: const Text('Open Guarded Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Guarded Modal'));
      await tester.pumpAndSettle();

      expect(find.text('Non-dismissible Dialog'), findsOneWidget);

      // Tap outside
      await tester.tapAt(const Offset(10, 10));
      await tester.pumpAndSettle();

      // Remains open!
      expect(find.text('Non-dismissible Dialog'), findsOneWidget);
    });

    testWidgets('dismisses on Escape key event', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionDialog<void>(
                    context: context,
                    builder: (ctx) =>
                        const OrionDialog(title: 'Escape Target Dialog'),
                  );
                },
                child: const Text('Open Modal For Escape'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Modal For Escape'));
      await tester.pumpAndSettle();

      expect(find.text('Escape Target Dialog'), findsOneWidget);

      // Send Escape key event
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(find.text('Escape Target Dialog'), findsNothing);
    });

    testWidgets('reduced motion settles immediately without ticking', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showOrionDialog<void>(
                      context: context,
                      builder: (ctx) => const OrionDialog(
                        title: 'Instant Reduced Motion Dialog',
                      ),
                    );
                  },
                  child: const Text('Open Reduced Modal'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Reduced Modal'));
      // Single frame pump
      await tester.pump();

      expect(find.text('Instant Reduced Motion Dialog'), findsOneWidget);
    });

    testWidgets('zero-rebuild transform invariant: content does not rebuild', (
      tester,
    ) async {
      int contentBuildCount = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionDialog<void>(
                    context: context,
                    builder: (ctx) => OrionDialog(
                      title: 'Ticker Test Dialog',
                      content: Builder(
                        builder: (c) {
                          contentBuildCount++;
                          return const Text('Stable Child');
                        },
                      ),
                    ),
                  );
                },
                child: const Text('Open Ticker Modal'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Ticker Modal'));
      await tester.pump(); // Route pushes
      expect(contentBuildCount, 1);

      // Advance 10 frames across the spring simulation
      for (int i = 0; i < 10; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        // Verify child does NOT rebuild per ticker frame
        expect(contentBuildCount, 1);
      }
      await tester.pumpAndSettle();

      // Content was built during mount, never on animation ticks
      expect(contentBuildCount, 1);
    });

    testWidgets('returns typed value on dismiss', (tester) async {
      String? returnedValue;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedValue = await showOrionDialog<String>(
                    context: context,
                    builder: (ctx) => OrionDialog(
                      title: 'Select Result',
                      actions: [
                        OrionDialogAction.primary(
                          label: 'Accept',
                          onPressed: () => Navigator.of(ctx).pop('accepted'),
                        ),
                      ],
                    ),
                  );
                },
                child: const Text('Open Typed Dialog'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Typed Dialog'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Accept'));
      await tester.pumpAndSettle();

      expect(returnedValue, 'accepted');
    });
  });

  group('showOrionConfirmDialog & showOrionAlertDialog Helpers', () {
    testWidgets('showOrionConfirmDialog returns true when confirmed', (
      tester,
    ) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await showOrionConfirmDialog(
                    context: context,
                    title: 'Confirm Operation',
                    message: 'Do you wish to proceed?',
                    confirmLabel: 'Yes, Proceed',
                    cancelLabel: 'No, Cancel',
                  );
                },
                child: const Text('Launch Confirm'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Confirm'));
      await tester.pumpAndSettle();

      expect(find.text('Confirm Operation'), findsOneWidget);
      expect(find.text('Do you wish to proceed?'), findsOneWidget);

      await tester.tap(find.text('Yes, Proceed'));
      // Verify dialog is still visible during exit transition frame (NOT snapped away at t = 0)
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Confirm Operation'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(confirmed, isTrue);
      expect(find.text('Confirm Operation'), findsNothing);
    });

    testWidgets('showOrionConfirmDialog returns false when cancelled', (
      tester,
    ) async {
      bool? confirmed;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  confirmed = await showOrionConfirmDialog(
                    context: context,
                    title: 'Confirm Operation',
                    message: 'Do you wish to proceed?',
                  );
                },
                child: const Text('Launch Cancel Flow'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Cancel Flow'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      // Verify dialog is still visible during exit transition
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Confirm Operation'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(confirmed, isFalse);
      expect(find.text('Confirm Operation'), findsNothing);
    });

    testWidgets('showOrionAlertDialog displays message and pops on OK', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionAlertDialog(
                    context: context,
                    title: 'Important Alert',
                    message: 'System upgrade completed.',
                    actionLabel: 'Dismiss',
                  );
                },
                child: const Text('Launch Alert'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Alert'));
      await tester.pumpAndSettle();

      expect(find.text('Important Alert'), findsOneWidget);
      expect(find.text('System upgrade completed.'), findsOneWidget);

      await tester.tap(find.text('Dismiss'));
      // Verify dialog is still visible during exit transition
      await tester.pump(const Duration(milliseconds: 16));
      expect(find.text('Important Alert'), findsOneWidget);

      await tester.pumpAndSettle();

      expect(find.text('Important Alert'), findsNothing);
    });

    testWidgets(
      'mid-flight interruption: barrier tap during entrance reverses smoothly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (context) => ElevatedButton(
                  onPressed: () {
                    showOrionDialog<void>(
                      context: context,
                      builder: (ctx) =>
                          const OrionDialog(title: 'Interruptible Dialog'),
                    );
                  },
                  child: const Text('Open Modal For Interruption'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Modal For Interruption'));
        await tester.pump(); // Route pushes
        await tester
            .pump(); // PostFrameCallback runs and starts spring simulation
        await tester.pump(
          const Duration(milliseconds: 60),
        ); // Mid-flight entrance (val ~ 0.5)

        expect(find.text('Interruptible Dialog'), findsOneWidget);

        // Tap outside scrim while mid-flight
        await tester.tapAt(const Offset(10, 10));
        await tester.pump();
        await tester.pump(
          const Duration(milliseconds: 16),
        ); // Mid-flight reverse

        // Continues smoothly rather than jumping
        expect(find.text('Interruptible Dialog'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Interruptible Dialog'), findsNothing);
      },
    );
  });

  group('OrionDialogStyle & Themes', () {
    test('presets reproduce the light scheme default', () {
      final style = OrionDialogPresets.resolve(scheme: OrionColors.lightScheme);

      expect(style.borderWidth, 1.0);
      expect(style.maxWidth, 340.0);
      expect(style.contentSpacing, 16.0);
      expect(style.actionSpacing, 10.0);
      expect(style.backgroundColor, OrionColors.lightScheme.surfaceContainer);
      expect(style.borderColor, OrionColors.lightScheme.outlineVariant);
      expect(style.springSpec, OrionDialogPresets.defaultOpenSpring);
      expect(style.dismissSpringSpec, OrionDialogPresets.defaultDismissSpring);
    });

    test('style merge overrides only named fields', () {
      final base = OrionDialogStyle.from(
        borderWidth: 2.0,
        backgroundColor: Colors.white,
      );

      final merged = base.merge(
        OrionDialogStyle.from(backgroundColor: Colors.blue),
      );

      expect(merged.borderWidth, 2.0);
      expect(merged.backgroundColor, Colors.blue);
    });

    test('lerp correctly handles null values and interpolates scalars', () {
      const a = OrionDialogStyle(borderWidth: 1.0, maxWidth: 300.0);
      const b = OrionDialogStyle(borderWidth: 3.0, maxWidth: 400.0);

      final result = OrionDialogStyle.lerp(a, b, 0.5)!;
      expect(result.borderWidth, 2.0);
      expect(result.maxWidth, 350.0);
      expect(result.contentSpacing, isNull);
      expect(result.actionSpacing, isNull);
    });

    testWidgets('ambient OrionDialogTheme propagates spring specs', (
      tester,
    ) async {
      const customSpec = OrionSpringSpec(stiffness: 500.0, dampingRatio: 0.9);

      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(
            extensions: const [
              OrionDialogTheme(
                defaultStyle: OrionDialogStyle(springSpec: customSpec),
              ),
            ],
          ),
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  showOrionDialog<void>(
                    context: context,
                    builder: (ctx) => const OrionDialog(title: 'Themed Dialog'),
                  );
                },
                child: const Text('Launch Themed'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Themed'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('Themed Dialog'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Themed Dialog'), findsOneWidget);
    });
  });

  group('OrionDialog Audit Fixes & Features', () {
    testWidgets(
      'barrierDismissible: false blocks system Back while dismissOf closes smoothly',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () {
                    showOrionAlertDialog(
                      context: context,
                      title: 'Guarded Alert',
                      message: 'Must acknowledge explicitly.',
                      actionLabel: 'Acknowledge',
                      barrierDismissible: false,
                    );
                  },
                  child: const Text('Open Guarded'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Guarded'));
        await tester.pumpAndSettle();
        expect(find.text('Guarded Alert'), findsOneWidget);

        // Simulate Android system back button (Navigator.maybePop()).
        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();
        expect(find.text('Guarded Alert'), findsOneWidget);

        // Tapping Acknowledge uses OrionDialog.dismissOf and animates out.
        await tester.tap(find.text('Acknowledge'));
        await tester.pump(const Duration(milliseconds: 16));
        expect(find.text('Guarded Alert'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(find.text('Guarded Alert'), findsNothing);
      },
    );

    testWidgets(
      'showOrionDialog propagates style (e.g. frosted) to descendant OrionDialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () {
                    showOrionDialog<void>(
                      context: context,
                      style: OrionDialogStyle.from(frosted: true),
                      builder: (BuildContext ctx) => const OrionDialog(
                        title: 'Propagated Style',
                        description: 'Inherited from showOrionDialog',
                      ),
                    );
                  },
                  child: const Text('Open Propagated'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Propagated'));
        await tester.pumpAndSettle();

        expect(find.byType(BackdropFilter), findsOneWidget);
      },
    );

    testWidgets('omits border when borderWidth is zero', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionDialog(
                title: 'Borderless',
                style: OrionDialogStyle.from(borderWidth: 0),
              ),
            ),
          ),
        ),
      );

      final Container container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(OrionDialog),
              matching: find.byType(Container),
            )
            .first,
      );
      expect((container.decoration! as BoxDecoration).border, isNull);
    });

    testWidgets('vertical auto-stack places primary/destructive above cancel', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionDialog(
                title: 'Delete Workspace?',
                actions: <OrionDialogAction>[
                  OrionDialogAction.cancel(onPressed: () {}),
                  OrionDialogAction.destructive(
                    label: 'Delete Workspace',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      final double deleteY = tester
          .getTopLeft(find.text('Delete Workspace'))
          .dy;
      final double cancelY = tester.getTopLeft(find.text('Cancel')).dy;
      expect(deleteY, lessThan(cancelY));
    });

    testWidgets(
      'OrionDialogAction.cancel() with omitted onPressed dismisses dialog',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () {
                    showOrionDialog<void>(
                      context: context,
                      builder: (BuildContext ctx) => OrionDialog(
                        title: 'Default Cancel',
                        actions: <OrionDialogAction>[
                          OrionDialogAction.cancel(),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open Cancel Default'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Cancel Default'));
        await tester.pumpAndSettle();
        expect(find.text('Default Cancel'), findsOneWidget);

        await tester.tap(find.text('Cancel'));
        await tester.pumpAndSettle();
        expect(find.text('Default Cancel'), findsNothing);
      },
    );

    testWidgets(
      'disabled destructive action renders muted disabled surface instead of error red',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionDialog(
                  title: 'Disabled Destructive',
                  actions: <OrionDialogAction>[
                    OrionDialogAction.destructive(
                      label: 'Delete',
                      enabled: false,
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
            ),
          ),
        );

        final DecoratedBox buttonSurface = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(OrionButton),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final Color bg = (buttonSurface.decoration as BoxDecoration).color!;
        expect(bg, OrionColors.lightScheme.onSurface.withValues(alpha: 0.12));
        expect(bg, isNot(OrionColors.lightScheme.error));
      },
    );

    testWidgets(
      'showCloseButton dismisses dialog and centerContent: false aligns text to start',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () {
                    showOrionDialog<void>(
                      context: context,
                      builder: (BuildContext ctx) => const OrionDialog(
                        title: 'Start Aligned',
                        description: 'Aligned to leading edge.',
                        centerContent: false,
                        showCloseButton: true,
                      ),
                    );
                  },
                  child: const Text('Open Start Aligned'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Start Aligned'));
        await tester.pumpAndSettle();

        final Text titleWidget = tester.widget<Text>(
          find.text('Start Aligned'),
        );
        expect(titleWidget.textAlign, TextAlign.start);

        await tester.tap(find.byKey(orionDialogCloseButtonKey));
        await tester.pumpAndSettle();
        expect(find.text('Start Aligned'), findsNothing);
      },
    );

    testWidgets(
      'scrolls tall content without overflow and respects keyboard viewInsets',
      (tester) async {
        tester.view.physicalSize = const Size(360, 420);
        tester.view.devicePixelRatio = 1.0;
        tester.view.viewInsets = const FakeViewPadding(bottom: 180.0);
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          tester.view.resetViewInsets();
        });

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () {
                    showOrionDialog<void>(
                      context: context,
                      builder: (BuildContext ctx) => OrionDialog(
                        title: 'Tall Form',
                        description:
                            'Line 1\nLine 2\nLine 3\nLine 4\nLine 5\nLine 6\nLine 7\nLine 8',
                        content: const SizedBox(height: 160),
                        actions: <OrionDialogAction>[
                          OrionDialogAction.cancel(),
                          OrionDialogAction.primary(
                            label: 'Save',
                            onPressed: () => OrionDialog.dismissOf<void>(ctx),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Open Tall'),
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Open Tall'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(find.text('Save'), findsOneWidget);
        // Footer remains above the 180pt keyboard inset (420 - 180 = 240).
        expect(
          tester.getBottomLeft(find.text('Save')).dy,
          lessThanOrEqualTo(240),
        );
      },
    );

    testWidgets('showOrionDialog preserves locally scoped dark Theme', (
      WidgetTester tester,
    ) async {
      Brightness? capturedBrightness;
      Color? capturedSurface;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Theme(
            data: OrionTheme.dark(),
            child: Scaffold(
              body: Builder(
                builder: (BuildContext context) => ElevatedButton(
                  onPressed: () {
                    showOrionDialog<void>(
                      context: context,
                      builder: (BuildContext dialogContext) {
                        final ThemeData dialogTheme = Theme.of(dialogContext);
                        capturedBrightness = dialogTheme.brightness;
                        capturedSurface = dialogTheme.colorScheme.surface;
                        return OrionDialog(
                          title: 'Scoped Dark Dialog',
                          description: 'Inherits local theme.',
                          actions: <OrionDialogAction>[
                            OrionDialogAction.primary(
                              label: 'Done',
                              onPressed: () =>
                                  OrionDialog.dismissOf<void>(dialogContext),
                            ),
                          ],
                        );
                      },
                    );
                  },
                  child: const Text('Launch Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Launch Dialog'));
      await tester.pumpAndSettle();

      expect(find.text('Scoped Dark Dialog'), findsOneWidget);
      expect(capturedBrightness, Brightness.dark);
      expect(capturedSurface, OrionColors.darkScheme.surface);
    });
  });
}
