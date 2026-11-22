import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Playground for [OrionTextField].
///
/// The `Disabled`, `Error` and `Obscured` flags in the top controls card drive
/// every sample; the sections below are the reference matrices - faces, sizes,
/// types, content - and the playground last drives one field through its axes
/// with the generated call behind the Code tab.
class OrionTextFieldShowcaseScreen extends StatefulWidget {
  const OrionTextFieldShowcaseScreen({super.key});

  @override
  State<OrionTextFieldShowcaseScreen> createState() =>
      _OrionTextFieldShowcaseScreenState();
}

/// The instance-level skins the customization section demonstrates.
enum _FieldSkin { standard, accent, square }

class _OrionTextFieldShowcaseScreenState
    extends State<OrionTextFieldShowcaseScreen> {
  // Flags: shared by every sample on the page.
  bool _disabled = false;
  bool _error = false;
  bool _obscured = false;

  // Customization: the focused skin choice.
  _FieldSkin _skin = _FieldSkin.standard;

  // Playground: the focused specimen's axes.
  OrionTextFieldVariant _variant = OrionTextFieldVariant.outline;
  OrionTextFieldSize _size = OrionTextFieldSize.medium;
  OrionTextFieldType _type = OrionTextFieldType.text;

  /// One sample under the shared flags.
  OrionTextField _sample({
    required String label,
    required String hint,
    String? error,
    OrionTextFieldVariant? variant,
    OrionTextFieldSize? size,
    OrionTextFieldType type = OrionTextFieldType.text,
    Widget? prefix,
    Widget? suffix,
    int? maxLength,
    bool reserveCaption = false,
    bool readOnly = false,
  }) {
    return OrionTextField(
      label: label,
      hint: hint,
      variant: variant ?? _variant,
      size: size ?? _size,
      type: type,
      enabled: !_disabled,
      error: _error ? error : null,
      obscureText: _obscured || type == OrionTextFieldType.password,
      prefix: prefix,
      suffix: suffix,
      maxLength: maxLength,
      reserveCaption: reserveCaption,
      readOnly: readOnly,
      onChanged: _disabled ? null : (String _) {},
    );
  }

  OrionTextFieldStyle? _skinStyle(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    return switch (_skin) {
      _FieldSkin.standard => null,
      _FieldSkin.accent => OrionTextFieldStyle.from(
        borderColor: scheme.primary,
      ),
      _FieldSkin.square => OrionTextFieldStyle.from(
        radius: BorderRadius.zero,
        borderWidth: 2,
      ),
    };
  }

  String _skinLabel(_FieldSkin skin) => switch (skin) {
    _FieldSkin.standard => 'Standard',
    _FieldSkin.accent => 'Accent',
    _FieldSkin.square => 'Square',
  };

  String _variantLabel(OrionTextFieldVariant variant) => switch (variant) {
    OrionTextFieldVariant.outline => 'Outline',
    OrionTextFieldVariant.filled => 'Filled',
    OrionTextFieldVariant.underline => 'Underline',
  };

  String _sizeLabel(OrionTextFieldSize size) => switch (size) {
    OrionTextFieldSize.small => 'Small',
    OrionTextFieldSize.medium => 'Medium',
    OrionTextFieldSize.large => 'Large',
  };

  String _typeLabel(OrionTextFieldType type) => switch (type) {
    OrionTextFieldType.text => 'Text',
    OrionTextFieldType.email => 'Email',
    OrionTextFieldType.password => 'Password',
    OrionTextFieldType.number => 'Number',
    OrionTextFieldType.phone => 'Phone',
    OrionTextFieldType.url => 'URL',
    OrionTextFieldType.multiline => 'Multiline',
    OrionTextFieldType.search => 'Search',
  };

  /// The exact call the current controls produce.
  String get _snippet {
    final List<String> lines = <String>[
      'OrionTextField(',
      "  label: 'Name',",
      "  hint: 'Ada Lovelace',",
    ];
    if (_variant != OrionTextFieldVariant.outline) {
      lines.add('  variant: OrionTextFieldVariant.${_variant.name},');
    }
    if (_size != OrionTextFieldSize.medium) {
      lines.add('  size: OrionTextFieldSize.${_size.name},');
    }
    if (_type != OrionTextFieldType.text) {
      lines.add('  type: OrionTextFieldType.${_type.name},');
    }
    if (_disabled) {
      lines.add('  enabled: false,');
    }
    if (_error) {
      lines.add("  error: 'Name is required',");
    }
    if (_obscured) {
      lines.add('  obscureText: true,');
    }
    lines.add(');');
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion Text field',
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
                      'INPUT • EXPANDING FOCUS HAIRLINE',
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
                    'Single-line or expanding multiline field. Hairline focus steps to primary and expands half a point wider on clamped critically damped spring without flash-back.',
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
                    Expanded(
                      child: OrionShowcaseToggle(
                        label: 'Error',
                        value: _error,
                        onChanged: (value) => setState(() => _error = value),
                      ),
                    ),
                    Expanded(
                      child: OrionShowcaseToggle(
                        label: 'Obscured',
                        value: _obscured,
                        onChanged: (value) => setState(() => _obscured = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 2.04),

            // Variants Card
            OrionShowcaseSection(
              title: 'Variants',
              subtitle:
                  'Outline (default hairline), Filled (container fill), and Underline (classic bottom line)',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final OrionTextFieldVariant variant
                      in OrionTextFieldVariant.values) ...<Widget>[
                    OrionShowcaseLabeledRow(
                      label: _variantLabel(variant),
                      child: _sample(
                        label: 'Name',
                        hint: 'Ada Lovelace',
                        error: 'Name is required',
                        variant: variant,
                      ),
                    ),
                    if (variant != OrionTextFieldVariant.values.last)
                      const SizedBox(height: OrionSpacing.space12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Sizes Card
            OrionShowcaseSection(
              title: 'Sizes',
              subtitle:
                  'Small (36 pt), Medium (44 pt), and Large (52 pt) container heights',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final OrionTextFieldSize size
                      in OrionTextFieldSize.values) ...<Widget>[
                    OrionShowcaseLabeledRow(
                      label: _sizeLabel(size),
                      child: _sample(
                        label: 'Name',
                        hint: 'Ada Lovelace',
                        error: 'Name is required',
                        size: size,
                      ),
                    ),
                    if (size != OrionTextFieldSize.values.last)
                      const SizedBox(height: OrionSpacing.space12),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Types Card
            OrionShowcaseSection(
              title: 'Types',
              subtitle:
                  'Semantic keyboard presets, action types, input filters, and reveal toggles',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sample(
                    label: 'Email',
                    hint: 'ada@example.com',
                    error: 'Enter a valid email',
                    type: OrionTextFieldType.email,
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    label: 'Password',
                    hint: 'Your password',
                    error: 'At least 8 characters',
                    type: OrionTextFieldType.password,
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    label: 'Search',
                    hint: 'Search chats',
                    type: OrionTextFieldType.search,
                    prefix: const Icon(Icons.search, size: 20),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Content Card
            OrionShowcaseSection(
              title: 'Content',
              subtitle:
                  'Slot composition: prefix/suffix widgets, character counter, and read-only mode',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sample(
                    label: 'Prefix and suffix',
                    hint: 'orion.dev',
                    prefix: const Icon(Icons.link, size: 20),
                    suffix: const Text('@'),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    label: 'Counter',
                    hint: 'Keep it short',
                    maxLength: 20,
                    reserveCaption: true,
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  _sample(
                    label: 'Read only',
                    hint: 'Tap to change',
                    readOnly: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Customization Card
            OrionShowcaseSection(
              title: 'Customization',
              subtitle:
                  'Three-layer style contract: Presets -> OrionTextFieldTheme -> Instance OrionTextFieldStyle',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<_FieldSkin>(
                    label: 'Skin',
                    values: _FieldSkin.values,
                    selected: _skin,
                    labelOf: _skinLabel,
                    onChanged: (value) => setState(() => _skin = value),
                  ),
                  const SizedBox(height: 2.04),
                  OrionTextField(
                    label: 'Name',
                    hint: 'Ada Lovelace',
                    enabled: !_disabled,
                    error: _error ? 'Name is required' : null,
                    obscureText: _obscured,
                    style: _skinStyle(context),
                    onChanged: _disabled ? null : (String _) {},
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2.00),

            // Playground Card
            OrionShowcaseSection(
              title: 'Playground',
              subtitle: 'Interactive text field with live code generator',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  OrionShowcaseChoice<OrionTextFieldVariant>(
                    label: 'Variant',
                    values: OrionTextFieldVariant.values,
                    selected: _variant,
                    labelOf: _variantLabel,
                    onChanged: (value) => setState(() => _variant = value),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseChoice<OrionTextFieldSize>(
                    label: 'Size',
                    values: OrionTextFieldSize.values,
                    selected: _size,
                    labelOf: _sizeLabel,
                    onChanged: (value) => setState(() => _size = value),
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  OrionShowcaseChoice<OrionTextFieldType>(
                    label: 'Type',
                    values: OrionTextFieldType.values,
                    selected: _type,
                    labelOf: _typeLabel,
                    onChanged: (value) => setState(() => _type = value),
                  ),
                  const SizedBox(height: 2.04),
                  OrionShowcasePanel(
                    key: const ValueKey<String>('showcase-panel-playground'),
                    preview: _sample(
                      label: 'Name',
                      hint: 'Ada Lovelace',
                      error: 'Name is required',
                      type: _type,
                    ),
                    code: _snippet,
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
