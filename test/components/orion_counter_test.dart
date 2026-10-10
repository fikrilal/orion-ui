import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderView;
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

/// One period of a slot's column, in rows, as the component defines it.
const int _period = 10;

Future<void> _pumpCounter(
  WidgetTester tester, {
  required int value,
  OrionCounterStyle? style,
  String? semanticLabel,
  bool animate = true,
  bool disableAnimations = false,
  double textScale = 1.0,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Center(
          child: MediaQuery(
            data: MediaQueryData(
              disableAnimations: disableAnimations,
              textScaler: TextScaler.linear(textScale),
            ),
            child: OrionCounter(
              value: value,
              style: style,
              semanticLabel: semanticLabel,
              animate: animate,
            ),
          ),
        ),
      ),
    ),
  );
}

Finder _slot(int index) => find.byKey(ValueKey<int>(index));

/// The per-slot translation, in slot order: most significant first.
List<double> _offsets(WidgetTester tester) {
  return _transforms(tester)
      .map((Transform transform) => transform.transform.getTranslation().y)
      .toList();
}

List<Transform> _transforms(WidgetTester tester) {
  return tester
      .widgetList<Transform>(
        find.descendant(
          of: find.byType(OrionCounter),
          matching: find.byType(Transform),
        ),
      )
      .toList();
}

/// The render objects of the digit rows under a slot, in order.
List<RenderObject> _rows(WidgetTester tester, int index) {
  return find
      .descendant(of: _slot(index), matching: find.byType(Text))
      .evaluate()
      .map((Element element) => element.renderObject!)
      .toList();
}

int _slotCount(WidgetTester tester) => _offsets(tester).length;

/// The height of one digit line, read off the window itself.
double _lineHeight(WidgetTester tester) => tester.getSize(_slot(0)).height;

/// The digit the window actually shows: the glyph row overlapping it most.
///
/// This reads painted geometry, not component state, so it proves what a user
/// sees rather than what the math intends.
String _visibleDigit(WidgetTester tester, int index) {
  final Finder slot = _slot(index);
  final Rect window = tester.getRect(slot);
  var best = '';
  var bestArea = -1.0;
  for (final Element element
      in find.descendant(of: slot, matching: find.byType(Text)).evaluate()) {
    final RenderBox box = element.renderObject! as RenderBox;
    final Rect glyph = box.localToGlobal(Offset.zero) & box.size;
    final Rect overlap = glyph.intersect(window);
    final double area = overlap.isEmpty ? 0 : overlap.width * overlap.height;
    if (area > bestArea) {
      bestArea = area;
      best = (element.widget as Text).data!;
    }
  }
  return best;
}

/// The value the row reads, most significant digit first.
String _read(WidgetTester tester) {
  final StringBuffer buffer = StringBuffer();
  for (var index = _slotCount(tester) - 1; index >= 0; index--) {
    buffer.write(_visibleDigit(tester, index));
  }
  return buffer.toString();
}

/// A slot's translation is periodic over ten rows, so a frame-to-frame delta of
/// more than half a period is the wrap, not a reversal. Rewrap those deltas into
/// one continuous track, which is the trajectory the eye follows.
List<double> _unwrap(List<double> offsets, double lineHeight) {
  final double period = lineHeight * _period;
  final List<double> track = <double>[offsets.first];
  for (var i = 1; i < offsets.length; i++) {
    var delta = offsets[i] - offsets[i - 1];
    if (delta > period / 2) {
      delta -= period;
    } else if (delta < -period / 2) {
      delta += period;
    }
    track.add(track.last + delta);
  }
  return track;
}

/// Samples one slot's translation on every frame.
///
/// [slotIndex] counts from the right, so 0 is the ones digit.
Future<List<double>> _sample(
  WidgetTester tester,
  int slotIndex, {
  int frames = 60,
}) async {
  double at() => _offsets(tester)[_slotCount(tester) - 1 - slotIndex];
  final List<double> samples = <double>[at()];
  for (var frame = 0; frame < frames; frame++) {
    await tester.pump(const Duration(milliseconds: 16));
    samples.add(at());
  }
  return samples;
}

List<SemanticsNode> _nodes(WidgetTester tester) {
  final List<SemanticsNode> nodes = <SemanticsNode>[];
  void visit(SemanticsNode node) {
    nodes.add(node);
    node.visitChildren((SemanticsNode child) {
      visit(child);
      return true;
    });
  }

  for (final RenderView view in tester.binding.renderViews) {
    final SemanticsNode? root = view.owner?.semanticsOwner?.rootSemanticsNode;
    if (root != null) {
      visit(root);
    }
  }
  return nodes;
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

/// The style the digits are actually painted with.
TextStyle _digitStyle(WidgetTester tester) {
  return tester
      .widgetList<Text>(
        find.descendant(of: _slot(0), matching: find.byType(Text)),
      )
      .first
      .style!;
}

/// Asserts that [track] is one monotone run of [rows] rows in a single
/// direction, and that the slot then stays put.
///
/// [up] is the direction a growing value rolls: the column moves up, so the
/// unwrapped translation falls. A reversal anywhere before the slot arrives is
/// the failure this guards: a `9` becoming `0` that unwinds backwards travels
/// nine rows the wrong way rather than one row forward.
void _expectRoll({
  required List<double> track,
  required double lineHeight,
  required bool up,
  required int rows,
}) {
  final double target = up
      ? track.first - rows * lineHeight
      : track.first + rows * lineHeight;

  final int arrival = track.indexWhere(
    (double y) => up ? y <= target + 1e-9 : y >= target - 1e-9,
  );
  expect(arrival, greaterThan(0), reason: 'the slot never reached its target');
  for (var i = 1; i <= arrival; i++) {
    if (up) {
      expect(track[i], lessThanOrEqualTo(track[i - 1] + 1e-9));
    } else {
      expect(track[i], greaterThanOrEqualTo(track[i - 1] - 1e-9));
    }
  }

  // The whole travel is [rows] rows, not nine of them.
  expect((track.first - target).abs(), closeTo(rows * lineHeight, 0.05));

  // Settled: once the digit arrives it only wobbles inside the documented
  // bounce, so there is no second run away from the target.
  for (final double y in track.skip(arrival)) {
    expect((y - target).abs(), lessThan(lineHeight * 0.05));
  }
}

void main() {
  group('OrionCounter', () {
    testWidgets('rests on its digits without ticking', (tester) async {
      await _pumpCounter(tester, value: 1234);
      await tester.pumpAndSettle();

      expect(_slotCount(tester), 4);
      expect(_read(tester), '1234');

      final List<double> resting = _offsets(tester);
      for (var frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(_offsets(tester), resting);
      }
    });

    testWidgets('rests on zero with a single slot', (tester) async {
      await _pumpCounter(tester, value: 0);
      await tester.pumpAndSettle();

      expect(_slotCount(tester), 1);
      expect(_read(tester), '0');
    });

    testWidgets('rolls a changed digit over more than one frame', (
      tester,
    ) async {
      await _pumpCounter(tester, value: 5);
      await tester.pumpAndSettle();
      final double lineHeight = _lineHeight(tester);
      final double start = _offsets(tester).single;

      await _pumpCounter(tester, value: 6);
      // Frame 0: the retarget has not moved anything yet.
      expect(_offsets(tester).single, start);

      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      final double mid = _offsets(tester).single;
      expect(mid, lessThan(start));
      expect(mid, greaterThan(start - lineHeight));

      await tester.pumpAndSettle();
      expect(_read(tester), '6');
      expect(_offsets(tester).single, closeTo(start - lineHeight, 0.001));
    });

    testWidgets('leaves untouched slots exactly still', (tester) async {
      await _pumpCounter(tester, value: 1234);
      await tester.pumpAndSettle();
      final List<double> resting = _offsets(tester);
      final List<double> still = resting.sublist(0, 3);

      await _pumpCounter(tester, value: 1235);
      List<Transform> before = _transforms(tester);
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final List<Transform> now = _transforms(tester);

        // The three untouched slots never even rebuild...
        for (var index = 0; index < 3; index++) {
          expect(identical(now[index], before[index]), isTrue);
        }
        if (frame == 0) {
          // ...while the ones slot did, so the stillness above is not a missed
          // change.
          expect(identical(now.last, before.last), isFalse);
        }
        before = now;
        expect(_offsets(tester).sublist(0, 3), still);
      }

      // The ones slot really did travel, so the stillness above is not a missed
      // change.
      expect(_offsets(tester).last, isNot(resting.last));
      expect(_read(tester), '1235');
    });

    testWidgets('keeps an unchanged slot still during a carry', (tester) async {
      await _pumpCounter(tester, value: 190);
      await tester.pumpAndSettle();
      final double ones = _offsets(tester).last;

      await _pumpCounter(tester, value: 200);
      for (var frame = 0; frame < 40; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(_offsets(tester).last, ones);
      }

      expect(_read(tester), '200');
    });

    testWidgets('rolls up when the value grows and down when it shrinks', (
      tester,
    ) async {
      await _pumpCounter(tester, value: 5);
      await tester.pumpAndSettle();
      final double five = _offsets(tester).single;

      await _pumpCounter(tester, value: 6);
      await tester.pump(const Duration(milliseconds: 32));
      expect(_offsets(tester).single, lessThan(five));

      await tester.pumpAndSettle();
      final double six = _offsets(tester).single;

      await _pumpCounter(tester, value: 5);
      await tester.pump(const Duration(milliseconds: 32));
      expect(_offsets(tester).single, greaterThan(six));

      await tester.pumpAndSettle();
      expect(_read(tester), '5');
    });

    testWidgets('keeps rolling past the nine to zero boundary', (tester) async {
      await _pumpCounter(tester, value: 9);
      await tester.pumpAndSettle();
      final double lineHeight = _lineHeight(tester);
      expect(_read(tester), '9');

      await _pumpCounter(tester, value: 10);
      final List<double> offsets = await _sample(tester, 0, frames: 90);

      // It really crossed the boundary: the raw translation ended a whole period
      // away from where it started.
      expect(offsets.first, closeTo(-9 * lineHeight, 0.001));
      expect(offsets.last, closeTo(0, 0.001));

      // One row of travel, upward, with no reversal anywhere on the way.
      _expectRoll(
        track: _unwrap(offsets, lineHeight),
        lineHeight: lineHeight,
        up: true,
        rows: 1,
      );

      await tester.pumpAndSettle();
      expect(_read(tester), '10');
      // The new leading slot rested on its digit rather than springing in.
      expect(_visibleDigit(tester, 1), '1');
    });

    testWidgets('rolls the other way when zero becomes nine', (tester) async {
      await _pumpCounter(tester, value: 100);
      await tester.pumpAndSettle();
      final double lineHeight = _lineHeight(tester);

      await _pumpCounter(tester, value: 99);
      final List<double> offsets = await _sample(tester, 0, frames: 90);

      // Backward travel: the column moves down, so the unwrapped track only
      // grows, and the zero travels one row to become a nine.
      _expectRoll(
        track: _unwrap(offsets, lineHeight),
        lineHeight: lineHeight,
        up: false,
        rows: 1,
      );

      await tester.pumpAndSettle();
      expect(_slotCount(tester), 2);
      expect(_read(tester), '99');
    });

    testWidgets('carries across every slot', (tester) async {
      await _pumpCounter(tester, value: 199);
      await tester.pumpAndSettle();

      await _pumpCounter(tester, value: 200);
      await tester.pumpAndSettle();

      final double lineHeight = _lineHeight(tester);
      expect(_slotCount(tester), 3);
      expect(_read(tester), '200');
      expect(_offsets(tester)[0], closeTo(-2 * lineHeight, 0.001));
      expect(_offsets(tester)[1], closeTo(0, 0.001));
      expect(_offsets(tester)[2], closeTo(0, 0.001));
    });

    testWidgets('re-lays out when a leading slot appears', (tester) async {
      await _pumpCounter(tester, value: 9);
      await tester.pumpAndSettle();
      final double lineHeight = _lineHeight(tester);
      final double anchored =
          tester.getRect(find.byType(OrionCounter)).right -
          tester.getRect(_slot(0)).right;

      await _pumpCounter(tester, value: 10);
      await tester.pump();

      // The new slot is already at rest on its digit, and the ones slot has not
      // moved: the row re-laid out instead of animating a width into being.
      expect(_slotCount(tester), 2);
      expect(_visibleDigit(tester, 1), '1');
      expect(_offsets(tester).last, closeTo(-9 * lineHeight, 0.001));
      expect(tester.getSize(_slot(0)).width, tester.getSize(_slot(1)).width);
      // The units digit stays pinned to the trailing edge.
      expect(
        tester.getRect(find.byType(OrionCounter)).right -
            tester.getRect(_slot(0)).right,
        anchored,
      );

      await tester.pumpAndSettle();
      expect(_read(tester), '10');
    });

    testWidgets('drops the leading slot when the value shrinks', (
      tester,
    ) async {
      await _pumpCounter(tester, value: 1000);
      await tester.pumpAndSettle();

      await _pumpCounter(tester, value: 999);
      await tester.pumpAndSettle();

      expect(_slotCount(tester), 3);
      expect(_read(tester), '999');
      expect(tester.takeException(), isNull);
    });

    testWidgets('drops a slot that is still rolling', (tester) async {
      await _pumpCounter(tester, value: 2000);
      await tester.pumpAndSettle();

      // Start the thousands slot rolling, then take its slot away mid-flight.
      await _pumpCounter(tester, value: 3000);
      await tester.pump(const Duration(milliseconds: 16));
      await _pumpCounter(tester, value: 999);
      await tester.pumpAndSettle();

      expect(_slotCount(tester), 3);
      expect(_read(tester), '999');
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders immediately when animate is false', (tester) async {
      await _pumpCounter(tester, value: 12, animate: false);
      await tester.pumpAndSettle();

      await _pumpCounter(tester, value: 99, animate: false);
      await tester.pump();

      expect(_read(tester), '99');
      expect(_offsets(tester)[0], closeTo(-9 * _lineHeight(tester), 0.001));
      expect(_offsets(tester)[1], closeTo(-9 * _lineHeight(tester), 0.001));
    });

    testWidgets('settles at once when animate turns off mid-flight', (
      tester,
    ) async {
      await _pumpCounter(tester, value: 5);
      await _pumpCounter(tester, value: 6);
      await tester.pump(const Duration(milliseconds: 16));

      final double lineHeight = _lineHeight(tester);
      expect(_offsets(tester).single, greaterThan(-6 * lineHeight));

      await _pumpCounter(tester, value: 6, animate: false);
      await tester.pump();

      expect(_offsets(tester).single, closeTo(-6 * lineHeight, 0.001));
    });

    testWidgets('renders immediately when motion is reduced', (tester) async {
      await _pumpCounter(tester, value: 1234, disableAnimations: true);
      await tester.pumpAndSettle();

      await _pumpCounter(tester, value: 9876, disableAnimations: true);
      await tester.pump();

      final double lineHeight = _lineHeight(tester);
      expect(_read(tester), '9876');
      final List<double> settled = _offsets(tester);
      for (var index = 0; index < settled.length; index++) {
        expect(settled[index], closeTo(-(9 - index) * lineHeight, 0.001));
      }
    });

    testWidgets('settles at once when motion is reduced mid-flight', (
      tester,
    ) async {
      await _pumpCounter(tester, value: 5);
      await _pumpCounter(tester, value: 6);
      await tester.pump(const Duration(milliseconds: 16));

      final double lineHeight = _lineHeight(tester);
      expect(_offsets(tester).single, greaterThan(-6 * lineHeight));

      await _pumpCounter(tester, value: 6, disableAnimations: true);
      // The jump is scheduled for the end of the frame that noticed the change.
      await tester.pump();
      await tester.pump();

      expect(_offsets(tester).single, closeTo(-6 * lineHeight, 0.001));
    });

    testWidgets('keeps the digit column out of the ticker rebuilds', (
      tester,
    ) async {
      await _pumpCounter(tester, value: 1234);
      await _pumpCounter(tester, value: 1235);

      final Finder tickers = find.descendant(
        of: find.byType(OrionCounter),
        matching: find.byType(AnimatedBuilder),
      );
      final List<Widget> columns = tester
          .widgetList<AnimatedBuilder>(tickers)
          .map((AnimatedBuilder builder) => builder.child!)
          .toList();
      // Every slot rolls behind the same pre-built column.
      expect(columns.toSet(), hasLength(1));
      // The rows themselves keep their elements and their render objects.
      final List<RenderObject> rows = _rows(tester, 0);
      expect(rows, hasLength(20));

      List<double> previous = _offsets(tester);
      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));

        // The ticker really ran, so the identity check is not vacuous.
        final List<double> current = _offsets(tester);
        expect(current, isNot(previous));
        previous = current;
        for (final AnimatedBuilder builder
            in tester.widgetList<AnimatedBuilder>(tickers)) {
          expect(identical(builder.child, columns.first), isTrue);
        }
        final List<RenderObject> now = _rows(tester, 0);
        for (var row = 0; row < rows.length; row++) {
          expect(identical(now[row], rows[row]), isTrue);
        }
      }

      await tester.pumpAndSettle();
    });

    testWidgets('overshoots once without stalling at a cap', (tester) async {
      await _pumpCounter(tester, value: 5);
      final double lineHeight = _lineHeight(tester);
      final double target = -6 * lineHeight;

      await _pumpCounter(tester, value: 6);
      final List<double> offsets = await _sample(tester, 0, frames: 90);
      final double peak = offsets.reduce(math.min);

      // It really does travel past the target...
      expect(peak, lessThan(target));
      // ...by less than the resolved style's own leading, so no glyph of the
      // neighbouring row can reach the window.
      expect(peak, greaterThan(target - lineHeight * 0.05));
      // A cap would hold the value at the peak for many frames; a spring visits.
      expect(
        offsets.where((double y) => (y - peak).abs() < 1e-6),
        hasLength(1),
      );
      expect(offsets.last, closeTo(target, 0.001));
    });

    testWidgets('renders exactly one line at three text scales', (
      tester,
    ) async {
      for (final double scale in <double>[1.0, 1.5, 2.0]) {
        await _pumpCounter(tester, value: 123, textScale: scale);
        await tester.pumpAndSettle();

        final TextPainter painter = TextPainter(
          text: TextSpan(text: '0', style: _digitStyle(tester)),
          textDirection: TextDirection.ltr,
          textScaler: TextScaler.linear(scale),
        )..layout();

        expect(
          tester.getSize(find.byType(OrionCounter)).height,
          closeTo(painter.height, 0.001),
        );
      }
    });

    testWidgets('pins every slot to the widest digit', (tester) async {
      await _pumpCounter(tester, value: 1);
      await tester.pumpAndSettle();
      final double narrow = tester.getSize(find.byType(OrionCounter)).width;

      await _pumpCounter(tester, value: 8);
      await tester.pumpAndSettle();
      final double wide = tester.getSize(find.byType(OrionCounter)).width;

      // A proportional figure cannot make the row twitch.
      expect(wide, narrow);

      final TextStyle style = _digitStyle(tester);
      var widest = 0.0;
      for (var digit = 0; digit < 10; digit++) {
        final TextPainter painter = TextPainter(
          text: TextSpan(text: '$digit', style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        widest = math.max(widest, painter.width);
      }
      expect(tester.getSize(_slot(0)).width, closeTo(widest, 0.001));
    });

    testWidgets('asks for tabular figures', (tester) async {
      await _pumpCounter(tester, value: 42);
      await tester.pumpAndSettle();

      expect(
        _digitStyle(tester).fontFeatures,
        contains(const FontFeature.tabularFigures()),
      );
    });

    testWidgets('merges the ambient style with the given one', (tester) async {
      await _pumpCounter(
        tester,
        value: 7,
        style: OrionCounterStyle.from(
          textStyle: const TextStyle(fontSize: 32, letterSpacing: 2),
        ),
      );
      await tester.pumpAndSettle();

      final TextStyle style = _digitStyle(tester);
      expect(style.fontSize, 32);
      expect(style.letterSpacing, 2);
      // The ambient style still supplies what the override left unset.
      expect(style.color, isNotNull);
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionCounterTheme(
            defaultStyle: OrionCounterStyle.from(
              textStyle: const TextStyle(fontSize: 28),
            ),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: themed,
          home: const Scaffold(body: Center(child: OrionCounter(value: 7))),
        ),
      );
      await tester.pumpAndSettle();
      expect(_digitStyle(tester).fontSize, 28);

      await tester.pumpWidget(
        MaterialApp(
          theme: themed,
          home: const Scaffold(
            body: Center(
              child: OrionCounter(
                value: 7,
                style: OrionCounterStyle(textStyle: TextStyle(fontSize: 12)),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(_digitStyle(tester).fontSize, 12);
    });

    testWidgets('a retuned deformation reaches the roll', (tester) async {
      await _pumpCounter(
        tester,
        value: 7,
        style: OrionCounterStyle.from(rollStretchX: 0.4, rollSquashY: 0.5),
      );
      await tester.pumpAndSettle();

      await _pumpCounter(
        tester,
        value: 8,
        style: OrionCounterStyle.from(rollStretchX: 0.4, rollSquashY: 0.5),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // Mid-roll the digit is stretched well past the shipped 6 %.
      double maxScale = 0;
      for (var frame = 0; frame < 40; frame++) {
        final Transform transform = tester.widget<Transform>(
          find
              .descendant(
                of: find.byType(OrionCounter),
                matching: find.byType(Transform),
              )
              .last,
        );
        maxScale = math.max(maxScale, transform.transform.entry(0, 0));
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(maxScale, greaterThan(1.2));
      await tester.pumpAndSettle();
    });

    test('a merge only changes the fields it names', () {
      final OrionCounterStyle base = OrionCounterStyle.from(
        rollStretchX: 0.2,
        textStyle: const TextStyle(fontSize: 20),
      );
      final OrionCounterStyle merged = base.merge(
        OrionCounterStyle.from(textStyle: const TextStyle(fontSize: 24)),
      );

      expect(merged.textStyle, const TextStyle(fontSize: 24));
      expect(merged.rollStretchX, 0.2);
    });

    test('presets reproduce the shipped roll', () {
      final OrionCounterStyle style = OrionCounterPresets.resolve();

      expect(style.textStyle, isNull);
      expect(style.rollStretchX, 0.06);
      expect(style.rollSquashY, 0.10);
      expect(style.spring, OrionSpringSpec.gentle);
    });

    testWidgets('exposes one node with the formatted value', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCounter(tester, value: 128, semanticLabel: 'Unread');
      await tester.pumpAndSettle();

      final SemanticsNode node = tester.getSemantics(find.byType(OrionCounter));
      expect(node.label, 'Unread');
      expect(node.value, '128');
      expect(node.flagsCollection.isButton, isFalse);

      // Exactly one node carries the value...
      expect(
        _nodes(tester).where((SemanticsNode node) => node.value == '128'),
        hasLength(1),
      );
      // ...and no digit glyph reached the tree, in any node.
      final RegExp glyph = RegExp(r'^\d$');
      expect(
        _nodes(tester).where(
          (SemanticsNode node) =>
              glyph.hasMatch(node.label) || glyph.hasMatch(node.value),
        ),
        isEmpty,
      );
      handle.dispose();
    });

    testWidgets('exposes the value alone when there is no spoken name', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpCounter(tester, value: 42);
      await tester.pumpAndSettle();

      final SemanticsNode node = tester.getSemantics(find.byType(OrionCounter));
      expect(node.label, isEmpty);
      expect(node.value, '42');
      handle.dispose();
    });

    testWidgets('rejects a negative value', (tester) async {
      expect(() => _pumpCounter(tester, value: -1), throwsAssertionError);
    });

    testWidgets('stays silent while its list is dragged', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              itemExtent: 60,
              itemCount: 20,
              itemBuilder: (BuildContext context, int index) =>
                  OrionCounter(value: 1000 + index),
            ),
          ),
        ),
      );
      final ScrollableState scrollable = tester.state<ScrollableState>(
        find.byType(Scrollable),
      );
      expect(scrollable.position.pixels, 0);

      // The counter takes no pointer itself, so the drag belongs to the list.
      await tester.drag(
        find.byType(OrionCounter).first,
        const Offset(0, -300),
        warnIfMissed: false,
      );
      await tester.pumpAndSettle();

      // The list really scrolled, so the silence below is not a missed drag.
      expect(scrollable.position.pixels, greaterThan(0));
      expect(haptics, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('survives being scrolled away while rolling', (tester) async {
      final ValueNotifier<int> value = ValueNotifier<int>(1234);
      addTearDown(value.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              itemExtent: 60,
              itemCount: 20,
              itemBuilder: (BuildContext context, int index) =>
                  ValueListenableBuilder<int>(
                    valueListenable: value,
                    builder:
                        (BuildContext context, int current, Widget? child) =>
                            OrionCounter(value: index == 0 ? current : index),
                  ),
            ),
          ),
        ),
      );

      value.value = 1235;
      await tester.pump(const Duration(milliseconds: 16));

      await tester.drag(find.byType(ListView), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });

    testWidgets('disposes every driver when it leaves the tree mid-roll', (
      tester,
    ) async {
      await _pumpCounter(tester, value: 1234);
      await _pumpCounter(tester, value: 1235);
      await tester.pump(const Duration(milliseconds: 16));

      await tester.pumpWidget(const SizedBox());

      expect(tester.takeException(), isNull);
      // A driver left alive would still have a ticker scheduled.
      expect(tester.binding.transientCallbackCount, 0);
    });

    testWidgets('keeps its digits left to right under right-to-left', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: const Center(child: OrionCounter(value: 123)),
            ),
          ),
        ),
      );
      await tester.pump();

      // Numerals read left to right in every locale: the ones slot stays on the
      // right, so 123 is never rendered as 321.
      final double ones = tester
          .getCenter(find.byKey(const ValueKey<int>(0)))
          .dx;
      final double tens = tester
          .getCenter(find.byKey(const ValueKey<int>(1)))
          .dx;
      final double hundreds = tester
          .getCenter(find.byKey(const ValueKey<int>(2)))
          .dx;
      expect(ones, greaterThan(tens));
      expect(tens, greaterThan(hundreds));
    });
  });
}
