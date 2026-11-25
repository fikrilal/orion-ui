import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionButton].
///
/// The three flags in the top controls card drive every section, the way the
/// design-system benchmark drives its samples from one panel; the sections
/// below are the reference matrices, and the playground last carries the
/// focused specimen with its generated call behind the Code tab.
class OrionButtonShowcaseScreen extends StatefulWidget {
  const OrionButtonShowcaseScreen({super.key});

  @override
  State<OrionButtonShowcaseScreen> createState() =>
      _OrionButtonShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _ButtonSkin { standard, brand, pill }

class _OrionButtonShowcaseScreenState extends State<OrionButtonShowcaseScreen> {
  static const double _defaultPressScale = 0.985;

  // Flags: shared by every sample on the page.
  bool _disabled = false;
  bool _loading = false;
  bool _expanded = false;

  // Playground: the focused specimen's own axes.
  OrionButtonVariant _variant = OrionButtonVariant.solid;
  OrionButtonSize _size = OrionButtonSize.medium;
  double _pressScale = _defaultPressScale;
  OrionSpringSpec _pressSpring = OrionSpringSpec.snappy;

  _ButtonSkin _skin = _ButtonSkin.standard;
  int _debouncedTaps = 0;

  Future<void> _runAsyncAction() async {
    await Future<void>.delayed(const Duration(milliseconds: 1200));
  }

  bool get _customisedPhysics =>
      _pressScale != _defaultPressScale ||
      _pressSpring != OrionSpringSpec.snappy;

  OrionButtonStyle? get _playgroundStyle => _customisedPhysics
      ? OrionButtonStyle.from(
          pressedScale: _pressScale,
          pressSpring: _pressSpring,
        )
      : null;

  /// One sample under the shared flags.
  OrionButton _sample({
    String? label,
    Widget? child,
    OrionButtonVariant variant = OrionButtonVariant.solid,
    OrionButtonSize size = OrionButtonSize.medium,
    bool debounce = false,
    Widget? leading,
    Widget? trailing,
    OrionButtonStyle? style,
    VoidCallback? onPressed,
  }) {
    return OrionButton(
      label: label,
      variant: variant,
      size: size,
      leading: leading,
      trailing: trailing,
      debounce: debounce,
      style: style,
      isLoading: _loading,
      isExpanded: _expanded,
      onPressed: _disabled ? null : (onPressed ?? () {}),
      child: child,
    );
  }

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionButton(',
      '  variant: OrionButtonVariant.${_variant.name},',
      '  size: OrionButtonSize.${_size.name},',
    ];
    if (_disabled) {
      lines.add('  onPressed: null, // disabled');
    } else {
      lines.add('  onPressed: _runAsyncAction,');
    }
    if (_loading) {
      lines.add('  isLoading: true,');
    }
    if (_expanded) {
      lines.add('  isExpanded: true,');
    }
    if (_customisedPhysics) {
      lines.add('  style: OrionButtonStyle.from(');
      if (_pressScale != _defaultPressScale) {
        lines.add('    pressedScale: ${_pressScale.toStringAsFixed(2)},');
      }
      if (_pressSpring != OrionSpringSpec.snappy) {
        lines.add(
          '    pressSpring: OrionSpringSpec.${_springName(_pressSpring)},',
        );
      }
      lines.add('  ),');
    }
    lines.add("  label: 'Deploy',");
    lines.add(');');
    return lines.join('\n');
  }

  OrionButtonStyle? _skinStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (_skin) {
      _ButtonSkin.standard => null,
      _ButtonSkin.brand => OrionButtonStyle.from(
        backgroundColor: scheme.tertiary,
        foregroundColor: scheme.onTertiary,
      ),
      _ButtonSkin.pill => OrionButtonStyle.from(
        borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Buttons',
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
                      'PRIMITIVE • PHYSICS-DRIVEN',
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
                    'Tactile, spring-driven button with async in-flight locking, rapid-tap debounce, and 3-layer style customization.',
                    style: TextStyle(
                      fontSize: 13.5,
                      height: 1.4,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Playground (prominently at the top)
            OrionShowcaseSection(
              title: 'Playground',
              subtitle:
                  'Live interactive specimen with configurable states, physics, and code generator',
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Canvas Stage
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space24,
                        vertical: OrionSpacing.space32,
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
                          Center(
                            child: OrionButton(
                              label: 'Deploy',
                              loadingLabel: 'Deploying...',
                              variant: _variant,
                              size: _size,
                              style: _playgroundStyle,
                              isLoading: _loading,
                              isExpanded: _expanded,
                              onPressed: _disabled ? null : _runAsyncAction,
                            ),
                          ),
                          const SizedBox(height: OrionSpacing.space12),
                          Text(
                            'Hold and release to feel tactile spring physics',
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

                    // State Flags Bar
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
                            label: 'Loading',
                            value: _loading,
                            onChanged: (value) =>
                                setState(() => _loading = value),
                          ),
                        ),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Expanded',
                            value: _expanded,
                            onChanged: (value) =>
                                setState(() => _expanded = value),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    // Variant Selector
                    OrionShowcaseChoice<OrionButtonVariant>(
                      label: 'Variant',
                      values: OrionButtonVariant.values,
                      selected: _variant,
                      labelOf: _variantLabel,
                      onChanged: (value) => setState(() => _variant = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    // Size Selector
                    OrionShowcaseChoice<OrionButtonSize>(
                      label: 'Size',
                      values: OrionButtonSize.values,
                      selected: _size,
                      labelOf: _sizeLabel,
                      onChanged: (value) => setState(() => _size = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    // Physics Tuners
                    OrionShowcaseValueSlider(
                      label: 'Press scale',
                      value: _pressScale,
                      min: 0.85,
                      max: 1,
                      step: 0.05,
                      display: _pressScale.toStringAsFixed(2),
                      onChanged: (value) => setState(() => _pressScale = value),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<OrionSpringSpec>(
                      label: 'Press spring',
                      values: const [
                        OrionSpringSpec.snappy,
                        OrionSpringSpec.gentle,
                        OrionSpringSpec.immediate,
                      ],
                      selected: _pressSpring,
                      labelOf: _springLabel,
                      onChanged: (value) =>
                          setState(() => _pressSpring = value),
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Variants Card
            OrionShowcaseSection(
              title: 'Variants',
              subtitle: 'Semantic role treatments mapping to theme ColorScheme',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space12,
                runSpacing: OrionSpacing.space12,
                children: [
                  for (final variant in OrionButtonVariant.values)
                    _sample(variant: variant, label: _variantLabel(variant)),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (32 pt), Medium (40 pt), Large (48 pt) with a 44 pt hit floor',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final size in OrionButtonSize.values) ...[
                    OrionShowcaseLabeledRow(
                      label: _sizeLabel(size),
                      child: _sample(size: size, label: 'Continue'),
                    ),
                    if (size != OrionButtonSize.values.last)
                      const SizedBox(height: OrionSpacing.space12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Icons Card
            OrionShowcaseSection(
              title: 'Icons',
              subtitle:
                  'Composable leading and trailing slots; replaces with spinner when loading',
              card: true,
              child: Wrap(
                spacing: OrionSpacing.space12,
                runSpacing: OrionSpacing.space12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  _sample(
                    leading: const Icon(
                      Icons.download,
                      size: OrionSizing.iconSmall,
                    ),
                    child: const Text('Leading'),
                  ),
                  _sample(
                    trailing: const Icon(
                      Icons.arrow_forward,
                      size: OrionSizing.iconSmall,
                    ),
                    child: const Text('Trailing'),
                  ),
                  _sample(
                    leading: const Icon(
                      Icons.rocket_launch,
                      size: OrionSizing.iconSmall,
                    ),
                    trailing: const Icon(
                      Icons.arrow_forward,
                      size: OrionSizing.iconSmall,
                    ),
                    child: const Text('Both'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // States Card
            OrionShowcaseSection(
              title: 'States',
              subtitle:
                  'In-flight asynchronous action locking and opt-in rapid-tap debounce',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseLabeledRow(
                    label: 'Async',
                    child: _sample(
                      leading: const Icon(
                        Icons.download,
                        size: OrionSizing.iconSmall,
                      ),
                      onPressed: _runAsyncAction,
                      child: const Text('Async action'),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseLabeledRow(
                    label: 'Debounced',
                    child: _sample(
                      debounce: true,
                      onPressed: () => setState(() => _debouncedTaps++),
                      child: const Text('Debounced'),
                    ),
                  ),
                  const SizedBox(height: OrionSpacing.space8),
                  Text(
                    'debounced taps: $_debouncedTaps',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Preset -> OrionButtonTheme -> Instance OrionButtonStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_ButtonSkin>(
                    label: 'Skin',
                    values: _ButtonSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: OrionSpacing.space20),
                  Center(
                    child: _sample(
                      style: _skinStyle(context),
                      child: const Text('Save changes'),
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

  String _variantLabel(OrionButtonVariant variant) => switch (variant) {
    OrionButtonVariant.solid => 'Solid',
    OrionButtonVariant.bordered => 'Bordered',
    OrionButtonVariant.glow => 'Glow',
    OrionButtonVariant.flat => 'Flat',
  };

  String _sizeLabel(OrionButtonSize size) => switch (size) {
    OrionButtonSize.small => 'Small',
    OrionButtonSize.medium => 'Medium',
    OrionButtonSize.large => 'Large',
  };

  String _skinLabel(_ButtonSkin skin) => switch (skin) {
    _ButtonSkin.standard => 'Standard',
    _ButtonSkin.brand => 'Brand',
    _ButtonSkin.pill => 'Pill',
  };

  String _springName(OrionSpringSpec spring) {
    if (spring == OrionSpringSpec.gentle) {
      return 'gentle';
    }
    if (spring == OrionSpringSpec.immediate) {
      return 'immediate';
    }
    return 'snappy';
  }

  String _springLabel(OrionSpringSpec spring) {
    if (spring == OrionSpringSpec.gentle) {
      return 'Gentle';
    }
    if (spring == OrionSpringSpec.immediate) {
      return 'Immediate';
    }
    return 'Snappy';
  }
}
