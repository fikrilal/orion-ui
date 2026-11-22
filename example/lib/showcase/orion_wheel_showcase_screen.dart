import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionWheelPicker].
///
/// The page itself scrolls, and the wheels in it take their own vertical drags,
/// so the page is scrolled from outside a wheel. That is the documented contract
/// of the component rather than a bug in the page: a picker claims the drag that
/// starts on it.
///
/// The `Disabled` flag at the top drives every wheel, the sections below are the
/// reference matrices - a month list, a number list, and a seven-slot wheel -
/// and the playground last carries the focused wheel with its item set and
/// value, generating the call it stands for behind the Code tab.
class OrionWheelShowcaseScreen extends StatefulWidget {
  const OrionWheelShowcaseScreen({super.key});

  @override
  State<OrionWheelShowcaseScreen> createState() =>
      _OrionWheelShowcaseScreenState();
}

/// The item sets the playground can drive.
enum _WheelItems { months, numbers }

/// The instance-level skins the customization section demonstrates.
enum _WheelSkin { standard, dense, accent }

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

  // Flag: shared by every wheel on the page.
  bool _disabled = false;

  int _month = 2;
  int _repetitions = 8;
  int _sevenSlot = 5;

  // Playground: the focused wheel's own axes.
  _WheelItems _playgroundItems = _WheelItems.months;
  int _playgroundIndex = 2;

  // Customization: the focused skin and its specimen.
  _WheelSkin _skin = _WheelSkin.standard;
  int _skinned = 6;

  List<OrionWheelItem<String>> get _monthItems => <OrionWheelItem<String>>[
    for (final String month in _months)
      OrionWheelItem<String>(value: month, label: Text(month)),
  ];

  List<OrionWheelItem<int>> get _numberItems => <OrionWheelItem<int>>[
    for (int value = 1; value <= 12; value++)
      OrionWheelItem<int>(value: value, label: Text('$value')),
  ];

  OrionWheelPickerStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _WheelSkin.standard => null,
    _WheelSkin.dense => OrionWheelPickerStyle.from(itemExtent: 32),
    _WheelSkin.accent => OrionWheelPickerStyle.from(
      selectedColor: scheme.primary,
      focusRingColor: scheme.primary,
    ),
  };

  String _skinLabel(_WheelSkin skin) => switch (skin) {
    _WheelSkin.standard => 'Standard',
    _WheelSkin.dense => 'Dense',
    _WheelSkin.accent => 'Accent',
  };

  /// The playground's current value list, in wheel order.
  List<String> get _playgroundValues => switch (_playgroundItems) {
    _WheelItems.months => _months,
    _WheelItems.numbers => <String>[
      for (int value = 1; value <= 12; value++) '$value',
    ],
  };

  /// One wheel under the shared flag.
  OrionWheelPicker<T> _sample<T>({
    required List<OrionWheelItem<T>> items,
    required T value,
    required ValueChanged<T> onChanged,
    String? semanticLabel,
    int visibleItemCount = 5,
  }) {
    return OrionWheelPicker<T>(
      items: items,
      value: value,
      visibleItemCount: visibleItemCount,
      semanticLabel: semanticLabel,
      onChanged: _disabled ? null : onChanged,
    );
  }

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[];
    if (_playgroundItems == _WheelItems.months) {
      lines.addAll(<String>[
        'OrionWheelPicker<String>(',
        '  items: <OrionWheelItem<String>>[',
        '    for (final String month in _months)',
        '      OrionWheelItem<String>(value: month, label: Text(month)),',
        '  ],',
        "  value: '${_months[_playgroundIndex]}',",
      ]);
    } else {
      lines.addAll(<String>[
        'OrionWheelPicker<int>(',
        '  items: <OrionWheelItem<int>>[',
        '    for (int value = 1; value <= 12; value++)',
        "      OrionWheelItem<int>(value: value, label: Text('\$value')),",
        '  ],',
        '  value: ${_playgroundIndex + 1},',
      ]);
    }
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else if (_playgroundItems == _WheelItems.months) {
      lines.add('  onChanged: (String month) => _onMonthChanged(month),');
    } else {
      lines.add('  onChanged: (int value) => _onNumberChanged(value),');
    }
    lines.add(');');
    return lines.join('\n');
  }

  /// The focused wheel, on the playground's item set and value.
  Widget get _playgroundWheel => switch (_playgroundItems) {
    _WheelItems.months => OrionWheelPicker<String>(
      key: const ValueKey<String>('showcase-wheel-playground'),
      items: _monthItems,
      value: _months[_playgroundIndex],
      semanticLabel: 'Month',
      onChanged: _disabled
          ? null
          : (String month) =>
                setState(() => _playgroundIndex = _months.indexOf(month)),
    ),
    _WheelItems.numbers => OrionWheelPicker<int>(
      key: const ValueKey<String>('showcase-wheel-playground'),
      items: _numberItems,
      value: _playgroundIndex + 1,
      semanticLabel: 'Number',
      onChanged: _disabled
          ? null
          : (int value) => setState(() => _playgroundIndex = value - 1),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Wheel',
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Intro Header
            Padding(
              padding: const EdgeInsets.only(bottom: 2.00),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space8,
                      vertical: OrionSpacing.space4,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? scheme.onSurface.withValues(alpha: 0.10)
                          : scheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
                      border: Border.all(
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.20)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'PICKER • VELOCITY PROJECTION',
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
                    'Vertical wheel picker on a single retargeted spring. Exact direct finger drag with release velocity projecting into settling detents. Haptic selection click on crossings.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            OrionShowcaseControls(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: OrionShowcaseToggle(
                        label: 'Disabled',
                        value: _disabled,
                        onChanged: (value) => setState(() => _disabled = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2.04),

            // Month Card
            OrionShowcaseSection(
              title: 'Month',
              subtitle:
                  'Text option wheel with standard 5-slot visible height and 44 pt rows',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240,
                    child: _sample<String>(
                      items: _monthItems,
                      value: _months[_month],
                      semanticLabel: 'Month',
                      onChanged: (String month) =>
                          setState(() => _month = _months.indexOf(month)),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Text(
                    'Selected: ${_months[_month]}',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Number Card
            OrionShowcaseSection(
              title: 'Number',
              subtitle:
                  'Numeric wheel odometer settling critically damped onto selected integer',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 120,
                    child: _sample<int>(
                      items: _numberItems,
                      value: _repetitions,
                      semanticLabel: 'Repetitions',
                      onChanged: (int value) =>
                          setState(() => _repetitions = value),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Text(
                    'Selected: $_repetitions',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Seven slots Card
            OrionShowcaseSection(
              title: 'Seven slots',
              subtitle:
                  'Extended 7-slot visible band with edge scaling for deep option columns',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 240,
                    child: _sample<int>(
                      items: _numberItems,
                      value: _sevenSlot,
                      visibleItemCount: 7,
                      semanticLabel: 'Stage',
                      onChanged: (int value) =>
                          setState(() => _sevenSlot = value),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Text(
                    'Selected: Stage $_sevenSlot',
                    style: textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: scheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionWheelPickerTheme -> Instance OrionWheelPickerStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_WheelSkin>(
                    label: 'Skin',
                    values: _WheelSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  SizedBox(
                    width: 120,
                    child: OrionWheelPicker<int>(
                      items: _numberItems,
                      value: _skinned,
                      semanticLabel: 'Skinned',
                      style: _skinStyle(Theme.of(context).colorScheme),
                      onChanged: _disabled
                          ? null
                          : (int value) => setState(() => _skinned = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive wheel with switchable datasets and live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrionShowcaseChoice<_WheelItems>(
                      label: 'Items',
                      values: _WheelItems.values,
                      selected: _playgroundItems,
                      labelOf: _itemsLabel,
                      onChanged: (value) => setState(() {
                        _playgroundItems = value;
                        _playgroundIndex = _playgroundIndex.clamp(
                          0,
                          _playgroundValues.length - 1,
                        );
                      }),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseValueSlider(
                      label: 'Value',
                      value: _playgroundIndex.toDouble(),
                      min: 0,
                      max: (_playgroundValues.length - 1).toDouble(),
                      step: 1,
                      display: _playgroundValues[_playgroundIndex],
                      onChanged: (value) =>
                          setState(() => _playgroundIndex = value.round()),
                    ),
                    const SizedBox(height: 2.04),
                    Center(
                      child: SizedBox(width: 240, child: _playgroundWheel),
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
          ],
        );
      },
    );
  }

  String _itemsLabel(_WheelItems items) => switch (items) {
    _WheelItems.months => 'Months',
    _WheelItems.numbers => 'Numbers',
  };
}
