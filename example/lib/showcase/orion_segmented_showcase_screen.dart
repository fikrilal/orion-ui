import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionSegmentedControl].
///
/// The `Disabled` flag in the top controls card gates every sample, the
/// sections below are the reference matrices, and the playground last is the
/// control itself: its selection state drives the generated call behind the
/// Code tab.
class OrionSegmentedShowcaseScreen extends StatefulWidget {
  const OrionSegmentedShowcaseScreen({super.key});

  @override
  State<OrionSegmentedShowcaseScreen> createState() =>
      _OrionSegmentedShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _SegmentSkin { standard, brand, compact }

class _OrionSegmentedShowcaseScreenState
    extends State<OrionSegmentedShowcaseScreen> {
  static const List<OrionSegment<String>> _tripSegments =
      <OrionSegment<String>>[
        OrionSegment(value: 'overview', label: Text('Overview')),
        OrionSegment(value: 'live', label: Text('Live')),
        OrionSegment(value: 'tickets', label: Text('Tickets')),
      ];

  static const List<OrionSegment<String>> _rangeSegments =
      <OrionSegment<String>>[
        OrionSegment(value: 'today', label: Text('Today')),
        OrionSegment(value: 'week', label: Text('This week')),
      ];

  static const List<OrionSegment<String>> _iconSegments =
      <OrionSegment<String>>[
        OrionSegment(
          value: 'overview',
          label: _IconLabel(icon: Icons.grid_view_rounded, label: 'Overview'),
        ),
        OrionSegment(
          value: 'live',
          label: _IconLabel(icon: Icons.podcasts_rounded, label: 'Live'),
        ),
        OrionSegment(
          value: 'tickets',
          label: _IconLabel(
            icon: Icons.confirmation_number_outlined,
            label: 'Tickets',
          ),
        ),
      ];

  static const List<OrionSegment<String>> _countSegments =
      <OrionSegment<String>>[
        OrionSegment(value: 'overview', label: Text('Overview')),
        OrionSegment(value: 'live', label: Text('Live'), badge: Text('3')),
        OrionSegment(
          value: 'tickets',
          label: Text('Tickets'),
          badge: Text('12'),
        ),
      ];

  // Flag: shared by every sample on the page.
  bool _disabled = false;

  String _trip = 'live';
  String _range = 'today';
  String _iconTrip = 'overview';
  String _countTrip = 'live';

  // Customization: the focused skin choice.
  _SegmentSkin _skin = _SegmentSkin.standard;
  String _skinTrip = 'live';

  // Playground: the focused specimen's own selection.
  String _playground = 'overview';

  void _selectPlayground(String value) => setState(() => _playground = value);

  /// One sample under the shared flag.
  OrionSegmentedControl<String> _sample({
    required String value,
    required ValueChanged<String> onChanged,
    required List<OrionSegment<String>> segments,
    OrionSegmentedControlStyle? style,
  }) {
    return OrionSegmentedControl<String>(
      value: value,
      onChanged: _disabled ? null : onChanged,
      style: style,
      segments: segments,
    );
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
        pillColor: WidgetStatePropertyAll<Color?>(scheme.onPrimary),
        labelColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return scheme.onSurface.withValues(alpha: 0.38);
          }
          return states.contains(WidgetState.selected)
              ? scheme.primary
              : scheme.onPrimary;
        }),
      ),
      _SegmentSkin.compact => OrionSegmentedControlStyle.from(
        height: 36,
        radius: BorderRadius.circular(OrionRadii.radius12),
        labelStyle: theme.textTheme.labelSmall,
      ),
    };
  }

  String _skinLabel(_SegmentSkin skin) => switch (skin) {
    _SegmentSkin.standard => 'Standard',
    _SegmentSkin.brand => 'Brand',
    _SegmentSkin.compact => 'Compact',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionSegmentedControl<String>(',
      "  value: '$_playground',",
      _disabled
          ? '  onChanged: null, // disabled'
          : '  onChanged: _selectPlayground,',
      '  segments: const [',
      "    OrionSegment(value: 'overview', label: Text('Overview')),",
      "    OrionSegment(value: 'live', label: Text('Live')),",
      "    OrionSegment(value: 'tickets', label: Text('Tickets')),",
      '  ],',
      ')',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Segments',
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
                      'SELECTION • IMMEDIATE SPRING',
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
                    'Single-select pill track. Selection pill slides on the immediate travel spec without lateral overshoot. Arrow keys follow text direction.',
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

            // Trip Card
            OrionShowcaseSection(
              title: 'Trip',
              subtitle:
                  'Equal segment distribution with sliding active selection indicator pill',
              card: true,
              child: _sample(
                value: _trip,
                onChanged: (value) => setState(() => _trip = value),
                segments: _tripSegments,
              ),
            ),
            const SizedBox(height: 2.00),

            // Two options Card
            OrionShowcaseSection(
              title: 'Two options',
              subtitle: 'Binary switch-style pill track for quick mode swaps',
              card: true,
              child: _sample(
                value: _range,
                onChanged: (value) => setState(() => _range = value),
                segments: _rangeSegments,
              ),
            ),
            const SizedBox(height: 2.00),

            // Icon and text Card
            OrionShowcaseSection(
              title: 'Icon and text',
              subtitle:
                  'Rich labels composing icon and text; icons inherit segment state colors',
              card: true,
              child: _sample(
                value: _iconTrip,
                onChanged: (value) => setState(() => _iconTrip = value),
                segments: _iconSegments,
              ),
            ),
            const SizedBox(height: 2.00),

            // With counts Card
            OrionShowcaseSection(
              title: 'With counts',
              subtitle:
                  'Segments carrying optional badge counter chips beside their labels',
              card: true,
              child: _sample(
                value: _countTrip,
                onChanged: (value) => setState(() => _countTrip = value),
                segments: _countSegments,
              ),
            ),
            const SizedBox(height: 2.00),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionSegmentedControlTheme -> Instance OrionSegmentedControlStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_SegmentSkin>(
                    label: 'Skin',
                    values: _SegmentSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: 2.04),
                  _sample(
                    value: _skinTrip,
                    onChanged: (value) => setState(() => _skinTrip = value),
                    segments: _tripSegments,
                    style: _skinStyle(context),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle: 'Interactive segment specimen with live code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space16,
                        vertical: 2.04,
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
                          value: _playground,
                          onChanged: _selectPlayground,
                          segments: _tripSegments,
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

class _IconLabel extends StatelessWidget {
  const _IconLabel({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon),
        const SizedBox(width: OrionSpacing.space4),
        Flexible(child: Text(label)),
      ],
    );
  }
}
