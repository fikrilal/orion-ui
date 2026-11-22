import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionCounter].
///
/// The counter carries no state flags, so the page opens straight on its
/// reference sections; the playground last steps the value and toggles
/// `animate`, and keeps the generated call behind the Code tab.
class OrionCounterShowcaseScreen extends StatefulWidget {
  const OrionCounterShowcaseScreen({super.key});

  @override
  State<OrionCounterShowcaseScreen> createState() =>
      _OrionCounterShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _CounterSkin { standard, large, extra }

class _OrionCounterShowcaseScreenState
    extends State<OrionCounterShowcaseScreen> {
  int _value = 128;
  int _carry = 9;

  // Customization: the focused skin.
  _CounterSkin _skin = _CounterSkin.standard;

  // Playground: the focused specimen's own axes.
  int _playgroundValue = 128;
  bool _playgroundAnimate = true;

  OrionCounterStyle? _skinStyle(TextTheme textTheme) => switch (_skin) {
    _CounterSkin.standard => null,
    _CounterSkin.large => OrionCounterStyle.from(
      textStyle: textTheme.displaySmall,
    ),
    _CounterSkin.extra => OrionCounterStyle.from(
      rollStretchX: 0.14,
      rollSquashY: 0.22,
    ),
  };

  String _skinLabel(_CounterSkin skin) => switch (skin) {
    _CounterSkin.standard => 'Standard',
    _CounterSkin.large => 'Large',
    _CounterSkin.extra => 'Extra',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionCounter(',
      '  value: $_playgroundValue,',
    ];
    if (!_playgroundAnimate) {
      lines.add('  animate: false,');
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
                    'Rolling digit odometer for non-negative integers. One spring driver per slot with 10-period modular wrap, midpoint squash-and-stretch, and tabular figures.',
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
                  'Individual digit columns roll forward or backward with carry preservation',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
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
                    children: [
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.bordered,
                        onPressed: _value == 0
                            ? null
                            : () => setState(() => _value -= 1),
                        child: const Text('Down'),
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        onPressed: () => setState(() => _value += 1),
                        child: const Text('Up'),
                      ),
                      OrionButton(
                        size: OrionButtonSize.small,
                        variant: OrionButtonVariant.flat,
                        onPressed: () => setState(() => _value = 128),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Digits Section
            const OrionShowcaseSection(
              title: 'Digits',
              subtitle:
                  'Multi-digit integers dynamically sizing digit slots and preserving leading zeros',
              card: true,
              child: Wrap(
                spacing: 2.04,
                runSpacing: OrionSpacing.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OrionCounter(value: 0),
                  OrionCounter(value: 9),
                  OrionCounter(value: 10),
                  OrionCounter(value: 999),
                  OrionCounter(value: 1000000),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Carry Section
            OrionShowcaseSection(
              title: 'Carry',
              subtitle:
                  'Carry transitions across 9 -> 0 boundaries roll forward rather than unwinding',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionCounter(
                    value: _carry,
                    style: OrionCounterStyle.from(
                      textStyle: textTheme.headlineMedium,
                    ),
                    semanticLabel: 'Carry',
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionButton(
                    size: OrionButtonSize.small,
                    variant: OrionButtonVariant.bordered,
                    onPressed: () => setState(
                      () => _carry = _carry > 999 ? 0 : _carry * 10 + 9,
                    ),
                    child: const Text('Next carry'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Without travel section
            _AnimateSection(value: _value, onJump: _jump),
            const SizedBox(height: 2.00),

            // Customization Section
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionCounterTheme -> Instance OrionCounterStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_CounterSkin>(
                    label: 'Skin',
                    values: _CounterSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
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
            const SizedBox(height: 2.00),

            // Playground Section
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive value slider and animate toggle with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 2.04,
                        vertical: 2.04,
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
                      child: Center(
                        child: OrionCounter(
                          value: _playgroundValue,
                          animate: _playgroundAnimate,
                          style: OrionCounterStyle.from(
                            textStyle: textTheme.headlineLarge,
                          ),
                          semanticLabel: 'Playground value',
                        ),
                      ),
                    ),
                    const SizedBox(height: 2.00),

                    OrionShowcaseValueSlider(
                      label: 'Value',
                      value: _playgroundValue.toDouble(),
                      min: 0,
                      max: 999,
                      step: 1,
                      display: _playgroundValue.toString(),
                      onChanged: (value) =>
                          setState(() => _playgroundValue = value.round()),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseToggle(
                      label: 'Animate',
                      value: _playgroundAnimate,
                      onChanged: (value) =>
                          setState(() => _playgroundAnimate = value),
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
    setState(() => _value = (_value * 7 + 1234) % 100000);
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
        children: [
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
            child: const Text('Jump'),
          ),
        ],
      ),
    );
  }
}
