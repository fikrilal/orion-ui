import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

const List<OrionTab<String>> _tabs = <OrionTab<String>>[
  OrionTab(value: 'a', label: 'A'),
  OrionTab(value: 'b', label: 'B'),
  OrionTab(value: 'c', label: 'C'),
];

/// The documented usage: `value` + `onChanged` with the parent owning the page, bound to
/// a [PageController]. The echo the parent feeds back is what used to seize a swipe.
class _Host extends StatefulWidget {
  const _Host({required this.pageController, this.reduce = false});

  final PageController pageController;
  final bool reduce;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  String _value = 'a';
  final List<String> changes = <String>[];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: OrionTheme.light(),
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: widget.reduce),
        child: Scaffold(
          body: Column(
            children: <Widget>[
              OrionTabs<String>(
                tabs: _tabs,
                value: _value,
                pageController: widget.pageController,
                onChanged: (String next) {
                  changes.add(next);
                  setState(() => _value = next);
                },
              ),
              Expanded(
                child: PageView(
                  controller: widget.pageController,
                  children: const <Widget>[
                    Center(child: Text('page a')),
                    Center(child: Text('page b')),
                    Center(child: Text('page c')),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

List<String> _haptics(WidgetTester tester) {
  final List<String> log = <String>[];
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
    SystemChannels.platform,
    (MethodCall call) async {
      if (call.method == 'HapticFeedback.vibrate') {
        log.add(call.arguments.toString());
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
  return log;
}

void main() {
  testWidgets('a swipe can be dragged back past halfway', (tester) async {
    final PageController pageController = PageController();
    addTearDown(pageController.dispose);
    await tester.pumpWidget(_Host(pageController: pageController));
    await tester.pumpAndSettle();

    final TestGesture gesture = await tester.startGesture(
      tester.getCenter(find.text('page a')),
    );
    await gesture.moveBy(const Offset(-500, 0)); // well past half a page
    await tester.pump();

    // Hold still: the value echo must not start an animation that drives the page.
    final double held = pageController.page!;
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      pageController.page,
      closeTo(held, 0.02),
      reason: 'the echo of a half-swipe must not take the page from the finger',
    );

    await gesture.moveBy(const Offset(420, 0)); // and drag back
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
    expect(pageController.page, closeTo(0, 0.01));
  });

  testWidgets('reduced motion jumps a bound pager in one frame', (
    tester,
  ) async {
    final PageController pageController = PageController();
    addTearDown(pageController.dispose);
    await tester.pumpWidget(
      _Host(pageController: pageController, reduce: true),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('B'));
    await tester.pump();
    expect(pageController.page, closeTo(1, 0.01));
  });

  testWidgets('an empty strip renders instead of throwing', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: OrionTabs<String>(
                tabs: const <OrionTab<String>>[],
                onChanged: (String _) {},
              ),
            ),
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('equal distribution gives every tab the same width', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: OrionTabs<String>(
                tabs: _tabs,
                value: 'a',
                distribution: OrionTabsDistribution.equal,
                onChanged: (String _) {},
              ),
            ),
          ),
        ),
      ),
    );

    // The outer box is already 300 wide, so only per-tab measurements prove the split:
    // intrinsic tabs differ in width by their labels, equal tabs do not.
    final List<double> widths = <String>['A', 'B', 'C']
        .map(
          (String label) =>
              tester.getSize(find.widgetWithText(OrionPressable, label)).width,
        )
        .toList();
    expect(widths.first, greaterThan(0));
    for (final double width in widths) {
      expect(width, closeTo(widths.first, 0.01));
    }
  });

  testWidgets('the indicator keeps its velocity across a retarget', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              child: OrionTabs<String>(
                tabs: _tabs,
                value: 'a',
                onChanged: (String _) {},
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('C'));
    for (int frame = 0; frame < 3; frame++) {
      await tester.pump(const Duration(milliseconds: 16));
    }

    final OrionTabsState<String> state = tester.state<OrionTabsState<String>>(
      find.byType(OrionTabs<String>),
    );
    final double inFlight = state.indicatorDriver.value;
    expect(inFlight, greaterThan(0));
    expect(inFlight, lessThan(2));
    expect(
      state.indicatorDriver.velocity,
      isNot(0),
      reason: 'a retarget that teleported would lose the velocity',
    );
    await tester.pumpAndSettle();
    expect(state.indicatorDriver.value, closeTo(2, 0.01));
  });

  testWidgets('a tap reports once, and the pager animation does not echo it', (
    tester,
  ) async {
    final List<String> changes = <String>[];
    final PageController pageController = PageController();
    addTearDown(pageController.dispose);
    String value = 'a';

    await tester.pumpWidget(
      MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  OrionTabs<String>(
                    tabs: _tabs,
                    value: value,
                    pageController: pageController,
                    onChanged: (String next) {
                      changes.add(next);
                      setState(() => value = next);
                    },
                  ),
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      children: const <Widget>[
                        Center(child: Text('page a')),
                        Center(child: Text('page b')),
                        Center(child: Text('page c')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('C'));
    await tester.pumpAndSettle();

    expect(changes, <String>[
      'c',
    ], reason: 'the page the tap animates to is not a second user event');
  });

  testWidgets('a user drag still reports the page it lands on', (tester) async {
    final List<String> changes = <String>[];
    final PageController pageController = PageController();
    addTearDown(pageController.dispose);
    String value = 'a';

    await tester.pumpWidget(
      MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Column(
                children: <Widget>[
                  OrionTabs<String>(
                    tabs: _tabs,
                    value: value,
                    pageController: pageController,
                    onChanged: (String next) {
                      changes.add(next);
                      setState(() => value = next);
                    },
                  ),
                  Expanded(
                    child: PageView(
                      controller: pageController,
                      children: const <Widget>[
                        Center(child: Text('page a')),
                        Center(child: Text('page b')),
                        Center(child: Text('page c')),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('page a'), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(
      changes,
      isNotEmpty,
      reason: 'silencing the tap animation must not silence the finger',
    );
    expect(changes.last, 'b');
    expect(value, 'b');
  });

  testWidgets('a shrunk list cannot strand the selection', (tester) async {
    const List<OrionTab<String>> five = <OrionTab<String>>[
      OrionTab(value: 'a', label: 'A'),
      OrionTab(value: 'b', label: 'B'),
      OrionTab(value: 'c', label: 'C'),
      OrionTab(value: 'd', label: 'D'),
      OrionTab(value: 'e', label: 'E'),
    ];
    final OrionTabsController<String> controller =
        OrionTabsController<String>();
    addTearDown(controller.dispose);

    Widget build(List<OrionTab<String>> tabs) {
      return MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 300,
              height: 64,
              child: OrionTabs<String>(
                tabs: tabs,
                value: 'e',
                controller: controller,
                onChanged: (String _) {},
              ),
            ),
          ),
        ),
      );
    }

    await tester.pumpWidget(build(five));
    await tester.pumpAndSettle();
    expect(controller.index, 4);

    await tester.pumpWidget(
      build(const <OrionTab<String>>[
        OrionTab(value: 'a', label: 'A'),
        OrionTab(value: 'b', label: 'B'),
      ]),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(controller.index, lessThan(2));
  });

  testWidgets('a scroll gesture cancels the press silently', (tester) async {
    final List<String> haptics = _haptics(tester);
    final List<String> changes = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          // A non-lazy scroll view: the strip must stay mounted for the assertion after
          // the scroll, and a ListView would dispose it once it left the viewport.
          body: SingleChildScrollView(
            child: Column(
              children: <Widget>[
                SizedBox(
                  width: 300,
                  height: 64,
                  child: OrionTabs<String>(
                    tabs: _tabs,
                    value: 'a',
                    onChanged: changes.add,
                  ),
                ),
                const SizedBox(height: 1200),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(find.text('B'), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(changes, isEmpty, reason: 'a scroll is not a tab change');
    expect(haptics, isEmpty);
    expect(
      tester
          .state<OrionPressableState>(find.byType(OrionPressable).first)
          .driver
          .value,
      closeTo(1, 0.001),
      reason: 'the press must spring back when the arena goes to the scroll',
    );
  });
}
