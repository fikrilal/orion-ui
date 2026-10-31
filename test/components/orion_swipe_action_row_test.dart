import 'dart:ui' show PointerDeviceKind;

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
  bool autoClose = true,
  Color? background,
  Color? foreground,
}) {
  return <OrionSwipeAction>[
    for (final String label in labels)
      OrionSwipeAction(
        icon: const Icon(Icons.star),
        label: label,
        background: background,
        foreground: foreground,
        autoClose: autoClose,
        onPressed: disabled.contains(label)
            ? null
            : (onPressed == null ? _noop : () => onPressed(label)),
      ),
  ];
}

/// Screen-space horizontal translation of the row content.
double _offset(WidgetTester tester, {int index = 0}) {
  final Transform transform = tester
      .widgetList<Transform>(find.byKey(OrionSwipeActionRow.contentKey))
      .elementAt(index);
  return transform.transform.entry(0, 3);
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
  bool leadingFullSwipe = false,
  bool trailingFullSwipe = false,
  bool enabled = true,
  Widget? child,
  OrionSwipeController? controller,
  OrionSwipeStyle? style,
  ValueChanged<bool>? onOpenChanged,
  ValueChanged<OrionSwipeSide?>? onSideChanged,
  bool scoped = false,
  bool disableAnimations = false,
  TextDirection textDirection = TextDirection.ltr,
  bool scrollable = false,
  int rows = 1,
  double width = 390,
}) {
  Widget buildRow(int index) => OrionSwipeActionRow(
    trailing: trailing ?? _actions(<String>['Star', 'Delete']),
    leading: leading,
    leadingFullSwipe: leadingFullSwipe,
    trailingFullSwipe: trailingFullSwipe,
    enabled: enabled,
    controller: index == 0 ? controller : null,
    style: style,
    onOpenChanged: index == 0 ? onOpenChanged : null,
    onSideChanged: index == 0 ? onSideChanged : null,
    child:
        child ??
        SizedBox(
          key: index == 0 ? _childKey : ValueKey<String>('swipe-child-$index'),
          height: 56,
          child: Text('Row $index'),
        ),
  );

  final Widget content = scrollable
      ? ListView.builder(
          itemCount: 20,
          itemBuilder: (BuildContext context, int index) => buildRow(index),
        )
      : Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[for (int i = 0; i < rows; i++) buildRow(i)],
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

Future<TestGesture> _drag(
  WidgetTester tester,
  List<Offset> steps, {
  Duration step = const Duration(milliseconds: 100),
  bool release = true,
  int rowIndex = 0,
}) async {
  final Finder target = find.byType(OrionSwipeActionRow).at(rowIndex);
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
  return gesture;
}

void main() {
  group('OrionSwipeActionRow', () {
    testWidgets('rests closed with panes collapsed (zero bleed) and inert', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Delete'], onPressed: pressed.add),
        style: OrionSwipeStyle(borderRadius: BorderRadius.circular(12)),
      );

      expect(_offset(tester), 0);
      expect(find.text('Delete'), findsNothing);

      final Rect row = tester.getRect(find.byType(OrionSwipeActionRow));
      await tester.tapAt(Offset(row.right - 22, row.center.dy));
      await tester.pump();
      expect(pressed, isEmpty);
      expect(haptics, isEmpty);
    });

    testWidgets(
      'tracks 1:1 inside extent, resists past it, and reverses immediately',
      (tester) async {
        await _pumpRow(tester);

        final TestGesture g = await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-40, 0),
        ], release: false);
        // 1:1 inside 148 px extent.
        expect(_offset(tester), closeTo(-65, 1.0));

        // Pull well past 148 px into elastic stretch.
        await g.moveBy(const Offset(-220, 0));
        await tester.pump();
        final double stretched = _offset(tester);
        expect(stretched, lessThan(_twoTrailing));
        expect(stretched, greaterThan(-280));

        // Reversing right moves back immediately (no sticky dead-zone).
        await g.moveBy(const Offset(40, 0));
        await tester.pump();
        expect(_offset(tester), greaterThan(stretched + 30));

        await g.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets(
      'ignores small accidental drags and closes naturally when dragged back',
      (tester) async {
        await _pumpRow(tester);

        // Small 16 px nudge stays closed (not accidentally snapped open).
        await _drag(tester, <Offset>[const Offset(-16, 0)]);
        await tester.pumpAndSettle();
        expect(_offset(tester), closeTo(0, 0.5));

        // Deliberate drag opens onto -148 px.
        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-70, 0),
        ]);
        await tester.pumpAndSettle();
        expect(_offset(tester), closeTo(_twoTrailing, 0.5));

        // Dragging an open row ~45% back toward closed (-148 -> ~-80) and
        // releasing slowly closes it cleanly instead of snapping back open.
        await _drag(tester, <Offset>[const Offset(25, 0), const Offset(45, 0)]);
        await tester.pumpAndSettle();
        expect(_offset(tester), closeTo(0, 0.5));
      },
    );

    testWidgets('opens on a fast flick and closes on a closing flick', (
      tester,
    ) async {
      await _pumpRow(tester);

      await _drag(tester, <Offset>[
        const Offset(-20, 0),
        const Offset(-25, 0),
      ], step: const Duration(milliseconds: 10));
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(_twoTrailing, 0.5));

      await _drag(tester, <Offset>[
        const Offset(20, 0),
        const Offset(25, 0),
      ], step: const Duration(milliseconds: 10));
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(0, 0.5));
    });

    testWidgets(
      'full-swipe arms, expands primary action, commits on release, and disarms if pulled back',
      (tester) async {
        final List<String> haptics = _captureHaptics(tester);
        final List<String> pressed = <String>[];
        await _pumpRow(
          tester,
          trailingFullSwipe: true,
          trailing: _actions(<String>[
            'Star',
            'Delete',
          ], onPressed: pressed.add),
        );

        // Pull past full-swipe threshold (~226 px on 390 px row), then pull back
        // to disarm before releasing -> opens tray without committing!
        final TestGesture disarm = await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-280, 0),
        ], release: false);
        await tester.pumpAndSettle();
        expect(haptics, contains('HapticFeedbackType.mediumImpact'));

        // Primary action expanded wider than resting extent while armed.
        final double armedDeleteWidth = tester
            .getSize(
              find.ancestor(
                of: find.text('Delete'),
                matching: find.byType(OrionPressable),
              ),
            )
            .width;
        expect(armedDeleteWidth, greaterThan(200));

        // Pull back below threshold to disarm and release.
        await disarm.moveBy(const Offset(130, 0));
        await tester.pumpAndSettle();
        await disarm.up();
        await tester.pumpAndSettle();
        expect(pressed, isEmpty);
        expect(_offset(tester), closeTo(_twoTrailing, 0.5));

        // Close, then pull past threshold and release -> commits Delete!
        await _drag(tester, <Offset>[const Offset(100, 0)]);
        await tester.pumpAndSettle();

        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-290, 0),
        ]);
        await tester.pumpAndSettle();
        expect(pressed, <String>['Delete']);
        expect(_offset(tester), closeTo(0, 0.5));
      },
    );

    testWidgets(
      'non-full-swipe long pull stretches all actions and settles without committing',
      (tester) async {
        final List<String> pressed = <String>[];
        await _pumpRow(
          tester,
          trailingFullSwipe: false,
          trailing: _actions(<String>[
            'Star',
            'Delete',
          ], onPressed: pressed.add),
        );

        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-300, 0),
        ]);
        await tester.pumpAndSettle();

        expect(pressed, isEmpty);
        expect(_offset(tester), closeTo(_twoTrailing, 0.5));
      },
    );

    testWidgets('mirrors drag direction and pane alignment accurately in RTL', (
      tester,
    ) async {
      final List<String> pressed = <String>[];
      await _pumpRow(
        tester,
        textDirection: TextDirection.rtl,
        leading: _actions(<String>['Pin'], onPressed: pressed.add),
        trailing: _actions(<String>['Star', 'Delete'], onPressed: pressed.add),
      );

      // In RTL, leading sits on the RIGHT edge: dragging LEFT exposes it.
      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-65, 0)]);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(-_extent, 0.5));
      final Rect rowRect = tester.getRect(find.byType(OrionSwipeActionRow));
      final Rect pinRect = tester.getRect(find.text('Pin'));
      expect(pinRect.center.dx, greaterThan(rowRect.center.dx));

      // Tap Pin to invoke and close.
      await tester.tap(find.text('Pin'));
      await tester.pumpAndSettle();
      expect(pressed, <String>['Pin']);
      expect(_offset(tester), closeTo(0, 0.5));

      // In RTL, trailing sits on the LEFT edge: dragging RIGHT exposes it.
      await _drag(tester, <Offset>[const Offset(25, 0), const Offset(130, 0)]);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(2 * _extent, 0.5));
      final Rect deleteRect = tester.getRect(find.text('Delete'));
      expect(deleteRect.center.dx, lessThan(rowRect.center.dx));
    });

    testWidgets(
      'auto-selects high-contrast foreground for custom backgrounds',
      (tester) async {
        await _pumpRow(
          tester,
          trailing: const <OrionSwipeAction>[
            OrionSwipeAction(
              icon: Icon(Icons.archive_outlined),
              label: 'DarkBg',
              background: Color(0xFF171717),
              onPressed: _noop,
            ),
            OrionSwipeAction(
              icon: Icon(Icons.flag_outlined),
              label: 'LightBg',
              background: Color(0xFFF5F5F5),
              onPressed: _noop,
            ),
          ],
        );

        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-130, 0),
        ]);
        await tester.pumpAndSettle();

        final Text darkText = tester.widget<Text>(find.text('DarkBg'));
        final Text lightText = tester.widget<Text>(find.text('LightBg'));
        expect(darkText.style?.color, Colors.white);
        expect(lightText.style?.color, const Color(0xFF0A0A0A));
      },
    );

    testWidgets(
      'blocks rapid double-taps while closing and supports autoClose: false',
      (tester) async {
        final List<String> pressed = <String>[];
        await _pumpRow(
          tester,
          trailing: _actions(<String>['Delete'], onPressed: pressed.add),
        );

        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-65, 0),
        ]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Delete'));
        await tester.pump(const Duration(milliseconds: 16));
        await tester.tap(find.text('Delete'), warnIfMissed: false);
        await tester.pumpAndSettle();
        expect(pressed, <String>['Delete']);

        // autoClose: false keeps the row open across multiple taps.
        pressed.clear();
        await _pumpRow(
          tester,
          trailing: _actions(
            <String>['Mute'],
            onPressed: pressed.add,
            autoClose: false,
          ),
        );
        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-65, 0),
        ]);
        await tester.pumpAndSettle();

        await tester.tap(find.text('Mute'));
        await tester.pumpAndSettle();
        expect(_offset(tester), closeTo(-_extent, 0.5));
        await tester.tap(find.text('Mute'));
        await tester.pumpAndSettle();
        expect(pressed, <String>['Mute', 'Mute']);
      },
    );

    testWidgets('supports OrionSwipeController open/close and state sync', (
      tester,
    ) async {
      final OrionSwipeController controller = OrionSwipeController();
      addTearDown(controller.dispose);
      final List<OrionSwipeSide?> sides = <OrionSwipeSide?>[];
      int notifications = 0;
      controller.addListener(() => notifications++);

      await _pumpRow(
        tester,
        controller: controller,
        leading: _actions(<String>['Pin']),
        trailing: _actions(<String>['Delete']),
        onSideChanged: sides.add,
      );

      expect(controller.isAttached, isTrue);
      expect(controller.isOpen, isFalse);

      controller.openTrailing();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isTrue);
      expect(controller.openSide, OrionSwipeSide.trailing);
      expect(_offset(tester), closeTo(-_extent, 0.5));

      controller.openLeading();
      await tester.pumpAndSettle();
      expect(controller.openSide, OrionSwipeSide.leading);
      expect(_offset(tester), closeTo(_extent, 0.5));

      controller.close();
      await tester.pumpAndSettle();
      expect(controller.isOpen, isFalse);
      expect(controller.openSide, isNull);
      expect(_offset(tester), closeTo(0, 0.5));
      expect(sides, <OrionSwipeSide?>[
        OrionSwipeSide.trailing,
        OrionSwipeSide.leading,
        null,
      ]);
      expect(notifications, 3);
    });

    testWidgets(
      'OrionSwipeScope closes on sibling tap without eating tap, and closes on list scroll',
      (tester) async {
        int secondRowTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: SizedBox(
                width: 390,
                child: OrionSwipeScope(
                  child: ListView(
                    children: <Widget>[
                      OrionSwipeActionRow(
                        trailing: _actions(<String>['Delete']),
                        child: const SizedBox(
                          key: _childKey,
                          height: 60,
                          child: Text('First'),
                        ),
                      ),
                      OrionSwipeActionRow(
                        trailing: _actions(<String>['Delete']),
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => secondRowTaps++,
                          child: const SizedBox(
                            height: 60,
                            child: Text('Second'),
                          ),
                        ),
                      ),
                      for (int i = 0; i < 20; i++)
                        SizedBox(height: 60, child: Text('Spacer $i')),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );

        // Open first row.
        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-65, 0),
        ], rowIndex: 0);
        await tester.pumpAndSettle();
        expect(_offset(tester, index: 0), closeTo(-_extent, 0.5));

        // Tapping interactive second row closes first row AND fires second row tap!
        await tester.tap(find.text('Second'));
        await tester.pumpAndSettle();
        expect(secondRowTaps, 1);
        expect(_offset(tester, index: 0), closeTo(0, 0.5));

        // Open first row again, then scroll the ListView slightly (keeping row 0
        // in the viewport) -> closes immediately!
        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-65, 0),
        ], rowIndex: 0);
        await tester.pumpAndSettle();
        expect(_offset(tester, index: 0), closeTo(-_extent, 0.5));

        await tester.drag(find.byType(ListView), const Offset(0, -30));
        await tester.pumpAndSettle();
        expect(_offset(tester, index: 0), closeTo(0, 0.5));
      },
    );

    testWidgets(
      'supports all motion modes, floating pill gaps, hover, reduced motion, and zero content rebuilds',
      (tester) async {
        for (final OrionSwipeMotion motion in OrionSwipeMotion.values) {
          int builds = 0;
          await _pumpRow(
            tester,
            style: OrionSwipeStyle(
              motion: motion,
              borderRadius: BorderRadius.circular(14),
              actionGap: 8,
              actionRadius: BorderRadius.circular(12),
            ),
            child: Builder(
              key: _childKey,
              builder: (BuildContext context) {
                builds++;
                return const SizedBox(height: 56, child: Text('Card'));
              },
            ),
          );
          expect(builds, 1);

          final TestGesture g = await _drag(tester, <Offset>[
            const Offset(-12, 0),
            const Offset(-90, 0),
          ], release: false);
          expect(tester.takeException(), isNull);
          expect(builds, 1);

          await g.up();
          await tester.pumpAndSettle();
          expect(builds, 1);
          expect(_offset(tester), closeTo(-(2 * _extent + 2 * 8), 0.5));
        }

        // Pointer hover over revealed action works cleanly.
        final TestGesture mouse = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await mouse.addPointer(location: Offset.zero);
        addTearDown(mouse.removePointer);
        await mouse.moveTo(tester.getCenter(find.text('Delete')));
        await tester.pump();
        expect(tester.takeException(), isNull);

        // Reduced motion lands in a single frame.
        await _pumpRow(tester, disableAnimations: true);
        await _drag(tester, <Offset>[
          const Offset(-25, 0),
          const Offset(-70, 0),
        ]);
        await tester.pump();
        expect(_offset(tester), closeTo(_twoTrailing, 0.5));
      },
    );

    testWidgets('tapping open content closes it without activating child tap', (
      tester,
    ) async {
      int childTaps = 0;
      await _pumpRow(
        tester,
        trailing: _actions(<String>['Delete']),
        child: GestureDetector(
          key: _childKey,
          behavior: HitTestBehavior.opaque,
          onTap: () => childTaps++,
          child: const SizedBox(height: 56, child: Text('Row')),
        ),
      );

      await tester.tap(find.text('Row'));
      await tester.pump();
      expect(childTaps, 1);

      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-65, 0)]);
      await tester.pumpAndSettle();
      expect(_offset(tester), closeTo(-_extent, 0.5));

      // Tap the shifted content's left side: closes row without triggering childTaps.
      final Rect rowRect = tester.getRect(find.byType(OrionSwipeActionRow));
      await tester.tapAt(Offset(rowRect.left + 40, rowRect.center.dy));
      await tester.pumpAndSettle();
      expect(childTaps, 1);
      expect(_offset(tester), closeTo(0, 0.5));
    });

    testWidgets('exposes custom semantics actions and disables cleanly', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> invoked = <String>[];
      await _pumpRow(
        tester,
        trailing: _actions(
          <String>['Star', 'Delete'],
          disabled: <String>['Star'],
          onPressed: invoked.add,
        ),
        leading: _actions(<String>['Pin'], onPressed: invoked.add),
      );

      final SemanticsData data = tester
          .getSemantics(find.byType(OrionSwipeActionRow))
          .getSemanticsData();
      // Pin and Delete are enabled; Star is disabled.
      expect(data.customSemanticsActionIds?.length, 2);

      // Disabled row ignores drag and exposes zero actions.
      await _pumpRow(tester, enabled: false);
      await _drag(tester, <Offset>[const Offset(-25, 0), const Offset(-90, 0)]);
      await tester.pumpAndSettle();
      expect(_offset(tester), 0);
      final SemanticsData disabledData = tester
          .getSemantics(find.byType(OrionSwipeActionRow))
          .getSemanticsData();
      expect(disabledData.customSemanticsActionIds, anyOf(isNull, isEmpty));
      handle.dispose();
    });
  });

  group('OrionSwipeStyle & OrionSwipeTheme', () {
    test('lerp interpolates style and theme fields smoothly', () {
      final OrionSwipeStyle a = OrionSwipeStyle(
        actionExtent: 64,
        actionGap: 0,
        iconSize: 18,
        fullSwipeThreshold: 0.5,
        borderRadius: BorderRadius.circular(0),
        actionRadius: BorderRadius.circular(0),
      );
      final OrionSwipeStyle b = OrionSwipeStyle(
        actionExtent: 84,
        actionGap: 12,
        iconSize: 24,
        fullSwipeThreshold: 0.7,
        borderRadius: BorderRadius.circular(16),
        actionRadius: BorderRadius.circular(12),
      );

      final OrionSwipeTheme lerped = OrionSwipeTheme(
        defaultStyle: a,
      ).lerp(OrionSwipeTheme(defaultStyle: b), 0.5);
      final OrionSwipeStyle mid = lerped.defaultStyle!;

      expect(mid.actionExtent, closeTo(74, 0.001));
      expect(mid.actionGap, closeTo(6, 0.001));
      expect(mid.iconSize, closeTo(21, 0.001));
      expect(mid.fullSwipeThreshold, closeTo(0.6, 0.001));
      expect(mid.borderRadius, BorderRadius.circular(8));
      expect(mid.actionRadius, BorderRadius.circular(6));
    });
  });
}
