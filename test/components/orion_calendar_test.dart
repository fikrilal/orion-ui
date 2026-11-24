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

  testWidgets('horizontal swipe left and right pages months smoothly', (
    tester,
  ) async {
    await pump(tester, value: march, onChanged: (_) {});
    expect(find.text('March 2026'), findsOneWidget);

    await tester.fling(
      find.byKey(orionCalendarGridKey),
      const Offset(-160, 0),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.text('April 2026'), findsOneWidget);

    await tester.fling(
      find.byKey(orionCalendarGridKey),
      const Offset(160, 0),
      800,
    );
    await tester.pumpAndSettle();
    expect(find.text('March 2026'), findsOneWidget);
  });

  testWidgets('tapping Month Year pill opens month and year pickers', (
    tester,
  ) async {
    await pump(tester, value: march, onChanged: (_) {});

    // Tap header pill -> switches to month picker for 2026.
    await tester.tap(find.byKey(orionCalendarMonthYearButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('2026'), findsOneWidget);
    expect(find.text('Oct'), findsOneWidget);

    // Tap header pill again -> switches to 12-year picker.
    await tester.tap(find.byKey(orionCalendarMonthYearButtonKey));
    await tester.pumpAndSettle();
    expect(find.text('2028'), findsOneWidget);

    // Pick year 2028 -> returns to month picker.
    await tester.tap(find.byKey(const ValueKey<String>('orion_calendar_year_2028')));
    await tester.pumpAndSettle();
    expect(find.text('2028'), findsOneWidget);

    // Pick Oct -> returns to day grid in October 2028.
    await tester.tap(find.byKey(const ValueKey<String>('orion_calendar_month_10')));
    await tester.pumpAndSettle();
    expect(find.text('October 2028'), findsOneWidget);
  });

  testWidgets('Today pill appears off current month and jumps back', (
    tester,
  ) async {
    final DateTime now = DateTime.now();
    final DateTime otherMonth = DateTime(now.year - 1, now.month, 10);

    await pump(tester, value: otherMonth, onChanged: (_) {});
    expect(find.byKey(orionCalendarTodayButtonKey), findsOneWidget);

    await tester.tap(find.byKey(orionCalendarTodayButtonKey));
    await tester.pumpAndSettle();

    expect(find.byKey(orionCalendarTodayButtonKey), findsNothing);
  });

  testWidgets(
    'OrionCalendar.range selects ordered range and enforces min/max span',
    (tester) async {
      DateTimeRange? committed;

      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 340,
                child: OrionCalendar.range(
                  initialMonth: DateTime(2026, 3),
                  minRangeDays: 3,
                  maxRangeDays: 7,
                  onRangeChanged: (DateTimeRange? r) => committed = r,
                ),
              ),
            ),
          ),
        ),
      );

      // Tap start day March 10.
      await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 10))));
      await tester.pump();
      expect(committed, isNull);

      // March 11 (2 days) is below minRangeDays: 3 -> blocked.
      await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 11))));
      await tester.pump();
      expect(committed, isNull);

      // March 20 (11 days) exceeds maxRangeDays: 7 -> blocked.
      await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 20))));
      await tester.pump();
      expect(committed, isNull);

      // March 14 (5 days) is valid -> commits range.
      await tester.tap(find.byKey(orionCalendarDayKey(DateTime(2026, 3, 14))));
      await tester.pump();
      expect(
        committed,
        DateTimeRange(start: DateTime(2026, 3, 10), end: DateTime(2026, 3, 14)),
      );
    },
  );

  testWidgets(
    'showOrionDateRangePickerSheet selects range and returns typed value',
    (tester) async {
      DateTimeRange? picked;
      final DateTimeRange initial = DateTimeRange(
        start: DateTime(2026, 3, 10),
        end: DateTime(2026, 3, 16),
      );

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          locale: const Locale('en', 'US'),
          home: Scaffold(
            body: Builder(
              builder: (BuildContext context) => ElevatedButton(
                onPressed: () async {
                  picked = await showOrionDateRangePickerSheet(
                    context: context,
                    initialRange: initial,
                    firstDate: DateTime(2026, 1, 1),
                    lastDate: DateTime(2026, 12, 31),
                  );
                },
                child: const Text('Open Range Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Range Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('7 days'), findsOneWidget);

      await tester.tap(find.byKey(orionDatePickerConfirmKey));
      await tester.pumpAndSettle();

      expect(picked, initial);
    },
  );
}
