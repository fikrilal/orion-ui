import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpSwitch(
  WidgetTester tester, {
  required bool value,
  required ValueChanged<bool>? onChanged,
  bool disableAnimations = false,
  bool autofocus = false,
  TextDirection textDirection = TextDirection.ltr,
  String? semanticLabel,
  OrionSwitchStyle? style,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: textDirection,
          child: Center(
            child: MediaQuery(
              data: MediaQueryData(disableAnimations: disableAnimations),
              child: OrionSwitch(
                value: value,
                onChanged: onChanged,
                autofocus: autofocus,
                semanticLabel: semanticLabel,
                style: style,
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

Color _trackPaint(WidgetTester tester) {
  final DecoratedBox track = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OrionSwitch),
          matching: find.byType(DecoratedBox),
        ),
      )
      .firstWhere((DecoratedBox box) {
        return (box.decoration as BoxDecoration).shape != BoxShape.circle;
      });
  return (track.decoration as BoxDecoration).color!;
}

double _thumbX(WidgetTester tester) {
  final Transform transform = tester.widget<Transform>(
    find.descendant(
      of: find.byType(OrionSwitch),
      matching: find.byType(Transform),
    ),
  );
  return transform.transform.entry(0, 3);
}

void main() {
  group('OrionSwitch', () {
    testWidgets('rests the thumb at the start when off', (tester) async {
      await _pumpSwitch(tester, value: false, onChanged: (_) {});

      expect(_thumbX(tester), 0);
      final DecoratedBox track = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(OrionSwitch),
              matching: find.byType(DecoratedBox),
            ),
          )
          .firstWhere((DecoratedBox box) {
            return (box.decoration as BoxDecoration).shape != BoxShape.circle;
          });
      expect(tester.getSize(find.byWidget(track)), const Size(52, 32));
    });

    testWidgets('rests the thumb at the end when on', (tester) async {
      await _pumpSwitch(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_thumbX(tester), 20);
    });

    testWidgets('reports the opposite value on tap', (tester) async {
      bool? reported;
      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (bool value) => reported = value,
      );

      await tester.tap(find.byType(OrionSwitch));
      expect(reported, isTrue);
    });

    testWidgets('flips from the keyboard', (tester) async {
      bool? reported;
      await _pumpSwitch(
        tester,
        value: false,
        autofocus: true,
        onChanged: (bool value) => reported = value,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(reported, isTrue);
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (_) {},
        disableAnimations: true,
      );
      expect(_thumbX(tester), 0);

      await _pumpSwitch(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_thumbX(tester), 20);
    });

    testWidgets('eases the track color with the thumb', (tester) async {
      await _pumpSwitch(tester, value: false, onChanged: (_) {});
      expect(_trackPaint(tester), OrionColors.lightScheme.outline);

      await _pumpSwitch(tester, value: true, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      final Color mid = _trackPaint(tester);
      expect(mid, isNot(OrionColors.lightScheme.outline));
      expect(mid, isNot(OrionColors.lightScheme.primary));

      await tester.pumpAndSettle();
      expect(_trackPaint(tester), OrionColors.lightScheme.primary);
    });

    testWidgets('slides the thumb instead of jumping', (tester) async {
      await _pumpSwitch(tester, value: false, onChanged: (_) {});
      await _pumpSwitch(tester, value: true, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      expect(_thumbX(tester), greaterThan(0));
      expect(_thumbX(tester), lessThan(20));
      await tester.pumpAndSettle();
    });

    testWidgets('ignores taps when disabled', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpSwitch(tester, value: true, onChanged: null);

      await tester.tap(find.byType(OrionSwitch));
      final SemanticsNode node = tester.getSemantics(find.byType(OrionSwitch));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
      expect(node.label, isEmpty);
      handle.dispose();
    });

    testWidgets('exposes the spoken name', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (_) {},
        semanticLabel: 'Notifications',
      );

      expect(
        tester.getSemantics(find.byType(OrionSwitch)).label,
        'Notifications',
      );
      handle.dispose();
    });

    testWidgets('rests on at the start edge in right-to-left', (tester) async {
      await _pumpSwitch(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
        textDirection: TextDirection.rtl,
      );
      await tester.pump();

      expect(_thumbX(tester), -20);
    });

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionSwitchTheme(
            defaultStyle: OrionSwitchStyle.from(
              trackColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpSwitch(tester, value: false, onChanged: (_) {}, theme: themed);
      expect(_trackPaint(tester), const Color(0xFF00AA00));

      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (_) {},
        theme: themed,
        style: OrionSwitchStyle.from(trackColor: const Color(0xFFAA0000)),
      );
      expect(_trackPaint(tester), const Color(0xFFAA0000));
    });

    testWidgets('a style retunes the geometry', (tester) async {
      await _pumpSwitch(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionSwitchStyle.from(trackWidth: 64, trackHeight: 40, inset: 4),
      );
      await tester.pump();

      expect(tester.getSize(find.byType(OrionSwitch)), const Size(64, 44));

      final DecoratedBox track = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(OrionSwitch),
              matching: find.byType(DecoratedBox),
            ),
          )
          .firstWhere((DecoratedBox box) {
            return (box.decoration as BoxDecoration).shape != BoxShape.circle;
          });
      expect(tester.getSize(find.byWidget(track)), const Size(64, 40));

      // Thumb 32, insets 4: the travel is 64 - 32 - 8.
      expect(_thumbX(tester), 24);
    });
  });

  group('OrionSwitchStyle', () {
    test('a merge only changes the fields it names', () {
      const OrionSwitchStyle base = OrionSwitchStyle(
        trackWidth: 52,
        pressStretch: 0.18,
      );
      final OrionSwitchStyle merged = base.merge(
        OrionSwitchStyle.from(trackWidth: 64),
      );

      expect(merged.trackWidth, 64);
      expect(merged.pressStretch, 0.18);
    });

    test('defaults reproduce the shipped geometry', () {
      final OrionSwitchStyle style = OrionSwitchStyle.defaults(
        scheme: OrionColors.lightScheme,
      );

      expect(style.trackWidth, 52);
      expect(style.trackHeight, OrionSizing.controlHeightSmall);
      expect(style.inset, OrionSpacing.space4);
      expect(style.pressStretch, 0.18);
      expect(style.pressSquish, 0.12);
      expect(style.slideSpring, OrionSpringSpec.gentle);
      expect(style.pressSpring, OrionSpringSpec.snappy);
    });
  });
}
