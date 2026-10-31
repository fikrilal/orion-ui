import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionRadio] and [OrionRadioGroup].
///
/// The `Disabled` and `Error` flags in the top controls card drive every
/// sample; the sections below showcase card groups, plain & horizontal groups,
/// size steps, side-by-side comparison with [OrionCheckbox], state-aware
/// customization skins, and an interactive playground with live code output.
class OrionRadioShowcaseScreen extends StatefulWidget {
  const OrionRadioShowcaseScreen({super.key});

  @override
  State<OrionRadioShowcaseScreen> createState() =>
      _OrionRadioShowcaseScreenState();
}

enum _BillingPlan { monthly, yearly, lifetime }

enum _Density { compact, balanced, spacious }

enum _ThemeOption { light, system, dark }

/// The instance-level skins the customization section demonstrates.
enum _RadioSkin { standard, filled, tinted, thick }

class _OrionRadioShowcaseScreenState extends State<OrionRadioShowcaseScreen> {
  // Flags: shared by every sample on the page.
  bool _disabled = false;
  bool _error = false;

  // Samples: groups and interactive states.
  _BillingPlan _plan = _BillingPlan.yearly;
  _Density _density = _Density.balanced;
  OrionRadioSize _sizeChoice = OrionRadioSize.medium;
  int _compareRadio = 0;
  bool _compareCheckbox = true;
  int _skinChoice = 0;

  // Customization and playground controls.
  _RadioSkin _skin = _RadioSkin.standard;
  OrionRadioGroupVariant _playgroundVariant = OrionRadioGroupVariant.plain;
  Axis _playgroundDirection = Axis.vertical;
  OrionRadioSize _playgroundSize = OrionRadioSize.medium;
  _ThemeOption _playgroundChoice = _ThemeOption.system;

  OrionRadioStyle? _skinStyle(ColorScheme scheme) {
    final Color muted = scheme.onSurface.withValues(alpha: 0.12);
    final Color mutedDot = scheme.onSurface.withValues(alpha: 0.38);

    return switch (_skin) {
      _RadioSkin.standard => null,
      _RadioSkin.filled => OrionRadioStyle(
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (!states.contains(WidgetState.selected)) {
            return Colors.transparent;
          }
          if (states.contains(WidgetState.disabled)) {
            return muted;
          }
          return states.contains(WidgetState.error)
              ? scheme.error
              : scheme.primary;
        }),
        dotColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return mutedDot;
          }
          return states.contains(WidgetState.error)
              ? scheme.onError
              : scheme.onPrimary;
        }),
      ),
      _RadioSkin.tinted => OrionRadioStyle(
        fillColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.04);
          }
          if (states.contains(WidgetState.selected)) {
            return (states.contains(WidgetState.error)
                    ? scheme.error
                    : scheme.primary)
                .withValues(alpha: 0.12);
          }
          return scheme.surfaceContainerHighest;
        }),
      ),
      _RadioSkin.thick => OrionRadioStyle.from(borderWidth: 3.5),
    };
  }

  String _skinLabel(_RadioSkin skin) => switch (skin) {
    _RadioSkin.standard => 'Standard',
    _RadioSkin.filled => 'Filled',
    _RadioSkin.tinted => 'Tinted',
    _RadioSkin.thick => 'Thick',
  };

  String _sizeLabel(OrionRadioSize size) => switch (size) {
    OrionRadioSize.small => 'Small',
    OrionRadioSize.medium => 'Medium',
    OrionRadioSize.large => 'Large',
  };

  String _variantLabel(OrionRadioGroupVariant variant) => switch (variant) {
    OrionRadioGroupVariant.plain => 'Plain',
    OrionRadioGroupVariant.card => 'Card',
  };

  String _directionLabel(Axis direction) => switch (direction) {
    Axis.vertical => 'Vertical',
    Axis.horizontal => 'Horizontal',
  };

  /// The exact call the current playground controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionRadioGroup<ThemeMode>(',
      '  value: ThemeMode.${_playgroundChoice.name},',
    ];
    if (_playgroundVariant != OrionRadioGroupVariant.plain) {
      lines.add(
        '  variant: OrionRadioGroupVariant.${_playgroundVariant.name},',
      );
    }
    if (_playgroundDirection != Axis.vertical) {
      lines.add('  direction: Axis.${_playgroundDirection.name},');
    }
    if (_playgroundSize != OrionRadioSize.medium) {
      lines.add('  size: OrionRadioSize.${_playgroundSize.name},');
    }
    if (_error) {
      lines.add("  error: 'Please pick a theme',");
    }
    if (_disabled) {
      lines.add('  onChanged: null, // disabled');
    } else {
      lines.add('  onChanged: (value) => setState(() => _theme = value),');
    }
    lines.add('  options: const [');
    lines.add("    OrionRadioOption(value: ThemeMode.light, label: 'Light'),");
    lines.add(
      "    OrionRadioOption(value: ThemeMode.system, label: 'System'),",
    );
    lines.add("    OrionRadioOption(value: ThemeMode.dark, label: 'Dark'),");
    lines.add('  ],');
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Radio',
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
                      'SELECTION • CRISP SPRING',
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
                    'Exclusive single-choice radio and typed radio group. Clickable labels, selectable cards, crisp spring travel, pointer hover halos, and WAI-ARIA arrow-key navigation.',
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
                    Expanded(
                      child: OrionShowcaseToggle(
                        label: 'Error',
                        value: _error,
                        onChanged: (bool value) =>
                            setState(() => _error = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Card Group
            OrionShowcaseSection(
              title: 'Radio Group — Cards',
              subtitle:
                  'Typed OrionRadioGroup with selectable cards, captions, and trailing prices',
              card: true,
              child: OrionRadioGroup<_BillingPlan>(
                label: 'Billing cycle',
                helper: 'Switch or cancel anytime',
                error: _error ? 'Please select an active plan' : null,
                variant: OrionRadioGroupVariant.card,
                value: _plan,
                enabled: !_disabled,
                onChanged: (_BillingPlan next) => setState(() => _plan = next),
                options: <OrionRadioOption<_BillingPlan>>[
                  OrionRadioOption<_BillingPlan>(
                    value: _BillingPlan.monthly,
                    label: 'Monthly',
                    subtitle: 'Flexible month-to-month billing',
                    trailing: Text(
                      r'$12/mo',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OrionRadioOption<_BillingPlan>(
                    value: _BillingPlan.yearly,
                    label: 'Yearly',
                    subtitle: 'Billed annually — save 31%',
                    trailing: Text(
                      r'$99/yr',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OrionRadioOption<_BillingPlan>(
                    value: _BillingPlan.lifetime,
                    label: 'Lifetime',
                    subtitle: 'One-time payment, all updates included',
                    trailing: Text(
                      r'$249',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Horizontal Plain Group
            OrionShowcaseSection(
              title: 'Horizontal Group',
              subtitle:
                  'Wrapping horizontal strip with clickable labels and arrow-key navigation',
              card: true,
              child: OrionRadioGroup<_Density>(
                label: 'Interface density',
                direction: Axis.horizontal,
                value: _density,
                enabled: !_disabled,
                hasError: _error,
                onChanged: (_Density next) => setState(() => _density = next),
                options: const <OrionRadioOption<_Density>>[
                  OrionRadioOption<_Density>(
                    value: _Density.compact,
                    label: 'Compact',
                  ),
                  OrionRadioOption<_Density>(
                    value: _Density.balanced,
                    label: 'Balanced',
                  ),
                  OrionRadioOption<_Density>(
                    value: _Density.spacious,
                    label: 'Spacious',
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (20 pt), Medium (24 pt), and Large (28 pt) geometry under 44 pt target',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (final OrionRadioSize size
                      in OrionRadioSize.values) ...<Widget>[
                    OrionRadio(
                      value: _sizeChoice == size,
                      label: _sizeLabel(size),
                      size: size,
                      error: _error,
                      onChanged: _disabled
                          ? null
                          : (_) => setState(() => _sizeChoice = size),
                    ),
                    if (size != OrionRadioSize.values.last)
                      const SizedBox(height: OrionSpacing.space4),
                  ],
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Next to a checkbox Card
            OrionShowcaseSection(
              title: 'Next to a Checkbox',
              subtitle:
                  'Shared crisp spring (520 / 0.80) and 0.90 tactile dip across sibling controls',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space24,
                runSpacing: OrionSpacing.space8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      OrionRadio(
                        value: _compareRadio == 0,
                        label: 'Choice A',
                        error: _error,
                        onChanged: _disabled
                            ? null
                            : (_) => setState(() => _compareRadio = 0),
                      ),
                      const SizedBox(width: OrionSpacing.space12),
                      OrionRadio(
                        value: _compareRadio == 1,
                        label: 'Choice B',
                        error: _error,
                        onChanged: _disabled
                            ? null
                            : (_) => setState(() => _compareRadio = 1),
                      ),
                    ],
                  ),
                  OrionCheckbox(
                    value: _compareCheckbox,
                    label: 'Checkbox',
                    error: _error,
                    onChanged: _disabled
                        ? null
                        : (bool? value) =>
                              setState(() => _compareCheckbox = value ?? false),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'State-aware OrionRadioStyle skins honoring disabled, hover, and error states',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseChoice<_RadioSkin>(
                    label: 'Skin',
                    values: _RadioSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (_RadioSkin value) =>
                        setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space20),
                  OrionRadioGroup<int>(
                    direction: Axis.horizontal,
                    value: _skinChoice,
                    enabled: !_disabled,
                    hasError: _error,
                    radioStyle: _skinStyle(scheme),
                    onChanged: (int next) => setState(() => _skinChoice = next),
                    options: const <OrionRadioOption<int>>[
                      OrionRadioOption<int>(value: 0, label: 'Alpha'),
                      OrionRadioOption<int>(value: 1, label: 'Beta'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive OrionRadioGroup with live generated usage snippet',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionShowcaseChoice<OrionRadioGroupVariant>(
                      label: 'Variant',
                      values: OrionRadioGroupVariant.values,
                      selected: _playgroundVariant,
                      labelOf: _variantLabel,
                      onChanged: (OrionRadioGroupVariant value) =>
                          setState(() => _playgroundVariant = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseChoice<Axis>(
                      label: 'Direction',
                      values: Axis.values,
                      selected: _playgroundDirection,
                      labelOf: _directionLabel,
                      onChanged: (Axis value) =>
                          setState(() => _playgroundDirection = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionShowcaseChoice<OrionRadioSize>(
                      label: 'Size',
                      values: OrionRadioSize.values,
                      selected: _playgroundSize,
                      labelOf: _sizeLabel,
                      onChanged: (OrionRadioSize value) =>
                          setState(() => _playgroundSize = value),
                    ),
                    const SizedBox(height: OrionSpacing.space20),
                    OrionRadioGroup<_ThemeOption>(
                      variant: _playgroundVariant,
                      direction: _playgroundDirection,
                      size: _playgroundSize,
                      value: _playgroundChoice,
                      enabled: !_disabled,
                      error: _error ? 'Please pick a theme' : null,
                      onChanged: (_ThemeOption next) =>
                          setState(() => _playgroundChoice = next),
                      options: const <OrionRadioOption<_ThemeOption>>[
                        OrionRadioOption<_ThemeOption>(
                          value: _ThemeOption.light,
                          label: 'Light',
                        ),
                        OrionRadioOption<_ThemeOption>(
                          value: _ThemeOption.system,
                          label: 'System',
                        ),
                        OrionRadioOption<_ThemeOption>(
                          value: _ThemeOption.dark,
                          label: 'Dark',
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
