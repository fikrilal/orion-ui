import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button.dart';
import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/components/calendar/orion_calendar.dart';
import 'package:orion_ui/src/components/calendar/orion_calendar_style.dart';
import 'package:orion_ui/src/components/sheet/orion_bottom_sheet.dart';
import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_style.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Key for the sheet's reset / clear action.
const Key orionDatePickerResetKey = Key('orion_date_picker_reset');

/// Key for the sheet's cancel action.
const Key orionDatePickerCancelKey = Key('orion_date_picker_cancel');

/// Key for the sheet's confirm / apply action.
const Key orionDatePickerConfirmKey = Key('orion_date_picker_confirm');

/// Presents an [OrionDatePickerSheet] in single-day mode inside an
/// [OrionBottomSheet].
Future<DateTime?> showOrionDatePickerSheet({
  required BuildContext context,
  DateTime? initialDate,
  DateTime? firstDate,
  DateTime? lastDate,
  bool Function(DateTime day)? selectableDayPredicate,
  String title = 'Select date',
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  String? resetLabel,
  String? constraintMessage,
  OrionBottomSheetVariant variant = OrionBottomSheetVariant.floating,
  bool showCloseButton = true,
  bool isDismissible = true,
  bool useRootNavigator = true,
  OrionCalendarStyle? calendarStyle,
  OrionBottomSheetStyle? sheetStyle,
}) {
  return showOrionBottomSheet<DateTime>(
    context: context,
    fitContent: true,
    variant: variant,
    title: title,
    showCloseButton: showCloseButton,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    style: sheetStyle,
    builder: (BuildContext sheetContext, ScrollController scrollController) {
      return OrionDatePickerSheet.single(
        scrollController: scrollController,
        initialDate: initialDate,
        firstDate: firstDate,
        lastDate: lastDate,
        selectableDayPredicate: selectableDayPredicate,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        resetLabel: resetLabel,
        constraintMessage: constraintMessage,
        calendarStyle: calendarStyle,
        onCancel: () => OrionBottomSheet.dismissOf<DateTime>(sheetContext),
        onConfirmDate: (DateTime value) =>
            OrionBottomSheet.dismissOf<DateTime>(sheetContext, value),
      );
    },
  );
}

/// Presents an [OrionDatePickerSheet] in date-range mode inside an
/// [OrionBottomSheet], with clean start/end summary readouts.
Future<DateTimeRange?> showOrionDateRangePickerSheet({
  required BuildContext context,
  DateTimeRange? initialRange,
  DateTime? firstDate,
  DateTime? lastDate,
  int? minRangeDays,
  int? maxRangeDays,
  bool Function(DateTime day)? selectableDayPredicate,
  String title = 'Select dates',
  String startLabel = 'Start date',
  String endLabel = 'End date',
  String confirmLabel = 'Apply',
  String cancelLabel = 'Cancel',
  String? resetLabel = 'Clear',
  String? constraintMessage,
  OrionBottomSheetVariant variant = OrionBottomSheetVariant.floating,
  bool showCloseButton = true,
  bool isDismissible = true,
  bool useRootNavigator = true,
  OrionCalendarStyle? calendarStyle,
  OrionBottomSheetStyle? sheetStyle,
}) {
  return showOrionBottomSheet<DateTimeRange>(
    context: context,
    fitContent: true,
    variant: variant,
    title: title,
    showCloseButton: showCloseButton,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    style: sheetStyle,
    builder: (BuildContext sheetContext, ScrollController scrollController) {
      return OrionDatePickerSheet.range(
        scrollController: scrollController,
        initialRange: initialRange,
        firstDate: firstDate,
        lastDate: lastDate,
        minRangeDays: minRangeDays,
        maxRangeDays: maxRangeDays,
        selectableDayPredicate: selectableDayPredicate,
        startLabel: startLabel,
        endLabel: endLabel,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        resetLabel: resetLabel,
        constraintMessage: constraintMessage,
        calendarStyle: calendarStyle,
        onCancel: () => OrionBottomSheet.dismissOf<DateTimeRange>(sheetContext),
        onConfirmRange: (DateTimeRange range) =>
            OrionBottomSheet.dismissOf<DateTimeRange>(sheetContext, range),
      );
    },
  );
}

/// Composable date-picker sheet body combining a clean selection summary,
/// [OrionCalendar], and a sticky action footer.
class OrionDatePickerSheet extends StatefulWidget {
  /// Creates a single-day picker body.
  const OrionDatePickerSheet.single({
    super.key,
    this.scrollController,
    this.initialDate,
    this.firstDate,
    this.lastDate,
    this.selectableDayPredicate,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.resetLabel,
    this.constraintMessage,
    this.calendarStyle,
    this.onConfirmDate,
    this.onCancel,
  }) : mode = OrionCalendarSelectionMode.single,
       initialRange = null,
       minRangeDays = null,
       maxRangeDays = null,
       startLabel = 'Start date',
       endLabel = 'End date',
       onConfirmRange = null;

  /// Creates a date-range picker body.
  const OrionDatePickerSheet.range({
    super.key,
    this.scrollController,
    this.initialRange,
    this.firstDate,
    this.lastDate,
    this.minRangeDays,
    this.maxRangeDays,
    this.selectableDayPredicate,
    this.startLabel = 'Start date',
    this.endLabel = 'End date',
    this.confirmLabel = 'Apply',
    this.cancelLabel = 'Cancel',
    this.resetLabel = 'Clear',
    this.constraintMessage,
    this.calendarStyle,
    this.onConfirmRange,
    this.onCancel,
  }) : mode = OrionCalendarSelectionMode.range,
       initialDate = null,
       onConfirmDate = null;

  final ScrollController? scrollController;
  final OrionCalendarSelectionMode mode;
  final DateTime? initialDate;
  final DateTimeRange? initialRange;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final int? minRangeDays;
  final int? maxRangeDays;
  final bool Function(DateTime day)? selectableDayPredicate;
  final String startLabel;
  final String endLabel;
  final String confirmLabel;
  final String cancelLabel;
  final String? resetLabel;
  final String? constraintMessage;
  final OrionCalendarStyle? calendarStyle;
  final ValueChanged<DateTime>? onConfirmDate;
  final ValueChanged<DateTimeRange>? onConfirmRange;
  final VoidCallback? onCancel;

  @override
  State<OrionDatePickerSheet> createState() => _OrionDatePickerSheetState();
}

class _OrionDatePickerSheetState extends State<OrionDatePickerSheet> {
  DateTime? _selectedDate;
  DateTime? _rangeStart;
  DateTime? _rangeEnd;

  @override
  void initState() {
    super.initState();
    if (widget.mode == OrionCalendarSelectionMode.single) {
      _selectedDate = widget.initialDate == null
          ? null
          : _civil(widget.initialDate!);
    } else if (widget.initialRange != null) {
      DateTime s = _civil(widget.initialRange!.start);
      DateTime e = _civil(widget.initialRange!.end);
      if (e.isBefore(s)) {
        final DateTime tmp = s;
        s = e;
        e = tmp;
      }
      _rangeStart = s;
      _rangeEnd = e;
    }
  }

  DateTime _civil(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _hasSelection => switch (widget.mode) {
    OrionCalendarSelectionMode.single => _selectedDate != null,
    OrionCalendarSelectionMode.range =>
      _rangeStart != null || _rangeEnd != null,
  };

  bool get _hasValidSelection => switch (widget.mode) {
    OrionCalendarSelectionMode.single => _selectedDate != null,
    OrionCalendarSelectionMode.range =>
      _rangeStart != null && _rangeEnd != null,
  };

  int? get _rangeDayCount {
    if (_rangeStart == null || _rangeEnd == null) return null;
    return _rangeEnd!.difference(_rangeStart!).inDays.abs() + 1;
  }

  void _reset() {
    setState(() {
      _selectedDate = null;
      _rangeStart = null;
      _rangeEnd = null;
    });
  }

  void _confirm() {
    if (!_hasValidSelection) return;
    if (widget.mode == OrionCalendarSelectionMode.single) {
      if (widget.onConfirmDate != null) {
        widget.onConfirmDate!(_selectedDate!);
      } else {
        OrionBottomSheet.dismissOf<DateTime>(context, _selectedDate!);
      }
    } else {
      final DateTimeRange result = DateTimeRange(
        start: _rangeStart!,
        end: _rangeEnd!,
      );
      if (widget.onConfirmRange != null) {
        widget.onConfirmRange!(result);
      } else {
        OrionBottomSheet.dismissOf<DateTimeRange>(context, result);
      }
    }
  }

  void _cancel() {
    if (widget.onCancel != null) {
      widget.onCancel!();
    } else {
      OrionBottomSheet.dismissOf<void>(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final MaterialLocalizations localizations = MaterialLocalizations.of(
      context,
    );

    final bool pickingEnd =
        widget.mode == OrionCalendarSelectionMode.range &&
        _rangeStart != null &&
        _rangeEnd == null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Flexible(
          child: SingleChildScrollView(
            controller: widget.scrollController,
            padding: const EdgeInsets.symmetric(
              horizontal: OrionSpacing.space16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                // Clean active summary header
                if (widget.mode == OrionCalendarSelectionMode.range)
                  _RangeSummaryBar(
                    startLabel: widget.startLabel,
                    endLabel: widget.endLabel,
                    startDate: _rangeStart,
                    endDate: _rangeEnd,
                    pickingEnd: pickingEnd,
                    dayCount: _rangeDayCount,
                    localizations: localizations,
                  )
                else
                  _SingleSummaryBar(
                    selectedDate: _selectedDate,
                    localizations: localizations,
                  ),

                // Optional constraint message banner
                if (widget.constraintMessage != null &&
                    widget.constraintMessage!.trim().isNotEmpty) ...<Widget>[
                  const SizedBox(height: OrionSpacing.space12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space12,
                      vertical: OrionSpacing.space8,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.surfaceContainerHighest.withValues(
                        alpha: 0.55,
                      ),
                      borderRadius: BorderRadius.circular(OrionRadii.radius8),
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: OrionSpacing.space8),
                        Expanded(
                          child: Text(
                            widget.constraintMessage!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: OrionSpacing.space16),

                // Core OrionCalendar
                if (widget.mode == OrionCalendarSelectionMode.single)
                  OrionCalendar(
                    value: _selectedDate,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    selectableDayPredicate: widget.selectableDayPredicate,
                    style: widget.calendarStyle,
                    onChanged: (DateTime day) =>
                        setState(() => _selectedDate = day),
                  )
                else
                  OrionCalendar.range(
                    rangeStart: _rangeStart,
                    rangeEnd: _rangeEnd,
                    rangeValue: (_rangeStart != null && _rangeEnd != null)
                        ? DateTimeRange(start: _rangeStart!, end: _rangeEnd!)
                        : null,
                    firstDate: widget.firstDate,
                    lastDate: widget.lastDate,
                    minRangeDays: widget.minRangeDays,
                    maxRangeDays: widget.maxRangeDays,
                    selectableDayPredicate: widget.selectableDayPredicate,
                    style: widget.calendarStyle,
                    onRangeSelectionChanged: (DateTime? start, DateTime? end) {
                      setState(() {
                        _rangeStart = start;
                        _rangeEnd = end;
                      });
                    },
                  ),
                const SizedBox(height: OrionSpacing.space12),
              ],
            ),
          ),
        ),
        // Sticky action footer (always reachable even on compact viewports)
        Divider(
          height: 1,
          color: scheme.outlineVariant.withValues(alpha: 0.35),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(
            OrionSpacing.space16,
            OrionSpacing.space12,
            OrionSpacing.space16,
            OrionSpacing.space16,
          ),
          child: Row(
            children: <Widget>[
              if (widget.resetLabel != null &&
                  widget.resetLabel!.trim().isNotEmpty)
                OrionButton(
                  key: orionDatePickerResetKey,
                  label: widget.resetLabel!.trim(),
                  variant: OrionButtonVariant.flat,
                  size: OrionButtonSize.medium,
                  onPressed: _hasSelection ? _reset : null,
                ),
              const Spacer(),
              OrionButton(
                key: orionDatePickerCancelKey,
                label: widget.cancelLabel,
                variant: OrionButtonVariant.bordered,
                size: OrionButtonSize.medium,
                onPressed: _cancel,
              ),
              const SizedBox(width: OrionSpacing.space8),
              OrionButton(
                key: orionDatePickerConfirmKey,
                label: widget.confirmLabel,
                variant: OrionButtonVariant.solid,
                size: OrionButtonSize.medium,
                onPressed: _hasValidSelection ? _confirm : null,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SingleSummaryBar extends StatelessWidget {
  const _SingleSummaryBar({
    required this.selectedDate,
    required this.localizations,
  });

  final DateTime? selectedDate;
  final MaterialLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String text = selectedDate == null
        ? 'No date selected'
        : localizations.formatMediumDate(selectedDate!);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space12,
        vertical: OrionSpacing.space8,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(OrionRadii.radius12),
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.calendar_today_rounded,
            size: 16,
            color: selectedDate != null
                ? scheme.primary
                : scheme.onSurfaceVariant,
          ),
          const SizedBox(width: OrionSpacing.space8),
          Text(
            text,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: selectedDate != null
                  ? FontWeight.w600
                  : FontWeight.w400,
              color: selectedDate != null
                  ? scheme.onSurface
                  : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSummaryBar extends StatelessWidget {
  const _RangeSummaryBar({
    required this.startLabel,
    required this.endLabel,
    required this.startDate,
    required this.endDate,
    required this.pickingEnd,
    required this.dayCount,
    required this.localizations,
  });

  final String startLabel;
  final String endLabel;
  final DateTime? startDate;
  final DateTime? endDate;
  final bool pickingEnd;
  final int? dayCount;
  final MaterialLocalizations localizations;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    Widget slot({
      required String caption,
      required DateTime? date,
      required bool active,
      CrossAxisAlignment alignment = CrossAxisAlignment.start,
    }) {
      return Expanded(
        child: Column(
          crossAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              caption,
              style: theme.textTheme.labelSmall?.copyWith(
                color: active ? scheme.primary : scheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              date == null ? 'Add date' : localizations.formatMediumDate(date),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: date != null ? FontWeight.w600 : FontWeight.w400,
                color: date != null
                    ? scheme.onSurface
                    : scheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }

    return Row(
      children: <Widget>[
        slot(
          caption: startLabel,
          date: startDate,
          active: !pickingEnd && endDate == null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: OrionSpacing.space12),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 160),
            switchInCurve: Curves.easeOutCubic,
            switchOutCurve: Curves.easeInCubic,
            child: dayCount != null
                ? Container(
                    key: ValueKey<int>(dayCount!),
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: scheme.primary.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(
                        OrionRadii.radiusPill,
                      ),
                    ),
                    child: Text(
                      '$dayCount ${dayCount == 1 ? 'day' : 'days'}',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.primary,
                        fontWeight: FontWeight.w600,
                        fontFeatures: const <FontFeature>[
                          FontFeature.tabularFigures(),
                        ],
                      ),
                    ),
                  )
                : Icon(
                    Icons.arrow_forward_rounded,
                    key: const ValueKey<String>('arrow'),
                    size: 16,
                    color: scheme.onSurfaceVariant,
                  ),
          ),
        ),
        slot(
          caption: endLabel,
          date: endDate,
          active: pickingEnd,
          alignment: CrossAxisAlignment.end,
        ),
      ],
    );
  }
}
