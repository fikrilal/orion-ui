import 'dart:async';
import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpButton(WidgetTester tester, OrionButton button) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: Center(child: button)),
    ),
  );
}

void main() {
  group('OrionButton', () {
    testWidgets('invokes a synchronous action on tap', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('locks while an async action is in flight', (tester) async {
      var calls = 0;
      final completer = Completer<void>();
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {
            calls++;
            return completer.future;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      expect(calls, 1);

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      expect(calls, 1, reason: 'presses while pending are ignored');

      completer.complete();
      await tester.pumpAndSettle();

      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();
      expect(calls, 2, reason: 'the lock releases after completion');
    });

    testWidgets('shows a progress indicator while pending without resizing', (
      tester,
    ) async {
      final completer = Completer<void>();
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () => completer.future,
          leading: const Icon(Icons.add),
          child: const Text('Save'),
        ),
      );

      final Size before = tester.getSize(find.byType(OrionButton));

      await tester.tap(find.byType(OrionButton));
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(tester.getSize(find.byType(OrionButton)), before);

      completer.complete();
      await tester.pumpAndSettle();
      expect(find.byType(CircularProgressIndicator), findsNothing);
    });

    testWidgets('leading and trailing icons use the button foreground', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {},
          leading: const Icon(Icons.download),
          trailing: const Icon(Icons.arrow_forward),
          child: const Text('Save'),
        ),
      );

      final BuildContext context = tester.element(find.byType(OrionButton));
      final Color foreground = OrionButtonPresets.resolve(
        variant: OrionButtonVariant.solid,
        size: OrionButtonSize.medium,
        scheme: Theme.of(context).colorScheme,
        theme: OrionTheme.of(context),
        textTheme: Theme.of(context).textTheme,
      ).foreground!.resolve(const <WidgetState>{})!;

      for (final icon in [Icons.download, Icons.arrow_forward]) {
        expect(
          IconTheme.of(tester.element(find.byIcon(icon))).color,
          foreground,
        );
      }
    });

    testWidgets('isLoading shows a spinner and ignores taps', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          isLoading: true,
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      expect(calls, 0);
    });

    testWidgets('isExpanded fills a bounded width and stays safe in a row', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                child: OrionButton(
                  isExpanded: true,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(OrionButton),
                matching: find.byType(DecoratedBox),
              ),
            )
            .width,
        320,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                OrionButton(
                  isExpanded: true,
                  onPressed: () {},
                  child: const Text('Save'),
                ),
              ],
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester
            .getSize(
              find.descendant(
                of: find.byType(OrionButton),
                matching: find.byType(DecoratedBox),
              ),
            )
            .width,
        lessThan(320),
      );
    });

    testWidgets('debounce suppresses presses inside the double-tap window', (
      tester,
    ) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          debounce: true,
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      expect(calls, 1);
    });

    testWidgets('without debounce both quick presses run', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          onPressed: () {
            calls++;
          },
          child: const Text('Save'),
        ),
      );

      await tester.tap(find.byType(OrionButton));
      await tester.pump();
      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      expect(calls, 2);
    });

    testWidgets('disabled button ignores taps and reports disabled semantics', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await _pumpButton(tester, const OrionButton(child: Text('Save')));

      await tester.tap(find.byType(OrionButton));
      await tester.pumpAndSettle();

      final SemanticsNode node = tester.getSemantics(
        find.byType(OrionPressable),
      );
      expect(node.flagsCollection.isButton, isTrue);
      expect(node.flagsCollection.isEnabled, Tristate.isFalse);
      handle.dispose();
    });

    testWidgets('keeps a 44 pt hit target for every size', (tester) async {
      for (final OrionButtonSize size in OrionButtonSize.values) {
        await _pumpButton(
          tester,
          OrionButton(size: size, onPressed: () {}, child: const Text('Hi')),
        );

        final Rect rect = tester.getRect(find.byType(OrionButton));
        expect(rect.height, greaterThanOrEqualTo(OrionSizing.minHitTarget));
        expect(rect.width, greaterThanOrEqualTo(OrionSizing.minHitTarget));
      }
    });

    testWidgets('activates with Enter and Space when focused', (tester) async {
      var calls = 0;
      await _pumpButton(
        tester,
        OrionButton(
          autofocus: true,
          onPressed: () {
            calls++;
          },
          child: const Text('Go'),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        Focus.of(tester.element(find.byType(OrionPressable))).hasFocus,
        isTrue,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pumpAndSettle();
      expect(calls, 1);

      await tester.sendKeyEvent(LogicalKeyboardKey.space);
      await tester.pumpAndSettle();
      expect(calls, 2);
    });

    testWidgets('builds every variant with its label', (tester) async {
      for (final OrionButtonVariant variant in OrionButtonVariant.values) {
        await _pumpButton(
          tester,
          OrionButton(
            variant: variant,
            onPressed: () {},
            child: const Text('V'),
          ),
        );

        expect(find.text('V'), findsOneWidget);
      }
    });

    testWidgets('renders plain text with label and loadingLabel shorthands', (
      tester,
    ) async {
      await _pumpButton(
        tester,
        OrionButton(
          label: 'Deploy',
          loadingLabel: 'Deploying...',
          onPressed: () {},
        ),
      );

      final Text idleText = tester.widget<Text>(find.text('Deploy'));
      expect(idleText.maxLines, 1);
      expect(idleText.overflow, TextOverflow.ellipsis);

      await _pumpButton(
        tester,
        OrionButton(
          label: 'Deploy',
          loadingLabel: 'Deploying...',
          isLoading: true,
          onPressed: () {},
        ),
      );

      expect(find.text('Deploying...'), findsOneWidget);
      expect(find.text('Deploy'), findsNothing);
    });
  });

  group('OrionButtonStyle', () {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF6750A4),
    );
    final TextTheme textTheme = ThemeData().textTheme;
    const OrionThemeData orion = OrionThemeData.fallback;

    OrionButtonStyle preset(
      OrionButtonVariant variant, {
      OrionButtonSize size = OrionButtonSize.medium,
    }) {
      return OrionButtonPresets.resolve(
        variant: variant,
        size: size,
        scheme: scheme,
        theme: orion,
        textTheme: textTheme,
      );
    }

    Color? background(OrionButtonStyle style, Set<WidgetState> states) =>
        style.background?.resolve(states);

    Color? foreground(OrionButtonStyle style, Set<WidgetState> states) =>
        style.foreground?.resolve(states);

    BorderSide? border(OrionButtonStyle style, Set<WidgetState> states) =>
        style.border?.resolve(states);

    List<BoxShadow>? shadow(OrionButtonStyle style, Set<WidgetState> states) =>
        style.shadow?.resolve(states);

    test('solid fills with primary and onPrimary and tints on pressed', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.solid);
      final Color resting = background(style, const <WidgetState>{})!;
      final Color pressed = background(style, const <WidgetState>{
        WidgetState.pressed,
      })!;
      expect(resting, scheme.primary);
      expect(pressed, isNot(resting));
      expect(foreground(style, const <WidgetState>{}), scheme.onPrimary);
      expect(border(style, const <WidgetState>{}), isNull);
    });

    test('bordered stays transparent at rest and tints on pressed', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.bordered);
      expect(background(style, const <WidgetState>{}), isNull);
      expect(
        background(style, const <WidgetState>{WidgetState.pressed}),
        isNotNull,
      );
      expect(border(style, const <WidgetState>{})?.color, scheme.outline);
    });

    test('glow adds a primary-tinted shadow', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.glow);
      expect(background(style, const <WidgetState>{}), scheme.primary);
      expect(shadow(style, const <WidgetState>{}), isNotEmpty);
    });

    test('flat has no background or border', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.flat);
      expect(background(style, const <WidgetState>{}), isNull);
      expect(border(style, const <WidgetState>{}), isNull);
    });

    test('sizes map to control heights and text styles', () {
      expect(
        preset(OrionButtonVariant.solid, size: OrionButtonSize.small).height,
        OrionSizing.controlHeightSmall,
      );
      expect(
        preset(OrionButtonVariant.solid, size: OrionButtonSize.medium).height,
        OrionSizing.controlHeightMedium,
      );
      expect(
        preset(OrionButtonVariant.solid, size: OrionButtonSize.large).height,
        OrionSizing.controlHeightLarge,
      );
      expect(
        preset(OrionButtonVariant.flat, size: OrionButtonSize.small).textStyle,
        textTheme.labelMedium,
      );
      expect(
        preset(OrionButtonVariant.flat, size: OrionButtonSize.large).textStyle,
        textTheme.titleMedium,
      );
    });

    test('disabled uses Material disabled opacities', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.solid);
      expect(
        background(style, const <WidgetState>{WidgetState.disabled}),
        scheme.onSurface.withValues(alpha: 0.12),
      );
      expect(
        foreground(style, const <WidgetState>{WidgetState.disabled}),
        scheme.onSurface.withValues(alpha: 0.38),
      );
    });

    test('focus adds a 2 pt ring for every variant', () {
      for (final OrionButtonVariant variant in OrionButtonVariant.values) {
        final OrionButtonStyle style = preset(variant);
        expect(
          border(style, const <WidgetState>{WidgetState.focused})?.width,
          2.0,
          reason: variant.name,
        );
      }
    });

    test('focus is ignored while disabled', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.bordered);
      final BorderSide? resting = border(style, const <WidgetState>{});
      final BorderSide? disabledFocused = border(style, const <WidgetState>{
        WidgetState.disabled,
        WidgetState.focused,
      });
      expect(disabledFocused?.width, resting?.width);
    });

    test('a merge only changes the fields it names', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.solid);
      final OrionButtonStyle merged = style.merge(
        OrionButtonStyle.from(backgroundColor: const Color(0xFF00FF00)),
      );
      expect(
        background(merged, const <WidgetState>{}),
        const Color(0xFF00FF00),
      );
      expect(merged.height, style.height);
      expect(merged.padding, style.padding);
      expect(
        foreground(merged, const <WidgetState>{}),
        scheme.onPrimary,
        reason: 'unnamed fields fall through to the preset',
      );
    });

    test('physics fields fall through the merge until set', () {
      final OrionButtonStyle style = preset(OrionButtonVariant.solid);
      expect(style.pressedScale, isNull);

      final OrionButtonStyle merged = style.merge(
        OrionButtonStyle.from(
          pressedScale: 0.9,
          pressSpring: OrionSpringSpec.gentle,
        ),
      );
      expect(merged.pressedScale, 0.9);
      expect(merged.pressSpring, OrionSpringSpec.gentle);
      expect(merged.releaseSpring, isNull);
    });

    testWidgets(
      'icon passed directly as child inherits button foreground color',
      (WidgetTester tester) async {
        for (final ThemeData theme in <ThemeData>[
          OrionTheme.light(),
          OrionTheme.dark(),
        ]) {
          Color? resolvedIconColor;
          await tester.pumpWidget(
            MaterialApp(
              key: ValueKey<Brightness>(theme.brightness),
              theme: theme,
              home: Scaffold(
                body: Center(
                  child: OrionButton(
                    onPressed: () {},
                    child: Builder(
                      builder: (BuildContext context) {
                        resolvedIconColor = IconTheme.of(context).color;
                        return const Icon(Icons.add);
                      },
                    ),
                  ),
                ),
              ),
            ),
          );

          expect(
            resolvedIconColor,
            theme.colorScheme.onPrimary,
            reason:
                '${theme.brightness.name} solid button child icon must tint with onPrimary',
          );
        }
      },
    );
  });
}
