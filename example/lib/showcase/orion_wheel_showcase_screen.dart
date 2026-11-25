import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground and verification showcase for [OrionWheelPicker].
class OrionWheelShowcaseScreen extends StatefulWidget {
  const OrionWheelShowcaseScreen({super.key});

  @override
  State<OrionWheelShowcaseScreen> createState() =>
      _OrionWheelShowcaseScreenState();
}

enum _PlaygroundDataset { months, minutes }

class _OrionWheelShowcaseScreenState extends State<OrionWheelShowcaseScreen> {
  static const List<String> _months = <String>[
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static const List<int> _daysInMonth = <int>[
    31,
    28,
    31,
    30,
    31,
    30,
    31,
    31,
    30,
    31,
    30,
    31,
  ];

  // 1. Hero Interactive Playground state
  _PlaygroundDataset _dataset = _PlaygroundDataset.months;
  int _playgroundMonthIndex = 2;
  int _livePlaygroundMonthIndex = 2;
  int _playgroundMinute = 30;
  int _livePlaygroundMinute = 30;
  OrionWheelSelectionStyle _selectionStyle = OrionWheelSelectionStyle.pill;
  int _visibleCount = 5;
  bool _looping = true;
  bool _cylinder3d = true;
  bool _edgeFade = true;
  bool _disabled = false;

  // 2. Looping Time Picker state (live header + settled values)
  int _hour = 9;
  int _minute = 30;
  String _meridiem = 'AM';
  int _liveHour = 9;
  int _liveMinute = 30;
  String _liveMeridiem = 'AM';

  // 3. Dynamic Dependent Date Columns state (Month + Day)
  int _dateMonth = 0; // January (31 days) -> try rolling to February (28 days)
  int _dateDay = 31;

  // 4. Precision Hairlines Odometer state
  int _precisionReps = 12;

  List<OrionWheelItem<String>> get _monthItems => <OrionWheelItem<String>>[
    for (final String month in _months)
      OrionWheelItem<String>(value: month, label: Text(month)),
  ];

  List<OrionWheelItem<int>> get _minuteItems => <OrionWheelItem<int>>[
    for (int m = 0; m < 60; m++)
      OrionWheelItem<int>(
        value: m,
        label: Text(m.toString().padLeft(2, '0')),
        semanticLabel: '$m minutes',
      ),
  ];

  List<OrionWheelItem<int>> get _hourItems => <OrionWheelItem<int>>[
    for (int h = 1; h <= 12; h++)
      OrionWheelItem<int>(
        value: h,
        label: Text(h.toString().padLeft(2, '0')),
        semanticLabel: '$h o-clock',
      ),
  ];

  List<OrionWheelItem<String>> get _meridiemItems =>
      const <OrionWheelItem<String>>[
        OrionWheelItem<String>(value: 'AM', label: Text('AM')),
        OrionWheelItem<String>(value: 'PM', label: Text('PM')),
      ];

  List<OrionWheelItem<int>> _dayItemsForMonth(int monthIndex) {
    final int count = _daysInMonth[monthIndex];
    return <OrionWheelItem<int>>[
      for (int d = 1; d <= count; d++)
        OrionWheelItem<int>(value: d, label: Text('$d')),
    ];
  }

  String get _playgroundDisplay => _dataset == _PlaygroundDataset.months
      ? _months[_livePlaygroundMonthIndex]
      : '${_livePlaygroundMinute.toString().padLeft(2, '0')} min';

  OrionWheelPickerStyle get _playgroundStyle => OrionWheelPickerStyle.from(
    selectionStyle: _selectionStyle,
    perspective: _cylinder3d ? 0.003 : 0.0,
    edgeScale: _cylinder3d ? 0.7 : 1.0,
    edgeFade: _edgeFade,
  );

  String get _snippet {
    final List<String> lines = <String>[
      _dataset == _PlaygroundDataset.months
          ? 'OrionWheelPicker<String>('
          : 'OrionWheelPicker<int>(',
      _dataset == _PlaygroundDataset.months
          ? '  items: monthItems,'
          : '  items: minuteItems,',
      _dataset == _PlaygroundDataset.months
          ? "  value: '${_months[_playgroundMonthIndex]}',"
          : '  value: $_playgroundMinute,',
    ];
    if (_visibleCount != 5) {
      lines.add('  visibleItemCount: $_visibleCount,');
    }
    if (_looping) {
      lines.add('  looping: true,');
    }
    if (_selectionStyle != OrionWheelSelectionStyle.pill ||
        !_cylinder3d ||
        !_edgeFade) {
      lines.add('  style: OrionWheelPickerStyle.from(');
      if (_selectionStyle != OrionWheelSelectionStyle.pill) {
        lines.add(
          '    selectionStyle: OrionWheelSelectionStyle.${_selectionStyle.name},',
        );
      }
      if (!_cylinder3d) {
        lines.add('    perspective: 0.0,');
        lines.add('    edgeScale: 1.0,');
      }
      if (!_edgeFade) {
        lines.add('    edgeFade: false,');
      }
      lines.add('  ),');
    }
    lines.add(
      _disabled
          ? '  onChanged: null, // disabled'
          : '  onChanged: (value) => setState(() => selected = value),',
    );
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final Color stageBg = isDark
        ? scheme.surfaceContainer
        : scheme.surfaceContainerHighest.withValues(alpha: 0.45);
    final Color stageBorder = scheme.outlineVariant;
    final Color unifiedPillBg = scheme.onSurface.withValues(
      alpha: isDark ? 0.10 : 0.06,
    );

    return OrionThemedScaffold(
      title: 'Orion Wheel',
      builder: (BuildContext context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Top Intro Header
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
                            ? scheme.outlineVariant.withValues(alpha: 0.25)
                            : scheme.outlineVariant.withValues(alpha: 0.50),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'PICKER • 3D CYLINDER DRUM',
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
                    'Cylindrical 3D drum picker on a single retargeted spring. '
                    'Features infinite looping, touch-to-catch momentum, asymptotic '
                    'rubber-banding, mouse-wheel scroll, translucent selection loupe, '
                    'and background-agnostic edge fade.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // 1. Hero Interactive Playground
            OrionShowcaseSection(
              title: 'Interactive Playground',
              subtitle:
                  'Flick, catch mid-spin, scroll with mouse wheel, or tap rows to inspect 3D perspective, looping, and loupe styles.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                code: _snippet,
                preview: Column(
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space16,
                        vertical: OrionSpacing.space20,
                      ),
                      decoration: BoxDecoration(
                        color: stageBg,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(color: stageBorder),
                      ),
                      child: Column(
                        children: <Widget>[
                          SizedBox(
                            width: 240,
                            child: _dataset == _PlaygroundDataset.months
                                ? OrionWheelPicker<String>(
                                    key: const ValueKey<String>(
                                      'showcase-wheel-playground-months',
                                    ),
                                    items: _monthItems,
                                    value: _months[_playgroundMonthIndex],
                                    visibleItemCount: _visibleCount,
                                    looping: _looping,
                                    semanticLabel: 'Month',
                                    style: _playgroundStyle,
                                    onActiveChanged: (String m) {
                                      setState(
                                        () => _livePlaygroundMonthIndex =
                                            _months.indexOf(m),
                                      );
                                    },
                                    onChanged: _disabled
                                        ? null
                                        : (String m) {
                                            final int idx = _months.indexOf(m);
                                            setState(() {
                                              _playgroundMonthIndex = idx;
                                              _livePlaygroundMonthIndex = idx;
                                            });
                                          },
                                  )
                                : OrionWheelPicker<int>(
                                    key: const ValueKey<String>(
                                      'showcase-wheel-playground-minutes',
                                    ),
                                    items: _minuteItems,
                                    value: _playgroundMinute,
                                    visibleItemCount: _visibleCount,
                                    looping: _looping,
                                    semanticLabel: 'Minutes',
                                    style: _playgroundStyle,
                                    onActiveChanged: (int m) {
                                      setState(() => _livePlaygroundMinute = m);
                                    },
                                    onChanged: _disabled
                                        ? null
                                        : (int m) {
                                            setState(() {
                                              _playgroundMinute = m;
                                              _livePlaygroundMinute = m;
                                            });
                                          },
                                  ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            'Selected: $_playgroundDisplay',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseControls(
                      children: <Widget>[
                        OrionShowcaseChoice<_PlaygroundDataset>(
                          label: 'Dataset',
                          selected: _dataset,
                          values: _PlaygroundDataset.values,
                          labelOf: (_PlaygroundDataset d) => switch (d) {
                            _PlaygroundDataset.months => 'Months (12)',
                            _PlaygroundDataset.minutes => 'Minutes (60)',
                          },
                          onChanged: (_PlaygroundDataset d) =>
                              setState(() => _dataset = d),
                        ),
                        OrionShowcaseChoice<OrionWheelSelectionStyle>(
                          label: 'Selection Indicator',
                          selected: _selectionStyle,
                          values: OrionWheelSelectionStyle.values,
                          labelOf: (OrionWheelSelectionStyle s) => switch (s) {
                            OrionWheelSelectionStyle.pill => 'Pill',
                            OrionWheelSelectionStyle.hairlines => 'Hairlines',
                            OrionWheelSelectionStyle.none => 'None',
                          },
                          onChanged: (OrionWheelSelectionStyle s) =>
                              setState(() => _selectionStyle = s),
                        ),
                        OrionShowcaseChoice<int>(
                          label: 'Visible Slots',
                          selected: _visibleCount,
                          values: const <int>[3, 5, 7],
                          labelOf: (int c) => '$c Slots',
                          onChanged: (int c) =>
                              setState(() => _visibleCount = c),
                        ),
                        OrionShowcaseToggle(
                          label: 'Infinite Looping',
                          value: _looping,
                          onChanged: (bool v) => setState(() => _looping = v),
                        ),
                        OrionShowcaseToggle(
                          label: '3D Cylinder Perspective',
                          value: _cylinder3d,
                          onChanged: (bool v) =>
                              setState(() => _cylinder3d = v),
                        ),
                        OrionShowcaseToggle(
                          label: 'Edge Fade Mask',
                          value: _edgeFade,
                          onChanged: (bool v) => setState(() => _edgeFade = v),
                        ),
                        OrionShowcaseToggle(
                          label: 'Disabled',
                          value: _disabled,
                          onChanged: (bool v) => setState(() => _disabled = v),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // 2. Looping Time Picker (Multi-Column Unified Loupe)
            OrionShowcaseSection(
              title: 'Looping Time Picker',
              subtitle:
                  'Three coordinated columns sharing one continuous selection bar with live onActiveChanged readout.',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-time'),
                code: '''
Stack(
  alignment: Alignment.center,
  children: [
    // Shared translucent loupe bar across all columns
    Container(height: 40, decoration: BoxDecoration(...)),
    Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(width: 68, child: OrionWheelPicker<int>(looping: true, ...)),
        const Text(':'),
        SizedBox(width: 68, child: OrionWheelPicker<int>(looping: true, ...)),
        SizedBox(width: 72, child: OrionWheelPicker<String>(...)),
      ],
    ),
  ],
)''',
                preview: Column(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space12,
                        vertical: OrionSpacing.space4,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radiusPill,
                        ),
                      ),
                      child: Text(
                        '${_liveHour.toString().padLeft(2, '0')}:'
                        '${_liveMinute.toString().padLeft(2, '0')} '
                        '$_liveMeridiem',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                          color: scheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space12,
                        vertical: OrionSpacing.space12,
                      ),
                      decoration: BoxDecoration(
                        color: stageBg,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(color: stageBorder),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: 244,
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              Positioned(
                                left: 0,
                                right: 0,
                                height: 40,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: unifiedPillBg,
                                    borderRadius: BorderRadius.circular(
                                      OrionRadii.radius8,
                                    ),
                                  ),
                                ),
                              ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: <Widget>[
                                  SizedBox(
                                    width: 72,
                                    child: OrionWheelPicker<int>(
                                      items: _hourItems,
                                      value: _hour,
                                      looping: true,
                                      semanticLabel: 'Hour',
                                      style: OrionWheelPickerStyle.from(
                                        selectionStyle:
                                            OrionWheelSelectionStyle.none,
                                        offAxisFraction: -0.35,
                                      ),
                                      onActiveChanged: (int v) =>
                                          setState(() => _liveHour = v),
                                      onChanged: _disabled
                                          ? null
                                          : (int v) => setState(() {
                                              _hour = v;
                                              _liveHour = v;
                                            }),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 2),
                                    child: Text(
                                      ':',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: scheme.onSurface,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                    width: 72,
                                    child: OrionWheelPicker<int>(
                                      items: _minuteItems,
                                      value: _minute,
                                      looping: true,
                                      semanticLabel: 'Minute',
                                      style: OrionWheelPickerStyle.from(
                                        selectionStyle:
                                            OrionWheelSelectionStyle.none,
                                      ),
                                      onActiveChanged: (int v) =>
                                          setState(() => _liveMinute = v),
                                      onChanged: _disabled
                                          ? null
                                          : (int v) => setState(() {
                                              _minute = v;
                                              _liveMinute = v;
                                            }),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  SizedBox(
                                    width: 72,
                                    child: OrionWheelPicker<String>(
                                      items: _meridiemItems,
                                      value: _meridiem,
                                      semanticLabel: 'Period',
                                      style: OrionWheelPickerStyle.from(
                                        selectionStyle:
                                            OrionWheelSelectionStyle.none,
                                        offAxisFraction: 0.35,
                                      ),
                                      onActiveChanged: (String v) =>
                                          setState(() => _liveMeridiem = v),
                                      onChanged: _disabled
                                          ? null
                                          : (String v) => setState(() {
                                              _meridiem = v;
                                              _liveMeridiem = v;
                                            }),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // 3. Dynamic Dependent Month + Day Wheels (Joined Pill Radii)
            OrionShowcaseSection(
              title: 'Dynamic Dependent Columns',
              subtitle:
                  'Joined selectionRadius pills with a Day column that safely clamps from 31 → 28 when rolling into February.',
              card: true,
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space12,
                      vertical: OrionSpacing.space12,
                    ),
                    decoration: BoxDecoration(
                      color: stageBg,
                      borderRadius: BorderRadius.circular(OrionRadii.radius12),
                      border: Border.all(color: stageBorder),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          SizedBox(
                            width: 152,
                            child: OrionWheelPicker<String>(
                              items: _monthItems,
                              value: _months[_dateMonth],
                              looping: true,
                              semanticLabel: 'Date Month',
                              style: OrionWheelPickerStyle.from(
                                offAxisFraction: -0.25,
                                selectionRadius: const BorderRadius.horizontal(
                                  left: Radius.circular(OrionRadii.radius8),
                                ),
                              ),
                              onChanged: _disabled
                                  ? null
                                  : (String month) {
                                      setState(() {
                                        _dateMonth = _months.indexOf(month);
                                        final int maxDay =
                                            _daysInMonth[_dateMonth];
                                        if (_dateDay > maxDay) {
                                          _dateDay = maxDay;
                                        }
                                      });
                                    },
                            ),
                          ),
                          SizedBox(
                            width: 84,
                            child: OrionWheelPicker<int>(
                              items: _dayItemsForMonth(_dateMonth),
                              value: _dateDay,
                              semanticLabel: 'Date Day',
                              style: OrionWheelPickerStyle.from(
                                offAxisFraction: 0.25,
                                selectionRadius: const BorderRadius.horizontal(
                                  right: Radius.circular(OrionRadii.radius8),
                                ),
                              ),
                              onChanged: _disabled
                                  ? null
                                  : (int day) => setState(() => _dateDay = day),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Text(
                    'Selected: ${_months[_dateMonth]} $_dateDay '
                    '(${_daysInMonth[_dateMonth]} days)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // 4. Precision Hairlines & Dense Style
            OrionShowcaseSection(
              title: 'Precision Hairlines & Compact Drum',
              subtitle:
                  'Minimal top/bottom hairline rules with compact 36 pt row extent and 7 visible slots.',
              card: true,
              child: Column(
                children: <Widget>[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      vertical: OrionSpacing.space12,
                    ),
                    decoration: BoxDecoration(
                      color: stageBg,
                      borderRadius: BorderRadius.circular(OrionRadii.radius12),
                      border: Border.all(color: stageBorder),
                    ),
                    child: Center(
                      child: SizedBox(
                        width: 160,
                        child: OrionWheelPicker<int>(
                          items: <OrionWheelItem<int>>[
                            for (int i = 1; i <= 30; i++)
                              OrionWheelItem<int>(
                                value: i,
                                label: Text('$i reps'),
                              ),
                          ],
                          value: _precisionReps,
                          visibleItemCount: 7,
                          semanticLabel: 'Repetitions',
                          style: OrionWheelPickerStyle.from(
                            itemExtent: 36,
                            selectionStyle: OrionWheelSelectionStyle.hairlines,
                            selectedColor: scheme.primary,
                          ),
                          onChanged: _disabled
                              ? null
                              : (int v) => setState(() => _precisionReps = v),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Text(
                    'Target: $_precisionReps reps',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
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
