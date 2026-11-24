import 'dart:ui' show PointerDeviceKind, Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpSwitch(
  WidgetTester tester, {
  required bool value,
  required ValueChanged<bool>? onChanged,
  OrionSwitchSize size = OrionSwitchSize.medium,
  String? label,
  String? subtitle,
  OrionSwitchControlAffinity controlAffinity =
      OrionSwitchControlAffinity.trailing,
  Widget? activeIcon,
  Widget? inactiveIcon,
  String? tooltip,
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
                size: size,
                label: label,
                subtitle: subtitle,
                controlAffinity: controlAffinity,
                activeIcon: activeIcon,
                inactiveIcon: inactiveIcon,
                tooltip: tooltip,
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

List<String> _captureHaptics(WidgetTester tester) {
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

Finder get _trackFinder => find.descendant(
  of: find.byType(OrionSwitch),
  matching: find.byKey(orionSwitchTrackKey),
);

Finder get _thumbFinder => find.descendant(
  of: find.byType(OrionSwitch),
  matching: find.byKey(orionSwitchThumbKey),
);

Color _trackPaint(WidgetTester tester) {
  final DecoratedBox track = tester.widget<DecoratedBox>(_trackFinder);
  return (track.decoration as BoxDecoration).color!;
}

Color _thumbPaint(WidgetTester tester) {
  final DecoratedBox thumb = tester.widget<DecoratedBox>(_thumbFinder);
  return (thumb.decoration as BoxDecoration).color!;
}

/// Thumb displacement from its resting start edge (positive toward end edge,
/// signed in physical X: +travel in LTR, -travel in RTL).
double _thumbOffsetFromStart(
  WidgetTester tester, {
  TextDirection direction = TextDirection.ltr,
  double inset = 4.0,
}) {
  final Rect track = tester.getRect(_trackFinder);
  final Rect thumb = tester.getRect(_thumbFinder);
  if (direction == TextDirection.rtl) {
    return thumb.right - (track.right - inset);
  }
  return thumb.left - (track.left + inset);
}

void main() {
  group('OrionSwitch', () {
    testWidgets('rests the thumb at the start when off', (tester) async {
      await _pumpSwitch(tester, value: false, onChanged: (_) {});

      expect(_thumbOffsetFromStart(tester), closeTo(0.0, 0.01));
      expect(tester.getSize(_trackFinder), const Size(52, 32));
    });

    testWidgets('rests the thumb at the end when on', (tester) async {
      await _pumpSwitch(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_thumbOffsetFromStart(tester), closeTo(20.0, 0.01));
    });

    testWidgets('reports the opposite value on tap and triggers haptic', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      bool? reported;
      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (bool value) => reported = value,
      );

      await tester.tap(find.byType(OrionSwitch));
      expect(reported, isTrue);
      expect(haptics, isNotEmpty);
    });

    testWidgets('hapticType.none silences tap haptic', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      bool? reported;
      await _pumpSwitch(
        tester,
        value: false,
        style: OrionSwitchStyle.from(hapticType: OrionHapticType.none),
        onChanged: (bool value) => reported = value,
      );

      await tester.tap(find.byType(OrionSwitch));
      expect(reported, isTrue);
      expect(haptics, isEmpty);
    });

    testWidgets('flips silently from keyboard Enter and Space', (tester) async {
      final List<String> haptics = _captureHaptics(tester);
      final List<bool> reports = <bool>[];
      bool current = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return OrionSwitch(
                    value: current,
                    autofocus: true,
                    onChanged: (bool next) {
                      reports.add(next);
                      setState(() => current = next);
                    },
                  );
                },
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(reports, <bool>[true]);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pump();
      expect(reports, <bool>[true, false]);
      expect(haptics, isEmpty);
    });

    testWidgets('jumps when motion is reduced', (tester) async {
      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (_) {},
        disableAnimations: true,
      );
      expect(_thumbOffsetFromStart(tester), closeTo(0.0, 0.01));

      await _pumpSwitch(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_thumbOffsetFromStart(tester), closeTo(20.0, 0.01));
    });

    testWidgets('eases track color and keeps light thumb crisp mid-slide', (
      tester,
    ) async {
      await _pumpSwitch(tester, value: false, onChanged: (_) {});
      expect(_trackPaint(tester), OrionColors.lightScheme.outline);
      expect(_thumbPaint(tester), OrionColors.lightScheme.surface);

      await _pumpSwitch(tester, value: true, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      final Color midTrack = _trackPaint(tester);
      final Color midThumb = _thumbPaint(tester);
      expect(midTrack, isNot(OrionColors.lightScheme.outline));
      expect(midTrack, isNot(OrionColors.lightScheme.primary));
      // Light-mode thumb stays bright throughout the slide instead of crossing
      // the track through 50% gray.
      expect(
        (midThumb.computeLuminance() - midTrack.computeLuminance()).abs(),
        greaterThan(0.25),
      );

      await tester.pumpAndSettle();
      expect(_trackPaint(tester), OrionColors.lightScheme.primary);
      expect(_thumbPaint(tester), OrionColors.lightScheme.onPrimary);
    });

    testWidgets('slides the thumb instead of jumping', (tester) async {
      await _pumpSwitch(tester, value: false, onChanged: (_) {});
      await _pumpSwitch(tester, value: true, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      expect(_thumbOffsetFromStart(tester), greaterThan(0.0));
      expect(_thumbOffsetFromStart(tester), lessThan(20.0));
      await tester.pumpAndSettle();
      expect(_thumbOffsetFromStart(tester), closeTo(20.0, 0.01));
    });

    testWidgets('ignores taps and drags when disabled and omits thumb shadow', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpSwitch(tester, value: true, onChanged: null);

      await tester.tap(find.byType(OrionSwitch));
      await tester.drag(find.byType(OrionSwitch), const Offset(-40, 0));
      await tester.pumpAndSettle();

      final DecoratedBox thumb = tester.widget<DecoratedBox>(_thumbFinder);
      expect((thumb.decoration as BoxDecoration).boxShadow, isNull);

      final SemanticsNode node = tester.getSemantics(find.byType(OrionSwitch));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
      expect(node.label, isEmpty);
      handle.dispose();
    });

    testWidgets('exposes spoken name and tooltip', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (_) {},
        semanticLabel: 'Notifications',
        tooltip: 'Toggle push alerts',
      );

      expect(
        tester.getSemantics(find.byType(OrionSwitch)).label,
        'Notifications',
      );
      expect(
        tester.widget<Tooltip>(find.byType(Tooltip)).message,
        'Toggle push alerts',
      );
      handle.dispose();
    });

    testWidgets('rests on at the end edge in right-to-left', (tester) async {
      await _pumpSwitch(
        tester,
        value: true,
        onChanged: (_) {},
        disableAnimations: true,
        textDirection: TextDirection.rtl,
      );
      await tester.pump();

      expect(
        _thumbOffsetFromStart(tester, direction: TextDirection.rtl),
        closeTo(-20.0, 0.01),
      );
    });

    testWidgets('horizontal drag past halfway commits toggle with haptic', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      bool current = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return OrionSwitch(
                    value: current,
                    onChanged: (bool next) => setState(() => current = next),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(OrionSwitch), const Offset(36, 0));
      await tester.pumpAndSettle();

      expect(current, isTrue);
      expect(haptics, isNotEmpty);
      expect(_thumbOffsetFromStart(tester), closeTo(20.0, 0.05));
    });

    testWidgets(
      'small horizontal drag below halfway springs back without toggling',
      (tester) async {
        int changes = 0;
        await _pumpSwitch(tester, value: false, onChanged: (_) => changes++);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.byType(OrionSwitch)),
        );
        await gesture.moveBy(const Offset(20, 0)); // clears slop slightly
        await gesture.moveBy(const Offset(-14, 0)); // pull back before halfway
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();

        expect(changes, 0);
        expect(_thumbOffsetFromStart(tester), closeTo(0.0, 0.05));
      },
    );

    testWidgets('RTL horizontal drag left turns on and right turns off', (
      tester,
    ) async {
      bool current = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Directionality(
            textDirection: TextDirection.rtl,
            child: Scaffold(
              body: Center(
                child: StatefulBuilder(
                  builder: (BuildContext context, StateSetter setState) {
                    return OrionSwitch(
                      value: current,
                      onChanged: (bool next) => setState(() => current = next),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      );

      // Drag left in RTL turns switch ON.
      await tester.drag(find.byType(OrionSwitch), const Offset(-36, 0));
      await tester.pumpAndSettle();
      expect(current, isTrue);

      // Drag right in RTL turns switch OFF.
      await tester.drag(find.byType(OrionSwitch), const Offset(36, 0));
      await tester.pumpAndSettle();
      expect(current, isFalse);
    });

    testWidgets('rejected drag springs thumb back to authoritative value', (
      tester,
    ) async {
      bool? requested;
      // Parent receives onChanged but intentionally keeps value == false.
      await _pumpSwitch(
        tester,
        value: false,
        onChanged: (bool next) => requested = next,
      );

      await tester.drag(find.byType(OrionSwitch), const Offset(36, 0));
      await tester.pumpAndSettle();

      expect(requested, isTrue);
      expect(_thumbOffsetFromStart(tester), closeTo(0.0, 0.05));
    });

    testWidgets('vertical scroll inside ScrollView takes priority silently', (
      tester,
    ) async {
      final List<String> haptics = _captureHaptics(tester);
      final ScrollController scrollController = ScrollController();
      addTearDown(scrollController.dispose);
      int changes = 0;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              controller: scrollController,
              child: Column(
                children: <Widget>[
                  const SizedBox(height: 40),
                  OrionSwitch(value: false, onChanged: (_) => changes++),
                  const SizedBox(height: 1200),
                ],
              ),
            ),
          ),
        ),
      );

      await tester.drag(find.byType(OrionSwitch), const Offset(0, -180));
      await tester.pumpAndSettle();

      expect(scrollController.offset, greaterThan(100.0));
      expect(changes, 0);
      expect(haptics, isEmpty);
      expect(tester.getRect(_thumbFinder).width, closeTo(24.0, 0.05));
    });

    testWidgets(
      'size presets step geometry while guaranteeing 44 pt hit target',
      (tester) async {
        await _pumpSwitch(
          tester,
          value: false,
          size: OrionSwitchSize.small,
          onChanged: (_) {},
        );
        expect(tester.getSize(_trackFinder), const Size(40, 24));
        expect(tester.getSize(find.byType(OrionSwitch)), const Size(44, 44));

        await _pumpSwitch(
          tester,
          value: false,
          size: OrionSwitchSize.large,
          onChanged: (_) {},
        );
        expect(tester.getSize(_trackFinder), const Size(64, 38));
        expect(tester.getSize(find.byType(OrionSwitch)), const Size(64, 44));
      },
    );

    testWidgets('clamps invalid custom geometry without throwing', (
      tester,
    ) async {
      await _pumpSwitch(
        tester,
        value: true,
        style: OrionSwitchStyle.from(
          trackWidth: 12,
          trackHeight: 10,
          inset: 50,
        ),
        onChanged: (_) {},
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });

    testWidgets('renders clickable label and subtitle with unified semantics', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      bool current = false;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16),
              child: StatefulBuilder(
                builder: (BuildContext context, StateSetter setState) {
                  return Column(
                    children: <Widget>[
                      OrionSwitch(
                        value: current,
                        label: 'Push notifications',
                        subtitle: 'Alerts for mentions and replies',
                        onChanged: (bool next) =>
                            setState(() => current = next),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      // Default trailing affinity puts switch to the right of the label.
      final double labelLeft = tester
          .getTopLeft(find.text('Push notifications'))
          .dx;
      final double trackLeft = tester.getTopLeft(_trackFinder).dx;
      expect(trackLeft, greaterThan(labelLeft));

      // Tapping the label toggles once.
      await tester.tap(find.text('Push notifications'));
      await tester.pumpAndSettle();
      expect(current, isTrue);

      final SemanticsNode node = tester.getSemantics(find.byType(OrionSwitch));
      expect(node.label, 'Push notifications');
      expect(node.flagsCollection.isToggled, Tristate.isTrue);
      handle.dispose();
    });

    testWidgets('leading affinity and unbounded Row lay out cleanly', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: <Widget>[
                  OrionSwitch(
                    value: false,
                    label: 'Leading',
                    controlAffinity: OrionSwitchControlAffinity.leading,
                    onChanged: (_) {},
                  ),
                  OrionSwitch(
                    value: true,
                    label: 'Trailing Unbounded',
                    controlAffinity: OrionSwitchControlAffinity.trailing,
                    onChanged: (_) {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      final double leadingTrackX = tester
          .getTopLeft(
            find.descendant(
              of: find.byType(OrionSwitch).first,
              matching: find.byKey(orionSwitchTrackKey),
            ),
          )
          .dx;
      final double leadingLabelX = tester.getTopLeft(find.text('Leading')).dx;
      expect(leadingTrackX, lessThan(leadingLabelX));
    });

    testWidgets('renders activeIcon and inactiveIcon inside thumb', (
      tester,
    ) async {
      await _pumpSwitch(
        tester,
        value: false,
        activeIcon: const Icon(Icons.check_rounded),
        inactiveIcon: const Icon(Icons.close_rounded),
        disableAnimations: true,
        onChanged: (_) {},
      );
      expect(find.byIcon(Icons.close_rounded), findsOneWidget);
      expect(find.byIcon(Icons.check_rounded), findsNothing);

      await _pumpSwitch(
        tester,
        value: true,
        activeIcon: const Icon(Icons.check_rounded),
        inactiveIcon: const Icon(Icons.close_rounded),
        disableAnimations: true,
        onChanged: (_) {},
      );
      await tester.pump();
      expect(find.byIcon(Icons.check_rounded), findsOneWidget);
      expect(find.byIcon(Icons.close_rounded), findsNothing);
    });

    testWidgets('pointer hover passes WidgetState.hovered to trackColor', (
      tester,
    ) async {
      const Color restColor = Color(0xFF9E9E9E);
      const Color hoveredColor = Color(0xFF123456);
      await _pumpSwitch(
        tester,
        value: false,
        style: OrionSwitchStyle(
          trackColor: WidgetStateProperty.resolveWith<Color?>((
            Set<WidgetState> states,
          ) {
            if (states.contains(WidgetState.hovered)) {
              return hoveredColor;
            }
            return restColor;
          }),
        ),
        onChanged: (_) {},
      );

      expect(_trackPaint(tester), restColor);

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(_trackFinder));
      await tester.pump();
      expect(_trackPaint(tester), hoveredColor);
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
      expect(tester.getSize(_trackFinder), const Size(64, 40));

      // Thumb 32, insets 4: travel is 64 - 32 - 8 = 24.
      expect(_thumbOffsetFromStart(tester, inset: 4.0), closeTo(24.0, 0.01));
    });
  });

  group('OrionSwitchStyle & Theme', () {
    test('merge only changes the fields it names', () {
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

    test('defaults reproduce the medium preset geometry', () {
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
      expect(style.thumbShadow, isNotEmpty);
    });

    test('lerp smoothly interpolates style and theme values', () {
      final OrionSwitchTheme a = OrionSwitchTheme(
        defaultStyle: OrionSwitchStyle.from(
          trackWidth: 40,
          trackHeight: 24,
          trackColor: const Color(0xFF000000),
        ),
      );
      final OrionSwitchTheme b = OrionSwitchTheme(
        defaultStyle: OrionSwitchStyle.from(
          trackWidth: 60,
          trackHeight: 40,
          trackColor: const Color(0xFFFFFFFF),
        ),
      );

      final OrionSwitchTheme mid = a.lerp(b, 0.5);
      expect(mid.defaultStyle?.trackWidth, closeTo(50.0, 0.01));
      expect(mid.defaultStyle?.trackHeight, closeTo(32.0, 0.01));
      expect(
        mid.defaultStyle?.trackColor?.resolve(const <WidgetState>{}),
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
    });
  });
}
