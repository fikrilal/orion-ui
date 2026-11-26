import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground and verification showcase for [OrionSwitch].
class OrionSwitchShowcaseScreen extends StatefulWidget {
  const OrionSwitchShowcaseScreen({super.key});

  @override
  State<OrionSwitchShowcaseScreen> createState() =>
      _OrionSwitchShowcaseScreenState();
}

enum _SwitchSkin { standard, emerald, destructive }

class _OrionSwitchShowcaseScreenState extends State<OrionSwitchShowcaseScreen> {
  // Playground controls
  OrionSwitchSize _size = OrionSwitchSize.medium;
  _SwitchSkin _skin = _SwitchSkin.standard;
  bool _showIcons = false;
  bool _disabled = false;
  bool _playgroundOn = true;

  // Sizes & thumb icons section
  bool _smallOn = true;
  bool _mediumOn = true;
  bool _largeOn = true;
  bool _darkIconOn = false;
  bool _muteIconOn = true;

  // Settings rows section
  bool _pushNotifications = true;
  bool _hapticFeedback = true;
  bool _cellularSync = false;
  bool _leadingLogs = true;

  // States matrix
  bool _stateOff = false;
  bool _stateOn = true;

  OrionSwitchStyle? _skinStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    const Color emerald = Color(0xFF16A34A);
    return switch (_skin) {
      _SwitchSkin.standard => null,
      _SwitchSkin.emerald => OrionSwitchStyle(
        trackColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return states.contains(WidgetState.disabled)
                ? emerald.withValues(alpha: 0.38)
                : emerald;
          }
          return states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.12)
              : scheme.outline;
        }),
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surface.withValues(alpha: 0.72);
          }
          return Colors.white;
        }),
        activeIconColor: emerald,
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
        thumbColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.surface.withValues(alpha: 0.72);
          }
          return states.contains(WidgetState.selected)
              ? scheme.onError
              : (scheme.brightness == Brightness.dark
                    ? scheme.onSurface
                    : scheme.surface);
        }),
        activeIconColor: scheme.error,
      ),
    };
  }

  String _sizeLabel(OrionSwitchSize size) => switch (size) {
    OrionSwitchSize.small => 'Small',
    OrionSwitchSize.medium => 'Medium',
    OrionSwitchSize.large => 'Large',
  };

  String _skinLabel(_SwitchSkin skin) => switch (skin) {
    _SwitchSkin.standard => 'Standard',
    _SwitchSkin.emerald => 'Emerald',
    _SwitchSkin.destructive => 'Destructive',
  };

  String get _snippet {
    final List<String> lines = <String>[
      'OrionSwitch(',
      '  value: $_playgroundOn,',
      if (_size != OrionSwitchSize.medium)
        '  size: OrionSwitchSize.${_size.name},',
      if (_showIcons) ...<String>[
        '  activeIcon: const Icon(Icons.check_rounded),',
        '  inactiveIcon: const Icon(Icons.close_rounded),',
      ],
      "  semanticLabel: 'Notifications',",
      if (_disabled)
        '  onChanged: null, // disabled'
      else
        '  onChanged: (bool value) => setState(() => _on = value),',
      ');',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Orion Switch',
      builder: (BuildContext context) {
        final ThemeData theme = Theme.of(context);
        final ColorScheme scheme = theme.colorScheme;
        final bool isDark = theme.brightness == Brightness.dark;
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
                      'SELECTION • DRAG & CAPSULE PHYSICS',
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
                    'Tactile pill switch supporting tap, horizontal drag/flick '
                    'with midpoint haptics, true stadium capsule elongation on '
                    'hold, optional thumb icons, and clickable settings rows.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
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
                  'Tap, hold to feel capsule elongation, or drag horizontally across the track',
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
                        horizontal: OrionSpacing.space16,
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
                      child: Column(
                        children: <Widget>[
                          OrionSwitch(
                            value: _playgroundOn,
                            size: _size,
                            style: _skinStyle(context),
                            activeIcon: _showIcons
                                ? const Icon(Icons.check_rounded)
                                : null,
                            inactiveIcon: _showIcons
                                ? const Icon(Icons.close_rounded)
                                : null,
                            semanticLabel: 'Notifications',
                            tooltip: 'Tap or drag to toggle',
                            onChanged: _disabled
                                ? null
                                : (bool value) =>
                                      setState(() => _playgroundOn = value),
                          ),
                          const SizedBox(height: OrionSpacing.space8),
                          Text(
                            _disabled
                                ? 'Disabled (${_playgroundOn ? 'On' : 'Off'})'
                                : (_playgroundOn ? 'On' : 'Off'),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseControls(
                      children: <Widget>[
                        OrionShowcaseChoice<OrionSwitchSize>(
                          label: 'Size',
                          values: OrionSwitchSize.values,
                          selected: _size,
                          labelOf: _sizeLabel,
                          onChanged: (OrionSwitchSize v) =>
                              setState(() => _size = v),
                        ),
                        OrionShowcaseChoice<_SwitchSkin>(
                          label: 'Skin',
                          values: _SwitchSkin.values,
                          selected: _skin,
                          labelOf: _skinLabel,
                          onChanged: (_SwitchSkin v) =>
                              setState(() => _skin = v),
                        ),
                        Wrap(
                          spacing: OrionSpacing.space24,
                          runSpacing: OrionSpacing.space12,
                          children: <Widget>[
                            OrionShowcaseToggle(
                              label: 'Thumb Icons',
                              value: _showIcons,
                              onChanged: (bool v) =>
                                  setState(() => _showIcons = v),
                            ),
                            OrionShowcaseToggle(
                              label: 'Disabled',
                              value: _disabled,
                              onChanged: (bool v) =>
                                  setState(() => _disabled = v),
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

            // Sizes & Thumb Icons Card
            OrionShowcaseSection(
              title: 'Sizes & Thumb Icons',
              subtitle:
                  'Small (40×24 with 44 pt hit target), Medium (52×32), Large (64×38), and undistorted capsule icons',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseLabeledRow(
                    label: 'Small',
                    child: OrionSwitch(
                      size: OrionSwitchSize.small,
                      value: _smallOn,
                      onChanged: (bool v) => setState(() => _smallOn = v),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseLabeledRow(
                    label: 'Medium',
                    child: OrionSwitch(
                      size: OrionSwitchSize.medium,
                      value: _mediumOn,
                      onChanged: (bool v) => setState(() => _mediumOn = v),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseLabeledRow(
                    label: 'Large',
                    child: OrionSwitch(
                      size: OrionSwitchSize.large,
                      value: _largeOn,
                      onChanged: (bool v) => setState(() => _largeOn = v),
                    ),
                  ),
                  const Divider(height: OrionSpacing.space24),
                  OrionShowcaseLabeledRow(
                    label: 'Appearance',
                    child: OrionSwitch(
                      size: OrionSwitchSize.large,
                      value: _darkIconOn,
                      activeIcon: const Icon(Icons.dark_mode_rounded),
                      inactiveIcon: const Icon(Icons.light_mode_rounded),
                      onChanged: (bool v) => setState(() => _darkIconOn = v),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseLabeledRow(
                    label: 'Sound',
                    child: OrionSwitch(
                      value: _muteIconOn,
                      activeIcon: const Icon(Icons.volume_up_rounded),
                      inactiveIcon: const Icon(Icons.volume_off_rounded),
                      onChanged: (bool v) => setState(() => _muteIconOn = v),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Settings Rows (Label, Subtitle & Control Affinity)
            OrionShowcaseSection(
              title: 'Labeled Settings Rows',
              subtitle:
                  'Full-row tap targets with unified screen-reader semantics and trailing or leading placement',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionSwitch(
                    value: _pushNotifications,
                    label: 'Push notifications',
                    subtitle: 'Alerts for mentions, replies, and task updates',
                    onChanged: (bool v) =>
                        setState(() => _pushNotifications = v),
                  ),
                  const Divider(height: OrionSpacing.space24),
                  OrionSwitch(
                    value: _hapticFeedback,
                    label: 'Tactile haptics',
                    subtitle: 'Selection tick on flip and midpoint drag detent',
                    onChanged: (bool v) => setState(() => _hapticFeedback = v),
                  ),
                  const Divider(height: OrionSpacing.space24),
                  OrionSwitch(
                    value: _cellularSync,
                    label: 'Sync over cellular',
                    subtitle: 'Download media attachments without Wi-Fi',
                    onChanged: (bool v) => setState(() => _cellularSync = v),
                  ),
                  const Divider(height: OrionSpacing.space24),
                  const OrionSwitch(
                    value: true,
                    label: 'Enterprise SSO',
                    subtitle: 'Managed by your workspace administrator',
                    onChanged: null,
                  ),
                  const Divider(height: OrionSpacing.space24),
                  OrionSwitch(
                    value: _leadingLogs,
                    size: OrionSwitchSize.small,
                    controlAffinity: OrionSwitchControlAffinity.leading,
                    label: 'Include diagnostic logs',
                    onChanged: (bool v) => setState(() => _leadingLogs = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // States Reference Matrix
            OrionShowcaseSection(
              title: 'States Matrix',
              subtitle:
                  'Enabled and disabled contrast across light and dark schemes',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseLabeledRow(
                    label: 'Off',
                    child: OrionSwitch(
                      value: _stateOff,
                      onChanged: (bool v) => setState(() => _stateOff = v),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseLabeledRow(
                    label: 'On',
                    child: OrionSwitch(
                      value: _stateOn,
                      onChanged: (bool v) => setState(() => _stateOn = v),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  const OrionShowcaseLabeledRow(
                    label: 'Disabled Off',
                    child: OrionSwitch(value: false, onChanged: null),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  const OrionShowcaseLabeledRow(
                    label: 'Disabled On',
                    child: OrionSwitch(value: true, onChanged: null),
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
