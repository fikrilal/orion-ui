import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionSlider].
///
/// The Disabled flag in the top controls card drives every sample, the way the
/// design-system benchmark drives its samples from one panel; the sections
/// below are the reference matrices - free, stepped, driven, RTL, sizes,
/// skins - and the playground last drives one specimen through its axes with
/// the generated call behind the Code tab.
class OrionSliderShowcaseScreen extends StatefulWidget {
  const OrionSliderShowcaseScreen({super.key});

  @override
  State<OrionSliderShowcaseScreen> createState() =>
      _OrionSliderShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _SliderSkin { standard, thin, thick }

class _OrionSliderShowcaseScreenState extends State<OrionSliderShowcaseScreen> {
  // Flag: shared by every sample on the page.
  bool _disabled = false;

  // Live samples.
  double _volume = 0.4;
  double _rating = 3;
  double _driven = 0.25;
  double _mirrored = 0.5;
  final Map<OrionSliderSize, double> _sized = <OrionSliderSize, double>{
    OrionSliderSize.small: 0.3,
    OrionSliderSize.medium: 0.5,
    OrionSliderSize.large: 0.7,
  };
  double _skinned = 0.6;

  // Playground: the focused specimen's own axes.
  double _playgroundValue = 0.5;
  double? _playgroundStep;
  OrionSliderSize _playgroundSize = OrionSliderSize.medium;
  _SliderSkin _skin = _SliderSkin.standard;

  /// One sample under the shared flag.
  OrionSlider _sample({
    required double value,
    required String semanticLabel,
    double min = 0,
    double max = 1,
    double? step,
    ValueChanged<double>? onChanged,
    OrionSliderSize size = OrionSliderSize.medium,
    OrionSliderStyle? style,
  }) {
    return OrionSlider(
      value: value,
      min: min,
      max: max,
      step: step,
      semanticLabel: semanticLabel,
      size: size,
      onChanged: _disabled ? null : (onChanged ?? (_) {}),
      style: style,
    );
  }

  OrionSliderStyle? _skinStyle() => switch (_skin) {
    _SliderSkin.standard => null,
    _SliderSkin.thin => OrionSliderStyle.from(trackHeight: 2),
    _SliderSkin.thick => OrionSliderStyle.from(trackHeight: 8),
  };

  String _skinLabel(_SliderSkin skin) => switch (skin) {
    _SliderSkin.standard => 'Standard',
    _SliderSkin.thin => 'Thin',
    _SliderSkin.thick => 'Thick',
  };

  String _sizeLabel(OrionSliderSize size) => switch (size) {
    OrionSliderSize.small => 'Small',
    OrionSliderSize.medium => 'Medium',
    OrionSliderSize.large => 'Large',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionSlider(',
      '  value: ${_playgroundValue.toStringAsFixed(2)},',
    ];
    if (_playgroundStep != null) {
      lines.add('  step: $_playgroundStep,');
    }
    if (_playgroundSize != OrionSliderSize.medium) {
      lines.add('  size: OrionSliderSize.${_playgroundSize.name},');
    }
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else {
      lines.add(
        '  onChanged: (value) => '
        'setState(() => _playgroundValue = value),',
      );
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Slider',
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Intro Header
            Padding(
              padding: const EdgeInsets.only(bottom: OrionSpacing.space20),
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
                      'CONTINUOUS • DRAG & SETTLE',
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
                    'Precision horizontal slider. Follows the pointer exactly during drag without lag; spring settles release to the nearest step. Ignores vertical parent scroll gestures.',
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
            const SizedBox(height: OrionSpacing.space24),

            // Free Card
            OrionShowcaseSection(
              title: 'Free',
              subtitle:
                  'Continuous slider following the pointer exactly on every drag update',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sample(
                    value: _volume,
                    semanticLabel: 'Volume',
                    onChanged: (double value) =>
                        setState(() => _volume = value),
                  ),
                  _Readout(label: 'Volume', value: _volume.toStringAsFixed(2)),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Stepped Card
            OrionShowcaseSection(
              title: 'Stepped',
              subtitle:
                  'Discrete steps: thumb follows drag smoothly, then springs to nearest step on release',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sample(
                    value: _rating,
                    min: 0,
                    max: 5,
                    step: 0.5,
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
              title: 'Driven from outside',
              subtitle:
                  'Programmatically updated value settles cleanly without overshoot',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sample(
                    value: _driven,
                    semanticLabel: 'Progress',
                    onChanged: (double value) =>
                        setState(() => _driven = value),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Row(
                    children: [
                      OrionButton(
                        variant: OrionButtonVariant.bordered,
                        size: OrionButtonSize.small,
                        onPressed: _disabled
                            ? null
                            : () => setState(() => _driven = 0),
                        child: const Text('Empty'),
                      ),
                      const SizedBox(width: OrionSpacing.space8),
                      OrionButton(
                        variant: OrionButtonVariant.bordered,
                        size: OrionButtonSize.small,
                        onPressed: _disabled
                            ? null
                            : () => setState(() => _driven = 1),
                        child: const Text('Full'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Right to left Card
            OrionShowcaseSection(
              title: 'Right to left',
              subtitle:
                  'Directionality-aware layout reversing drag and keyboard arrow directions',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Directionality(
                    textDirection: TextDirection.rtl,
                    child: _sample(
                      value: _mirrored,
                      semanticLabel: 'Mirrored',
                      onChanged: (double value) =>
                          setState(() => _mirrored = value),
                    ),
                  ),
                  _Readout(
                    label: 'Mirrored',
                    value: _mirrored.toStringAsFixed(2),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small, Medium, and Large stepped track and thumb geometry under 44 pt target',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
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
                  'Three-layer style contract: Presets -> OrionSliderTheme -> Instance OrionSliderStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_SliderSkin>(
                    label: 'Skin',
                    values: _SliderSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    value: _skinned,
                    semanticLabel: 'Volume',
                    style: _skinStyle(),
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
              subtitle: 'Interactive slider with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space16,
                        vertical: OrionSpacing.space24,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(OrionRadii.radius12),
                        border: Border.all(
                          color: isDark
                              ? scheme.outlineVariant.withValues(alpha: 0.15)
                              : scheme.outlineVariant.withValues(alpha: 0.30),
                          width: 1,
                        ),
                      ),
                      child: _sample(
                        value: _playgroundValue,
                        step: _playgroundStep,
                        size: _playgroundSize,
                        semanticLabel: 'Value',
                        onChanged: (double value) =>
                            setState(() => _playgroundValue = value),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),

                    OrionShowcaseChoice<double?>(
                      label: 'Step',
                      values: const <double?>[null, 0.5],
                      selected: _playgroundStep,
                      labelOf: _stepLabel,
                      onChanged: (value) =>
                          setState(() => _playgroundStep = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseChoice<OrionSliderSize>(
                      label: 'Size',
                      values: OrionSliderSize.values,
                      selected: _playgroundSize,
                      labelOf: _sizeLabel,
                      onChanged: (value) =>
                          setState(() => _playgroundSize = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseValueSlider(
                      label: 'Value',
                      value: _playgroundValue,
                      min: 0,
                      max: 1,
                      step: 0.05,
                      display: _playgroundValue.toStringAsFixed(2),
                      onChanged: (value) =>
                          setState(() => _playgroundValue = value),
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

  String _stepLabel(double? step) => step == null ? 'None' : 'Half';
}

/// The slider owns no label, so the page composes the readout a screen would.
class _Readout extends StatelessWidget {
  const _Readout({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: OrionSpacing.space8),
      child: Text(
        '$label $value',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}
