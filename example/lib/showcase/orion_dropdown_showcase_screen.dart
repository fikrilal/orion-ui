import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground and verification showcase for [OrionDropdown].
///
/// The playground drives variant, size, the disabled flag, and the error flag
/// against one live specimen; the sections below are the reference matrix -
/// rich option rows, a searchable list, a long list that scrolls inside its
/// bounded panel, and the form states the field can rest in.
class OrionDropdownShowcaseScreen extends StatefulWidget {
  const OrionDropdownShowcaseScreen({super.key});

  @override
  State<OrionDropdownShowcaseScreen> createState() =>
      _OrionDropdownShowcaseScreenState();
}

class _OrionDropdownShowcaseScreenState
    extends State<OrionDropdownShowcaseScreen> {
  // Specimen options ---------------------------------------------------------

  static const List<OrionDropdownOption<String>> _environments =
      <OrionDropdownOption<String>>[
        OrionDropdownOption(
          value: 'development',
          label: 'Development',
          description: 'Local mocks and seeds',
          leading: Icon(Icons.terminal_rounded),
        ),
        OrionDropdownOption(
          value: 'staging',
          label: 'Staging',
          description: 'Release candidates',
          leading: Icon(Icons.science_rounded),
        ),
        OrionDropdownOption(
          value: 'production',
          label: 'Production',
          description: 'Customer traffic',
          leading: Icon(Icons.rocket_launch_rounded),
        ),
      ];

  static const List<OrionDropdownOption<String>> _runTargets =
      <OrionDropdownOption<String>>[
        OrionDropdownOption(
          value: 'iphone',
          label: 'iPhone 16 Pro',
          description: 'Simulator, iOS 18',
          leading: Icon(Icons.phone_iphone_rounded),
        ),
        OrionDropdownOption(
          value: 'pixel',
          label: 'Pixel 9',
          description: 'Emulator, API 35',
          leading: Icon(Icons.android_rounded),
        ),
        OrionDropdownOption(
          value: 'web',
          label: 'Chrome preview',
          description: 'Web target, hot reload',
          leading: Icon(Icons.language_rounded),
        ),
      ];

  static const List<OrionDropdownOption<String>> _queues =
      <OrionDropdownOption<String>>[
        OrionDropdownOption(
          value: 'default',
          label: 'Default queue',
          leading: OrionBadge.count(
            value: 12,
            variant: OrionBadgeVariant.primary,
          ),
        ),
        OrionDropdownOption(
          value: 'retries',
          label: 'Retry queue',
          leading: OrionBadge.count(value: 3, variant: OrionBadgeVariant.error),
        ),
        OrionDropdownOption(
          value: 'drafts',
          label: 'Draft queue',
          leading: OrionBadge(
            variant: OrionBadgeVariant.outline,
            child: Text('NEW'),
          ),
        ),
      ];

  static const List<OrionDropdownOption<String>>
  _countries = <OrionDropdownOption<String>>[
    OrionDropdownOption(
      value: 'nl',
      label: 'Netherlands',
      description: 'Europe',
    ),
    OrionDropdownOption(value: 'de', label: 'Germany', description: 'Europe'),
    OrionDropdownOption(value: 'jp', label: 'Japan', description: 'Asia'),
    OrionDropdownOption(value: 'id', label: 'Indonesia', description: 'Asia'),
  ];

  static const List<OrionDropdownOption<String>> _timezones =
      <OrionDropdownOption<String>>[
        OrionDropdownOption(
          value: 'los-angeles',
          label: 'UTC-08:00 Los Angeles',
        ),
        OrionDropdownOption(value: 'denver', label: 'UTC-07:00 Denver'),
        OrionDropdownOption(value: 'chicago', label: 'UTC-06:00 Chicago'),
        OrionDropdownOption(value: 'new-york', label: 'UTC-05:00 New York'),
        OrionDropdownOption(value: 'sao-paulo', label: 'UTC-03:00 Sao Paulo'),
        OrionDropdownOption(value: 'london', label: 'UTC+00:00 London'),
        OrionDropdownOption(value: 'berlin', label: 'UTC+01:00 Berlin'),
        OrionDropdownOption(value: 'helsinki', label: 'UTC+02:00 Helsinki'),
        OrionDropdownOption(value: 'istanbul', label: 'UTC+03:00 Istanbul'),
        OrionDropdownOption(value: 'dubai', label: 'UTC+04:00 Dubai'),
        OrionDropdownOption(value: 'mumbai', label: 'UTC+05:30 Mumbai'),
        OrionDropdownOption(value: 'jakarta', label: 'UTC+07:00 Jakarta'),
        OrionDropdownOption(value: 'singapore', label: 'UTC+08:00 Singapore'),
        OrionDropdownOption(value: 'tokyo', label: 'UTC+09:00 Tokyo'),
        OrionDropdownOption(value: 'sydney', label: 'UTC+10:00 Sydney'),
        OrionDropdownOption(value: 'auckland', label: 'UTC+13:00 Auckland'),
      ];

  static const List<OrionDropdownOption<String>> _plans =
      <OrionDropdownOption<String>>[
        OrionDropdownOption(value: 'starter', label: 'Starter'),
        OrionDropdownOption(value: 'pro', label: 'Pro'),
        OrionDropdownOption(value: 'business', label: 'Business'),
      ];

  static const List<OrionDropdownOption<String>> _archived =
      <OrionDropdownOption<String>>[
        OrionDropdownOption(value: 'legacy', label: 'Legacy'),
        OrionDropdownOption(value: 'sunset', label: 'Sunset'),
        OrionDropdownOption(value: 'archived', label: 'Archived'),
      ];

  static const List<OrionDropdownOption<String>> _roles =
      <OrionDropdownOption<String>>[
        OrionDropdownOption(
          value: 'admin',
          label: 'Admin',
          description: 'Full workspace access',
        ),
        OrionDropdownOption(
          value: 'editor',
          label: 'Editor',
          description: 'Can edit content',
        ),
        OrionDropdownOption(
          value: 'viewer',
          label: 'Viewer',
          description: 'Read-only access',
        ),
        OrionDropdownOption(
          value: 'guest',
          label: 'Guest',
          description: 'Included with the Free plan',
          enabled: false,
        ),
      ];

  // Playground state ---------------------------------------------------------

  OrionDropdownVariant _variant = OrionDropdownVariant.outline;
  OrionDropdownSize _size = OrionDropdownSize.medium;
  bool _disabled = false;
  bool _showError = false;
  String? _environment;

  // Specimen state -----------------------------------------------------------

  String? _runTarget;
  String? _queue;
  String? _timezone;
  String? _country;
  String? _role;

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionDropdown<String>(',
      _environment == null
          ? '  value: null, // shows the placeholder'
          : "  value: '$_environment',",
      "  placeholder: 'Choose environment',",
      '  variant: OrionDropdownVariant.${_variant.name},',
      '  size: OrionDropdownSize.${_size.name},',
      if (_disabled) '  enabled: false,',
      if (_showError) "  error: 'Pick an environment',",
      '  onChanged: (value) => setState(() => _environment = value),',
      '  options: const <OrionDropdownOption<String>>[',
      "    OrionDropdownOption(value: 'development', label: 'Development'),",
      "    OrionDropdownOption(value: 'staging', label: 'Staging'),",
      "    OrionDropdownOption(value: 'production', label: 'Production'),",
      '  ],',
      ');',
    ];
    return lines.join('\n');
  }

  /// Keeps a specimen field at a readable form width.
  Widget _field(Widget child) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 360),
      child: child,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Dropdown',
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
                      'FORM • DROPDOWN',
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
                    'A physics-driven single-select form control. The option '
                    'panel blossoms directly out of the trigger anchor using '
                    "Emil Kowalski's transform-origin law, with a bounded "
                    'scrollable list, wrap-around keyboard navigation, and '
                    'FormField validation shared with OrionTextField.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Interactive Playground
            OrionShowcaseSection(
              title: 'Interactive Playground',
              subtitle:
                  'Switch variant, size, and the state flags to inspect the blossom kinematics and validation row',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                code: _snippet,
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        vertical: OrionSpacing.space20,
                        horizontal: OrionSpacing.space16,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(OrionRadii.radius12),
                        border: Border.all(
                          color: scheme.outlineVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Center(
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: OrionDropdown<String>(
                            key: const ValueKey<String>(
                              'showcase-dropdown-playground',
                            ),
                            value: _environment,
                            placeholder: 'Choose environment',
                            variant: _variant,
                            size: _size,
                            enabled: !_disabled,
                            error: _showError ? 'Pick an environment' : null,
                            options: _environments,
                            onChanged: (value) =>
                                setState(() => _environment = value),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Text(
                      'Selected: ${_environment ?? 'none'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseControls(
                      children: [
                        OrionShowcaseChoice<OrionDropdownVariant>(
                          label: 'Variant',
                          selected: _variant,
                          values: const [
                            OrionDropdownVariant.outline,
                            OrionDropdownVariant.filled,
                            OrionDropdownVariant.underline,
                          ],
                          labelOf: (value) => switch (value) {
                            OrionDropdownVariant.outline => 'OUTLINE',
                            OrionDropdownVariant.filled => 'FILLED',
                            OrionDropdownVariant.underline => 'UNDERLINE',
                          },
                          onChanged: (value) =>
                              setState(() => _variant = value),
                        ),
                        OrionShowcaseChoice<OrionDropdownSize>(
                          label: 'Size',
                          selected: _size,
                          values: const [
                            OrionDropdownSize.small,
                            OrionDropdownSize.medium,
                            OrionDropdownSize.large,
                          ],
                          labelOf: (value) => switch (value) {
                            OrionDropdownSize.small => 'SMALL',
                            OrionDropdownSize.medium => 'MEDIUM',
                            OrionDropdownSize.large => 'LARGE',
                          },
                          onChanged: (value) => setState(() => _size = value),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: OrionShowcaseToggle(
                                label: 'Disabled',
                                value: _disabled,
                                onChanged: (value) =>
                                    setState(() => _disabled = value),
                              ),
                            ),
                            Expanded(
                              child: OrionShowcaseToggle(
                                label: 'Error',
                                value: _showError,
                                onChanged: (value) =>
                                    setState(() => _showError = value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Rich Option Rows Specimen
            OrionShowcaseSection(
              title: 'Rich Option Rows',
              subtitle:
                  'Leading icons and badges with secondary description lines inside the panel',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-options'),
                code: '''
OrionDropdown<String>(
  value: runTarget,
  placeholder: 'Pick a run target',
  onChanged: (value) => setState(() => runTarget = value),
  options: const <OrionDropdownOption<String>>[
    OrionDropdownOption(
      value: 'iphone',
      label: 'iPhone 16 Pro',
      description: 'Simulator, iOS 18',
      leading: Icon(Icons.phone_iphone_rounded),
    ),
    OrionDropdownOption(
      value: 'pixel',
      label: 'Pixel 9',
      description: 'Emulator, API 35',
      leading: Icon(Icons.android_rounded),
    ),
    // A badge can lead a row too, when the status matters more than the type.
    OrionDropdownOption(
      value: 'web',
      label: 'Chrome preview',
      leading: OrionBadge.count(value: 12),
    ),
  ],
)''',
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OrionShowcaseLabeledRow(
                      label: 'Icons + detail',
                      labelWidth: 120,
                      child: _field(
                        OrionDropdown<String>(
                          key: const ValueKey<String>(
                            'showcase-dropdown-targets',
                          ),
                          value: _runTarget,
                          placeholder: 'Pick a run target',
                          options: _runTargets,
                          onChanged: (value) =>
                              setState(() => _runTarget = value),
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space20),
                    OrionShowcaseLabeledRow(
                      label: 'Badge leading',
                      labelWidth: 120,
                      child: _field(
                        OrionDropdown<String>(
                          key: const ValueKey<String>(
                            'showcase-dropdown-queues',
                          ),
                          value: _queue,
                          placeholder: 'Pick a queue',
                          options: _queues,
                          onChanged: (value) => setState(() => _queue = value),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Long List Specimen
            OrionShowcaseSection(
              title: 'Long List & Inner Scrolling',
              subtitle:
                  '16 timezones inside the 320 pt panel cap; the option list scrolls while the field stays put',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-long-list'),
                code: '''
OrionDropdown<String>(
  value: timezone,
  placeholder: 'Jump to a timezone',
  onChanged: (value) => setState(() => timezone = value),
  // Sixteen options; the panel caps its own height and scrolls the list.
  options: const <OrionDropdownOption<String>>[
    OrionDropdownOption(value: 'los-angeles', label: 'UTC-08:00 Los Angeles'),
    OrionDropdownOption(value: 'london', label: 'UTC+00:00 London'),
    OrionDropdownOption(value: 'auckland', label: 'UTC+13:00 Auckland'),
  ],
)''',
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      OrionDropdown<String>(
                        key: const ValueKey<String>(
                          'showcase-dropdown-timezones',
                        ),
                        value: _timezone,
                        placeholder: 'Jump to a timezone',
                        options: _timezones,
                        onChanged: (value) => setState(() => _timezone = value),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Text(
                      'Timezone: ${_timezone ?? 'none'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            OrionShowcaseSection(
              title: 'Searchable',
              subtitle:
                  'The open face takes a query. The list keeps a case-insensitive subsequence, and closing clears it',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-search'),
                code: '''
OrionDropdown<String>(
  searchable: true,
  value: country,
  placeholder: 'Find a country',
  onChanged: (value) => setState(() => country = value),
  options: const <OrionDropdownOption<String>>[
    OrionDropdownOption(value: 'nl', label: 'Netherlands'),
    OrionDropdownOption(value: 'jp', label: 'Japan'),
  ],
)''',
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      OrionDropdown<String>(
                        key: const ValueKey<String>('showcase-dropdown-search'),
                        searchable: true,
                        value: _country,
                        placeholder: 'Find a country',
                        options: _countries,
                        onChanged: (value) => setState(() => _country = value),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Text(
                      'Country: ${_country ?? 'none'}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Form States Specimen
            OrionShowcaseSection(
              title: 'Form States',
              subtitle:
                  'Placeholder, selected value, disabled face, error text, and a label + helper caption',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseLabeledRow(
                    label: 'Placeholder',
                    labelWidth: 120,
                    child: _field(
                      OrionDropdown<String>(
                        placeholder: 'Pick a plan',
                        options: _plans,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionShowcaseLabeledRow(
                    label: 'Selected value',
                    labelWidth: 120,
                    child: _field(
                      OrionDropdown<String>(
                        value: 'pro',
                        options: _plans,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionShowcaseLabeledRow(
                    label: 'Disabled',
                    labelWidth: 120,
                    child: _field(
                      OrionDropdown<String>(
                        key: const ValueKey<String>(
                          'showcase-dropdown-disabled',
                        ),
                        enabled: false,
                        placeholder: 'Unavailable',
                        options: _archived,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionShowcaseLabeledRow(
                    label: 'Error',
                    labelWidth: 120,
                    child: _field(
                      OrionDropdown<String>(
                        error: 'A plan is required',
                        placeholder: 'Required plan',
                        options: _plans,
                        onChanged: (_) {},
                      ),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionShowcaseLabeledRow(
                    label: 'Label + helper',
                    labelWidth: 120,
                    child: _field(
                      OrionDropdown<String>(
                        key: const ValueKey<String>('showcase-dropdown-role'),
                        value: _role,
                        label: 'Workspace role',
                        helper: 'Owners are assigned in billing settings',
                        placeholder: 'Select a role',
                        options: _roles,
                        onChanged: (value) => setState(() => _role = value),
                      ),
                    ),
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
