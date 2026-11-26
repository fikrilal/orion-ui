import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

import 'package:orion_ui_example/main.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

void main() {
  testWidgets('Orion Showcase index renders all 24 entries and navigates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OrionShowcaseApp());

    expect(find.text('Orion Showcase'), findsOneWidget);
    expect(find.text('24 COMPONENTS'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);

    await tester.tap(find.text('Buttons'));
    await tester.pumpAndSettle();

    expect(find.text('Orion Buttons'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
  });

  testWidgets(
    'OrionThemedScaffold inherits dark parent theme and toggles via OrionSwitch',
    (WidgetTester tester) async {
      Brightness? bodyBrightness;
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.dark(),
          home: OrionThemedScaffold(
            title: 'Test Screen',
            builder: (BuildContext context) {
              bodyBrightness = Theme.of(context).brightness;
              return const Text('Body');
            },
          ),
        ),
      );

      expect(bodyBrightness, Brightness.dark);
      final Finder toggle = find.byKey(
        const ValueKey<String>('showcase-theme-toggle'),
      );
      expect(toggle, findsOneWidget);
      expect(tester.widget<OrionSwitch>(toggle).value, isTrue);

      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(bodyBrightness, Brightness.light);
      expect(tester.widget<OrionSwitch>(toggle).value, isFalse);
    },
  );
}
