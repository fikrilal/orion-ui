import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/otp/orion_otp_field.dart';
import 'package:orion_ui/src/components/otp/orion_otp_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionOtpStyle].
abstract final class OrionOtpPresets {
  /// Resolves the default OTP field style for the active color scheme and
  /// [variant].
  static OrionOtpStyle resolve({
    required ColorScheme scheme,
    OrionOtpVariant variant = OrionOtpVariant.outline,
    TextTheme? textTheme,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color successColor = isDark
        ? const Color(0xFF22C55E)
        : const Color(0xFF16A34A);
    final Color errorTint = scheme.error.withValues(
      alpha: isDark ? 0.12 : 0.06,
    );
    final Color successTint = successColor.withValues(
      alpha: isDark ? 0.12 : 0.06,
    );
    final Color disabledFill = scheme.onSurface.withValues(alpha: 0.06);
    final Color disabledBorder = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledText = scheme.onSurface.withValues(alpha: 0.38);
    final Color filledBorder = scheme.onSurface.withValues(
      alpha: isDark ? 0.32 : 0.28,
    );
    final Color hoverBorder = scheme.onSurface.withValues(
      alpha: isDark ? 0.42 : 0.38,
    );

    final (
      double borderWidth,
      BorderRadius radius,
      Color bg,
      Color activeBg,
      Color filledBg,
      Color errorBg,
      Color successBg,
      Color disabledBg,
      Color hoverBg,
      Color border,
      Color filledSlotBorder,
    ) = switch (variant) {
      OrionOtpVariant.outline => (
        1.0,
        BorderRadius.circular(OrionRadii.radius12),
        scheme.surfaceContainer,
        scheme.surfaceContainer,
        scheme.surfaceContainer,
        errorTint,
        successTint,
        disabledFill,
        scheme.onSurface.withValues(alpha: 0.03),
        scheme.outline,
        filledBorder,
      ),
      OrionOtpVariant.filled => (
        0.0,
        BorderRadius.circular(OrionRadii.radius12),
        scheme.surfaceContainerHighest,
        scheme.surfaceContainer,
        scheme.surfaceContainerHighest,
        errorTint,
        successTint,
        disabledFill,
        scheme.onSurface.withValues(alpha: 0.05),
        Colors.transparent,
        Colors.transparent,
      ),
      OrionOtpVariant.underline => (
        1.5,
        BorderRadius.zero,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        Colors.transparent,
        scheme.outline,
        filledBorder,
      ),
    };

    return OrionOtpStyle(
      slotWidth: 42.0,
      slotHeight: 52.0,
      slotBorderRadius: radius,
      slotBorderWidth: borderWidth,
      activeBorderWidth: 2.0,
      slotSpacing: 6.0,
      groupSpacing: 14.0,
      backgroundColor: bg,
      activeBackgroundColor: activeBg,
      filledBackgroundColor: filledBg,
      errorBackgroundColor: errorBg,
      successBackgroundColor: successBg,
      disabledBackgroundColor: disabledBg,
      hoverBackgroundColor: hoverBg,
      borderColor: border,
      activeBorderColor: scheme.primary,
      filledBorderColor: filledSlotBorder,
      errorBorderColor: scheme.error,
      successBorderColor: successColor,
      disabledBorderColor: disabledBorder,
      hoverBorderColor: variant == OrionOtpVariant.filled
          ? Colors.transparent
          : hoverBorder,
      textStyle: TextStyle(
        fontSize: 20.0,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.5,
        color: scheme.onSurface,
        fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
      ),
      disabledTextColor: disabledText,
      placeholderTextStyle: TextStyle(
        fontSize: 18.0,
        fontWeight: FontWeight.w500,
        color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
      ),
      labelStyle:
          textTheme?.labelMedium?.copyWith(color: scheme.onSurface) ??
          TextStyle(
            fontSize: 13.0,
            fontWeight: FontWeight.w500,
            color: scheme.onSurface,
          ),
      captionStyle:
          textTheme?.bodySmall?.copyWith(color: scheme.onSurfaceVariant) ??
          TextStyle(fontSize: 12.0, color: scheme.onSurfaceVariant),
      caretColor: scheme.primary,
      caretWidth: 2.0,
      caretHeight: 22.0,
      shakeSpringSpec: const OrionSpringSpec(
        stiffness: 900.0,
        dampingRatio: 0.28,
      ),
      slotSpringSpec: const OrionSpringSpec(
        stiffness: 600.0,
        dampingRatio: 0.85,
      ),
    );
  }
}
