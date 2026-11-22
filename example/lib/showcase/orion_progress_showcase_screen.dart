import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for the progress family.
///
/// The step, partial, empty, linear and indeterminate samples stay as
/// reference sections - the sweeping bar runs forever - and the playground
/// last steps `count`/`value` with small steppers and generates the call
/// behind the Code tab.
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

  // Steps sample: the running one near the top of the page.
  int _step = 1;

  // Playground: the focused specimen's own axes.
  int _playgroundCount = 4;
  double _playgroundValue = 2;

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

  /// The exact call the current controls produce.
  String get _snippet => <String>[
    'OrionSegmentedProgress(',
    '  count: $_playgroundCount,',
    '  value: ${_formatValue(_playgroundValue)},',
    ')',
  ].join('\n');

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Orion Progress',
      builder: (context) {
        // Read under the scaffold so the theme toggle reaches every sample.
        final TextTheme textTheme = Theme.of(context).textTheme;
        final ColorScheme scheme = Theme.of(context).colorScheme;
        final bool isDark = Theme.of(context).brightness == Brightness.dark;

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
                      'INDICATOR • CRITICALLY DAMPED',
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
                    'Segmented progress and continuous linear bars. Fills settle on critically damped springs (zeta 1.0) so progress never wobbles or overshoots.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

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
                  OrionButton(
                    size: OrionButtonSize.small,
                    onPressed: _step >= 4
                        ? null
                        : () => setState(() => _step += 1),
                    child: const Text('Next'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Partial Card
            const OrionShowcaseSection(
              title: 'Partial',
              subtitle: 'Fractional values filling the final segment partially',
              card: true,
              child: OrionSegmentedProgress(count: 5, value: 2.5),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Empty Card
            const OrionShowcaseSection(
              title: 'Empty',
              subtitle: 'Zero progress resting empty on quiet track container',
              card: true,
              child: OrionSegmentedProgress(count: 3, value: 0),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Linear Card
            OrionShowcaseSection(
              title: 'Linear',
              subtitle:
                  'Continuous 0..1 clamped progress bar with optional buffered cache layer',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const OrionLinearProgress(value: 0.25),
                  const SizedBox(height: OrionSpacing.space16),
                  const OrionLinearProgress(value: 0.6, bufferedValue: 0.8),
                  const SizedBox(height: OrionSpacing.space16),
                  Row(
                    children: [
                      const Expanded(child: OrionLinearProgress(value: 0.85)),
                      const SizedBox(width: OrionSpacing.space8),
                      Text(
                        '85%',
                        style: textTheme.labelSmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontFeatures: const <FontFeature>[
                            FontFeature.tabularFigures(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Indeterminate Card
            const OrionShowcaseSection(
              title: 'Indeterminate',
              subtitle:
                  'Continuous looping sweep animation resting static under reduced motion',
              card: true,
              child: OrionLinearProgress(),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive segment count and value controls with live code generator',
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
                      child: OrionSegmentedProgress(
                        count: _playgroundCount,
                        value: _playgroundValue,
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),

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
