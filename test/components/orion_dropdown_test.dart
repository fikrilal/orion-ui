import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orion_ui/orion_ui.dart';

const List<OrionDropdownOption<String>> _options =
    <OrionDropdownOption<String>>[
      OrionDropdownOption<String>(value: 'nl', label: 'Netherlands'),
      OrionDropdownOption<String>(value: 'de', label: 'Germany'),
      OrionDropdownOption<String>(value: 'fr', label: 'France', enabled: false),
      OrionDropdownOption<String>(value: 'es', label: 'Spain'),
    ];

class _Host extends StatefulWidget {
  const _Host({
    this.initialValue,
    this.onChanged,
    this.enabled = true,
    this.validator,
    this.error,
    this.label,
    this.formKey,
    this.alignment = Alignment.center,
    this.disableAnimations = false,
    this.searchable = false,
    this.options,
  });

  final String? initialValue;
  final ValueChanged<String>? onChanged;
  final bool enabled;
  final FormFieldValidator<String?>? validator;
  final String? error;
  final String? label;
  final GlobalKey<FormState>? formKey;
  final AlignmentGeometry alignment;
  final bool disableAnimations;
  final bool searchable;
  final List<OrionDropdownOption<String>>? options;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String? _value;

  @override
  void initState() {
    super.initState();
    _value = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final Widget dropdown = OrionDropdown<String>(
      options: widget.options ?? _options,
      value: _value,
      label: widget.label,
      placeholder: 'Pick one',
      error: widget.error,
      validator: widget.validator,
      enabled: widget.enabled,
      searchable: widget.searchable,
      onChanged: (String value) {
        setState(() => _value = value);
        widget.onChanged?.call(value);
      },
    );
    return MaterialApp(
      theme: OrionTheme.light(),
      builder: widget.disableAnimations
          ? (BuildContext context, Widget? child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(disableAnimations: true),
              child: child!,
            )
          : null,
      home: Scaffold(
        body: Align(
          alignment: widget.alignment,
          child: SizedBox(
            width: 300,
            child: widget.formKey != null
                ? Form(key: widget.formKey, child: dropdown)
                : dropdown,
          ),
        ),
      ),
    );
  }
}

OrionDropdownState<String> _state(WidgetTester tester) => tester
    .state<OrionDropdownState<String>>(find.byType(OrionDropdown<String>));

Future<void> _setViewport(WidgetTester tester, Size size) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
}

Future<void> _open(
  WidgetTester tester, [
  String placeholder = 'Pick one',
]) async {
  await tester.tap(find.text(placeholder));
  await tester.pumpAndSettle();
}

void main() {
  group('OrionDropdown', () {
    testWidgets('shows the placeholder, then the selected label', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host());
      expect(find.text('Pick one'), findsOneWidget);
      expect(find.text('Netherlands'), findsNothing);
    });

    testWidgets('shows explicit error text in the caption', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host(error: 'Bad value'));
      expect(find.text('Bad value'), findsOneWidget);
    });

    testWidgets('shows the selected label for a known value', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host(initialValue: 'nl'));
      expect(find.text('Netherlands'), findsOneWidget);
    });

    testWidgets('asserts when the value is not among the options', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host(initialValue: 'zz'));
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets(
      'opens anchored below the field with rounded borders preserved',
      (WidgetTester tester) async {
        await _setViewport(tester, const Size(400, 700));
        await tester.pumpWidget(const _Host());
        final Rect triggerRect = tester.getRect(
          find.byType(OrionDropdown<String>),
        );

        await tester.tap(find.text('Pick one'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final OrionDropdownState<String> state = _state(tester);
        expect(state.isOpen, isTrue);
        expect(state.openDriver.value, greaterThan(0.0));

        await tester.pumpAndSettle();
        final Rect separated = state.panelRect!;
        expect((separated.top - (triggerRect.bottom + 8)).abs(), lessThan(0.5));
        expect(state.openDriver.value, closeTo(1.0, 0.001));

        // The trigger field maintains its clean rounded borders at all times
        final DecoratedBox triggerDecorated = tester.widget<DecoratedBox>(
          find
              .descendant(
                of: find.byType(OrionDropdown<String>),
                matching: find.byType(DecoratedBox),
              )
              .first,
        );
        final BoxDecoration decoration =
            triggerDecorated.decoration as BoxDecoration;
        final BorderRadius radius = decoration.borderRadius as BorderRadius;
        expect(radius.bottomLeft.x, greaterThan(0));
        expect(radius.bottomRight.x, greaterThan(0));
      },
    );

    testWidgets('flips above the field when there is no room below', (
      WidgetTester tester,
    ) async {
      await _setViewport(tester, const Size(400, 300));
      await tester.pumpWidget(const _Host(alignment: Alignment.bottomCenter));
      final Rect triggerRect = tester.getRect(
        find.byType(OrionDropdown<String>),
      );

      await _open(tester);

      final Rect panelRect = _state(tester).panelRect!;
      expect(panelRect.bottom, lessThanOrEqualTo(triggerRect.top + 0.5));
      expect((triggerRect.top - panelRect.bottom - 8).abs(), lessThan(1.0));
    });

    testWidgets('commits the selection once and closes', (
      WidgetTester tester,
    ) async {
      final List<String> changes = <String>[];
      await tester.pumpWidget(_Host(onChanged: changes.add));
      await _open(tester);
      expect(find.text('Germany'), findsOneWidget);

      await tester.tap(find.text('Germany'));
      await tester.pumpAndSettle();

      expect(changes, equals(<String>['de']));
      expect(find.text('Germany'), findsOneWidget);
      expect(_state(tester).panelRect, isNull);
    });

    testWidgets('re-committing the current value closes silently', (
      WidgetTester tester,
    ) async {
      final List<String> changes = <String>[];
      await tester.pumpWidget(
        _Host(initialValue: 'nl', onChanged: changes.add),
      );
      await _open(tester, 'Netherlands');
      expect(find.text('Netherlands'), findsNWidgets(2));

      await tester.tap(find.text('Netherlands').last);
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
      expect(_state(tester).panelRect, isNull);
    });

    testWidgets('an outside tap closes without changing the value', (
      WidgetTester tester,
    ) async {
      final List<String> changes = <String>[];
      await tester.pumpWidget(
        _Host(initialValue: 'nl', onChanged: changes.add),
      );
      await _open(tester, 'Netherlands');

      await tester.tapAt(const Offset(5, 5));
      await tester.pumpAndSettle();

      expect(changes, isEmpty);
      expect(_state(tester).panelRect, isNull);
    });

    testWidgets('a drag outside the panel dismisses it', (
      WidgetTester tester,
    ) async {
      await _setViewport(tester, const Size(400, 700));
      await tester.pumpWidget(const _Host());
      await _open(tester);
      expect(find.text('Netherlands'), findsOneWidget);

      await tester.dragFrom(const Offset(380, 660), const Offset(0, -100));
      await tester.pumpAndSettle();

      expect(find.text('Netherlands'), findsNothing);
    });

    testWidgets('a disabled control does not open', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host(enabled: false));
      await tester.tap(find.text('Pick one'));
      await tester.pumpAndSettle();
      expect(find.text('Netherlands'), findsNothing);
    });

    testWidgets(
      'keyboard steps skip disabled options, wrap, and commit with enter',
      (WidgetTester tester) async {
        final List<String> changes = <String>[];
        await tester.pumpWidget(_Host(onChanged: changes.add));
        final OrionDropdownState<String> state = _state(tester);
        state.triggerFocusNode.requestFocus();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(state.isOpen, isTrue);
        expect(state.activeIndex, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pump();
        expect(state.activeIndex, 3, reason: 'wraps to the last enabled row');

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(state.activeIndex, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(state.activeIndex, 3);

        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(state.activeIndex, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(changes, equals(<String>['nl']));
        expect(state.isOpen, isFalse);
        expect(state.triggerFocusNode.hasFocus, isTrue);
      },
    );

    testWidgets('two arrow keys in one frame move two rows', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host());
      final OrionDropdownState<String> state = _state(tester);
      state.triggerFocusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(state.activeIndex, 0);

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(state.activeIndex, 3, reason: '0 -> 1 -> 3, skipping disabled');
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
    });

    testWidgets('escape closes and restores focus to the trigger', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host());
      final OrionDropdownState<String> state = _state(tester);
      state.triggerFocusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(state.isOpen, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(state.isOpen, isFalse);
      expect(state.panelRect, isNull);
      expect(state.triggerFocusNode.hasFocus, isTrue);
    });

    testWidgets('tab closes the panel', (WidgetTester tester) async {
      await tester.pumpWidget(const _Host());
      final OrionDropdownState<String> state = _state(tester);
      state.triggerFocusNode.requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(state.isOpen, isTrue);

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pumpAndSettle();

      expect(state.isOpen, isFalse);
    });

    testWidgets('reduced motion opens and closes at final geometry', (
      WidgetTester tester,
    ) async {
      await _setViewport(tester, const Size(400, 700));
      await tester.pumpWidget(const _Host(disableAnimations: true));
      final Rect triggerRect = tester.getRect(
        find.byType(OrionDropdown<String>),
      );

      await tester.tap(find.text('Pick one'));
      await tester.pump();

      final OrionDropdownState<String> state = _state(tester);
      expect(state.openDriver.value, 1.0);
      final Rect panelRect = state.panelRect!;
      expect((panelRect.top - (triggerRect.bottom + 8)).abs(), lessThan(1.0));

      await tester.tapAt(const Offset(5, 5));
      await tester.pump();
      expect(state.isOpen, isFalse);
      expect(state.panelRect, isNull);
    });

    testWidgets('validation runs through the form and clears on selection', (
      WidgetTester tester,
    ) async {
      final GlobalKey<FormState> formKey = GlobalKey<FormState>();
      await tester.pumpWidget(
        _Host(
          formKey: formKey,
          validator: (String? value) => value == null ? 'Required' : null,
        ),
      );

      expect(formKey.currentState!.validate(), isFalse);
      await tester.pumpAndSettle();
      expect(find.text('Required'), findsOneWidget);

      await _open(tester);
      await tester.tap(find.text('Spain'));
      await tester.pumpAndSettle();

      expect(formKey.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Required'), findsNothing);
    });

    testWidgets('exposes one semantic node for the control and its options', (
      WidgetTester tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await tester.pumpWidget(
        const _Host(initialValue: 'nl', label: 'Country'),
      );

      final Finder triggerNode = find.byWidgetPredicate(
        (Widget widget) =>
            widget is Semantics && widget.properties.label == 'Country',
      );
      final SemanticsNode collapsed = tester.getSemantics(triggerNode);
      expect(collapsed.label, 'Country');
      expect(collapsed.value, 'Netherlands');
      expect(collapsed.flagsCollection.isButton, isTrue);
      expect(collapsed.flagsCollection.isEnabled, Tristate.isTrue);
      expect(collapsed.flagsCollection.isExpanded, Tristate.isFalse);

      await _open(tester, 'Netherlands');
      expect(
        tester.getSemantics(triggerNode).flagsCollection.isExpanded,
        Tristate.isTrue,
      );

      final SemanticsNode optionNode = tester.getSemantics(
        find.byWidgetPredicate(
          (Widget widget) =>
              widget is Semantics && widget.properties.selected == true,
        ),
      );
      expect(optionNode.label, 'Netherlands');
      expect(optionNode.flagsCollection.isSelected, Tristate.isTrue);
      expect(optionNode.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });

    testWidgets(
      'displays selected option leading widget on trigger face, and prefix wins',
      (WidgetTester tester) async {
        const Key optionLeadingKey = ValueKey<String>('option-star');
        const Key prefixKey = ValueKey<String>('fixed-prefix');

        const List<OrionDropdownOption<String>> richOptions = [
          OrionDropdownOption<String>(
            value: 'star',
            label: 'Favorite',
            leading: Icon(Icons.star, key: optionLeadingKey),
          ),
          OrionDropdownOption<String>(value: 'plain', label: 'Regular'),
        ];

        // 1. When value is null, option leading is not shown
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionDropdown<String>(
                  options: richOptions,
                  placeholder: 'Select...',
                ),
              ),
            ),
          ),
        );
        expect(find.byKey(optionLeadingKey), findsNothing);

        // 2. When an option with leading is selected, its leading widget renders on the face
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionDropdown<String>(
                  options: richOptions,
                  value: 'star',
                  placeholder: 'Select...',
                ),
              ),
            ),
          ),
        );
        expect(find.byKey(optionLeadingKey), findsOneWidget);

        // 3. Explicit prefix on the dropdown overrides option leading
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Center(
                child: OrionDropdown<String>(
                  prefix: Icon(Icons.language, key: prefixKey),
                  options: richOptions,
                  value: 'star',
                  placeholder: 'Select...',
                ),
              ),
            ),
          ),
        );
        expect(find.byKey(prefixKey), findsOneWidget);
        expect(find.byKey(optionLeadingKey), findsNothing);
      },
    );

    testWidgets('taps inside the panel padding do not dismiss the panel', (
      WidgetTester tester,
    ) async {
      await _setViewport(tester, const Size(400, 700));
      await tester.pumpWidget(const _Host());
      await _open(tester);

      final OrionDropdownState<String> state = _state(tester);
      expect(state.isOpen, isTrue);
      final Rect panelRect = state.panelRect!;

      // Tap near the edge of the panel (inside the 8pt padding, away from row text)
      await tester.tapAt(Offset(panelRect.left + 2, panelRect.top + 2));
      await tester.pumpAndSettle();

      // Panel must stay open!
      expect(state.isOpen, isTrue);
      expect(state.panelRect, isNotNull);
    });

    testWidgets(
      'zero-rebuild transform invariant: option rows do not rebuild on open ticks',
      (WidgetTester tester) async {
        int rowBuildCount = 0;
        final List<OrionDropdownOption<String>> testOptions = [
          OrionDropdownOption(
            value: 'a',
            label: 'Alpha',
            leading: Builder(
              builder: (context) {
                rowBuildCount++;
                return const Icon(Icons.star);
              },
            ),
          ),
        ];

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionDropdown<String>(
                  options: testOptions,
                  placeholder: 'Select',
                ),
              ),
            ),
          ),
        );

        await tester.tap(find.text('Select'));
        await tester.pump(); // Overlay added to tree and laid out once
        final int initialBuilds = rowBuildCount;
        expect(initialBuilds, 1);

        // Pump multiple frames during active spring blossom
        for (int i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();

        expect(rowBuildCount, initialBuilds);
      },
    );

    testWidgets(
      'cooperates with parent scrollable: drag cancels trigger tap and scrolls list',
      (WidgetTester tester) async {
        final ScrollController scrollController = ScrollController();
        addTearDown(scrollController.dispose);

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: ListView(
                controller: scrollController,
                children: const [
                  SizedBox(height: 200),
                  OrionDropdown<String>(
                    options: _options,
                    placeholder: 'Scrollable Dropdown',
                  ),
                  SizedBox(height: 800),
                ],
              ),
            ),
          ),
        );

        expect(scrollController.offset, 0.0);
        // Drag upwards starting directly over the dropdown trigger
        await tester.drag(
          find.text('Scrollable Dropdown'),
          const Offset(0, -150),
        );
        await tester.pumpAndSettle();

        expect(scrollController.offset, greaterThan(100.0));
        expect(find.text('Netherlands'), findsNothing); // Panel remained closed
      },
    );

    testWidgets('options length shrinking while open re-measures safely', (
      WidgetTester tester,
    ) async {
      List<OrionDropdownOption<String>> currentOptions = _options; // 4 options
      late void Function(void Function()) setStateHost;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setStateHost = setState;
                return Center(
                  child: OrionDropdown<String>(
                    options: currentOptions,
                    placeholder: 'Dynamic',
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Dynamic'));
      await tester.pumpAndSettle();
      expect(find.text('Spain'), findsOneWidget);

      // Shrink options while open to 2 options
      setStateHost(() {
        currentOptions = const [
          OrionDropdownOption<String>(value: 'nl', label: 'Netherlands'),
          OrionDropdownOption<String>(value: 'de', label: 'Germany'),
        ];
      });
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Spain'), findsNothing);
      expect(find.text('Germany'), findsOneWidget);
    });

    testWidgets('touch press down scales option row and recovers on release', (
      WidgetTester tester,
    ) async {
      await _setViewport(tester, const Size(400, 700));
      await tester.pumpWidget(const _Host());
      await _open(tester);

      final Finder netherlandsRow = find.widgetWithText(
        OrionPressable,
        'Netherlands',
      );
      expect(netherlandsRow, findsOneWidget);

      // Start press gesture on Netherlands row
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Netherlands')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      final OrionPressableState pressableState = tester
          .state<OrionPressableState>(netherlandsRow);
      expect(pressableState.driver.value, lessThan(1.0));

      // Release finger
      await gesture.up();
      await tester.pumpAndSettle();

      // Tap on Netherlands committed the selection and closed the panel
      expect(find.text('Netherlands'), findsOneWidget);
      expect(_state(tester).panelRect, isNull);
    });

    testWidgets('deactivation safety: unmounting mid-flight does not throw', (
      WidgetTester tester,
    ) async {
      bool mounted = true;
      late void Function(void Function()) setStateHost;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                setStateHost = setState;
                return Center(
                  child: mounted
                      ? const OrionDropdown<String>(
                          options: _options,
                          placeholder: 'Unmount test',
                        )
                      : const SizedBox(),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('Unmount test'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 30));

      // Unmount while opening animation is active
      setStateHost(() => mounted = false);
      await tester.pumpAndSettle();

      expect(find.text('Unmount test'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'mid-flight retargeting: closing mid-open reverses smoothly without snapping',
      (WidgetTester tester) async {
        await _setViewport(tester, const Size(400, 700));
        await tester.pumpWidget(const _Host());

        // Open
        await tester.tap(find.text('Pick one'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 40));

        final OrionDropdownState<String> state = _state(tester);
        expect(state.isOpen, isTrue);
        final double midOpenVal = state.openDriver.value;
        expect(midOpenVal, greaterThan(0.0));
        expect(midOpenVal, lessThan(1.0));

        // Close mid-flight via hide
        state.hide();
        await tester.pump();
        // Immediately after retargeting, value is continuous
        expect(state.openDriver.value, closeTo(midOpenVal, 0.05));

        await tester.pumpAndSettle();
        expect(state.isOpen, isFalse);
        expect(state.panelRect, isNull);
      },
    );

    testWidgets('a searchable face shows a search icon', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host());
      expect(find.byIcon(Icons.search_rounded), findsNothing);

      await tester.pumpWidget(const _Host(searchable: true));
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);

      await _open(tester);
      expect(find.byIcon(Icons.search_rounded), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('searchable defaults to false', (WidgetTester tester) async {
      await tester.pumpWidget(const _Host());
      expect(
        tester
            .widget<OrionDropdown<String>>(find.byType(OrionDropdown<String>))
            .searchable,
        isFalse,
      );
    });

    testWidgets(
      'a query keeps a case-insensitive subsequence of the label, description, and string value',
      (WidgetTester tester) async {
        const List<OrionDropdownOption<String>> described =
            <OrionDropdownOption<String>>[
              OrionDropdownOption<String>(
                value: 'a',
                label: 'Alpha',
                description: 'Netherlands office',
              ),
              OrionDropdownOption<String>(value: 'b', label: 'Beta'),
              OrionDropdownOption<String>(
                value: 'netherlands',
                label: 'Lowlands',
              ),
            ];
        await tester.pumpWidget(
          const _Host(searchable: true, options: described),
        );
        await _open(tester);
        await tester.enterText(find.byType(TextField), '  NeT ');
        await tester.pump();

        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Lowlands'), findsOneWidget);
        expect(find.text('Beta'), findsNothing);

        await tester.enterText(find.byType(TextField), 'off');
        await tester.pump();
        expect(find.text('Alpha'), findsOneWidget);
        expect(find.text('Lowlands'), findsNothing);
      },
    );

    testWidgets('an int value is not searched through its toString', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: OrionDropdown<int>(
                  searchable: true,
                  placeholder: 'Pick one',
                  options: <OrionDropdownOption<int>>[
                    OrionDropdownOption<int>(value: 123, label: 'Count'),
                    OrionDropdownOption<int>(value: 7, label: 'Seven'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await _open(tester);
      await tester.enterText(find.byType(TextField), '123');
      await tester.pump();
      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('Count'), findsNothing);

      await tester.enterText(find.byType(TextField), 'sev');
      await tester.pump();
      expect(find.text('Seven'), findsOneWidget);
      expect(find.text('Count'), findsNothing);
    });

    testWidgets(
      'a disabled match stays visible, is not the cursor, and does not commit',
      (WidgetTester tester) async {
        final List<String> changes = <String>[];
        await tester.pumpWidget(
          _Host(searchable: true, onChanged: changes.add),
        );
        await _open(tester);
        await tester.enterText(find.byType(TextField), 'fra');
        await tester.pump();

        expect(find.text('France'), findsOneWidget);
        expect(find.text('Netherlands'), findsNothing);
        expect(_state(tester).activeIndex, isNull);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pump();
        expect(changes, isEmpty);
        expect(_state(tester).isOpen, isTrue);
        expect(find.text('No matches'), findsNothing);
      },
    );

    testWidgets(
      'a query that hides the cursor falls back, and Enter commits that row',
      (WidgetTester tester) async {
        final List<String> changes = <String>[];
        await tester.pumpWidget(
          _Host(searchable: true, initialValue: 'nl', onChanged: changes.add),
        );
        await tester.tap(find.text('Netherlands'));
        await tester.pumpAndSettle();
        expect(_state(tester).activeIndex, 0);

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(_state(tester).activeIndex, 3);

        await tester.enterText(find.byType(TextField), 'ger');
        await tester.pump();
        expect(find.text('Spain'), findsNothing);
        expect(find.text('Netherlands'), findsNothing);
        expect(_state(tester).activeIndex, 1);

        await tester.sendKeyEvent(LogicalKeyboardKey.enter);
        await tester.pumpAndSettle();
        expect(changes, equals(<String>['de']));
        expect(_state(tester).isOpen, isFalse);
        expect(find.text('Germany'), findsOneWidget);
      },
    );

    testWidgets('an empty result stays open and Enter commits nothing', (
      WidgetTester tester,
    ) async {
      final List<String> changes = <String>[];
      await tester.pumpWidget(_Host(searchable: true, onChanged: changes.add));
      await _open(tester);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();

      expect(find.text('No matches'), findsOneWidget);
      expect(find.text('Netherlands'), findsNothing);
      expect(_state(tester).activeIndex, isNull);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(changes, isEmpty);
      expect(_state(tester).isOpen, isTrue);
    });

    testWidgets(
      'closing clears the query on the face and the next open lists everything',
      (WidgetTester tester) async {
        await tester.pumpWidget(const _Host(searchable: true));
        await _open(tester);
        await tester.enterText(find.byType(TextField), 'net');
        await tester.pump();
        expect(find.text('Germany'), findsNothing);

        await tester.tapAt(const Offset(5, 5));
        await tester.pump();
        final OrionDropdownState<String> state = _state(tester);
        expect(state.isOpen, isTrue);
        expect(find.text('Germany'), findsNothing);
        expect(find.text('Netherlands'), findsOneWidget);
        expect(find.text('Pick one'), findsOneWidget);

        await tester.pumpAndSettle();
        expect(state.isOpen, isFalse);
        expect(find.byType(TextField), findsNothing);
        expect(find.text('Pick one'), findsOneWidget);

        await _open(tester);
        expect(find.text('Germany'), findsOneWidget);
        expect(find.text('Spain'), findsOneWidget);
        expect(find.text('France'), findsOneWidget);
      },
    );

    testWidgets(
      'arrows move the visible rows, and an arrow while closed only opens',
      (WidgetTester tester) async {
        await tester.pumpWidget(
          const _Host(searchable: true, initialValue: 'es'),
        );
        final OrionDropdownState<String> state = _state(tester);
        state.triggerFocusNode.requestFocus();
        await tester.pump();

        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(state.isOpen, isTrue);
        expect(state.activeIndex, 3);
        expect(state.triggerFocusNode.hasFocus, isTrue);

        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
        await tester.pump();
        expect(state.activeIndex, 1, reason: 'Spain -> Netherlands -> Germany');
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
        await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);

        await tester.sendKeyEvent(LogicalKeyboardKey.escape);
        await tester.pumpAndSettle();
        expect(state.isOpen, isFalse);
        expect(state.triggerFocusNode.hasFocus, isTrue);
      },
    );

    testWidgets('space types into the query', (WidgetTester tester) async {
      final List<String> changes = <String>[];
      await tester.pumpWidget(_Host(searchable: true, onChanged: changes.add));
      await _open(tester);
      expect(_state(tester).activeIndex, 0);

      // The hardware key must not commit. A widget test has no IME, so the
      // character arrives through the text input connection.
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(changes, isEmpty);
      expect(_state(tester).isOpen, isTrue);
      expect(_state(tester).activeIndex, 0);

      await tester.showKeyboard(find.byType(TextField));
      tester.testTextInput.enterText(' ');
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        ' ',
      );
      expect(changes, isEmpty);
      expect(_state(tester).isOpen, isTrue);
      expect(find.text('Netherlands'), findsOneWidget);
    });

    testWidgets('a tap in the query stays open and the chevron closes it', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(const _Host(searchable: true));
      await _open(tester);
      expect(_state(tester).isOpen, isTrue);

      await tester.tap(find.byType(TextField));
      await tester.pump();
      expect(_state(tester).isOpen, isTrue);

      await tester.tap(find.byIcon(Icons.keyboard_arrow_down_rounded));
      await tester.pumpAndSettle();
      expect(_state(tester).isOpen, isFalse);
    });
  });

  group('OrionDropdownStyle', () {
    test('merges field-by-field and lerps with discrete specs swapping', () {
      const OrionDropdownStyle base = OrionDropdownStyle(
        panelGap: 4,
        pressScale: 0.9,
        springSpec: OrionDropdownPresets.unfoldSpring,
      );
      final OrionDropdownStyle merged = base.merge(
        const OrionDropdownStyle(panelGap: 12),
      );
      expect(merged.panelGap, 12);
      expect(merged.pressScale, 0.9);

      final OrionDropdownStyle lerped = OrionDropdownStyle.lerp(
        base,
        const OrionDropdownStyle(
          panelGap: 8,
          springSpec: OrionDropdownPresets.separationSpring,
        ),
        0.25,
      )!;
      expect(lerped.panelGap, closeTo(5, 0.001));
      // The kit's lerp convention treats a missing side as 0, like the tabs
      // and popover styles do.
      expect(lerped.pressScale, closeTo(0.675, 0.001));
      expect(lerped.springSpec, OrionDropdownPresets.unfoldSpring);
    });
  });
}
