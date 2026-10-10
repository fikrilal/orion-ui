import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/wheel/orion_wheel_picker_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look and feel for the wheel.
///
/// This is the bottom layer of the wheel's three-layer resolution: the shipped
/// numbers, the two label colours at the kit's disabled alphas, and the
/// critically damped settle.
abstract final class OrionWheelPickerPresets {
  /// Resolves the built-in style against the ambient scheme and type scale.
  static OrionWheelPickerStyle resolve({
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
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
      textStyle: textTheme.bodyLarge,
      radius: BorderRadius.circular(OrionRadii.radius12),
      itemExtent: OrionSizing.minHitTarget,
      edgeScale: 0.7,
      projectionSeconds: 0.08,
      endResistance: 0.35,
      focusRingColor: scheme.onSurface,
      focusRingWidth: 2,
      settleSpring: const OrionSpringSpec(stiffness: 380, dampingRatio: 1),
    );
  }
}
