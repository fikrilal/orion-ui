import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/dialog/orion_dialog_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionDialogStyle].
abstract final class OrionDialogPresets {
  /// Default spring for modal dialog entrance.
  static const OrionSpringSpec defaultOpenSpring = OrionSpringSpec(
    stiffness: 420.0,
    dampingRatio: 0.88,
  );

  /// Default critically damped spring for modal dialog dismissal.
  static const OrionSpringSpec defaultDismissSpring = OrionSpringSpec(
    stiffness: 440.0,
    dampingRatio: 1.0,
    clampOvershoot: true,
  );

  /// Resolves the default dialog style for the active color scheme.
  static OrionDialogStyle resolve({required ColorScheme scheme}) {
    return OrionDialogStyle(
      backgroundColor: scheme.surfaceContainer,
      borderColor: scheme.outlineVariant,
      borderWidth: 1.0,
      borderRadius: BorderRadius.circular(OrionRadii.radius24),
      shadow: OrionThemeData.defaultShadow,
      frosted: false,
      barrierColor: const Color(0x73000000), // 45% black barrier scrim
      padding: const EdgeInsets.all(OrionSpacing.space24),
      maxWidth: 340.0,
      contentSpacing: 16.0,
      actionSpacing: 10.0,
      springSpec: defaultOpenSpring,
      dismissSpringSpec: defaultDismissSpring,
    );
  }
}
