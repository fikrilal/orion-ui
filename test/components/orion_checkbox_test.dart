import 'dart:math' as math;
import 'dart:ui' show CheckedState, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpCheckbox(
  WidgetTester tester, {
  required bool? value,
  required ValueChanged<bool?>? onChanged,
  bool disableAnimations = false,
  bool autofocus = false,
  bool error = false,
  String? semanticLabel,
  OrionCheckboxSize size = OrionCheckboxSize.medium,
  OrionCheckboxStyle? style,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: OrionCheckbox(
              value: value,
              onChanged: onChanged,
              autofocus: autofocus,
              error: error,
              semanticLabel: semanticLabel,
              size: size,
              style: style,
            ),
          ),
        ),
      ),
    ),
  );
}

BoxDecoration _boxDecoration(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(OrionCheckbox),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

BorderSide _boxBorder(WidgetTester tester) {
  return (_boxDecoration(tester).border! as Border).top;
}

double _markScale(WidgetTester tester) {
  // The pressable wraps the whole control and the glyph swap wraps each mark
  // in a transition, so the travel's transform is the first one under the
  // box's clip: that is the scale the driver owns.
  final Transform transform = tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(ClipRRect),
          matching: find.byType(Transform),
        ),
      )
      .first;
  return transform.transform.entry(0, 0);
}

void main() {
  group('OrionCheckbox', () {
    testWidgets('rests empty when unchecked', (tester) async {
      await _pumpCheckbox(tester, value: false, onChanged: (_) {});

      final BoxDecoration decoration = _boxDecoration(tester);
      expect(decoration.color!.a, 0);
      expect(_boxBorder(tester).color, OrionColors.lightScheme.outline);
      expect(_markScale(tester), 0);
    });

    testWidgets('fills with the primary color when checked', (tester) async {
      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_boxDecoration(tester).color, OrionColors.lightScheme.primary);
      expect(_boxBorder(tester).color, OrionColors.lightScheme.primary);
      expect(_markScale(tester), 1);
      expect(find.byKey(orionCheckboxCheckMarkKey), findsOneWidget);
    });

    testWidgets('draws a bar instead of a check when indeterminate', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCheckbox(
        tester,
        value: null,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(find.byKey(orionCheckboxCheckMarkKey), findsNothing);
      expect(tester.getSize(find.byType(DecoratedBox).last), const Size(12, 2));
      expect(_boxDecoration(tester).color, OrionColors.lightScheme.primary);

      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionCheckbox),
      );
      expect(node.flagsCollection.isChecked, CheckedState.mixed);
      handle.dispose();
    });

    testWidgets('reports the opposite value on tap', (tester) async {
      bool? reported;
      await _pumpCheckbox(
        tester,
        value: false,
        onChanged: (bool? value) => reported = value,
      );

      await tester.tap(find.byType(OrionCheckbox));
      expect(reported, isTrue);
    });

    testWidgets('checks on the first tap when indeterminate', (tester) async {
      bool? reported;
      await _pumpCheckbox(
        tester,
        value: null,
        onChanged: (bool? value) => reported = value,
      );

      await tester.tap(find.byType(OrionCheckbox));
      expect(reported, isTrue);
    });

    testWidgets('unchecks on tap when checked', (tester) async {
      bool? reported;
      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (bool? value) => reported = value,
      );

      await tester.tap(find.byType(OrionCheckbox));
      expect(reported, isFalse);
    });

    testWidgets('ignores taps when disabled', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCheckbox(tester, value: true, onChanged: null);

      await tester.tap(find.byType(OrionCheckbox));
      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionCheckbox),
      );
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      expect(node.label, isEmpty);
      handle.dispose();
    });

    testWidgets('pins the disabled paint', (tester) async {
      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: null,
        disableAnimations: true,
      );
      await tester.pump();

      const ColorScheme scheme = OrionColors.lightScheme;
      final Color muted = scheme.onSurface.withValues(alpha: 0.12);
      expect(_boxDecoration(tester).color, muted);
      expect(_boxBorder(tester).color, muted);
      expect(find.byKey(orionCheckboxCheckMarkKey), findsOneWidget);
    });

    testWidgets('flips from the keyboard', (tester) async {
      bool? reported;
      await _pumpCheckbox(
        tester,
        value: false,
        autofocus: true,
        onChanged: (bool? value) => reported = value,
      );
      await tester.pumpAndSettle();

      expect(
        Focus.of(tester.element(find.byType(GestureDetector))).hasFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(reported, isTrue);

      reported = null;
      await _pumpCheckbox(
        tester,
        value: true,
        autofocus: true,
        onChanged: (bool? value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(reported, isFalse);
    });

    testWidgets('grows the mark instead of jumping', (tester) async {
      await _pumpCheckbox(tester, value: false, onChanged: (_) {});
      expect(_markScale(tester), 0);

      await _pumpCheckbox(tester, value: true, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      expect(_markScale(tester), greaterThan(0));
      expect(_markScale(tester), lessThan(1));

      await tester.pumpAndSettle();
      expect(_markScale(tester), closeTo(1, 0.001));
    });

    testWidgets('keeps the mark out of the ticker rebuilds', (tester) async {
      await _pumpCheckbox(tester, value: false, onChanged: (_) {});
      await _pumpCheckbox(tester, value: true, onChanged: (_) {});

      final Finder ticker = find.descendant(
        of: find.byType(OrionCheckbox),
        matching: find.byType(AnimatedBuilder),
      );
      final Widget mark = tester
          .widgetList<AnimatedBuilder>(ticker)
          .first
          .child!;
      Color previous = _boxDecoration(tester).color!;

      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));

        // The ticker really ran, so the identity check is not vacuous.
        final Color current = _boxDecoration(tester).color!;
        expect(current, isNot(previous));
        previous = current;
        expect(
          identical(
            tester.widgetList<AnimatedBuilder>(ticker).first.child,
            mark,
          ),
          isTrue,
        );
      }

      await tester.pumpAndSettle();
    });

    testWidgets('pops once without stalling at a cap', (tester) async {
      await _pumpCheckbox(tester, value: false, onChanged: (_) {});
      await _pumpCheckbox(tester, value: true, onChanged: (_) {});

      final List<double> marks = <double>[];
      final List<double> fills = <double>[];
      for (var frame = 0; frame < 90; frame++) {
        marks.add(_markScale(tester));
        fills.add(_boxDecoration(tester).color!.a);
        await tester.pump(const Duration(milliseconds: 16));
      }

      // A cap would pin the mark at the cap; the spring only visits its peak.
      final double peak = marks.reduce(math.max);
      expect(peak, greaterThan(1));
      expect(peak, lessThan(1.1));

      // Once the fill reaches full it never fades back out.
      final int full = fills.indexWhere((double fill) => fill >= 0.999);
      expect(full, greaterThanOrEqualTo(0));
      expect(fills.skip(full).every((double fill) => fill >= 0.98), isTrue);

      await tester.pumpAndSettle();
      expect(_markScale(tester), closeTo(1, 0.001));
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      await _pumpCheckbox(
        tester,
        value: false,
        onChanged: (_) {},
        disableAnimations: true,
      );
      expect(_markScale(tester), 0);

      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_markScale(tester), 1);
    });

    testWidgets('settles at once when motion is turned off mid-flight', (
      tester,
    ) async {
      await _pumpCheckbox(tester, value: false, onChanged: (_) {});
      await _pumpCheckbox(tester, value: true, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));
      expect(_markScale(tester), lessThan(1));

      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_markScale(tester), 1);
    });

    testWidgets('keeps a 44 pt hit target', (tester) async {
      await _pumpCheckbox(tester, value: false, onChanged: (_) {});

      expect(
        tester.getSize(find.byType(OrionCheckbox)),
        const Size(OrionSizing.minHitTarget, OrionSizing.minHitTarget),
      );
    });

    testWidgets('exposes the spoken name', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (_) {},
        semanticLabel: 'Remember me',
      );

      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionCheckbox),
      );
      expect(node.label, 'Remember me');
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      handle.dispose();
    });

    testWidgets('paints the focus overlay under the box when focused', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      await _pumpCheckbox(
        tester,
        value: false,
        autofocus: true,
        onChanged: (_) {},
      );
      await tester.pumpAndSettle();

      final ColoredBox overlay = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(OrionCheckbox),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(
        overlay.color,
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.12),
      );
      expect(
        _boxDecoration(tester).boxShadow,
        isNull,
        reason: 'focus is an overlay, not a second border',
      );
    });

    testWidgets('cross-fades the swap between the check and the bar', (
      tester,
    ) async {
      await _pumpCheckbox(tester, value: true, onChanged: (_) {});
      await tester.pumpAndSettle();
      expect(find.byKey(orionCheckboxCheckMarkKey), findsOneWidget);

      // Checked and indeterminate share the travel's filled end, so the spring
      // has nothing to move; the glyph swap is its own transition.
      await _pumpCheckbox(tester, value: null, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));
      expect(
        tester.hasRunningAnimations,
        isTrue,
        reason: 'the swap animates instead of cutting',
      );

      await tester.pumpAndSettle();
      expect(find.byKey(orionCheckboxCheckMarkKey), findsNothing);
      expect(tester.getSize(find.byType(DecoratedBox).last), const Size(12, 2));
    });

    testWidgets('swaps the mark at once when motion is reduced', (
      tester,
    ) async {
      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      await _pumpCheckbox(
        tester,
        value: null,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(tester.hasRunningAnimations, isFalse);
      expect(find.byKey(orionCheckboxCheckMarkKey), findsNothing);
    });

    testWidgets('steps the box, radius, mark and bar with the size', (
      tester,
    ) async {
      await _pumpCheckbox(
        tester,
        value: null,
        onChanged: (_) {},
        size: OrionCheckboxSize.large,
        disableAnimations: true,
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(28, 28),
      );
      expect(
        (_boxDecoration(tester).borderRadius! as BorderRadius).topLeft,
        const Radius.circular(8),
      );
      expect(tester.getSize(find.byType(DecoratedBox).last), const Size(16, 2));

      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (_) {},
        size: OrionCheckboxSize.small,
        disableAnimations: true,
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(20, 20),
      );
      expect(
        tester.getSize(find.byKey(orionCheckboxCheckMarkKey)),
        const Size(12, 12),
      );
      expect(
        tester.getSize(find.byType(OrionCheckbox)),
        const Size(OrionSizing.minHitTarget, OrionSizing.minHitTarget),
        reason: 'the hit target does not change with the size',
      );
    });

    testWidgets('animates the fill and border out when unchecked', (
      tester,
    ) async {
      const ColorScheme scheme = OrionColors.lightScheme;
      await _pumpCheckbox(tester, value: true, onChanged: (_) {});
      await tester.pumpAndSettle();
      expect(_boxDecoration(tester).color, scheme.primary);

      await _pumpCheckbox(tester, value: false, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      final double fillAlpha = _boxDecoration(tester).color!.a;
      expect(
        fillAlpha,
        greaterThan(0),
        reason: 'the fill travels out instead of snapping on frame 0',
      );
      expect(fillAlpha, lessThan(1));
      expect(_boxBorder(tester).color, isNot(scheme.outline));
      expect(_boxBorder(tester).color, isNot(scheme.primary));

      await tester.pumpAndSettle();
      expect(_boxDecoration(tester).color!.a, 0);
      expect(_boxBorder(tester).color, scheme.outline);
    });

    testWidgets(
      'keeps an unchecked box transparent when only a fill is given',
      (tester) async {
        const ColorScheme scheme = OrionColors.lightScheme;
        final OrionCheckboxStyle style = OrionCheckboxStyle.from(
          fillColor: scheme.primary,
        );

        await _pumpCheckbox(
          tester,
          value: false,
          onChanged: (_) {},
          style: style,
          disableAnimations: true,
        );
        await tester.pump();
        expect(_boxDecoration(tester).color!.a, 0);

        await _pumpCheckbox(
          tester,
          value: true,
          onChanged: (_) {},
          style: style,
          disableAnimations: true,
        );
        await tester.pump();
        expect(_boxDecoration(tester).color, scheme.primary);
      },
    );

    testWidgets('paints the error role', (tester) async {
      const ColorScheme scheme = OrionColors.lightScheme;
      await _pumpCheckbox(
        tester,
        value: false,
        onChanged: (_) {},
        error: true,
        disableAnimations: true,
      );

      expect(_boxBorder(tester).color, scheme.error);
      expect(_boxDecoration(tester).color!.a, 0);

      await _pumpCheckbox(
        tester,
        value: true,
        onChanged: (_) {},
        error: true,
        disableAnimations: true,
      );
      await tester.pump();

      expect(_boxDecoration(tester).color, scheme.error);
      expect(_boxBorder(tester).color, scheme.error);
      expect(find.byKey(orionCheckboxCheckMarkKey), findsOneWidget);
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionCheckboxTheme(
            defaultStyle: OrionCheckboxStyle.from(
              size: 18,
              borderColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpCheckbox(
        tester,
        value: false,
        onChanged: (_) {},
        theme: themed,
        disableAnimations: true,
      );
      expect(_boxBorder(tester).color, const Color(0xFF00AA00));
      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(18, 18),
      );

      await _pumpCheckbox(
        tester,
        value: false,
        onChanged: (_) {},
        theme: themed,
        disableAnimations: true,
        style: OrionCheckboxStyle.from(borderColor: const Color(0xFFAA0000)),
      );
      expect(_boxBorder(tester).color, const Color(0xFFAA0000));
      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(18, 18),
        reason: 'the instance style only overrides what it names',
      );
    });

    testWidgets('emits one haptic on tap and none from the keyboard', (
      tester,
    ) async {
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

      bool? reported;
      await _pumpCheckbox(
        tester,
        value: false,
        autofocus: true,
        onChanged: (bool? value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OrionCheckbox));
      await tester.pump();
      expect(haptics, <String>['HapticFeedbackType.selectionClick']);
      expect(reported, isTrue);

      reported = null;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(haptics, hasLength(1));
      expect(reported, isTrue);
    });

    testWidgets('a scroll drag never toggles and stays silent', (tester) async {
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

      bool? reported;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              itemExtent: 60,
              itemCount: 20,
              itemBuilder: (BuildContext context, int index) => Center(
                child: OrionCheckbox(
                  value: false,
                  onChanged: (bool? value) => reported = value,
                ),
              ),
            ),
          ),
        ),
      );

      final double resting = tester
          .getTopLeft(find.byType(OrionCheckbox).first)
          .dy;

      await tester.drag(
        find.byType(OrionCheckbox).first,
        const Offset(0, -300),
      );
      await tester.pumpAndSettle();

      // The list really scrolled, so the silence below is not a missed drag.
      expect(
        tester.getTopLeft(find.byType(OrionCheckbox).first).dy,
        lessThan(resting),
      );
      expect(reported, isNull);
      expect(haptics, isEmpty);
    });

    testWidgets('survives being scrolled off-screen while held', (
      tester,
    ) async {
      bool? reported;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              itemExtent: 60,
              itemCount: 20,
              itemBuilder: (BuildContext context, int index) => OrionCheckbox(
                value: false,
                onChanged: (bool? value) => reported = value,
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionCheckbox).first),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // Drag the held box out of the viewport, then release over nothing.
      await gesture.moveBy(const Offset(0, -600));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(reported, isNull);
    });

    testWidgets(
      'renders clickable label and subtitle row and toggles on label tap',
      (tester) async {
        bool? reported;
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: OrionCheckbox(
                  value: false,
                  label: 'Accept terms',
                  subtitle: 'Required to create an account',
                  onChanged: (bool? v) => reported = v,
                ),
              ),
            ),
          ),
        );

        expect(find.text('Accept terms'), findsOneWidget);
        expect(find.text('Required to create an account'), findsOneWidget);

        await tester.tap(find.text('Accept terms'));
        await tester.pump();
        expect(reported, isTrue);

        final SemanticsNode node = tester.getSemantics(
          find.byType(OrionCheckbox),
        );
        expect(node.label, 'Accept terms');
        handle.dispose();
      },
    );
  });

  group('OrionCheckboxStyle', () {
    test('a merge only changes the fields it names', () {
      final OrionCheckboxStyle base = OrionCheckboxStyle.from(
        size: 20,
        borderColor: const Color(0xFF111111),
      );
      final OrionCheckboxStyle merged = base.merge(
        OrionCheckboxStyle.from(borderColor: const Color(0xFF333333)),
      );

      expect(
        merged.borderColor?.resolve(const <WidgetState>{}),
        const Color(0xFF333333),
      );
      expect(merged.size, base.size);
    });

    test('presets reproduce the shipped box', () {
      final OrionCheckboxStyle style = OrionCheckboxPresets.resolve(
        size: OrionCheckboxSize.medium,
        scheme: OrionColors.lightScheme,
      );

      expect(style.size, OrionSizing.iconMedium);
      expect(style.borderWidth, 1.75);
      expect(style.markSize, OrionSizing.iconSmall);
      expect(style.barWidth, OrionSpacing.space12);
      expect(style.pressedScale, 0.90);
      expect(style.radius, BorderRadius.circular(OrionRadii.radius6));
      expect(style.spring, OrionCheckboxPresets.defaultSpring);
      expect(
        style.borderColor?.resolve(const <WidgetState>{}),
        OrionColors.lightScheme.outline,
      );
      expect(
        style.borderColor?.resolve(const <WidgetState>{WidgetState.selected}),
        OrionColors.lightScheme.primary,
      );
      expect(
        style.borderColor?.resolve(const <WidgetState>{WidgetState.error}),
        OrionColors.lightScheme.error,
      );
    });

    test('from fills only the selected state', () {
      final OrionCheckboxStyle style = OrionCheckboxStyle.from(
        fillColor: const Color(0xFF123456),
      );

      expect(
        style.fillColor?.resolve(const <WidgetState>{WidgetState.selected}),
        const Color(0xFF123456),
      );
      expect(
        style.fillColor?.resolve(const <WidgetState>{}),
        Colors.transparent,
        reason: 'an unchecked box never fills',
      );
    });
  });
}
