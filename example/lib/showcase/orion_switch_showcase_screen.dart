import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionSwitch].
///
/// The `Disabled` flag in the top controls card drives every sample; the
/// sections below are the reference matrix of the thumb's two resting places
/// and the customization skin, and the playground last carries the focused
/// specimen - the switch itself - with its generated call behind the Code tab.
class OrionSwitchShowcaseScreen extends StatefulWidget {
  const OrionSwitchShowcaseScreen({super.key});

  @override
  State<OrionSwitchShowcaseScreen> createState() =>
      _OrionSwitchShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _SwitchSkin { standard, large, destructive }

class _OrionSwitchShowcaseScreenState extends State<OrionSwitchShowcaseScreen> {
  static const String _label = 'Notifications';

  // Flags: shared by every sample on the page.
  bool _disabled = false;

  // Customization: the focused skin choice.
  _SwitchSkin _skin = _SwitchSkin.standard;
  bool _skinOn = true;

  // Playground: the focused specimen's own state.
  bool _on = false;

  /// One sample under the shared flags.
  OrionSwitch _sample({
    required bool value,
    String? semanticLabel,
    ValueChanged<bool>? onChanged,
    OrionSwitchStyle? style,
  }) {
    return OrionSwitch(
      value: value,
      semanticLabel: semanticLabel,
      style: style,
      onChanged: _disabled ? null : (onChanged ?? (bool _) {}),
    );
  }

  OrionSwitchStyle? _skinStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (_skin) {
      _SwitchSkin.standard => null,
      _SwitchSkin.large => OrionSwitchStyle.from(
        trackWidth: 64,
        trackHeight: 40,
        inset: 4,
      ),
      _SwitchSkin.destructive => OrionSwitchStyle(
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return states.contains(WidgetState.disabled)
                ? scheme.error.withValues(alpha: 0.38)
                : scheme.error;
          }
          return states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.12)
              : scheme.outline;
        }),
      ),
    };
  }

  String _skinLabel(_SwitchSkin skin) => switch (skin) {
    _SwitchSkin.standard => 'Standard',
    _SwitchSkin.large => 'Large',
    _SwitchSkin.destructive => 'Destructive',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionSwitch(',
      '  value: $_on,',
      "  semanticLabel: '$_label',",
    ];
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else {
      lines.add('  onChanged: (bool value) {},');
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Switch',
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
                      'SELECTION • ASYMMETRIC SPRINGS',
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
                    'Pill track switch. Slides on gentle spring (zeta 0.80) while held thumb widens and squashes on snappy spring (zeta 0.78). Enter and Space flip it.',
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

            // States Card
            OrionShowcaseSection(
              title: 'States',
              subtitle:
                  'Resting positions: inactive off and active on across the pill track',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseLabeledRow(
                    label: 'Off',
                    child: _sample(value: false),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseLabeledRow(
                    label: 'On',
                    child: _sample(value: true),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionSwitchTheme -> Instance OrionSwitchStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_SwitchSkin>(
                    label: 'Skin',
                    values: _SwitchSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space24),
                  OrionShowcaseLabeledRow(
                    label: 'On',
                    child: _sample(
                      value: _skinOn,
                      style: _skinStyle(context),
                      onChanged: (bool value) =>
                          setState(() => _skinOn = value),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive switch with tactile hold deformation and live code generator',
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
                      child: Center(
                        child: _sample(
                          value: _on,
                          semanticLabel: _label,
                          onChanged: (bool value) =>
                              setState(() => _on = value),
                        ),
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
}
