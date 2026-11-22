import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionChip].
///
/// The `Disabled` flag in the top controls card drives every sample; the
/// sections below are the reference matrices - the multi-select filter row, the
/// sizes, the customization skins - and the playground last selects a single
/// chip with its generated call behind the Code tab.
class OrionChipShowcaseScreen extends StatefulWidget {
  const OrionChipShowcaseScreen({super.key});

  @override
  State<OrionChipShowcaseScreen> createState() =>
      _OrionChipShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _ChipSkin { standard, soft, loud }

class _OrionChipShowcaseScreenState extends State<OrionChipShowcaseScreen> {
  static const List<String> _filters = <String>[
    'Live',
    'Draft',
    'Archived',
    'Mine',
  ];

  static const List<String> _ranges = <String>['Today', 'This week', 'All'];

  // Flags: shared by every sample on the page.
  bool _disabled = false;

  // Filters: the row owns the set it reports.
  final Set<String> _selected = <String>{'Live'};

  // Customization: the focused skin and its specimen.
  _ChipSkin _skin = _ChipSkin.standard;
  bool _skinned = false;

  // Playground: the single select and the size.
  String _range = 'Today';
  OrionChipSize _size = OrionChipSize.medium;

  /// One sample under the shared flag.
  OrionChip _sample({
    required String label,
    required bool selected,
    required ValueChanged<bool> onSelected,
    OrionChipSize size = OrionChipSize.medium,
    OrionChipStyle? style,
  }) {
    return OrionChip(
      label: Text(label),
      selected: selected,
      size: size,
      onSelected: _disabled ? null : onSelected,
      style: style,
    );
  }

  OrionChipStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _ChipSkin.standard => null,
    _ChipSkin.soft => OrionChipStyle.from(borderWidth: 0),
    _ChipSkin.loud => OrionChipStyle.from(
      fillColor: scheme.primary,
      labelColor: scheme.onPrimary,
    ),
  };

  String _skinLabel(_ChipSkin skin) => switch (skin) {
    _ChipSkin.standard => 'Standard',
    _ChipSkin.soft => 'Soft',
    _ChipSkin.loud => 'Loud',
  };

  String _sizeLabel(OrionChipSize size) => switch (size) {
    OrionChipSize.small => 'Small',
    OrionChipSize.medium => 'Medium',
    OrionChipSize.large => 'Large',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionChip(',
      "  label: const Text('$_range'),",
      '  selected: true,',
    ];
    if (_size != OrionChipSize.medium) {
      lines.add('  size: OrionChipSize.${_size.name},');
    }
    if (_disabled) {
      lines.add('  onSelected: null, // disabled');
    } else {
      lines.add('  onSelected: (bool value) {},');
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
      title: 'Orion Chip',
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
                    'Tap-only selectable pill with animated checkmark and color lerp riding the gentle travel spring. Surface state focus layer without outer halos.',
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

            // Filters Card
            OrionShowcaseSection(
              title: 'Filters',
              subtitle:
                  'Multi-select token filters with smooth label and check interpolation',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: OrionSpacing.space8,
                    runSpacing: OrionSpacing.space8,
                    children: [
                      for (final String filter in _filters)
                        _sample(
                          label: filter,
                          selected: _selected.contains(filter),
                          onSelected: (bool value) => setState(() {
                            if (value) {
                              _selected.add(filter);
                            } else {
                              _selected.remove(filter);
                            }
                          }),
                        ),
                    ],
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  Text(
                    '${_selected.length} of ${_filters.length} selected',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (28 pt), Medium (32 pt), and Large (40 pt) inside the constant 44 pt hit target',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space8,
                runSpacing: OrionSpacing.space8,
                children: [
                  for (final OrionChipSize size in OrionChipSize.values)
                    _sample(
                      label: _sizeLabel(size),
                      selected: true,
                      size: size,
                      onSelected: (_) {},
                    ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionChipTheme -> Instance OrionChipStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_ChipSkin>(
                    label: 'Skin',
                    values: _ChipSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    label: 'Live',
                    selected: _skinned,
                    style: _skinStyle(scheme),
                    onSelected: (bool value) =>
                        setState(() => _skinned = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle: 'Single-select choice chips with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrionShowcaseChoice<OrionChipSize>(
                      label: 'Size',
                      values: OrionChipSize.values,
                      selected: _size,
                      labelOf: _sizeLabel,
                      onChanged: (value) => setState(() => _size = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    Wrap(
                      spacing: OrionSpacing.space8,
                      runSpacing: OrionSpacing.space8,
                      children: [
                        for (final String range in _ranges)
                          _sample(
                            label: range,
                            selected: _range == range,
                            size: _size,
                            onSelected: (_) => setState(() => _range = range),
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
