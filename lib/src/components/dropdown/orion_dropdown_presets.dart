import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/dropdown/orion_dropdown_style.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look and motion for every [OrionDropdownVariant] and
/// [OrionDropdownSize].
///
/// This is the bottom layer of the dropdown's three-layer resolution. The face
/// mirrors `OrionTextFieldPresets` value for value so the two controls align in
/// one form; the panel mirrors the popover surface vocabulary; the springs
/// follow the kit's choreography laws - the unfold moves a layout edge (clamped,
/// no pass), the separation is a small underdamped pinch, and the dismissal is
/// critically damped with zero rebound.
abstract final class OrionDropdownPresets {
  /// Spring governing the panel extent unfolding from the field edge.
  static const OrionSpringSpec unfoldSpring = OrionSpringSpec(
    stiffness: 420.0,
    dampingRatio: 0.85,
    clampOvershoot: true,
  );

  /// Spring governing the gap opening and the facing edges rounding out.
  static const OrionSpringSpec separationSpring = OrionSpringSpec(
    stiffness: 460.0,
    dampingRatio: 0.70,
  );

  /// Spring governing dismissal: both the re-attachment and the retraction run
  /// on it, never passing their targets.
  static const OrionSpringSpec dismissSpring = OrionSpringSpec(
    stiffness: 380.0,
    dampingRatio: 1.0,
    clampOvershoot: true,
  );

  /// Spring governing the gliding highlight as the active option moves. The
  /// highlight moves a visible edge, so it is clamped.
  static const OrionSpringSpec highlightSpring = OrionSpringSpec(
    stiffness: 500.0,
    dampingRatio: 0.85,
    clampOvershoot: true,
  );

  /// Resolves the built-in style against the ambient scheme and type scale.
  static OrionDropdownStyle resolve({
    required OrionDropdownVariant variant,
    required OrionDropdownSize size,
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
    final (
      double height,
      double padding,
      BorderRadius radius,
      TextStyle? text,
    ) = switch (size) {
      OrionDropdownSize.small => (
        40,
        OrionSpacing.space12,
        BorderRadius.circular(OrionRadii.radius8),
        textTheme.bodyMedium,
      ),
      OrionDropdownSize.medium => (
        OrionSizing.controlHeightLarge,
        OrionSpacing.space12,
        BorderRadius.circular(OrionRadii.radius8),
        textTheme.bodyLarge,
      ),
      OrionDropdownSize.large => (
        56,
        OrionSpacing.space16,
        BorderRadius.circular(OrionRadii.radius12),
        textTheme.bodyLarge,
      ),
    };

    final Color disabledContainer = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledContent = scheme.onSurface.withValues(alpha: 0.38);
    final Color restingBorder = switch (variant) {
      OrionDropdownVariant.outline => scheme.outline,
      OrionDropdownVariant.filled => Colors.transparent,
      OrionDropdownVariant.underline => scheme.outline,
    };
    final Color fill = switch (variant) {
      OrionDropdownVariant.outline => scheme.surface,
      OrionDropdownVariant.filled => scheme.surfaceContainerHighest,
      OrionDropdownVariant.underline => Colors.transparent,
    };

    return OrionDropdownStyle(
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? (variant == OrionDropdownVariant.filled
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
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padding),
      radius: variant == OrionDropdownVariant.underline
          ? BorderRadius.zero
          : radius,
      labelGap: OrionSpacing.space8,
      captionGap: OrionSpacing.space8,
      textStyle: text,
      labelStyle: textTheme.labelMedium,
      captionStyle: textTheme.bodySmall,
      iconSize: 18,
      chevronColor: scheme.onSurfaceVariant,
      panelColor: scheme.surface,
      panelBorderColor: scheme.outlineVariant.withValues(alpha: 0.35),
      panelBorderWidth: 1,
      panelBorderRadius: BorderRadius.circular(OrionRadii.radius12),
      panelShadow: OrionThemeData.defaultShadow,
      panelPadding: const EdgeInsets.all(OrionSpacing.space8),
      panelGap: 8,
      panelMaxWidth: 320,
      panelMaxHeight: 320,
      rowMinHeight: 44,
      rowPadding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space12,
        vertical: OrionSpacing.space8,
      ),
      rowTitleStyle: const TextStyle(
        fontSize: 14.0,
        fontWeight: FontWeight.w500,
      ),
      rowDescriptionStyle: const TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w400,
      ),
      labelColor: scheme.onSurfaceVariant,
      selectedLabelColor: scheme.onSurface,
      descriptionColor: scheme.onSurfaceVariant,
      activeRowColor: scheme.onSurface.withValues(alpha: 0.06),
      activeRowRadius: BorderRadius.circular(OrionRadii.radius8),
      checkColor: scheme.primary,
      springSpec: unfoldSpring,
      separationSpringSpec: separationSpring,
      dismissSpringSpec: dismissSpring,
      highlightSpringSpec: highlightSpring,
      pressScale: 0.98,
      pressSpring: const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.85),
      releaseSpring: const OrionSpringSpec(
        stiffness: 380.0,
        dampingRatio: 0.85,
      ),
      hapticType: OrionHapticType.selectionClick,
    );
  }
}
