import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/text_field/orion_text_field.dart';
import 'package:orion_ui/src/components/text_field/orion_text_field_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionTextFieldVariant] and
/// [OrionTextFieldSize].
///
/// This is the bottom layer of the field's three-layer resolution: the variant
/// picks the face, the size steps height, padding, radius, icon size, and
/// crisp 13 / 14 / 15 pt input typography, and focus sweeps the hairline on a
/// clamped critically damped spring.
abstract final class OrionTextFieldPresets {
  /// Default critically damped focus spring (no overshoot).
  static const OrionSpringSpec defaultFocusSpring = OrionSpringSpec(
    stiffness: 380.0,
    dampingRatio: 1.0,
    clampOvershoot: true,
  );

  /// Resolves the built-in style against the ambient scheme and type scale.
  static OrionTextFieldStyle resolve({
    required OrionTextFieldVariant variant,
    required OrionTextFieldSize size,
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final (
      double height,
      double horizontalPad,
      double verticalPad,
      BorderRadius radius,
      double fontSize,
      double lineHeight,
      double iconSize,
    ) = switch (size) {
      OrionTextFieldSize.small => (
        40.0,
        OrionSpacing.space12,
        OrionSpacing.space8,
        BorderRadius.circular(OrionRadii.radius8),
        13.0,
        1.35,
        16.0,
      ),
      OrionTextFieldSize.medium => (
        OrionSizing.controlHeightLarge,
        OrionSpacing.space12,
        12.0,
        BorderRadius.circular(OrionRadii.radius8),
        14.0,
        1.4,
        18.0,
      ),
      OrionTextFieldSize.large => (
        56.0,
        OrionSpacing.space16,
        15.0,
        BorderRadius.circular(OrionRadii.radius12),
        15.0,
        1.4,
        20.0,
      ),
    };

    final Color disabledBorder = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledContent = scheme.onSurface.withValues(alpha: 0.38);
    final Color disabledOutlineFill = scheme.onSurface.withValues(
      alpha: isDark ? 0.05 : 0.04,
    );
    final Color disabledFilledBg = scheme.onSurface.withValues(
      alpha: isDark ? 0.08 : 0.07,
    );

    final Color restingBorder = switch (variant) {
      OrionTextFieldVariant.outline => scheme.outline,
      OrionTextFieldVariant.filled => Colors.transparent,
      OrionTextFieldVariant.underline => scheme.outline,
    };
    final Color hoveredBorder = switch (variant) {
      OrionTextFieldVariant.outline || OrionTextFieldVariant.underline =>
        Color.lerp(scheme.outline, scheme.onSurface, isDark ? 0.22 : 0.28)!,
      OrionTextFieldVariant.filled => scheme.outline.withValues(alpha: 0.65),
    };

    final Color restingFill = switch (variant) {
      OrionTextFieldVariant.outline => scheme.surface,
      OrionTextFieldVariant.filled => scheme.surfaceContainerHighest,
      OrionTextFieldVariant.underline => Colors.transparent,
    };
    final Color hoveredFill = switch (variant) {
      OrionTextFieldVariant.outline => Color.lerp(
        scheme.surface,
        scheme.onSurface,
        isDark ? 0.02 : 0.015,
      )!,
      OrionTextFieldVariant.filled => Color.lerp(
        scheme.surfaceContainerHighest,
        scheme.onSurface,
        0.04,
      )!,
      OrionTextFieldVariant.underline => Colors.transparent,
    };
    final Color focusedFill = switch (variant) {
      OrionTextFieldVariant.outline => scheme.surface,
      OrionTextFieldVariant.filled => Color.lerp(
        scheme.surfaceContainerHighest,
        scheme.surface,
        isDark ? 0.15 : 0.35,
      )!,
      OrionTextFieldVariant.underline => Colors.transparent,
    };

    final TextStyle resolvedTextStyle =
        (textTheme.bodyMedium ?? const TextStyle()).copyWith(
          fontSize: fontSize,
          height: lineHeight,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.0,
        );
    final TextStyle resolvedLabelStyle =
        (textTheme.labelMedium ?? const TextStyle()).copyWith(
          fontSize: 13.0,
          height: 1.3,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.05,
        );
    final TextStyle resolvedCaptionStyle =
        (textTheme.bodySmall ?? const TextStyle()).copyWith(
          fontSize: 12.0,
          height: 1.35,
          fontWeight: FontWeight.w400,
        );

    return OrionTextFieldStyle(
      fillColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return switch (variant) {
            OrionTextFieldVariant.outline => disabledOutlineFill,
            OrionTextFieldVariant.filled => disabledFilledBg,
            OrionTextFieldVariant.underline => Colors.transparent,
          };
        }
        if (states.contains(WidgetState.focused)) {
          return focusedFill;
        }
        if (states.contains(WidgetState.hovered)) {
          return hoveredFill;
        }
        return restingFill;
      }),
      borderColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return variant == OrionTextFieldVariant.filled
              ? Colors.transparent
              : disabledBorder;
        }
        if (states.contains(WidgetState.error)) {
          return scheme.error;
        }
        if (states.contains(WidgetState.focused)) {
          return scheme.primary;
        }
        if (states.contains(WidgetState.hovered)) {
          return hoveredBorder;
        }
        return restingBorder;
      }),
      borderWidth: 1.0,
      focusedBorderWidth: 1.5,
      focusRingColor: Colors.transparent,
      focusRingWidth: 0.0,
      textColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? disabledContent
            : scheme.onSurface,
      ),
      hintColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? disabledContent
            : scheme.onSurfaceVariant,
      ),
      labelColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return disabledContent;
        }
        if (states.contains(WidgetState.error)) {
          return scheme.error;
        }
        return scheme.onSurface;
      }),
      iconColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return disabledContent;
        }
        if (states.contains(WidgetState.error)) {
          return scheme.error;
        }
        if (states.contains(WidgetState.focused)) {
          return scheme.onSurface;
        }
        return scheme.onSurfaceVariant;
      }),
      errorColor: scheme.error,
      cursorColor: scheme.primary,
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPad,
        vertical: verticalPad,
      ),
      radius: variant == OrionTextFieldVariant.underline
          ? BorderRadius.zero
          : radius,
      iconSize: iconSize,
      labelGap: 6.0,
      captionGap: 6.0,
      textStyle: resolvedTextStyle,
      labelStyle: resolvedLabelStyle,
      captionStyle: resolvedCaptionStyle,
      spring: defaultFocusSpring,
    );
  }
}
