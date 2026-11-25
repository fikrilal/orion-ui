import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionChip] and [OrionChipGroup].
class OrionChipShowcaseScreen extends StatefulWidget {
  const OrionChipShowcaseScreen({super.key});

  @override
  State<OrionChipShowcaseScreen> createState() =>
      _OrionChipShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _ChipSkin { standard, soft, loud }

class _OrionChipShowcaseScreenState extends State<OrionChipShowcaseScreen> {
  static const List<OrionChipItem<String>> _filterItems =
      <OrionChipItem<String>>[
        OrionChipItem<String>(
          value: 'live',
          label: 'Live',
          leading: Icon(Icons.bolt_rounded),
        ),
        OrionChipItem<String>(
          value: 'draft',
          label: 'Draft',
          leading: Icon(Icons.edit_note_rounded),
        ),
        OrionChipItem<String>(
          value: 'archived',
          label: 'Archived',
          leading: Icon(Icons.archive_outlined),
        ),
        OrionChipItem<String>(
          value: 'mine',
          label: 'Mine',
          leading: Icon(Icons.person_outline_rounded),
        ),
        OrionChipItem<String>(
          value: 'shared',
          label: 'Shared',
          leading: Icon(Icons.group_outlined),
        ),
      ];

  static const List<OrionChipItem<String>> _rangeItems =
      <OrionChipItem<String>>[
        OrionChipItem<String>(value: 'today', label: 'Today'),
        OrionChipItem<String>(value: 'week', label: 'This week'),
        OrionChipItem<String>(value: 'month', label: 'This month'),
        OrionChipItem<String>(value: 'all', label: 'All time'),
      ];

  static const List<String> _initialTags = <String>[
    'Flutter',
    'Dart',
    'Motion',
    'Design System',
  ];

  // Shared flag
  bool _disabled = false;

  // Multi-select filter bar
  Set<String> _selectedFilters = <String>{'live'};
  OrionChipGroupLayout _filterLayout = OrionChipGroupLayout.wrap;

  // Single-select choice group
  Set<String> _selectedRange = <String>{'today'};

  // Removable input tags
  List<String> _tags = List<String>.of(_initialTags);

  // Customization
  _ChipSkin _skin = _ChipSkin.standard;
  bool _skinned = false;

  // Playground
  String _playgroundValue = 'Today';
  OrionChipSize _size = OrionChipSize.medium;
  bool _showCheckmark = true;

  OrionChipStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _ChipSkin.standard => null,
    _ChipSkin.soft => OrionChipStyle.from(borderWidth: 0),
    _ChipSkin.loud => OrionChipStyle.from(
      fillColor: scheme.primary,
      labelColor: scheme.onPrimary,
      borderColor: scheme.primary,
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

  String _layoutLabel(OrionChipGroupLayout layout) => switch (layout) {
    OrionChipGroupLayout.wrap => 'Wrap',
    OrionChipGroupLayout.horizontal => 'Horizontal',
  };

  /// The exact call the current playground controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionChip(',
      "  text: '$_playgroundValue',",
      '  selected: true,',
    ];
    if (!_showCheckmark) {
      lines.add('  showCheckmark: false,');
    }
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
                      'SELECTION • CHIPS & GROUPS',
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
                    'Selectable pill with crisp spring travel, optional checkmark, leading/trailing slots, removal, and managed OrionChipGroup.',
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

            // Multi-select OrionChipGroup Card
            OrionShowcaseSection(
              title: 'Filter Group (Multi-Select)',
              subtitle:
                  'OrionChipGroup with leading icons, summary count, clear action, and wrap/scroll layout',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseChoice<OrionChipGroupLayout>(
                    label: 'Layout',
                    values: OrionChipGroupLayout.values,
                    selected: _filterLayout,
                    labelOf: _layoutLabel,
                    onChanged: (OrionChipGroupLayout value) =>
                        setState(() => _filterLayout = value),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionChipGroup<String>(
                    items: _filterItems,
                    selectedValues: _selectedFilters,
                    layout: _filterLayout,
                    enabled: !_disabled,
                    showClearAction: true,
                    selectedCountLabelBuilder: (int count) =>
                        '$count of ${_filterItems.length} selected',
                    onSelectionChanged: (Set<String> next) =>
                        setState(() => _selectedFilters = next),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Single-select Choice Group Card
            OrionShowcaseSection(
              title: 'Choice Group (Single-Select)',
              subtitle:
                  'Defaults to showCheckmark: false for zero horizontal reflow jitter',
              card: true,
              child: OrionChipGroup<String>(
                items: _rangeItems,
                selectedValues: _selectedRange,
                selectionMode: OrionChipSelectionMode.single,
                allowDeselect: false,
                enabled: !_disabled,
                onSelectionChanged: (Set<String> next) =>
                    setState(() => _selectedRange = next),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Removable Tags Card
            OrionShowcaseSection(
              title: 'Removable Tags',
              subtitle: 'Input chips with onDeleted and plain text shorthand',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  if (_tags.isEmpty)
                    Text(
                      'All tags removed.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    )
                  else
                    Wrap(
                      spacing: OrionSpacing.space8,
                      runSpacing: OrionSpacing.space8,
                      children: <Widget>[
                        for (final String tag in _tags)
                          OrionChip(
                            text: tag,
                            selected: false,
                            onSelected: null,
                            onDeleted: _disabled
                                ? null
                                : () => setState(() => _tags.remove(tag)),
                          ),
                      ],
                    ),
                  if (_tags.length < _initialTags.length) ...<Widget>[
                    const SizedBox(height: OrionSpacing.space12),
                    OrionButton(
                      variant: OrionButtonVariant.flat,
                      size: OrionButtonSize.small,
                      label: 'Reset tags',
                      onPressed: _disabled
                          ? null
                          : () => setState(
                              () => _tags = List<String>.of(_initialTags),
                            ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (28 pt), Medium (32 pt), and Large (40 pt) with stepped typography inside the 44 pt hit target',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space8,
                runSpacing: OrionSpacing.space8,
                children: <Widget>[
                  for (final OrionChipSize size in OrionChipSize.values)
                    OrionChip(
                      text: _sizeLabel(size),
                      selected: true,
                      size: size,
                      onSelected: _disabled ? null : (_) {},
                    ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract — Soft uses borderWidth: 0 (truly borderless)',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseChoice<_ChipSkin>(
                    label: 'Skin',
                    values: _ChipSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (_ChipSkin value) =>
                        setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionChip(
                    text: 'Live',
                    selected: _skinned,
                    style: _skinStyle(scheme),
                    onSelected: _disabled
                        ? null
                        : (bool value) => setState(() => _skinned = value),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle: 'Configure size and checkmark with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionShowcaseChoice<OrionChipSize>(
                      label: 'Size',
                      values: OrionChipSize.values,
                      selected: _size,
                      labelOf: _sizeLabel,
                      onChanged: (OrionChipSize value) =>
                          setState(() => _size = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseToggle(
                      label: 'Show checkmark',
                      value: _showCheckmark,
                      onChanged: (bool value) =>
                          setState(() => _showCheckmark = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    Wrap(
                      spacing: OrionSpacing.space8,
                      runSpacing: OrionSpacing.space8,
                      children: <Widget>[
                        for (final String label in const <String>[
                          'Today',
                          'This week',
                          'All',
                        ])
                          OrionChip(
                            text: label,
                            selected: _playgroundValue == label,
                            size: _size,
                            showCheckmark: _showCheckmark,
                            onSelected: _disabled
                                ? null
                                : (_) =>
                                      setState(() => _playgroundValue = label),
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
