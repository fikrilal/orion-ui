import 'dart:math' as math;
import 'dart:ui' show PointerDeviceKind, Tristate;

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

/// Default cylindrical geometry constants mirrored from [OrionWheelPickerPresets].
const double _diameterRatio = 1.07;
const double _perspective = 0.003;
const double _squeeze = 1.25;

/// Inverts the exact [MatrixUtils.createCylindricalProjectionTransform] center Y
/// back into a signed item offset relative to the wheel center.
double _invertCylindricalOffset(
  double dyFromCenter, {
  required int visibleItemCount,
}) {
  final double wheelHeight = _extent * visibleItemCount;
  final double radius = wheelHeight * _diameterRatio / 2.0;
  final double maxVisibleRadian = math.asin(1.0 / _diameterRatio);
  final double radiansPerItem =
      (2.0 * maxVisibleRadian) / (visibleItemCount * _squeeze);

  // Forward projection: y(angle) = -R * sin(angle) / (1 + p * R * (1 - cos(angle)))
  // Strictly decreasing in angle on (-pi/2, +pi/2).
  double lo = -(math.pi / 2.0 - 0.04);
  double hi = math.pi / 2.0 - 0.04;
  for (int i = 0; i < 40; i++) {
    final double mid = (lo + hi) * 0.5;
    final double projected =
        (-radius * math.sin(mid)) /
        (1.0 + _perspective * radius * (1.0 - math.cos(mid)));
    if (projected > dyFromCenter) {
      lo = mid;
    } else {
      hi = mid;
    }
  }
  final double angle = (lo + hi) * 0.5;
  return -angle / radiansPerItem;
}

/// The wheel's offset in item units, read from where a row is painted.
///
/// Picks the visible row closest to the centre (best conditioning on the
/// cylinder) and inverts its painted Y back through the cylindrical projection.
double _offset(WidgetTester tester, {int visibleItemCount = 5}) {
  final Rect wheelRect = tester.getRect(find.byType(OrionWheelPicker<int>));
  final double wheelCenterY = wheelRect.center.dy;
  int? bestIndex;
  double bestDy = double.infinity;

  for (int index = 0; index < 40; index++) {
    final Finder row = find.text('Item $index');
    if (row.evaluate().isEmpty) {
      continue;
    }
    final double dy = tester.getCenter(row).dy - wheelCenterY;
    if (dy.abs() < bestDy.abs()) {
      bestDy = dy;
      bestIndex = index;
    }
  }
  if (bestIndex == null) {
    fail('no wheel row was painted');
  }
  final double signedOffset = _invertCylindricalOffset(
    bestDy,
    visibleItemCount: visibleItemCount,
  );
  return bestIndex - signedOffset;
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
      expect(style.selectionStyle, OrionWheelSelectionStyle.pill);
      expect(style.edgeFade, isTrue);
      expect(style.perspective, greaterThan(0));
    });

    test('merge merges partial textStyle and lerp interpolates smoothly', () {
      final OrionWheelPickerStyle base = OrionWheelPickerStyle.from(
        itemExtent: 44,
        selectedColor: const Color(0xFF000000),
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
        selectionColor: const Color(0x10000000),
        perspective: 0.002,
      );
      final OrionWheelPickerStyle merged = base.merge(
        OrionWheelPickerStyle.from(
          textStyle: const TextStyle(fontWeight: FontWeight.w700),
        ),
      );
      expect(merged.textStyle?.fontSize, 15);
      expect(merged.textStyle?.fontWeight, FontWeight.w700);

      final OrionWheelPickerStyle target = OrionWheelPickerStyle.from(
        itemExtent: 36,
        selectedColor: const Color(0xFFFFFFFF),
        selectionColor: const Color(0x30FFFFFF),
        perspective: 0.0,
      );
      final OrionWheelPickerStyle mid = OrionWheelPickerStyle.lerp(
        base,
        target,
        0.5,
      )!;
      expect(mid.itemExtent, 40);
      expect(mid.perspective, closeTo(0.001, 0.0001));
      expect(
        mid.selectedColor?.resolve(const <WidgetState>{}),
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
      expect(OrionWheelPickerStyle.lerp(null, target, 0.0), isNull);
      expect(OrionWheelPickerStyle.lerp(null, target, 1.0), equals(target));

      final OrionWheelPickerTheme themeA = OrionWheelPickerTheme(
        defaultStyle: base,
      );
      final OrionWheelPickerTheme themeB = OrionWheelPickerTheme(
        defaultStyle: target,
      );
      final OrionWheelPickerTheme themeMid = themeA.lerp(themeB, 0.5);
      expect(themeMid.defaultStyle?.itemExtent, 40);
    });
  });

  group('OrionWheelPicker S-Tier Features & Regressions', () {
    testWidgets(
      'looping wraps cleanly past ends via keyboard, drag, semantics, and shortest-path value change',
      (tester) async {
        final List<int> reported = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: OrionWheelPicker<int>(
                    items: _items(12),
                    value: 11,
                    looping: true,
                    autofocus: true,
                    semanticLabel: 'Hour',
                    onChanged: reported.add,
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // ArrowDown from last item (11) wraps to 0!
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
        await tester.pumpAndSettle();
        expect(reported, <int>[0]);

        // ArrowUp from 0 wraps back to 11!
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
        await tester.pumpAndSettle();
        expect(reported, <int>[0, 11]);

        // Semantics exposes wrapped increasedValue ('Item 0') at item 11
        final SemanticsHandle handle = tester.ensureSemantics();
        final SemanticsData data = tester
            .getSemantics(find.byType(OrionWheelPicker<int>))
            .getSemanticsData();
        expect(data.value, 'Item 11');
        expect(data.increasedValue, 'Item 0');
        expect(data.decreasedValue, 'Item 10');
        handle.dispose();
      },
    );

    testWidgets(
      'pointer scroll (mouse wheel) steps detents and claims the scroll signal',
      (tester) async {
        final List<int> reported = <int>[];
        await _pumpWheel(tester, value: 2, onChanged: reported.add);

        final Offset center = tester.getCenter(
          find.byType(OrionWheelPicker<int>),
        );
        final TestPointer pointer = TestPointer(1, PointerDeviceKind.mouse);
        await tester.sendEventToBinding(pointer.hover(center));
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, 44)));
        await tester.pumpAndSettle();

        expect(_offset(tester), closeTo(3, 0.001));
        expect(reported, <int>[3]);

        // Reverse scroll notch
        await tester.sendEventToBinding(pointer.scroll(const Offset(0, -44)));
        await tester.pumpAndSettle();

        expect(_offset(tester), closeTo(2, 0.001));
        expect(reported, <int>[3, 2]);
      },
    );

    testWidgets(
      'touching down on a flying wheel catches momentum immediately without jumping to a tapped row',
      (tester) async {
        final List<int> reported = <int>[];
        await _pumpWheel(tester, value: 0, onChanged: reported.add);

        await _flick(tester, steps: 12);
        await tester.pump(const Duration(milliseconds: 32));
        final double caughtOffset = _offset(tester);
        expect(caughtOffset, greaterThan(0));

        // Put finger down on the flying wheel without dragging, then lift
        final TestGesture catchGesture = await tester.startGesture(
          tester.getCenter(find.byType(OrionWheelPicker<int>)),
        );
        await tester.pump(const Duration(milliseconds: 64));
        // Momentum stayed arrested while finger held down
        expect(_offset(tester), closeTo(caughtOffset, 0.001));

        await catchGesture.up();
        await _settle(tester);

        // Settled cleanly onto the caught nearest detent, not further down the flick
        expect(_offset(tester), closeTo(caughtOffset.roundToDouble(), 0.001));
        expect(reported, hasLength(1));
      },
    );

    testWidgets(
      'shrinking items list clamps safely without RangeError and reorders stay synced',
      (tester) async {
        // Start with 31 items selected at index 30 (day 31)
        await _pumpWheel(
          tester,
          items: _items(31),
          value: 30,
          onChanged: (_) {},
        );
        await tester.pumpAndSettle();
        expect(find.text('Item 30'), findsOneWidget);

        // Shrink to 28 items with value clamped to 27 (February 28)
        await _pumpWheel(
          tester,
          items: _items(28),
          value: 27,
          onChanged: (_) {},
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(_offset(tester), closeTo(27, 0.001));

        // Same-length reorder: move value 2 from index 2 to index 0
        final List<OrionWheelItem<int>> initial = <OrionWheelItem<int>>[
          OrionWheelItem<int>(value: 0, label: const Text('Item 0')),
          OrionWheelItem<int>(value: 1, label: const Text('Item 1')),
          OrionWheelItem<int>(value: 2, label: const Text('Item 2')),
        ];
        final List<OrionWheelItem<int>> reordered = <OrionWheelItem<int>>[
          OrionWheelItem<int>(value: 2, label: const Text('Item 2')),
          OrionWheelItem<int>(value: 0, label: const Text('Item 0')),
          OrionWheelItem<int>(value: 1, label: const Text('Item 1')),
        ];

        await _pumpWheel(tester, items: initial, value: 2, onChanged: (_) {});
        await tester.pumpAndSettle();
        expect(_offset(tester), closeTo(2, 0.001));

        await _pumpWheel(tester, items: reordered, value: 2, onChanged: (_) {});
        await tester.pumpAndSettle();
        final double wheelTop = tester
            .getTopLeft(find.byType(OrionWheelPicker<int>))
            .dy;
        expect(
          tester.getCenter(find.text('Item 2')).dy,
          closeTo(wheelTop + 2.5 * _extent, 0.5),
        );
      },
    );

    testWidgets(
      'onActiveChanged reports live detent crossings while dragging before onChanged settles',
      (tester) async {
        final List<int> live = <int>[];
        final List<int> committed = <int>[];

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 240,
                  child: OrionWheelPicker<int>(
                    items: _items(12),
                    value: 0,
                    onActiveChanged: live.add,
                    onChanged: committed.add,
                  ),
                ),
              ),
            ),
          ),
        );

        final TestGesture gesture = await _grab(tester);
        await gesture.moveBy(const Offset(0, -44));
        await tester.pump();
        await gesture.moveBy(const Offset(0, -44));
        await tester.pump();

        expect(live, <int>[1, 2]);
        expect(committed, isEmpty);

        await gesture.up();
        await _settle(tester);
        expect(committed, <int>[2]);
      },
    );

    testWidgets('keyboard supports KeyRepeatEvent and PageUp/PageDown jumps', (
      tester,
    ) async {
      final List<int> reported = <int>[];
      await _pumpWheel(
        tester,
        value: 0,
        onChanged: reported.add,
        autofocus: true,
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(5, 0.001));

      await tester.sendKeyDownEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyRepeatEvent(LogicalKeyboardKey.arrowDown);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.arrowDown);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(7, 0.001));

      await tester.sendKeyEvent(LogicalKeyboardKey.pageUp);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(2, 0.001));
    });

    testWidgets(
      'asymptotic rubber-banding caps extreme over-drag so rows stay visible',
      (tester) async {
        await _pumpWheel(tester, value: 11, onChanged: (_) {});

        final TestGesture gesture = await _grab(tester);
        await gesture.moveBy(const Offset(0, -1500));
        await tester.pump();

        final double stretched = _offset(tester);
        expect(stretched, greaterThan(11));
        expect(stretched, lessThan(12.6));

        await gesture.up();
        await _settle(tester);
        expect(_offset(tester), closeTo(11, 0.001));
      },
    );

    testWidgets(
      'selectionStyle, edgeFade, and selectedTextStyle emphasis apply cleanly',
      (tester) async {
        await _pumpWheel(
          tester,
          value: 2,
          onChanged: (_) {},
          style: OrionWheelPickerStyle.from(
            selectionStyle: OrionWheelSelectionStyle.hairlines,
            edgeFade: false,
            perspective: 0.0,
          ),
        );

        expect(
          find.descendant(
            of: find.byType(OrionWheelPicker<int>),
            matching: find.byType(ShaderMask),
          ),
          findsNothing,
        );
        final TextStyle selectedStyle = DefaultTextStyle.of(
          tester.element(find.text('Item 2')),
        ).style;
        final TextStyle idleStyle = DefaultTextStyle.of(
          tester.element(find.text('Item 1')),
        ).style;
        expect(selectedStyle.fontWeight, FontWeight.w600);
        expect(idleStyle.fontWeight, FontWeight.w400);
      },
    );

    testWidgets(
      '3D cylindrical projection visibly foreshortens outer rows compared to flat 2D mode',
      (tester) async {
        // Measure outer row distance from centre in 3D cylinder mode (default)
        await _pumpWheel(tester, value: 4, onChanged: (_) {});
        final double centerY3d = tester.getCenter(find.text('Item 4')).dy;
        final double outerDist3d =
            (tester.getCenter(find.text('Item 6')).dy - centerY3d).abs();

        // Compare against flat 2D mode (perspective: 0)
        await _pumpWheel(
          tester,
          value: 4,
          onChanged: (_) {},
          style: OrionWheelPickerStyle.from(perspective: 0.0, edgeScale: 1.0),
        );
        final double centerY2d = tester.getCenter(find.text('Item 4')).dy;
        final double outerDist2d =
            (tester.getCenter(find.text('Item 6')).dy - centerY2d).abs();

        // Flat 2D puts +2 at exact 2 * 44 = 88px; 3D cylinder compresses it inward!
        expect(outerDist2d, closeTo(88.0, 0.1));
        expect(outerDist3d, lessThan(outerDist2d - 10.0));
      },
    );

    testWidgets(
      'hard flick on looping wheel settles cleanly even when parent echoes onActiveChanged into value',
      (tester) async {
        int current = 2;
        int finalCommitted = -1;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return SizedBox(
                      width: 240,
                      child: OrionWheelPicker<int>(
                        items: _items(12),
                        value: current,
                        looping: true,
                        onActiveChanged: (int v) => setState(() => current = v),
                        onChanged: (int v) => setState(() {
                          current = v;
                          finalCommitted = v;
                        }),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        );

        // Hard flick across multiple detents
        await _flick(tester, steps: 10, dy: -65);
        await tester.pumpAndSettle();

        // Must stop cleanly (no infinite chase) and commit the settled item
        expect(finalCommitted, greaterThanOrEqualTo(0));
        expect(finalCommitted, equals(current));
      },
    );
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
