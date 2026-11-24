import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/tabs/orion_tabs_style.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Built-in defaults and preset resolutions for [OrionTabsStyle].
abstract final class OrionTabsPresets {
  /// Default spring specification for indicator travel ($k = 340.0, \zeta = 0.92$).
  static const OrionSpringSpec defaultSpringSpec = OrionSpringSpec(
    stiffness: 340.0,
    dampingRatio: 0.92,
    clampOvershoot: true,
  );

  /// Resolves the default tab bar styling for the active [ColorScheme] and [variant].
  static OrionTabsStyle resolve({
    required ColorScheme scheme,
    OrionTabsVariant variant = OrionTabsVariant.underline,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color hoverSurface = scheme.onSurface.withValues(
      alpha: isDark ? 0.06 : 0.04,
    );
    final Color hoverLabel = Color.lerp(
      scheme.onSurfaceVariant,
      scheme.onSurface,
      0.55,
    )!;

    switch (variant) {
      case OrionTabsVariant.underline:
        return OrionTabsStyle(
          indicatorColor: scheme.primary,
          indicatorHeight: 2.5,
          indicatorRadius: const BorderRadius.vertical(
            top: Radius.circular(OrionRadii.radiusPill),
          ),
          dividerColor: scheme.outlineVariant,
          dividerThickness: 1.0,
          trackColor: Colors.transparent,
          activeLabelColor: scheme.primary,
          inactiveLabelColor: scheme.onSurfaceVariant,
          hoverLabelColor: hoverLabel,
          hoverColor: hoverSurface,
          disabledLabelColor: scheme.onSurface.withValues(alpha: 0.38),
          labelStyle: const TextStyle(
            fontSize: 14.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          tabPadding: const EdgeInsets.symmetric(
            horizontal: OrionSpacing.space16,
            vertical: OrionSpacing.space12,
          ),
          trackPadding: EdgeInsets.zero,
          tabSpacing: OrionSpacing.space4,
          edgeFadeWidth: 28.0,
          springSpec: defaultSpringSpec,
          pressedScale: 0.98,
          pressSpring: const OrionSpringSpec(
            stiffness: 420.0,
            dampingRatio: 0.85,
          ),
          releaseSpring: const OrionSpringSpec(
            stiffness: 380.0,
            dampingRatio: 0.85,
          ),
          hapticType: OrionHapticType.selectionClick,
          focusRingColor: scheme.primary.withValues(alpha: 0.5),
          iconSize: 18.0,
        );

      case OrionTabsVariant.pill:
        return OrionTabsStyle(
          indicatorColor: scheme.primary,
          indicatorRadius: BorderRadius.circular(OrionRadii.radiusPill),
          dividerColor: Colors.transparent,
          dividerThickness: 0.0,
          trackColor: Colors.transparent,
          activeLabelColor: scheme.onPrimary,
          inactiveLabelColor: scheme.onSurfaceVariant,
          hoverLabelColor: hoverLabel,
          hoverColor: hoverSurface,
          disabledLabelColor: scheme.onSurface.withValues(alpha: 0.38),
          labelStyle: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.1,
          ),
          tabPadding: const EdgeInsets.symmetric(
            horizontal: OrionSpacing.space16,
            vertical: OrionSpacing.space8,
          ),
          trackPadding: EdgeInsets.zero,
          tabSpacing: 6.0,
          edgeFadeWidth: 28.0,
          springSpec: defaultSpringSpec,
          pressedScale: 0.98,
          pressSpring: const OrionSpringSpec(
            stiffness: 420.0,
            dampingRatio: 0.85,
          ),
          releaseSpring: const OrionSpringSpec(
            stiffness: 380.0,
            dampingRatio: 0.85,
          ),
          hapticType: OrionHapticType.selectionClick,
          focusRingColor: scheme.primary.withValues(alpha: 0.5),
          iconSize: 18.0,
        );
    }
  }
}
