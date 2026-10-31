import 'dart:ui' show CheckedState, PointerDeviceKind, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

enum _Plan { monthly, yearly, lifetime }

const List<OrionRadioOption<_Plan>> _planOptions = <OrionRadioOption<_Plan>>[
  OrionRadioOption<_Plan>(
    value: _Plan.monthly,
    label: 'Monthly',
    subtitle: r'$12 per month',
    trailing: Text(r'$12'),
  ),
  OrionRadioOption<_Plan>(
    value: _Plan.yearly,
    label: 'Yearly',
    subtitle: r'$99 per year',
    trailing: Text(r'$99'),
  ),
  OrionRadioOption<_Plan>(
    value: _Plan.lifetime,
    label: 'Lifetime',
    subtitle: r'$249 once',
    trailing: Text(r'$249'),
  ),
];

void main() {
  group('OrionRadioGroup', () {
    testWidgets('selects options by tapping labels and exposes semantics', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      _Plan? selected = _Plan.monthly;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return OrionRadioGroup<_Plan>(
                  label: 'Billing cycle',
                  helper: 'Switch plans anytime',
                  value: selected,
                  options: _planOptions,
                  onChanged: (_Plan next) => setState(() => selected = next),
                );
              },
            ),
          ),
        ),
      );

      expect(find.text('Billing cycle'), findsOneWidget);
      expect(find.text('Switch plans anytime'), findsOneWidget);
      expect(find.text('Monthly'), findsOneWidget);
      expect(find.text('Yearly'), findsOneWidget);

      await tester.tap(find.text('Yearly'));
      await tester.pumpAndSettle();
      expect(selected, _Plan.yearly);

      final List<SemanticsNode> radioNodes = tester
          .widgetList<OrionRadio>(find.byType(OrionRadio))
          .map(
            (OrionRadio widget) => tester.getSemantics(find.byWidget(widget)),
          )
          .toList();
      expect(radioNodes[0].flagsCollection.isChecked, CheckedState.isFalse);
      expect(radioNodes[1].flagsCollection.isChecked, CheckedState.isTrue);
      expect(radioNodes[1].flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      expect(radioNodes[2].flagsCollection.isChecked, CheckedState.isFalse);
      handle.dispose();
    });

    testWidgets('supports nullable initial value before first selection', (
      tester,
    ) async {
      _Plan? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return OrionRadioGroup<_Plan>(
                  value: selected,
                  options: _planOptions,
                  onChanged: (_Plan next) => setState(() => selected = next),
                );
              },
            ),
          ),
        ),
      );

      for (final OrionRadio radio in tester.widgetList<OrionRadio>(
        find.byType(OrionRadio),
      )) {
        expect(radio.value, isFalse);
      }

      await tester.tap(find.text('Lifetime'));
      await tester.pumpAndSettle();
      expect(selected, _Plan.lifetime);
    });

    testWidgets('respects per-option and group-level disabled states', (
      tester,
    ) async {
      _Plan? selected = _Plan.monthly;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (BuildContext context, StateSetter setState) {
                return OrionRadioGroup<_Plan>(
                  value: selected,
                  options: const <OrionRadioOption<_Plan>>[
                    OrionRadioOption<_Plan>(
                      value: _Plan.monthly,
                      label: 'Monthly',
                    ),
                    OrionRadioOption<_Plan>(
                      value: _Plan.yearly,
                      label: 'Yearly',
                      enabled: false,
                    ),
                  ],
                  onChanged: (_Plan next) => setState(() => selected = next),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Yearly'));
      await tester.pump();
      expect(selected, _Plan.monthly);

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionRadioGroup<_Plan>(
              value: selected,
              enabled: false,
              options: _planOptions,
              onChanged: (_Plan next) => selected = next,
            ),
          ),
        ),
      );

      await tester.tap(find.text('Lifetime'));
      await tester.pump();
      expect(selected, _Plan.monthly);
    });

    testWidgets('renders selectable cards with border highlight and haptics', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> haptics = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            haptics.add(call.arguments.toString());
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

      _Plan? selected = _Plan.monthly;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return OrionRadioGroup<_Plan>(
                    variant: OrionRadioGroupVariant.card,
                    value: selected,
                    options: _planOptions,
                    onChanged: (_Plan next) => setState(() => selected = next),
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Retapping already-selected card stays silent.
      await tester.tap(find.text('Monthly'));
      await tester.pump();
      expect(haptics, isEmpty);

      // Tapping another card updates selection and emits one haptic.
      await tester.tap(find.text(r'$99'));
      await tester.pumpAndSettle();
      expect(selected, _Plan.yearly);
      expect(haptics, <String>['HapticFeedbackType.selectionClick']);

      // Hovering unselected card updates smoothly without exceptions.
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.text('Lifetime')));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      handle.dispose();
    });

    testWidgets('renders horizontal plain and card layouts without overflow', (
      tester,
    ) async {
      _Plan selected = _Plan.monthly;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionRadioGroup<_Plan>(
                    direction: Axis.horizontal,
                    value: selected,
                    options: _planOptions,
                    onChanged: (_Plan next) => selected = next,
                  ),
                  const SizedBox(height: 16),
                  OrionRadioGroup<_Plan>(
                    direction: Axis.horizontal,
                    variant: OrionRadioGroupVariant.card,
                    value: selected,
                    options: _planOptions,
                    onChanged: (_Plan next) => selected = next,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('integrates with Form validation and error captions', (
      tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      _Plan? selected;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Form(
              key: formKey,
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return OrionRadioGroup<_Plan>(
                    label: 'Choose a plan',
                    helper: 'Required to continue',
                    value: selected,
                    options: _planOptions,
                    validator: (_Plan? value) =>
                        value == null ? 'Please choose a plan' : null,
                    onChanged: (_Plan next) => setState(() => selected = next),
                  );
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('Required to continue'), findsOneWidget);
      expect(formKey.currentState!.validate(), isFalse);
      await tester.pump();

      expect(find.text('Please choose a plan'), findsOneWidget);
      expect(find.text('Required to continue'), findsNothing);
      for (final OrionRadio radio in tester.widgetList<OrionRadio>(
        find.byType(OrionRadio),
      )) {
        expect(radio.error, isTrue);
      }

      await tester.tap(find.text('Monthly'));
      await tester.pumpAndSettle();
      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Please choose a plan'), findsNothing);
      expect(find.text('Required to continue'), findsOneWidget);
    });

    testWidgets(
      'navigates with arrow keys, Home, and End while skipping disabled items',
      (tester) async {
        _Plan selected = _Plan.monthly;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return OrionRadioGroup<_Plan>(
                    value: selected,
                    options: const <OrionRadioOption<_Plan>>[
                      OrionRadioOption<_Plan>(
                        value: _Plan.monthly,
                        label: 'Monthly',
                      ),
                      OrionRadioOption<_Plan>(
                        value: _Plan.yearly,
                        label: 'Yearly',
                        enabled: false,
                      ),
                      OrionRadioOption<_Plan>(
                        value: _Plan.lifetime,
                        label: 'Lifetime',
                      ),
                    ],
                    onChanged: (_Plan next) => setState(() => selected = next),
                  );
                },
              ),
            ),
          ),
        );

        // Focus first option via Tab (roving tabindex enters selected item).
        await tester.sendKeyEvent(LogicalKeyboardKey.tab);
        await tester.pump();

        // ArrowDown skips disabled Yearly and selects Lifetime.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(selected, _Plan.lifetime);

        // ArrowDown wraps back to Monthly.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(selected, _Plan.monthly);

        // ArrowUp wraps to Lifetime.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(selected, _Plan.lifetime);

        // Home jumps to first enabled option (Monthly).
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(selected, _Plan.monthly);

        // End jumps to last enabled option (Lifetime).
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(selected, _Plan.lifetime);
      },
    );

    testWidgets('reverses Left/Right arrow navigation in RTL locales', (
      tester,
    ) async {
      _Plan selected = _Plan.monthly;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return OrionRadioGroup<_Plan>(
                    variant: OrionRadioGroupVariant.card,
                    value: selected,
                    options: _planOptions,
                    onChanged: (_Plan next) => setState(() => selected = next),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      // In RTL, ArrowLeft advances forward (monthly -> yearly).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(selected, _Plan.yearly);

      // In RTL, ArrowRight moves backward (yearly -> monthly).
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(selected, _Plan.monthly);
    });

    testWidgets('handles dynamic option list growth and shrinking cleanly', (
      tester,
    ) async {
      _Plan selected = _Plan.monthly;
      List<OrionRadioOption<_Plan>> options = _planOptions;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionRadioGroup<_Plan>(
              value: selected,
              options: options,
              onChanged: (_Plan next) => selected = next,
            ),
          ),
        ),
      );

      options = _planOptions.take(1).toList();
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionRadioGroup<_Plan>(
              value: selected,
              options: options,
              onChanged: (_Plan next) => selected = next,
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(find.byType(OrionRadio), findsOneWidget);

      final SemanticsHandle handle = tester.ensureSemantics();
      final SemanticsNode node = tester.getSemantics(find.byType(OrionRadio));
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      handle.dispose();
    });
  });
}
