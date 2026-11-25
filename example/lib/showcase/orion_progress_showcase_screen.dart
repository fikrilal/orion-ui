import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for the progress family: [OrionLinearProgress],
/// [OrionSegmentedProgress], and [OrionCircularProgress].
class OrionProgressShowcaseScreen extends StatefulWidget {
  const OrionProgressShowcaseScreen({super.key});

  @override
  State<OrionProgressShowcaseScreen> createState() =>
      _OrionProgressShowcaseScreenState();
}

class _OrionProgressShowcaseScreenState
    extends State<OrionProgressShowcaseScreen> {
  static const int _maxPlaygroundCount = 8;
  static const double _playgroundStep = 0.5;

  // Steps sample
  int _step = 1;

  // Live linear & circular sample
  double? _linearValue = 0.35;
  double _bufferedValue = 0.65;

  // Playground: segmented specimen controls
  int _playgroundCount = 4;
  double _playgroundValue = 2;
  OrionProgressTone _tone = OrionProgressTone.primary;

  void _incrementCount() {
    setState(() {
      _playgroundCount += 1;
    });
  }

  void _decrementCount() {
    setState(() {
      _playgroundCount -= 1;
      if (_playgroundValue > _playgroundCount) {
        _playgroundValue = _playgroundCount.toDouble();
      }
    });
  }

  void _incrementValue() => setState(() => _playgroundValue += _playgroundStep);

  void _decrementValue() => setState(() => _playgroundValue -= _playgroundStep);

  void _advanceLinear() {
    setState(() {
      final double current = _linearValue ?? 0.0;
      final double next = (current + 0.2).clamp(0.0, 1.0);
      _linearValue = next;
      if (_bufferedValue < next) {
        _bufferedValue = (next + 0.15).clamp(0.0, 1.0);
      }
    });
  }

  void _advanceBuffer() {
    setState(() {
      _linearValue ??= 0.2;
      _bufferedValue = (_bufferedValue + 0.2).clamp(0.0, 1.0);
    });
  }

  String _toneLabel(OrionProgressTone tone) => switch (tone) {
    OrionProgressTone.primary => 'Primary',
    OrionProgressTone.success => 'Success',
    OrionProgressTone.warning => 'Warning',
    OrionProgressTone.error => 'Error',
  };

  /// The exact call the current controls produce.
  String get _snippet => <String>[
    'OrionSegmentedProgress(',
    '  count: $_playgroundCount,',
    '  value: ${_formatValue(_playgroundValue)},',
    if (_tone != OrionProgressTone.primary)
      '  tone: OrionProgressTone.${_tone.name},',
    ')',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Orion Progress',
      builder: (context) {
        final TextTheme textTheme = Theme.of(context).textTheme;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final bool isDark = Theme.of(context).brightness == Brightness.dark;
        final int linearPercent = ((_linearValue ?? 0.0) * 100).round();

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
                      'INDICATOR • LINEAR • SEGMENTED • CIRCULAR',
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
                    'Segmented, linear, and circular progress indicators with critically damped fills, smooth buffer animation, semantic tones, and reduced-motion fallbacks.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Interactive Linear & Circular Card
            OrionShowcaseSection(
              title: 'Linear & Circular (Interactive)',
              subtitle:
                  'Live critically-damped fill and buffer springs with indeterminate toggle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      OrionCircularProgress(
                        value: _linearValue,
                        tone: _linearValue == 1.0
                            ? OrionProgressTone.success
                            : _tone,
                        size: 56,
                        strokeWidth: 4.5,
                        child: _linearValue == null
                            ? null
                            : _linearValue == 1.0
                            ? Icon(
                                Icons.check_rounded,
                                size: 22,
                                color: OrionProgressStyle.resolveToneColor(
                                  scheme: scheme,
                                  tone: OrionProgressTone.success,
                                ),
                              )
                            : Text(
                                '$linearPercent%',
                                style: textTheme.labelSmall?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: scheme.onSurface,
                                  fontFeatures: const <FontFeature>[
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                              ),
                      ),
                      const SizedBox(width: OrionSpacing.space16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _linearValue == null
                                      ? 'Preparing upload…'
                                      : _linearValue == 1.0
                                      ? 'Upload complete'
                                      : 'Uploading assets',
                                  style: textTheme.labelMedium?.copyWith(
                                    color: scheme.onSurface,
                                  ),
                                ),
                                Text(
                                  _linearValue == null
                                      ? '—'
                                      : '$linearPercent%',
                                  style: textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontFeatures: const <FontFeature>[
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: OrionSpacing.space8),
                            OrionLinearProgress(
                              value: _linearValue,
                              bufferedValue: _bufferedValue,
                              tone: _linearValue == 1.0
                                  ? OrionProgressTone.success
                                  : _tone,
                              style: OrionProgressStyle.from(height: 6),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Wrap(
                    spacing: OrionSpacing.space8,
                    runSpacing: OrionSpacing.space8,
                    children: [
                      OrionButton(
                        size: OrionButtonSize.small,
                        onPressed: _advanceLinear,
                        child: const Text('+20%'),
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: _advanceBuffer,
                        child: const Text('+Buffer'),
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => setState(() {
                          _linearValue = _linearValue == null ? 0.25 : null;
                        }),
                        child: Text(
                          _linearValue == null
                              ? 'Determinate'
                              : 'Indeterminate',
                        ),
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: () => setState(() {
                          _linearValue = 0.0;
                          _bufferedValue = 0.2;
                        }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Circular Spinners & Tones Card
            OrionShowcaseSection(
              title: 'Circular & Semantic Tones',
              subtitle:
                  'Determinate rings, C1-smooth indeterminate spinners, and status tones',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: const [
                      OrionCircularProgress(size: 24, strokeWidth: 3),
                      OrionCircularProgress(
                        value: 0.72,
                        tone: OrionProgressTone.primary,
                      ),
                      OrionCircularProgress(
                        value: 1.0,
                        tone: OrionProgressTone.success,
                      ),
                      OrionCircularProgress(
                        value: 0.65,
                        tone: OrionProgressTone.warning,
                      ),
                      OrionCircularProgress(
                        value: 0.35,
                        tone: OrionProgressTone.error,
                      ),
                    ],
                  ),
                  const SizedBox(height: OrionSpacing.space20),
                  const OrionLinearProgress(
                    value: 0.85,
                    tone: OrionProgressTone.success,
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  const OrionLinearProgress(
                    value: 0.55,
                    tone: OrionProgressTone.warning,
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  const OrionLinearProgress(
                    value: 0.30,
                    tone: OrionProgressTone.error,
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Steps Card
            OrionShowcaseSection(
              title: 'Steps',
              subtitle:
                  'Equal discrete segments filling incrementally with step actions',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionSegmentedProgress(count: 4, value: _step.toDouble()),
                  const SizedBox(height: OrionSpacing.space16),
                  Row(
                    children: [
                      OrionButton(
                        size: OrionButtonSize.small,
                        onPressed: _step >= 4
                            ? null
                            : () => setState(() => _step += 1),
                        child: const Text('Next'),
                      ),
                      const SizedBox(width: OrionSpacing.space8),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: _step <= 0
                            ? null
                            : () => setState(() => _step = 0),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Partial & Indeterminate Card
            OrionShowcaseSection(
              title: 'Partial & Indeterminate',
              subtitle:
                  'Fractional segmented progress and pill-capped indeterminate linear sweep',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OrionSegmentedProgress(count: 5, value: 2.5),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionLinearProgress(
                    style: OrionProgressStyle.from(height: 6),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive segment count, value, and tone controls with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(OrionSpacing.space24),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surface
                            : scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: OrionSegmentedProgress(
                        count: _playgroundCount,
                        value: _playgroundValue,
                        tone: _tone,
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),

                    OrionShowcaseChoice<OrionProgressTone>(
                      label: 'Tone',
                      values: OrionProgressTone.values,
                      selected: _tone,
                      labelOf: _toneLabel,
                      onChanged: (value) => setState(() => _tone = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseLabeledRow(
                      label: 'Count',
                      child: _Stepper(
                        display: '$_playgroundCount',
                        decrementLabel: 'Decrease count',
                        incrementLabel: 'Increase count',
                        onDecrement: _playgroundCount <= 1
                            ? null
                            : _decrementCount,
                        onIncrement: _playgroundCount >= _maxPlaygroundCount
                            ? null
                            : _incrementCount,
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseLabeledRow(
                      label: 'Value',
                      child: _Stepper(
                        display: _formatValue(_playgroundValue),
                        decrementLabel: 'Decrease value',
                        incrementLabel: 'Increase value',
                        onDecrement: _playgroundValue <= 0
                            ? null
                            : _decrementValue,
                        onIncrement: _playgroundValue >= _playgroundCount
                            ? null
                            : _incrementValue,
                      ),
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

  String _formatValue(double value) => value == value.roundToDouble()
      ? value.toInt().toString()
      : value.toString();
}

/// A small stepper built from the kit's own button.
class _Stepper extends StatelessWidget {
  const _Stepper({
    required this.display,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String display;
  final String decrementLabel;
  final String incrementLabel;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OrionButton(
          variant: OrionButtonVariant.bordered,
          size: OrionButtonSize.small,
          semanticLabel: decrementLabel,
          onPressed: onDecrement,
          child: const Text('−'),
        ),
        const SizedBox(width: OrionSpacing.space12),
        Text(display, style: textTheme.bodySmall),
        const SizedBox(width: OrionSpacing.space12),
        OrionButton(
          variant: OrionButtonVariant.bordered,
          size: OrionButtonSize.small,
          semanticLabel: incrementLabel,
          onPressed: onIncrement,
          child: const Text('+'),
        ),
      ],
    );
  }
}
