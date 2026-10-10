import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/chip/orion_chip.dart';
import 'package:orion_ui/src/components/chip/orion_chip_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionChipSize].
///
/// This is the bottom layer of the chip's three-layer resolution: the size
/// steps the pill, its padding, the check and the gap as real geometry, the
/// medium size reproduces the shipped 32 pt pill exactly, and the state travel
/// keeps the kit's gentle spring.
abstract final class OrionChipPresets {
  /// Resolves the built-in style against the ambient scheme.
  static OrionChipStyle resolve({
    required OrionChipSize size,
    required ColorScheme scheme,
  }) {
    final (
      double height,
      double padding,
      double check,
      double gap,
    ) = switch (size) {
      OrionChipSize.small => (28, 10, 12, 6),
      OrionChipSize.medium => (
        OrionSizing.controlHeightSmall,
        OrionSpacing.space12,
        OrionSizing.iconSmall,
        OrionSpacing.space8,
      ),
      OrionChipSize.large => (
        OrionSizing.controlHeightMedium,
        OrionSpacing.space16,
        20,
        10,
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
            : scheme.outline;
      }),
      labelColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return mutedLabel;
        }
        return states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurfaceVariant;
      }),
      checkColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? mutedLabel
            : scheme.onPrimary,
      ),
      height: height,
      padding: EdgeInsets.symmetric(horizontal: padding),
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      borderWidth: 1,
      checkSize: check,
      checkGap: gap,
      focusOverlayColor: scheme.onSurface.withValues(alpha: 0.12),
      spring: OrionSpringSpec.gentle,
    );
  }
}
