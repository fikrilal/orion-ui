import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

const List<OrionNavigationDestination> _destinations =
    <OrionNavigationDestination>[
      OrionNavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chats',
      ),
      OrionNavigationDestination(
        icon: Icon(Icons.people_outline),
        label: 'Contacts',
      ),
      OrionNavigationDestination(
        icon: Icon(Icons.settings_outlined),
        label: 'Settings',
      ),
    ];

const double _width = 320;

double _slotWidth() => (_width - 8) / _destinations.length;

Future<void> _pumpBar(
  WidgetTester tester, {
  required int selectedIndex,
  required ValueChanged<int>? onChanged,
  double? dragPosition,
  bool visible = true,
  bool disableAnimations = false,
  bool autofocus = false,
  TextDirection textDirection = TextDirection.ltr,
  List<OrionNavigationDestination>? destinations,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: Directionality(
          textDirection: textDirection,
          child: Center(
            child: SizedBox(
              width: _width,
              child: MediaQuery(
                data: MediaQueryData(disableAnimations: disableAnimations),
                child: OrionNavigationBar(
                  destinations: destinations ?? _destinations,
                  selectedIndex: selectedIndex,
                  onChanged: onChanged,
                  dragPosition: dragPosition,
                  visible: visible,
                  autofocus: autofocus,
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}

double _pillX(WidgetTester tester) {
  final Transform pill = tester
      .widgetList<Transform>(find.byType(Transform))
      .firstWhere((Transform transform) {
        final Widget? child = transform.child;
        if (child is! DecoratedBox) {
          return false;
        }
        final Color? color = (child.decoration as BoxDecoration).color;
        return color != null && color.a > 0 && color.a < 0.2;
      });
  return pill.transform.entry(0, 3);
}

Color _labelColor(WidgetTester tester, String label) {
  return tester.widget<Text>(find.text(label)).style!.color!;
}

void main() {
  group('OrionNavigationBar', () {
    testWidgets('rests the pill on the selected slot', (tester) async {
      await _pumpBar(
        tester,
        selectedIndex: 2,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();

      expect(_pillX(tester), closeTo(2 * _slotWidth(), 0.1));
      final Text settings = tester.widget<Text>(find.text('Settings'));
      expect(settings.style?.fontWeight, FontWeight.w700);
      expect(settings.style?.color, OrionColors.lightScheme.primary);
      expect(
        _labelColor(tester, 'Contacts'),
        OrionColors.lightScheme.onSurfaceVariant,
      );
    });

    testWidgets('reports the tapped index, including a retap', (tester) async {
      int? reported;
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (int index) => reported = index,
      );

      await tester.tap(find.text('Contacts'));
      expect(reported, 1);

      reported = null;
      await tester.tap(find.text('Chats'));
      expect(reported, 0);
    });

    testWidgets('moves with the arrow keys', (tester) async {
      int? reported;
      await _pumpBar(
        tester,
        selectedIndex: 0,
        autofocus: true,
        onChanged: (int index) => reported = index,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(reported, 1);
    });

    testWidgets('follows a drag position', (tester) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        dragPosition: 1.5,
      );
      await tester.pump();

      expect(_pillX(tester), closeTo(1.5 * _slotWidth(), 0.1));
      expect(
        _labelColor(tester, 'Chats'),
        OrionColors.lightScheme.onSurfaceVariant,
      );
      expect(
        _labelColor(tester, 'Contacts'),
        Color.lerp(
          OrionColors.lightScheme.onSurfaceVariant,
          OrionColors.lightScheme.primary,
          0.5,
        ),
      );
    });

    testWidgets('travels to the slot and settles on it', (tester) async {
      await _pumpBar(tester, selectedIndex: 0, onChanged: (_) {});
      await _pumpBar(tester, selectedIndex: 1, onChanged: (_) {});

      double peak = 0;
      for (var step = 0; step < 30; step++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double x = _pillX(tester);
        if (x > peak) {
          peak = x;
        }
      }

      // It still moves with life, but a travel spring keeps that to a pixel or two. This
      // used to run on the press spring, whose overshoot is nearly a third of the travel -
      // a wobble past the destination rather than a settle on it.
      expect(peak, greaterThan(0.5 * _slotWidth()));
      expect(peak, lessThanOrEqualTo(_slotWidth() + 2));
      await tester.pumpAndSettle();
      expect(_pillX(tester), closeTo(_slotWidth(), 0.1));
    });

    testWidgets('does not select the tab between a long jump', (tester) async {
      await _pumpBar(tester, selectedIndex: 0, onChanged: (_) {});
      await _pumpBar(tester, selectedIndex: 2, onChanged: (_) {});
      await tester.pump(const Duration(milliseconds: 16));

      expect(_pillX(tester), greaterThan(0));
      expect(_pillX(tester), lessThan(2 * _slotWidth()));
      expect(
        _labelColor(tester, 'Contacts'),
        OrionColors.lightScheme.onSurfaceVariant,
      );
      await tester.pumpAndSettle();
      expect(_pillX(tester), closeTo(2 * _slotWidth(), 0.1));
      expect(
        _labelColor(tester, 'Contacts'),
        OrionColors.lightScheme.onSurfaceVariant,
      );
      expect(_labelColor(tester, 'Settings'), OrionColors.lightScheme.primary);
    });

    testWidgets('keeps the label blend when a drag settles', (tester) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        dragPosition: 0.6,
      );
      await _pumpBar(tester, selectedIndex: 1, onChanged: (_) {});
      await tester.pump();

      expect(
        _labelColor(tester, 'Chats'),
        isNot(OrionColors.lightScheme.onSurfaceVariant),
      );
      expect(
        _labelColor(tester, 'Contacts'),
        isNot(OrionColors.lightScheme.primary),
      );
    });

    testWidgets('hidden bar lets taps through and drops focus', (tester) async {
      var behind = 0;
      var reported = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                Align(
                  alignment: Alignment.bottomCenter,
                  child: TextButton(
                    onPressed: () => behind++,
                    child: const Text('Under'),
                  ),
                ),
                Align(
                  alignment: Alignment.bottomCenter,
                  child: OrionNavigationBar(
                    destinations: _destinations,
                    selectedIndex: 0,
                    visible: false,
                    autofocus: true,
                    onChanged: (_) => reported++,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Focus focus = tester.widget<Focus>(
        find.descendant(
          of: find.byType(OrionNavigationBar),
          matching: find.byType(Focus),
        ),
      );
      expect(focus.canRequestFocus, isFalse);
      await tester.tap(find.text('Under'));
      expect(behind, 1);
      expect(reported, 0);
    });

    testWidgets('hides by fading, shrinking, and a short slide', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        visible: false,
      );
      await tester.pumpAndSettle();

      final Transform slide = tester
          .widgetList<Transform>(find.byType(Transform))
          .firstWhere((Transform transform) => transform.child is Transform);
      final Transform scale = slide.child! as Transform;
      expect(slide.transform.entry(1, 3), closeTo(8, 0.1));
      expect(scale.transform.storage[0], closeTo(0.98, 0.01));
      expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 0);
    });

    testWidgets('is disabled when onChanged is null', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(tester, selectedIndex: 1, onChanged: null);

      await tester.tap(find.text('Settings'));
      final SemanticsNode node = tester.getSemantics(find.text('Contacts'));
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      expect(node.flagsCollection.isSelected, Tristate.isTrue);
      expect(
        _labelColor(tester, 'Contacts'),
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.38),
      );
      handle.dispose();
    });

    testWidgets('arrow left moves forward in right-to-left', (tester) async {
      int? reported;
      await _pumpBar(
        tester,
        selectedIndex: 0,
        autofocus: true,
        textDirection: TextDirection.rtl,
        onChanged: (int index) => reported = index,
      );
      await tester.pump();

      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(reported, 1);
    });

    testWidgets('rejects a single destination', (tester) async {
      final List<Object> errors = <Object>[];
      final void Function(FlutterErrorDetails)? previous = FlutterError.onError;
      FlutterError.onError = (FlutterErrorDetails details) {
        errors.add(details.exception);
      };
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: OrionNavigationBar(
            destinations: const <OrionNavigationDestination>[
              OrionNavigationDestination(
                icon: Icon(Icons.chat_bubble_outline),
                label: 'Chats',
              ),
            ],
            selectedIndex: 0,
            onChanged: (_) {},
          ),
        ),
      );
      FlutterError.onError = previous;

      expect(errors.whereType<AssertionError>(), isNotEmpty);
    });
  });
}
