import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/chip/orion_chip.dart';
import 'package:orion_ui/src/components/chip/orion_chip_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionChipSize].
///
/// This is the bottom layer of the chip's three-layer resolution: the size
/// steps the pill, its typography, padding, check and gap as real geometry,
/// and the state travel rides [defaultSpring] for a crisp, settled transition.
abstract final class OrionChipPresets {
  /// Default travel spring for the 0 to 1 selection transition.
  ///
  /// Crisper than [OrionSpringSpec.gentle] while preserving a subtle (~1%)
  /// tactile pop on the checkmark without visible wobble.
  static const OrionSpringSpec defaultSpring = OrionSpringSpec(
    stiffness: 460,
    dampingRatio: 0.82,
  );

  /// Resolves the built-in style against the ambient scheme and optional
  /// [textTheme].
  static OrionChipStyle resolve({
    required OrionChipSize size,
    required ColorScheme scheme,
    TextTheme? textTheme,
  }) {
    final (
      double height,
      double padding,
      double check,
      double gap,
      TextStyle? textStyle,
    ) = switch (size) {
      OrionChipSize.small => (28.0, 10.0, 12.0, 6.0, textTheme?.labelSmall),
      OrionChipSize.medium => (
        OrionSizing.controlHeightSmall,
        OrionSpacing.space12,
        OrionSizing.iconSmall,
        OrionSpacing.space8,
        textTheme?.labelMedium,
      ),
      OrionChipSize.large => (
        OrionSizing.controlHeightMedium,
        OrionSpacing.space16,
        20.0,
        10.0,
        textTheme?.labelLarge,
      ),
    };

    final Color muted = scheme.onSurface.withValues(alpha: 0.12);
    final Color mutedLabel = scheme.onSurface.withValues(alpha: 0.38);

    return OrionChipStyle(
      fillColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return muted;
        }
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.secondary;
      }),
      borderColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return muted;
        }
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.outlineVariant;
      }),
      labelColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return mutedLabel;
        }
        return states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSecondary;
      }),
      checkColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? mutedLabel
            : scheme.onPrimary,
      ),
      textStyle: textStyle,
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padding),
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      borderWidth: 1,
      checkSize: check,
      checkGap: gap,
      focusOverlayColor: scheme.onSurface.withValues(alpha: 0.12),
      hoverOverlayColor: scheme.onSurface.withValues(alpha: 0.05),
      spring: defaultSpring,
    );
  }
}
