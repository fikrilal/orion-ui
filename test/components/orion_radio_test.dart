import 'dart:ui' show CheckedState, PointerDeviceKind, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

/// The two radios below form a group. The parent owns it, so the harness keeps
/// the group state here and hands each radio its own `value`.
Future<void> _pumpRadio(
  WidgetTester tester, {
  required bool value,
  required ValueChanged<bool>? onChanged,
  bool disableAnimations = false,
  bool autofocus = false,
  bool error = false,
  String? semanticLabel,
  OrionRadioSize size = OrionRadioSize.medium,
  OrionRadioStyle? style,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: OrionRadio(
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

/// Pumps two radios that share one integer group value.
Future<void> _pumpGroup(
  WidgetTester tester, {
  required int selected,
  required ValueChanged<int> onChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              OrionRadio(
                value: selected == 0,
                semanticLabel: 'First',
                onChanged: (_) => onChanged(0),
              ),
              OrionRadio(
                value: selected == 1,
                semanticLabel: 'Second',
                onChanged: (_) => onChanged(1),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

/// The ring is the first [DecoratedBox]; the dot is nested inside it.
BoxDecoration _ring(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(OrionRadio),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

BorderSide _ringBorder(WidgetTester tester) =>
    (_ring(tester).border! as Border).top;

Color _dotColor(WidgetTester tester) {
  final DecoratedBox dot = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(OrionRadio),
          matching: find.byType(DecoratedBox),
        )
        .last,
  );
  return (dot.decoration as BoxDecoration).color!;
}

/// Scale applied to the dot by the travel spring.
double _dotScale(WidgetTester tester) {
  final Transform transform = tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(OrionRadio),
          matching: find.byType(Transform),
        ),
      )
      // ...and the dot is the innermost transform, after the ring.
      .last;
  return transform.transform.entry(0, 0);
}

void main() {
  group('OrionRadio', () {
    testWidgets('rests as an empty circle when unselected', (tester) async {
      await _pumpRadio(tester, value: false, onChanged: (_) {});

      expect(_ringBorder(tester).color, OrionColors.lightScheme.outline);
      expect(_ring(tester).shape, BoxShape.circle);
      expect(_dotScale(tester), 0);
    });

    testWidgets('draws a primary ring and dot when selected', (tester) async {
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_ringBorder(tester).color, OrionColors.lightScheme.primary);
      expect(_dotScale(tester), 1);
      expect(_dotColor(tester), OrionColors.lightScheme.primary);
    });

    testWidgets('never fills the interior, unlike the checkbox', (
      tester,
    ) async {
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      // The ring keeps a transparent interior in both states; only the dot
      // carries the selected colour.
      expect(_ring(tester).color, isNull);
    });

    testWidgets('reports true on tap, even when already selected', (
      tester,
    ) async {
      bool? reported;
      await _pumpRadio(
        tester,
        value: false,
        onChanged: (bool value) => reported = value,
      );

      await tester.tap(find.byType(OrionRadio));
      expect(reported, isTrue);

      reported = null;
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (bool value) => reported = value,
      );
      await tester.tap(find.byType(OrionRadio));

      // A radio cannot be switched off, so activating it again still reports
      // true. Nothing in this widget can ever report false.
      expect(reported, isTrue);
    });

    testWidgets('selects on Enter and Space without reporting false', (
      tester,
    ) async {
      final List<bool> reported = <bool>[];
      await _pumpRadio(
        tester,
        value: false,
        autofocus: true,
        onChanged: reported.add,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(reported, <bool>[true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(reported, <bool>[true, true]);
    });

    testWidgets('jumps to the selected state under reduced motion', (
      tester,
    ) async {
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );

      // No pump: reduced motion applies the value in the same frame.
      expect(_dotScale(tester), 1);
    });

    testWidgets('travels toward the new state instead of snapping', (
      tester,
    ) async {
      await _pumpRadio(tester, value: false, onChanged: (_) {});
      await _pumpRadio(tester, value: true, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      final double travelled = _dotScale(tester);
      expect(travelled, greaterThan(0));
      expect(travelled, lessThan(1));
    });

    testWidgets('settles at full scale after the travel', (tester) async {
      await _pumpRadio(tester, value: false, onChanged: (_) {});
      await _pumpRadio(tester, value: true, onChanged: (_) {});
      await tester.pumpAndSettle();

      expect(_dotScale(tester), closeTo(1, 0.001));
    });

    testWidgets('reports nothing and stays inert when disabled', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      var taps = 0;
      await _pumpRadio(
        tester,
        value: false,
        semanticLabel: 'Unavailable',
        onChanged: null,
      );

      await tester.tap(find.byType(OrionRadio));
      expect(taps, 0);

      final ColorScheme scheme = OrionColors.lightScheme;
      final SemanticsNode node = tester.getSemantics(find.byType(OrionRadio));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        _ringBorder(tester).color,
        scheme.onSurface.withValues(alpha: 0.12),
      );
      expect(_dotColor(tester), scheme.onSurface.withValues(alpha: 0.38));
      handle.dispose();
    });

    testWidgets('exposes the selected state and the exclusive group', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpRadio(
        tester,
        value: true,
        disableAnimations: true,
        semanticLabel: 'Monthly',
        onChanged: (_) {},
      );
      await tester.pump();

      final SemanticsNode node = tester.getSemantics(find.byType(OrionRadio));
      expect(node.flagsCollection.isChecked, CheckedState.isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });

    testWidgets('lets only one radio in a group be selected', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      int selected = 0;
      await _pumpGroup(tester, selected: selected, onChanged: (_) {});

      await _pumpGroup(
        tester,
        selected: selected,
        onChanged: (int value) => selected = value,
      );

      final Finder second = find.byType(OrionRadio).last;
      await tester.tap(second);
      await tester.pump();

      expect(selected, 1);

      // The parent now reports the second radio as selected and the first as
      // not; the widget itself has no memory of the group.
      await _pumpGroup(
        tester,
        selected: selected,
        onChanged: (int value) => selected = value,
      );
      await tester.pumpAndSettle();

      final List<double> scales = tester
          .widgetList<Transform>(
            find.descendant(
              of: find.byType(OrionRadio),
              matching: find.byType(Transform),
            ),
          )
          .map((Transform t) => t.transform.entry(0, 0))
          .toList();
      // The first scale belongs to the pressable wrapping the control; after it come
      // the ring and then the dot, whatever else the surrounding group adds.
      expect(scales.skip(1).first, closeTo(0, 0.001));
      expect(scales.last, closeTo(1, 0.001));
      handle.dispose();
    });

    testWidgets('refuses focus and draws no ring while disabled', (
      tester,
    ) async {
      await _pumpRadio(tester, value: false, autofocus: true, onChanged: null);
      await tester.pump();

      // A disabled radio must not be reachable by keyboard traversal, so the
      // focus highlight can never be requested either.
      final FocusableActionDetector detector = tester
          .widget<FocusableActionDetector>(
            find.byType(FocusableActionDetector),
          );
      expect(detector.enabled, isFalse);
      expect(_ring(tester).boxShadow, isNull);
    });

    testWidgets('paints the focus overlay under the circle when focused', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      await _pumpRadio(
        tester,
        value: false,
        autofocus: true,
        onChanged: (_) {},
      );
      await tester.pumpAndSettle();

      final ColoredBox overlay = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(OrionRadio),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(
        overlay.color,
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.12),
      );
      expect(
        _ring(tester).boxShadow,
        isNull,
        reason: 'focus is an overlay, not a second ring',
      );
    });

    testWidgets('steps the circle and the dot with the size', (tester) async {
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        size: OrionRadioSize.large,
        disableAnimations: true,
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(28, 28),
      );
      expect(
        tester.getSize(find.byType(DecoratedBox).last),
        const Size(10, 10),
      );

      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        size: OrionRadioSize.small,
        disableAnimations: true,
      );
      await tester.pump();

      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(20, 20),
      );
      expect(tester.getSize(find.byType(DecoratedBox).last), const Size(7, 7));
      expect(
        tester.getSize(find.byType(OrionRadio)),
        const Size(OrionSizing.minHitTarget, OrionSizing.minHitTarget),
        reason: 'the hit target does not change with the size',
      );
    });

    testWidgets('animates the ring out when deselected', (tester) async {
      const ColorScheme scheme = OrionColors.lightScheme;
      await _pumpRadio(tester, value: true, onChanged: (_) {});
      await tester.pumpAndSettle();
      expect(_ringBorder(tester).color, scheme.primary);

      await _pumpRadio(tester, value: false, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      expect(
        _ringBorder(tester).color,
        isNot(scheme.outline),
        reason: 'the ring travels back instead of snapping on frame 0',
      );
      expect(_ringBorder(tester).color, isNot(scheme.primary));

      await tester.pumpAndSettle();
      expect(_ringBorder(tester).color, scheme.outline);
      expect(_dotScale(tester), 0);
    });

    testWidgets('paints the error role', (tester) async {
      const ColorScheme scheme = OrionColors.lightScheme;
      await _pumpRadio(
        tester,
        value: false,
        onChanged: (_) {},
        error: true,
        disableAnimations: true,
      );

      expect(_ringBorder(tester).color, scheme.error);

      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        error: true,
        disableAnimations: true,
      );
      await tester.pump();

      expect(_ringBorder(tester).color, scheme.error);
      expect(_dotColor(tester), scheme.error);
    });

    testWidgets('keeps the interior transparent until a fill is given', (
      tester,
    ) async {
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      final ColoredBox interior = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(OrionRadio),
              matching: find.byType(ColoredBox),
            )
            .last,
      );
      expect(interior.color.a, 0);

      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionRadioStyle.from(fillColor: OrionColors.lightScheme.primary),
      );
      await tester.pump();

      final ColoredBox filled = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(OrionRadio),
              matching: find.byType(ColoredBox),
            )
            .last,
      );
      expect(filled.color, OrionColors.lightScheme.primary);
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionRadioTheme(
            defaultStyle: OrionRadioStyle.from(
              size: 18,
              ringColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpRadio(
        tester,
        value: false,
        onChanged: (_) {},
        theme: themed,
        disableAnimations: true,
      );
      expect(_ringBorder(tester).color, const Color(0xFF00AA00));
      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(18, 18),
      );

      await _pumpRadio(
        tester,
        value: false,
        onChanged: (_) {},
        theme: themed,
        disableAnimations: true,
        style: OrionRadioStyle.from(ringColor: const Color(0xFFAA0000)),
      );
      expect(_ringBorder(tester).color, const Color(0xFFAA0000));
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
      await _pumpRadio(
        tester,
        value: false,
        autofocus: true,
        onChanged: (bool value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OrionRadio));
      await tester.pump();
      expect(haptics, <String>['HapticFeedbackType.selectionClick']);
      expect(reported, isTrue);

      reported = null;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(haptics, hasLength(1));
      expect(reported, isTrue);
    });

    testWidgets('keeps the dot out of the ticker rebuilds', (tester) async {
      await _pumpRadio(tester, value: false, onChanged: (_) {});
      await _pumpRadio(tester, value: true, onChanged: (_) {});

      final Finder ticker = find.descendant(
        of: find.byType(OrionRadio),
        matching: find.byType(AnimatedBuilder),
      );
      final Widget dot = tester
          .widgetList<AnimatedBuilder>(ticker)
          .first
          .child!;
      BorderSide previous = _ringBorder(tester);
      var changedFrames = 0;

      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));

        // The ticker really ran, so the identity check is not vacuous.
        final BorderSide current = _ringBorder(tester);
        if (current.color != previous.color) changedFrames++;
        previous = current;

        final Widget currentDot = tester
            .widgetList<AnimatedBuilder>(ticker)
            .first
            .child!;
        expect(identical(currentDot, dot), isTrue);
      }

      expect(changedFrames, greaterThan(0));
    });

    testWidgets('a scroll drag never selects and stays silent', (tester) async {
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
                child: OrionRadio(
                  value: false,
                  onChanged: (bool value) => reported = value,
                ),
              ),
            ),
          ),
        ),
      );

      final double resting = tester
          .getTopLeft(find.byType(OrionRadio).first)
          .dy;

      await tester.drag(find.byType(OrionRadio).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // The list really scrolled, so the silence below is not a missed drag.
      expect(
        tester.getTopLeft(find.byType(OrionRadio).first).dy,
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
              itemBuilder: (BuildContext context, int index) => OrionRadio(
                value: false,
                onChanged: (bool value) => reported = value,
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionRadio).first),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // Drag the held circle out of the viewport, then release over nothing.
      await gesture.moveBy(const Offset(0, -600));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(reported, isNull);
    });
  });

  group('OrionRadioStyle', () {
    test('a merge only changes the fields it names', () {
      final OrionRadioStyle base = OrionRadioStyle.from(
        size: 20,
        ringColor: const Color(0xFF111111),
      );
      final OrionRadioStyle merged = base.merge(
        OrionRadioStyle.from(ringColor: const Color(0xFF333333)),
      );

      expect(
        merged.ringColor?.resolve(const <WidgetState>{}),
        const Color(0xFF333333),
      );
      expect(merged.size, base.size);
    });

    test('presets reproduce the shipped circle', () {
      final OrionRadioStyle style = OrionRadioPresets.resolve(
        size: OrionRadioSize.medium,
        scheme: OrionColors.lightScheme,
      );

      expect(style.size, OrionSizing.iconMedium);
      expect(style.dotSize, OrionSizing.iconSmall * 0.5);
      expect(style.borderWidth, 2);
      expect(style.pressedScale, 0.90);
      expect(style.spring, OrionRadioPresets.defaultSpring);
      expect(
        style.ringColor?.resolve(const <WidgetState>{}),
        OrionColors.lightScheme.outline,
      );
      expect(
        style.ringColor?.resolve(const <WidgetState>{WidgetState.hovered}),
        Color.lerp(
          OrionColors.lightScheme.outline,
          OrionColors.lightScheme.onSurface,
          0.25,
        ),
      );
      expect(
        style.ringColor?.resolve(const <WidgetState>{WidgetState.selected}),
        OrionColors.lightScheme.primary,
      );
      expect(
        style.ringColor?.resolve(const <WidgetState>{WidgetState.error}),
        OrionColors.lightScheme.error,
      );
      expect(
        style.fillColor?.resolve(const <WidgetState>{}),
        Colors.transparent,
      );
      expect(
        style.hoverOverlayColor,
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.05),
      );
    });

    test('from fills only the selected state', () {
      final OrionRadioStyle style = OrionRadioStyle.from(
        fillColor: const Color(0xFF123456),
      );

      expect(
        style.fillColor?.resolve(const <WidgetState>{WidgetState.selected}),
        const Color(0xFF123456),
      );
      expect(
        style.fillColor?.resolve(const <WidgetState>{}),
        Colors.transparent,
        reason: 'the interior stays transparent while unselected',
      );
    });

    test('lerp interpolates scalars, colours, and theme extensions', () {
      final OrionRadioStyle a = OrionRadioStyle.from(
        ringColor: const Color(0xFF000000),
        dotColor: const Color(0xFF000000),
        fillColor: const Color(0xFF000000),
        size: 20,
        dotSize: 6,
        borderWidth: 1,
        pressedScale: 0.88,
        focusOverlayColor: const Color(0x00000000),
        hoverOverlayColor: const Color(0x00000000),
      );
      final OrionRadioStyle b = OrionRadioStyle.from(
        ringColor: const Color(0xFFFFFFFF),
        dotColor: const Color(0xFFFFFFFF),
        fillColor: const Color(0xFFFFFFFF),
        size: 28,
        dotSize: 10,
        borderWidth: 3,
        pressedScale: 0.96,
        focusOverlayColor: const Color(0xFF000000),
        hoverOverlayColor: const Color(0xFF000000),
      );

      final OrionRadioTheme lerpedTheme = OrionRadioTheme(
        defaultStyle: a,
      ).lerp(OrionRadioTheme(defaultStyle: b), 0.5);
      final OrionRadioStyle mid = lerpedTheme.defaultStyle!;

      expect(mid.size, closeTo(24, 0.001));
      expect(mid.dotSize, closeTo(8, 0.001));
      expect(mid.borderWidth, closeTo(2, 0.001));
      expect(mid.pressedScale, closeTo(0.92, 0.001));
      expect(
        mid.ringColor?.resolve(const <WidgetState>{}),
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
      expect(
        mid.fillColor?.resolve(const <WidgetState>{WidgetState.selected}),
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
      expect(
        mid.focusOverlayColor,
        Color.lerp(const Color(0x00000000), const Color(0xFF000000), 0.5),
      );
      expect(
        mid.hoverOverlayColor,
        Color.lerp(const Color(0x00000000), const Color(0xFF000000), 0.5),
      );
    });
  });

  group('OrionRadio upgrades', () {
    testWidgets('resolves custom unselected fillColor without dropping it', (
      tester,
    ) async {
      const Color restFill = Color(0xFFEEEEEE);
      const Color selectedFill = Color(0xFF222222);
      final OrionRadioStyle style = OrionRadioStyle(
        fillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.selected) ? selectedFill : restFill,
        ),
      );

      await _pumpRadio(
        tester,
        value: false,
        onChanged: (_) {},
        disableAnimations: true,
        style: style,
      );
      await tester.pump();

      final ColoredBox restingInterior = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(OrionRadio),
              matching: find.byType(ColoredBox),
            )
            .last,
      );
      expect(restingInterior.color, restFill);

      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
        style: style,
      );
      await tester.pump();

      final ColoredBox selectedInterior = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(OrionRadio),
              matching: find.byType(ColoredBox),
            )
            .last,
      );
      expect(selectedInterior.color, selectedFill);
    });

    testWidgets('expands hit target for custom sizes larger than 44 pt', (
      tester,
    ) async {
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionRadioStyle.from(size: 56),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(OrionRadio)), const Size(56, 56));
      expect(
        tester.getSize(find.byType(DecoratedBox).first),
        const Size(56, 56),
      );
    });

    testWidgets('omits border cleanly when borderWidth is zero or negative', (
      tester,
    ) async {
      await _pumpRadio(
        tester,
        value: false,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionRadioStyle.from(borderWidth: 0),
      );
      expect(_ring(tester).border, isNull);

      await _pumpRadio(
        tester,
        value: false,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionRadioStyle.from(borderWidth: -2),
      );
      expect(tester.takeException(), isNull);
      expect(_ring(tester).border, isNull);
    });

    testWidgets('shows hover overlay and ring emphasis on pointer hover', (
      tester,
    ) async {
      await _pumpRadio(tester, value: false, onChanged: (_) {});

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();

      await mouse.moveTo(tester.getCenter(find.byType(OrionRadio)));
      await tester.pump();

      final ColoredBox hoverHalo = tester.widget<ColoredBox>(
        find
            .descendant(
              of: find.byType(OrionRadio),
              matching: find.byType(ColoredBox),
            )
            .first,
      );
      expect(
        hoverHalo.color,
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.05),
      );
      expect(
        _ringBorder(tester).color,
        Color.lerp(
          OrionColors.lightScheme.outline,
          OrionColors.lightScheme.onSurface,
          0.25,
        ),
      );

      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(_ringBorder(tester).color, OrionColors.lightScheme.outline);
    });

    testWidgets('stays silent when retapping an already-selected radio', (
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
      await _pumpRadio(
        tester,
        value: true,
        onChanged: (bool value) => reported = value,
      );

      await tester.tap(find.byType(OrionRadio));
      await tester.pump();

      expect(reported, isTrue);
      expect(haptics, isEmpty);
    });

    testWidgets('supports clickable label and subtitle rows', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      bool? reported;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionRadio(
                value: false,
                label: 'Annual billing',
                subtitle: 'Save 20% every year',
                onChanged: (bool value) => reported = value,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Annual billing'), findsOneWidget);
      expect(find.text('Save 20% every year'), findsOneWidget);

      final SemanticsNode node = tester.getSemantics(find.byType(OrionRadio));
      expect(node.label, 'Annual billing');

      await tester.tap(find.text('Annual billing'));
      await tester.pump();
      expect(reported, isTrue);

      reported = null;
      await tester.tap(find.text('Save 20% every year'));
      await tester.pump();
      expect(reported, isTrue);
      handle.dispose();
    });
  });
}
