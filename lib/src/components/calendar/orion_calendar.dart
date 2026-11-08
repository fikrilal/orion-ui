import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/calendar/orion_calendar_presets.dart';
import 'package:orion_ui/src/components/calendar/orion_calendar_style.dart';
import 'package:orion_ui/src/components/calendar/orion_calendar_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Key for the control that shows the previous month.
const Key orionCalendarPreviousMonthKey = Key('orion_calendar_previous_month');

/// Key for the control that shows the next month.
const Key orionCalendarNextMonthKey = Key('orion_calendar_next_month');

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

/// A single-month calendar.
///
/// The parent owns the selected civil day through [value] and [onChanged].
/// The calendar owns the visible month and the keyboard cursor. A pointer tap
/// commits. Arrow keys move the cursor, and Enter or Space commits it.
/// Changing month glides on a critically damped spring. The grid is always
/// six rows.
///
/// [value] is a civil day: the clock is ignored. [onChanged] is null when the
/// control is disabled. There is no range and no time.
class OrionCalendar extends StatefulWidget {
  /// Creates a calendar for one civil day.
  OrionCalendar({
    super.key,
    this.value,
    this.onChanged,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.initialMonth,
    this.label,
    this.style,
  }) : assert(
         _boundsAreOrdered(firstDate, lastDate),
         'firstDate must be on or before lastDate',
       );

  /// The selected civil day, or null when nothing is selected.
  ///
  /// The clock on this value is ignored.
  final DateTime? value;

  /// Called with the newly selected civil day.
  ///
  /// A null callback disables selection and month paging. The callback runs
  /// only when the civil day differs from [value].
  final ValueChanged<DateTime>? onChanged;

  /// The earliest selectable civil day, inclusive. Null leaves the past open
  /// back to year 1.
  final DateTime? firstDate;

  /// The latest selectable civil day, inclusive. Null leaves the future open
  /// through year 9999.
  final DateTime? lastDate;

  /// Extra days that stay visible but cannot be selected.
  final bool Function(DateTime day)? selectableDayPredicate;

  /// Month shown when [value] is null. Ignored once a day is selected.
  final DateTime? initialMonth;

  /// Optional caption above the month header.
  final String? label;

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

class _OrionCalendarState extends State<OrionCalendar>
    with SingleTickerProviderStateMixin {
  late DateTime _shown;
  DateTime? _incoming;
  DateTime? _cursor;
  int _direction = 1;
  bool _gridFocused = false;
  late final OrionSpringDriver _monthDriver;
  late final FocusNode _gridFocus;

  @override
  void initState() {
    super.initState();
    _shown = _initialMonth();
    _monthDriver = OrionSpringDriver(
      vsync: this,
      springSpec: OrionCalendarPresets.month,
      initialValue: 0,
    );
    _monthDriver.addStatusListener(_onMonthStatus);
    _gridFocus = FocusNode(debugLabel: 'OrionCalendar');
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final OrionCalendarStyle style = _resolve(Theme.of(context));
    final spec = style.spring ?? OrionCalendarPresets.month;
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
    final DateTime? next = widget.value == null ? null : _civil(widget.value!);
    final DateTime? previous = oldWidget.value == null
        ? null
        : _civil(oldWidget.value!);
    if (!_sameDay(next, previous)) {
      if (next != null) {
        _shown = _clampMonth(DateTime(next.year, next.month));
        _incoming = null;
        if (_gridFocus.hasFocus) {
          _cursor = _canSelect(next) ? next : _fallbackCursor(_shown);
        }
        // The parent rebuild already scheduled this frame. Jumping the driver
        // here would notify listeners during that build.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            _monthDriver.jumpTo(0);
          }
        });
      }
    }
    if (widget.onChanged == null) {
      _cursor = null;
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
    return OrionCalendarPresets.resolve()
        .merge(calendarTheme.defaultStyle)
        .merge(widget.style);
  }

  DateTime _initialMonth() {
    final DateTime seed = widget.value ?? widget.initialMonth ?? DateTime.now();
    return _clampMonth(DateTime(seed.year, seed.month));
  }

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

  bool _canSelect(DateTime day) {
    if (widget.onChanged == null || !_insideWindow(day)) {
      return false;
    }
    final bool Function(DateTime day)? predicate =
        widget.selectableDayPredicate;
    return predicate == null || predicate(_civil(day));
  }

  DateTime? _fallbackCursor(DateTime month) {
    final DateTime? selected = widget.value == null
        ? null
        : _civil(widget.value!);
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
      _incoming = null;
    });
    // The settled frame already shows [next]. The driver returns to 0
    // afterwards so the next nudge starts from rest, without a visual jump.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _monthDriver.jumpTo(0);
      }
    });
  }

  void _page(int delta) {
    if (widget.onChanged == null) {
      return;
    }
    final DateTime from = _destination;
    _pageTo(_clampMonth(DateTime(from.year, from.month + delta)));
  }

  void _pageTo(DateTime month) {
    if (widget.onChanged == null) {
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

  void _select(DateTime day) {
    if (!_canSelect(day)) {
      return;
    }
    final DateTime civil = _civil(day);
    if (!_gridFocus.hasFocus) {
      _cursor = civil;
      _gridFocus.requestFocus();
    }
    setState(() => _cursor = civil);
    if (_sameDay(civil, widget.value)) {
      return;
    }
    OrionHaptics.trigger(OrionHapticType.selectionClick);
    widget.onChanged!(civil);
  }

  void _handleFocus(bool focused) {
    _gridFocused = focused;
    if (focused && _cursor == null) {
      _cursor = _fallbackCursor(_destination);
    }
    setState(() {});
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (widget.onChanged == null) {
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionCalendarStyle style = _resolve(theme);
    final double dayExtent = style.dayExtent ?? OrionSizing.controlHeightMedium;
    final double selectedExtent = style.selectedExtent ?? 32;
    final double dotSize = style.todayDotSize ?? 3;
    final double slide = style.monthSlide ?? 12;
    final double exitSlide = style.monthExitSlide ?? 8;
    final double headerGap = style.headerGap ?? OrionSpacing.space8;
    final double weekdayGap = style.weekdayGap ?? OrionSpacing.space8;
    final double ringWidth = style.focusRingWidth ?? 1;
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );
    final bool enabled = widget.onChanged != null;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final DateTime titleMonth = _destination;
    final int slideSign = _direction * (rtl ? -1 : 1);
    final Widget shownGrid = _monthGrid(
      month: _shown,
      scheme: scheme,
      theme: theme,
      dayExtent: dayExtent,
      selectedExtent: selectedExtent,
      dotSize: dotSize,
      ringWidth: ringWidth,
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
            localizations: localizations,
          );

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        assert(
          constraints.hasBoundedWidth,
          'OrionCalendar needs a bounded width',
        );
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.label != null) ...<Widget>[
              Text(
                widget.label!,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurface,
                ),
              ),
              SizedBox(height: headerGap),
            ],
            Row(
              children: <Widget>[
                _Chevron(
                  key: orionCalendarPreviousMonthKey,
                  icon: rtl ? Icons.chevron_right : Icons.chevron_left,
                  label: 'Previous month',
                  enabled: enabled && _canStep(-1),
                  color: scheme.onSurface,
                  onTap: () => _page(-1),
                ),
                Expanded(
                  child: Text(
                    localizations.formatMonthYear(titleMonth),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: enabled
                          ? scheme.onSurface
                          : scheme.onSurface.withValues(alpha: 0.38),
                      fontFeatures: const <FontFeature>[
                        FontFeature.tabularFigures(),
                      ],
                    ),
                  ),
                ),
                _Chevron(
                  key: orionCalendarNextMonthKey,
                  icon: rtl ? Icons.chevron_left : Icons.chevron_right,
                  label: 'Next month',
                  enabled: enabled && _canStep(1),
                  color: scheme.onSurface,
                  onTap: () => _page(1),
                ),
              ],
            ),
            SizedBox(height: headerGap),
            _Weekdays(
              localizations: localizations,
              style: theme.textTheme.labelSmall,
              color: scheme.onSurfaceVariant,
            ),
            SizedBox(height: weekdayGap),
            Focus(
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
          ],
        );
      },
    );
  }

  bool _canStep(int delta) {
    final DateTime from = _destination;
    final DateTime target = _clampMonth(
      DateTime(from.year, from.month + delta),
    );
    return !_sameMonth(target, from);
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
    required MaterialLocalizations localizations,
  }) {
    final List<DateTime?> cells = _cells(month);
    final DateTime today = _civil(DateTime.now());
    final DateTime? selected = widget.value == null
        ? null
        : _civil(widget.value!);
    final TextStyle dayStyle =
        theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14);
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
                    today: today,
                    selected: selected,
                    dayExtent: dayExtent,
                    selectedExtent: selectedExtent,
                    dotSize: dotSize,
                    ringWidth: ringWidth,
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
    required DateTime today,
    required DateTime? selected,
    required double dayExtent,
    required double selectedExtent,
    required double dotSize,
    required double ringWidth,
    required ColorScheme scheme,
    required TextStyle dayStyle,
    required MaterialLocalizations localizations,
  }) {
    if (day == null) {
      return SizedBox(height: dayExtent);
    }
    final bool isSelected = _sameDay(day, selected);
    final bool isToday = _sameDay(day, today);
    final bool canSelect = _canSelect(day);
    final bool focused =
        _gridFocused && _cursor != null && _sameDay(day, _cursor);
    final Color textColor = isSelected
        ? scheme.onPrimary
        : canSelect
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);
    final Widget face = SizedBox(
      height: dayExtent,
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Container(
            width: selectedExtent,
            height: selectedExtent,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? scheme.primary : null,
              border: focused
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
                fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
              ),
            ),
          ),
          if (isToday && !isSelected)
            Positioned(
              bottom: 2,
              child: Container(
                key: orionCalendarTodayDotKey,
                width: dotSize,
                height: dotSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
        ],
      ),
    );
    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
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
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
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
          child: Icon(
            icon,
            color: enabled ? color : color.withValues(alpha: 0.38),
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
