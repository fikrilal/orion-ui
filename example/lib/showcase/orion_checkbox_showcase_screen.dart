import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionCheckbox].
///
/// The `Disabled`, `Indeterminate` and `Error` flags in the top controls card
/// drive every sample; the sections below are the reference matrices - confirm,
/// sizes, the tri-state row, the customization skins - and the playground last
/// drives one box through its size with the generated call behind the Code tab.
class OrionCheckboxShowcaseScreen extends StatefulWidget {
  const OrionCheckboxShowcaseScreen({super.key});

  @override
  State<OrionCheckboxShowcaseScreen> createState() =>
      _OrionCheckboxShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _CheckboxSkin { standard, round, square }

class _OrionCheckboxShowcaseScreenState
    extends State<OrionCheckboxShowcaseScreen> {
  static const String _rememberLabel = 'Remember me';
  static const String _selectAllLabel = 'Select all';

  // Flags: shared by every sample on the page.
  bool _disabled = false;
  bool _indeterminate = false;
  bool _error = false;

  // Samples: the states the flags do not own.
  bool _remember = false;
  final Set<OrionCheckboxSize> _checkedSizes = <OrionCheckboxSize>{};
  bool? _selectAll;
  bool _skinned = false;

  // Customization and playground: the focused choices.
  _CheckboxSkin _skin = _CheckboxSkin.standard;
  OrionCheckboxSize _size = OrionCheckboxSize.medium;
  bool _playground = false;

  /// One sample under the shared flags.
  ///
  /// `Indeterminate` pins every box to the middle state, `Error` repaints every
  /// one, and `Disabled` takes the tap away.
  OrionCheckbox _sample({
    required bool? value,
    String? label,
    String? subtitle,
    String? semanticLabel,
    required ValueChanged<bool?> onChanged,
    OrionCheckboxSize size = OrionCheckboxSize.medium,
    OrionCheckboxStyle? style,
  }) {
    return OrionCheckbox(
      value: _indeterminate ? null : value,
      label: label,
      subtitle: subtitle,
      semanticLabel: semanticLabel,
      error: _error,
      size: size,
      onChanged: _disabled ? null : onChanged,
      style: style,
    );
  }

  OrionCheckboxStyle? _skinStyle() => switch (_skin) {
    _CheckboxSkin.standard => null,
    _CheckboxSkin.round => OrionCheckboxStyle.from(
      radius: BorderRadius.circular(OrionRadii.radiusPill),
    ),
    _CheckboxSkin.square => OrionCheckboxStyle.from(radius: BorderRadius.zero),
  };

  String _skinLabel(_CheckboxSkin skin) => switch (skin) {
    _CheckboxSkin.standard => 'Standard',
    _CheckboxSkin.round => 'Round',
    _CheckboxSkin.square => 'Square',
  };

  String _sizeLabel(OrionCheckboxSize size) => switch (size) {
    OrionCheckboxSize.small => 'Small',
    OrionCheckboxSize.medium => 'Medium',
    OrionCheckboxSize.large => 'Large',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>['OrionCheckbox('];
    if (_indeterminate) {
      lines.add('  value: null, // indeterminate');
    } else {
      lines.add('  value: $_playground,');
    }
    lines.add("  semanticLabel: '$_rememberLabel',");
    if (_size != OrionCheckboxSize.medium) {
      lines.add('  size: OrionCheckboxSize.${_size.name},');
    }
    if (_error) {
      lines.add('  error: true,');
    }
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else {
      lines.add('  onChanged: (bool? value) {},');
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Checkbox',
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
                    'Tap-only box confirming boolean or indeterminate states. Fill, border, and mark ride the gentle travel spring with translucent surface focus.',
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
                        label: 'Indeterminate',
                        value: _indeterminate,
                        onChanged: (value) =>
                            setState(() => _indeterminate = value),
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
            const SizedBox(height: OrionSpacing.space24),
            OrionShowcaseSection(
              title: 'Confirm',
              subtitle:
                  'Built-in clickable label and subtitle row with stroke-drawn check animation',
              card: true,
              child: _sample(
                value: _remember,
                label: _rememberLabel,
                subtitle: 'Keep me signed in on this device for 30 days',
                onChanged: (bool? value) =>
                    setState(() => _remember = value ?? false),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (20 pt), Medium (24 pt), and Large (28 pt) under a constant 44 pt target',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final OrionCheckboxSize size
                      in OrionCheckboxSize.values) ...<Widget>[
                    OrionShowcaseLabeledRow(
                      label: _sizeLabel(size),
                      child: _sample(
                        value: _checkedSizes.contains(size),
                        semanticLabel: '${_sizeLabel(size)} box',
                        size: size,
                        onChanged: (bool? value) => setState(() {
                          if (value ?? false) {
                            _checkedSizes.add(size);
                          } else {
                            _checkedSizes.remove(size);
                          }
                        }),
                      ),
                    ),
                    if (size != OrionCheckboxSize.values.last)
                      const SizedBox(height: OrionSpacing.space12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),
            OrionShowcaseSection(
              title: 'Tri-state',
              subtitle:
                  'Indeterminate middle state cross-fading smoothly to checked or unchecked',
              card: true,
              child: _sample(
                value: _selectAll,
                label: _selectAllLabel,
                onChanged: (bool? _) => setState(() {
                  _selectAll = switch (_selectAll) {
                    null => false,
                    false => true,
                    true => null,
                  };
                }),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionCheckboxTheme -> Instance OrionCheckboxStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_CheckboxSkin>(
                    label: 'Skin',
                    values: _CheckboxSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space24),
                  Center(
                    child: _sample(
                      value: _skinned,
                      semanticLabel: _rememberLabel,
                      onChanged: (bool? value) =>
                          setState(() => _skinned = value ?? false),
                      style: _skinStyle(),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),
            OrionShowcaseSection(
              title: 'Playground',
              subtitle: 'Interactive workbench with live code generator',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<OrionCheckboxSize>(
                    label: 'Size',
                    values: OrionCheckboxSize.values,
                    selected: _size,
                    labelOf: _sizeLabel,
                    onChanged: (value) => setState(() => _size = value),
                  ),
                  const SizedBox(height: OrionSpacing.space24),
                  OrionShowcasePanel(
                    key: const ValueKey<String>('showcase-panel-playground'),
                    preview: Center(
                      child: _sample(
                        value: _playground,
                        label: _rememberLabel,
                        size: _size,
                        onChanged: (bool? value) =>
                            setState(() => _playground = value ?? false),
                      ),
                    ),
                    code: _snippet,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
