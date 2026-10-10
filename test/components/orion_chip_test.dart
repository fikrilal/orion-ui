import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpChip(
  WidgetTester tester, {
  required bool selected,
  required ValueChanged<bool>? onSelected,
  bool disableAnimations = false,
  bool autofocus = false,
  String? semanticLabel,
  String text = 'Live',
  OrionChipSize size = OrionChipSize.medium,
  OrionChipStyle? style,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: OrionChip(
              label: Text(text),
              selected: selected,
              onSelected: onSelected,
              semanticLabel: semanticLabel,
              autofocus: autofocus,
              size: size,
              style: style,
            ),
          ),
        ),
      ),
    ),
  );
}

List<String> _captureHaptics(WidgetTester tester) {
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
  return haptics;
}

BoxDecoration _chipDecoration(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(OrionChip),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

BorderSide _chipBorder(WidgetTester tester) {
  return (_chipDecoration(tester).border! as Border).top;
}

/// Scale of the check. [OrionPressable] wraps the pill in its own transform, so
/// the check's transform is the innermost one.
double _checkScale(WidgetTester tester) {
  final List<Transform> transforms = tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(OrionChip),
          matching: find.byType(Transform),
        ),
      )
      .toList();
  return transforms.last.transform.entry(0, 0);
}

/// The label slides right as the check slot grows, so it reports the travel.
double _labelX(WidgetTester tester) => tester.getTopLeft(find.text('Live')).dx;

/// Effective label color, which the design lerps together with the fill.
Color _labelColor(WidgetTester tester) =>
    DefaultTextStyle.of(tester.element(find.text('Live'))).style.color!;

/// The painted pill, inside the hit target.
Size _pillSize(WidgetTester tester) => tester.getSize(
  find
      .descendant(
        of: find.byType(OrionChip),
        matching: find.byType(DecoratedBox),
      )
      .first,
);

/// Recovers the travel sample from the fill, which lerps secondary to primary.
/// [Color] compares its double components, so the lerped fill never equals
/// `primary` exactly until the spring snaps home.
double _fillProgress(WidgetTester tester) {
  final Color fill = _chipDecoration(tester).color!;
  final double idle = OrionColors.lightScheme.secondary.r;
  final double on = OrionColors.lightScheme.primary.r;
  return ((idle - fill.r) / (idle - on)).clamp(0.0, 1.0);
}

void main() {
  group('OrionChip', () {
    testWidgets('rests unselected with no check', (tester) async {
      await _pumpChip(tester, selected: false, onSelected: (_) {});

      expect(_chipDecoration(tester).color, OrionColors.lightScheme.secondary);
      expect(_chipBorder(tester).color, OrionColors.lightScheme.outline);
      expect(_checkScale(tester), 0);
      // The check is built but collapsed, so the label starts at the padding.
      expect(
        _labelX(tester),
        closeTo(
          tester.getTopLeft(find.byType(OrionChip)).dx + OrionSpacing.space12,
          0.01,
        ),
      );
    });

    testWidgets('fills primary and draws a check when selected', (
      tester,
    ) async {
      await _pumpChip(
        tester,
        selected: false,
        onSelected: (_) {},
        disableAnimations: true,
      );
      final double resting = _labelX(tester);

      await _pumpChip(
        tester,
        selected: true,
        onSelected: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_chipDecoration(tester).color, OrionColors.lightScheme.primary);
      expect(_chipBorder(tester).color, OrionColors.lightScheme.primary);
      expect(_checkScale(tester), 1);
      expect(find.byIcon(Icons.check), findsOneWidget);
      expect(_labelX(tester), greaterThan(resting));
    });

    testWidgets('reports the opposite value on tap', (tester) async {
      bool? reported;
      await _pumpChip(
        tester,
        selected: false,
        onSelected: (bool value) => reported = value,
      );

      await tester.tap(find.byType(OrionChip));
      expect(reported, isTrue);
    });

    testWidgets('reports false when the selected chip is tapped', (
      tester,
    ) async {
      bool? reported;
      await _pumpChip(
        tester,
        selected: true,
        onSelected: (bool value) => reported = value,
      );

      await tester.tap(find.byType(OrionChip));
      expect(reported, isFalse);
    });

    testWidgets('ignores taps when disabled', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpChip(tester, selected: false, onSelected: null);

      await tester.tap(find.byType(OrionChip));
      final SemanticsNode node = tester.getSemantics(find.byType(OrionChip));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('pins the disabled paint', (tester) async {
      await _pumpChip(
        tester,
        selected: true,
        onSelected: null,
        disableAnimations: true,
      );
      await tester.pump();

      const ColorScheme scheme = OrionColors.lightScheme;
      final Color muted = scheme.onSurface.withValues(alpha: 0.12);
      expect(_chipDecoration(tester).color, muted);
      expect(_chipBorder(tester).color, muted);
      expect(
        tester.widget<Icon>(find.byIcon(Icons.check)).color,
        scheme.onSurface.withValues(alpha: 0.38),
      );
    });

    testWidgets('flips from the keyboard', (tester) async {
      bool? reported;
      await _pumpChip(
        tester,
        selected: false,
        autofocus: true,
        onSelected: (bool value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(reported, isTrue);

      reported = null;
      await _pumpChip(
        tester,
        selected: true,
        autofocus: true,
        onSelected: (bool value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(reported, isFalse);
    });

    testWidgets('eases the fill between the two states', (tester) async {
      await _pumpChip(tester, selected: false, onSelected: (_) {});
      expect(_chipDecoration(tester).color, OrionColors.lightScheme.secondary);

      await _pumpChip(tester, selected: true, onSelected: (_) {});

      // Frame 0: the fill has not moved, so the label must not have either.
      expect(_labelColor(tester), OrionColors.lightScheme.onSurfaceVariant);

      await tester.pump(const Duration(milliseconds: 16));

      final Color mid = _chipDecoration(tester).color!;
      expect(mid, isNot(OrionColors.lightScheme.secondary));
      expect(mid, isNot(OrionColors.lightScheme.primary));
      final Color midLabel = _labelColor(tester);
      expect(midLabel, isNot(OrionColors.lightScheme.onSurfaceVariant));
      expect(midLabel, isNot(OrionColors.lightScheme.onPrimary));

      await tester.pumpAndSettle();
      expect(_chipDecoration(tester).color, OrionColors.lightScheme.primary);
      expect(_labelColor(tester), OrionColors.lightScheme.onPrimary);
    });

    testWidgets('keeps the check out of the ticker rebuilds', (tester) async {
      await _pumpChip(tester, selected: false, onSelected: (_) {});
      await _pumpChip(tester, selected: true, onSelected: (_) {});

      // OrionPressable wraps the pill in its own AnimatedBuilder, so the travel
      // builder, the one that holds the check, is the innermost builder.
      final Finder ticker = find.descendant(
        of: find.byType(OrionChip),
        matching: find.byType(AnimatedBuilder),
      );
      final Widget check = tester
          .widgetList<AnimatedBuilder>(ticker)
          .last
          .child!;
      Color previous = _chipDecoration(tester).color!;

      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));

        // The ticker really ran, so the identity check is not vacuous.
        final Color current = _chipDecoration(tester).color!;
        expect(current, isNot(previous));
        previous = current;
        expect(
          identical(
            tester.widgetList<AnimatedBuilder>(ticker).last.child,
            check,
          ),
          isTrue,
        );
      }

      await tester.pumpAndSettle();
    });

    testWidgets('pops once without stalling at a cap', (tester) async {
      await _pumpChip(tester, selected: false, onSelected: (_) {});
      await _pumpChip(tester, selected: true, onSelected: (_) {});

      final List<double> checks = <double>[];
      final List<double> fills = <double>[];
      for (var frame = 0; frame < 90; frame++) {
        checks.add(_checkScale(tester));
        fills.add(_fillProgress(tester));
        await tester.pump(const Duration(milliseconds: 16));
      }

      // A cap would pin the check at the cap; the spring only visits its peak.
      final double peak = checks.reduce(math.max);
      expect(peak, greaterThan(1));
      expect(peak, lessThan(1.1));

      // Once the fill reaches primary it never fades back out.
      final int full = fills.indexWhere((double fill) => fill >= 0.999);
      expect(full, greaterThanOrEqualTo(0));
      expect(fills.skip(full).every((double fill) => fill >= 0.98), isTrue);

      await tester.pumpAndSettle();
      expect(_checkScale(tester), closeTo(1, 0.001));
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      await _pumpChip(
        tester,
        selected: false,
        onSelected: (_) {},
        disableAnimations: true,
      );
      expect(_checkScale(tester), 0);

      await _pumpChip(
        tester,
        selected: true,
        onSelected: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_checkScale(tester), 1);
    });

    testWidgets('settles at once when motion is turned off mid-flight', (
      tester,
    ) async {
      await _pumpChip(tester, selected: false, onSelected: (_) {});
      await _pumpChip(tester, selected: true, onSelected: (_) {});
      await tester.pump(const Duration(milliseconds: 16));
      expect(_checkScale(tester), lessThan(1));

      await _pumpChip(
        tester,
        selected: true,
        onSelected: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_checkScale(tester), 1);
    });

    testWidgets('keeps a 44 pt hit target around a 32 pt pill', (tester) async {
      await _pumpChip(tester, selected: false, onSelected: (_) {});

      final Size target = tester.getSize(find.byType(OrionPressable));
      // Exact, not a floor: a hit area that grows to fill a loose bounded
      // parent is just as wrong as one that is too small.
      expect(target.height, OrionSizing.minHitTarget);
      expect(target.width, greaterThanOrEqualTo(OrionSizing.minHitTarget));
      expect(_pillSize(tester).height, OrionSizing.controlHeightSmall);
    });

    testWidgets('does not stretch inside a loose bounded box', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 120,
                child: Center(
                  child: OrionChip(
                    label: const Text('Live'),
                    selected: false,
                    onSelected: (_) {},
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(OrionChip)).height,
        OrionSizing.minHitTarget,
      );
      expect(
        tester.getSize(find.byType(OrionPressable)).height,
        OrionSizing.minHitTarget,
      );
      expect(_pillSize(tester).height, OrionSizing.controlHeightSmall);
    });

    testWidgets('keeps the hit target when the label is narrow', (
      tester,
    ) async {
      await _pumpChip(tester, selected: false, onSelected: (_) {}, text: 'i');

      expect(_pillSize(tester).width, lessThan(OrionSizing.minHitTarget));
      expect(
        tester.getSize(find.byType(OrionPressable)).width,
        greaterThanOrEqualTo(OrionSizing.minHitTarget),
      );
    });

    testWidgets('merges the spoken name and the selected state', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpChip(tester, selected: true, onSelected: (_) {});

      final SemanticsNode node = tester.getSemantics(find.byType(OrionChip));
      expect(node.label, 'Live');
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('exposes a spoken name override', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpChip(
        tester,
        selected: false,
        onSelected: (_) {},
        semanticLabel: 'Live filter',
      );

      final SemanticsNode node = tester.getSemantics(find.byType(OrionChip));
      expect(node.label, 'Live filter');
      handle.dispose();
    });

    testWidgets('paints the focus layer over the pill when focused', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      await _pumpChip(
        tester,
        selected: false,
        autofocus: true,
        onSelected: (_) {},
      );
      await tester.pumpAndSettle();

      final ColoredBox layer = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byType(OrionChip),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(
        layer.color,
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.12),
      );
      expect(
        _chipDecoration(tester).boxShadow,
        isNull,
        reason: 'focus is a state layer, not a second edge',
      );
    });

    testWidgets('steps the pill, the check and the gap with the size', (
      tester,
    ) async {
      await _pumpChip(
        tester,
        selected: true,
        onSelected: (_) {},
        size: OrionChipSize.large,
        disableAnimations: true,
      );
      await tester.pump();

      expect(_pillSize(tester).height, OrionSizing.controlHeightMedium);
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).size, 20);

      await _pumpChip(
        tester,
        selected: true,
        onSelected: (_) {},
        size: OrionChipSize.small,
        disableAnimations: true,
      );
      await tester.pump();

      expect(_pillSize(tester).height, 28);
      expect(tester.widget<Icon>(find.byIcon(Icons.check)).size, 12);
      expect(
        tester.getSize(find.byType(OrionPressable)).height,
        OrionSizing.minHitTarget,
        reason: 'the hit target does not change with the size',
      );
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionChipTheme(
            defaultStyle: OrionChipStyle.from(
              height: 36,
              fillColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpChip(
        tester,
        selected: false,
        onSelected: (_) {},
        theme: themed,
        disableAnimations: true,
      );
      expect(_chipDecoration(tester).color, const Color(0xFF00AA00));
      expect(_pillSize(tester).height, 36);

      await _pumpChip(
        tester,
        selected: false,
        onSelected: (_) {},
        theme: themed,
        disableAnimations: true,
        style: OrionChipStyle.from(fillColor: const Color(0xFFAA0000)),
      );
      expect(_chipDecoration(tester).color, const Color(0xFFAA0000));
      expect(
        _pillSize(tester).height,
        36,
        reason: 'the instance style only overrides what it names',
      );
    });

    testWidgets('emits one haptic on tap and none from the keyboard', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);

      bool? reported;
      await _pumpChip(
        tester,
        selected: false,
        autofocus: true,
        onSelected: (bool value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OrionChip));
      await tester.pump();
      expect(haptics, <String>['HapticFeedbackType.selectionClick']);
      expect(reported, isTrue);

      reported = null;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(haptics, hasLength(1));
      expect(reported, isTrue);
    });

    testWidgets('a scroll drag never selects and stays silent', (tester) async {
      final List<String> haptics = _captureHaptics(tester);

      bool? reported;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              itemExtent: 60,
              itemCount: 20,
              itemBuilder: (BuildContext context, int index) => Center(
                child: OrionChip(
                  label: Text('Chip $index'),
                  selected: false,
                  onSelected: (bool value) => reported = value,
                ),
              ),
            ),
          ),
        ),
      );

      final double resting = tester.getTopLeft(find.byType(OrionChip).first).dy;

      await tester.drag(find.byType(OrionChip).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      // The list really scrolled, so the silence below is not a missed drag.
      expect(
        tester.getTopLeft(find.byType(OrionChip).first).dy,
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
              itemBuilder: (BuildContext context, int index) => OrionChip(
                label: Text('Chip $index'),
                selected: false,
                onSelected: (bool value) => reported = value,
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionChip).first),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await gesture.moveBy(const Offset(0, -600));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(reported, isNull);
    });
  });

  group('OrionChipStyle', () {
    test('a merge only changes the fields it names', () {
      final OrionChipStyle base = OrionChipStyle.from(
        height: 28,
        fillColor: const Color(0xFF111111),
      );
      final OrionChipStyle merged = base.merge(
        OrionChipStyle.from(fillColor: const Color(0xFF333333)),
      );

      expect(
        merged.fillColor?.resolve(const <WidgetState>{}),
        const Color(0xFF333333),
      );
      expect(merged.height, base.height);
    });

    test('presets reproduce the shipped pill', () {
      final OrionChipStyle style = OrionChipPresets.resolve(
        size: OrionChipSize.medium,
        scheme: OrionColors.lightScheme,
      );

      expect(style.height, OrionSizing.controlHeightSmall);
      expect(style.borderWidth, 1);
      expect(style.checkSize, OrionSizing.iconSmall);
      expect(style.checkGap, OrionSpacing.space8);
      expect(style.radius, BorderRadius.circular(OrionRadii.radiusPill));
      expect(style.spring, OrionSpringSpec.gentle);
      expect(
        style.fillColor?.resolve(const <WidgetState>{}),
        OrionColors.lightScheme.secondary,
      );
      expect(
        style.fillColor?.resolve(const <WidgetState>{WidgetState.selected}),
        OrionColors.lightScheme.primary,
      );
      expect(
        style.labelColor?.resolve(const <WidgetState>{WidgetState.selected}),
        OrionColors.lightScheme.onPrimary,
      );
      expect(
        style.checkColor?.resolve(const <WidgetState>{WidgetState.disabled}),
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.38),
      );
    });
  });
}
