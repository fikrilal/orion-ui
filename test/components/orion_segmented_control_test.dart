import 'dart:ui' show Tristate;

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
  });
}
