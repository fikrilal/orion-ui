import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/toast/orion_toast_data.dart';
import 'package:orion_ui/src/components/toast/orion_toast_style.dart';
import 'package:orion_ui/src/components/toast/orion_toast_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in defaults for [OrionToastStyle].
abstract final class OrionToastPresets {
  /// Default spring governing card entrance and anchor-edge exit motion.
  static const OrionSpringSpec defaultMountSpring = OrionSpringSpec(
    stiffness: 380.0,
    dampingRatio: 0.85,
  );

  /// Default spring governing stack depth, expand, and collapse motion.
  static const OrionSpringSpec defaultStackSpring = OrionSpringSpec(
    stiffness: 380.0,
    dampingRatio: 0.95,
  );

  /// Default spring governing swipe-to-dismiss glide and snap-back.
  static const OrionSpringSpec defaultSwipeSpring = OrionSpringSpec.gentle;

  /// Elevated shadow recipe tuned for light mode.
  static const List<BoxShadow> lightShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 20.0, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 6.0, offset: Offset(0, 2)),
  ];

  /// Deeper elevation shadow recipe tuned for dark mode.
  static const List<BoxShadow> darkShadow = <BoxShadow>[
    BoxShadow(color: Color(0x73000000), blurRadius: 24.0, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x47000000), blurRadius: 8.0, offset: Offset(0, 2)),
  ];

  /// Resolves the effective style of a toast through all four layers:
  /// built-in defaults for [status], ambient [OrionToastTheme], host
  /// [stackStyle], and per-toast [instanceStyle].
  static OrionToastStyle resolveFor(
    ThemeData theme, {
    required OrionToastStatus status,
    bool richColors = false,
    OrionToastStyle? stackStyle,
    OrionToastStyle? instanceStyle,
  }) {
    final OrionToastTheme toastTheme =
        theme.extension<OrionToastTheme>() ?? OrionToastTheme.fallback;
    final bool effectiveRich =
        instanceStyle?.richColors ??
        stackStyle?.richColors ??
        toastTheme.defaultStyle?.richColors ??
        richColors;

    return resolve(
      scheme: theme.colorScheme,
      textTheme: theme.textTheme,
      status: status,
      richColors: effectiveRich,
    ).merge(toastTheme.defaultStyle).merge(stackStyle).merge(instanceStyle);
  }

  /// Resolves the default toast style for the active scheme and status.
  static OrionToastStyle resolve({
    required ColorScheme scheme,
    required TextTheme textTheme,
    OrionToastStatus status = OrionToastStatus.neutral,
    bool richColors = false,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color iconColor = switch (status) {
      OrionToastStatus.neutral => scheme.onSurfaceVariant,
      OrionToastStatus.info =>
        isDark ? const Color(0xFF60A5FA) : const Color(0xFF2563EB),
      OrionToastStatus.success =>
        isDark ? const Color(0xFF4ADE80) : const Color(0xFF16A34A),
      OrionToastStatus.warning =>
        isDark ? const Color(0xFFFBBF24) : const Color(0xFFD97706),
      OrionToastStatus.error => scheme.error,
      OrionToastStatus.loading => scheme.primary,
    };

    // Elevate dark cards onto surfaceContainerHigh with a crisp translucent
    // white border so toasts clearly lift off pure dark scaffolds.
    final Color baseSurface = isDark
        ? scheme.surfaceContainerHigh
        : scheme.surface;
    final Color baseBorder = isDark
        ? const Color(0x26FFFFFF)
        : scheme.outlineVariant;

    final bool tintableStatus =
        status == OrionToastStatus.info ||
        status == OrionToastStatus.success ||
        status == OrionToastStatus.warning ||
        status == OrionToastStatus.error;

    final Color bg = richColors && tintableStatus
        ? Color.lerp(baseSurface, iconColor, isDark ? 0.14 : 0.08)!
        : baseSurface;
    final Color border = richColors && tintableStatus
        ? iconColor.withValues(alpha: isDark ? 0.35 : 0.28)
        : baseBorder;

    return OrionToastStyle(
      backgroundColor: bg,
      borderColor: border,
      borderWidth: 1.0,
      borderRadius: BorderRadius.circular(OrionRadii.radius16),
      padding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space16,
        vertical: OrionSpacing.space12,
      ),
      maxWidth: 380.0,
      titleStyle: (textTheme.bodyMedium ?? const TextStyle()).copyWith(
        fontSize: 13.5,
        height: 1.3,
        fontWeight: FontWeight.w600,
        color: scheme.onSurface,
      ),
      descriptionStyle: (textTheme.bodySmall ?? const TextStyle()).copyWith(
        fontSize: 12.5,
        height: 1.35,
        color: scheme.onSurfaceVariant,
      ),
      iconColor: iconColor,
      iconBackgroundColor: iconColor.withValues(alpha: isDark ? 0.16 : 0.10),
      closeButtonColor: scheme.onSurfaceVariant.withValues(alpha: 0.72),
      progressBarColor: status == OrionToastStatus.neutral
          ? scheme.primary
          : iconColor,
      frosted: false,
      richColors: richColors,
      shadow: isDark ? darkShadow : lightShadow,
      mountSpring: defaultMountSpring,
      stackSpring: defaultStackSpring,
      swipeSpring: defaultSwipeSpring,
    );
  }
}
