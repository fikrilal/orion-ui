import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

const List<OrionSegment<String>> _trips = <OrionSegment<String>>[
  OrionSegment(value: 'overview', label: Text('Overview')),
  OrionSegment(value: 'live', label: Text('Live')),
  OrionSegment(value: 'tickets', label: Text('Tickets')),
];

Future<void> _pumpControl(
  WidgetTester tester, {
  required String value,
  required ValueChanged<String>? onChanged,
  bool disableAnimations = false,
  bool autofocus = false,
  double width = 300,
  TextDirection textDirection = TextDirection.ltr,
  Widget? unboundedChild,
}) {
  final Widget control =
      unboundedChild ??
      SizedBox(
        width: width,
        child: OrionSegmentedControl<String>(
          autofocus: autofocus,
          segments: _trips,
          value: value,
          onChanged: onChanged,
        ),
      );
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: textDirection,
          child: Center(
            child: disableAnimations
                ? MediaQuery(
                    data: const MediaQueryData(disableAnimations: true),
                    child: control,
                  )
                : control,
          ),
        ),
      ),
    ),
  );
}

Finder get _pill => find.descendant(
  of: find.byType(OrionSegmentedControl<String>),
  matching: find.byWidgetPredicate((Widget widget) {
    if (widget is! DecoratedBox) {
      return false;
    }
    final Decoration decoration = widget.decoration;
    return decoration is BoxDecoration &&
        decoration.color == OrionColors.lightScheme.surface;
  }),
);

double _pillInset(WidgetTester tester) {
  final Rect control = tester.getRect(
    find.byType(OrionSegmentedControl<String>),
  );
  return tester.getRect(_pill).left - control.left;
}

double _slotInset(int index, {double width = 300, int count = 3}) {
  final double slot = (width - OrionSpacing.space4 * 2) / count;
  return OrionSpacing.space4 + index * slot;
}

void main() {
  group('OrionSegmentedControl', () {
    testWidgets('reports a tap on an unselected segment once', (tester) async {
      final List<String> values = <String>[];
      await _pumpControl(tester, value: 'overview', onChanged: values.add);

      await tester.tap(find.text('Live'));
      await tester.pump();

      expect(values, <String>['live']);
    });

    testWidgets('ignores a tap on the selected segment', (tester) async {
      var calls = 0;
      await _pumpControl(tester, value: 'live', onChanged: (_) => calls++);

      await tester.tap(find.text('Live'));
      await tester.pump();

      expect(calls, 0);
    });

    testWidgets('centers each label on its pill', (tester) async {
      await _pumpControl(
        tester,
        value: 'overview',
        disableAnimations: true,
        onChanged: (_) {},
      );

      expect(
        tester.getCenter(find.text('Overview')).dx,
        closeTo(tester.getCenter(_pill).dx, 0.1),
      );

      await _pumpControl(
        tester,
        value: 'tickets',
        disableAnimations: true,
        onChanged: (_) {},
      );
      await tester.pump();

      expect(
        tester.getCenter(find.text('Tickets')).dx,
        closeTo(tester.getCenter(_pill).dx, 0.1),
      );
    });

    testWidgets('mutes the track and labels when disabled', (tester) async {
      await _pumpControl(tester, value: 'overview', onChanged: null);

      final ColorScheme scheme = OrionColors.lightScheme;
      expect(
        find.byWidgetPredicate((Widget widget) {
          if (widget is! DecoratedBox) {
            return false;
          }
          final Decoration decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == scheme.onSurface.withValues(alpha: 0.12);
        }),
        findsOneWidget,
      );
      expect(
        DefaultTextStyle.of(tester.element(find.text('Overview'))).style.color,
        scheme.onSurface.withValues(alpha: 0.38),
      );
      expect(
        DefaultTextStyle.of(tester.element(find.text('Live'))).style.color,
        scheme.onSurface.withValues(alpha: 0.38),
      );
    });

    testWidgets('follows text direction for the pill and arrow keys', (
      tester,
    ) async {
      String value = 'overview';
      Future<void> pump() {
        return _pumpControl(
          tester,
          value: value,
          autofocus: true,
          textDirection: TextDirection.rtl,
          onChanged: (next) => value = next,
        );
      }

      await pump();
      await tester.pump();

      final Rect control = tester.getRect(
        find.byType(OrionSegmentedControl<String>),
      );
      final Rect pill = tester.getRect(_pill);
      expect(pill.center.dx, greaterThan(control.center.dx));
      expect(
        tester.getCenter(find.text('Overview')).dx,
        closeTo(pill.center.dx, 0.1),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await pump();
      expect(value, 'live');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pump();
      expect(value, 'overview');
    });

    testWidgets('ignores taps when onChanged is null', (tester) async {
      final handle = tester.ensureSemantics();
      await _pumpControl(tester, value: 'overview', onChanged: null);

      await tester.tap(find.text('Live'));
      await tester.pump();

      final SemanticsNode node = tester.getSemantics(find.text('Overview'));
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isInMutuallyExclusiveGroup, isTrue);

      final SemanticsNode idle = tester.getSemantics(find.text('Live'));
      expect(idle.flagsCollection.isSelected, Tristate.isFalse);
      expect(idle.flagsCollection.isInMutuallyExclusiveGroup, isTrue);
      handle.dispose();
    });

    testWidgets('jumps the pill when motion is reduced', (tester) async {
      String value = 'overview';
      await _pumpControl(
        tester,
        value: value,
        disableAnimations: true,
        onChanged: (next) => value = next,
      );
      expect(_pillInset(tester), closeTo(_slotInset(0), 0.1));

      value = 'tickets';
      await _pumpControl(
        tester,
        value: value,
        disableAnimations: true,
        onChanged: (next) => value = next,
      );
      await tester.pump();

      expect(_pillInset(tester), closeTo(_slotInset(2), 0.1));
    });

    testWidgets('slides the pill instead of jumping', (tester) async {
      String value = 'overview';
      await _pumpControl(
        tester,
        value: value,
        onChanged: (next) => value = next,
      );

      value = 'tickets';
      await _pumpControl(
        tester,
        value: value,
        onChanged: (next) => value = next,
      );
      await tester.pump(const Duration(milliseconds: 16));

      final double inset = _pillInset(tester);
      expect(inset, greaterThan(_slotInset(0) + 1));
      expect(inset, lessThan(_slotInset(2) - 20));
      await tester.pumpAndSettle();
    });

    testWidgets('arrow keys move the selection and stop at the ends', (
      tester,
    ) async {
      String value = 'overview';
      Future<void> pump() {
        return _pumpControl(
          tester,
          value: value,
          autofocus: true,
          onChanged: (next) => value = next,
        );
      }

      await pump();
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pump();
      expect(value, 'live');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pump();
      expect(value, 'tickets');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await pump();
      expect(value, 'tickets');

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await pump();
      expect(value, 'live');
    });

    testWidgets('rejects a missing value', (tester) async {
      await _pumpControl(tester, value: 'missing', onChanged: (_) {});
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('rejects an empty segment list', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrionSegmentedControl<String>(
            segments: const <OrionSegment<String>>[],
            value: 'overview',
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('rejects duplicate values', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: OrionSegmentedControl<String>(
            segments: const <OrionSegment<String>>[
              OrionSegment(value: 'overview', label: Text('Overview')),
              OrionSegment(value: 'overview', label: Text('Again')),
            ],
            value: 'overview',
            onChanged: (_) {},
          ),
        ),
      );
      expect(tester.takeException(), isAssertionError);
    });

    testWidgets('rejects an unbounded width', (tester) async {
      final List<Object> errors = <Object>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details.exception);
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Row(
            children: <Widget>[
              OrionSegmentedControl<String>(
                segments: _trips,
                value: 'overview',
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      );
      FlutterError.onError = previous;
      expect(errors.whereType<AssertionError>(), isNotEmpty);
    });

    testWidgets('renders a badge in a themed chip and keeps slots equal', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: OrionSegmentedControl<String>(
                  value: 'live',
                  onChanged: (_) {},
                  segments: const <OrionSegment<String>>[
                    OrionSegment(value: 'overview', label: Text('Overview')),
                    OrionSegment(
                      value: 'live',
                      label: Text('Live'),
                      badge: Text('12'),
                    ),
                    OrionSegment(value: 'tickets', label: Text('Tickets')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('12'), findsOneWidget);
      expect(
        find.byWidgetPredicate((Widget widget) {
          if (widget is! DecoratedBox) {
            return false;
          }
          final Decoration decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == OrionColors.lightScheme.primary;
        }),
        findsOneWidget,
      );

      final Finder slots = find.descendant(
        of: find.byType(OrionSegmentedControl<String>),
        matching: find.byType(OrionPressable),
      );
      expect(slots, findsNWidgets(3));
      final double first = tester.getSize(slots.at(0)).width;
      expect(tester.getSize(slots.at(1)).width, closeTo(first, 0.1));
      expect(tester.getSize(slots.at(2)).width, closeTo(first, 0.1));
    });

    testWidgets('mutes the badge when the control is disabled', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: OrionSegmentedControl<String>(
                  value: 'live',
                  onChanged: null,
                  segments: const <OrionSegment<String>>[
                    OrionSegment(value: 'overview', label: Text('Overview')),
                    OrionSegment(
                      value: 'live',
                      label: Text('Live'),
                      badge: Text('12'),
                    ),
                    OrionSegment(value: 'tickets', label: Text('Tickets')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      final ColorScheme scheme = OrionColors.lightScheme;
      expect(
        find.byWidgetPredicate((Widget widget) {
          if (widget is! DecoratedBox) {
            return false;
          }
          final Decoration decoration = widget.decoration;
          return decoration is BoxDecoration &&
              decoration.color == scheme.onSurface.withValues(alpha: 0.38);
        }),
        findsOneWidget,
      );
      expect(
        DefaultTextStyle.of(tester.element(find.text('12'))).style.color,
        scheme.surface,
      );
    });

    Widget badgedControl({required Widget? badge, required bool reduced}) {
      return MaterialApp(
        theme: OrionTheme.light(),
        home: Scaffold(
          body: Center(
            child: MediaQuery(
              data: MediaQueryData(disableAnimations: reduced),
              child: SizedBox(
                width: 300,
                child: OrionSegmentedControl<String>(
                  value: 'live',
                  onChanged: (_) {},
                  segments: <OrionSegment<String>>[
                    const OrionSegment(
                      value: 'overview',
                      label: Text('Overview'),
                    ),
                    OrionSegment(
                      value: 'live',
                      label: const Text('Live'),
                      badge: badge,
                    ),
                    const OrionSegment(
                      value: 'tickets',
                      label: Text('Tickets'),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    testWidgets('lands a badge change in the same frame under reduced motion', (
      tester,
    ) async {
      await tester.pumpWidget(
        badgedControl(badge: const Text('12'), reduced: true),
      );
      await tester.pump();
      final double withBadge = tester.getCenter(find.text('Live')).dx;

      await tester.pumpWidget(badgedControl(badge: null, reduced: true));
      await tester.pump();

      expect(find.text('12'), findsNothing);
      expect(
        tester.getCenter(find.text('Live')).dx,
        greaterThan(withBadge + 1),
        reason: 'reduced motion re-centres in the same frame',
      );
    });

    testWidgets('animates a badge change instead of snapping', (tester) async {
      await tester.pumpWidget(badgedControl(badge: null, reduced: false));
      await tester.pumpAndSettle();
      final double centred = tester.getCenter(find.text('Live')).dx;

      await tester.pumpWidget(
        badgedControl(badge: const Text('12'), reduced: false),
      );
      await tester.pump(const Duration(milliseconds: 16));
      final double midway = tester.getCenter(find.text('Live')).dx;

      await tester.pumpAndSettle();
      final double settled = tester.getCenter(find.text('Live')).dx;

      expect(
        settled,
        lessThan(centred - 5),
        reason: 'the chip keeps its space once arrived',
      );
      expect(
        midway,
        lessThan(centred - 0.5),
        reason: 'the label has started moving',
      );
      expect(
        midway,
        greaterThan(settled + 0.5),
        reason: 'and has not snapped to the end',
      );
    });
  });

  group('OrionSegmentedControlStyle', () {
    final ColorScheme scheme = OrionColors.lightScheme;

    OrionSegmentedControlStyle defaults() =>
        OrionSegmentedControlStyle.defaults(scheme: scheme);

    test('defaults reproduce the shipped look', () {
      final OrionSegmentedControlStyle style = defaults();
      expect(
        style.trackColor?.resolve(const <WidgetState>{}),
        scheme.secondary,
      );
      expect(
        style.trackColor?.resolve(const <WidgetState>{WidgetState.disabled}),
        scheme.onSurface.withValues(alpha: 0.12),
      );
      expect(style.pillColor?.resolve(const <WidgetState>{}), scheme.surface);
      expect(
        style.labelColor?.resolve(const <WidgetState>{WidgetState.selected}),
        scheme.onSurface,
      );
      expect(
        style.labelColor?.resolve(const <WidgetState>{}),
        scheme.onSurfaceVariant,
      );
      expect(
        style.labelColor?.resolve(const <WidgetState>{WidgetState.disabled}),
        scheme.onSurface.withValues(alpha: 0.38),
      );
      expect(style.badge?.fill?.resolve(const <WidgetState>{}), scheme.primary);
      expect(
        style.badge?.ink?.resolve(const <WidgetState>{}),
        scheme.onPrimary,
      );
      expect(
        style.badge?.fill?.resolve(const <WidgetState>{WidgetState.disabled}),
        scheme.onSurface.withValues(alpha: 0.38),
      );
      expect(style.height, OrionSizing.minHitTarget);
      expect(style.iconSize, OrionSizing.iconSmall);
      expect(style.badge?.height, 18);
    });

    test('a merge only changes the fields it names, deeply for the badge', () {
      final OrionSegmentedControlStyle base = defaults();
      final OrionSegmentedControlStyle merged = base.merge(
        OrionSegmentedControlStyle.from(
          pillColor: const Color(0xFF00FF00),
          badge: OrionSegmentBadgeStyle.from(fill: const Color(0xFFFF0000)),
        ),
      );

      expect(
        merged.pillColor?.resolve(const <WidgetState>{}),
        const Color(0xFF00FF00),
      );
      expect(merged.height, base.height);
      expect(
        merged.badge?.fill?.resolve(const <WidgetState>{}),
        const Color(0xFFFF0000),
      );
      expect(
        merged.badge?.ink?.resolve(const <WidgetState>{}),
        base.badge?.ink?.resolve(const <WidgetState>{}),
        reason: 'unnamed badge fields fall through the deep merge',
      );
    });

    test('from wraps plain values for every state', () {
      final OrionSegmentedControlStyle style = OrionSegmentedControlStyle.from(
        trackColor: const Color(0xFF123456),
      );
      expect(
        style.trackColor?.resolve(const <WidgetState>{WidgetState.disabled}),
        const Color(0xFF123456),
      );
      expect(style.pillColor, isNull);
    });

    testWidgets('an instance style repaints the pill, beating the theme', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionSegmentedControlTheme(
            defaultStyle: OrionSegmentedControlStyle.from(
              pillColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      Widget build(ThemeData theme, {OrionSegmentedControlStyle? style}) {
        return MaterialApp(
          theme: theme,
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: OrionSegmentedControl<String>(
                  value: 'overview',
                  onChanged: (_) {},
                  style: style,
                  segments: _trips,
                ),
              ),
            ),
          ),
        );
      }

      Finder pillWith(Color color) => find.byWidgetPredicate((Widget widget) {
        if (widget is! DecoratedBox) {
          return false;
        }
        final Decoration decoration = widget.decoration;
        return decoration is BoxDecoration && decoration.color == color;
      });

      await tester.pumpWidget(build(themed));
      expect(pillWith(const Color(0xFF00AA00)), findsOneWidget);

      await tester.pumpWidget(
        build(
          themed,
          style: OrionSegmentedControlStyle.from(
            pillColor: const Color(0xFFAA0000),
          ),
        ),
      );
      expect(pillWith(const Color(0xFFAA0000)), findsOneWidget);
      expect(pillWith(const Color(0xFF00AA00)), findsNothing);
    });

    test('lerp interpolates segmented control and badge styles smoothly', () {
      final OrionSegmentedControlStyle a = OrionSegmentedControlStyle.from(
        trackColor: const Color(0xFF000000),
        pillColor: const Color(0xFF000000),
        labelColor: const Color(0xFF000000),
        hoverColor: const Color(0x00000000),
        height: 36,
        inset: 2,
        iconSize: 14,
        radius: BorderRadius.circular(8),
        badge: OrionSegmentBadgeStyle.from(
          fill: const Color(0xFF000000),
          ink: const Color(0xFFFFFFFF),
          height: 16,
          minWidth: 16,
          gap: 2,
        ),
      );
      final OrionSegmentedControlStyle b = OrionSegmentedControlStyle.from(
        trackColor: const Color(0xFFFFFFFF),
        pillColor: const Color(0xFFFFFFFF),
        labelColor: const Color(0xFFFFFFFF),
        hoverColor: const Color(0xFF000000),
        height: 52,
        inset: 6,
        iconSize: 22,
        radius: BorderRadius.circular(24),
        badge: OrionSegmentBadgeStyle.from(
          fill: const Color(0xFFFFFFFF),
          ink: const Color(0xFF000000),
          height: 24,
          minWidth: 24,
          gap: 6,
        ),
      );

      final OrionSegmentedControlTheme lerped = OrionSegmentedControlTheme(
        defaultStyle: a,
      ).lerp(OrionSegmentedControlTheme(defaultStyle: b), 0.5);
      final OrionSegmentedControlStyle mid = lerped.defaultStyle!;

      expect(mid.height, closeTo(44, 0.001));
      expect(mid.inset, closeTo(4, 0.001));
      expect(mid.iconSize, closeTo(18, 0.001));
      expect(mid.radius, BorderRadius.circular(16));
      expect(
        mid.pillColor?.resolve(const <WidgetState>{}),
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
      expect(mid.badge?.height, closeTo(20, 0.001));
      expect(mid.badge?.gap, closeTo(4, 0.001));
      expect(
        mid.badge?.fill?.resolve(const <WidgetState>{}),
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
    });
  });

  group('OrionSegmentedControl upgrades', () {
    testWidgets('derives a concentric inner radius for rounded-rect tracks', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: OrionSegmentedControl<String>(
                  value: 'overview',
                  onChanged: (_) {},
                  style: OrionSegmentedControlStyle.from(
                    inset: 4,
                    radius: BorderRadius.circular(12),
                  ),
                  segments: _trips,
                ),
              ),
            ),
          ),
        ),
      );

      final DecoratedBox pillBox = tester.widget<DecoratedBox>(_pill);
      final BoxDecoration pillDec = pillBox.decoration as BoxDecoration;
      expect(pillDec.borderRadius, BorderRadius.circular(8));
    });

    testWidgets('uses directional start padding for badges in RTL locales', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Directionality(
              textDirection: TextDirection.rtl,
              child: Center(
                child: SizedBox(
                  width: 300,
                  child: OrionSegmentedControl<String>(
                    value: 'live',
                    onChanged: (_) {},
                    segments: const <OrionSegment<String>>[
                      OrionSegment(value: 'overview', label: Text('Overview')),
                      OrionSegment(
                        value: 'live',
                        label: Text('Live'),
                        badge: Text('9'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      final Rect labelRect = tester.getRect(find.text('Live'));
      final Rect badgeRect = tester.getRect(find.text('9'));
      // In RTL, the badge sits to the left of the label with positive gap.
      expect(badgeRect.right, lessThan(labelRect.left));
      expect(labelRect.left - badgeRect.right, greaterThanOrEqualTo(4));
    });

    testWidgets('interpolates label color continuously as the pill travels', (
      tester,
    ) async {
      String value = 'overview';
      await _pumpControl(tester, value: value, onChanged: (v) => value = v);
      await tester.pumpAndSettle();

      value = 'tickets';
      await _pumpControl(tester, value: value, onChanged: (v) => value = v);
      await tester.pump(const Duration(milliseconds: 16));

      final Color? midTicketsColor = DefaultTextStyle.of(
        tester.element(find.text('Tickets')),
      ).style.color;
      expect(midTicketsColor, isNot(OrionColors.lightScheme.onSurface));

      await tester.pumpAndSettle();
      final Color? settledTicketsColor = DefaultTextStyle.of(
        tester.element(find.text('Tickets')),
      ).style.color;
      expect(settledTicketsColor, OrionColors.lightScheme.onSurface);
    });

    testWidgets('supports horizontal pill drag-to-scrub with detent haptics', (
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

      String value = 'overview';
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return OrionSegmentedControl<String>(
                      value: value,
                      segments: _trips,
                      onChanged: (String next) => setState(() => value = next),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      final Offset start = tester.getCenter(find.text('Overview'));
      final Offset end = tester.getCenter(find.text('Tickets'));
      await tester.dragFrom(start, end - start);
      await tester.pumpAndSettle();

      expect(value, 'tickets');
      expect(haptics, isNotEmpty);
      expect(_pillInset(tester), closeTo(_slotInset(2), 0.5));
    });

    testWidgets('supports pointer hover highlight on unselected segments', (
      tester,
    ) async {
      await _pumpControl(tester, value: 'overview', onChanged: (_) {});

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await tester.pump();

      await mouse.moveTo(tester.getCenter(find.text('Live')));
      await tester.pump();

      final Color? hoveredColor = DefaultTextStyle.of(
        tester.element(find.text('Live')),
      ).style.color;
      expect(
        hoveredColor,
        Color.lerp(
          OrionColors.lightScheme.onSurfaceVariant,
          OrionColors.lightScheme.onSurface,
          0.5,
        ),
      );

      await mouse.moveTo(Offset.zero);
      await tester.pump();
      expect(
        DefaultTextStyle.of(tester.element(find.text('Live'))).style.color,
        OrionColors.lightScheme.onSurfaceVariant,
      );
    });

    testWidgets(
      'supports per-segment disabled, Home/End keys, icon, semanticLabel, and tooltip',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();
        String value = 'overview';

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 320,
                  child: StatefulBuilder(
                    builder: (BuildContext context, StateSetter setState) {
                      return OrionSegmentedControl<String>(
                        autofocus: true,
                        value: value,
                        onChanged: (String next) =>
                            setState(() => value = next),
                        segments: const <OrionSegment<String>>[
                          OrionSegment(
                            value: 'overview',
                            icon: Icon(Icons.grid_view_rounded),
                            label: Text('Overview'),
                            semanticLabel: 'Overview tab',
                            tooltip: 'Show overview',
                          ),
                          OrionSegment(
                            value: 'live',
                            label: Text('Live'),
                            enabled: false,
                          ),
                          OrionSegment(
                            value: 'tickets',
                            label: Text('Tickets'),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        // Tapping disabled segment does nothing.
        await tester.tap(find.text('Live'));
        await tester.pump();
        expect(value, 'overview');

        // ArrowRight skips disabled 'live' and selects 'tickets'.
        await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
        await tester.pump();
        expect(value, 'tickets');

        // Home jumps to first enabled segment ('overview').
        await tester.sendKeyEvent(LogicalKeyboardKey.home);
        await tester.pump();
        expect(value, 'overview');

        // End jumps to last enabled segment ('tickets').
        await tester.sendKeyEvent(LogicalKeyboardKey.end);
        await tester.pump();
        expect(value, 'tickets');

        expect(find.byType(Tooltip), findsOneWidget);
        expect(find.byIcon(Icons.grid_view_rounded), findsOneWidget);
        final SemanticsNode disabledNode = tester.getSemantics(
          find.text('Live'),
        );
        expect(disabledNode.flagsCollection.isEnabled, Tristate.isFalse);
        handle.dispose();
      },
    );

    testWidgets(
      'supports intrinsic sizing (expand: false) inside an unbounded Row and size presets',
      (tester) async {
        String value = 'a';
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Row(
                children: <Widget>[
                  OrionSegmentedControl<String>(
                    expand: false,
                    size: OrionSegmentedControlSize.small,
                    value: value,
                    onChanged: (String next) => value = next,
                    segments: const <OrionSegment<String>>[
                      OrionSegment(
                        value: 'a',
                        icon: Icon(Icons.list_rounded),
                        label: Text('List'),
                      ),
                      OrionSegment(
                        value: 'b',
                        icon: Icon(Icons.grid_view_rounded),
                        label: Text('Grid'),
                        badge: Text('4'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );

        expect(tester.takeException(), isNull);
        final Size controlSize = tester.getSize(
          find.byType(OrionSegmentedControl<String>),
        );
        expect(controlSize.height, 36);
        expect(controlSize.width, greaterThan(72));
        expect(controlSize.width, lessThan(300));
      },
    );

    testWidgets('lifted pill and hairline borders render cleanly in dark mode', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.dark(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 300,
                child: OrionSegmentedControl<String>(
                  value: 'overview',
                  onChanged: (_) {},
                  segments: _trips,
                ),
              ),
            ),
          ),
        ),
      );

      final OrionSegmentedControlStyle darkDefaults =
          OrionSegmentedControlStyle.defaults(scheme: OrionColors.darkScheme);
      final Color track = darkDefaults.trackColor!.resolve(
        const <WidgetState>{},
      )!;
      final Color pill = darkDefaults.pillColor!.resolve(const <WidgetState>{
        WidgetState.selected,
      })!;
      // In dark mode the active pill is lighter (lifted) than the recessed track.
      expect(pill.computeLuminance(), greaterThan(track.computeLuminance()));
      expect(darkDefaults.pillBorder, isNot(BorderSide.none));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'drag-to-scrub respects RTL direction and skips disabled slots',
      (tester) async {
        String value = 'overview';
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: Directionality(
                textDirection: TextDirection.rtl,
                child: Center(
                  child: SizedBox(
                    width: 300,
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setState) {
                        return OrionSegmentedControl<String>(
                          value: value,
                          onChanged: (String next) =>
                              setState(() => value = next),
                          segments: const <OrionSegment<String>>[
                            OrionSegment(
                              value: 'overview',
                              label: Text('Overview'),
                            ),
                            OrionSegment(
                              value: 'live',
                              label: Text('Live'),
                              enabled: false,
                            ),
                            OrionSegment(
                              value: 'tickets',
                              label: Text('Tickets'),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        // In RTL, 'overview' is on the right and 'tickets' is on the left.
        final Offset start = tester.getCenter(find.text('Overview'));
        final Offset end = tester.getCenter(find.text('Tickets'));
        expect(end.dx, lessThan(start.dx));

        await tester.dragFrom(start, end - start);
        await tester.pumpAndSettle();
        expect(value, 'tickets');
      },
    );
  });
}
