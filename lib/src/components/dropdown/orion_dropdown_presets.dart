import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/dropdown/orion_dropdown_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look and motion for every [OrionDropdownVariant] and
/// [OrionDropdownSize].
///
/// The closed trigger mirrors `OrionTextFieldPresets` so dropdowns and text
/// fields align seamlessly in forms, while the floating panel elevates onto
/// `ColorScheme.surfaceContainer` with crisp `outlineVariant` borders in both
/// light and dark themes.
abstract final class OrionDropdownPresets {
  /// Default spring governing popover panel entrance.
  static const OrionSpringSpec openSpring = OrionSpringSpec(
    stiffness: 440.0,
    dampingRatio: 0.88,
    clampOvershoot: true,
  );

  /// Compatibility alias for [openSpring].
  static const OrionSpringSpec unfoldSpring = openSpring;

  /// Legacy compatibility spring.
  static const OrionSpringSpec separationSpring = OrionSpringSpec(
    stiffness: 460.0,
    dampingRatio: 0.70,
  );

  /// Critically damped spring governing dismissal with zero rebound.
  static const OrionSpringSpec dismissSpring = OrionSpringSpec(
    stiffness: 420.0,
    dampingRatio: 1.0,
    clampOvershoot: true,
  );

  /// Spring governing the gliding highlight as the active option moves.
  static const OrionSpringSpec highlightSpring = OrionSpringSpec(
    stiffness: 520.0,
    dampingRatio: 0.88,
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
        40.0,
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
        56.0,
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
      hoverFillColor: scheme.onSurface.withValues(alpha: 0.03),
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
      borderWidth: 1.0,
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
      iconSize: 18.0,
      chevronColor: scheme.onSurfaceVariant,
      panelColor: scheme.surfaceContainer,
      panelBorderColor: scheme.outlineVariant,
      panelBorderWidth: 1.0,
      panelBorderRadius: BorderRadius.circular(OrionRadii.radius12),
      panelShadow: OrionThemeData.defaultShadow,
      panelPadding: const EdgeInsets.all(OrionSpacing.space8),
      panelGap: 6.0,
      panelMaxWidth: null,
      panelMaxHeight: 320.0,
      rowMinHeight: 44.0,
      rowPadding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space12,
        vertical: OrionSpacing.space8,
      ),
      rowTitleStyle:
          (textTheme.bodyMedium ?? const TextStyle(fontSize: 14.0)).copyWith(
            fontWeight: FontWeight.w500,
          ),
      rowDescriptionStyle:
          (textTheme.bodySmall ?? const TextStyle(fontSize: 12.0)).copyWith(
            fontWeight: FontWeight.w400,
          ),
      groupHeaderStyle:
          (textTheme.labelSmall ?? const TextStyle(fontSize: 11.0)).copyWith(
            fontWeight: FontWeight.w600,
            letterSpacing: 0.4,
            color: scheme.onSurfaceVariant,
          ),
      labelColor: scheme.onSurface,
      selectedLabelColor: scheme.onSurface,
      descriptionColor: scheme.onSurfaceVariant,
      activeRowColor: scheme.onSurface.withValues(alpha: 0.06),
      selectedRowColor: scheme.primary.withValues(alpha: 0.07),
      activeRowRadius: BorderRadius.circular(OrionRadii.radius8),
      checkColor: scheme.primary,
      springSpec: openSpring,
      separationSpringSpec: separationSpring,
      dismissSpringSpec: dismissSpring,
      highlightSpringSpec: highlightSpring,
      pressScale: 0.99,
      pressSpring: const OrionSpringSpec(stiffness: 460.0, dampingRatio: 0.88),
      releaseSpring: const OrionSpringSpec(
        stiffness: 420.0,
        dampingRatio: 0.88,
      ),
    );
  }
}
