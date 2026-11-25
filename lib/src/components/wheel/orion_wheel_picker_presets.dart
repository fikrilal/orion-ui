import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/wheel/orion_wheel_picker_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look and feel for the wheel.
///
/// Matches iOS `CupertinoPicker` cylindrical geometry (`diameterRatio: 1.07`,
/// `perspective: 0.003`, `squeeze: 1.25`) paired with a translucent centre
/// selection loupe, tabular typography, and critically damped spring settle.
abstract final class OrionWheelPickerPresets {
  /// Resolves the built-in style against the ambient scheme and type scale.
  static OrionWheelPickerStyle resolve({
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final TextStyle baseTextStyle = (textTheme.bodyLarge ?? const TextStyle())
        .copyWith(
          fontSize: 15.0,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.1,
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        );

    return OrionWheelPickerStyle(
      selectedColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? scheme.onSurface.withValues(alpha: 0.38)
            : scheme.onSurface,
      ),
      idleColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? scheme.onSurface.withValues(alpha: 0.38)
            : scheme.onSurfaceVariant,
      ),
      textStyle: baseTextStyle,
      selectedTextStyle: const TextStyle(fontWeight: FontWeight.w600),
      selectionStyle: OrionWheelSelectionStyle.pill,
      selectionColor: scheme.onSurface.withValues(alpha: isDark ? 0.11 : 0.07),
      selectionBorderColor: scheme.onSurface.withValues(
        alpha: isDark ? 0.14 : 0.10,
      ),
      selectionRadius: BorderRadius.circular(OrionRadii.radius8),
      radius: BorderRadius.circular(OrionRadii.radius12),
      itemExtent: OrionSizing.minHitTarget,
      edgeScale: 0.7,
      diameterRatio: 1.07,
      perspective: 0.003,
      squeeze: 1.25,
      offAxisFraction: 0.0,
      edgeFade: true,
      horizontalPadding: OrionSpacing.space12,
      projectionSeconds: 0.08,
      endResistance: 0.35,
      focusRingColor: scheme.onSurface,
      focusRingWidth: 2,
      settleSpring: const OrionSpringSpec(stiffness: 380, dampingRatio: 1),
    );
  }
}
