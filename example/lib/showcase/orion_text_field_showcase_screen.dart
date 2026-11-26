import 'package:flutter/material.dart';
import 'package:orion_ui/orion_ui.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';

/// Playground and verification showcase for [OrionTextField].
class OrionTextFieldShowcaseScreen extends StatefulWidget {
  const OrionTextFieldShowcaseScreen({super.key});

  @override
  State<OrionTextFieldShowcaseScreen> createState() =>
      _OrionTextFieldShowcaseScreenState();
}

class _OrionTextFieldShowcaseScreenState
    extends State<OrionTextFieldShowcaseScreen> {
  // Playground state
  final TextEditingController _playgroundController = TextEditingController();
  OrionTextFieldVariant _variant = OrionTextFieldVariant.outline;
  OrionTextFieldSize _size = OrionTextFieldSize.medium;
  OrionTextFieldType _type = OrionTextFieldType.text;
  bool _clearable = true;
  bool _required = false;
  bool _error = false;
  bool _disabled = false;

  // Live form demo state
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _formEmailController = TextEditingController();
  final TextEditingController _formAmountController = TextEditingController();
  final TextEditingController _formBioController = TextEditingController();
  String _formStatus = 'Fill out the form or tap Prefill to test sync.';

  // Patterns demo state
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _pickerController = TextEditingController(
    text: 'Pro Workspace',
  );
  int _pickerIndex = 0;
  static const List<String> _workspaces = <String>[
    'Pro Workspace',
    'Design Systems',
    'Mobile Core',
  ];

  @override
  void dispose() {
    _playgroundController.dispose();
    _formEmailController.dispose();
    _formAmountController.dispose();
    _formBioController.dispose();
    _searchController.dispose();
    _pickerController.dispose();
    super.dispose();
  }

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

  String _hintForType(OrionTextFieldType type) => switch (type) {
    OrionTextFieldType.text => 'Ada Lovelace',
    OrionTextFieldType.email => 'ada@orion.dev',
    OrionTextFieldType.password => 'Enter your password',
    OrionTextFieldType.number => '42',
    OrionTextFieldType.phone => '+1 (555) 234-5678',
    OrionTextFieldType.url => 'https://orion.dev',
    OrionTextFieldType.multiline => 'Write a short release note...',
    OrionTextFieldType.search => 'Search components...',
  };

  Widget? _prefixForType(OrionTextFieldType type) => switch (type) {
    OrionTextFieldType.email => const Icon(Icons.mail_outline_rounded),
    OrionTextFieldType.password => const Icon(Icons.lock_outline_rounded),
    OrionTextFieldType.phone => const Icon(Icons.phone_outlined),
    OrionTextFieldType.url => const Icon(Icons.link_rounded),
    OrionTextFieldType.search => const Icon(Icons.search_rounded),
    _ => null,
  };

  String get _snippet {
    final List<String> lines = <String>[
      'OrionTextField(',
      "  label: '${_typeLabel(_type)}',",
      "  hint: '${_hintForType(_type)}',",
      if (_variant != OrionTextFieldVariant.outline)
        '  variant: OrionTextFieldVariant.${_variant.name},',
      if (_size != OrionTextFieldSize.medium)
        '  size: OrionTextFieldSize.${_size.name},',
      if (_type != OrionTextFieldType.text)
        '  type: OrionTextFieldType.${_type.name},',
      if (_clearable && _type != OrionTextFieldType.search)
        '  showClearButton: true,',
      if (!_clearable && _type == OrionTextFieldType.search)
        '  showClearButton: false,',
      if (_required) '  required: true,',
      if (_disabled) '  enabled: false,',
      if (_error) "  error: 'Please enter a valid value',",
      ');',
    ];
    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Orion Text Field',
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
                      'INPUT • FORM-SYNCED TEXT FIELD',
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
                    'Refined 13 / 14 / 15 pt input typography with full-box '
                    'caret hit-testing, critically damped hairline focus, '
                    'synchronized FormField reset/validate, animated clear '
                    'actions, and crash-safe multiline support.',
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
                  'Test variants, sizes, semantic presets, clear button, and validation states',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                code: _snippet,
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionTextField(
                      controller: _playgroundController,
                      variant: _variant,
                      size: _size,
                      type: _type,
                      label: _typeLabel(_type),
                      hint: _hintForType(_type),
                      helper: 'Tap the label or anywhere inside to focus.',
                      error: _error ? 'Please enter a valid value' : null,
                      prefix: _prefixForType(_type),
                      showClearButton: _clearable,
                      required: _required,
                      enabled: !_disabled,
                      reserveCaption: true,
                    ),
                    const SizedBox(height: OrionSpacing.space16),
                    OrionShowcaseControls(
                      children: <Widget>[
                        OrionShowcaseChoice<OrionTextFieldVariant>(
                          label: 'Variant',
                          values: OrionTextFieldVariant.values,
                          selected: _variant,
                          labelOf: _variantLabel,
                          onChanged: (OrionTextFieldVariant v) =>
                              setState(() => _variant = v),
                        ),
                        OrionShowcaseChoice<OrionTextFieldSize>(
                          label: 'Size',
                          values: OrionTextFieldSize.values,
                          selected: _size,
                          labelOf: _sizeLabel,
                          onChanged: (OrionTextFieldSize s) =>
                              setState(() => _size = s),
                        ),
                        OrionShowcaseChoice<OrionTextFieldType>(
                          label: 'Type',
                          values: OrionTextFieldType.values,
                          selected: _type,
                          labelOf: _typeLabel,
                          onChanged: (OrionTextFieldType t) =>
                              setState(() => _type = t),
                        ),
                        Wrap(
                          spacing: OrionSpacing.space20,
                          runSpacing: OrionSpacing.space12,
                          children: <Widget>[
                            OrionShowcaseToggle(
                              label: 'Clearable',
                              value: _clearable,
                              onChanged: (bool v) =>
                                  setState(() => _clearable = v),
                            ),
                            OrionShowcaseToggle(
                              label: 'Required',
                              value: _required,
                              onChanged: (bool v) =>
                                  setState(() => _required = v),
                            ),
                            OrionShowcaseToggle(
                              label: 'Error',
                              value: _error,
                              onChanged: (bool v) => setState(() => _error = v),
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

            // Variants & Sizes Card
            OrionShowcaseSection(
              title: 'Variants & Sizes',
              subtitle:
                  'Small (40 pt / 13 pt), Medium (48 pt / 14 pt), and Large (56 pt / 15 pt)',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const OrionTextField(
                    variant: OrionTextFieldVariant.outline,
                    size: OrionTextFieldSize.small,
                    label: 'Outline • Small',
                    hint: 'Compact 40 pt field',
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  const OrionTextField(
                    variant: OrionTextFieldVariant.filled,
                    size: OrionTextFieldSize.medium,
                    label: 'Filled • Medium',
                    hint: 'Standard 48 pt filled field',
                  ),
                  const SizedBox(height: OrionSpacing.space12),
                  const OrionTextField(
                    variant: OrionTextFieldVariant.underline,
                    size: OrionTextFieldSize.large,
                    label: 'Underline • Large',
                    hint: 'Generous 56 pt underline field',
                  ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Live Form Validation & Sync Card
            OrionShowcaseSection(
              title: 'Form Validation & Controller Sync',
              subtitle:
                  'Validates programmatic prefills, supports decimal numbers, and resets both controller and errors',
              card: true,
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    OrionTextField(
                      controller: _formEmailController,
                      type: OrionTextFieldType.email,
                      label: 'Work email',
                      hint: 'ada@orion.dev',
                      required: true,
                      showClearButton: true,
                      prefix: const Icon(Icons.mail_outline_rounded),
                      reserveCaption: true,
                      validator: (String? value) {
                        final String v = (value ?? '').trim();
                        if (v.isEmpty) return 'Email is required';
                        if (!v.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionTextField(
                      controller: _formAmountController,
                      type: OrionTextFieldType.number,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      label: 'Budget (decimal allowed)',
                      hint: '1250.50',
                      prefix: const Text(r'$'),
                      suffix: const Text('USD'),
                      reserveCaption: true,
                      validator: (String? value) {
                        final String v = (value ?? '').trim();
                        if (v.isEmpty) return 'Amount is required';
                        if (double.tryParse(v) == null) {
                          return 'Enter a valid decimal number';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    OrionTextField(
                      controller: _formBioController,
                      type: OrionTextFieldType.multiline,
                      label: 'Release summary',
                      hint: 'Multi-line notes with proper vertical padding...',
                      maxLength: 140,
                      reserveCaption: true,
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Wrap(
                      spacing: OrionSpacing.space8,
                      runSpacing: OrionSpacing.space8,
                      children: <Widget>[
                        OrionButton(
                          label: 'Validate',
                          size: OrionButtonSize.small,
                          onPressed: () {
                            final bool ok =
                                _formKey.currentState?.validate() ?? false;
                            setState(() {
                              _formStatus = ok
                                  ? 'Form is valid (${_formEmailController.text}, \$${_formAmountController.text})'
                                  : 'Validation failed — see highlighted errors above.';
                            });
                          },
                        ),
                        OrionButton(
                          label: 'Prefill',
                          variant: OrionButtonVariant.bordered,
                          size: OrionButtonSize.small,
                          onPressed: () {
                            _formEmailController.text = 'ada@orion.dev';
                            _formAmountController.text = '249.95';
                            _formBioController.text =
                                'Upgraded OrionTextField with synced FormField state and refined typography.';
                            setState(() {
                              _formStatus =
                                  'Prefilled via controllers — tap Validate to confirm sync.';
                            });
                          },
                        ),
                        OrionButton(
                          label: 'Reset',
                          variant: OrionButtonVariant.flat,
                          size: OrionButtonSize.small,
                          onPressed: () {
                            _formKey.currentState?.reset();
                            setState(() {
                              _formStatus = 'Form & controllers reset cleanly.';
                            });
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space8),
                    Text(
                      _formStatus,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: OrionSpacing.space20),

            // Common Input Patterns Card
            OrionShowcaseSection(
              title: 'Input Patterns',
              subtitle:
                  'Auto-clearable search, balanced password reveal, picker trigger mode, and disabled state',
              card: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  OrionTextField(
                    controller: _searchController,
                    type: OrionTextFieldType.search,
                    variant: OrionTextFieldVariant.filled,
                    label: 'Search',
                    hint: 'Type to reveal animated clear button',
                    prefix: const Icon(Icons.search_rounded),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  const OrionTextField(
                    type: OrionTextFieldType.password,
                    size: OrionTextFieldSize.small,
                    label: 'Small password (40 pt)',
                    hint: 'Eye toggle fits cleanly without stretching',
                    prefix: Icon(Icons.lock_outline_rounded),
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  OrionTextField(
                    controller: _pickerController,
                    readOnly: true,
                    label: 'Workspace (Read-only picker)',
                    helper: 'Tap to cycle workspace — click cursor, no caret.',
                    prefix: const Icon(Icons.workspaces_outline),
                    suffix: const Icon(Icons.keyboard_arrow_down_rounded),
                    onTap: () {
                      setState(() {
                        _pickerIndex = (_pickerIndex + 1) % _workspaces.length;
                        _pickerController.text = _workspaces[_pickerIndex];
                      });
                    },
                  ),
                  const SizedBox(height: OrionSpacing.space16),
                  const OrionTextField(
                    initialValue: 'Locked account setting',
                    label: 'Disabled field',
                    enabled: false,
                    prefix: Icon(Icons.shield_outlined),
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
