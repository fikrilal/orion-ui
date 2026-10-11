import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/otp/orion_otp_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionOtpStyle].
abstract final class OrionOtpPresets {
  /// Resolves the default OTP field style for the active color scheme.
  static OrionOtpStyle resolve({required ColorScheme scheme}) {
    return OrionOtpStyle(
      slotWidth: 42.0,
      slotHeight: 52.0,
      slotBorderRadius: BorderRadius.circular(OrionRadii.radius12),
      slotBorderWidth: 1.0,
      activeBorderWidth: 2.0,
      slotSpacing: 6.0,
      groupSpacing: 14.0,
      backgroundColor: scheme.surfaceContainerLowest,
      activeBackgroundColor: scheme.surface,
      filledBackgroundColor: scheme.surface,
      borderColor: scheme.outlineVariant.withValues(alpha: 0.35),
      activeBorderColor: scheme.primary,
      filledBorderColor: scheme.outlineVariant.withValues(alpha: 0.65),
      errorBorderColor: scheme.error,
      successBorderColor: scheme.primary,
      textStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: scheme.onSurface,
      ),
      caretColor: scheme.primary,
      caretWidth: 2.0,
      caretHeight: 22.0,
      shakeSpringSpec: const OrionSpringSpec(
        stiffness: 420.0,
        dampingRatio: 0.65,
      ),
      slotSpringSpec: const OrionSpringSpec(
        stiffness: 450.0,
        dampingRatio: 0.80,
      ),
    );
  }
}
