import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

const double _extent = OrionSwipeActionRow.actionExtent;
const double _twoTrailing = -2 * _extent;
const Key _childKey = ValueKey<String>('swipe-test-child');

void _noop() {}

List<OrionSwipeAction> _actions(
  List<String> labels, {
  void Function(String)? onPressed,
  List<String> disabled = const <String>[],
}) {
  return <OrionSwipeAction>[
    for (final String label in labels)
      OrionSwipeAction(
        icon: const Icon(Icons.star),
        label: label,
        onPressed: disabled.contains(label)
            ? null
            : (onPressed == null ? _noop : () => onPressed(label)),
      ),
  ];
}

/// The row's offset in logical pixels, read from the translated content.
double _offset(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find.byKey(OrionSwipeActionRow.contentKey),
  );
  return transform.transform.entry(0, 3);
}

/// The pane layers that are actually in the tree: a side with no actions builds
/// nothing, so the leading layer is present only when the row has leading actions.
/// Every row's offset, in tree order.
List<double> _offsets(WidgetTester tester) => tester
    .widgetList<Transform>(find.byKey(OrionSwipeActionRow.contentKey))
    .map((Transform t) => t.transform.entry(0, 3))
    .toList();

List<Opacity> _paneLayers(WidgetTester tester) => tester
    .widgetList<Opacity>(
      find.descendant(
        of: find.byType(OrionSwipeActionRow),
        matching: find.byType(Opacity),
      ),
    )
    .toList();

/// Opacity of the trailing pane layer, or of the leading one when asked.
double _paneOpacity(WidgetTester tester, {bool leading = false}) {
  final List<Opacity> layers = _paneLayers(tester);
  return (leading ? layers.first : layers.last).opacity;
}

double _paneWidth(WidgetTester tester, {bool leading = false}) {
  final List<Opacity> layers = _paneLayers(tester);
  final Element element = tester.element(
    find.byWidget(leading ? layers.first : layers.last),
  );
  return tester
      .getSize(
        find
            .descendant(
              of: find.byElementPredicate((Element e) => e == element),
              matching: find.byType(SizedBox),
            )
            .first,
      )
      .width;
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

Future<void> _pumpRow(
  WidgetTester tester, {
  List<OrionSwipeAction>? trailing,
  List<OrionSwipeAction> leading = const <OrionSwipeAction>[],
  bool enabled = true,
  Widget? child,
  ValueChanged<bool>? onOpenChanged,
  bool scoped = false,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
  bool scrollable = false,
  int rows = 1,
  double width = 390,
}) {
  Widget buildRow() => OrionSwipeActionRow(
    trailing: trailing ?? _actions(<String>['Star', 'Delete']),
    leading: leading,
    enabled: enabled,
    onOpenChanged: onOpenChanged,
    child:
        child ?? const SizedBox(key: _childKey, height: 56, child: Text('Row')),
  );

  final Widget content = scrollable
      ? ListView.builder(
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) => buildRow(),
        )
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[for (int i = 0; i < rows; i++) buildRow()],
        );

  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: textDirection,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: SizedBox(
              width: width,
              child: scoped ? OrionSwipeScope(child: content) : content,
            ),
          ),
        ),
      ),
    ),
  );
}

/// Drags a row. The default step is deliberately slow. Tests that want a flick
/// pass a short [step] on purpose. A flick still only opens the row.
Future<void> _drag(
  WidgetTester tester,
  List<Offset> steps, {
  Duration step = const Duration(milliseconds: 100),
  bool release = true,
  int rowIndex = 0,
  Finder? on,
}) async {
  final Finder target = on ?? find.byKey(_childKey).at(rowIndex);
  final TestGesture gesture = await tester.startGesture(
    tester.getCenter(target),
  );
  Duration stamp = Duration.zero;
  for (final Offset delta in steps) {
    stamp += step;
    await gesture.moveBy(delta, timeStamp: stamp);
    await tester.pump(step);
  }
  if (release) {
    await gesture.up();
    await tester.pump();
  }
}

void main() {
  group('OrionSwipeActionRow', () {
    testWidgets('rests closed with its panes invisible and inert', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Delete'], onPressed: pressed.add),
        child: const SizedBox(key: _childKey, height: 56),
      );

      expect(_offset(tester), 0);
      expect(_paneOpacity(tester), 0);
      expect(_paneWidth(tester), _extent);

      final Rect row = tester.getRect(find.byType(OrionSwipeActionRow));
      await tester.tapAt(Offset(row.right - 22, row.center.dy));
      await tester.pump();
      expect(pressed, isEmpty);
      expect(haptics, isEmpty);
    });

    testWidgets('follows the finger one to one inside the extent', (
      tester,
    ) async {
      await _pumpRow(tester);

      // The drag is accepted at the pointer down, so there is no dead zone: every
      // pixel the finger moves moves the row.
      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-15, 0),
      ], release: false);
      expect(_offset(tester), closeTo(-40, 0.5));
    });

    testWidgets('resists past the extent and keeps travelling', (tester) async {
      await _pumpRow(tester);

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-200, 0),
      ], release: false);

      // Elastic, but still past the buttons, so a long drag has not stuck there.
      expect(_offset(tester), lessThan(_twoTrailing));
      expect(_offset(tester), greaterThan(-420));
    });

    testWidgets('a long pull stretches both actions, then rests them', (
      tester,
    ) async {
      await _pumpRow(tester);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_childKey)),
      );
      Duration stamp = Duration.zero;
      for (final double dx in <double>[-25, -300]) {
        stamp += const Duration(milliseconds: 100);
        await gesture.moveBy(Offset(dx, 0), timeStamp: stamp);
        await tester.pump(const Duration(milliseconds: 100));
      }

      final List<double> pulled = <double>[
        for (final String label in <String>['Star', 'Delete'])
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(OrionPressable),
                ),
              )
              .width,
      ];
      expect(pulled.first, greaterThan(_extent + 20));
      expect(pulled.last, closeTo(pulled.first, 0.5));

      await gesture.up();
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(_twoTrailing, 0.5));
      for (final String label in <String>['Star', 'Delete']) {
        expect(
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(OrionPressable),
                ),
              )
              .width,
          closeTo(_extent, 0.5),
        );
      }
    });

    testWidgets('a deliberate drag opens onto the extent', (tester) async {
      await _pumpRow(tester);

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-60, 0)]);
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(_twoTrailing, 0.5));
      expect(_paneOpacity(tester), 1);
    });

    testWidgets('a release under the reveal travel closes', (tester) async {
      await _pumpRow(tester);

      await _drag(tester, <Offset>[const Offset(-10, 0)]);
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(0, 0.5));
      expect(_paneOpacity(tester), 0);
    });

    testWidgets('a deliberate drag opens without committing', (tester) async {
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Star', 'Delete'], onPressed: pressed.add),
      );

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-60, 0)]);
      await tester.pumpAndSettle();

      expect(pressed, isEmpty);
      expect(_offset(tester), closeTo(_twoTrailing, 0.5));
    });

    testWidgets('a second drag retargets the same spring without snapping', (
      tester,
    ) async {
      await _pumpRow(tester);

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-40, 0)]);
      await tester.pump(const Duration(milliseconds: 16));
      final double mid = _offset(tester);
      expect(mid, greaterThan(_twoTrailing));
      expect(mid, lessThan(0));

      // Grab it again mid-settle: acceptance must not move the row, and the
      // displacement is measured from where the row actually is, so the follow is
      // absolute rather than re-anchored to zero.
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_childKey)),
      );
      await gesture.moveBy(const Offset(20, 0)); // consumed as the drag slop
      await tester.pump();
      expect(_offset(tester), closeTo(mid, 0.01));

      await gesture.moveBy(const Offset(20, 0));
      await tester.pump();
      expect(_offset(tester), closeTo(mid + 20, 0.5));

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('a full swipe rests on both actions and runs nothing', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Star', 'Delete'], onPressed: pressed.add),
      );

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-200, 0),
        const Offset(-200, 0),
      ]);
      await tester.pumpAndSettle();

      expect(pressed, isEmpty);
      expect(_offset(tester), closeTo(_twoTrailing, 0.5));
      for (final String label in <String>['Star', 'Delete']) {
        expect(
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(OrionPressable),
                ),
              )
              .width,
          _extent,
        );
      }
      expect(haptics, <String>['HapticFeedbackType.selectionClick']);
    });

    testWidgets('a fast flick reveals and stays revealed, however fast', (
      tester,
    ) async {
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Star', 'Delete'], onPressed: pressed.add),
      );

      // A quick flick of the kind a thumb makes. Velocity must not run an action,
      // and it must not send the row home either.
      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-60, 0),
      ], step: const Duration(milliseconds: 8));
      await tester.pumpAndSettle();

      expect(pressed, isEmpty);
      expect(_offset(tester), closeTo(_twoTrailing, 0.5));
    });

    testWidgets('a long slow swipe rests on both actions', (tester) async {
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Star', 'Delete'], onPressed: pressed.add),
      );

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-200, 0),
        const Offset(-120, 0),
      ]);
      await tester.pumpAndSettle();

      expect(pressed, isEmpty);
      expect(_offset(tester), closeTo(_twoTrailing, 0.5));
    });

    testWidgets('a resting open row gives each action a wide target', (
      tester,
    ) async {
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Star', 'Delete'], onPressed: pressed.add),
      );

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-60, 0)]);
      await tester.pumpAndSettle();

      for (final String label in <String>['Star', 'Delete']) {
        expect(
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(OrionPressable),
                ),
              )
              .width,
          _extent,
        );
      }
      await tester.tap(find.text('Star'));
      await tester.pumpAndSettle();
      expect(pressed, <String>['Star']);
    });

    testWidgets('a disabled dominant action is never committed', (
      tester,
    ) async {
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(
          <String>['Star', 'Delete'],
          onPressed: pressed.add,
          disabled: <String>['Delete'],
        ),
      );

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-200, 0),
        const Offset(-200, 0),
      ]);
      await tester.pumpAndSettle();

      // A disabled action never runs, and the long swipe still opens the row.
      expect(pressed, isEmpty);
      expect(_offset(tester), closeTo(_twoTrailing, 0.5));
    });

    testWidgets('a drag toward a side with no actions is damped, then closes', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      await _pumpRow(tester);

      await _drag(tester, <Offset>[const Offset(25, 0), const Offset(200, 0)]);
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(0, 0.5));
      expect(haptics, isEmpty);
    });

    testWidgets('a tap on open content closes it without activating it', (
      tester,
    ) async {
      int childTaps = 0;
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Delete']),
        child: GestureDetector(
          key: _childKey,
          onTap: () => childTaps++,
          child: const SizedBox(height: 56, child: Text('Row')),
        ),
      );

      await tester.tap(find.byKey(_childKey));
      await tester.pump();
      expect(childTaps, 1);

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-60, 0)]);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(-_extent, 0.5));

      await tester.tap(find.byKey(_childKey));
      await tester.pumpAndSettle();
      expect(childTaps, 1);
      expect(_offset(tester), closeTo(0, 0.5));
    });

    testWidgets('a tap on the surrounding surface closes the open row', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionSwipeScope(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  OrionSwipeActionRow(
                    trailing: _actions(<String>['Star', 'Delete']),
                    child: const SizedBox(
                      key: _childKey,
                      height: 56,
                      child: Text('Row'),
                    ),
                  ),
                  const SizedBox(height: 200),
                ],
              ),
            ),
          ),
        ),
      );

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-60, 0)]);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(_twoTrailing, 0.5));

      // Anywhere on the surface that is not the open row itself.
      await tester.tapAt(
        tester.getCenter(find.byType(OrionSwipeActionRow)) +
            const Offset(0, 120),
      );
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(0, 0.5));
    });

    testWidgets('opening another row closes the first', (tester) async {
      await _pumpRow(tester, scoped: true, rows: 2);

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-60, 0),
      ], rowIndex: 0);
      await tester.pumpAndSettle();
      expect(
        tester
            .widgetList<Transform>(find.byKey(OrionSwipeActionRow.contentKey))
            .first
            .transform
            .entry(0, 3),
        closeTo(_twoTrailing, 0.5),
      );

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-60, 0),
      ], rowIndex: 1);
      await tester.pumpAndSettle();

      final List<double> offsets = tester
          .widgetList<Transform>(find.byKey(OrionSwipeActionRow.contentKey))
          .map((Transform t) => t.transform.entry(0, 3))
          .toList();
      expect(offsets.first, closeTo(0, 0.5));
      expect(offsets.last, closeTo(_twoTrailing, 0.5));
    });

    testWidgets('haptics tick at the thresholds and stay quiet otherwise', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      await _pumpRow(tester);

      // Cross the reveal threshold once, then dip back into the hysteresis band
      // (85 % of the extent) and out again: resetting on any dip below the line
      // would chatter here, and the latch is what stops it.
      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-170, 0),
        const Offset(60, 0),
        const Offset(-60, 0),
        const Offset(60, 0),
      ], release: false);

      expect(haptics, <String>['HapticFeedbackType.selectionClick']);

      await tester.tap(find.byType(OrionSwipeActionRow));
      await tester.pumpAndSettle();
    });

    testWidgets('a cancelled drag is silent and springs back', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      await _pumpRow(tester);

      // Under half the extent, so cancelling springs back to rest and no
      // threshold was ever crossed.
      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_childKey)),
      );
      Duration stamp = Duration.zero;
      for (final double dx in <double>[-5, -5]) {
        stamp += const Duration(milliseconds: 100);
        await gesture.moveBy(Offset(dx, 0), timeStamp: stamp);
        await tester.pump(const Duration(milliseconds: 100));
      }
      await gesture.cancel();
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(0, 0.5));
      expect(haptics, isEmpty);
    });

    testWidgets('a vertical drag scrolls a list and leaves the row silent', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      await _pumpRow(tester, scrollable: true);

      final ScrollableState scrollable = tester.state(
        find.byType(Scrollable).first,
      );
      await tester.drag(find.byType(ListView), const Offset(0, -300));
      await tester.pumpAndSettle();

      expect(scrollable.position.pixels, greaterThan(0));
      expect(_offsets(tester).first, 0);
      expect(haptics, isEmpty);
    });

    testWidgets('jumps to the open position when motion is reduced', (
      tester,
    ) async {
      await _pumpRow(tester, disableAnimations: true);

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-60, 0)]);
      await tester.pump();

      expect(_offset(tester), _twoTrailing);
    });

    testWidgets('settles at once when motion is turned off mid-drag', (
      tester,
    ) async {
      await _pumpRow(tester);

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-40, 0),
      ], release: false);
      await tester.pump(const Duration(milliseconds: 16));
      expect(_offset(tester).abs(), lessThan(_twoTrailing.abs()));

      await _pumpRow(tester, disableAnimations: true);
      await tester.pump();
      await tester.pump();

      expect(_offset(tester), closeTo(0, 0.5));
    });

    testWidgets('keeps the content out of the ticker rebuilds', (tester) async {
      int builds = 0;
      await _pumpRow(
        tester,
        child: Builder(
          key: _childKey,
          builder: (BuildContext context) {
            builds++;
            return const SizedBox(height: 56);
          },
        ),
      );
      expect(builds, 1);

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-40, 0),
      ], release: false);
      for (int frame = 0; frame < 6; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(builds, 1);
      }
      await tester.pumpAndSettle();
      expect(builds, 1);
    });

    testWidgets('reports every open and closed transition', (tester) async {
      final List<bool> states = <bool>[];
      await _pumpRow(tester, onOpenChanged: states.add);

      await _drag(tester, <Offset>[
        const Offset(-25, 0),
        const Offset(-100, 0),
      ]);
      await tester.pumpAndSettle();
      expect(states, <bool>[true]);

      await tester.tap(find.byKey(_childKey));
      await tester.pumpAndSettle();
      expect(states, <bool>[true, false]);
    });

    testWidgets('a closed row lets an ancestor take the tap', (tester) async {
      int ancestorTaps = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => ancestorTaps++,
              child: SizedBox(
                width: 390,
                child: OrionSwipeActionRow(
                  trailing: _actions(<String>['Delete']),
                  child: const SizedBox(key: _childKey, height: 56),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(_childKey));
      await tester.pump();
      expect(ancestorTaps, 1);
    });

    testWidgets('keeps wide actions and the height of its child', (
      tester,
    ) async {
      await _pumpRow(tester);

      expect(
        tester.getSize(find.byType(OrionSwipeActionRow)).height,
        tester.getSize(find.byKey(_childKey)).height,
      );

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-40, 0)]);
      await tester.pumpAndSettle();

      for (final String label in <String>['Star', 'Delete']) {
        expect(
          tester
              .getSize(
                find.ancestor(
                  of: find.text(label),
                  matching: find.byType(OrionPressable),
                ),
              )
              .width,
          greaterThanOrEqualTo(_extent),
        );
      }
    });

    testWidgets('mirrors the drag direction in right-to-left', (tester) async {
      await _pumpRow(
        tester,
        trailing: const <OrionSwipeAction>[],
        leading: _actions(<String>['Pin']),
        textDirection: TextDirection.rtl,
      );

      await _drag(tester, <Offset>[const Offset(25, 0), const Offset(40, 0)]);
      await tester.pumpAndSettle();

      expect(_offset(tester), closeTo(_extent, 0.5));
    });

    testWidgets('exposes every enabled action as an accessibility action', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Star'], disabled: <String>['Star']),
        leading: _actions(<String>['Pin']),
      );

      final SemanticsData data = tester
          .getSemantics(find.byType(OrionSwipeActionRow))
          .getSemanticsData();
      // Only the enabled action contributes one.
      expect(data.customSemanticsActionIds?.length, 1);
      handle.dispose();
    });

    testWidgets('a disabled row drags nothing and exposes nothing', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpRow(tester, enabled: false);

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-40, 0)]);
      await tester.pumpAndSettle();

      expect(_offset(tester), 0);
      final SemanticsData data = tester
          .getSemantics(find.byType(OrionSwipeActionRow))
          .getSemanticsData();
      expect(data.customSemanticsActionIds ?? const <int>[], isEmpty);
      handle.dispose();
    });

    testWidgets('survives being scrolled away while held', (tester) async {
      await _pumpRow(tester, scrollable: true);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byKey(_childKey).first),
      );
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, -600));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
