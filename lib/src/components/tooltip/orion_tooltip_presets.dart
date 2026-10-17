import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/tooltip/orion_tooltip_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionTooltipStyle].
abstract final class OrionTooltipPresets {
  /// Resolves the default tooltip style for the active color scheme.
  static OrionTooltipStyle resolve({required ColorScheme scheme}) {
    return OrionTooltipStyle(
      backgroundColor: scheme.inverseSurface,
      borderRadius: BorderRadius.circular(OrionRadii.radius8),
      shadow: OrionThemeData.defaultShadow,
      frosted: false,
      padding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space12,
        vertical: OrionSpacing.space4,
      ),
      textStyle: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        letterSpacing: -0.1,
        color: scheme.onInverseSurface,
      ),
      gap: 6.0,
      showArrow: true,
      arrowSize: const Size(10.0, 5.0),
      maxWidth: 260.0,
      springSpec: const OrionSpringSpec(stiffness: 480.0, dampingRatio: 0.85),
      dismissSpringSpec: const OrionSpringSpec(
        stiffness: 420.0,
        dampingRatio: 1.0,
        clampOvershoot: true,
      ),
    );
  }
}
