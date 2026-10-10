import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/toast/orion_toast_data.dart';
import 'package:orion_ui/src/components/toast/orion_toast_style.dart';
import 'package:orion_ui/src/components/toast/orion_toast_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionToastStyle].
abstract final class OrionToastPresets {
  /// Resolves the effective style of a toast through all four layers: the
  /// built-in defaults for [status], the ambient [OrionToastTheme], the style
  /// the host stack was given, and the instance style, each overriding the last.
  ///
  /// Includes the motion specs, so a stack that resolves its own springs and a
  /// card that resolves its surface agree on every value.
  static OrionToastStyle resolveFor(
    ThemeData theme, {
    required OrionToastStatus status,
    OrionToastStyle? stackStyle,
    OrionToastStyle? instanceStyle,
  }) {
    final OrionToastTheme toastTheme =
        theme.extension<OrionToastTheme>() ?? OrionToastTheme.fallback;
    return resolve(
      scheme: theme.colorScheme,
      textTheme: theme.textTheme,
      status: status,
    ).merge(toastTheme.defaultStyle).merge(stackStyle).merge(instanceStyle);
  }

  /// Resolves the default toast style for the active scheme and status.
  static OrionToastStyle resolve({
    required ColorScheme scheme,
    required TextTheme textTheme,
    OrionToastStatus status = OrionToastStatus.neutral,
  }) {
    final Color iconColor = switch (status) {
      OrionToastStatus.neutral => scheme.onSurfaceVariant,
      OrionToastStatus.info => scheme.primary,
      OrionToastStatus.success => const Color(0xFF16A34A),
      OrionToastStatus.warning => const Color(0xFFF59E0B),
      OrionToastStatus.error => scheme.error,
      OrionToastStatus.loading => scheme.primary,
    };

    return OrionToastStyle(
      backgroundColor: scheme.surface,
      borderColor: scheme.outlineVariant.withValues(alpha: 0.35),
      borderWidth: 1.0,
      borderRadius: BorderRadius.circular(OrionRadii.radius16),
      titleStyle: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      descriptionStyle: (textTheme.bodySmall ?? const TextStyle()).copyWith(
        color: scheme.onSurfaceVariant,
        height: 1.35,
      ),
      iconColor: iconColor,
      closeButtonColor: scheme.onSurfaceVariant.withValues(alpha: 0.60),
      frosted: false,
      shadow: OrionThemeData.defaultShadow,
      mountSpring: const OrionSpringSpec(stiffness: 380, dampingRatio: 0.85),
      stackSpring: const OrionSpringSpec(stiffness: 380, dampingRatio: 0.95),
      swipeSpring: OrionSpringSpec.gentle,
    );
  }
}
