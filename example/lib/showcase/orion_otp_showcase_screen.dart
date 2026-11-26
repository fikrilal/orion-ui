import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Interactive showcase playground for [OrionOtpField] and [OrionOtpController].
class OrionOtpShowcaseScreen extends StatefulWidget {
  const OrionOtpShowcaseScreen({super.key});

  @override
  State<OrionOtpShowcaseScreen> createState() => _OrionOtpShowcaseScreenState();
}

enum _OtpLengthChoice { four, six, eight }

enum _OtpStatusChoice { idle, error, success }

enum _OtpGroupChoice { none, grouped }

class _OrionOtpShowcaseScreenState extends State<OrionOtpShowcaseScreen> {
  final OrionOtpController _playgroundController = OrionOtpController();
  final OrionOtpController _groupedController = OrionOtpController();
  final OrionOtpController _pinController = OrionOtpController();
  final OrionOtpController _inviteController = OrionOtpController();

  OrionOtpVariant _variant = OrionOtpVariant.outline;
  _OtpLengthChoice _lengthChoice = _OtpLengthChoice.six;
  _OtpStatusChoice _statusChoice = _OtpStatusChoice.idle;
  _OtpGroupChoice _groupChoice = _OtpGroupChoice.none;
  bool _obscureText = false;
  bool _delayedObscure = true;
  bool _disabled = false;
  bool _showPlaceholder = false;

  String _lastCompletedCode = 'None';
  OrionOtpStatus _pinStatus = OrionOtpStatus.idle;
  String? _pinError;
  String _pinHelper = 'Enter 4-digit PIN (Try 1234)';

  int get _activeLength => switch (_lengthChoice) {
    _OtpLengthChoice.four => 4,
    _OtpLengthChoice.six => 6,
    _OtpLengthChoice.eight => 8,
  };

  OrionOtpStatus get _activeStatus => switch (_statusChoice) {
    _OtpStatusChoice.idle => OrionOtpStatus.idle,
    _OtpStatusChoice.error => OrionOtpStatus.error,
    _OtpStatusChoice.success => OrionOtpStatus.success,
  };

  int? get _activeGroupLength => switch (_groupChoice) {
    _OtpGroupChoice.none => null,
    _OtpGroupChoice.grouped => switch (_lengthChoice) {
      _OtpLengthChoice.four => 2,
      _OtpLengthChoice.six => 3,
      _OtpLengthChoice.eight => 4,
    },
  };

  String get _snippet {
    final List<String> lines = <String>[
      'OrionOtpField(',
      '  length: $_activeLength,',
      if (_variant != OrionOtpVariant.outline)
        '  variant: OrionOtpVariant.${_variant.name},',
      if (_activeStatus != OrionOtpStatus.idle)
        '  status: OrionOtpStatus.${_activeStatus.name},',
    ];
    if (_obscureText) {
      lines.add('  obscureText: true,');
      if (!_delayedObscure) {
        lines.add('  delayedObscure: false,');
      }
    }
    if (_activeGroupLength != null) {
      lines.add('  groupLength: $_activeGroupLength,');
    }
    if (_showPlaceholder) {
      lines.add("  placeholder: '–',");
    }
    if (_disabled) {
      lines.add('  enabled: false,');
    }
    lines.addAll(<String>[
      '  onChanged: (code) => print("OTP changed: \$code"),',
      '  onCompleted: (code) => print("OTP completed: \$code"),',
      ');',
    ]);
    return lines.join('\n');
  }

  @override
  void dispose() {
    _playgroundController.dispose();
    _groupedController.dispose();
    _pinController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  void _verifyPin(String pin) {
    if (pin.length < 4) return;
    if (pin == '1234') {
      setState(() {
        _pinStatus = OrionOtpStatus.success;
        _pinError = null;
        _pinHelper = 'PIN verified successfully';
      });
    } else {
      _pinController.shake();
      setState(() {
        _pinStatus = OrionOtpStatus.error;
        _pinError = 'Incorrect PIN. Try 1234.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return OrionThemedScaffold(
      title: 'Orion OTP & PIN Field',
      builder: (context) {
        final theme = Theme.of(context);
        final scheme = theme.colorScheme;
        final isDark = theme.brightness == Brightness.dark;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category Header
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
                      'INPUT • CODE & PIN VERIFICATION',
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
                    'Physics-driven OTP and PIN fields with outline/filled/underline faces, formatted clipboard paste, responsive narrow-width scaling, obscured semantics, and oscillating error shake.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.45,
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Hero Interactive Stage Card
            OrionShowcaseSection(
              title: 'Interactive Playground',
              subtitle:
                  'Type, long-press to paste formatted codes (e.g. 123-456), or switch variants below',
              card: true,
              child: OrionShowcasePanel(
                key: const ValueKey<String>('showcase-panel-playground'),
                preview: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space12,
                        vertical: OrionSpacing.space24,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? scheme.surface
                            : scheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(
                          OrionRadii.radius12,
                        ),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Center(
                        child: OrionOtpField(
                          controller: _playgroundController,
                          length: _activeLength,
                          variant: _variant,
                          status: _activeStatus,
                          enabled: !_disabled,
                          obscureText: _obscureText,
                          delayedObscure: _delayedObscure,
                          groupLength: _activeGroupLength,
                          placeholder: _showPlaceholder ? '–' : null,
                          error: _activeStatus == OrionOtpStatus.error
                              ? 'Invalid verification code'
                              : null,
                          helper: _activeStatus == OrionOtpStatus.success
                              ? 'Code verified'
                              : 'Long-press any slot to paste from clipboard',
                          onCompleted: (code) {
                            setState(() => _lastCompletedCode = code);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    // Quick Controller Action Buttons
                    Wrap(
                      spacing: OrionSpacing.space8,
                      runSpacing: OrionSpacing.space8,
                      children: [
                        OrionButton(
                          size: OrionButtonSize.small,
                          variant: OrionButtonVariant.bordered,
                          onPressed: () => _playgroundController.shake(),
                          leading: const Icon(
                            Icons.vibration_rounded,
                            size: 16,
                          ),
                          child: const Text('Shake Error'),
                        ),
                        OrionButton(
                          size: OrionButtonSize.small,
                          variant: OrionButtonVariant.bordered,
                          onPressed: () {
                            _playgroundController.value =
                                switch (_activeLength) {
                                  4 => '1234',
                                  6 => '123-456',
                                  _ => '1234-5678',
                                };
                          },
                          leading: const Icon(
                            Icons.auto_fix_high_rounded,
                            size: 16,
                          ),
                          child: const Text('Fill Dummy Code'),
                        ),
                        OrionButton(
                          size: OrionButtonSize.small,
                          variant: OrionButtonVariant.flat,
                          onPressed: () {
                            _playgroundController.clear();
                            setState(() => _lastCompletedCode = 'None');
                          },
                          leading: const Icon(Icons.clear_rounded, size: 16),
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space20),

                    // Controls
                    OrionShowcaseChoice<OrionOtpVariant>(
                      label: 'Variant',
                      values: OrionOtpVariant.values,
                      selected: _variant,
                      labelOf: (v) => switch (v) {
                        OrionOtpVariant.outline => 'Outline',
                        OrionOtpVariant.filled => 'Filled',
                        OrionOtpVariant.underline => 'Underline',
                      },
                      onChanged: (v) => setState(() => _variant = v),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_OtpLengthChoice>(
                      label: 'Length',
                      values: _OtpLengthChoice.values,
                      selected: _lengthChoice,
                      labelOf: (l) => switch (l) {
                        _OtpLengthChoice.four => '4 digits',
                        _OtpLengthChoice.six => '6 digits',
                        _OtpLengthChoice.eight => '8 digits',
                      },
                      onChanged: (l) => setState(() {
                        _lengthChoice = l;
                      }),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_OtpStatusChoice>(
                      label: 'Status',
                      values: _OtpStatusChoice.values,
                      selected: _statusChoice,
                      labelOf: (s) => switch (s) {
                        _OtpStatusChoice.idle => 'Idle',
                        _OtpStatusChoice.error => 'Error',
                        _OtpStatusChoice.success => 'Success',
                      },
                      onChanged: (s) => setState(() => _statusChoice = s),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_OtpGroupChoice>(
                      label: 'Slot grouping',
                      values: _OtpGroupChoice.values,
                      selected: _groupChoice,
                      labelOf: (g) => switch (g) {
                        _OtpGroupChoice.none => 'Continuous',
                        _OtpGroupChoice.grouped => 'Grouped',
                      },
                      onChanged: (g) => setState(() => _groupChoice = g),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    Row(
                      children: [
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Obscure digits',
                            value: _obscureText,
                            onChanged: (val) =>
                                setState(() => _obscureText = val),
                          ),
                        ),
                        const SizedBox(width: OrionSpacing.space16),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Delayed mask',
                            value: _delayedObscure,
                            onChanged: (val) =>
                                setState(() => _delayedObscure = val),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: OrionSpacing.space12),
                    Row(
                      children: [
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Placeholder',
                            value: _showPlaceholder,
                            onChanged: (val) =>
                                setState(() => _showPlaceholder = val),
                          ),
                        ),
                        const SizedBox(width: OrionSpacing.space16),
                        Expanded(
                          child: OrionShowcaseToggle(
                            label: 'Disabled',
                            value: _disabled,
                            onChanged: (val) => setState(() => _disabled = val),
                          ),
                        ),
                      ],
                    ),

                    Padding(
                      padding: const EdgeInsets.only(top: OrionSpacing.space12),
                      child: Text(
                        'Last completed code: $_lastCompletedCode',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: scheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                code: _snippet,
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Grouped SMS 2FA Specimen Card
            OrionShowcaseSection(
              title: 'Grouped SMS Authentication',
              subtitle:
                  '3 + 3 cluster with separator dash that scales cleanly to narrow phone widths',
              card: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OrionSpacing.space16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrionRadii.radius12),
                  color: isDark
                      ? scheme.surface
                      : scheme.surfaceContainerLowest,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      'Verification Code',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Enter the 6-digit passcode sent to +1 (555) •••-8920',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: OrionOtpField(
                        controller: _groupedController,
                        length: 6,
                        groupLength: 3,
                        groupSeparator: Text(
                          '—',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        onCompleted: (code) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Verified SMS Passcode: $code'),
                              duration: const Duration(seconds: 2),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Secure 4-Digit Transaction PIN Specimen Card (Filled variant)
            OrionShowcaseSection(
              title: 'Secure Transaction PIN (Filled)',
              subtitle:
                  'Filled tiles with 400 ms peek mask, live error caption, and semantic green success state',
              card: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OrionSpacing.space16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrionRadii.radius12),
                  color: isDark
                      ? scheme.surface
                      : scheme.surfaceContainerLowest,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          size: 18,
                          color: scheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Authorize Transaction',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: scheme.onSurface,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Enter your 4-digit PIN to release funds',
                      style: TextStyle(
                        fontSize: 12,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: OrionOtpField(
                        controller: _pinController,
                        length: 4,
                        variant: OrionOtpVariant.filled,
                        status: _pinStatus,
                        obscureText: true,
                        delayedObscure: true,
                        error: _pinError,
                        helper: _pinHelper,
                        onChanged: (val) {
                          if (val.length < 4 &&
                              (_pinStatus != OrionOtpStatus.idle ||
                                  _pinError != null)) {
                            setState(() {
                              _pinStatus = OrionOtpStatus.idle;
                              _pinError = null;
                              _pinHelper = 'Enter 4-digit PIN (Try 1234)';
                            });
                          }
                        },
                        onCompleted: _verifyPin,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: OrionSpacing.space24),

            // Alphanumeric Invite Code Specimen Card (Underline variant)
            OrionShowcaseSection(
              title: 'Alphanumeric Invite Code (Underline)',
              subtitle:
                  'Underline slots with digitsOnly: false, uppercase formatter, and placeholder glyph',
              card: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(OrionSpacing.space16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrionRadii.radius12),
                  color: isDark
                      ? scheme.surface
                      : scheme.surfaceContainerLowest,
                  border: Border.all(color: scheme.outlineVariant),
                ),
                child: Center(
                  child: OrionOtpField(
                    controller: _inviteController,
                    length: 6,
                    groupLength: 3,
                    variant: OrionOtpVariant.underline,
                    digitsOnly: false,
                    textCapitalization: TextCapitalization.characters,
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp('[A-Za-z0-9]')),
                      TextInputFormatter.withFunction(
                        (
                          TextEditingValue oldValue,
                          TextEditingValue newValue,
                        ) => newValue.copyWith(
                          text: newValue.text.toUpperCase(),
                        ),
                      ),
                    ],
                    label: 'Workspace Invite Code',
                    placeholder: '–',
                    helper: '6-character alphanumeric code',
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
