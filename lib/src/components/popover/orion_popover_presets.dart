import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/popover/orion_popover_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionPopoverStyle].
abstract final class OrionPopoverPresets {
  /// Resolves the default popover style for the active color scheme.
  static OrionPopoverStyle resolve({required ColorScheme scheme}) {
    return OrionPopoverStyle(
      backgroundColor: scheme.surface,
      borderColor: scheme.outlineVariant.withValues(alpha: 0.35),
      borderWidth: 1.0,
      borderRadius: BorderRadius.circular(OrionRadii.radius12),
      shadow: OrionThemeData.defaultShadow,
      frosted: false,
      gap: 8.0,
      padding: const EdgeInsets.all(OrionSpacing.space8),
      arrowSize: const Size(14.0, 7.0),
      showArrow: false,
      springSpec: const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.82),
      dismissSpringSpec: const OrionSpringSpec(
        stiffness: 380.0,
        dampingRatio: 1.0,
        clampOvershoot: true,
      ),
      minWidth: 140.0,
      maxWidth: 320.0,
    );
  }
}
