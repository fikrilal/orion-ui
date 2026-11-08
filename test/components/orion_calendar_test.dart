import 'dart:ui' show Tristate;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:orion_ui/orion_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final DateTime march = DateTime(2026, 3, 16);
  final DateTime marchNight = DateTime(2026, 3, 16, 23, 30);

  Future<void> pump(
    WidgetTester tester, {
    DateTime? value,
    ValueChanged<DateTime>? onChanged,
    DateTime? firstDate,
    DateTime? lastDate,
    bool Function(DateTime day)? selectableDayPredicate,
    DateTime? initialMonth,
    bool disableAnimations = false,
    TextDirection direction = TextDirection.ltr,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en', 'US'),
        builder: (BuildContext context, Widget? child) {
          return MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(disableAnimations: disableAnimations),
            child: Directionality(textDirection: direction, child: child!),
          );
        },
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 320,
              child: OrionCalendar(
                value: value,
                onChanged: onChanged,
                firstDate: firstDate,
                lastDate: lastDate,
                selectableDayPredicate: selectableDayPredicate,
                initialMonth: initialMonth,
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('selects the civil day and ignores the clock', (tester) async {
    final SemanticsHandle handle = tester.ensureSemantics();
    await pump(tester, value: marchNight, onChanged: (_) {});

    final SemanticsNode node = tester.getSemantics(
      find.byKey(orionCalendarDayKey(march)),
    );
    expect(node.flagsCollection.isSelected, Tristate.isTrue);
    expect(find.text('March 2026'), findsOneWidget);
    handle.dispose();
  });

  testWidgets('a tap reports the day once', (tester) async {
    final List<DateTime> reported = <DateTime>[];
    await pump(tester, value: march, onChanged: reported.add);

    await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 18))));
    await tester.pump();
    expect(reported, <DateTime>[DateTime(2026, 3, 18)]);

    await pump(tester, value: DateTime(2026, 3, 18), onChanged: reported.add);
    await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 18))));
    await tester.pump();
    expect(reported, <DateTime>[DateTime(2026, 3, 18)]);
  });

  testWidgets('a disabled day and a day outside the bounds do not report', (
    tester,
  ) async {
    final List<DateTime> reported = <DateTime>[];
    await pump(
      tester,
      value: march,
      firstDate: DateTime(2026, 3, 10),
      lastDate: DateTime(2026, 3, 20),
      selectableDayPredicate: (DateTime day) => day.day != 18,
      onChanged: reported.add,
    );

    await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 9))));
    await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 18))));
    await tester.pump();
    expect(reported, isEmpty);

    final SemanticsNode blocked = tester.getSemantics(
      find.byKey(orionCalendarDayKey(DateTime(2026, 3, 9))),
    );
    expect(blocked.flagsCollection.isEnabled, Tristate.isFalse);
  });

  testWidgets('a null onChanged ignores taps and chevrons', (tester) async {
    await pump(tester, value: march);

    await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 18))));
    await tester.tap(find.byKey(orionCalendarNextMonthKey));
    await tester.pump();

    expect(find.text('March 2026'), findsOneWidget);
    final SemanticsNode chevron = tester.getSemantics(
      find.byKey(orionCalendarNextMonthKey),
    );
    expect(chevron.flagsCollection.isEnabled, Tristate.isFalse);
  });

  testWidgets('the grid stays six rows across short and long months', (
    tester,
  ) async {
    await pump(tester, value: DateTime(2026, 2, 1), onChanged: (_) {});
    expect(
      find.byKey(orionCalendarRowKey(DateTime(2026, 2), 5)),
      findsOneWidget,
    );
    final double february = tester
        .getSize(find.byKey(orionCalendarGridKey))
        .height;

    await pump(tester, value: DateTime(2026, 3, 1), onChanged: (_) {});
    expect(
      find.byKey(orionCalendarRowKey(DateTime(2026, 3), 5)),
      findsOneWidget,
    );
    expect(tester.getSize(find.byKey(orionCalendarGridKey)).height, february);
    expect(find.text('S'), findsWidgets);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('orion_calendar_weekday_0')))
          .data,
      'S',
    );
  });

  testWidgets('reduced motion changes the month without a leftover slide', (
    tester,
  ) async {
    await pump(
      tester,
      value: march,
      onChanged: (_) {},
      disableAnimations: true,
    );

    await tester.tap(find.byKey(orionCalendarNextMonthKey));
    await tester.pump();
    await tester.pump();

    expect(find.text('April 2026'), findsOneWidget);
    expect(
      find.byKey(orionCalendarRowKey(DateTime(2026, 4), 0)),
      findsOneWidget,
    );
    expect(find.byKey(orionCalendarRowKey(DateTime(2026, 3), 0)), findsNothing);
    for (final Transform transform in tester.widgetList<Transform>(
      find.byType(Transform),
    )) {
      expect(transform.transform.getTranslation().x, 0);
    }
  });

  testWidgets('arrows move the cursor and Enter commits', (tester) async {
    final List<DateTime> reported = <DateTime>[];
    await pump(tester, value: march, onChanged: reported.add);

    final Focus grid = tester.widget<Focus>(find.byKey(orionCalendarGridKey));
    grid.focusNode!.requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pump();
    expect(reported, isEmpty);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reported, <DateTime>[DateTime(2026, 3, 18)]);
  });

  testWidgets('arrows skip a day the predicate rejects', (tester) async {
    final List<DateTime> reported = <DateTime>[];
    await pump(
      tester,
      value: march,
      selectableDayPredicate: (DateTime day) => day.day != 17,
      onChanged: reported.add,
    );

    final Focus grid = tester.widget<Focus>(find.byKey(orionCalendarGridKey));
    grid.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(reported, <DateTime>[DateTime(2026, 3, 18)]);
  });

  testWidgets('PageDown shows the next month and Home stays in the week', (
    tester,
  ) async {
    final List<DateTime> reported = <DateTime>[];
    await pump(
      tester,
      value: march,
      onChanged: reported.add,
      disableAnimations: true,
    );

    final Focus grid = tester.widget<Focus>(find.byKey(orionCalendarGridKey));
    grid.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.home);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reported, <DateTime>[DateTime(2026, 3, 15)]);

    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    await tester.pump();
    await tester.pump();
    expect(find.text('April 2026'), findsOneWidget);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(reported, <DateTime>[DateTime(2026, 3, 15), DateTime(2026, 4, 15)]);
  });

  testWidgets('RTL flips the horizontal arrows', (tester) async {
    final List<DateTime> reported = <DateTime>[];
    await pump(
      tester,
      value: march,
      onChanged: reported.add,
      direction: TextDirection.rtl,
    );

    final Focus grid = tester.widget<Focus>(find.byKey(orionCalendarGridKey));
    grid.focusNode!.requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();

    expect(reported, <DateTime>[DateTime(2026, 3, 15)]);
  });

  testWidgets('today keeps a dot until that day is selected', (tester) async {
    final DateTime today = DateTime.now();
    final DateTime civil = DateTime(today.year, today.month, today.day);
    final DateTime other = DateTime(
      civil.year,
      civil.month,
      civil.day == 1 ? 2 : 1,
    );

    await pump(tester, value: other, onChanged: (_) {});
    expect(find.byKey(orionCalendarTodayDotKey), findsOneWidget);

    await pump(
      tester,
      value: DateTime(civil.year, civil.month, civil.day, 23, 30),
      onChanged: (_) {},
    );
    expect(find.byKey(orionCalendarTodayDotKey), findsNothing);
  });
}
