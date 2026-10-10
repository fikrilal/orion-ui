import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/text_field/orion_text_field.dart';
import 'package:orion_ui/src/components/text_field/orion_text_field_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionTextFieldVariant] and
/// [OrionTextFieldSize].
///
/// This is the bottom layer of the field's three-layer resolution: the variant
/// picks the face, the size steps the height, padding, radius and type, and
/// focus is the line itself - it steps to `primary` and half a point wider on
/// the kit's clamped critically damped spring.
abstract final class OrionTextFieldPresets {
  /// Resolves the built-in style against the ambient scheme and type scale.
  static OrionTextFieldStyle resolve({
    required OrionTextFieldVariant variant,
    required OrionTextFieldSize size,
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
    final (
      double height,
      double padding,
      BorderRadius radius,
      TextStyle? text,
    ) = switch (size) {
      OrionTextFieldSize.small => (
        40,
        OrionSpacing.space12,
        BorderRadius.circular(OrionRadii.radius8),
        textTheme.bodyMedium,
      ),
      OrionTextFieldSize.medium => (
        OrionSizing.controlHeightLarge,
        OrionSpacing.space12,
        BorderRadius.circular(OrionRadii.radius8),
        textTheme.bodyLarge,
      ),
      OrionTextFieldSize.large => (
        56,
        OrionSpacing.space16,
        BorderRadius.circular(OrionRadii.radius12),
        textTheme.bodyLarge,
      ),
    };

    final Color disabledContainer = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledContent = scheme.onSurface.withValues(alpha: 0.38);
    final Color restingBorder = switch (variant) {
      OrionTextFieldVariant.outline => scheme.outline,
      OrionTextFieldVariant.filled => Colors.transparent,
      OrionTextFieldVariant.underline => scheme.outline,
    };
    final Color fill = switch (variant) {
      OrionTextFieldVariant.outline => scheme.surface,
      OrionTextFieldVariant.filled => scheme.surfaceContainerHighest,
      OrionTextFieldVariant.underline => Colors.transparent,
    };

    return OrionTextFieldStyle(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? (variant == OrionTextFieldVariant.filled
                  ? disabledContainer
                  : fill)
            : fill,
      ),
      borderColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return disabledContainer;
        }
        if (states.contains(WidgetState.error)) {
          return scheme.error;
        }
        return states.contains(WidgetState.focused)
            ? scheme.primary
            : restingBorder;
      }),
      borderWidth: 1,
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
      cursorColor: scheme.onSurface,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padding),
      radius: variant == OrionTextFieldVariant.underline
          ? BorderRadius.zero
          : radius,
      labelGap: OrionSpacing.space8,
      captionGap: OrionSpacing.space8,
      textStyle: text,
      labelStyle: textTheme.labelMedium,
      captionStyle: textTheme.bodySmall,
      spring: const OrionSpringSpec(
        stiffness: 380,
        dampingRatio: 1,
        clampOvershoot: true,
      ),
    );
  }
}
