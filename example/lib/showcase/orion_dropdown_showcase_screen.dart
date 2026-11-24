import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground and verification showcase for [OrionDropdown] and
/// [OrionDropdown.multi].
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
        OrionDropdownOption<String>(
          value: 'development',
          label: 'Development',
          description: 'Local mocks and seeds',
          leading: Icon(Icons.terminal_rounded),
          trailing: OrionBadge(
            label: 'LOCAL',
            variant: OrionBadgeVariant.neutral,
            size: OrionBadgeSize.small,
          ),
        ),
        OrionDropdownOption<String>(
          value: 'staging',
          label: 'Staging',
          description: 'Release candidates',
          leading: Icon(Icons.science_rounded),
          trailing: OrionBadge(
            label: 'QA',
            variant: OrionBadgeVariant.outline,
            size: OrionBadgeSize.small,
          ),
        ),
        OrionDropdownOption<String>(
          value: 'production',
          label: 'Production',
          description: 'Customer traffic',
          leading: Icon(Icons.rocket_launch_rounded),
          trailing: OrionBadge(
            label: 'LIVE',
            variant: OrionBadgeVariant.primary,
            size: OrionBadgeSize.small,
          ),
        ),
      ];

  static const List<OrionDropdownOption<String>> _skillOptions =
      <OrionDropdownOption<String>>[
        OrionDropdownOption<String>(
          value: 'flutter',
          label: 'Flutter',
          description: 'Cross-platform UI toolkit',
          group: 'Mobile',
        ),
        OrionDropdownOption<String>(
          value: 'swift',
          label: 'SwiftUI',
          description: 'Native Apple interfaces',
          group: 'Mobile',
        ),
        OrionDropdownOption<String>(
          value: 'kotlin',
          label: 'Jetpack Compose',
          description: 'Modern Android UI',
          group: 'Mobile',
        ),
        OrionDropdownOption<String>(
          value: 'rust',
          label: 'Rust',
          description: 'Systems & backend services',
          group: 'Backend',
        ),
        OrionDropdownOption<String>(
          value: 'go',
          label: 'Go',
          description: 'Cloud-native APIs',
          group: 'Backend',
        ),
        OrionDropdownOption<String>(
          value: 'postgres',
          label: 'PostgreSQL',
          description: 'Relational data store',
          group: 'Backend',
        ),
      ];

  static const List<OrionDropdownOption<String>> _countries =
      <OrionDropdownOption<String>>[
        OrionDropdownOption<String>(
          value: 'id',
          label: 'Indonesia',
          description: 'Jakarta (UTC+7)',
          group: 'Asia',
          searchTerms: <String>['IDN', 'Jakarta'],
          trailing: Text('ID'),
        ),
        OrionDropdownOption<String>(
          value: 'jp',
          label: 'Japan',
          description: 'Tokyo (UTC+9)',
          group: 'Asia',
          searchTerms: <String>['Nippon', 'JP', 'Tokyo'],
          trailing: Text('JP'),
        ),
        OrionDropdownOption<String>(
          value: 'sg',
          label: 'Singapore',
          description: 'Singapore (UTC+8)',
          group: 'Asia',
          searchTerms: <String>['SG'],
          trailing: Text('SG'),
        ),
        OrionDropdownOption<String>(
          value: 'nl',
          label: 'Netherlands',
          description: 'Amsterdam (UTC+1)',
          group: 'Europe',
          searchTerms: <String>['Holland', 'NL'],
          trailing: Text('NL'),
        ),
        OrionDropdownOption<String>(
          value: 'de',
          label: 'Germany',
          description: 'Berlin (UTC+1)',
          group: 'Europe',
          searchTerms: <String>['Deutschland', 'DE'],
          trailing: Text('DE'),
        ),
        OrionDropdownOption<String>(
          value: 'gb',
          label: 'United Kingdom',
          description: 'London (UTC+0)',
          group: 'Europe',
          searchTerms: <String>['UK', 'Britain', 'London'],
          trailing: Text('UK'),
        ),
        OrionDropdownOption<String>(
          value: 'us',
          label: 'United States',
          description: 'New York (UTC-5)',
          group: 'Americas',
          searchTerms: <String>['USA', 'America', 'US'],
          trailing: Text('US'),
        ),
        OrionDropdownOption<String>(
          value: 'ca',
          label: 'Canada',
          description: 'Toronto (UTC-5)',
          group: 'Americas',
          searchTerms: <String>['CA'],
          trailing: Text('CA'),
        ),
      ];

  static const List<OrionDropdownOption<String>> _timezones =
      <OrionDropdownOption<String>>[
        OrionDropdownOption<String>(
          value: 'los-angeles',
          label: 'UTC-08:00 Los Angeles',
        ),
        OrionDropdownOption<String>(value: 'denver', label: 'UTC-07:00 Denver'),
        OrionDropdownOption<String>(
          value: 'chicago',
          label: 'UTC-06:00 Chicago',
        ),
        OrionDropdownOption<String>(
          value: 'new-york',
          label: 'UTC-05:00 New York',
        ),
        OrionDropdownOption<String>(
          value: 'sao-paulo',
          label: 'UTC-03:00 Sao Paulo',
        ),
        OrionDropdownOption<String>(value: 'london', label: 'UTC+00:00 London'),
        OrionDropdownOption<String>(value: 'berlin', label: 'UTC+01:00 Berlin'),
        OrionDropdownOption<String>(
          value: 'helsinki',
          label: 'UTC+02:00 Helsinki',
        ),
        OrionDropdownOption<String>(
          value: 'istanbul',
          label: 'UTC+03:00 Istanbul',
        ),
        OrionDropdownOption<String>(value: 'dubai', label: 'UTC+04:00 Dubai'),
        OrionDropdownOption<String>(value: 'mumbai', label: 'UTC+05:30 Mumbai'),
        OrionDropdownOption<String>(
          value: 'jakarta',
          label: 'UTC+07:00 Jakarta',
        ),
        OrionDropdownOption<String>(
          value: 'singapore',
          label: 'UTC+08:00 Singapore',
        ),
        OrionDropdownOption<String>(value: 'tokyo', label: 'UTC+09:00 Tokyo'),
        OrionDropdownOption<String>(value: 'sydney', label: 'UTC+10:00 Sydney'),
        OrionDropdownOption<String>(
          value: 'auckland',
          label: 'UTC+13:00 Auckland',
        ),
      ];

  static const List<OrionDropdownOption<String>> _roles =
      <OrionDropdownOption<String>>[
        OrionDropdownOption<String>(
          value: 'admin',
          label: 'Admin',
          description: 'Full workspace access',
        ),
        OrionDropdownOption<String>(
          value: 'editor',
          label: 'Editor',
          description: 'Can edit content',
        ),
        OrionDropdownOption<String>(
          value: 'viewer',
          label: 'Viewer',
          description: 'Read-only access',
        ),
        OrionDropdownOption<String>(
          value: 'guest',
          label: 'Guest',
          description: 'Included with the Free plan',
          enabled: false,
        ),
      ];

  // Playground state ---------------------------------------------------------

  OrionDropdownVariant _variant = OrionDropdownVariant.outline;
  OrionDropdownSize _size = OrionDropdownSize.medium;
  OrionDropdownPresentation _presentation = OrionDropdownPresentation.popover;
  bool _searchable = false;
  bool _clearable = true;
  bool _isLoading = false;
  bool _disabled = false;
  bool _showError = false;
  String? _environment = 'staging';

  // Specimen state -----------------------------------------------------------

  Set<String> _selectedSkills = <String>{'flutter', 'rust'};
  OrionDropdownPresentation _multiPresentation =
      OrionDropdownPresentation.popover;
  String? _country;
  String? _timezone;
  String? _role;

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionDropdown<String>(',
      _environment == null
          ? '  value: null,'
          : "  value: '$_environment',",
      "  placeholder: 'Choose environment',",
      '  variant: OrionDropdownVariant.${_variant.name},',
      '  size: OrionDropdownSize.${_size.name},',
      if (_presentation != OrionDropdownPresentation.popover)
        '  presentation: OrionDropdownPresentation.${_presentation.name},',
      if (_searchable) '  searchable: true,',
      if (_clearable) ...<String>[
        '  clearable: true,',
        '  onCleared: () => setState(() => _environment = null),',
      ],
      if (_isLoading) '  isLoading: true,',
      if (_disabled) '  enabled: false,',
      if (_showError) "  error: 'Pick an environment',",
      '  onChanged: (value) => setState(() => _environment = value),',
      '  options: _environments,',
      ');',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Dropdown',
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
                      borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
                      border: Border.all(
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.20)
                            : scheme.outlineVariant.withValues(alpha: 0.35),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'FORM • SELECT & COMBOBOX',
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
                    'Single- and multi-select dropdown with full trigger-width popover or modal bottom-sheet presentation, in-panel combobox search, grouped sections, clearable values, and FormField validation.',
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
                  'Test variant, size, presentation (popover / sheet / auto), in-panel search, clearable, and loading states',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                code: _snippet,
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
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
                          color: scheme.outlineVariant.withValues(alpha: 0.25),
                        ),
                      ),
                      child: OrionDropdown<String>(
                        key: const ValueKey<String>(
                          'showcase-dropdown-playground',
                        ),
                        value: _environment,
                        placeholder: 'Choose environment',
                        variant: _variant,
                        size: _size,
                        presentation: _presentation,
                        searchable: _searchable,
                        clearable: _clearable,
                        isLoading: _isLoading,
                        enabled: !_disabled,
                        error: _showError ? 'Pick an environment' : null,
                        options: _environments,
                        onChanged: (String value) =>
                            setState(() => _environment = value),
                        onCleared: () => setState(() => _environment = null),
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
                      children: <Widget>[
                        OrionShowcaseChoice<OrionDropdownVariant>(
                          label: 'Variant',
                          selected: _variant,
                          values: OrionDropdownVariant.values,
                          labelOf: (OrionDropdownVariant v) =>
                              v.name.toUpperCase(),
                          onChanged: (OrionDropdownVariant value) =>
                              setState(() => _variant = value),
                        ),
                        OrionShowcaseChoice<OrionDropdownSize>(
                          label: 'Size',
                          selected: _size,
                          values: OrionDropdownSize.values,
                          labelOf: (OrionDropdownSize s) =>
                              s.name.toUpperCase(),
                          onChanged: (OrionDropdownSize value) =>
                              setState(() => _size = value),
                        ),
                        OrionShowcaseChoice<OrionDropdownPresentation>(
                          label: 'Presentation',
                          selected: _presentation,
                          values: OrionDropdownPresentation.values,
                          labelOf: (OrionDropdownPresentation p) =>
                              p.name.toUpperCase(),
                          onChanged: (OrionDropdownPresentation value) =>
                              setState(() => _presentation = value),
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OrionShowcaseToggle(
                                label: 'Searchable',
                                value: _searchable,
                                onChanged: (bool value) =>
                                    setState(() => _searchable = value),
                              ),
                            ),
                            Expanded(
                              child: OrionShowcaseToggle(
                                label: 'Clearable',
                                value: _clearable,
                                onChanged: (bool value) =>
                                    setState(() => _clearable = value),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: OrionShowcaseToggle(
                                label: 'Loading',
                                value: _isLoading,
                                onChanged: (bool value) =>
                                    setState(() => _isLoading = value),
                              ),
                            ),
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
                        OrionShowcaseToggle(
                          label: 'Error',
                          value: _showError,
                          onChanged: (bool value) =>
                              setState(() => _showError = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Multi-Select Section
            OrionShowcaseSection(
              title: 'Multi-Select & Inline Tags',
              subtitle:
                  'OrionDropdown.multi with checkboxes, grouped sections, inline tags, +N overflow, and Clear/Done footer',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseChoice<OrionDropdownPresentation>(
                    label: 'Presentation',
                    selected: _multiPresentation,
                    values: const <OrionDropdownPresentation>[
                      OrionDropdownPresentation.popover,
                      OrionDropdownPresentation.sheet,
                    ],
                    labelOf: (OrionDropdownPresentation p) =>
                        p.name.toUpperCase(),
                    onChanged: (OrionDropdownPresentation value) =>
                        setState(() => _multiPresentation = value),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionDropdown<String>.multi(
                    key: const ValueKey<String>('showcase-dropdown-multi'),
                    label: 'Tech stack',
                    placeholder: 'Select skills',
                    searchable: true,
                    clearable: true,
                    maxVisibleTags: 2,
                    presentation: _multiPresentation,
                    options: _skillOptions,
                    values: _selectedSkills,
                    onValuesChanged: (Set<String> next) =>
                        setState(() => _selectedSkills = next),
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Grouped Searchable Bottom-Sheet Picker
            OrionShowcaseSection(
              title: 'Grouped Searchable Sheet Picker',
              subtitle:
                  'Bottom-sheet mode with group headers, search aliases (try "USA", "UK", "Nippon"), and trailing country codes',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionDropdown<String>(
                    key: const ValueKey<String>('showcase-dropdown-countries'),
                    label: 'Country / Region',
                    placeholder: 'Find a country',
                    searchPlaceholder: 'Search name, region, or code...',
                    searchable: true,
                    clearable: true,
                    presentation: OrionDropdownPresentation.sheet,
                    value: _country,
                    options: _countries,
                    onChanged: (String value) =>
                        setState(() => _country = value),
                    onCleared: () => setState(() => _country = null),
                  ),
                ],
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Adaptive Long List (16 Timezones)
            OrionShowcaseSection(
              title: 'Adaptive Long List (Auto Presentation)',
              subtitle:
                  '16 timezones using presentation: auto — opens as a bottom sheet on phones and anchored popover on wide screens',
              card: true,
              child: OrionDropdown<String>(
                key: const ValueKey<String>('showcase-dropdown-timezones'),
                label: 'Timezone',
                placeholder: 'Jump to a timezone',
                searchable: true,
                clearable: true,
                presentation: OrionDropdownPresentation.auto,
                value: _timezone,
                options: _timezones,
                onChanged: (String value) => setState(() => _timezone = value),
                onCleared: () => setState(() => _timezone = null),
              ),
            ),

            const SizedBox(height: OrionSpacing.space20),

            // Form States Specimen
            OrionShowcaseSection(
              title: 'Form States & Disabled Options',
              subtitle:
                  'Disabled items skipped by keyboard navigation, helper captions, and error styling',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionDropdown<String>(
                    key: const ValueKey<String>('showcase-dropdown-role'),
                    value: _role,
                    clearable: true,
                    label: 'Workspace role',
                    helper: 'Owners are assigned in billing settings',
                    placeholder: 'Select a role',
                    options: _roles,
                    onChanged: (String value) => setState(() => _role = value),
                    onCleared: () => setState(() => _role = null),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionDropdown<String>(
                    enabled: false,
                    label: 'Disabled field',
                    placeholder: 'Unavailable',
                    options: _roles,
                    onChanged: (_) {},
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionDropdown<String>(
                    label: 'Required field',
                    error: 'A workspace role is required',
                    placeholder: 'Select a role',
                    options: _roles,
                    onChanged: (_) {},
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
