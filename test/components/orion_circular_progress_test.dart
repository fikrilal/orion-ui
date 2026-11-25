import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionCircularProgress', () {
    testWidgets(
      'sizes to default 40 and respects size/strokeWidth shorthands',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Column(
                children: <Widget>[
                  OrionCircularProgress(value: 0.5),
                  OrionCircularProgress(value: 0.75, size: 64, strokeWidth: 6),
                ],
              ),
            ),
          ),
        );

        expect(
          tester.getSize(find.byType(OrionCircularProgress).at(0)),
          const Size(40, 40),
        );
        expect(
          tester.getSize(find.byType(OrionCircularProgress).at(1)),
          const Size(64, 64),
        );
      },
    );

    testWidgets(
      'animates determinate value without rebuilding child on spring ticks',
      (tester) async {
        int childBuilds = 0;

        Widget buildRing(double value) => MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Center(
              child: OrionCircularProgress(
                value: value,
                child: Builder(
                  builder: (BuildContext context) {
                    childBuilds++;
                    return const Text('Static');
                  },
                ),
              ),
            ),
          ),
        );

        await tester.pumpWidget(buildRing(0.1));
        await tester.pumpWidget(buildRing(0.9));
        final int buildsAfterUpdate = childBuilds;

        for (int i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }
        await tester.pumpAndSettle();

        expect(childBuilds, buildsAfterUpdate);
        expect(find.text('Static'), findsOneWidget);
      },
    );

    testWidgets(
      'indeterminate spinner animates continuously and rests static under reduced motion',
      (tester) async {
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(body: Center(child: OrionCircularProgress())),
          ),
        );

        expect(tester.binding.hasScheduledFrame, isTrue);
        await tester.pump(const Duration(milliseconds: 300));
        expect(find.byType(CustomPaint), findsWidgets);

        // Under reduced motion, ticker stops cleanly and paints a static arc.
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(body: Center(child: OrionCircularProgress())),
            ),
          ),
        );
        await tester.pump();
        expect(tester.binding.hasScheduledFrame, isFalse);
      },
    );

    testWidgets(
      'carries percentage semantics, supports semanticValue override, and guards NaN',
      (tester) async {
        final SemanticsHandle handle = tester.ensureSemantics();

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: const Scaffold(
              body: Column(
                children: <Widget>[
                  OrionCircularProgress(value: 0.64, semanticLabel: 'Syncing'),
                  OrionCircularProgress(
                    value: double.nan,
                    tone: OrionProgressTone.error,
                    semanticValue: 'Paused',
                  ),
                  OrionCircularProgress(),
                ],
              ),
            ),
          ),
        );
        await tester.pump();

        expect(tester.takeException(), isNull);

        final SemanticsNode first = tester.getSemantics(
          find.byType(OrionCircularProgress).at(0),
        );
        expect(first.label, 'Syncing');
        expect(first.value, '64%');

        final SemanticsNode second = tester.getSemantics(
          find.byType(OrionCircularProgress).at(1),
        );
        expect(second.value, 'Paused');

        final SemanticsNode third = tester.getSemantics(
          find.byType(OrionCircularProgress).at(2),
        );
        expect(third.value, isEmpty);

        handle.dispose();
      },
    );

    testWidgets('resolves through OrionProgressTheme and instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.dark(),
        extensions: <ThemeExtension<dynamic>>[
          OrionProgressTheme(
            defaultStyle: OrionProgressStyle.from(size: 52, strokeWidth: 5),
          ),
        ],
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: themed,
          home: const Scaffold(
            body: Center(child: OrionCircularProgress(value: 0.5)),
          ),
        ),
      );

      expect(
        tester.getSize(find.byType(OrionCircularProgress)),
        const Size(52, 52),
      );
    });
  });
}
