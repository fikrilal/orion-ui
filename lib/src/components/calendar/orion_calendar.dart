import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/calendar/orion_calendar_presets.dart';
import 'package:orion_ui/src/components/calendar/orion_calendar_style.dart';
import 'package:orion_ui/src/components/calendar/orion_calendar_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Selection mode for [OrionCalendar].
enum OrionCalendarSelectionMode { single, range }

/// Key for the control that shows the previous month.
const Key orionCalendarPreviousMonthKey = Key('orion_calendar_previous_month');

/// Key for the control that shows the next month.
const Key orionCalendarNextMonthKey = Key('orion_calendar_next_month');

/// Key for the clickable Month Year header pill that toggles the inline
/// month/year quick-jump picker.
const Key orionCalendarMonthYearButtonKey = Key(
  'orion_calendar_month_year_button',
);

/// Key for the quick "Today" jump pill shown when browsing away from today's month.
const Key orionCalendarTodayButtonKey = Key('orion_calendar_today_button');

/// Key for the focusable day grid.
const Key orionCalendarGridKey = Key('orion_calendar_grid');

/// Key for the dot under today's numeral, when today is not selected.
const Key orionCalendarTodayDotKey = Key('orion_calendar_today_dot');

/// Key for one civil day cell.
Key orionCalendarDayKey(DateTime day) {
  return ValueKey<String>(
    'orion_calendar_day_${day.year}-${day.month}-${day.day}',
  );
}

/// Key for one of the six week rows in [month].
Key orionCalendarRowKey(DateTime month, int row) {
  return ValueKey<String>(
    'orion_calendar_row_${month.year}_${month.month}_$row',
  );
}

enum _CalendarView { days, months, years }

/// A modern, physics-driven calendar supporting single-day and date-range
/// selection, inline month/year quick jump, horizontal swipe paging, and
/// full keyboard navigation.
///
/// Features:
/// - **Single & Range Modes:** Use the default constructor for single-day
///   selection or [OrionCalendar.range] for Airbnb/Wise-style continuous range
///   selection with optional [minRangeDays] / [maxRangeDays] enforcement.
/// - **Inline Month & Year Picker:** Tap the Month Year pill to quickly jump
///   across months and years inside the same calendar footprint.
/// - **Swipe & Spring Paging:** Swipe horizontally across the grid (or use
///   the framed chevron buttons) to glide between months on a critically-damped
///   spring.
/// - **Today Quick Jump:** A quiet "Today" pill appears whenever browsing away
///   from today's month.
class OrionCalendar extends StatefulWidget {
  /// Creates a calendar for selecting a single civil day.
  OrionCalendar({
    super.key,
    this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.initialMonth,
    this.label,
    this.showTodayButton = true,
    this.style,
  }) : mode = OrionCalendarSelectionMode.single,
       rangeValue = null,
       rangeStart = null,
       rangeEnd = null,
       onRangeChanged = null,
       onRangeSelectionChanged = null,
       minRangeDays = null,
       maxRangeDays = null,
       assert(
         _boundsAreOrdered(firstDate, lastDate),
         'firstDate must be on or before lastDate',
       );

  /// Creates a calendar for selecting an inclusive civil date range.
  ///
  /// Supply either [rangeValue] (completed range) or [rangeStart] + [rangeEnd]
  /// (for controlled in-progress range selection, such as in a picker sheet).
  OrionCalendar.range({
    super.key,
    this.rangeValue,
    this.rangeStart,
    this.rangeEnd,
    this.onRangeChanged,
    this.onRangeSelectionChanged,
    this.minRangeDays,
    this.maxRangeDays,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.initialMonth,
    this.label,
    this.showTodayButton = true,
    this.style,
  }) : mode = OrionCalendarSelectionMode.range,
       value = null,
       onChanged = null,
       assert(
         _boundsAreOrdered(firstDate, lastDate),
         'firstDate must be on or before lastDate',
       ),
       assert(
         minRangeDays == null || minRangeDays > 0,
         'minRangeDays must be positive',
       ),
       assert(
         maxRangeDays == null || maxRangeDays > 0,
         'maxRangeDays must be positive',
       ),
       assert(
         minRangeDays == null ||
             maxRangeDays == null ||
             minRangeDays <= maxRangeDays,
         'minRangeDays must not exceed maxRangeDays',
       );

  /// Whether this calendar selects a single day or a date range.
  final OrionCalendarSelectionMode mode;

  /// The selected civil day (single mode), or null when nothing is selected.
  final DateTime? value;

  /// Called with the newly selected civil day in single mode.
  ///
  /// A null callback disables selection and month paging.
  final ValueChanged<DateTime>? onChanged;

  /// Completed range value (range mode).
  final DateTimeRange? rangeValue;

  /// Controlled range start endpoint (takes precedence over `rangeValue?.start`).
  final DateTime? rangeStart;

  /// Controlled range end endpoint (takes precedence over `rangeValue?.end`).
  final DateTime? rangeEnd;

  /// Called when a complete valid range is selected (or cleared with null).
  final ValueChanged<DateTimeRange?>? onRangeChanged;

  /// Called on every range tap with both the in-progress start and end dates
  /// (so a parent header can highlight whether the user is picking start or end).
  final void Function(DateTime? start, DateTime? end)? onRangeSelectionChanged;

  /// Optional minimum inclusive day span in range mode.
  final int? minRangeDays;

  /// Optional maximum inclusive day span in range mode.
  final int? maxRangeDays;

  /// The earliest selectable civil day, inclusive.
  final DateTime? firstDate;

  /// The latest selectable civil day, inclusive.
  final DateTime? lastDate;

  /// Extra days that stay visible but cannot be selected.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// Month shown when no value is selected.
  final DateTime? initialMonth;

  /// Optional caption above the month header.
  final String? label;

  /// Whether to show a quick "Today" pill when viewing a different month.
  final bool showTodayButton;

  /// Instance style. Null fields fall through to the theme, then the presets.
  final OrionCalendarStyle? style;

  @override
  State<OrionCalendar> createState() => _OrionCalendarState();
}

bool _boundsAreOrdered(DateTime? first, DateTime? last) {
  if (first == null || last == null) {
    return true;
  }
  return !_civil(first).isAfter(_civil(last));
}

DateTime _civil(DateTime value) {
  return DateTime(value.year, value.month, value.day);
}

bool _sameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) {
    return a == null && b == null;
  }
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

bool _sameMonth(DateTime a, DateTime b) {
  return a.year == b.year && a.month == b.month;
}

int _monthIndex(DateTime month) => month.year * 12 + month.month;

int _inclusiveDaySpan(DateTime a, DateTime b) {
  return _civil(a).difference(_civil(b)).inDays.abs() + 1;
}

class _OrionCalendarState extends State<OrionCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _shown;
  DateTime? _incoming;
  DateTime? _cursor;
  int _direction = 1;
  bool _gridFocused = false;
  _CalendarView _view = _CalendarView.days;
  late int _pickerYear;
  late int _yearPageStart;

  // Internal draft start/end when caller uses `rangeValue` + `onRangeChanged`
  // without passing explicit `rangeStart`/`rangeEnd`.
  DateTime? _draftStart;
  DateTime? _draftEnd;

  late final OrionSpringDriver _monthDriver;
  late final FocusNode _gridFocus;

  bool get _isEnabled => switch (widget.mode) {
    OrionCalendarSelectionMode.single => widget.onChanged != null,
    OrionCalendarSelectionMode.range =>
      widget.onRangeChanged != null || widget.onRangeSelectionChanged != null,
  };

  bool get _usesExplicitEndpoints =>
      widget.rangeStart != null ||
      widget.rangeEnd != null ||
      widget.onRangeSelectionChanged != null;

  DateTime? get _effectiveRangeStart {
    if (widget.mode != OrionCalendarSelectionMode.range) return null;
    if (_usesExplicitEndpoints) {
      final DateTime? s = widget.rangeStart ?? widget.rangeValue?.start;
      return s == null ? null : _civil(s);
    }
    return _draftStart;
  }

  DateTime? get _effectiveRangeEnd {
    if (widget.mode != OrionCalendarSelectionMode.range) return null;
    if (_usesExplicitEndpoints) {
      final DateTime? e = widget.rangeEnd ?? widget.rangeValue?.end;
      return e == null ? null : _civil(e);
    }
    return _draftEnd;
  }

  @override
  void initState() {
    super.initState();
    _syncDraftRangeFromWidget();
    _shown = _initialMonth();
    _pickerYear = _shown.year;
    _yearPageStart = _yearWindowStart(_shown.year);
    _monthDriver = OrionSpringDriver(
      vsync: this,
      springSpec: OrionCalendarPresets.month,
      initialValue: 0,
    );
    _monthDriver.addStatusListener(_onMonthStatus);
    _gridFocus = FocusNode(debugLabel: 'OrionCalendar');
  }

  void _syncDraftRangeFromWidget() {
    if (widget.mode != OrionCalendarSelectionMode.range) {
      _draftStart = null;
      _draftEnd = null;
      return;
    }
    if (widget.rangeValue != null) {
      _draftStart = _civil(widget.rangeValue!.start);
      _draftEnd = _civil(widget.rangeValue!.end);
    } else {
      _draftStart = widget.rangeStart == null
          ? null
          : _civil(widget.rangeStart!);
      _draftEnd = widget.rangeEnd == null ? null : _civil(widget.rangeEnd!);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final OrionCalendarStyle style = _resolve(Theme.of(context));
    final OrionSpringSpec spec = style.spring ?? OrionCalendarPresets.month;
    if (_monthDriver.springSpec != spec) {
      _monthDriver.springSpec = spec;
    }
    final bool reduce = MediaQuery.disableAnimationsOf(context);
    if (_monthDriver.reducedMotion != reduce) {
      _monthDriver.reducedMotion = reduce;
    }
  }

  @override
  void didUpdateWidget(OrionCalendar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.mode == OrionCalendarSelectionMode.single) {
      final DateTime? next = widget.value == null
          ? null
          : _civil(widget.value!);
      final DateTime? previous = oldWidget.value == null
          ? null
          : _civil(oldWidget.value!);
      if (!_sameDay(next, previous)) {
        if (next != null) {
          _shown = _clampMonth(DateTime(next.year, next.month));
          _pickerYear = _shown.year;
          _incoming = null;
          if (_gridFocus.hasFocus) {
            _cursor = _canSelect(next) ? next : _fallbackCursor(_shown);
          }
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _monthDriver.jumpTo(0);
            }
          });
        }
      }
    } else {
      final bool rangeChanged =
          !_sameDay(widget.rangeValue?.start, oldWidget.rangeValue?.start) ||
          !_sameDay(widget.rangeValue?.end, oldWidget.rangeValue?.end) ||
          !_sameDay(widget.rangeStart, oldWidget.rangeStart) ||
          !_sameDay(widget.rangeEnd, oldWidget.rangeEnd);
      if (rangeChanged) {
        _syncDraftRangeFromWidget();
        final DateTime? jumpTarget =
            _effectiveRangeStart ?? widget.rangeValue?.start;
        if (jumpTarget != null &&
            !_sameMonth(jumpTarget, _shown) &&
            widget.rangeValue != null &&
            oldWidget.rangeValue != widget.rangeValue) {
          _shown = _clampMonth(DateTime(jumpTarget.year, jumpTarget.month));
          _pickerYear = _shown.year;
          _incoming = null;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              _monthDriver.jumpTo(0);
            }
          });
        }
      }
    }

    if (!_isEnabled) {
      _cursor = null;
      _view = _CalendarView.days;
    }
  }

  @override
  void dispose() {
    _monthDriver.removeStatusListener(_onMonthStatus);
    _monthDriver.dispose();
    _gridFocus.dispose();
    super.dispose();
  }

  DateTime get _destination => _incoming ?? _shown;

  OrionCalendarStyle _resolve(ThemeData theme) {
    final OrionCalendarTheme calendarTheme =
        theme.extension<OrionCalendarTheme>() ?? OrionCalendarTheme.fallback;
    return OrionCalendarPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(calendarTheme.defaultStyle).merge(widget.style);
  }

  DateTime _initialMonth() {
    final DateTime seed =
        widget.value ??
        widget.rangeStart ??
        widget.rangeValue?.start ??
        widget.initialMonth ??
        DateTime.now();
    return _clampMonth(DateTime(seed.year, seed.month));
  }

  int _yearWindowStart(int year) => math.max(1, year - 4);

  DateTime _clampMonth(DateTime month) {
    final DateTime normalized = DateTime(month.year, month.month);
    final DateTime min = widget.firstDate == null
        ? DateTime(1)
        : DateTime(widget.firstDate!.year, widget.firstDate!.month);
    final DateTime max = widget.lastDate == null
        ? DateTime(9999, 12)
        : DateTime(widget.lastDate!.year, widget.lastDate!.month);
    if (normalized.isBefore(min)) {
      return min;
    }
    if (normalized.isAfter(max)) {
      return max;
    }
    return normalized;
  }

  bool _insideWindow(DateTime day) {
    final DateTime civil = _civil(day);
    if (civil.isBefore(DateTime(1))) {
      return false;
    }
    if (civil.isAfter(DateTime(9999, 12, 31))) {
      return false;
    }
    if (widget.firstDate != null && civil.isBefore(_civil(widget.firstDate!))) {
      return false;
    }
    if (widget.lastDate != null && civil.isAfter(_civil(widget.lastDate!))) {
      return false;
    }
    return true;
  }

  bool _isMonthAllowed(int year, int month) {
    final DateTime start = DateTime(year, month, 1);
    final DateTime end = DateTime(
      year,
      month,
      DateUtils.getDaysInMonth(year, month),
    );
    if (widget.firstDate != null && end.isBefore(_civil(widget.firstDate!))) {
      return false;
    }
    if (widget.lastDate != null && start.isAfter(_civil(widget.lastDate!))) {
      return false;
    }
    return true;
  }

  bool _isYearAllowed(int year) {
    if (year < 1 || year > 9999) return false;
    if (widget.firstDate != null && year < widget.firstDate!.year) {
      return false;
    }
    if (widget.lastDate != null && year > widget.lastDate!.year) {
      return false;
    }
    return true;
  }

  bool _isInvalidRangeSize(DateTime start, DateTime end) {
    final int span = _inclusiveDaySpan(start, end);
    if (widget.minRangeDays != null && span < widget.minRangeDays!) {
      return true;
    }
    if (widget.maxRangeDays != null && span > widget.maxRangeDays!) {
      return true;
    }
    return false;
  }

  bool _canSelect(DateTime day) {
    if (!_isEnabled || !_insideWindow(day)) {
      return false;
    }
    final bool Function(DateTime day)? predicate =
        widget.selectableDayPredicate;
    if (predicate != null && !predicate(_civil(day))) {
      return false;
    }
    if (widget.mode == OrionCalendarSelectionMode.range) {
      final DateTime? start = _effectiveRangeStart;
      final DateTime? end = _effectiveRangeEnd;
      if (start != null && end == null && _isInvalidRangeSize(start, day)) {
        return false;
      }
    }
    return true;
  }

  DateTime? _fallbackCursor(DateTime month) {
    final DateTime? selected = widget.mode == OrionCalendarSelectionMode.single
        ? (widget.value == null ? null : _civil(widget.value!))
        : _effectiveRangeStart;
    if (selected != null &&
        _sameMonth(selected, month) &&
        _canSelect(selected)) {
      return selected;
    }
    final DateTime today = _civil(DateTime.now());
    if (_sameMonth(today, month) && _canSelect(today)) {
      return today;
    }
    final int count = DateUtils.getDaysInMonth(month.year, month.month);
    for (var day = 1; day <= count; day++) {
      final DateTime candidate = DateTime(month.year, month.month, day);
      if (_canSelect(candidate)) {
        return candidate;
      }
    }
    return null;
  }

  void _onMonthStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || _incoming == null) {
      return;
    }
    if (_monthDriver.target >= 1) {
      _commitIncoming();
    } else {
      setState(() => _incoming = null);
    }
  }

  void _commitIncoming() {
    final DateTime? next = _incoming;
    if (next == null) {
      return;
    }
    setState(() {
      _shown = next;
      _pickerYear = next.year;
      _incoming = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _monthDriver.jumpTo(0);
      }
    });
  }

  void _page(int delta) {
    if (!_isEnabled) {
      return;
    }
    if (_view == _CalendarView.months) {
      final int candidate = _pickerYear + delta;
      if (_isYearAllowed(candidate)) {
        setState(() => _pickerYear = candidate);
      }
      return;
    }
    if (_view == _CalendarView.years) {
      final int candidate = _yearPageStart + delta * 12;
      if (candidate >= 1 && candidate <= 9988) {
        setState(() => _yearPageStart = candidate);
      }
      return;
    }
    final DateTime from = _destination;
    _pageTo(_clampMonth(DateTime(from.year, from.month + delta)));
  }

  void _pageTo(DateTime month) {
    if (!_isEnabled) {
      return;
    }
    final DateTime target = _clampMonth(month);
    final DateTime from = _destination;
    if (_sameMonth(target, from)) {
      if (_incoming != null && _sameMonth(target, _shown)) {
        _retreat();
      }
      return;
    }
    _direction = _monthIndex(target) >= _monthIndex(from) ? 1 : -1;
    _incoming = target;
    _pickerYear = target.year;
    setState(() {});
    if (_monthDriver.reducedMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _commitIncoming();
        }
      });
      return;
    }
    _monthDriver.retarget(1);
  }

  void _retreat() {
    if (_monthDriver.reducedMotion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _incoming = null;
        _monthDriver.jumpTo(0);
        setState(() {});
      });
      return;
    }
    _monthDriver.retarget(0);
  }

  void _togglePickerView() {
    if (!_isEnabled) return;
    OrionHaptics.trigger(OrionHapticType.selectionClick);
    setState(() {
      switch (_view) {
        case _CalendarView.days:
          _pickerYear = _destination.year;
          _view = _CalendarView.months;
        case _CalendarView.months:
          _yearPageStart = _yearWindowStart(_pickerYear);
          _view = _CalendarView.years;
        case _CalendarView.years:
          _view = _CalendarView.days;
      }
    });
  }

  void _jumpToToday() {
    if (!_isEnabled) return;
    final DateTime today = _civil(DateTime.now());
    final DateTime month = _clampMonth(DateTime(today.year, today.month));
    OrionHaptics.trigger(OrionHapticType.selectionClick);
    setState(() {
      _view = _CalendarView.days;
    });
    _pageTo(month);
  }

  void _select(DateTime day) {
    if (!_canSelect(day)) {
      return;
    }
    final DateTime civil = _civil(day);
    if (!_gridFocus.hasFocus) {
      _cursor = civil;
      _gridFocus.requestFocus();
    }

    if (widget.mode == OrionCalendarSelectionMode.single) {
      setState(() => _cursor = civil);
      if (_sameDay(civil, widget.value)) {
        return;
      }
      OrionHaptics.trigger(OrionHapticType.selectionClick);
      widget.onChanged!(civil);
      return;
    }

    // Range selection logic (matches mobile-core-kit / Airbnb / Wise).
    final DateTime? currentStart = _effectiveRangeStart;
    final DateTime? currentEnd = _effectiveRangeEnd;

    DateTime? nextStart;
    DateTime? nextEnd;

    if (currentStart == null || currentEnd != null) {
      nextStart = civil;
      nextEnd = null;
    } else {
      final DateTime orderedStart = civil.isBefore(currentStart)
          ? civil
          : currentStart;
      final DateTime orderedEnd = civil.isBefore(currentStart)
          ? currentStart
          : civil;
      if (_isInvalidRangeSize(orderedStart, orderedEnd)) {
        return;
      }
      nextStart = orderedStart;
      nextEnd = orderedEnd;
    }

    OrionHaptics.trigger(OrionHapticType.selectionClick);
    setState(() {
      _cursor = civil;
      if (!_usesExplicitEndpoints) {
        _draftStart = nextStart;
        _draftEnd = nextEnd;
      }
    });

    widget.onRangeSelectionChanged?.call(nextStart, nextEnd);
    if (nextEnd != null) {
      widget.onRangeChanged?.call(
        DateTimeRange(start: nextStart, end: nextEnd),
      );
    }
  }

  void _handleFocus(bool focused) {
    _gridFocused = focused;
    if (focused && _cursor == null) {
      _cursor = _fallbackCursor(_destination);
    }
    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!_isEnabled || _view != _CalendarView.days) {
      return KeyEventResult.ignored;
    }
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      final DateTime? cursor = _cursor;
      if (cursor != null) {
        _select(cursor);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _pageKey(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _pageKey(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _moveWeekEdge(end: false);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _moveWeekEdge(end: true);
      return KeyEventResult.handled;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int? delta = switch (key) {
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowUp => -7,
      LogicalKeyboardKey.arrowDown => 7,
      _ => null,
    };
    if (delta == null) {
      return KeyEventResult.ignored;
    }
    _moveByDays(delta);
    return KeyEventResult.handled;
  }

  void _moveByDays(int delta) {
    final DateTime? from = _cursor ?? _fallbackCursor(_destination);
    if (from == null) {
      return;
    }
    final DateTime? next = _skip(from, delta);
    if (next == null) {
      return;
    }
    _cursor = next;
    final DateTime month = DateTime(next.year, next.month);
    if (!_sameMonth(month, _destination)) {
      _pageTo(month);
      return;
    }
    setState(() {});
  }

  DateTime? _skip(DateTime from, int delta) {
    final int step = delta > 0 ? 1 : -1;
    DateTime cursor = DateTime(from.year, from.month, from.day + delta);
    for (var attempt = 0; attempt < 366; attempt++) {
      if (!_insideWindow(cursor)) {
        return null;
      }
      if (_canSelect(cursor)) {
        return cursor;
      }
      cursor = DateTime(cursor.year, cursor.month, cursor.day + step);
    }
    return null;
  }

  void _moveWeekEdge({required bool end}) {
    final DateTime? from = _cursor ?? _fallbackCursor(_destination);
    if (from == null) {
      return;
    }
    final int column = _columnOf(from);
    final int shift = end ? 6 - column : -column;
    final DateTime next = DateTime(from.year, from.month, from.day + shift);
    if (!_canSelect(next)) {
      return;
    }
    _cursor = next;
    final DateTime month = DateTime(next.year, next.month);
    if (!_sameMonth(month, _destination)) {
      _pageTo(month);
      return;
    }
    setState(() {});
  }

  void _pageKey(int delta) {
    final DateTime? from = _cursor ?? _fallbackCursor(_destination);
    final DateTime base = from ?? _destination;
    final DateTime month = _clampMonth(DateTime(base.year, base.month + delta));
    final int length = DateUtils.getDaysInMonth(month.year, month.month);
    final int day = (from?.day ?? 1).clamp(1, length);
    DateTime landed = DateTime(month.year, month.month, day);
    if (!_canSelect(landed)) {
      final DateTime? fallback = _fallbackCursor(month);
      if (fallback == null) {
        return;
      }
      landed = fallback;
    }
    _cursor = landed;
    if (!_sameMonth(month, _destination)) {
      _pageTo(month);
      return;
    }
    setState(() {});
  }

  int _columnOf(DateTime day) {
    final int first = MaterialLocalizations.of(context).firstDayOfWeekIndex;
    final int sundayBased = day.weekday % DateTime.daysPerWeek;
    return (sundayBased - first + DateTime.daysPerWeek) % DateTime.daysPerWeek;
  }

  List<DateTime?> _cells(DateTime month) {
    final DateTime firstOfMonth = DateTime(month.year, month.month);
    final int leading = _columnOf(firstOfMonth);
    final int days = DateUtils.getDaysInMonth(month.year, month.month);
    return <DateTime?>[
      for (var index = 0; index < leading; index++) null,
      for (var day = 1; day <= days; day++)
        DateTime(month.year, month.month, day),
      for (
        var index = leading + days;
        index < DateTime.daysPerWeek * 6;
        index++
      )
        null,
    ];
  }

  bool _canStep(int delta) {
    if (_view == _CalendarView.months) {
      return _isYearAllowed(_pickerYear + delta);
    }
    if (_view == _CalendarView.years) {
      final int candidate = _yearPageStart + delta * 12;
      return candidate >= 1 && candidate <= 9988;
    }
    final DateTime from = _destination;
    final DateTime target = _clampMonth(
      DateTime(from.year, from.month + delta),
    );
    return !_sameMonth(target, from);
  }

  void _onHorizontalSwipeEnd(DragEndDetails details) {
    if (!_isEnabled || _view != _CalendarView.days) return;
    final double vx = details.primaryVelocity ?? 0.0;
    if (vx.abs() < 180.0) return;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int delta = (vx < 0 ? 1 : -1) * (rtl ? -1 : 1);
    if (_canStep(delta)) {
      OrionHaptics.trigger(OrionHapticType.selectionClick);
      _page(delta);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionCalendarStyle style = _resolve(theme);
    final double dayExtent = style.dayExtent ?? OrionSizing.minHitTarget;
    final double selectedExtent = style.selectedExtent ?? 38;
    final double dotSize = style.todayDotSize ?? 4;
    final double slide = style.monthSlide ?? 36;
    final double exitSlide = style.monthExitSlide ?? 24;
    final double headerGap = style.headerGap ?? OrionSpacing.space12;
    final double weekdayGap = style.weekdayGap ?? OrionSpacing.space8;
    final double ringWidth = style.focusRingWidth ?? 1.5;
    final Color rangeFill =
        style.rangeFillColor ?? scheme.primary.withValues(alpha: 0.11);
    final Color rangeText = style.rangeTextColor ?? scheme.onSurface;
    final bool strikethroughDisabled = style.strikethroughDisabled ?? true;

    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final bool enabled = _isEnabled;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final DateTime titleMonth = _destination;
    final DateTime today = _civil(DateTime.now());
    final bool canJumpToday =
        widget.showTodayButton &&
        enabled &&
        _view == _CalendarView.days &&
        !_sameMonth(titleMonth, today) &&
        _insideWindow(today);

    final int slideSign = _direction * (rtl ? -1 : 1);

    final String headerTitle = switch (_view) {
      _CalendarView.days => localizations.formatMonthYear(titleMonth),
      _CalendarView.months => '$_pickerYear',
      _CalendarView.years => '$_yearPageStart – ${_yearPageStart + 11}',
    };

    final double gridHeight = dayExtent * 6;

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(
          constraints.hasBoundedWidth,
          'OrionCalendar needs a bounded width',
        );

        Widget bodyContent;
        if (_view == _CalendarView.months) {
          bodyContent = _buildMonthPicker(
            theme: theme,
            scheme: scheme,
            localizations: localizations,
            totalHeight: gridHeight + 24 + weekdayGap,
          );
        } else if (_view == _CalendarView.years) {
          bodyContent = _buildYearPicker(
            theme: theme,
            scheme: scheme,
            totalHeight: gridHeight + 24 + weekdayGap,
          );
        } else {
          final Widget shownGrid = _monthGrid(
            month: _shown,
            scheme: scheme,
            theme: theme,
            dayExtent: dayExtent,
            selectedExtent: selectedExtent,
            dotSize: dotSize,
            ringWidth: ringWidth,
            rangeFill: rangeFill,
            rangeText: rangeText,
            strikethroughDisabled: strikethroughDisabled,
            localizations: localizations,
          );
          final Widget? incomingGrid = _incoming == null
              ? null
              : _monthGrid(
                  month: _incoming!,
                  scheme: scheme,
                  theme: theme,
                  dayExtent: dayExtent,
                  selectedExtent: selectedExtent,
                  dotSize: dotSize,
                  ringWidth: ringWidth,
                  rangeFill: rangeFill,
                  rangeText: rangeText,
                  strikethroughDisabled: strikethroughDisabled,
                  localizations: localizations,
                );

          bodyContent = Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              _Weekdays(
                localizations: localizations,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.4,
                ),
                color: scheme.onSurfaceVariant,
              ),
              SizedBox(height: weekdayGap),
              GestureDetector(
                behavior: HitTestBehavior.translucent,
                onHorizontalDragEnd: _onHorizontalSwipeEnd,
                child: Focus(
                  key: orionCalendarGridKey,
                  focusNode: _gridFocus,
                  onFocusChange: _handleFocus,
                  onKeyEvent: _onKey,
                  child: AnimatedBuilder(
                    animation: _monthDriver,
                    builder: (BuildContext context, Widget? child) {
                      final double t = _monthDriver.value.clamp(0.0, 1.0);
                      return ClipRect(
                        child: Stack(
                          children: <Widget>[
                            if (incomingGrid != null)
                              ExcludeSemantics(
                                excluding: false,
                                child: _slide(
                                  child: incomingGrid,
                                  dx: slideSign * slide * (1 - t),
                                  opacity: (t * 2).clamp(0.0, 1.0),
                                ),
                              ),
                            ExcludeSemantics(
                              excluding: incomingGrid != null,
                              child: _slide(
                                child: shownGrid,
                                dx: incomingGrid == null
                                    ? 0
                                    : -slideSign * exitSlide * t,
                                opacity: incomingGrid == null ? 1 : (1 - t),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        }

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.label != null) ...<Widget>[
              Text(
                widget.label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: OrionSpacing.space8),
            ],
            // Wise/Airbnb header bar: left-aligned Month/Year selector pill +
            // right-aligned Today pill & framed circular chevron buttons.
            Row(
              children: <Widget>[
                Expanded(
                  child: Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Semantics(
                      button: true,
                      enabled: enabled,
                      label: 'Change month or year, currently $headerTitle',
                      child: OrionPressable(
                        key: orionCalendarMonthYearButtonKey,
                        onTap: enabled ? _togglePickerView : null,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: OrionSpacing.space12,
                            vertical: OrionSpacing.space8,
                          ),
                          decoration: BoxDecoration(
                            color: _view != _CalendarView.days
                                ? scheme.primary.withValues(alpha: 0.10)
                                : scheme.surfaceContainerHighest.withValues(
                                    alpha: 0.55,
                                  ),
                            borderRadius: BorderRadius.circular(
                              OrionRadii.radiusPill,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: <Widget>[
                              Flexible(
                                child: Text(
                                  headerTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: -0.2,
                                    color: enabled
                                        ? (_view != _CalendarView.days
                                              ? scheme.primary
                                              : scheme.onSurface)
                                        : scheme.onSurface.withValues(
                                            alpha: 0.38,
                                          ),
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              AnimatedRotation(
                                turns: _view == _CalendarView.days ? 0.0 : 0.5,
                                duration: const Duration(milliseconds: 180),
                                child: Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  size: 18,
                                  color: enabled
                                      ? (_view != _CalendarView.days
                                            ? scheme.primary
                                            : scheme.onSurfaceVariant)
                                      : scheme.onSurface.withValues(
                                          alpha: 0.38,
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                if (canJumpToday) ...<Widget>[
                  OrionPressable(
                    key: orionCalendarTodayButtonKey,
                    onTap: _jumpToToday,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radiusPill,
                        ),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.7),
                        ),
                      ),
                      child: Text(
                        'Today',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurface,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: OrionSpacing.space4),
                ],
                _Chevron(
                  key: orionCalendarPreviousMonthKey,
                  icon: rtl
                      ? Icons.chevron_right_rounded
                      : Icons.chevron_left_rounded,
                  label: 'Previous month',
                  enabled: enabled && _canStep(-1),
                  scheme: scheme,
                  onTap: () => _page(-1),
                ),
                _Chevron(
                  key: orionCalendarNextMonthKey,
                  icon: rtl
                      ? Icons.chevron_left_rounded
                      : Icons.chevron_right_rounded,
                  label: 'Next month',
                  enabled: enabled && _canStep(1),
                  scheme: scheme,
                  onTap: () => _page(1),
                ),
              ],
            ),
            SizedBox(height: headerGap),
            bodyContent,
          ],
        );
      },
    );
  }

  Widget _buildMonthPicker({
    required ThemeData theme,
    required ColorScheme scheme,
    required MaterialLocalizations localizations,
    required double totalHeight,
  }) {
    const List<String> shortMonths = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final DateTime now = DateTime.now();

    return SizedBox(
      height: totalHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: OrionSpacing.space8,
          crossAxisSpacing: OrionSpacing.space8,
          childAspectRatio: 2.1,
        ),
        itemCount: 12,
        itemBuilder: (BuildContext context, int index) {
          final int month = index + 1;
          final bool allowed = _isMonthAllowed(_pickerYear, month);
          final bool isSelected =
              _destination.year == _pickerYear && _destination.month == month;
          final bool isCurrent = now.year == _pickerYear && now.month == month;

          return OrionPressable(
            key: ValueKey<String>('orion_calendar_month_$month'),
            onTap: allowed
                ? () {
                    OrionHaptics.trigger(OrionHapticType.selectionClick);
                    final DateTime target = _clampMonth(
                      DateTime(_pickerYear, month),
                    );
                    setState(() {
                      _shown = target;
                      _incoming = null;
                      _view = _CalendarView.days;
                    });
                    _monthDriver.jumpTo(0);
                  }
                : null,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(OrionRadii.radius12),
                border: isCurrent && !isSelected
                    ? Border.all(color: scheme.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                shortMonths[index],
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected || isCurrent
                      ? FontWeight.w700
                      : FontWeight.w500,
                  color: !allowed
                      ? scheme.onSurface.withValues(alpha: 0.30)
                      : isSelected
                      ? scheme.onPrimary
                      : scheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildYearPicker({
    required ThemeData theme,
    required ColorScheme scheme,
    required double totalHeight,
  }) {
    final int currentYear = DateTime.now().year;

    return SizedBox(
      height: totalHeight,
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          mainAxisSpacing: OrionSpacing.space8,
          crossAxisSpacing: OrionSpacing.space8,
          childAspectRatio: 2.1,
        ),
        itemCount: 12,
        itemBuilder: (BuildContext context, int index) {
          final int year = _yearPageStart + index;
          final bool allowed = _isYearAllowed(year);
          final bool isSelected = _pickerYear == year;
          final bool isCurrent = currentYear == year;

          return OrionPressable(
            key: ValueKey<String>('orion_calendar_year_$year'),
            onTap: allowed
                ? () {
                    OrionHaptics.trigger(OrionHapticType.selectionClick);
                    setState(() {
                      _pickerYear = year;
                      _view = _CalendarView.months;
                    });
                  }
                : null,
            child: Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isSelected
                    ? scheme.primary
                    : scheme.surfaceContainerHighest.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(OrionRadii.radius12),
                border: isCurrent && !isSelected
                    ? Border.all(color: scheme.primary, width: 1.5)
                    : null,
              ),
              child: Text(
                '$year',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: isSelected || isCurrent
                      ? FontWeight.w700
                      : FontWeight.w500,
                  fontFeatures: const <FontFeature>[
                    FontFeature.tabularFigures(),
                  ],
                  color: !allowed
                      ? scheme.onSurface.withValues(alpha: 0.30)
                      : isSelected
                      ? scheme.onPrimary
                      : scheme.onSurface,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _slide({
    required Widget child,
    required double dx,
    required double opacity,
  }) {
    return IgnorePointer(
      ignoring: _incoming != null,
      child: Opacity(
        opacity: opacity,
        child: Transform.translate(offset: Offset(dx, 0), child: child),
      ),
    );
  }

  Widget _monthGrid({
    required DateTime month,
    required ColorScheme scheme,
    required ThemeData theme,
    required double dayExtent,
    required double selectedExtent,
    required double dotSize,
    required double ringWidth,
    required Color rangeFill,
    required Color rangeText,
    required bool strikethroughDisabled,
    required MaterialLocalizations localizations,
  }) {
    final List<DateTime?> cells = _cells(month);
    final DateTime today = _civil(DateTime.now());
    final DateTime? selected = widget.mode == OrionCalendarSelectionMode.single
        ? (widget.value == null ? null : _civil(widget.value!))
        : null;
    final DateTime? rangeStart = _effectiveRangeStart;
    final DateTime? rangeEnd = _effectiveRangeEnd;
    final TextStyle dayStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
    final bool rtl = Directionality.of(context) == TextDirection.rtl;

    return Column(
      children: <Widget>[
        for (var row = 0; row < 6; row++)
          Row(
            key: orionCalendarRowKey(month, row),
            children: <Widget>[
              for (var column = 0; column < DateTime.daysPerWeek; column++)
                Expanded(
                  child: _day(
                    day: cells[row * DateTime.daysPerWeek + column],
                    column: column,
                    rtl: rtl,
                    today: today,
                    selected: selected,
                    rangeStart: rangeStart,
                    rangeEnd: rangeEnd,
                    dayExtent: dayExtent,
                    selectedExtent: selectedExtent,
                    dotSize: dotSize,
                    ringWidth: ringWidth,
                    rangeFill: rangeFill,
                    rangeText: rangeText,
                    strikethroughDisabled: strikethroughDisabled,
                    scheme: scheme,
                    dayStyle: dayStyle,
                    localizations: localizations,
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _day({
    required DateTime? day,
    required int column,
    required bool rtl,
    required DateTime today,
    required DateTime? selected,
    required DateTime? rangeStart,
    required DateTime? rangeEnd,
    required double dayExtent,
    required double selectedExtent,
    required double dotSize,
    required double ringWidth,
    required Color rangeFill,
    required Color rangeText,
    required bool strikethroughDisabled,
    required ColorScheme scheme,
    required TextStyle dayStyle,
    required MaterialLocalizations localizations,
  }) {
    if (day == null) {
      return SizedBox(height: dayExtent);
    }

    final bool isSingleSelected = _sameDay(day, selected);
    final bool isRangeStart = _sameDay(day, rangeStart);
    final bool isRangeEnd = _sameDay(day, rangeEnd);
    final bool hasCompletedRange =
        rangeStart != null &&
        rangeEnd != null &&
        !_sameDay(rangeStart, rangeEnd);
    final bool isInRangeMiddle =
        hasCompletedRange && day.isAfter(rangeStart) && day.isBefore(rangeEnd);
    final bool isEndpoint = isSingleSelected || isRangeStart || isRangeEnd;

    final bool isToday = _sameDay(day, today);
    final bool canSelect = _canSelect(day);
    final bool focused =
        _gridFocused && _cursor != null && _sameDay(day, _cursor);

    final Color textColor = isEndpoint
        ? scheme.onPrimary
        : !canSelect
        ? scheme.onSurface.withValues(alpha: 0.30)
        : isInRangeMiddle
        ? rangeText
        : isToday
        ? scheme.primary
        : scheme.onSurface;

    // Seamless Airbnb/Wise continuous range connector behind the day circle.
    Widget? rangeBand;
    if (hasCompletedRange) {
      final double radius = selectedExtent / 2;
      if (isInRangeMiddle) {
        final bool roundStart = column == 0 || day.day == 1;
        final bool roundEnd =
            column == DateTime.daysPerWeek - 1 ||
            day.day == DateUtils.getDaysInMonth(day.year, day.month);
        rangeBand = SizedBox(
          height: selectedExtent,
          width: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: rangeFill,
              borderRadius: BorderRadiusDirectional.horizontal(
                start: roundStart ? Radius.circular(radius) : Radius.zero,
                end: roundEnd ? Radius.circular(radius) : Radius.zero,
              ).resolve(rtl ? TextDirection.rtl : TextDirection.ltr),
            ),
          ),
        );
      } else if (isRangeStart) {
        rangeBand = SizedBox(
          height: selectedExtent,
          width: double.infinity,
          child: Row(
            children: <Widget>[
              const Expanded(child: SizedBox.shrink()),
              Expanded(child: ColoredBox(color: rangeFill, child: const SizedBox.expand())),
            ],
          ),
        );
      } else if (isRangeEnd) {
        rangeBand = SizedBox(
          height: selectedExtent,
          width: double.infinity,
          child: Row(
            children: <Widget>[
              Expanded(child: ColoredBox(color: rangeFill, child: const SizedBox.expand())),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
        );
      }
    }

    final Widget face = SizedBox(
      height: dayExtent,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          ?rangeBand,
          Container(
            width: selectedExtent,
            height: selectedExtent,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isEndpoint ? scheme.primary : null,
              border: focused && !isEndpoint
                  ? Border.all(
                      color: scheme.onSurface.withValues(alpha: 0.45),
                      width: ringWidth,
                    )
                  : null,
            ),
            child: Text(
              '${day.day}',
              style: dayStyle.copyWith(
                color: textColor,
                fontWeight: isEndpoint || isToday
                    ? FontWeight.w700
                    : FontWeight.w500,
                decoration: (!canSelect && strikethroughDisabled && _isEnabled)
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: scheme.onSurface.withValues(alpha: 0.25),
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (isToday && !isEndpoint)
            Positioned(
              bottom: 5,
              child: Container(
                key: orionCalendarTodayDotKey,
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.primary,
                ),
              ),
            ),
        ],
      ),
    );

    return Semantics(
      container: true,
      button: true,
      selected: isEndpoint,
      enabled: canSelect,
      label: localizations.formatFullDate(day),
      child: canSelect
          ? OrionPressable(
              key: orionCalendarDayKey(day),
              onTap: () => _select(day),
              child: face,
            )
          : KeyedSubtree(key: orionCalendarDayKey(day), child: face),
    );
  }
}

class _Chevron extends StatelessWidget {
  const _Chevron({
    super.key,
    required this.icon,
    required this.label,
    required this.enabled,
    required this.scheme,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: OrionPressable(
        onTap: enabled ? onTap : null,
        child: SizedBox(
          width: OrionSizing.minHitTarget,
          height: OrionSizing.minHitTarget,
          child: Center(
            child: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: enabled
                    ? scheme.surfaceContainerHighest.withValues(alpha: 0.5)
                    : Colors.transparent,
                border: Border.all(
                  color: scheme.outlineVariant.withValues(
                    alpha: enabled ? 0.55 : 0.2,
                  ),
                ),
              ),
              child: Icon(
                icon,
                size: 20,
                color: enabled
                    ? scheme.onSurface
                    : scheme.onSurface.withValues(alpha: 0.30),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Weekdays extends StatelessWidget {
  const _Weekdays({
    required this.localizations,
    required this.style,
    required this.color,
  });

  final MaterialLocalizations localizations;
  final TextStyle? style;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final int first = localizations.firstDayOfWeekIndex;
    final List<String> names = localizations.narrowWeekdays;
    return Row(
      children: <Widget>[
        for (var index = 0; index < DateTime.daysPerWeek; index++)
          Expanded(
            child: Text(
              names[(first + index) % DateTime.daysPerWeek],
              key: ValueKey<String>('orion_calendar_weekday_$index'),
              textAlign: TextAlign.center,
              style: style?.copyWith(color: color),
            ),
          ),
      ],
    );
  }
}
