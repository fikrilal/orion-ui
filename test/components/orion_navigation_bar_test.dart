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
  ValueChanged<int>? onLongPress,
  OrionNavigationBarStyle? style,
  ThemeData? theme,
  double? dragPosition,
  bool visible = true,
  bool disableAnimations = false,
  bool autofocus = false,
  TextDirection textDirection = TextDirection.ltr,
  List<OrionNavigationDestination>? destinations,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
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
                  onLongPress: onLongPress,
                  style: style,
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

/// The rendered scale of the badge wrapper at [index] - the implicit
/// widget's `scale` property is the target, not the value mid-animation, and
/// the transform's z axis stays 1 whatever the scale.
double _badgeScale(WidgetTester tester, int index) {
  final Finder wrapper = find.byType(AnimatedScale).at(index);
  final Transform transform = tester.widget<Transform>(
    find.descendant(of: wrapper, matching: find.byType(Transform)).first,
  );
  return transform.transform.entry(0, 0);
}

/// The capsule's height - the bar's root widget fills the test body, so the
/// outer decorated box is the bar itself.
Rect _capsuleRect(WidgetTester tester) {
  // The capsule's outer box is the only decorated box in the bar carrying a
  // shadow.
  final DecoratedBox capsule = tester
      .widgetList<DecoratedBox>(
        find.descendant(
          of: find.byType(OrionNavigationBar),
          matching: find.byType(DecoratedBox),
        ),
      )
      .firstWhere((DecoratedBox box) {
        final Decoration decoration = box.decoration;
        return decoration is BoxDecoration && decoration.boxShadow != null;
      });
  return tester.getRect(find.byWidget(capsule));
}

Size _capsuleSize(WidgetTester tester) => _capsuleRect(tester).size;

double _barHeight(WidgetTester tester) => _capsuleSize(tester).height;

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

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionNavigationTheme(
            defaultStyle: OrionNavigationBarStyle.from(
              destinationColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpBar(
        tester,
        selectedIndex: 2,
        onChanged: (_) {},
        disableAnimations: true,
        theme: themed,
      );
      await tester.pump();
      expect(_labelColor(tester, 'Settings'), const Color(0xFF00AA00));

      await _pumpBar(
        tester,
        selectedIndex: 2,
        onChanged: (_) {},
        disableAnimations: true,
        theme: themed,
        style: OrionNavigationBarStyle.from(
          destinationColor: const Color(0xFFAA0000),
        ),
      );
      await tester.pump();
      expect(_labelColor(tester, 'Settings'), const Color(0xFFAA0000));
    });

    testWidgets('paints a badge with its cut-out ring', (tester) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        disableAnimations: true,
        destinations: const <OrionNavigationDestination>[
          OrionNavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
            badge: Text('12'),
          ),
          OrionNavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Contacts',
          ),
        ],
      );
      await tester.pump();

      expect(find.text('12'), findsOneWidget);

      final ThemeData theme = Theme.of(
        tester.element(find.byType(OrionNavigationBar)),
      );
      final Iterable<DecoratedBox> chips = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(OrionNavigationBar),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where((DecoratedBox box) {
            final Decoration decoration = box.decoration;
            return decoration is BoxDecoration &&
                decoration.color == theme.colorScheme.primary &&
                decoration.border != null;
          });
      expect(chips, hasLength(1));
      expect(
        (chips.first.decoration as BoxDecoration).border,
        Border.all(color: theme.colorScheme.surface, width: 1.33),
      );
    });

    testWidgets('scales a badge in when it appears', (tester) async {
      const OrionNavigationDestination chats = OrionNavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chats',
      );
      const OrionNavigationDestination contactsPlain =
          OrionNavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Contacts',
          );
      const OrionNavigationDestination contactsBadged =
          OrionNavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Contacts',
            badge: Text('3'),
          );

      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        destinations: const <OrionNavigationDestination>[chats, contactsPlain],
      );
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        destinations: const <OrionNavigationDestination>[chats, contactsBadged],
      );
      await tester.pump(const Duration(milliseconds: 90));

      expect(_badgeScale(tester, 0), 0);
      final double mid = _badgeScale(tester, 1);
      expect(mid, greaterThan(0));
      expect(mid, lessThan(1));

      await tester.pumpAndSettle();
      expect(find.text('3'), findsOneWidget);
      expect(_badgeScale(tester, 0), 0);
      expect(_badgeScale(tester, 1), 1);
    });

    testWidgets('reduced motion shows a badge in the same frame', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        disableAnimations: true,
        destinations: const <OrionNavigationDestination>[
          OrionNavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
            badge: Text('12'),
          ),
          OrionNavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Contacts',
          ),
        ],
      );
      await tester.pump();

      expect(find.text('12'), findsOneWidget);
      expect(find.byType(AnimatedScale), findsNothing);
      expect(tester.binding.hasScheduledFrame, isFalse);
    });

    testWidgets('keeps the badge legible on a disabled bar', (tester) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: null,
        disableAnimations: true,
        destinations: const <OrionNavigationDestination>[
          OrionNavigationDestination(
            icon: Icon(Icons.chat_bubble_outline),
            label: 'Chats',
            badge: Text('12'),
          ),
          OrionNavigationDestination(
            icon: Icon(Icons.people_outline),
            label: 'Contacts',
          ),
        ],
      );
      await tester.pump();

      final ThemeData theme = Theme.of(
        tester.element(find.byType(OrionNavigationBar)),
      );
      final Iterable<Color> chipFills = tester
          .widgetList<DecoratedBox>(
            find.descendant(
              of: find.byType(OrionNavigationBar),
              matching: find.byType(DecoratedBox),
            ),
          )
          .where((DecoratedBox box) {
            final Decoration decoration = box.decoration;
            if (decoration is! BoxDecoration || decoration.border is! Border) {
              return false;
            }
            // The chip's ring is the only 1.33 pt border in the bar; the
            // capsule's hairline is 1 and the focus ring is 2.
            return (decoration.border! as Border).top.width == 1.33;
          })
          .map((DecoratedBox box) => (box.decoration as BoxDecoration).color!);
      expect(chipFills, <Color>[
        theme.colorScheme.primary,
      ], reason: 'a muted chip would merge with the muted icon beneath it');
      expect(
        _labelColor(tester, 'Chats'),
        theme.colorScheme.onSurface.withValues(alpha: 0.38),
        reason: 'the destination still mutes while the badge stays legible',
      );
    });

    testWidgets('hides the labels when the style asks', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.none,
        ),
      );
      await tester.pump();

      expect(find.text('Chats'), findsNothing);
      expect(find.text('Settings'), findsNothing);
      expect(
        find.descendant(
          of: find.byType(OrionNavigationBar),
          matching: find.byType(Icon),
        ),
        findsNWidgets(3),
      );
      expect(
        find.bySemanticsLabel('Contacts'),
        findsOneWidget,
        reason: "the label stays the destination's spoken name",
      );
      expect(_barHeight(tester), 52, reason: 'an icon-only bar hugs its icons');
      expect(
        _capsuleSize(tester).width,
        188,
        reason:
            'and hugs them horizontally: three 60 pt slots plus the padding',
      );

      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        disableAnimations: true,
      );
      await tester.pump();
      expect(_barHeight(tester), 64);
      expect(_capsuleSize(tester).width, 320);
      handle.dispose();
    });

    testWidgets('expands the selected destination in selected mode', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        selectedIndex: 1,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.selected,
        ),
      );
      await tester.pump();

      expect(find.text('Contacts'), findsOneWidget);
      expect(find.text('Chats'), findsNothing);
      expect(find.text('Settings'), findsNothing);
      expect(_barHeight(tester), 52);
      expect(
        _capsuleSize(tester).width,
        greaterThan(188),
        reason: 'the capsule reserves room for the expanded label',
      );
    });

    testWidgets('keeps its geometry under a scaled text size', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: MediaQuery(
                  data: const MediaQueryData(
                    disableAnimations: true,
                    textScaler: TextScaler.linear(1.3),
                  ),
                  child: OrionNavigationBar(
                    destinations: _destinations,
                    selectedIndex: 1,
                    onChanged: (_) {},
                    style: OrionNavigationBarStyle.from(
                      labelMode: OrionNavigationLabelMode.selected,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        tester.takeException(),
        isNull,
        reason: 'a scaled label must fit the room the capsule reserved',
      );
      expect(
        _barHeight(tester),
        lessThanOrEqualTo(54),
        reason: 'the capsule stays compact, the scaled label may add a hair',
      );
      expect(find.text('Contacts'), findsOneWidget);
    });

    testWidgets('keeps the label and pill on a disabled expanding bar', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        selectedIndex: 1,
        onChanged: null,
        disableAnimations: true,
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.selected,
        ),
      );
      await tester.pump();

      final ThemeData theme = Theme.of(
        tester.element(find.byType(OrionNavigationBar)),
      );
      expect(
        find.text('Contacts'),
        findsOneWidget,
        reason: 'a disabled bar mutes, it does not drop the active label',
      );
      expect(
        tester
            .widgetList<DecoratedBox>(
              find.descendant(
                of: find.byType(OrionNavigationBar),
                matching: find.byType(DecoratedBox),
              ),
            )
            .where((DecoratedBox box) {
              final Decoration decoration = box.decoration;
              return decoration is BoxDecoration &&
                  decoration.color ==
                      theme.colorScheme.onSurface.withValues(alpha: 0.04);
            }),
        isNotEmpty,
        reason: 'nor its muted pill',
      );
    });

    testWidgets('blends a mid-flight retarget instead of snapping', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.selected,
        ),
      );
      await tester.pump();

      // Jump two destinations and interrupt the flight on the middle one.
      await _pumpBar(
        tester,
        selectedIndex: 2,
        onChanged: (_) {},
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.selected,
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));
      await _pumpBar(
        tester,
        selectedIndex: 1,
        onChanged: (_) {},
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.selected,
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final double faded = tester
          .widget<Opacity>(
            find
                .ancestor(
                  of: find.text('Contacts'),
                  matching: find.byType(Opacity),
                )
                .first,
          )
          .opacity;
      expect(
        faded,
        lessThan(0.5),
        reason: 'the handed-over label arrives, it does not appear at once',
      );

      await tester.pumpAndSettle();
      expect(find.text('Contacts'), findsOneWidget);
    });

    testWidgets('centers the destinations in the expanding reserve', (
      tester,
    ) async {
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.selected,
        ),
      );
      await tester.pump();

      final Rect capsule = _capsuleRect(tester);
      final Rect first = tester.getRect(find.byIcon(Icons.chat_bubble_outline));
      final Rect last = tester.getRect(find.byIcon(Icons.settings_outlined));
      expect(
        (first.center.dx - capsule.left) - (capsule.right - last.center.dx),
        closeTo(0, 2),
        reason: "a short label's slack splits evenly across the capsule",
      );
    });

    testWidgets('fades a departing badge out', (tester) async {
      const OrionNavigationDestination badged = OrionNavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chats',
        badge: Text('12'),
      );
      const OrionNavigationDestination plain = OrionNavigationDestination(
        icon: Icon(Icons.chat_bubble_outline),
        label: 'Chats',
      );
      const OrionNavigationDestination other = OrionNavigationDestination(
        icon: Icon(Icons.people_outline),
        label: 'Contacts',
      );

      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        destinations: const <OrionNavigationDestination>[badged, other],
      );
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (_) {},
        destinations: const <OrionNavigationDestination>[plain, other],
      );
      await tester.pump(const Duration(milliseconds: 90));

      expect(
        find.text('12'),
        findsOneWidget,
        reason: 'the chip stays mounted while it scales out',
      );
      expect(_badgeScale(tester, 0), lessThan(1));

      await tester.pumpAndSettle();
      expect(find.text('12'), findsNothing);
    });

    testWidgets('announces a shown label once', (tester) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpBar(
        tester,
        selectedIndex: 2,
        onChanged: (_) {},
        disableAnimations: true,
        style: OrionNavigationBarStyle.from(
          labelMode: OrionNavigationLabelMode.selected,
        ),
      );
      await tester.pump();

      expect(
        find.bySemanticsLabel('Settings'),
        findsOneWidget,
        reason: 'the shown label must not be announced twice',
      );
      handle.dispose();
    });

    testWidgets('reports a long press without stealing the tap', (
      tester,
    ) async {
      int? longPressed;
      int? tapped;
      await _pumpBar(
        tester,
        selectedIndex: 0,
        onChanged: (int index) => tapped = index,
        onLongPress: (int index) => longPressed = index,
      );

      await tester.longPress(find.text('Contacts'));
      expect(longPressed, 1);
      expect(tapped, isNull);

      await tester.tap(find.text('Contacts'));
      expect(tapped, 1);
    });
  });

  group('OrionNavigationBarStyle', () {
    test('a merge only changes the fields it names, deeply for the badge', () {
      final OrionNavigationBarStyle base = OrionNavigationBarStyle.defaults(
        scheme: OrionColors.lightScheme,
      );
      final OrionNavigationBarStyle merged = base.merge(
        OrionNavigationBarStyle.from(
          maxWidth: 280,
          badge: OrionNavigationBadgeStyle.from(fill: const Color(0xFFFF0000)),
        ),
      );

      expect(merged.maxWidth, 280);
      expect(merged.minHeight, base.minHeight);
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

    test('defaults reproduce the shipped bar', () {
      final OrionNavigationBarStyle style = OrionNavigationBarStyle.defaults(
        scheme: OrionColors.lightScheme,
      );

      expect(style.maxWidth, 360);
      expect(style.minHeight, isNull, reason: 'the height falls back per mode');
      expect(style.iconSize, 20);
      expect(style.labelMode, OrionNavigationLabelMode.all);
      expect(style.hideSlide, 8);
      expect(style.hideScale, 0.98);
      expect(style.selectionSpring, OrionSpringSpec.immediate);
      expect(
        style.selectionColor?.resolve(const <WidgetState>{}),
        OrionColors.lightScheme.onSurface.withValues(alpha: 0.08),
      );
    });
  });
}
