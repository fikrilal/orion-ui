import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionCounter].
class OrionCounterShowcaseScreen extends StatefulWidget {
  const OrionCounterShowcaseScreen({super.key});

  @override
  State<OrionCounterShowcaseScreen> createState() =>
      _OrionCounterShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _CounterSkin { standard, large, extra, hardClip }

class _OrionCounterShowcaseScreenState
    extends State<OrionCounterShowcaseScreen> {
  int _value = 128;
  int _carry = 9;
  double _balance = 1240.50;
  double _delta = 42.85;

  // Customization: the focused skin.
  _CounterSkin _skin = _CounterSkin.standard;

  // Playground: the focused specimen's own axes.
  double _playgroundValue = 128;
  bool _playgroundAnimate = true;
  bool _playgroundFadeEdges = true;
  bool _playgroundDecimals = false;
  bool _playgroundGrouping = true;
  bool _playgroundShowPlus = false;

  OrionCounterStyle? _skinStyle(TextTheme textTheme) => switch (_skin) {
    _CounterSkin.standard => null,
    _CounterSkin.large => OrionCounterStyle.from(
      textStyle: textTheme.displaySmall,
    ),
    _CounterSkin.extra => OrionCounterStyle.from(
      rollStretchX: 0.14,
      rollSquashY: 0.22,
    ),
    _CounterSkin.hardClip => OrionCounterStyle.from(fadeEdges: false),
  };

  String _skinLabel(_CounterSkin skin) => switch (skin) {
    _CounterSkin.standard => 'Standard',
    _CounterSkin.large => 'Large',
    _CounterSkin.extra => 'Extra Squash',
    _CounterSkin.hardClip => 'Hard Clip',
  };

  /// The exact call the current playground controls produce.
  String get _snippet {
    final String valueLiteral = _playgroundDecimals
        ? _playgroundValue.toStringAsFixed(2)
        : _playgroundValue.round().toString();
    final List<String> lines = <String>[
      'OrionCounter(',
      '  value: $valueLiteral,',
    ];
    if (_playgroundDecimals) {
      lines.add('  fractionDigits: 2,');
    }
    if (_playgroundGrouping) {
      lines.add("  thousandSeparator: ',',");
    }
    if (_playgroundShowPlus) {
      lines.add('  showPositiveSign: true,');
    }
    if (!_playgroundAnimate) {
      lines.add('  animate: false,');
    }
    if (!_playgroundFadeEdges) {
      lines.add('  fadeEdges: false,');
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final TextTheme textTheme = theme.textTheme;
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Counter',
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
                      'READOUT • INDEPENDENT SPRINGS',
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
                    'Rolling digit odometer for integers, decimals, and negative values. Independent spring per slot, tabular metrics, motion-aware edge fade, and zero-dependency formatting.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Rolling Section
            OrionShowcaseSection(
              title: 'Rolling',
              subtitle:
                  'Individual digit columns roll forward or backward with cached metrics',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Text(
                        'Unread: ',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                      OrionCounter(value: _value, semanticLabel: 'Unread'),
                    ],
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Wrap(
                    spacing: OrionSpacing.space8,
                    runSpacing: OrionSpacing.space8,
                    children: <Widget>[
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => setState(() => _value -= 1),
                        label: 'Down',
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        onPressed: () => setState(() => _value += 1),
                        label: 'Up',
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: () => setState(() => _value = 128),
                        label: 'Reset',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Currency & Signed Delta Section
            OrionShowcaseSection(
              title: 'Currency & Signed Delta',
              subtitle:
                  'Decimals, thousands grouping, prefix/suffix, and smooth sign flips',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionCounter(
                    value: _balance,
                    fractionDigits: 2,
                    thousandSeparator: ',',
                    prefix: r'$',
                    textStyle: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                    semanticLabel: 'Balance',
                  ),
                  const SizedBox(height: OrionSpacing.space4),
                  OrionCounter(
                    value: _delta,
                    fractionDigits: 2,
                    thousandSeparator: ',',
                    prefix: r'$',
                    suffix: ' today',
                    showPositiveSign: true,
                    textStyle: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: _delta < 0
                          ? scheme.error
                          : scheme.onSurfaceVariant,
                    ),
                    semanticLabel: 'Daily change',
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Wrap(
                    spacing: OrionSpacing.space8,
                    runSpacing: OrionSpacing.space8,
                    children: <Widget>[
                      OrionButton(
                        size: OrionButtonSize.small,
                        onPressed: () => setState(() {
                          _balance += 12.55;
                          _delta += 12.55;
                        }),
                        label: r'+$12.55',
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => setState(() {
                          _balance -= 25.00;
                          _delta -= 25.00;
                        }),
                        label: r'-$25.00',
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: () => setState(() => _delta = -_delta),
                        label: 'Flip sign',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Carry Section (fixed to demonstrate real 9 -> 10 / 99 -> 100 rollovers)
            OrionShowcaseSection(
              title: 'Carry & Width Glide',
              subtitle:
                  '9 -> 10 and 100 -> 99 roll forward/backward while gliding row width smoothly',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionCounter(
                    value: _carry,
                    thousandSeparator: ',',
                    textStyle: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    semanticLabel: 'Carry',
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Wrap(
                    spacing: OrionSpacing.space8,
                    runSpacing: OrionSpacing.space8,
                    children: <Widget>[
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: () => setState(() => _carry -= 1),
                        label: '-1',
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        onPressed: () => setState(() => _carry += 1),
                        label: '+1',
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: () => setState(() {
                          _carry = switch (_carry) {
                            < 10 => 99,
                            < 100 => 999,
                            _ => 9,
                          };
                        }),
                        label: 'Jump to 9 / 99 / 999',
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Formatting & Zero-Padding Section
            const OrionShowcaseSection(
              title: 'Formatting & Padding',
              subtitle:
                  'Thousands grouping, percentages, minDigits zero-padding, and negatives',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space24,
                runSpacing: OrionSpacing.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  OrionCounter(value: 9, minDigits: 2),
                  OrionCounter(value: -42),
                  OrionCounter(value: 98.4, fractionDigits: 1, suffix: '%'),
                  OrionCounter(value: 1000000, thousandSeparator: ','),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Without travel section
            _AnimateSection(value: _value, onJump: _jump),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Section
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionCounterTheme -> Instance OrionCounterStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseChoice<_CounterSkin>(
                    label: 'Skin',
                    values: _CounterSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (_CounterSkin value) =>
                        setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionCounter(
                    value: _value,
                    style: _skinStyle(textTheme),
                    semanticLabel: 'Skinned value',
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Section
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive signed value slider and formatting toggles with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space24,
                        vertical: OrionSpacing.space24,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
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
                      child: Center(
                        child: OrionCounter(
                          value: _playgroundDecimals
                              ? _playgroundValue
                              : _playgroundValue.round(),
                          fractionDigits: _playgroundDecimals ? 2 : 0,
                          thousandSeparator: _playgroundGrouping ? ',' : null,
                          showPositiveSign: _playgroundShowPlus,
                          animate: _playgroundAnimate,
                          fadeEdges: _playgroundFadeEdges,
                          textStyle: textTheme.headlineLarge?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          semanticLabel: 'Playground value',
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),
                    OrionShowcaseValueSlider(
                      label: 'Value',
                      value: _playgroundValue,
                      min: -1200,
                      max: 1200,
                      step: _playgroundDecimals ? 0.25 : 1,
                      display: _playgroundDecimals
                          ? _playgroundValue.toStringAsFixed(2)
                          : _playgroundValue.round().toString(),
                      onChanged: (double value) =>
                          setState(() => _playgroundValue = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseToggle(
                      label: 'Animate',
                      value: _playgroundAnimate,
                      onChanged: (bool value) =>
                          setState(() => _playgroundAnimate = value),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    OrionShowcaseToggle(
                      label: 'Fade edges',
                      value: _playgroundFadeEdges,
                      onChanged: (bool value) =>
                          setState(() => _playgroundFadeEdges = value),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    OrionShowcaseToggle(
                      label: 'Decimals (.00)',
                      value: _playgroundDecimals,
                      onChanged: (bool value) =>
                          setState(() => _playgroundDecimals = value),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    OrionShowcaseToggle(
                      label: 'Thousands (,)',
                      value: _playgroundGrouping,
                      onChanged: (bool value) =>
                          setState(() => _playgroundGrouping = value),
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    OrionShowcaseToggle(
                      label: 'Show + sign',
                      value: _playgroundShowPlus,
                      onChanged: (bool value) =>
                          setState(() => _playgroundShowPlus = value),
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

  void _jump() {
    setState(() => _value = (_value.abs() * 7 + 1234) % 100000);
  }
}

/// `animate: false` renders a new value without travel.
class _AnimateSection extends StatelessWidget {
  const _AnimateSection({required this.value, required this.onJump});

  final int value;
  final VoidCallback onJump;

  @override
  Widget build(BuildContext context) {
    return OrionShowcaseSection(
      title: 'Without travel',
      subtitle:
          'Instant numeric transition without animation when animate is false',
      card: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          OrionCounter(
            value: value,
            animate: false,
            semanticLabel: 'Instant value',
          ),
          const SizedBox(height: OrionSpacing.space8),
          OrionButton(
            size: OrionButtonSize.small,
            variant: OrionButtonVariant.bordered,
            onPressed: onJump,
            label: 'Jump',
          ),
        ],
      ),
    );
  }
}
