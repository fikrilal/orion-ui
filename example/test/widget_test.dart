import 'package:flutter_test/flutter_test.dart';

import 'package:orion_ui_example/main.dart';

void main() {
  testWidgets('Orion Showcase index renders all 25 entries and navigates', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const OrionShowcaseApp());

    expect(find.text('Orion Showcase'), findsOneWidget);
    expect(find.text('25 COMPONENTS'), findsOneWidget);
    expect(find.text('Buttons'), findsOneWidget);

    await tester.tap(find.text('Buttons'));
    await tester.pumpAndSettle();

    expect(find.text('Orion Buttons'), findsOneWidget);
    expect(find.text('Playground'), findsOneWidget);
  });
}
