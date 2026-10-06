import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

/// The slider under test fills 200 pt, so the thumb center travels 180 pt.
const double _sliderWidth = 200;
const double _thumbSize = 20;

Future<void> _pumpSlider(
  WidgetTester tester, {
  required double value,
  required ValueChanged<double>? onChanged,
  double min = 0,
  double max = 1,
  double? step,
  bool disableAnimations = false,
  bool autofocus = false,
  String? semanticLabel,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: Directionality(
              textDirection: textDirection,
              child: SizedBox(
                width: _sliderWidth,
                child: OrionSlider(
                  value: value,
                  onChanged: onChanged,
                  min: min,
                  max: max,
                  step: step,
                  semanticLabel: semanticLabel,
                  autofocus: autofocus,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// A parent that applies every reported value, the way a real screen does.
Future<void> _pumpHost(
  WidgetTester tester, {
  required double initial,
  double? step,
  ValueChanged<double>? onChanged,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: _sliderWidth,
            child: _SliderHost(
              initial: initial,
              step: step,
              onChanged: onChanged,
            ),
          ),
        ),
      ),
    ),
  );
}

class _SliderHost extends StatefulWidget {
  const _SliderHost({required this.initial, this.step, this.onChanged});

  final double initial;
  final double? step;
  final ValueChanged<double>? onChanged;

  @override
  State<_SliderHost> createState() => _SliderHostState();
}

class _SliderHostState extends State<_SliderHost> {
  late double _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return OrionSlider(
      value: _value,
      step: widget.step,
      autofocus: true,
      onChanged: (double value) {
        widget.onChanged?.call(value);
        setState(() => _value = value);
      },
    );
  }
}

/// The value the slider is currently showing.
double _value(WidgetTester tester) =>
    tester.widget<OrionSlider>(find.byType(OrionSlider)).value;

Finder _thumbFinder() => find.descendant(
  of: find.byType(OrionSlider),
  matching: find.byWidgetPredicate(
    (Widget widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.circle,
  ),
);

/// The scaled fill. The thumb is also `primary`, so the shape separates them.
Finder _fillFinder() => find.descendant(
  of: find.byType(OrionSlider),
  matching: find.byWidgetPredicate(
    (Widget widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).shape == BoxShape.rectangle &&
        (widget.decoration as BoxDecoration).color ==
            OrionColors.lightScheme.primary,
  ),
);

/// The track sits before the fill in the track stack.
Finder _trackFinder() => find
    .descendant(
      of: find.descendant(
        of: find.byType(OrionSlider),
        matching: find.byType(ClipRRect),
      ),
      matching: find.byType(DecoratedBox),
    )
    .first;

BoxDecoration _trackDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_trackFinder()).decoration as BoxDecoration;

BoxDecoration _thumbDecoration(WidgetTester tester) =>
    tester.widget<DecoratedBox>(_thumbFinder()).decoration as BoxDecoration;

/// The painted fraction of the thumb center along the track, from the leading
/// edge: 0 at `min`, 1 at `max`. Read from the render transform, so it is the
/// real on-screen position rather than a copied number.
double _thumbFraction(WidgetTester tester) {
  final Rect slider = tester.getRect(find.byType(OrionSlider));
  final double travel = slider.width - _thumbSize;
  final double drawn = tester.getCenter(_thumbFinder()).dx - slider.left;
  return (drawn - _thumbSize / 2) / travel;
}

/// The painted width of the fill as a fraction of the track.
double _fillFraction(WidgetTester tester) {
  final Rect track = tester.getRect(_trackFinder());
  return tester.getRect(_fillFinder()).width / track.width;
}

/// Drags from the leading edge of the slider to [fraction] of the track.
///
/// The move is a single real pointer move, far enough to pass the touch slop
/// the slider waits for.
Future<TestGesture> _dragTo(
  WidgetTester tester,
  double fraction, {
  double from = 0,
}) async {
  final Rect box = tester.getRect(find.byType(OrionSlider));
  final double travel = box.width - _thumbSize;
  final TestGesture gesture = await tester.startGesture(
    Offset(box.left + _thumbSize / 2 + travel * from, box.center.dy),
  );
  await tester.pump();
  await gesture.moveBy(Offset(travel * (fraction - from), 0));
  await tester.pump();
  return gesture;
}

/// Consumes the ticker's first tick, which carries zero elapsed time, so the
/// frames after it show real movement.
Future<void> _settleFrame(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 16));
}

void main() {
  group('OrionSlider', () {
    testWidgets('follows the pointer exactly at every step of a drag', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await _pumpSlider(tester, value: 0, onChanged: reported.add);

      final TestGesture gesture = await _dragTo(tester, 0.25);
      expect(reported.last, closeTo(0.25, 1e-9));
      expect(_thumbFraction(tester), closeTo(0.25, 0.002));
      expect(_fillFraction(tester), closeTo(0.25, 0.002));

      final Rect box = tester.getRect(find.byType(OrionSlider));
      final double travel = box.width - _thumbSize;
      await gesture.moveBy(Offset(travel * 0.25, 0));
      await tester.pump();
      expect(reported.last, closeTo(0.5, 1e-9));
      expect(_thumbFraction(tester), closeTo(0.5, 0.002));

      await gesture.moveBy(Offset(travel * 0.25, 0));
      await tester.pump();
      expect(reported.last, closeTo(0.75, 1e-9));
      expect(_thumbFraction(tester), closeTo(0.75, 0.002));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(reported.last, closeTo(0.75, 1e-9));
      expect(_thumbFraction(tester), closeTo(0.75, 0.002));
    });

    testWidgets('clamps at both bounds', (tester) async {
      final List<double> reported = <double>[];
      await _pumpSlider(tester, value: 0.5, onChanged: reported.add);

      final TestGesture gesture = await _dragTo(tester, 0.5);
      await gesture.moveBy(const Offset(-400, 0));
      await tester.pump();
      expect(reported.last, 0);
      expect(_thumbFraction(tester), closeTo(0, 0.002));
      expect(_fillFraction(tester), closeTo(0, 0.002));

      await gesture.moveBy(const Offset(800, 0));
      await tester.pump();
      expect(reported.last, 1);
      expect(_thumbFraction(tester), closeTo(1, 0.002));
      expect(_fillFraction(tester), closeTo(1, 0.002));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'a zero-width range reports nothing and never divides by zero',
      (tester) async {
        final List<double> reported = <double>[];
        await _pumpSlider(
          tester,
          value: 5,
          min: 5,
          max: 5,
          onChanged: reported.add,
        );

        final TestGesture gesture = await _dragTo(tester, 0.2);
        await gesture.moveBy(const Offset(120, 0));
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        expect(reported, isEmpty);
        expect(_thumbFraction(tester), 0);
      },
    );

    testWidgets('snaps to a step on release, not during the drag', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await _pumpSlider(tester, value: 0, step: 0.25, onChanged: reported.add);

      final TestGesture gesture = await _dragTo(tester, 0.3);
      // Mid-drag the thumb is under the pointer, on the raw value.
      expect(reported.last, closeTo(0.3, 1e-9));
      expect(_thumbFraction(tester), closeTo(0.3, 0.002));

      await gesture.up();
      // The release reports the nearest step and the thumb glides onto it.
      expect(reported.last, closeTo(0.25, 1e-9));
      await _settleFrame(tester);
      final double gliding = _thumbFraction(tester);
      expect(gliding, lessThan(0.3));
      expect(gliding, greaterThan(0.25));

      await tester.pumpAndSettle();
      expect(_thumbFraction(tester), closeTo(0.25, 0.002));
      expect(_fillFraction(tester), closeTo(0.25, 0.002));
    });

    testWidgets('snaps a fractional step', (tester) async {
      final List<double> reported = <double>[];
      await _pumpSlider(tester, value: 0, step: 0.1, onChanged: reported.add);

      final TestGesture down = await _dragTo(tester, 0.34);
      await down.up();
      expect(reported.last, closeTo(0.3, 1e-6));

      final TestGesture up = await _dragTo(tester, 0.36);
      await up.up();
      expect(reported.last, closeTo(0.4, 1e-6));

      await tester.pumpAndSettle();
      expect(_thumbFraction(tester), closeTo(0.4, 0.002));
    });

    testWidgets('steps with the arrows and jumps to the bounds', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await _pumpHost(tester, initial: 0.5, step: 0.1, onChanged: reported.add);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();
      expect(_value(tester), closeTo(0.6, 1e-9));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();
      expect(_value(tester), closeTo(0.5, 1e-9));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pump();
      expect(_value(tester), closeTo(0.6, 1e-9));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pump();
      expect(_value(tester), closeTo(0.5, 1e-9));

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pump();
      expect(_value(tester), 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(_value(tester), 0);
      expect(reported.last, 0);
      expect(_thumbFraction(tester), closeTo(0, 0.002));
    });

    testWidgets('steps a twentieth of the range without a step', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await _pumpHost(tester, initial: 0.5, onChanged: reported.add);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pumpAndSettle();

      expect(_value(tester), closeTo(0.55, 1e-9));
      expect(reported.last, closeTo(0.55, 1e-9));
      expect(_thumbFraction(tester), closeTo(0.55, 0.002));
    });

    testWidgets('mirrors the drag and the arrows under right-to-left', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await _pumpSlider(
        tester,
        value: 0.5,
        step: 0.1,
        autofocus: true,
        textDirection: TextDirection.rtl,
        onChanged: reported.add,
      );
      await tester.pumpAndSettle();

      // Right decreases in a mirrored layout, and left increases.
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(reported.last, closeTo(0.4, 1e-9));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(reported.last, closeTo(0.6, 1e-9));

      // The thumb starts at the trailing edge, so a drag to the right of the
      // track is a smaller value and the fill grows from the right.
      final TestGesture gesture = await _dragTo(tester, 0.75);
      expect(reported.last, closeTo(0.25, 1e-9));
      expect(1 - _thumbFraction(tester), closeTo(0.25, 0.002));

      final Rect slider = tester.getRect(find.byType(OrionSlider));
      final Rect fill = tester.getRect(_fillFinder());
      expect(fill.right, closeTo(slider.right - _thumbSize / 2, 0.01));
      expect(_fillFraction(tester), closeTo(0.25, 0.002));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('keeps the track, the fill, and the thumb out of drag frames', (
      tester,
    ) async {
      await _pumpSlider(tester, value: 0, onChanged: (_) {});

      // The first touch flips the focus highlight mode, which rebuilds the
      // focus scope once. That is framework churn, not ticker work.
      await tester.tapAt(tester.getCenter(find.byType(OrionSlider)));
      await tester.pump();

      final DecoratedBox track = tester.widget<DecoratedBox>(_trackFinder());
      final Widget fill = tester
          .widgetList<AnimatedBuilder>(
            find.descendant(
              of: find.byType(OrionSlider),
              matching: find.byType(AnimatedBuilder),
            ),
          )
          .first
          .child!;
      final BoxDecoration thumb = _thumbDecoration(tester);

      final List<Element> rebuilt = <Element>[];
      debugOnRebuildDirtyWidget = (Element element, bool builtOnce) =>
          rebuilt.add(element);
      addTearDown(() => debugOnRebuildDirtyWidget = null);

      final Rect box = tester.getRect(find.byType(OrionSlider));
      final TestGesture gesture = await tester.startGesture(
        Offset(box.left + _thumbSize / 2, box.center.dy),
      );
      // The first move has to pass the touch slop the slider waits for before
      // the frames below can be counted.
      await gesture.moveBy(const Offset(24, 0));
      await tester.pump();
      double previous = _thumbFraction(tester);
      for (var frame = 0; frame < 8; frame++) {
        await gesture.moveBy(const Offset(12, 0));
        await tester.pump(const Duration(milliseconds: 16));

        // The ticker really moved the thumb, so the identity checks below are
        // not vacuous.
        final double current = _thumbFraction(tester);
        expect(current, greaterThan(previous));
        previous = current;
        expect(
          identical(tester.widget<DecoratedBox>(_trackFinder()), track),
          isTrue,
        );
        expect(
          identical(
            tester
                .widgetList<AnimatedBuilder>(
                  find.descendant(
                    of: find.byType(OrionSlider),
                    matching: find.byType(AnimatedBuilder),
                  ),
                )
                .first
                .child,
            fill,
          ),
          isTrue,
        );
        expect(identical(_thumbDecoration(tester), thumb), isTrue);
      }

      await gesture.up();
      await tester.pumpAndSettle();

      final Iterable<Element> inside = rebuilt.where(
        (Element element) =>
            element.findAncestorWidgetOfExactType<OrionSlider>() != null,
      );
      // Only the two AnimatedBuilders rebuild; the widget build never runs and
      // the pre-built decorations keep their identity.
      expect(
        inside.where((Element element) => element.widget is! AnimatedBuilder),
        isEmpty,
      );
      expect(
        inside.where((Element element) => element.widget is AnimatedBuilder),
        isNotEmpty,
      );
    });

    testWidgets('keeps the release settle out of the widget build', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await _pumpSlider(tester, value: 0, step: 0.25, onChanged: reported.add);

      // Warm the focus highlight mode before the settle is measured.
      await tester.tapAt(tester.getCenter(find.byType(OrionSlider)));
      await tester.pump();

      final TestGesture gesture = await _dragTo(tester, 0.3);
      await gesture.up();

      final List<Element> rebuilt = <Element>[];
      debugOnRebuildDirtyWidget = (Element element, bool builtOnce) =>
          rebuilt.add(element);
      addTearDown(() => debugOnRebuildDirtyWidget = null);

      await tester.pump();
      double previous = _thumbFraction(tester);
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double current = _thumbFraction(tester);
        expect(current, lessThan(previous));
        previous = current;
      }
      await tester.pumpAndSettle();
      expect(_thumbFraction(tester), closeTo(0.25, 0.002));

      final Iterable<Element> inside = rebuilt.where(
        (Element element) =>
            element.findAncestorWidgetOfExactType<OrionSlider>() != null,
      );
      expect(
        inside.where((Element element) => element.widget is! AnimatedBuilder),
        isEmpty,
      );
      expect(
        inside.where((Element element) => element.widget is AnimatedBuilder),
        isNotEmpty,
      );
    });

    testWidgets('lands on the exact value when the parent drives it', (
      tester,
    ) async {
      await _pumpSlider(tester, value: 0, onChanged: (_) {});
      expect(_thumbFraction(tester), 0);

      await _pumpSlider(tester, value: 0.8, onChanged: (_) {});
      await _settleFrame(tester);
      final double gliding = _thumbFraction(tester);
      expect(gliding, greaterThan(0));
      expect(gliding, lessThan(0.8));

      await tester.pumpAndSettle();
      expect(_thumbFraction(tester), closeTo(0.8, 0.002));
      expect(_fillFraction(tester), closeTo(0.8, 0.002));
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      final List<double> reported = <double>[];
      await _pumpSlider(
        tester,
        value: 0,
        step: 0.25,
        disableAnimations: true,
        onChanged: reported.add,
      );

      final TestGesture gesture = await _dragTo(tester, 0.3);
      await gesture.up();
      await tester.pump();

      expect(reported.last, closeTo(0.25, 1e-9));
      expect(_thumbFraction(tester), closeTo(0.25, 0.002));
    });

    testWidgets('settles at once when motion is turned off mid-flight', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await _pumpSlider(tester, value: 0, step: 0.25, onChanged: reported.add);

      final TestGesture gesture = await _dragTo(tester, 0.3);
      await gesture.up();
      await _settleFrame(tester);
      expect(_thumbFraction(tester), greaterThan(0.25));
      expect(_thumbFraction(tester), lessThan(0.3));

      // Motion is turned off while the settle is still running.
      await _pumpSlider(
        tester,
        value: 0.25,
        step: 0.25,
        disableAnimations: true,
        onChanged: reported.add,
      );
      await tester.pump();

      expect(_thumbFraction(tester), closeTo(0.25, 0.002));
    });

    testWidgets('ignores drags when disabled', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpSlider(tester, value: 0.25, onChanged: null);

      final TestGesture gesture = await _dragTo(tester, 0.2);
      await gesture.moveBy(const Offset(120, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(_thumbFraction(tester), closeTo(0.25, 0.002));
      final SemanticsNode node = tester.getSemantics(find.byType(OrionSlider));
      expect(node.flagsCollection.isSlider, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        false,
      );
      handle.dispose();
    });

    testWidgets('paints an outline track with a primary thumb', (tester) async {
      await _pumpSlider(tester, value: 0.5, onChanged: (_) {});
      final ColorScheme scheme = OrionColors.lightScheme;

      expect(_trackDecoration(tester).color, scheme.outline);
      expect(_thumbDecoration(tester).color, scheme.primary);
    });

    testWidgets('pins the disabled paint', (tester) async {
      await _pumpSlider(tester, value: 0.5, onChanged: null);
      final ColorScheme scheme = OrionColors.lightScheme;

      expect(
        _trackDecoration(tester).color,
        scheme.onSurface.withValues(alpha: 0.12),
      );
      expect(
        _thumbDecoration(tester).color,
        scheme.onSurface.withValues(alpha: 0.38),
      );
    });

    testWidgets('exposes the value, the bounds, and the actions', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<double> reported = <double>[];
      await _pumpSlider(
        tester,
        value: 0.5,
        step: 0.1,
        semanticLabel: 'Volume',
        onChanged: reported.add,
      );

      final SemanticsNode node = tester.getSemantics(find.byType(OrionSlider));
      expect(node.flagsCollection.isSlider, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isTrue);
      expect(node.label, 'Volume');
      expect(node.value, '0.5');
      expect(node.increasedValue, '0.6');
      expect(node.decreasedValue, '0.4');
      expect(node.hint, 'Between 0 and 1');
      // A slider is not a scrollable, so the drag recognizer's default scroll
      // actions stay out of the node.
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.scrollLeft),
        false,
      );
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.scrollRight),
        false,
      );

      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.increase,
      );
      await tester.pump();
      expect(reported.last, closeTo(0.6, 1e-9));

      // The harness records without applying, so each action moves from the
      // value the parent still owns.
      tester.binding.renderViews.first.owner!.semanticsOwner!.performAction(
        node.id,
        SemanticsAction.decrease,
      );
      await tester.pump();
      expect(reported.last, closeTo(0.4, 1e-9));
      handle.dispose();
    });

    testWidgets('keeps a 44 pt hit target around a 4 pt track', (tester) async {
      await _pumpSlider(tester, value: 0.5, onChanged: (_) {});

      expect(
        tester.getSize(find.byType(OrionSlider)).height,
        OrionSizing.minHitTarget,
      );
      expect(tester.getSize(_trackFinder()).height, OrionSpacing.space4);
      expect(
        tester.getSize(_thumbFinder()).width,
        lessThan(OrionSizing.minHitTarget),
      );
    });

    testWidgets('a tap does not move the thumb', (tester) async {
      final List<double> reported = <double>[];
      await _pumpSlider(tester, value: 0.5, onChanged: reported.add);

      final Rect box = tester.getRect(find.byType(OrionSlider));
      await tester.tapAt(Offset(box.left + 30, box.center.dy));
      await tester.pumpAndSettle();

      expect(reported, isEmpty);
      expect(_thumbFraction(tester), closeTo(0.5, 0.002));
    });

    testWidgets(
      'a vertical drag scrolls the list and a horizontal drag moves',
      (tester) async {
        final List<double> reported = <double>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: ListView.builder(
                itemExtent: 60,
                itemCount: 20,
                itemBuilder: (BuildContext context, int index) => Center(
                  child: OrionSlider(value: 0.5, onChanged: reported.add),
                ),
              ),
            ),
          ),
        );

        // A horizontal drag moves the slider and leaves the list alone. The
        // item is wider than the standalone harness, so the value is read
        // against the real track the slider was given.
        final Finder first = find.byType(OrionSlider).first;
        final Rect box = tester.getRect(first);
        final double resting = box.top;
        final TestGesture sideways = await tester.startGesture(
          tester.getCenter(first),
        );
        await sideways.moveBy(const Offset(60, 0));
        await tester.pump();

        expect(
          reported.last,
          closeTo(0.5 + 60 / (box.width - _thumbSize), 1e-6),
        );
        await sideways.up();
        await tester.pumpAndSettle();
        expect(tester.getTopLeft(first).dy, resting);

        // A vertical drag belongs to the list: it scrolls and stays silent.
        reported.clear();
        await tester.drag(
          find.byType(OrionSlider).first,
          const Offset(0, -300),
        );
        await tester.pumpAndSettle();

        expect(
          tester.getTopLeft(find.byType(OrionSlider).first).dy,
          lessThan(resting),
        );
        expect(reported, isEmpty);
      },
    );

    testWidgets('survives being scrolled off-screen while held', (
      tester,
    ) async {
      final List<double> reported = <double>[];
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              itemExtent: 60,
              itemCount: 20,
              itemBuilder: (BuildContext context, int index) =>
                  OrionSlider(value: 0.5, onChanged: reported.add),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionSlider).first),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await gesture.moveBy(const Offset(0, -600));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(reported, isEmpty);
    });
  });
}
