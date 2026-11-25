import 'dart:math' as math;
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

const String _headerText = 'Details';
const String _panelText = 'Panel body';

Future<void> _pumpAccordion(
  WidgetTester tester, {
  required bool expanded,
  required ValueChanged<bool>? onExpandedChanged,
  bool disableAnimations = false,
  bool autofocus = false,
  String? semanticLabel,
  Widget? trailing,
  Widget? header,
  Widget? content,
  OrionAccordionStyle? style,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: Align(
          alignment: Alignment.topLeft,
          child: MediaQuery(
            data: MediaQueryData(disableAnimations: disableAnimations),
            child: OrionAccordion(
              header: header ?? const Text(_headerText),
              expanded: expanded,
              onExpandedChanged: onExpandedChanged,
              trailing: trailing,
              semanticLabel: semanticLabel,
              autofocus: autofocus,
              style: style,
              child: content ?? const Text(_panelText),
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

Finder _panelBody() => find.text(_panelText);

/// The panel's clip box. It is the nearest [ClipRect] above the content, and its
/// height is exactly `content.height * reveal`, so it reports the animated
/// extent.
Finder _panelClip() =>
    find.ancestor(of: _panelBody(), matching: find.byType(ClipRect)).first;

/// The travel builder. [OrionPressable] and the chevron each wrap their own, so
/// the content's nearest ancestor is the panel's.
Finder _panelBuilder() => find
    .ancestor(of: _panelBody(), matching: find.byType(AnimatedBuilder))
    .first;

Finder _chevron() => find.byIcon(Icons.expand_more);

Finder _chevronBuilder() =>
    find.ancestor(of: _chevron(), matching: find.byType(AnimatedBuilder)).first;

double _extent(WidgetTester tester) => tester.getSize(_panelClip()).height;

/// The content's own size including the default content padding, which the clip
/// never changes: it is laid out at its natural height whether the panel is
/// open, closed, or mid-travel.
double _naturalHeight(WidgetTester tester) => tester
    .getSize(
      find.ancestor(of: _panelBody(), matching: find.byType(Padding)).first,
    )
    .height;

/// Rotation of the default chevron. Positive is clockwise, matching
/// `Transform.rotate` around the two states.
double _chevronAngle(WidgetTester tester) {
  final Transform rotate = tester.widget<Transform>(
    find.ancestor(of: _chevron(), matching: find.byType(Transform)).first,
  );
  final Matrix4 matrix = rotate.transform;
  return math.atan2(matrix.entry(1, 0), matrix.entry(0, 0));
}

/// Scale of the press feedback, which is the outermost transform in the row.
double _pressScale(WidgetTester tester) => tester
    .widget<Transform>(
      find
          .descendant(
            of: find.byType(OrionAccordion),
            matching: find.byType(Transform),
          )
          .first,
    )
    .transform
    .entry(0, 0);

BoxDecoration _headerDecoration(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: find.byType(OrionAccordion),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return box.decoration as BoxDecoration;
}

/// The single announced node carrying [label].
///
/// [WidgetTester.getSemantics] resolves to the outer merge boundary, and the
/// widget-level `find.bySemanticsLabel` reads a render object's own node, which
/// an excluded subtree keeps as a stale object. The semantics finders search the
/// tree the platform actually sees, which answers both "what is announced" and
/// "is it still announced".
SemanticsNode _semanticsNode(WidgetTester tester, String label) {
  final Iterable<SemanticsNode> matches = find.semantics
      .byLabel(label)
      .evaluate();
  expect(matches, hasLength(1));
  return matches.single;
}

Set<String> _semanticsLabels(WidgetTester tester) => find.semantics
    .byPredicate((SemanticsNode node) => node.label.isNotEmpty)
    .evaluate()
    .map((SemanticsNode node) => node.label)
    .toSet();

/// Counts how many times the panel content is built. It is created once per test
/// and handed to the accordion as the same instance, so any rebuild is a real
/// rebuild of the subtree rather than a new widget.
class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild, required this.child});

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}

void main() {
  group('OrionAccordion', () {
    testWidgets('rests collapsed with the content laid out', (tester) async {
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});

      expect(_extent(tester), 0);
      expect(_chevronAngle(tester), 0);
      // The clip is what hides the panel: the Align still lays the content out
      // at its full natural height inside a zero-height clip box.
      expect(
        find.ancestor(of: _panelBody(), matching: find.byType(ClipRect)),
        findsOneWidget,
      );
      expect(_naturalHeight(tester), greaterThan(0));
    });

    testWidgets('reveals to the full content height when expanded', (
      tester,
    ) async {
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      final double natural = _naturalHeight(tester);

      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      await tester.pumpAndSettle();

      expect(_extent(tester), closeTo(natural, 0.01));
      expect(_chevronAngle(tester), closeTo(math.pi, 0.001));
      expect(
        tester.getSize(find.byType(OrionAccordion)).height,
        closeTo(OrionSizing.minHitTarget + natural, 0.01),
      );
    });

    testWidgets('grows over more than one frame', (tester) async {
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      final double natural = _naturalHeight(tester);

      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      // Frame 0: the reveal has not moved yet.
      expect(_extent(tester), 0);

      await tester.pump(const Duration(milliseconds: 16));
      final double mid = _extent(tester);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(natural));
      expect(_chevronAngle(tester), greaterThan(0));
      expect(_chevronAngle(tester), lessThan(math.pi));

      await tester.pumpAndSettle();
      expect(_extent(tester), closeTo(natural, 0.01));
    });

    testWidgets('keeps the extent and the chevron on one sample', (
      tester,
    ) async {
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      final double natural = _naturalHeight(tester);

      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      final List<double> fractions = <double>[];
      final List<double> angles = <double>[];
      for (var frame = 0; frame < 40; frame++) {
        final double fraction = _extent(tester) / natural;
        // The tail of the travel is excluded: past the target the rotation wraps
        // past pi, where atan2 reports the negative equivalent.
        if (fraction > 0 && fraction < 1) {
          fractions.add(fraction);
          angles.add(_chevronAngle(tester));
        }
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Both really travelled, so the equality below is not a rest state.
      expect(fractions.length, greaterThanOrEqualTo(4));
      for (var frame = 0; frame < fractions.length; frame++) {
        expect(angles[frame] / math.pi, closeTo(fractions[frame], 1e-9));
      }

      await tester.pumpAndSettle();
    });

    testWidgets('collapses back to a zero extent', (tester) async {
      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      await tester.pumpAndSettle();
      expect(_extent(tester), greaterThan(0));

      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      await tester.pumpAndSettle();

      expect(_extent(tester), 0);
      expect(_chevronAngle(tester), closeTo(0, 0.001));
      expect(_naturalHeight(tester), greaterThan(0));
    });

    testWidgets('expands cleanly without overshooting past content height', (
      tester,
    ) async {
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      final double natural = _naturalHeight(tester);

      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      final List<double> extents = <double>[];
      for (var frame = 0; frame < 60; frame++) {
        extents.add(_extent(tester) / natural);
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Critically damped + clamped expand spring reaches content height cleanly
      // without pushing sibling rows below past their resting position.
      final double peak = extents.reduce(math.max);
      expect(peak, lessThanOrEqualTo(1.001));
      expect(peak, closeTo(1.0, 0.001));

      await tester.pumpAndSettle();
      expect(_extent(tester), closeTo(natural, 0.01));
    });

    testWidgets('reports the opposite value on tap', (tester) async {
      bool? reported;
      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (bool value) => reported = value,
      );

      await tester.tap(find.text(_headerText));
      expect(reported, isTrue);

      reported = null;
      await _pumpAccordion(
        tester,
        expanded: true,
        onExpandedChanged: (bool value) => reported = value,
      );

      await tester.tap(find.text(_headerText));
      expect(reported, isFalse);
    });

    testWidgets('ignores taps, marks itself disabled, and dims', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      final List<String> haptics = _captureHaptics(tester);
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: null);

      // A disabled row does not acknowledge the touch at all: no compression,
      // no haptic, no report.
      final TestGesture press = await tester.startGesture(
        tester.getCenter(find.text(_headerText)),
      );
      // The first tick of a new ticker has zero elapsed time, so the spring only
      // starts travelling on the tick after it.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 32));
      expect(_pressScale(tester), 1);
      expect(haptics, isEmpty);
      await press.up();
      await tester.pump();

      await tester.tap(find.text(_headerText));

      final SemanticsNode node = _semanticsNode(tester, _headerText);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(
        tester
            .widget<Opacity>(
              find
                  .descendant(
                    of: find.byType(OrionPressable),
                    matching: find.byType(Opacity),
                  )
                  .first,
            )
            .opacity,
        0.38,
      );
      handle.dispose();
    });

    testWidgets('toggles from the keyboard', (tester) async {
      bool? reported;
      await _pumpAccordion(
        tester,
        expanded: false,
        autofocus: true,
        onExpandedChanged: (bool value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(reported, isTrue);

      reported = null;
      await _pumpAccordion(
        tester,
        expanded: true,
        autofocus: true,
        onExpandedChanged: (bool value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(reported, isFalse);
    });

    testWidgets('paints a focus ring when focused', (tester) async {
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(() {
        FocusManager.instance.highlightStrategy =
            FocusHighlightStrategy.automatic;
      });

      await _pumpAccordion(
        tester,
        expanded: false,
        autofocus: true,
        onExpandedChanged: (_) {},
      );
      await tester.pumpAndSettle();

      expect(_headerDecoration(tester).border, isNotNull);
    });

    testWidgets('toggles from the empty band above a short header', (
      tester,
    ) async {
      bool? reported;
      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (bool value) => reported = value,
      );

      final Rect target = tester.getRect(find.byType(OrionPressable));
      final Rect visual = tester.getRect(find.text(_headerText));
      // The visual is shorter than the target, so the band the tap lands in
      // belongs to the hit area alone.
      expect(visual.height, lessThan(OrionSizing.minHitTarget));
      final Offset band = Offset(target.center.dx, target.top + 1);
      expect(band.dy, lessThan(visual.top));

      await tester.tapAt(band);
      expect(reported, isTrue);
    });

    testWidgets('keeps an exact 44 pt target above a short header', (
      tester,
    ) async {
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});

      final Size target = tester.getSize(find.byType(OrionPressable));
      // Exact, not a floor: a hit area that grows to fill a loose bounded parent
      // is just as wrong as one that is too small.
      expect(target.height, OrionSizing.minHitTarget);
      expect(target.width, greaterThanOrEqualTo(OrionSizing.minHitTarget));
      expect(
        tester.getSize(find.text(_headerText)).height,
        lessThan(OrionSizing.minHitTarget),
      );
    });

    testWidgets('lets a tall header keep its own height', (tester) async {
      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        header: const SizedBox(height: 80, child: Text(_headerText)),
      );

      expect(
        tester.getSize(find.byType(OrionPressable)).height,
        80 + OrionSpacing.space8 * 2,
      );
    });

    testWidgets('does not stretch inside a loose bounded box', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                height: 200,
                child: Center(
                  child: OrionAccordion(
                    header: const Text(_headerText),
                    expanded: false,
                    onExpandedChanged: (_) {},
                    child: const Text(_panelText),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(OrionAccordion)).height,
        OrionSizing.minHitTarget,
      );
      expect(
        tester.getSize(find.byType(OrionPressable)).height,
        OrionSizing.minHitTarget,
      );
    });

    testWidgets('emits one haptic on tap and none from the keyboard', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);

      bool? reported;
      await _pumpAccordion(
        tester,
        expanded: false,
        autofocus: true,
        onExpandedChanged: (bool value) => reported = value,
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text(_headerText));
      await tester.pump();
      expect(haptics, <String>['HapticFeedbackType.selectionClick']);
      expect(reported, isTrue);

      reported = null;
      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      expect(haptics, hasLength(1));
      expect(reported, isTrue);
    });

    testWidgets('a scroll drag never toggles and stays silent', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      final ScrollController controller = ScrollController();
      addTearDown(controller.dispose);

      int reported = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView(
              controller: controller,
              children: <Widget>[
                for (var index = 0; index < 20; index++)
                  OrionAccordion(
                    header: Text('Row $index'),
                    expanded: false,
                    onExpandedChanged: (_) => reported++,
                    child: Text('Body $index'),
                  ),
              ],
            ),
          ),
        ),
      );

      await tester.drag(find.text('Row 0'), const Offset(0, -300));
      await tester.pumpAndSettle();

      // The list really scrolled, so the silence below is not a missed drag.
      expect(controller.offset, greaterThan(0));
      expect(reported, 0);
      expect(haptics, isEmpty);
    });

    testWidgets('survives being scrolled off-screen while held', (
      tester,
    ) async {
      int reported = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: ListView.builder(
              itemExtent: OrionSizing.minHitTarget,
              itemCount: 30,
              itemBuilder: (BuildContext context, int index) => OrionAccordion(
                header: Text('Row $index'),
                expanded: false,
                onExpandedChanged: (_) => reported++,
                child: Text('Body $index'),
              ),
            ),
          ),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Row 0')),
      );
      await tester.pump(const Duration(milliseconds: 16));

      await gesture.moveBy(const Offset(0, -600));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(reported, 0);
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      await _pumpAccordion(
        tester,
        expanded: false,
        disableAnimations: true,
        onExpandedChanged: (_) {},
      );
      expect(_extent(tester), 0);

      await _pumpAccordion(
        tester,
        expanded: true,
        disableAnimations: true,
        onExpandedChanged: (_) {},
      );
      await tester.pump();

      expect(_extent(tester), closeTo(_naturalHeight(tester), 0.01));
      expect(_chevronAngle(tester), closeTo(math.pi, 0.001));
    });

    testWidgets('settles at once when motion is turned off mid-flight', (
      tester,
    ) async {
      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      final double natural = _naturalHeight(tester);

      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));
      expect(_extent(tester), lessThan(natural));

      await _pumpAccordion(
        tester,
        expanded: true,
        disableAnimations: true,
        onExpandedChanged: (_) {},
      );
      await tester.pump();

      expect(_extent(tester), closeTo(natural, 0.01));
    });

    testWidgets('does not rebuild the panel or the chevron on ticks', (
      tester,
    ) async {
      int builds = 0;
      final Widget content = _BuildCounter(
        onBuild: () => builds++,
        child: const Text(_panelText),
      );

      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        content: content,
      );
      expect(builds, 1);

      await _pumpAccordion(
        tester,
        expanded: true,
        onExpandedChanged: (_) {},
        content: content,
      );
      final Widget panel = tester
          .widget<AnimatedBuilder>(_panelBuilder())
          .child!;
      final Widget chevron = tester
          .widget<AnimatedBuilder>(_chevronBuilder())
          .child!;
      double previous = _extent(tester);

      for (var frame = 0; frame < 8; frame++) {
        await tester.pump(const Duration(milliseconds: 16));

        // The ticker really ran, so the identity checks are not vacuous.
        final double current = _extent(tester);
        expect(current, greaterThan(previous));
        previous = current;
        expect(
          identical(
            tester.widget<AnimatedBuilder>(_panelBuilder()).child,
            panel,
          ),
          isTrue,
        );
        expect(
          identical(
            tester.widget<AnimatedBuilder>(_chevronBuilder()).child,
            chevron,
          ),
          isTrue,
        );
      }

      expect(builds, 1);
      await tester.pumpAndSettle();
    });

    testWidgets('exposes the expanded state and the spoken name', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      SemanticsNode node = _semanticsNode(tester, _headerText);
      expect(node.flagsCollection.isExpanded, Tristate.isTrue);
      expect(node.flagsCollection.isButton, isTrue);

      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      node = _semanticsNode(tester, _headerText);
      expect(node.flagsCollection.isExpanded, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('exposes a spoken name override', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpAccordion(
        tester,
        expanded: false,
        semanticLabel: 'Delivery details',
        onExpandedChanged: (_) {},
      );

      final SemanticsNode node = _semanticsNode(tester, 'Delivery details');
      expect(node.flagsCollection.isExpanded, Tristate.isFalse);
      // The visible text is replaced, not announced twice.
      expect(_semanticsLabels(tester), isNot(contains(_headerText)));
      handle.dispose();
    });

    testWidgets('drops the collapsed panel from the semantics tree', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();

      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      await tester.pumpAndSettle();
      expect(_semanticsLabels(tester), contains(_panelText));

      await _pumpAccordion(tester, expanded: false, onExpandedChanged: (_) {});
      // Mid-collapse the panel still has a visible extent, but the parent has
      // already said it is closed, so it stops being announced at once rather
      // than when the last pixel disappears.
      await tester.pump(const Duration(milliseconds: 48));
      expect(_extent(tester), greaterThan(0));
      expect(_semanticsLabels(tester), isNot(contains(_panelText)));

      await tester.pumpAndSettle();
      expect(_semanticsLabels(tester), isNot(contains(_panelText)));
      handle.dispose();
    });

    testWidgets('drops the collapsed panel from the focus order', (
      tester,
    ) async {
      final FocusNode panelFocus = FocusNode();
      addTearDown(panelFocus.dispose);
      Widget content() => TextButton(
        onPressed: () {},
        focusNode: panelFocus,
        child: const Text(_panelText),
      );

      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        content: content(),
      );
      panelFocus.requestFocus();
      await tester.pump();
      expect(panelFocus.hasFocus, isFalse);

      await _pumpAccordion(
        tester,
        expanded: true,
        onExpandedChanged: (_) {},
        content: content(),
      );
      await tester.pumpAndSettle();
      panelFocus.requestFocus();
      await tester.pump();
      expect(panelFocus.hasFocus, isTrue);
    });

    testWidgets('blocks taps on collapsed content', (tester) async {
      bool tapped = false;
      final Widget content = GestureDetector(
        onTap: () => tapped = true,
        child: const Text(_panelText),
      );

      await _pumpAccordion(
        tester,
        expanded: true,
        onExpandedChanged: (_) {},
        content: content,
      );
      await tester.pumpAndSettle();
      final Offset body = tester.getCenter(_panelBody());

      // The target really is tappable while the panel is open, so the block
      // below is the collapse and not a dead gesture.
      await tester.tapAt(body);
      expect(tapped, isTrue);
      tapped = false;

      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        content: content,
      );
      await tester.pumpAndSettle();
      expect(_extent(tester), 0);

      await tester.tapAt(body);
      await tester.pump();
      expect(tapped, isFalse);
    });

    testWidgets('leaves a caller-supplied trailing slot unrotated', (
      tester,
    ) async {
      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        trailing: const Icon(Icons.add),
      );
      await _pumpAccordion(
        tester,
        expanded: true,
        onExpandedChanged: (_) {},
        trailing: const Icon(Icons.add),
      );
      await tester.pumpAndSettle();

      expect(_chevron(), findsNothing);
      expect(find.byIcon(Icons.add), findsOneWidget);
      // The supplied slot sits under the press scale and nothing else. The
      // reveal rotation is part of the chevron this component owns, so a
      // replaced slot must not gain one.
      expect(
        find.ancestor(
          of: find.byIcon(Icons.add),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionAccordionTheme(
            defaultStyle: OrionAccordionStyle.from(
              headerPadding: const EdgeInsets.all(24),
              iconColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        theme: themed,
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.expand_more)).color,
        const Color(0xFF00AA00),
      );
      final Rect row = tester.getRect(find.byType(OrionAccordion));
      final Rect label = tester.getRect(find.text(_headerText));
      expect(label.left - row.left, 24);

      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        theme: themed,
        style: OrionAccordionStyle.from(iconColor: const Color(0xFFAA0000)),
      );
      expect(
        tester.widget<Icon>(find.byIcon(Icons.expand_more)).color,
        const Color(0xFFAA0000),
      );
      final Rect overridden = tester.getRect(find.text(_headerText));
      expect(
        overridden.left - row.left,
        24,
        reason: 'the instance style only overrides what it names',
      );
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

      await _pumpAccordion(
        tester,
        expanded: false,
        autofocus: true,
        onExpandedChanged: (_) {},
        style: OrionAccordionStyle.from(
          focusRingColor: const Color(0xFF00AA00),
          focusRingWidth: 4,
        ),
      );
      await tester.pumpAndSettle();

      final DecoratedBox face = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(OrionAccordion),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      final Border border =
          (face.decoration as BoxDecoration).border! as Border;
      expect(border.top.color, const Color(0xFF00AA00));
      expect(border.top.width, 4);
    });

    testWidgets('a retuned expand spring reaches the reveal', (tester) async {
      const OrionSpringSpec bouncySpring = OrionSpringSpec(
        stiffness: 380.0,
        dampingRatio: 0.36,
      );
      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        style: OrionAccordionStyle.from(expandSpring: bouncySpring),
      );
      await _pumpAccordion(
        tester,
        expanded: true,
        onExpandedChanged: (_) {},
        style: OrionAccordionStyle.from(expandSpring: bouncySpring),
      );
      await tester.pump(const Duration(milliseconds: 16));

      // An underdamped spring overshoots a full travel hard, so the panel's clip
      // grows past the content for at least one frame.
      double peak = 0;
      for (var frame = 0; frame < 60; frame++) {
        final double factor =
            tester.widget<Align>(find.byType(Align).last).heightFactor ?? 0;
        peak = math.max(peak, factor);
        await tester.pump(const Duration(milliseconds: 16));
      }
      expect(
        peak,
        greaterThan(1.1),
        reason: 'the retuned spring is the one the reveal rides',
      );

      await tester.pumpAndSettle();
    });

    testWidgets('header and panel content share exact horizontal alignment', (
      tester,
    ) async {
      await _pumpAccordion(tester, expanded: true, onExpandedChanged: (_) {});
      await tester.pumpAndSettle();

      final double headerLeft = tester.getTopLeft(find.text(_headerText)).dx;
      final double panelLeft = tester.getTopLeft(find.text(_panelText)).dx;

      expect(headerLeft, equals(panelLeft));
    });

    testWidgets(
      'header shows pressed surface wash without shrinking row by default',
      (tester) async {
        await _pumpAccordion(
          tester,
          expanded: false,
          onExpandedChanged: (_) {},
        );

        final ColoredBox idleWash = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(OrionPressable),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(idleWash.color, Colors.transparent);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.text(_headerText)),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        final OrionPressableState state = tester.state<OrionPressableState>(
          find.byType(OrionPressable),
        );
        expect(state.driver.target, 1.0);
        expect(state.driver.value, 1.0);

        final ColoredBox pressedWash = tester.widget<ColoredBox>(
          find
              .descendant(
                of: find.byType(OrionPressable),
                matching: find.byType(ColoredBox),
              )
              .first,
        );
        expect(pressedWash.color, isNot(Colors.transparent));

        await gesture.up();
        await tester.pumpAndSettle();
      },
    );

    testWidgets('supports title string shorthand with semi-bold styling', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionAccordion(
              title: 'Shipping details',
              expanded: false,
              onExpandedChanged: (_) {},
              child: const Text('Arrives tomorrow'),
            ),
          ),
        ),
      );

      final Text titleWidget = tester.widget<Text>(
        find.text('Shipping details'),
      );
      expect(titleWidget.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('card style paints container border and background', (
      tester,
    ) async {
      await _pumpAccordion(
        tester,
        expanded: false,
        onExpandedChanged: (_) {},
        style: OrionAccordionStyle.from(
          backgroundColor: const Color(0xFFF0F0F0),
          borderColor: const Color(0xFFCCCCCC),
        ),
      );

      final Container container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(OrionAccordion),
              matching: find.byType(Container),
            )
            .first,
      );
      final BoxDecoration decoration = container.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xFFF0F0F0));
      expect(decoration.border?.top.color, const Color(0xFFCCCCCC));
    });
  });

  group('OrionAccordionStyle', () {
    test('a merge only changes the fields it names', () {
      final OrionAccordionStyle base = OrionAccordionStyle.from(
        focusRingWidth: 4,
        iconColor: const Color(0xFF111111),
      );
      final OrionAccordionStyle merged = base.merge(
        OrionAccordionStyle.from(iconColor: const Color(0xFF333333)),
      );

      expect(merged.iconColor, const Color(0xFF333333));
      expect(merged.focusRingWidth, 4);
    });

    test('presets reproduce the shipped row', () {
      final OrionAccordionStyle style = OrionAccordionPresets.resolve(
        scheme: OrionColors.lightScheme,
      );

      expect(style.focusRingColor, OrionColors.lightScheme.onSurface);
      expect(style.focusRingWidth, 2);
      expect(style.disabledOpacity, 0.38);
      expect(style.iconColor, isNull);
      expect(style.pressedScale, 1.0);
      expect(
        style.headerPressedColor,
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.06),
      );
      expect(
        style.headerHoverColor,
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.03),
      );
      expect(style.expandSpring, OrionAccordionPresets.defaultExpandSpring);
      expect(style.collapseSpring, OrionAccordionPresets.defaultCollapseSpring);
      expect(
        style.headerPadding,
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space16,
          vertical: OrionSpacing.space8,
        ),
      );
      expect(
        style.contentPadding,
        const EdgeInsets.fromLTRB(
          OrionSpacing.space16,
          0,
          OrionSpacing.space16,
          OrionSpacing.space12,
        ),
      );
    });
  });
}
