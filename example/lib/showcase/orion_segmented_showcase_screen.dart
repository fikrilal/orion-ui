import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionSegmentedControl].
///
/// The `Disabled` flag in the top controls card gates every sample; the
/// sections below showcase drag-to-scrub, size steps, intrinsic width &
/// icon-only toolbars, animated badges, per-segment disabled options,
/// state-aware skins, and an interactive playground with live code output.
class OrionSegmentedShowcaseScreen extends StatefulWidget {
  const OrionSegmentedShowcaseScreen({super.key});

  @override
  State<OrionSegmentedShowcaseScreen> createState() =>
      _OrionSegmentedShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _SegmentSkin { standard, brand, rounded, outline }

enum _ViewMode { list, grid, map }

class _OrionSegmentedShowcaseScreenState
    extends State<OrionSegmentedShowcaseScreen> {
  static const List<OrionSegment<String>> _tripSegments =
      <OrionSegment<String>>[
        OrionSegment<String>(value: 'overview', label: Text('Overview')),
        OrionSegment<String>(value: 'live', label: Text('Live')),
        OrionSegment<String>(value: 'tickets', label: Text('Tickets')),
      ];

  static const List<OrionSegment<String>> _rangeSegments =
      <OrionSegment<String>>[
        OrionSegment<String>(value: 'today', label: Text('Today')),
        OrionSegment<String>(value: 'week', label: Text('Week')),
      ];

  // Flag: shared by every sample on the page.
  bool _disabled = false;

  // Samples.
  String _trip = 'live';
  String _smallChoice = 'overview';
  String _mediumChoice = 'live';
  String _largeChoice = 'tickets';
  _ViewMode _viewMode = _ViewMode.grid;
  String _range = 'today';
  String _badgeChoice = 'live';
  bool _showCounts = true;
  String _tierChoice = 'pro';

  // Customization.
  _SegmentSkin _skin = _SegmentSkin.standard;
  String _skinTrip = 'live';

  // Playground.
  OrionSegmentedControlSize _playgroundSize = OrionSegmentedControlSize.medium;
  bool _playgroundExpand = true;
  bool _playgroundIcons = false;
  bool _playgroundBadges = false;
  String _playground = 'overview';

  OrionSegmentedControl<T> _sample<T>({
    required T value,
    required ValueChanged<T> onChanged,
    required List<OrionSegment<T>> segments,
    OrionSegmentedControlSize size = OrionSegmentedControlSize.medium,
    bool expand = true,
    OrionSegmentedControlStyle? style,
  }) {
    return OrionSegmentedControl<T>(
      value: value,
      onChanged: _disabled ? null : onChanged,
      size: size,
      expand: expand,
      style: style,
      segments: segments,
    );
  }

  List<OrionSegment<String>> _richSegments({
    required bool icons,
    required bool badges,
  }) {
    return <OrionSegment<String>>[
      OrionSegment<String>(
        value: 'overview',
        icon: icons ? const Icon(Icons.grid_view_rounded) : null,
        label: const Text('Overview'),
      ),
      OrionSegment<String>(
        value: 'live',
        icon: icons ? const Icon(Icons.podcasts_rounded) : null,
        label: const Text('Live'),
        badge: badges ? const Text('3') : null,
      ),
      OrionSegment<String>(
        value: 'tickets',
        icon: icons ? const Icon(Icons.confirmation_number_outlined) : null,
        label: const Text('Tickets'),
        badge: badges ? const Text('12') : null,
      ),
    ];
  }

  OrionSegmentedControlStyle? _skinStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    return switch (_skin) {
      _SegmentSkin.standard => null,
      _SegmentSkin.brand => OrionSegmentedControlStyle(
        trackColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? scheme.onSurface.withValues(alpha: 0.12)
              : scheme.primary,
        ),
        pillColor: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? scheme.surface.withValues(alpha: 0.65)
              : scheme.onPrimary,
        ),
        pillBorder: BorderSide.none,
        trackBorder: BorderSide.none,
        labelColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          if (states.contains(WidgetState.selected)) {
            return scheme.primary;
          }
          return scheme.onPrimary.withValues(
            alpha: states.contains(WidgetState.hovered) ? 1.0 : 0.80,
          );
        }),
      ),
      _SegmentSkin.rounded => OrionSegmentedControlStyle.from(
        radius: BorderRadius.circular(OrionRadii.radius12),
      ),
      _SegmentSkin.outline => OrionSegmentedControlStyle(
        trackColor: const WidgetStatePropertyAll<Color?>(Colors.transparent),
        trackBorder: BorderSide(color: scheme.outlineVariant, width: 1),
        radius: BorderRadius.circular(OrionRadii.radius12),
      ),
    };
  }

  String _skinLabel(_SegmentSkin skin) => switch (skin) {
    _SegmentSkin.standard => 'Standard',
    _SegmentSkin.brand => 'Brand',
    _SegmentSkin.rounded => 'Rounded',
    _SegmentSkin.outline => 'Outline',
  };

  String _sizeLabel(OrionSegmentedControlSize size) => switch (size) {
    OrionSegmentedControlSize.small => 'Small',
    OrionSegmentedControlSize.medium => 'Medium',
    OrionSegmentedControlSize.large => 'Large',
  };

  /// The exact call the current playground controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionSegmentedControl<String>(',
      "  value: '$_playground',",
    ];
    if (_playgroundSize != OrionSegmentedControlSize.medium) {
      lines.add('  size: OrionSegmentedControlSize.${_playgroundSize.name},');
    }
    if (!_playgroundExpand) {
      lines.add('  expand: false,');
    }
    lines.add(
      _disabled
          ? '  onChanged: null, // disabled'
          : '  onChanged: (value) => setState(() => _tab = value),',
    );
    lines.add('  segments: const [');
    lines.add(
      _playgroundIcons
          ? "    OrionSegment(value: 'overview', icon: Icon(Icons.grid_view_rounded), label: Text('Overview')),"
          : "    OrionSegment(value: 'overview', label: Text('Overview')),",
    );
    final String liveExtras = <String>[
      if (_playgroundIcons) 'icon: Icon(Icons.podcasts_rounded)',
      if (_playgroundBadges) "badge: Text('3')",
    ].join(', ');
    lines.add(
      liveExtras.isEmpty
          ? "    OrionSegment(value: 'live', label: Text('Live')),"
          : "    OrionSegment(value: 'live', $liveExtras, label: Text('Live')),",
    );
    final String ticketExtras = <String>[
      if (_playgroundIcons) 'icon: Icon(Icons.confirmation_number_outlined)',
      if (_playgroundBadges) "badge: Text('12')",
    ].join(', ');
    lines.add(
      ticketExtras.isEmpty
          ? "    OrionSegment(value: 'tickets', label: Text('Tickets')),"
          : "    OrionSegment(value: 'tickets', $ticketExtras, label: Text('Tickets')),",
    );
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
      title: 'Orion Segments',
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
                      'SELECTION • DRAG & IMMEDIATE SPRING',
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
                    'Single-select pill track with tap or horizontal drag-to-scrub, pill-synced ink transitions, concentric corners, hover halos, and arrow/Home/End keyboard nav.',
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

            // Primary Drag or Tap Card
            OrionShowcaseSection(
              title: 'Drag or Tap',
              subtitle:
                  'Tap any slot or drag the active pill horizontally across segments',
              card: true,
              child: _sample<String>(
                value: _trip,
                onChanged: (String value) => setState(() => _trip = value),
                segments: _tripSegments,
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (36 pt), Medium (44 pt), and Large (52 pt) built-in height presets',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Small',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space8),
                  _sample<String>(
                    size: OrionSegmentedControlSize.small,
                    value: _smallChoice,
                    onChanged: (String value) =>
                        setState(() => _smallChoice = value),
                    segments: _tripSegments,
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Text(
                    'Medium (Default)',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space8),
                  _sample<String>(
                    size: OrionSegmentedControlSize.medium,
                    value: _mediumChoice,
                    onChanged: (String value) =>
                        setState(() => _mediumChoice = value),
                    segments: _tripSegments,
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  Text(
                    'Large',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space8),
                  _sample<String>(
                    size: OrionSegmentedControlSize.large,
                    value: _largeChoice,
                    onChanged: (String value) =>
                        setState(() => _largeChoice = value),
                    segments: _tripSegments,
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Intrinsic Width & Icon-Only Card
            OrionShowcaseSection(
              title: 'Intrinsic & Icon-Only',
              subtitle:
                  'expand: false sizes equal slots cleanly inside toolbars, Rows, or Wraps',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space12,
                runSpacing: OrionSpacing.space12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: <Widget>[
                  _sample<_ViewMode>(
                    expand: false,
                    size: OrionSegmentedControlSize.small,
                    value: _viewMode,
                    onChanged: (_ViewMode value) =>
                        setState(() => _viewMode = value),
                    segments: const <OrionSegment<_ViewMode>>[
                      OrionSegment<_ViewMode>(
                        value: _ViewMode.list,
                        label: Icon(Icons.view_list_rounded),
                        semanticLabel: 'List view',
                        tooltip: 'List view',
                      ),
                      OrionSegment<_ViewMode>(
                        value: _ViewMode.grid,
                        label: Icon(Icons.grid_view_rounded),
                        semanticLabel: 'Grid view',
                        tooltip: 'Grid view',
                      ),
                      OrionSegment<_ViewMode>(
                        value: _ViewMode.map,
                        label: Icon(Icons.map_outlined),
                        semanticLabel: 'Map view',
                        tooltip: 'Map view',
                      ),
                    ],
                  ),
                  _sample<String>(
                    expand: false,
                    size: OrionSegmentedControlSize.small,
                    value: _range,
                    onChanged: (String value) => setState(() => _range = value),
                    segments: _rangeSegments,
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Icons & Animated Badges Card
            OrionShowcaseSection(
              title: 'Icons & Animated Badges',
              subtitle:
                  'Built-in segment icon slot and AnimatedSize counter chips that collapse in place',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseToggle(
                    label: 'Show badge counts',
                    value: _showCounts,
                    onChanged: (bool value) =>
                        setState(() => _showCounts = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample<String>(
                    value: _badgeChoice,
                    onChanged: (String value) =>
                        setState(() => _badgeChoice = value),
                    segments: _richSegments(icons: true, badges: _showCounts),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Per-Segment Disabled Card
            OrionShowcaseSection(
              title: 'Per-Segment Disabled',
              subtitle:
                  'Locked options stay muted and are skipped by taps, dragging, and arrow keys',
              card: true,
              child: _sample<String>(
                value: _tierChoice,
                onChanged: (String value) =>
                    setState(() => _tierChoice = value),
                segments: const <OrionSegment<String>>[
                  OrionSegment<String>(value: 'free', label: Text('Free')),
                  OrionSegment<String>(value: 'pro', label: Text('Pro')),
                  OrionSegment<String>(
                    value: 'enterprise',
                    label: Text('Enterprise'),
                    enabled: false,
                    tooltip: 'Contact sales to unlock',
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Concentric rounded corners, state-aware brand skins, and outline tracks',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionShowcaseChoice<_SegmentSkin>(
                    label: 'Skin',
                    values: _SegmentSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (_SegmentSkin value) =>
                        setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space20),
                  _sample<String>(
                    value: _skinTrip,
                    onChanged: (String value) =>
                        setState(() => _skinTrip = value),
                    segments: _tripSegments,
                    style: _skinStyle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Configure size, width mode, icons, and badges with live code output',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionShowcaseChoice<OrionSegmentedControlSize>(
                      label: 'Size',
                      values: OrionSegmentedControlSize.values,
                      selected: _playgroundSize,
                      labelOf: _sizeLabel,
                      onChanged: (OrionSegmentedControlSize value) =>
                          setState(() => _playgroundSize = value),
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Expand',
                            value: _playgroundExpand,
                            onChanged: (bool value) =>
                                setState(() => _playgroundExpand = value),
                          ),
                        ),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Icons',
                            value: _playgroundIcons,
                            onChanged: (bool value) =>
                                setState(() => _playgroundIcons = value),
                          ),
                        ),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Badges',
                            value: _playgroundBadges,
                            onChanged: (bool value) =>
                                setState(() => _playgroundBadges = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space20),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space16,
                        vertical: OrionSpacing.space24,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainer,
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
                      child: Center(
                        child: _sample<String>(
                          size: _playgroundSize,
                          expand: _playgroundExpand,
                          value: _playground,
                          onChanged: (String value) =>
                              setState(() => _playground = value),
                          segments: _richSegments(
                            icons: _playgroundIcons,
                            badges: _playgroundBadges,
                          ),
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
