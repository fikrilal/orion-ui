import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionBottomSheetStyle].
abstract final class OrionBottomSheetPresets {
  /// Resolves the default bottom sheet style for the active color scheme.
  static OrionBottomSheetStyle resolve({required ColorScheme scheme}) {
    return OrionBottomSheetStyle(
      backgroundColor: scheme.surface,
      borderColor: scheme.outlineVariant.withValues(alpha: 0.35),
      borderWidth: 1.0,
      borderRadius: const BorderRadius.vertical(
        top: Radius.circular(OrionRadii.radius24),
      ),
      handleColor: scheme.onSurfaceVariant.withValues(alpha: 0.35),
      handleSize: const Size(36.0, 5.0),
      barrierColor: const Color(0x73000000), // 45% black scrim
      shadow: OrionThemeData.defaultShadow,
      frosted: false,
      detentSpring: OrionSpringSpec.gentle,
      dismissSpring: const OrionSpringSpec(
        stiffness: 300.0,
        dampingRatio: 1.0,
        clampOvershoot: true,
      ),
      rubberBandFactor: 0.15,
      dismissThreshold: 96.0,
    );
  }
}
