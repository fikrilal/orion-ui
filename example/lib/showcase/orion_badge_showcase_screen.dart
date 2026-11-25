import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionBadge].
///
/// The variants, sizes and content modes are wordless reference matrices; the
/// playground last drives one badge through the axes, and its count stepper is
/// the pop's stage. The generated call sits behind the Code tab.
class OrionBadgeShowcaseScreen extends StatefulWidget {
  const OrionBadgeShowcaseScreen({super.key});

  @override
  State<OrionBadgeShowcaseScreen> createState() =>
      _OrionBadgeShowcaseScreenState();
}

enum _BadgeMode { label, count, dot }

class _OrionBadgeShowcaseScreenState extends State<OrionBadgeShowcaseScreen> {
  // Playground: the focused specimen's axes.
  OrionBadgeVariant _variant = OrionBadgeVariant.neutral;
  OrionBadgeSize _size = OrionBadgeSize.medium;
  _BadgeMode _mode = _BadgeMode.count;
  int _count = 8;

  String _variantLabel(OrionBadgeVariant variant) => switch (variant) {
    OrionBadgeVariant.neutral => 'Neutral',
    OrionBadgeVariant.primary => 'Primary',
    OrionBadgeVariant.secondary => 'Secondary',
    OrionBadgeVariant.error => 'Error',
    OrionBadgeVariant.outline => 'Outline',
  };

  String _sizeLabel(OrionBadgeSize size) => switch (size) {
    OrionBadgeSize.small => 'Small',
    OrionBadgeSize.medium => 'Medium',
    OrionBadgeSize.large => 'Large',
  };

  String _modeLabel(_BadgeMode mode) => switch (mode) {
    _BadgeMode.label => 'Label',
    _BadgeMode.count => 'Count',
    _BadgeMode.dot => 'Dot',
  };

  Widget _playgroundBadge() => switch (_mode) {
    _BadgeMode.label => OrionBadge(
      label: 'New',
      variant: _variant,
      size: _size,
    ),
    _BadgeMode.count => OrionBadge.count(
      value: _count,
      variant: _variant,
      size: _size,
    ),
    _BadgeMode.dot => OrionBadge.dot(variant: _variant),
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      switch (_mode) {
        _BadgeMode.label => 'OrionBadge(',
        _BadgeMode.count => 'OrionBadge.count(',
        _BadgeMode.dot => 'OrionBadge.dot(',
      },
    ];
    if (_variant != OrionBadgeVariant.neutral) {
      lines.add('  variant: OrionBadgeVariant.${_variant.name},');
    }
    if (_mode != _BadgeMode.dot && _size != OrionBadgeSize.medium) {
      lines.add('  size: OrionBadgeSize.${_size.name},');
    }
    switch (_mode) {
      case _BadgeMode.label:
        lines.add("  label: 'New',");
      case _BadgeMode.count:
        lines.add('  value: $_count,');
      case _BadgeMode.dot:
        break;
    }
    lines.add(')');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Badges',
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
                      'INDICATOR • IMMEDIATE SPRING',
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
                    'Small pill-shaped label, decorative status dot, or tabular count badge. Numbers morph and pop on immediate spring physics.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Playground (top)
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Interactive badge workbench with live count stepper and spring physics preview',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space24,
                        vertical: OrionSpacing.space24,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surfaceContainerLowest
                            : scheme.surfaceContainerLowest,
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
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Center(child: _playgroundBadge()),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            _mode == _BadgeMode.count
                                ? 'Step count to trigger immediate spring pop'
                                : 'Live rendered badge preview',
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
                    const SizedBox(height: OrionSpacing.space20),

                    OrionShowcaseChoice<OrionBadgeVariant>(
                      label: 'Variant',
                      values: OrionBadgeVariant.values,
                      selected: _variant,
                      labelOf: _variantLabel,
                      onChanged: (value) => setState(() => _variant = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<OrionBadgeSize>(
                      label: 'Size',
                      values: OrionBadgeSize.values,
                      selected: _size,
                      labelOf: _sizeLabel,
                      onChanged: (value) => setState(() => _size = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_BadgeMode>(
                      label: 'Content',
                      values: _BadgeMode.values,
                      selected: _mode,
                      labelOf: _modeLabel,
                      onChanged: (value) => setState(() => _mode = value),
                    ),
                    if (_mode == _BadgeMode.count) ...[
                      const SizedBox(height: OrionSpacing.space16),
                      Row(
                        children: [
                          OrionButton(
                            size: OrionButtonSize.small,
                            onPressed: _count > 0
                                ? () => setState(() => _count--)
                                : null,
                            child: const Icon(Icons.remove, size: 18),
                          ),
                          const SizedBox(width: OrionSpacing.space8),
                          OrionButton(
                            size: OrionButtonSize.small,
                            onPressed: () => setState(() => _count++),
                            child: const Icon(Icons.add, size: 18),
                          ),
                          const SizedBox(width: OrionSpacing.space12),
                          Text(
                            'Count: $_count',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Variants Card
            OrionShowcaseSection(
              title: 'Variants',
              subtitle:
                  'Color roles mapped to theme ColorScheme, plus an outline role',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space12,
                runSpacing: OrionSpacing.space12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final OrionBadgeVariant variant
                      in OrionBadgeVariant.values)
                    OrionBadge(
                      variant: variant,
                      child: Text(_variantLabel(variant)),
                    ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small, Medium, and Large stepped padding and typography',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space12,
                runSpacing: OrionSpacing.space12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  for (final OrionBadgeSize size in OrionBadgeSize.values)
                    OrionBadge(size: size, child: Text(_sizeLabel(size))),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Content Modes Card
            OrionShowcaseSection(
              title: 'Content',
              subtitle:
                  'Text labels, tabular figures, capped maxCount ("99+"), and bare dots',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space12,
                runSpacing: OrionSpacing.space12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const OrionBadge(child: Text('Label')),
                  const OrionBadge.count(value: 3),
                  const OrionBadge.count(value: 12),
                  const OrionBadge.count(value: 128, maxCount: 99),
                  OrionBadge.dot(variant: OrionBadgeVariant.primary),
                  OrionBadge.dot(variant: OrionBadgeVariant.error),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
