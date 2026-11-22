import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pump(
  WidgetTester tester, {
  required Widget button,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

Color? _faceColor(WidgetTester tester, {Finder? scope}) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find
        .descendant(
          of: scope ?? find.byType(OrionButton),
          matching: find.byType(DecoratedBox),
        )
        .first,
  );
  return (box.decoration as BoxDecoration).color;
}

double _pressScale(WidgetTester tester, Finder scope) {
  final Transform transform = tester.widget<Transform>(
    find.descendant(of: scope, matching: find.byType(Transform)).first,
  );
  return transform.transform.entry(0, 0);
}

void main() {
  group('OrionButton customization', () {
    testWidgets('the instance style wins over the theme, the theme over the '
        'preset', (tester) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionButtonTheme(
            variantStyles: <OrionButtonVariant, OrionButtonStyle>{
              OrionButtonVariant.solid: OrionButtonStyle.from(
                backgroundColor: const Color(0xFF00AA00),
              ),
            },
          ),
        ],
      );

      await _pump(
        tester,
        theme: themed,
        button: OrionButton(onPressed: () {}, child: const Text('Save')),
      );
      expect(_faceColor(tester), const Color(0xFF00AA00));

      await _pump(
        tester,
        theme: themed,
        button: OrionButton(
          onPressed: () {},
          style: OrionButtonStyle.from(
            backgroundColor: const Color(0xFFAA0000),
          ),
          child: const Text('Save'),
        ),
      );
      expect(_faceColor(tester), const Color(0xFFAA0000));

      await _pump(
        tester,
        button: OrionButton(onPressed: () {}, child: const Text('Save')),
      );
      await tester.pumpAndSettle();
      expect(
        _faceColor(tester),
        isNot(const Color(0xFF00AA00)),
        reason: 'the theme re-skin does not leak into a plain theme',
      );
    });

    testWidgets('defaultStyle stacks under the variant style', (tester) async {
      final BorderRadius radius = BorderRadius.circular(4);
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionButtonTheme(
            defaultStyle: OrionButtonStyle.from(borderRadius: radius),
            variantStyles: <OrionButtonVariant, OrionButtonStyle>{
              OrionButtonVariant.flat: OrionButtonStyle.from(
                foregroundColor: const Color(0xFF123456),
              ),
            },
          ),
        ],
      );

      await _pump(
        tester,
        theme: themed,
        button: OrionButton(
          variant: OrionButtonVariant.flat,
          onPressed: () {},
          child: const Text('Save'),
        ),
      );

      final DecoratedBox box = tester.widget<DecoratedBox>(
        find
            .descendant(
              of: find.byType(OrionButton),
              matching: find.byType(DecoratedBox),
            )
            .first,
      );
      expect((box.decoration as BoxDecoration).borderRadius, radius);

      final DefaultTextStyle text = tester.widget<DefaultTextStyle>(
        find
            .descendant(
              of: find.byType(OrionButton),
              matching: find.byType(DefaultTextStyle),
            )
            .first,
      );
      expect(text.style.color, const Color(0xFF123456));
    });

    testWidgets('per-instance physics stay on the instance', (tester) async {
      await _pump(
        tester,
        button: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            OrionButton(
              onPressed: () {},
              style: OrionButtonStyle.from(pressedScale: 0.9),
              child: const Text('Custom'),
            ),
            OrionButton(onPressed: () {}, child: const Text('Default')),
          ],
        ),
      );

      final Finder custom = find.widgetWithText(OrionButton, 'Custom');
      final Finder plain = find.widgetWithText(OrionButton, 'Default');

      final TestGesture customPress = await tester.startGesture(
        tester.getCenter(custom),
      );
      await tester.pumpAndSettle();
      expect(_pressScale(tester, custom), closeTo(0.9, 0.001));
      await customPress.up();
      await tester.pumpAndSettle();

      final TestGesture plainPress = await tester.startGesture(
        tester.getCenter(plain),
      );
      await tester.pumpAndSettle();
      expect(
        _pressScale(tester, plain),
        closeTo(0.985, 0.001),
        reason: 'the sibling keeps the theme default',
      );
      await plainPress.up();
      await tester.pumpAndSettle();
    });

    testWidgets('state-dependent colors resolve through WidgetStateProperty', (
      tester,
    ) async {
      await _pump(
        tester,
        button: OrionButton(
          onPressed: () {},
          style: OrionButtonStyle(
            background: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.pressed)
                  ? const Color(0xFF222222)
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: const Text('Save'),
        ),
      );
      expect(_faceColor(tester), const Color(0xFFEEEEEE));

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionButton)),
      );
      await tester.pump();
      expect(
        _faceColor(tester),
        const Color(0xFF222222),
        reason: 'the pressed state reaches the resolver',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(_faceColor(tester), const Color(0xFFEEEEEE));
    });

    testWidgets('hover resolves through WidgetStateProperty', (tester) async {
      await _pump(
        tester,
        button: OrionButton(
          onPressed: () {},
          style: OrionButtonStyle(
            background: WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.hovered)
                  ? const Color(0xFF333333)
                  : const Color(0xFFEEEEEE),
            ),
          ),
          child: const Text('Save'),
        ),
      );

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);
      await mouse.moveTo(tester.getCenter(find.byType(OrionButton)));
      await tester.pumpAndSettle();

      expect(_faceColor(tester), const Color(0xFF333333));
    });

    testWidgets('long press fires its callback and its impact haptic', (
      tester,
    ) async {
      final log = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall methodCall) async {
          if (methodCall.method == 'HapticFeedback.vibrate') {
            log.add(methodCall.arguments.toString());
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

      var longPressed = 0;
      await _pump(
        tester,
        button: OrionButton(
          onPressed: () {},
          onLongPress: () => longPressed++,
          style: OrionButtonStyle.from(
            impactHapticType: OrionHapticType.heavyImpact,
          ),
          child: const Text('Hold'),
        ),
      );

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.byType(OrionButton)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 600));

      expect(longPressed, 1);
      expect(log, <String>['HapticFeedbackType.heavyImpact']);

      await gesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('loadingIndicator and loadingChild replace the defaults', (
      tester,
    ) async {
      const Key loader = ValueKey<String>('custom-loader');
      await _pump(
        tester,
        button: OrionButton(
          isLoading: true,
          onPressed: () {},
          loadingIndicator: const Icon(Icons.hourglass_top, key: loader),
          loadingChild: const Text('Working'),
          child: const Text('Save'),
        ),
      );

      expect(find.byKey(loader), findsOneWidget);
      expect(find.text('Working'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('minWidth, iconSize and gap paint through the style', (
      tester,
    ) async {
      await _pump(
        tester,
        button: OrionButton(
          onPressed: () {},
          style: OrionButtonStyle.from(minWidth: 200, iconSize: 12, gap: 14),
          leading: const Icon(Icons.add),
          child: const Text('Save'),
        ),
      );

      expect(
        tester.getSize(find.byType(OrionButton)).width,
        greaterThanOrEqualTo(200),
      );
      expect(tester.getSize(find.byIcon(Icons.add)).width, 12);

      final Iterable<Padding> paddings = tester.widgetList<Padding>(
        find.descendant(
          of: find.byType(OrionButton),
          matching: find.byType(Padding),
        ),
      );
      expect(
        paddings.any(
          (Padding padding) =>
              padding.padding == const EdgeInsets.only(right: 14),
        ),
        isTrue,
        reason: 'the leading slot spaces by the style gap',
      );
    });
  });
}
