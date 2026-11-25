import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/tooltip/orion_tooltip_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionTooltipStyle].
abstract final class OrionTooltipPresets {
  /// Resolves the default tooltip style for the active [ColorScheme] and [tone].
  static OrionTooltipStyle resolve({
    required ColorScheme scheme,
    OrionTooltipTone tone = OrionTooltipTone.inverted,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final bool isSurface = tone == OrionTooltipTone.surface;

    final Color backgroundColor = isSurface
        ? (isDark ? scheme.surfaceContainerHighest : scheme.surface)
        : scheme.inverseSurface;

    final Color foregroundColor = isSurface
        ? scheme.onSurface
        : scheme.onInverseSurface;

    final Color borderColor = isSurface ? scheme.outline : Colors.transparent;
    final double borderWidth = isSurface ? 1.0 : 0.0;

    final List<BoxShadow> shadow = isDark
        ? const <BoxShadow>[
            BoxShadow(
              color: Color(0x4D000000),
              blurRadius: 16.0,
              offset: Offset(0, 6),
            ),
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 4.0,
              offset: Offset(0, 2),
            ),
          ]
        : const <BoxShadow>[
            BoxShadow(
              color: Color(0x1C000000),
              blurRadius: 12.0,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color(0x0D000000),
              blurRadius: 2.0,
              offset: Offset(0, 1),
            ),
          ];

    return OrionTooltipStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: BorderRadius.circular(OrionRadii.radius8),
      shadow: shadow,
      frosted: false,
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 6.0),
      textStyle: TextStyle(
        fontSize: 12.0,
        fontWeight: FontWeight.w500,
        height: 1.35,
        letterSpacing: -0.1,
        color: foregroundColor,
      ),
      gap: 6.0,
      showArrow: true,
      arrowSize: const Size(10.0, 5.0),
      maxWidth: 260.0,
      springSpec: const OrionSpringSpec(stiffness: 480.0, dampingRatio: 0.85),
      dismissSpringSpec: const OrionSpringSpec(
        stiffness: 520.0,
        dampingRatio: 1.0,
        clampOvershoot: true,
      ),
    );
  }
}
