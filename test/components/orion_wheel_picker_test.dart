import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

/// Row extent, mirrored from the component so the geometry probes can invert a
/// painted position back into the wheel's offset.
const double _extent = 44;

List<OrionWheelItem<int>> _items(int count) => <OrionWheelItem<int>>[
  for (int index = 0; index < count; index++)
    OrionWheelItem<int>(value: index, label: Text('Item $index')),
];

Future<void> _pumpWheel(
  WidgetTester tester, {
  List<OrionWheelItem<int>>? items,
  int value = 0,
  ValueChanged<int>? onChanged,
  int visibleItemCount = 5,
  bool disableAnimations = false,
  bool autofocus = false,
  String? semanticLabel,
  double width = 240,
  OrionWheelPickerStyle? style,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: SizedBox(
              width: width,
              child: OrionWheelPicker<int>(
                items: items ?? _items(12),
                value: value,
                onChanged: onChanged,
                visibleItemCount: visibleItemCount,
                semanticLabel: semanticLabel,
                autofocus: autofocus,
                style: style,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

/// The wheel's offset in item units, read from where a row is painted.
///
/// The lowest painted row is always inside the window, and its position inverts
/// to the offset exactly, so this is a probe of the real geometry rather than of
/// any internal state.
double _offset(WidgetTester tester, {int visibleItemCount = 5}) {
  final double wheelTop = tester
      .getTopLeft(find.byType(OrionWheelPicker<int>))
      .dy;
  for (int index = 0; index < 40; index++) {
    final Finder row = find.text('Item $index');
    if (row.evaluate().isEmpty) {
      continue;
    }
    final double centre = tester.getCenter(row).dy;
    return index - ((centre - wheelTop) / _extent - visibleItemCount / 2);
  }
  fail('no wheel row was painted');
}

/// Starts a drag on the wheel and consumes the touch slop.
Future<TestGesture> _grab(WidgetTester tester) async {
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(find.byType(OrionWheelPicker<int>)),
  );
  await gesture.moveBy(const Offset(0, -20));
  await tester.pump();
  return gesture;
}

/// Drags the wheel in [steps] moves of [dy] each, with a timestamp per move so
/// the finger carries a real velocity.
///
/// Lifts the finger unless [lift] is false, in which case the caller owns the
/// gesture and can measure where the wheel was when it was let go.
Future<TestGesture> _flick(
  WidgetTester tester, {
  required int steps,
  double dy = -20,
  bool lift = true,
}) async {
  final TestGesture gesture = await _grab(tester);
  for (int step = 0; step < steps; step++) {
    await gesture.moveBy(
      Offset(0, dy),
      timeStamp: Duration(milliseconds: 16 * (step + 1)),
    );
    await tester.pump(const Duration(milliseconds: 16));
  }
  if (lift) {
    await gesture.up();
  }
  return gesture;
}

/// Pumps 16 ms frames until the wheel stops moving.
///
/// [WidgetTester.pumpAndSettle] steps 100 ms at a time, which can step clean
/// over a detent boundary and hide a crossing; a real display samples every
/// frame, so the tests do too.
Future<void> _settle(WidgetTester tester) async {
  double previous = double.nan;
  for (var frame = 0; frame < 120; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    final double current = _offset(tester);
    if (current == previous) {
      return;
    }
    previous = current;
  }
  fail('the wheel never settled');
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

void main() {
  group('OrionWheelPicker', () {
    testWidgets('a hard flick to the last item does not swing past the end', (
      tester,
    ) async {
      await _pumpWheel(tester, value: 11, onChanged: (int _) {});
      await tester.pumpAndSettle();

      // Measured from one item's painted position, not by discovering visible rows: past
      // the end those rows fall outside the falloff and the window is simply empty, so a
      // row-finding probe reports nothing while the wheel is a hundred pixels too far.
      final double settled = tester.getTopLeft(find.text('Item 11')).dy;
      final double extent =
          (tester.getTopLeft(find.text('Item 10')).dy - settled).abs();

      await _flick(tester, steps: 6, dy: -60);

      double excursion() =>
          (tester.getTopLeft(find.text('Item 11')).dy - settled).abs() / extent;

      // The pull itself may drag the wheel past the end - the end resistance allows about
      // two items - but from the moment it is released the wheel may only come back.
      // Handing the raw velocity over let it keep travelling, which emptied the window.
      final double atRelease = excursion();
      double farthest = atRelease;
      for (int frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double now = excursion();
        if (now > farthest) {
          farthest = now;
        }
      }
      await tester.pumpAndSettle();

      expect(
        farthest,
        lessThanOrEqualTo(atRelease + 0.05),
        reason:
            'a released wheel settles back toward its detent, it does not carry on',
      );
      expect(excursion(), lessThan(0.5));
    });

    testWidgets('centres the value and fades its neighbours', (tester) async {
      await _pumpWheel(tester, value: 2, onChanged: (_) {});

      expect(_offset(tester), closeTo(2, 0.001));
      // The centred row sits on the middle slot of five.
      final double wheelTop = tester
          .getTopLeft(find.byType(OrionWheelPicker<int>))
          .dy;
      expect(
        tester.getCenter(find.text('Item 2')).dy,
        closeTo(wheelTop + 2.5 * _extent, 0.001),
      );
      expect(_opacity(tester, 'Item 2'), 1);
      expect(_opacity(tester, 'Item 3'), lessThan(1));
      expect(_opacity(tester, 'Item 1'), _opacity(tester, 'Item 3'));
    });

    testWidgets('settles on the nearer detent after a half-item drag', (
      tester,
    ) async {
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 2, onChanged: reported.add);

      final TestGesture gesture = await _grab(tester);
      await gesture.moveBy(const Offset(0, -22));
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(2.5, 0.05));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(3, 0.001));
      expect(reported, <int>[3]);
    });

    testWidgets('a flick lands on a detent several items away', (tester) async {
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 0, onChanged: reported.add);

      final TestGesture gesture = await _flick(tester, steps: 12, lift: false);
      final double released = _offset(tester);
      expect(released, greaterThan(0));
      await gesture.up();
      await _settle(tester);

      final double landed = _offset(tester);
      // Momentum: the wheel carries on past where the finger let it go, by more
      // than one item, so the release is not just landing on the nearest detent.
      expect(landed - released, greaterThan(1.5));
      // Exactly on a detent, never between two.
      expect(landed, closeTo(landed.roundToDouble(), 0.001));
      expect(reported, hasLength(1));
      expect(reported.single, landed.round());
      expect(find.text('Item ${landed.round()}'), findsOneWidget);
    });

    testWidgets('a drag back to its starting detent is silent', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 2, onChanged: reported.add);

      final TestGesture gesture = await _grab(tester);
      await gesture.moveBy(const Offset(0, -13));
      await tester.pumpAndSettle();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(2, 0.001));
      expect(haptics, isEmpty);
      expect(reported, isEmpty);
    });

    testWidgets('ticks once per detent crossing', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      await _pumpWheel(tester, value: 0, onChanged: (_) {});

      await _flick(tester, steps: 12);
      await _settle(tester);

      final int landed = _offset(tester).round();
      expect(landed, greaterThanOrEqualTo(2));
      expect(haptics, hasLength(landed));
      expect(
        haptics.every(
          (String kind) => kind == 'HapticFeedbackType.selectionClick',
        ),
        isTrue,
      );
    });

    testWidgets('rubber-bands past the last item and returns to it', (
      tester,
    ) async {
      await _pumpWheel(tester, value: 11, onChanged: (_) {});

      final TestGesture gesture = await _grab(tester);
      await gesture.moveBy(const Offset(0, -100));
      await tester.pumpAndSettle();

      // Resistance, not a hard stop: the wheel moved past the end, by less than
      // the finger did.
      final double stretched = _offset(tester);
      expect(stretched, greaterThan(11));
      expect(stretched, lessThan(11 + 80 / _extent));

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(11, 0.001));
    });

    testWidgets('the keyboard steps one item and jumps to the ends', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      await _pumpWheel(tester, value: 4, onChanged: (_) {}, autofocus: true);
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(5, 0.001));

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(4, 0.001));

      await tester.sendKeyEvent(LogicalKeyboardKey.end);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(11, 0.001));

      await tester.sendKeyEvent(LogicalKeyboardKey.home);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(0, 0.001));

      expect(haptics, isEmpty);
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      final List<int> reported = <int>[];
      await _pumpWheel(
        tester,
        value: 2,
        onChanged: reported.add,
        disableAnimations: true,
      );
      expect(reported, isEmpty);

      final TestGesture gesture = await _grab(tester);
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();

      // The drag tracks the finger exactly, in both modes.
      expect(_offset(tester), closeTo(2 + 100 / _extent, 0.001));
      // Nothing is reported while the finger is still down.
      expect(reported, isEmpty);

      await gesture.up();
      await tester.pump();

      // No glide: the wheel is already on the landing detent, and it reports.
      expect(_offset(tester), closeTo(_offset(tester).roundToDouble(), 0.001));
      expect(reported, hasLength(1));
      expect(reported.single, _offset(tester).round());
    });

    testWidgets('settles at once when motion is turned off mid-flight', (
      tester,
    ) async {
      await _pumpWheel(tester, value: 0, onChanged: (_) {});
      await _flick(tester, steps: 12);
      await tester.pump(const Duration(milliseconds: 32));

      final double flying = _offset(tester);
      expect(flying, greaterThan(0));
      expect(flying, lessThan(flying.roundToDouble() + 1));

      await _pumpWheel(
        tester,
        value: 0,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_offset(tester), closeTo(_offset(tester).roundToDouble(), 0.001));
    });

    testWidgets('keeps the rows out of the ticker rebuilds', (tester) async {
      final _BuildCounter counter = _BuildCounter();
      await _pumpWheel(
        tester,
        value: 2,
        onChanged: (_) {},
        items: <OrionWheelItem<int>>[
          for (int index = 0; index < 12; index++)
            OrionWheelItem<int>(
              value: index,
              label: index == 2
                  ? _Probe('Item $index', counter)
                  : Text('Item $index'),
            ),
        ],
      );

      // A drag that returns to its starting detent: the ticker runs, nothing
      // crosses, so nothing may rebuild.
      final TestGesture gesture = await _grab(tester);
      await gesture.moveBy(const Offset(0, -13));
      await tester.pumpAndSettle();
      await gesture.up();
      // The driver's retarget restarts its ticker, so the first frame after one
      // re-anchors the spring instead of moving it.
      await tester.pump(const Duration(milliseconds: 16));

      double previous = _offset(tester);
      for (var frame = 0; frame < 12; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double current = _offset(tester);
        expect(current, isNot(previous));
        previous = current;
      }
      await tester.pumpAndSettle();

      expect(counter.count, 1);
    });

    testWidgets('keeps a 44 pt tap target on every row', (tester) async {
      await _pumpWheel(tester, value: 0, onChanged: (_) {});

      final Finder target = find
          .ancestor(
            of: find.text('Item 1'),
            matching: find.byType(GestureDetector),
          )
          .first;
      expect(tester.getSize(target).height, OrionSizing.minHitTarget);
      expect(
        tester.getSize(target).width,
        greaterThanOrEqualTo(OrionSizing.minHitTarget),
      );
      expect(
        tester.getSize(find.byType(OrionWheelPicker<int>)).height,
        OrionSizing.minHitTarget * 5,
      );
    });

    testWidgets('is one adjustable semantics node', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpWheel(
        tester,
        value: 2,
        onChanged: (_) {},
        semanticLabel: 'Month',
      );

      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionWheelPicker<int>),
      );
      expect(node.label, 'Month');
      expect(node.value, 'Item 2');
      final SemanticsData data = node.getSemanticsData();
      expect(data.increasedValue, 'Item 3');
      expect(data.decreasedValue, 'Item 1');
      expect(data.hasAction(SemanticsAction.increase), isTrue);
      expect(data.hasAction(SemanticsAction.decrease), isTrue);
      // The rows are not separate nodes.
      expect(find.bySemanticsLabel('Item 3'), findsNothing);
      handle.dispose();
    });

    testWidgets('builds only the rows around the detent', (tester) async {
      await _pumpWheel(
        tester,
        value: 500,
        onChanged: (_) {},
        items: _items(10000),
      );

      expect(
        find.descendant(
          of: find.byType(OrionWheelPicker<int>),
          matching: find.byType(Opacity),
        ),
        findsNWidgets(7),
      );
    });

    testWidgets('spans seven slots when asked for seven', (tester) async {
      await _pumpWheel(
        tester,
        value: 5,
        onChanged: (_) {},
        visibleItemCount: 7,
      );

      expect(
        tester.getSize(find.byType(OrionWheelPicker<int>)).height,
        _extent * 7,
      );
      expect(
        find.descendant(
          of: find.byType(OrionWheelPicker<int>),
          matching: find.byType(Opacity),
        ),
        findsNWidgets(9),
      );
    });

    testWidgets('a second drag mid-glide picks the wheel up where it is', (
      tester,
    ) async {
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 0, onChanged: reported.add);
      await _flick(tester, steps: 12);
      await tester.pump(const Duration(milliseconds: 32));

      final double flying = _offset(tester);
      expect(flying, greaterThan(0));
      expect(flying, isNot(flying.roundToDouble()));

      final TestGesture again = await _grab(tester);
      await again.moveBy(const Offset(0, -22));
      await tester.pump();

      // The wheel continues from where it was flying, not from a detent.
      expect(_offset(tester), closeTo(flying + 0.5, 0.001));

      await again.up();
      await _settle(tester);
      final double landed = _offset(tester);
      expect(landed, closeTo(landed.roundToDouble(), 0.001));
      expect(reported, hasLength(1));
    });

    testWidgets('rubber-bands past the first item and returns to it', (
      tester,
    ) async {
      await _pumpWheel(tester, value: 0, onChanged: (_) {});

      final TestGesture gesture = await _grab(tester);
      await gesture.moveBy(const Offset(0, 100));
      await tester.pump();

      final double stretched = _offset(tester);
      expect(stretched, lessThan(0));
      expect(stretched, greaterThan(-100 / _extent * 0.5));

      await gesture.up();
      await _settle(tester);
      expect(_offset(tester), closeTo(0, 0.001));
    });

    testWidgets('claims its own vertical drags inside a scrollable', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView(
              children: <Widget>[
                Center(
                  child: SizedBox(
                    width: 240,
                    child: OrionWheelPicker<int>(
                      items: _items(12),
                      value: 0,
                      onChanged: (_) {},
                    ),
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      );
      final double resting = tester
          .getTopLeft(find.byType(OrionWheelPicker<int>))
          .dy;

      await tester.drag(
        find.byType(OrionWheelPicker<int>),
        const Offset(0, -120),
      );
      await _settle(tester);

      // The wheel is a picker, not a cooperating child: it takes the drag, and
      // the list behind it never moves. This is why it must not be nested in a
      // vertically scrolling parent.
      expect(tester.getTopLeft(find.byType(OrionWheelPicker<int>)).dy, resting);
      expect(_offset(tester), greaterThan(0));
    });

    testWidgets('does not report or tick while the finger is down', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 0, onChanged: reported.add);

      final TestGesture gesture = await _grab(tester);
      for (var step = 0; step < 8; step++) {
        await gesture.moveBy(const Offset(0, -22));
        await tester.pump();
      }
      await tester.pump();

      // Four detents travelled with the finger down: no report yet.
      expect(reported, isEmpty);
      expect(haptics, hasLength(4));

      await gesture.up();
      await _settle(tester);
      expect(reported, hasLength(1));
      expect(reported.single, _offset(tester).round());
    });

    testWidgets('a tap on the centred item changes nothing', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 2, onChanged: reported.add);

      await tester.tap(find.text('Item 2'));
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(2, 0.001));
      expect(reported, isEmpty);
      expect(haptics, isEmpty);
    });

    testWidgets('a tap that crosses detents stays silent', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 0, onChanged: reported.add);

      // Only rows inside the band are built, and an invisible row is not a hit
      // target, so the farthest tappable item is the one at the band edge.
      await tester.tap(find.text('Item 2'));
      await _settle(tester);

      expect(_offset(tester), closeTo(2, 0.001));
      expect(reported, <int>[2]);
      // A tap is a command, not the wheel rolling under a finger.
      expect(haptics, isEmpty);
    });

    testWidgets('follows a value the parent changes', (tester) async {
      final List<int> reported = <int>[];
      await _pumpWheel(tester, value: 0, onChanged: reported.add);

      await _pumpWheel(tester, value: 4, onChanged: reported.add);
      await _settle(tester);

      expect(_offset(tester), closeTo(4, 0.001));
      expect(reported, isEmpty);
    });

    testWidgets('ignores nothing but does move for the screen reader', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> haptics = _captureHaptics(tester);
      final List<int> reported = <int>[];
      await _pumpWheel(
        tester,
        value: 2,
        onChanged: reported.add,
        semanticLabel: 'Month',
      );

      // What a screen reader's "increase" gesture does. The node finder also
      // asserts the action is actually offered.
      tester.semantics.increase(find.semantics.byLabel('Month'));
      await _settle(tester);

      expect(_offset(tester), closeTo(3, 0.001));
      expect(reported, <int>[3]);
      expect(haptics, isEmpty);
      expect(
        tester.getSemantics(find.byType(OrionWheelPicker<int>)).value,
        'Item 3',
      );
      handle.dispose();
    });

    testWidgets('is inert when disabled', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> haptics = _captureHaptics(tester);
      await _pumpWheel(tester, value: 2, onChanged: null);

      await tester.drag(
        find.byType(OrionWheelPicker<int>),
        const Offset(0, -120),
      );
      await tester.tap(find.text('Item 4'));
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(2, 0.001));
      expect(haptics, isEmpty);
      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionWheelPicker<int>),
      );
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        node.getSemanticsData().hasAction(SemanticsAction.increase),
        isFalse,
      );
      handle.dispose();
    });

    testWidgets('shows a click cursor only while enabled', (tester) async {
      await _pumpWheel(tester, value: 2, onChanged: (_) {});
      expect(_rowCursor(tester), SystemMouseCursors.click);

      await _pumpWheel(tester, value: 2, onChanged: null);
      expect(_rowCursor(tester), MouseCursor.defer);
    });

    testWidgets('keeps working with a single item', (tester) async {
      final List<int> reported = <int>[];
      await _pumpWheel(
        tester,
        value: 0,
        onChanged: reported.add,
        items: _items(1),
      );

      final TestGesture gesture = await _grab(tester);
      await gesture.moveBy(const Offset(0, -100));
      await tester.pump();
      expect(_offset(tester), greaterThan(0));

      await gesture.up();
      await _settle(tester);
      expect(_offset(tester), closeTo(0, 0.001));
      expect(reported, isEmpty);
    });

    testWidgets('survives being unmounted mid-glide', (tester) async {
      await _pumpWheel(tester, value: 0, onChanged: (_) {});
      await _flick(tester, steps: 12);
      await tester.pump(const Duration(milliseconds: 32));

      await tester.pumpWidget(const MaterialApp(home: Scaffold()));
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    group('rejects an invalid configuration', () {
      testWidgets('empty items', (tester) async {
        await _pumpRaw(
          tester,
          Center(
            child: SizedBox(
              width: 240,
              child: OrionWheelPicker<int>(
                items: const <OrionWheelItem<int>>[],
                value: 0,
                onChanged: (_) {},
              ),
            ),
          ),
        );
      });

      testWidgets('duplicate values', (tester) async {
        await _pumpRaw(
          tester,
          Center(
            child: SizedBox(
              width: 240,
              child: OrionWheelPicker<int>(
                items: <OrionWheelItem<int>>[
                  OrionWheelItem<int>(value: 1, label: const Text('a')),
                  OrionWheelItem<int>(value: 1, label: const Text('b')),
                ],
                value: 1,
                onChanged: (_) {},
              ),
            ),
          ),
        );
      });

      testWidgets('a value that is not an item', (tester) async {
        await _pumpRaw(
          tester,
          Center(
            child: SizedBox(
              width: 240,
              child: OrionWheelPicker<int>(
                items: _items(4),
                value: 9,
                onChanged: (_) {},
              ),
            ),
          ),
        );
      });

      testWidgets('an even visibleItemCount', (tester) async {
        await _pumpRaw(
          tester,
          Center(
            child: SizedBox(
              width: 240,
              child: OrionWheelPicker<int>(
                items: _items(4),
                value: 0,
                visibleItemCount: 4,
                onChanged: (_) {},
              ),
            ),
          ),
        );
      });

      testWidgets('a visibleItemCount below three', (tester) async {
        await _pumpRaw(
          tester,
          Center(
            child: SizedBox(
              width: 240,
              child: OrionWheelPicker<int>(
                items: _items(4),
                value: 0,
                visibleItemCount: 1,
                onChanged: (_) {},
              ),
            ),
          ),
        );
      });

      testWidgets('an unbounded width', (tester) async {
        final List<Object> errors = <Object>[];
        final void Function(FlutterErrorDetails)? previous =
            FlutterError.onError;
        FlutterError.onError = (FlutterErrorDetails details) {
          errors.add(details.exception);
        };
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Row(
              children: <Widget>[
                OrionWheelPicker<int>(
                  items: _items(4),
                  value: 0,
                  onChanged: (_) {},
                ),
              ],
            ),
          ),
        );
        FlutterError.onError = previous;
        expect(errors.whereType<AssertionError>(), isNotEmpty);
      });
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionWheelPickerTheme(
            defaultStyle: OrionWheelPickerStyle.from(
              selectedColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      Color rowColor(String label) =>
          DefaultTextStyle.of(tester.element(find.text(label))).style.color!;

      await _pumpWheel(tester, value: 2, onChanged: (_) {}, theme: themed);
      expect(rowColor('Item 2'), const Color(0xFF00AA00));
      expect(rowColor('Item 1'), OrionColors.lightScheme.onSurfaceVariant);

      await _pumpWheel(
        tester,
        value: 2,
        onChanged: (_) {},
        theme: themed,
        style: OrionWheelPickerStyle.from(
          selectedColor: const Color(0xFFAA0000),
        ),
      );
      expect(rowColor('Item 2'), const Color(0xFFAA0000));
      expect(
        rowColor('Item 1'),
        OrionColors.lightScheme.onSurfaceVariant,
        reason: 'the instance style only overrides what it names',
      );
    });

    testWidgets('a custom row extent changes the wheel height', (tester) async {
      await _pumpWheel(
        tester,
        value: 0,
        onChanged: (_) {},
        style: OrionWheelPickerStyle.from(itemExtent: 32),
      );

      expect(tester.getSize(find.byType(OrionWheelPicker<int>)).height, 32 * 5);
    });

    testWidgets('a custom ring colour and width repaint the focus ring', (
      tester,
    ) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      await _pumpWheel(
        tester,
        value: 0,
        onChanged: (_) {},
        autofocus: true,
        style: OrionWheelPickerStyle.from(
          focusRingColor: const Color(0xFF00AA00),
          focusRingWidth: 4,
        ),
      );
      await tester.pumpAndSettle();

      final DecoratedBox face = tester.widget<DecoratedBox>(
        find.descendant(
          of: find.byType(OrionWheelPicker<int>),
          matching: find.byType(DecoratedBox),
        ),
      );
      final Border border =
          (face.decoration as BoxDecoration).border! as Border;
      expect(border.top.color, const Color(0xFF00AA00));
      expect(border.top.width, 4);
    });
  });

  group('OrionWheelPickerStyle', () {
    test('a merge only changes the fields it names', () {
      final OrionWheelPickerStyle base = OrionWheelPickerStyle.from(
        itemExtent: 32,
        selectedColor: const Color(0xFF111111),
      );
      final OrionWheelPickerStyle merged = base.merge(
        OrionWheelPickerStyle.from(selectedColor: const Color(0xFF333333)),
      );

      expect(
        merged.selectedColor?.resolve(const <WidgetState>{}),
        const Color(0xFF333333),
      );
      expect(merged.itemExtent, 32);
    });

    test('presets reproduce the shipped wheel', () {
      final OrionWheelPickerStyle style = OrionWheelPickerPresets.resolve(
        scheme: OrionColors.lightScheme,
        textTheme: OrionTheme.light().textTheme,
      );

      expect(style.itemExtent, OrionSizing.minHitTarget);
      expect(style.edgeScale, 0.7);
      expect(style.projectionSeconds, 0.08);
      expect(style.endResistance, 0.35);
      expect(style.focusRingColor, OrionColors.lightScheme.onSurface);
      expect(style.focusRingWidth, 2);
      expect(
        style.settleSpring,
        const OrionSpringSpec(stiffness: 380, dampingRatio: 1),
      );
      expect(
        style.selectedColor?.resolve(const <WidgetState>{}),
        OrionColors.lightScheme.onSurface,
      );
      expect(
        style.idleColor?.resolve(const <WidgetState>{WidgetState.disabled}),
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.38),
      );
    });
  });
}

/// Pumps a widget that is expected to reject its configuration.
Future<void> _pumpRaw(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(body: child),
    ),
  );
  expect(tester.takeException(), isA<AssertionError>());
}

MouseCursor _rowCursor(WidgetTester tester) {
  return tester
      .widget<MouseRegion>(
        find
            .descendant(
              of: find.byType(OrionWheelPicker<int>),
              matching: find.byType(MouseRegion),
            )
            .first,
      )
      .cursor;
}

double _opacity(WidgetTester tester, String label) {
  return tester
      .widget<Opacity>(
        find
            .ancestor(of: find.text(label), matching: find.byType(Opacity))
            .first,
      )
      .opacity;
}

class _BuildCounter {
  int count = 0;
}

/// Counts how often the row's label is built, and depends on the ambient text
/// style, so a component that animated that style per frame would rebuild it.
class _Probe extends StatelessWidget {
  const _Probe(this.label, this.counter);

  final String label;
  final _BuildCounter counter;

  @override
  Widget build(BuildContext context) {
    counter.count += 1;
    return Text(
      label,
      style: TextStyle(color: DefaultTextStyle.of(context).style.color),
    );
  }
}
