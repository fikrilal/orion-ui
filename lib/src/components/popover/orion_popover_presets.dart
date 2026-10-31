import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/popover/orion_popover_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The built-in defaults for [OrionPopoverStyle].
abstract final class OrionPopoverPresets {
  /// Resolves the default popover style for the active color scheme.
  static OrionPopoverStyle resolve({required ColorScheme scheme}) {
    final bool isDark = scheme.brightness == Brightness.dark;
    return OrionPopoverStyle(
      backgroundColor: scheme.surfaceContainer,
      borderColor: scheme.outlineVariant,
      borderWidth: 1.0,
      borderRadius: BorderRadius.circular(14.0),
      shadow: isDark
          ? const <BoxShadow>[
              BoxShadow(
                color: Color(0x52000000),
                blurRadius: 24.0,
                offset: Offset(0, 10),
              ),
              BoxShadow(
                color: Color(0x2E000000),
                blurRadius: 6.0,
                offset: Offset(0, 2),
              ),
            ]
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x16000000),
                blurRadius: 20.0,
                offset: Offset(0, 8),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 4.0,
                offset: Offset(0, 1),
              ),
            ],
      frosted: false,
      gap: 8.0,
      padding: const EdgeInsets.all(6.0),
      arrowSize: const Size(14.0, 7.0),
      showArrow: false,
      springSpec: const OrionSpringSpec(stiffness: 520.0, dampingRatio: 0.86),
      dismissSpringSpec: const OrionSpringSpec(
        stiffness: 620.0,
        dampingRatio: 1.0,
        clampOvershoot: true,
      ),
      minWidth: 140.0,
      maxWidth: 320.0,
    );
  }
}
