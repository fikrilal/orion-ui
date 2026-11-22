import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionRadio].
///
/// The `Disabled` and `Error` flags in the top controls card drive every
/// sample; the sections below are the reference matrices - a plan group, the
/// size group, the radio beside a checkbox, the customization skins - and the
/// playground last selects within its own group with the generated call behind
/// the Code tab.
class OrionRadioShowcaseScreen extends StatefulWidget {
  const OrionRadioShowcaseScreen({super.key});

  @override
  State<OrionRadioShowcaseScreen> createState() =>
      _OrionRadioShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _RadioSkin { standard, filled, thick }

class _OrionRadioShowcaseScreenState extends State<OrionRadioShowcaseScreen> {
  static const List<(String, String)> _plans = <(String, String)>[
    ('Monthly', r'$12 per month'),
    ('Yearly', r'$99 per year'),
    ('Lifetime', r'$249 once'),
  ];

  static const List<String> _playgroundOptions = <String>[
    'Light',
    'System',
    'Dark',
  ];

  // Flags: shared by every sample on the page.
  bool _disabled = false;
  bool _error = false;

  // Samples: the groups the flags do not own.
  int _plan = 0;
  int _sizeChoice = 1;
  bool _shared = false;
  bool _skinned = false;

  // Customization and playground: the focused choices.
  _RadioSkin _skin = _RadioSkin.standard;
  OrionRadioSize _size = OrionRadioSize.medium;
  int _playgroundChoice = 1;

  /// One sample under the shared flags.
  ///
  /// `Error` repaints every circle and `Disabled` takes the tap away.
  OrionRadio _sample({
    required bool value,
    required String semanticLabel,
    ValueChanged<bool>? onChanged,
    OrionRadioSize size = OrionRadioSize.medium,
    OrionRadioStyle? style,
  }) {
    return OrionRadio(
      value: value,
      semanticLabel: semanticLabel,
      error: _error,
      size: size,
      onChanged: _disabled ? null : (onChanged ?? (_) {}),
      style: style,
    );
  }

  OrionRadioStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _RadioSkin.standard => null,
    _RadioSkin.filled => OrionRadioStyle.from(
      fillColor: scheme.primary,
      dotColor: scheme.onPrimary,
    ),
    _RadioSkin.thick => OrionRadioStyle.from(borderWidth: 4),
  };

  String _skinLabel(_RadioSkin skin) => switch (skin) {
    _RadioSkin.standard => 'Standard',
    _RadioSkin.filled => 'Filled',
    _RadioSkin.thick => 'Thick',
  };

  String _sizeLabel(OrionRadioSize size) => switch (size) {
    OrionRadioSize.small => 'Small',
    OrionRadioSize.medium => 'Medium',
    OrionRadioSize.large => 'Large',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final int index = _playgroundChoice;
    final String label = _playgroundOptions[index];
    final List<String> lines = <String>[
      'OrionRadio(',
      '  value: _selected == $index,',
      "  semanticLabel: '$label',",
    ];
    if (_size != OrionRadioSize.medium) {
      lines.add('  size: OrionRadioSize.${_size.name},');
    }
    if (_error) {
      lines.add('  error: true,');
    }
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else {
      lines.add('  onChanged: (_) => setState(() => _selected = $index),');
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Radio',
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
                      'SELECTION • GENTLE TRAVEL',
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
                    'Tap-only circular radio marking the chosen choice in an exclusive group. Inner dot pops on gentle travel spring; transparent interior by default.',
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
                    Expanded(
                      child: OrionShowcaseToggle(
                        label: 'Error',
                        value: _error,
                        onChanged: (value) => setState(() => _error = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2.04),

            // Group Card
            OrionShowcaseSection(
              title: 'Group',
              subtitle:
                  'Exclusive single choice option group; parent manages selected index',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (var index = 0; index < _plans.length; index++) ...[
                    _RadioRow(
                      label: _plans[index].$1,
                      caption: _plans[index].$2,
                      child: _sample(
                        value: _plan == index,
                        semanticLabel: _plans[index].$1,
                        onChanged: (_) => setState(() => _plan = index),
                      ),
                    ),
                    if (index != _plans.length - 1)
                      const SizedBox(height: OrionSpacing.space12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (20 pt), Medium (24 pt), and Large (28 pt) geometry under 44 pt target',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (
                    var index = 0;
                    index < OrionRadioSize.values.length;
                    index++
                  ) ...[
                    _RadioRow(
                      label: _sizeLabel(OrionRadioSize.values[index]),
                      child: _sample(
                        value: _sizeChoice == index,
                        semanticLabel: _sizeLabel(OrionRadioSize.values[index]),
                        size: OrionRadioSize.values[index],
                        onChanged: (_) => setState(() => _sizeChoice = index),
                      ),
                    ),
                    if (index != OrionRadioSize.values.length - 1)
                      const SizedBox(height: OrionSpacing.space12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Next to a checkbox Card
            OrionShowcaseSection(
              title: 'Next to a checkbox',
              subtitle:
                  'Distinguishable side-by-side: filled box vs transparent ring-plus-dot',
              card: true,
              child: Row(
                children: [
                  _RadioRow(
                    label: 'Radio',
                    child: _sample(
                      value: _shared,
                      semanticLabel: 'Radio sample',
                      onChanged: (_) => setState(() => _shared = true),
                    ),
                  ),
                  const SizedBox(width: 2.04),
                  _RadioRow(
                    label: 'Checkbox',
                    child: OrionCheckbox(
                      value: true,
                      semanticLabel: 'Checkbox sample',
                      onChanged: null,
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
                  'Three-layer style contract: Presets -> OrionRadioTheme -> Instance OrionRadioStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_RadioSkin>(
                    label: 'Skin',
                    values: _RadioSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: 2.04),
                  Center(
                    child: _sample(
                      value: _skinned,
                      semanticLabel: 'Radio sample',
                      onChanged: (_) => setState(() => _skinned = true),
                      style: _skinStyle(scheme),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle: 'Interactive group selection with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrionShowcaseChoice<OrionRadioSize>(
                      label: 'Size',
                      values: OrionRadioSize.values,
                      selected: _size,
                      labelOf: _sizeLabel,
                      onChanged: (value) => setState(() => _size = value),
                    ),
                    const SizedBox(height: 2.00),
                    for (
                      var index = 0;
                      index < _playgroundOptions.length;
                      index++
                    ) ...[
                      _RadioRow(
                        label: _playgroundOptions[index],
                        child: _sample(
                          value: _playgroundChoice == index,
                          semanticLabel: _playgroundOptions[index],
                          size: _size,
                          onChanged: (_) =>
                              setState(() => _playgroundChoice = index),
                        ),
                      ),
                      if (index != _playgroundOptions.length - 1)
                        const SizedBox(height: OrionSpacing.space8),
                    ],
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

/// The circle owns no label, so the page composes the row the way a screen
/// would.
///
/// The circle carries the spoken name, so the visible label stays out of the
/// semantics tree and is not announced twice.
class _RadioRow extends StatelessWidget {
  const _RadioRow({required this.label, required this.child, this.caption});

  final String label;
  final String? caption;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(width: OrionSpacing.space4),
        ExcludeSemantics(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: theme.textTheme.bodyMedium),
              if (caption != null)
                Text(caption!, style: theme.textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}
