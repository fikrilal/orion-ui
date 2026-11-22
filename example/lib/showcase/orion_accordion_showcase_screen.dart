import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

class _Faq {
  const _Faq(this.question, this.answer);

  final String question;
  final String answer;
}

/// The trailing widgets the playground can swap in.
enum _AccordionTrailing { chevron, tune }

/// The instance-level skins the customization section demonstrates.
enum _AccordionSkin { standard, roomy, accent }

/// Playground for [OrionAccordion].
///
/// The `Disabled` flag at the top drives every row, the sections below are the
/// reference matrices - a single controlled row, a composed list that keeps one
/// row open, and a supplied trailing slot - and the playground last drives its
/// own row's expanded state and trailing widget, generating the call it stands
/// for behind the Code tab.
class OrionAccordionShowcaseScreen extends StatefulWidget {
  const OrionAccordionShowcaseScreen({super.key});

  @override
  State<OrionAccordionShowcaseScreen> createState() =>
      _OrionAccordionShowcaseScreenState();
}

class _OrionAccordionShowcaseScreenState
    extends State<OrionAccordionShowcaseScreen> {
  static const List<_Faq> _faq = <_Faq>[
    _Faq(
      'How does the reveal move?',
      'One spring drives the panel extent and the chevron together, so the two '
          'can never disagree.',
    ),
    _Faq(
      'Is the content rebuilt while it animates?',
      'No. The content is laid out at its natural height and only the clipped '
          'extent changes.',
    ),
    _Faq(
      'What happens with reduced motion?',
      'The panel is open or closed on the next frame and the chevron is already '
          'at its end angle.',
    ),
  ];

  // Flag: shared by every row on the page.
  bool _disabled = false;

  bool _single = false;
  int? _open;
  bool _custom = false;

  // Playground: the focused row's own axes.
  bool _playgroundExpanded = false;
  _AccordionTrailing _trailing = _AccordionTrailing.chevron;

  // Customization: the focused skin and its specimen.
  _AccordionSkin _skin = _AccordionSkin.standard;
  bool _skinned = false;

  /// One row under the shared flag.
  OrionAccordion _sample({
    required Widget header,
    required Widget child,
    required bool expanded,
    required ValueChanged<bool> onExpandedChanged,
    Widget? trailing,
    OrionAccordionStyle? style,
  }) {
    return OrionAccordion(
      header: header,
      trailing: trailing,
      expanded: expanded,
      onExpandedChanged: _disabled ? null : onExpandedChanged,
      style: style,
      child: child,
    );
  }

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionAccordion(',
      "  header: const Text('Advanced options'),",
      '  expanded: $_playgroundExpanded,',
    ];
    if (_trailing == _AccordionTrailing.tune) {
      lines.add('  trailing: const Icon(Icons.tune),');
    }
    lines.add(
      _disabled
          ? '  onExpandedChanged: null, // disabled'
          : '  onExpandedChanged: _onExpandedChanged,',
    );
    lines.add("  child: const Text('Delivery window: 09:00 - 12:00'),");
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Accordion',
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
                      'DISCLOSURE • ASYMMETRIC SPRINGS',
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
                    'Controlled disclosure row. One spring drives the clip extent and chevron together with aligned insets and calm micro-press physics.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Playground (at the top)
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Live interactive specimen with configurable states, trailing slot, and code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Canvas Stage
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(OrionSpacing.space16),
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _sample(
                            header: const Text(
                              'Advanced options',
                              style: TextStyle(fontWeight: FontWeight.w600),
                            ),
                            expanded: _playgroundExpanded,
                            onExpandedChanged: (bool value) =>
                                setState(() => _playgroundExpanded = value),
                            trailing: _trailing == _AccordionTrailing.tune
                                ? const Icon(Icons.tune)
                                : null,
                            child: Text(
                              'Delivery window: 09:00 - 12:00. Special handling instructions are noted on the parcel.',
                              style: TextStyle(
                                color: scheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            'Tap header to toggle disclosure with calm 0.99 press',
                            style: TextStyle(
                              fontSize: 11.5,
                              color: scheme.onSurfaceVariant.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 2.00),

                    // Controls
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
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<bool>(
                      label: 'State',
                      values: const <bool>[false, true],
                      selected: _playgroundExpanded,
                      labelOf: (bool expanded) =>
                          expanded ? 'Expanded' : 'Collapsed',
                      onChanged: (value) =>
                          setState(() => _playgroundExpanded = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_AccordionTrailing>(
                      label: 'Trailing',
                      values: _AccordionTrailing.values,
                      selected: _trailing,
                      labelOf: _trailingLabel,
                      onChanged: (value) => setState(() => _trailing = value),
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: 2.04),

            // Single Accordion Card
            OrionShowcaseSection(
              title: 'Single',
              subtitle:
                  'Independent disclosure row with aligned header and body copy',
              card: true,
              child: _sample(
                header: const Text(
                  'Delivery details',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                expanded: _single,
                onExpandedChanged: (bool value) =>
                    setState(() => _single = value),
                child: Text(
                  'Left with the concierge, signed for at 09:40. The driver '
                  'photographed the parcel at the door.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 2.00),

            // One Open at a Time Card
            OrionShowcaseSection(
              title: 'One open at a time',
              subtitle:
                  'Composed group where expanding one item cleanly collapses the previous',
              card: true,
              child: Column(
                children: <Widget>[
                  for (var index = 0; index < _faq.length; index++) ...[
                    _sample(
                      header: Text(
                        _faq[index].question,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      expanded: _open == index,
                      onExpandedChanged: (bool value) =>
                          setState(() => _open = value ? index : null),
                      child: Text(
                        _faq[index].answer,
                        style: TextStyle(
                          color: scheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                    if (index < _faq.length - 1)
                      Divider(
                        height: 1,
                        thickness: 1,
                        color: isDark
                            ? scheme.outlineVariant.withValues(alpha: 0.15)
                            : scheme.outlineVariant.withValues(alpha: 0.30),
                      ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Custom Trailing Card
            OrionShowcaseSection(
              title: 'Custom trailing',
              subtitle:
                  'Supplied trailing slot replacing the default rotating chevron',
              card: true,
              child: _sample(
                header: const Text(
                  'Notification rules',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                trailing: const Icon(Icons.tune),
                expanded: _custom,
                onExpandedChanged: (bool value) =>
                    setState(() => _custom = value),
                child: Text(
                  'A supplied trailing slot replaces the chevron and is never '
                  'rotated by the reveal.',
                  style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4),
                ),
              ),
            ),
            const SizedBox(height: 2.00),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Preset -> OrionAccordionTheme -> Instance OrionAccordionStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_AccordionSkin>(
                    label: 'Skin',
                    values: _AccordionSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    header: const Text(
                      'Shipping options',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    expanded: _skinned,
                    style: _skinStyle(theme.colorScheme),
                    onExpandedChanged: (bool value) =>
                        setState(() => _skinned = value),
                    child: Text(
                      'Delivery window: 09:00 - 12:00',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        height: 1.4,
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

  String _trailingLabel(_AccordionTrailing trailing) => switch (trailing) {
    _AccordionTrailing.chevron => 'Chevron',
    _AccordionTrailing.tune => 'Tune',
  };

  OrionAccordionStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _AccordionSkin.standard => null,
    _AccordionSkin.roomy => OrionAccordionStyle.from(
      headerPadding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space16,
        vertical: OrionSpacing.space16,
      ),
    ),
    _AccordionSkin.accent => OrionAccordionStyle.from(
      iconColor: scheme.primary,
      focusRingColor: scheme.primary,
    ),
  };

  String _skinLabel(_AccordionSkin skin) => switch (skin) {
    _AccordionSkin.standard => 'Standard',
    _AccordionSkin.roomy => 'Roomy',
    _AccordionSkin.accent => 'Accent',
  };
}
