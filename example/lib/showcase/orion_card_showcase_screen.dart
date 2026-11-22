import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionCard] surfaces and press feedback.
///
/// The `Interactive` flag in the top controls card gates every pressable
/// sample, the sections below are the reference matrices, and the playground
/// last carries the focused specimen with its generated call behind the Code
/// tab.
class OrionCardShowcaseScreen extends StatefulWidget {
  const OrionCardShowcaseScreen({super.key});

  @override
  State<OrionCardShowcaseScreen> createState() =>
      _OrionCardShowcaseScreenState();
}

/// The radius steps the playground demonstrates.
enum _CardRadius { standard, tight, rounded, pill }

/// The instance-level skins the customization section demonstrates.
enum _CardSkin { standard, outlined, inverted }

class _OrionCardShowcaseScreenState extends State<OrionCardShowcaseScreen> {
  // Flag: shared by every pressable sample on the page.
  bool _interactive = true;

  // Customization: the focused skin.
  _CardSkin _skin = _CardSkin.standard;

  // Playground: the focused specimen's own axes.
  bool _frosted = false;
  _CardRadius _radius = _CardRadius.standard;

  int _cardTaps = 0;

  void _countTap() => setState(() => _cardTaps++);

  /// One sample under the shared flag.
  OrionCard _sample({
    required Widget child,
    bool frosted = false,
    double? radius,
    EdgeInsetsGeometry? padding,
    VoidCallback? onTap,
    OrionCardStyle? style,
  }) {
    return OrionCard(
      frosted: frosted,
      radius: radius,
      padding: padding,
      onTap: _interactive ? onTap : null,
      style: style,
      child: child,
    );
  }

  OrionCardStyle? _skinStyle(ColorScheme scheme) => switch (_skin) {
    _CardSkin.standard => null,
    _CardSkin.outlined => OrionCardStyle.from(
      border: BorderSide(color: scheme.outline),
    ),
    _CardSkin.inverted => OrionCardStyle.from(background: scheme.primary),
  };

  String _skinLabel(_CardSkin skin) => switch (skin) {
    _CardSkin.standard => 'Standard',
    _CardSkin.outlined => 'Outlined',
    _CardSkin.inverted => 'Inverted',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>['OrionCard('];
    if (_frosted) {
      lines.add('  frosted: true,');
    }
    final String? radius = _radiusToken(_radius);
    if (radius != null) {
      lines.add('  radius: $radius,');
    }
    lines.add(
      _interactive
          ? '  onTap: _countTap,'
          : '  onTap: null, // interactive off',
    );
    lines.add("  child: const Text('Card'),");
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Cards',
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
                      'SURFACE • STATIC BLUR ISOLATION',
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
                    'Quiet inset surface with optional frosted glass. Frosted backdrops sit in static layers behind content to prevent GPU re-sampling stalls on press.',
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
                  'Live interactive specimen with configurable blur, corner radius, and code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                          _Backdrop(
                            child: _sample(
                              frosted: _frosted,
                              radius: _radiusValue(_radius),
                              onTap: _countTap,
                              child: const Text(
                                'Card',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            'Hold card to verify press compression preserves static blur',
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

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Interactive',
                            value: _interactive,
                            onChanged: (value) =>
                                setState(() => _interactive = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<bool>(
                      label: 'Frosted',
                      values: const [false, true],
                      selected: _frosted,
                      labelOf: (value) => value ? 'On' : 'Off',
                      onChanged: (value) => setState(() => _frosted = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_CardRadius>(
                      label: 'Radius',
                      values: _CardRadius.values,
                      selected: _radius,
                      labelOf: _radiusLabel,
                      onChanged: (value) => setState(() => _radius = value),
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Plain Card
            OrionShowcaseSection(
              title: 'Plain',
              subtitle:
                  'Quiet inset panel with muted fill, no hairline border, and no shadow',
              card: true,
              child: _sample(child: const Text('Plain card')),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Frosted Card
            OrionShowcaseSection(
              title: 'Frosted',
              subtitle:
                  'Frosted backdrop sits in static clipped layer behind foreground content',
              card: true,
              child: _Backdrop(
                child: _sample(
                  frosted: true,
                  child: const Text('Frosted card over a gradient'),
                ),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Pressable Card
            OrionShowcaseSection(
              title: 'Pressable',
              subtitle:
                  'Tactile press feedback compresses only foreground content without scaling blur',
              card: true,
              child: _sample(
                onTap: _countTap,
                child: Text('Interactive card - taps: $_cardTaps'),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Radius and Padding Card
            OrionShowcaseSection(
              title: 'Radius and padding',
              subtitle:
                  'Customizable geometry tokens: AppRadii and AppSpacing overrides',
              card: true,
              child: _sample(
                radius: OrionRadii.radius8,
                padding: const EdgeInsets.all(OrionSpacing.space8),
                child: const Text('Tight card'),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionCardTheme -> Instance OrionCardStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_CardSkin>(
                    label: 'Skin',
                    values: _CardSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    style: _skinStyle(scheme),
                    child: Text(
                      'Skinned card',
                      style: _skin == _CardSkin.inverted
                          ? TextStyle(color: scheme.onPrimary)
                          : null,
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

  String? _radiusToken(_CardRadius radius) => switch (radius) {
    _CardRadius.standard => null,
    _CardRadius.tight => 'OrionRadii.radius8',
    _CardRadius.rounded => 'OrionRadii.radius24',
    _CardRadius.pill => 'OrionRadii.radiusPill',
  };

  String _radiusLabel(_CardRadius radius) => switch (radius) {
    _CardRadius.standard => 'Standard',
    _CardRadius.tight => 'Tight',
    _CardRadius.rounded => 'Rounded',
    _CardRadius.pill => 'Pill',
  };

  double? _radiusValue(_CardRadius radius) => switch (radius) {
    _CardRadius.standard => null,
    _CardRadius.tight => OrionRadii.radius8,
    _CardRadius.rounded => OrionRadii.radius24,
    _CardRadius.pill => OrionRadii.radiusPill,
  };
}

/// The gradient the frosted specimens sit on, so the blur reads.
class _Backdrop extends StatelessWidget {
  const _Backdrop({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(OrionRadii.radius24),
        gradient: LinearGradient(
          colors: [scheme.primaryContainer, scheme.tertiaryContainer],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(OrionSpacing.space16),
        child: child,
      ),
    );
  }
}
