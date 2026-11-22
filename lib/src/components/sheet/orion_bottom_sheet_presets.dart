import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionBottomSheetStyle].
abstract final class OrionBottomSheetPresets {
  /// Default crisp modal spring for snapping between detents.
  static const OrionSpringSpec defaultDetentSpring = OrionSpringSpec(
    stiffness: 420.0,
    dampingRatio: 0.92,
  );

  /// Default critically-damped dismissal spring.
  static const OrionSpringSpec defaultDismissSpring = OrionSpringSpec(
    stiffness: 480.0,
    dampingRatio: 1.0,
    clampOvershoot: true,
  );

  /// Resolves the default bottom sheet style for the active color scheme and [variant].
  static OrionBottomSheetStyle resolve({
    required ColorScheme scheme,
    OrionBottomSheetVariant variant = OrionBottomSheetVariant.edgeToEdge,
  }) {
    final BorderRadius borderRadius = switch (variant) {
      OrionBottomSheetVariant.edgeToEdge => const BorderRadius.vertical(
        top: Radius.circular(OrionRadii.radius24),
      ),
      OrionBottomSheetVariant.floating => BorderRadius.circular(
        OrionRadii.radius24,
      ),
    };

    return OrionBottomSheetStyle(
      backgroundColor: scheme.surface,
      borderWidth: 0.0,
      borderRadius: borderRadius,
      floatingMargin: const EdgeInsets.fromLTRB(
        OrionSpacing.space16,
        0,
        OrionSpacing.space16,
        OrionSpacing.space16,
      ),
      handleColor: scheme.onSurfaceVariant.withValues(alpha: 0.35),
      handleSize: const Size(36.0, 5.0),
      barrierColor: const Color(0x73000000), // 45% black scrim
      shadow: OrionThemeData.defaultShadow,
      frosted: false,
      detentSpring: defaultDetentSpring,
      dismissSpring: defaultDismissSpring,
      rubberBandFactor: 0.15,
      dismissThreshold: 96.0,
    );
  }
}
