import 'package:flutter/material.dart';
import 'package:orion_ui_example/showcase/orion_showcase_kit.dart';
import 'package:orion_ui_example/showcase/orion_showcase_scaffold.dart';
import 'package:orion_ui/orion_ui.dart';

/// Interactive showcase playground for [OrionOtpField] and [OrionOtpController].
class OrionOtpShowcaseScreen extends StatefulWidget {
  const OrionOtpShowcaseScreen({super.key});

  @override
  State<OrionOtpShowcaseScreen> createState() => _OrionOtpShowcaseScreenState();
}

enum _OtpLengthChoice { four, six }

enum _OtpStatusChoice { idle, error, success }

enum _OtpGroupChoice { none, grouped }

class _OrionOtpShowcaseScreenState extends State<OrionOtpShowcaseScreen> {
  final OrionOtpController _playgroundController = OrionOtpController();
  final OrionOtpController _groupedController = OrionOtpController();
  final OrionOtpController _pinController = OrionOtpController();

  _OtpLengthChoice _lengthChoice = _OtpLengthChoice.six;
  _OtpStatusChoice _statusChoice = _OtpStatusChoice.idle;
  _OtpGroupChoice _groupChoice = _OtpGroupChoice.none;
  bool _obscureText = false;
  bool _delayedObscure = true;

  String _lastCompletedCode = 'None';
  String _pinVerificationResult = 'Enter 4-digit PIN (Try 1234)';

  int get _activeLength => switch (_lengthChoice) {
    _OtpLengthChoice.four => 4,
    _OtpLengthChoice.six => 6,
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
    },
  };

  String get _snippet {
    final List<String> lines = <String>[
      'OrionOtpField(',
      '  length: $_activeLength,',
      '  status: OrionOtpStatus.${_activeStatus.name},',
    ];
    if (_obscureText) {
      lines.add('  obscureText: true,');
      if (_delayedObscure) {
        lines.add('  delayedObscure: true,');
      }
    }
    if (_activeGroupLength != null) {
      lines.add('  groupLength: $_activeGroupLength,');
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
    super.dispose();
  }

  void _verifyPin(String pin) {
    if (pin.length < 4) return;
    if (pin == '1234') {
      setState(() => _pinVerificationResult = 'PIN Verified Successfully! ✓');
    } else {
      _pinController.shake();
      setState(() => _pinVerificationResult = 'Incorrect PIN! (Try 1234) ✗');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return OrionThemedScaffold(
      title: 'Orion OTP & PIN Field',
      builder: (context) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Category Header
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
                    'Physics-driven OTP and PIN code fields with single-input autofill cooperation, slot micro-bounce springs, and delayed secure dot masking.',
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
                  'Type or paste digits into the field below to experience tactile slot springs and carets',
              card: true,
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
                        ),
                      ),
                      child: Center(
                        child: OrionOtpField(
                          key: ValueKey(
                            'otp-field-$_activeLength-$_activeGroupLength',
                          ),
                          controller: _playgroundController,
                          length: _activeLength,
                          status: _activeStatus,
                          obscureText: _obscureText,
                          delayedObscure: _delayedObscure,
                          groupLength: _activeGroupLength,
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
                            _playgroundController.value = _activeLength == 4
                                ? '1234'
                                : '123456';
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
                    const SizedBox(height: 2.00),

                    // Controls
                    OrionShowcaseChoice<_OtpLengthChoice>(
                      label: 'Length',
                      values: _OtpLengthChoice.values,
                      selected: _lengthChoice,
                      labelOf: (l) => switch (l) {
                        _OtpLengthChoice.four => '4 digits',
                        _OtpLengthChoice.six => '6 digits',
                      },
                      onChanged: (l) => setState(() {
                        _lengthChoice = l;
                        _playgroundController.clear();
                      }),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_OtpStatusChoice>(
                      label: 'Status',
                      values: _OtpStatusChoice.values,
                      selected: _statusChoice,
                      labelOf: (s) => s.name,
                      onChanged: (s) => setState(() => _statusChoice = s),
                    ),
                    const SizedBox(height: OrionSpacing.space16),

                    OrionShowcaseChoice<_OtpGroupChoice>(
                      label: 'Slot grouping',
                      values: _OtpGroupChoice.values,
                      selected: _groupChoice,
                      labelOf: (g) => switch (g) {
                        _OtpGroupChoice.none => 'Continuous',
                        _OtpGroupChoice.grouped => 'Grouped (e.g. 3 + 3)',
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
            const SizedBox(height: 2.04),

            // Grouped SMS 2FA Specimen Card
            OrionShowcaseSection(
              title: 'Grouped SMS Authentication',
              subtitle:
                  'Dividing 6-digit codes into 3 + 3 clusters with a subtle divider dash reduces verification fatigue',
              card: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(2.00),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrionRadii.radius12),
                  color: isDark
                      ? scheme.surfaceContainerLow
                      : scheme.surfaceContainerLowest,
                  border: Border.all(
                    color: isDark
                        ? scheme.outlineVariant.withValues(alpha: 0.15)
                        : scheme.outlineVariant.withValues(alpha: 0.30),
                  ),
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
                            color: scheme.outlineVariant,
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
            const SizedBox(height: 2.04),

            // Secure 4-Digit Transaction PIN Specimen Card
            OrionShowcaseSection(
              title: 'Secure Transaction PIN',
              subtitle:
                  'Briefly reveals entered numbers for 400 ms before securely rolling into bullet dots (●)',
              card: true,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(2.00),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(OrionRadii.radius12),
                  color: isDark
                      ? scheme.surfaceContainerLow
                      : scheme.surfaceContainerLowest,
                  border: Border.all(
                    color: isDark
                        ? scheme.outlineVariant.withValues(alpha: 0.15)
                        : scheme.outlineVariant.withValues(alpha: 0.30),
                  ),
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
                        obscureText: true,
                        delayedObscure: true,
                        onChanged: (val) {
                          if (val.length < 4) {
                            setState(
                              () => _pinVerificationResult =
                                  'Enter 4-digit PIN (Try 1234)',
                            );
                          }
                        },
                        onCompleted: _verifyPin,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _pinVerificationResult,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: _pinVerificationResult.contains('Successfully')
                            ? scheme.primary
                            : _pinVerificationResult.contains('Incorrect')
                            ? scheme.error
                            : scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
