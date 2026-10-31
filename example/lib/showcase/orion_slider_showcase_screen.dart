import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionSlider] and [OrionRangeSlider].
///
/// The `Disabled` flag in the top controls card gates every sample; the
/// sections below showcase live tooltips & track tap, dual-thumb
/// [OrionRangeSlider], stepped ticks with detent haptics, externally driven
/// settles, sizes, custom thumb/track skins, and a full interactive playground.
class OrionSliderShowcaseScreen extends StatefulWidget {
  const OrionSliderShowcaseScreen({super.key});

  @override
  State<OrionSliderShowcaseScreen> createState() =>
      _OrionSliderShowcaseScreenState();
}

enum _SliderSkin { standard, elevated, thin, thick }

enum _PlaygroundMode { single, range }

class _OrionSliderShowcaseScreenState extends State<OrionSliderShowcaseScreen> {
  // Flag: shared by every sample on the page.
  bool _disabled = false;

  // Live samples.
  double _volume = 0.45;
  double _committedVolume = 0.45;
  RangeValues _priceRange = const RangeValues(75, 350);
  RangeValues _committedPriceRange = const RangeValues(75, 350);
  double _rating = 3.0;
  double _driven = 0.25;
  final Map<OrionSliderSize, double> _sized = <OrionSliderSize, double>{
    OrionSliderSize.small: 0.3,
    OrionSliderSize.medium: 0.5,
    OrionSliderSize.large: 0.7,
  };
  double _skinned = 0.6;
  _SliderSkin _skin = _SliderSkin.standard;

  // Playground axes.
  _PlaygroundMode _mode = _PlaygroundMode.single;
  double _playgroundValue = 0.5;
  RangeValues _playgroundRange = const RangeValues(0.25, 0.75);
  double? _playgroundStep = 0.25;
  OrionSliderSize _playgroundSize = OrionSliderSize.medium;
  OrionSliderValueIndicator _playgroundIndicator =
      OrionSliderValueIndicator.onDrag;
  bool _playgroundTicks = true;
  bool _playgroundTrackTap = true;

  OrionSlider _sample({
    required double value,
    required String semanticLabel,
    double min = 0,
    double max = 1,
    double? step,
    bool showTicks = false,
    OrionSliderValueIndicator showValueIndicator =
        OrionSliderValueIndicator.never,
    String Function(double value)? valueLabelBuilder,
    bool allowTrackTap = false,
    ValueChanged<double>? onChanged,
    ValueChanged<double>? onChangeEnd,
    OrionSliderSize size = OrionSliderSize.medium,
    OrionSliderStyle? style,
  }) {
    return OrionSlider(
      value: value,
      min: min,
      max: max,
      step: step,
      showTicks: showTicks,
      showValueIndicator: showValueIndicator,
      valueLabelBuilder: valueLabelBuilder,
      allowTrackTap: allowTrackTap,
      semanticLabel: semanticLabel,
      size: size,
      onChanged: _disabled ? null : (onChanged ?? (_) {}),
      onChangeEnd: _disabled ? null : onChangeEnd,
      style: style,
    );
  }

  OrionSliderStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _SliderSkin.standard => null,
    _SliderSkin.elevated => OrionSliderStyle(
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? scheme.surfaceContainerHighest
            : scheme.surface,
      ),
      thumbBorder: BorderSide(color: scheme.primary, width: 2),
      thumbShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x22000000),
          blurRadius: 6,
          offset: Offset(0, 2),
        ),
      ],
      thumbSize: 22,
      trackHeight: 5,
    ),
    _SliderSkin.thin => OrionSliderStyle.from(trackHeight: 2),
    _SliderSkin.thick => OrionSliderStyle.from(trackHeight: 8, thumbSize: 22),
  };

  String _skinLabel(_SliderSkin skin) => switch (skin) {
    _SliderSkin.standard => 'Standard',
    _SliderSkin.elevated => 'Elevated',
    _SliderSkin.thin => 'Thin',
    _SliderSkin.thick => 'Thick',
  };

  String _sizeLabel(OrionSliderSize size) => switch (size) {
    OrionSliderSize.small => 'Small',
    OrionSliderSize.medium => 'Medium',
    OrionSliderSize.large => 'Large',
  };

  String _modeLabel(_PlaygroundMode mode) => switch (mode) {
    _PlaygroundMode.single => 'Single',
    _PlaygroundMode.range => 'Range',
  };

  String _stepLabel(double? step) => switch (step) {
    null => 'None',
    0.25 => '0.25',
    0.1 => '0.1',
    _ => step.toString(),
  };

  String _indicatorLabel(OrionSliderValueIndicator mode) => switch (mode) {
    OrionSliderValueIndicator.never => 'Never',
    OrionSliderValueIndicator.onDrag => 'On Drag',
    OrionSliderValueIndicator.always => 'Always',
  };

  /// The exact call the current playground controls produce.
  String get _snippet {
    final bool isRange = _mode == _PlaygroundMode.range;
    final List<String> lines = <String>[
      isRange ? 'OrionRangeSlider(' : 'OrionSlider(',
      if (isRange)
        '  values: RangeValues(${_playgroundRange.start.toStringAsFixed(2)}, ${_playgroundRange.end.toStringAsFixed(2)}),'
      else
        '  value: ${_playgroundValue.toStringAsFixed(2)},',
    ];
    if (_playgroundStep != null) {
      lines.add('  step: $_playgroundStep,');
      if (_playgroundTicks) {
        lines.add('  showTicks: true,');
      }
    }
    if (_playgroundIndicator != OrionSliderValueIndicator.never) {
      lines.add(
        '  showValueIndicator: OrionSliderValueIndicator.${_playgroundIndicator.name},',
      );
    }
    if (_playgroundTrackTap) {
      lines.add('  allowTrackTap: true,');
    }
    if (_playgroundSize != OrionSliderSize.medium) {
      lines.add('  size: OrionSliderSize.${_playgroundSize.name},');
    }
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else if (isRange) {
      lines.add('  onChanged: (values) => setState(() => _range = values),');
    } else {
      lines.add('  onChanged: (value) => setState(() => _value = value),');
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Slider',
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
                            ? scheme.outlineVariant.withValues(alpha: 0.20)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'CONTINUOUS & RANGE • DRAG, HAPTICS & SETTLE',
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
                    'Precision single and dual-thumb sliders. Exact 1:1 drag tracking, detent and bound haptics, discrete tick marks, floating value pills, and critically damped settles.',
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
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(
                      child: OrionShowcaseToggle(
                        label: 'Disabled',
                        value: _disabled,
                        onChanged: (bool value) =>
                            setState(() => _disabled = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Continuous + Tooltip + Track Tap Card
            OrionShowcaseSection(
              title: 'Continuous & Value Bubble',
              subtitle:
                  'Live pill tooltip while dragging, opt-in track tap, and committed onChangeEnd callback',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    value: _volume,
                    semanticLabel: 'Volume',
                    allowTrackTap: true,
                    showValueIndicator: OrionSliderValueIndicator.onDrag,
                    valueLabelBuilder: (double v) => '${(v * 100).round()}%',
                    onChanged: (double value) =>
                        setState(() => _volume = value),
                    onChangeEnd: (double value) =>
                        setState(() => _committedVolume = value),
                  ),
                  _Readout(
                    label: 'Live ${(100 * _volume).round()}%',
                    value: 'Committed ${(100 * _committedVolume).round()}%',
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Range Slider Card
            OrionShowcaseSection(
              title: 'Range Slider',
              subtitle:
                  'Dual-thumb OrionRangeSlider with minSpan separation, ticks, and detent haptics',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: OrionSpacing.space16),
                  OrionRangeSlider(
                    values: _priceRange,
                    min: 0,
                    max: 500,
                    step: 25,
                    minSpan: 50,
                    showTicks: true,
                    showValueIndicator: OrionSliderValueIndicator.onDrag,
                    valueLabelBuilder: (double v) => '\$${v.round()}',
                    semanticLabel: 'Price range',
                    onChanged: _disabled
                        ? null
                        : (RangeValues values) =>
                              setState(() => _priceRange = values),
                    onChangeEnd: _disabled
                        ? null
                        : (RangeValues values) =>
                              setState(() => _committedPriceRange = values),
                  ),
                  _Readout(
                    label:
                        'Range \$${_priceRange.start.round()} – \$${_priceRange.end.round()}',
                    value:
                        'Committed \$${_committedPriceRange.start.round()} – \$${_committedPriceRange.end.round()}',
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Stepped with Ticks Card
            OrionShowcaseSection(
              title: 'Stepped with Ticks',
              subtitle:
                  'Discrete step dots, per-detent selection haptics, and spring snap on release',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    value: _rating,
                    min: 0,
                    max: 5,
                    step: 0.5,
                    showTicks: true,
                    showValueIndicator: OrionSliderValueIndicator.onDrag,
                    valueLabelBuilder: (double v) => v.toStringAsFixed(1),
                    semanticLabel: 'Rating',
                    onChanged: (double value) =>
                        setState(() => _rating = value),
                  ),
                  _Readout(label: 'Rating', value: _rating.toStringAsFixed(1)),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Driven from outside Card
            OrionShowcaseSection(
              title: 'Driven from Outside',
              subtitle:
                  'Programmatically updated value settles cleanly without overshoot',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _sample(
                    value: _driven,
                    semanticLabel: 'Progress',
                    onChanged: (double value) =>
                        setState(() => _driven = value),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Row(
                    children: <Widget>[
                      OrionButton(
                        variant: OrionButtonVariant.bordered,
                        size: OrionButtonSize.small,
                        onPressed: _disabled
                            ? null
                            : () => setState(() => _driven = 0),
                        child: const Text('0%'),
                      ),
                      const SizedBox(width: OrionSpacing.space8),
                      OrionButton(
                        variant: OrionButtonVariant.bordered,
                        size: OrionButtonSize.small,
                        onPressed: _disabled
                            ? null
                            : () => setState(() => _driven = 0.5),
                        child: const Text('50%'),
                      ),
                      const SizedBox(width: OrionSpacing.space8),
                      OrionButton(
                        variant: OrionButtonVariant.bordered,
                        size: OrionButtonSize.small,
                        onPressed: _disabled
                            ? null
                            : () => setState(() => _driven = 1),
                        child: const Text('100%'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small, Medium, and Large track & thumb steps under a 44 pt hit target',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final OrionSliderSize size
                      in OrionSliderSize.values) ...<Widget>[
                    OrionShowcaseLabeledRow(
                      label: _sizeLabel(size),
                      child: _sample(
                        value: _sized[size]!,
                        semanticLabel: '${_sizeLabel(size)} volume',
                        size: size,
                        onChanged: (double value) =>
                            setState(() => _sized[size] = value),
                      ),
                    ),
                    if (size != OrionSliderSize.values.last)
                      const SizedBox(height: OrionSpacing.space12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'State-aware OrionSliderStyle skins with custom thumb border, shadow, and track thickness',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseChoice<_SliderSkin>(
                    label: 'Skin',
                    values: _SliderSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (_SliderSkin value) =>
                        setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    value: _skinned,
                    semanticLabel: 'Volume',
                    allowTrackTap: true,
                    style: _skinStyle(scheme),
                    onChanged: (double value) =>
                        setState(() => _skinned = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Switch single vs range mode, ticks, tooltips, and track tap with live code',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(
                        OrionSpacing.space16,
                        OrionSpacing.space40,
                        OrionSpacing.space16,
                        OrionSpacing.space20,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.15)
                              : scheme.outlineVariant.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: _mode == _PlaygroundMode.single
                          ? _sample(
                              value: _playgroundValue,
                              step: _playgroundStep,
                              size: _playgroundSize,
                              showTicks: _playgroundTicks,
                              showValueIndicator: _playgroundIndicator,
                              allowTrackTap: _playgroundTrackTap,
                              valueLabelBuilder: (double v) =>
                                  '${(v * 100).round()}%',
                              semanticLabel: 'Value',
                              onChanged: (double value) =>
                                  setState(() => _playgroundValue = value),
                            )
                          : OrionRangeSlider(
                              values: _playgroundRange,
                              step: _playgroundStep,
                              minSpan: _playgroundStep ?? 0.1,
                              size: _playgroundSize,
                              showTicks: _playgroundTicks,
                              showValueIndicator: _playgroundIndicator,
                              allowTrackTap: _playgroundTrackTap,
                              valueLabelBuilder: (double v) =>
                                  '${(v * 100).round()}%',
                              semanticLabel: 'Range value',
                              onChanged: _disabled
                                  ? null
                                  : (RangeValues values) => setState(
                                      () => _playgroundRange = values,
                                    ),
                            ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),
                    OrionShowcaseChoice<_PlaygroundMode>(
                      label: 'Mode',
                      values: _PlaygroundMode.values,
                      selected: _mode,
                      labelOf: _modeLabel,
                      onChanged: (_PlaygroundMode value) =>
                          setState(() => _mode = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseChoice<double?>(
                      label: 'Step',
                      values: const <double?>[null, 0.25, 0.1],
                      selected: _playgroundStep,
                      labelOf: _stepLabel,
                      onChanged: (double? value) =>
                          setState(() => _playgroundStep = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseChoice<OrionSliderValueIndicator>(
                      label: 'Tooltip',
                      values: OrionSliderValueIndicator.values,
                      selected: _playgroundIndicator,
                      labelOf: _indicatorLabel,
                      onChanged: (OrionSliderValueIndicator value) =>
                          setState(() => _playgroundIndicator = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseChoice<OrionSliderSize>(
                      label: 'Size',
                      values: OrionSliderSize.values,
                      selected: _playgroundSize,
                      labelOf: _sizeLabel,
                      onChanged: (OrionSliderSize value) =>
                          setState(() => _playgroundSize = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Show ticks',
                            value: _playgroundTicks,
                            onChanged: (bool value) =>
                                setState(() => _playgroundTicks = value),
                          ),
                        ),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Track tap',
                            value: _playgroundTrackTap,
                            onChanged: (bool value) =>
                                setState(() => _playgroundTrackTap = value),
                          ),
                        ),
                      ],
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
}

class _Readout extends StatelessWidget {
  const _Readout({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: OrionSpacing.space8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
