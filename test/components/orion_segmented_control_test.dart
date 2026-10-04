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
  });
}
