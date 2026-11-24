import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground for [OrionCalendar], [showOrionDatePickerSheet], and
/// [showOrionDateRangePickerSheet].
class OrionCalendarShowcaseScreen extends StatefulWidget {
  const OrionCalendarShowcaseScreen({super.key});

  @override
  State<OrionCalendarShowcaseScreen> createState() =>
      _OrionCalendarShowcaseScreenState();
}

enum _CalendarDemoMode { single, range }

class _OrionCalendarShowcaseScreenState
    extends State<OrionCalendarShowcaseScreen> {
  _CalendarDemoMode _mode = _CalendarDemoMode.range;
  bool _blockWeekends = false;

  DateTime _singleDate = DateTime(2026, 11, 22);
  DateTimeRange? _rangeDate = DateTimeRange(
    start: DateTime(2026, 11, 18),
    end: DateTime(2026, 11, 25),
  );

  DateTime? _sheetSingleDate;
  DateTimeRange? _sheetRangeDate;

  final TextEditingController _singleField = TextEditingController();
  final TextEditingController _rangeField = TextEditingController();

  @override
  void dispose() {
    _singleField.dispose();
    _rangeField.dispose();
    super.dispose();
  }

  bool _predicate(DateTime day) {
    if (!_blockWeekends) return true;
    return day.weekday != DateTime.saturday && day.weekday != DateTime.sunday;
  }

  Future<void> _openSingleSheet() async {
    final MaterialLocalizations loc = MaterialLocalizations.of(context);
    final DateTime? picked = await showOrionDatePickerSheet(
      context: context,
      initialDate: _sheetSingleDate ?? DateTime.now(),
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      selectableDayPredicate: _predicate,
      title: 'Schedule transfer',
      resetLabel: 'Clear',
      confirmLabel: 'Confirm',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _sheetSingleDate = picked;
      _singleField.text = loc.formatMediumDate(picked);
    });
  }

  Future<void> _openRangeSheet() async {
    final MaterialLocalizations loc = MaterialLocalizations.of(context);
    final DateTimeRange? picked = await showOrionDateRangePickerSheet(
      context: context,
      initialRange: _sheetRangeDate,
      firstDate: DateTime(2020, 1, 1),
      lastDate: DateTime(2030, 12, 31),
      minRangeDays: 2,
      maxRangeDays: 60,
      title: 'Filter statement',
      startLabel: 'From',
      endLabel: 'To',
      constraintMessage: 'Select between 2 and 60 days.',
      confirmLabel: 'Apply range',
    );
    if (!mounted || picked == null) return;
    setState(() {
      _sheetRangeDate = picked;
      _rangeField.text =
          '${loc.formatMediumDate(picked.start)} – ${loc.formatMediumDate(picked.end)}';
    });
  }

  String get _snippet {
    if (_mode == _CalendarDemoMode.single) {
      return '''OrionCalendar(
  value: _selectedDate,
  onChanged: (DateTime day) => setState(() => _selectedDate = day),
);''';
    }
    return '''OrionCalendar.range(
  rangeValue: _range,
  onRangeChanged: (DateTimeRange? range) => setState(() => _range = range),
);''';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final MaterialLocalizations loc = MaterialLocalizations.of(context);

    return OrionThemedScaffold(
      title: 'Orion Calendar',
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Intro header
            Padding(
              padding: const EdgeInsets.only(bottom: OrionSpacing.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space8,
                      vertical: OrionSpacing.space4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.onSurface.withValues(alpha: 0.10)
                          : scheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(
                        OrionRadii.radiusPill,
                      ),
                      border: Border.all(
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.20)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'INPUT • SINGLE, RANGE & PICKER SHEETS',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.8,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space8),
                  Text(
                    'Swipeable month grid with inline month/year quick-jump, Today shortcut, Airbnb-style continuous range strips, and Wise-style modal picker sheets with quick presets.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Playground
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Swipe horizontally across dates or tap the Month Year pill to jump years',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(OrionSpacing.space16),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius16,
                        ),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.15)
                              : scheme.outlineVariant.withValues(alpha: 0.30),
                        ),
                      ),
                      child: _mode == _CalendarDemoMode.single
                          ? OrionCalendar(
                              key: const Key('showcase-calendar-inline'),
                              value: _singleDate,
                              selectableDayPredicate: _predicate,
                              onChanged: (DateTime day) =>
                                  setState(() => _singleDate = day),
                            )
                          : OrionCalendar.range(
                              key: const Key('showcase-calendar-range'),
                              rangeValue: _rangeDate,
                              selectableDayPredicate: _predicate,
                              onRangeChanged: (DateTimeRange? range) =>
                                  setState(() => _rangeDate = range),
                            ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Text(
                      _mode == _CalendarDemoMode.single
                          ? 'Selected: ${loc.formatMediumDate(_singleDate)}'
                          : _rangeDate == null
                          ? 'Selected range: —'
                          : 'Selected range: ${loc.formatMediumDate(_rangeDate!.start)} → ${loc.formatMediumDate(_rangeDate!.end)} (${_rangeDate!.duration.inDays + 1} days)',
                      key: const Key('showcase-calendar-readout'),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseChoice<_CalendarDemoMode>(
                      label: 'Selection mode',
                      values: _CalendarDemoMode.values,
                      selected: _mode,
                      labelOf: (_CalendarDemoMode m) =>
                          m == _CalendarDemoMode.single ? 'Single' : 'Range',
                      onChanged: (_CalendarDemoMode m) =>
                          setState(() => _mode = m),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseToggle(
                      label: 'Block weekends (strikethrough)',
                      value: _blockWeekends,
                      onChanged: (bool value) =>
                          setState(() => _blockWeekends = value),
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Modal Date Picker Sheets
            OrionShowcaseSection(
              title: 'Modal Date Picker Sheets',
              subtitle:
                  'Floating OrionBottomSheet with live summary bar and validation',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  OrionTextField(
                    key: const Key('showcase-calendar-single-field'),
                    controller: _singleField,
                    readOnly: true,
                    label: 'Single date',
                    hint: 'Select transfer date',
                    suffix: const Icon(Icons.calendar_today_outlined, size: 18),
                    onTap: _openSingleSheet,
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionTextField(
                    key: const Key('showcase-calendar-range-field'),
                    controller: _rangeField,
                    readOnly: true,
                    label: 'Date range',
                    hint: 'Select statement period',
                    suffix: const Icon(Icons.date_range_rounded, size: 18),
                    onTap: _openRangeSheet,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
