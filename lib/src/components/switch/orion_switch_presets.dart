import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/switch/orion_switch_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Built-in presets for every [OrionSwitchSize].
///
/// This is the bottom layer of the switch's three-layer resolution:
/// [OrionSwitchPresets] -> `OrionSwitchTheme` -> instance [OrionSwitchStyle].
abstract final class OrionSwitchPresets {
  /// Default spring driving thumb slide transitions.
  static const OrionSpringSpec defaultSlideSpring = OrionSpringSpec.gentle;

  /// Default spring driving thumb press capsule elongation.
  static const OrionSpringSpec defaultPressSpring = OrionSpringSpec.snappy;

  /// Default subtle thumb elevation shadow for enabled switches.
  static const List<BoxShadow> defaultThumbShadow = <BoxShadow>[
    BoxShadow(color: Color(0x24000000), blurRadius: 4.0, offset: Offset(0, 1)),
    BoxShadow(
      color: Color(0x12000000),
      blurRadius: 1.0,
      offset: Offset(0, 0.5),
    ),
  ];

  /// Resolves the built-in [OrionSwitchStyle] for [size] and [scheme].
  static OrionSwitchStyle resolve({
    OrionSwitchSize size = OrionSwitchSize.medium,
    required ColorScheme scheme,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final (
      double trackWidth,
      double trackHeight,
      double inset,
      double iconSize,
    ) = switch (size) {
      OrionSwitchSize.small => (40.0, 24.0, 3.0, 11.0),
      OrionSwitchSize.medium => (
        52.0,
        OrionSizing.controlHeightSmall,
        OrionSpacing.space4,
        14.0,
      ),
      OrionSwitchSize.large => (64.0, 38.0, 4.0, 17.0),
    };

    final Color disabledTrackOff = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledTrackOn = scheme.primary.withValues(alpha: 0.38);
    final Color disabledThumb = isDark
        ? scheme.onSurface.withValues(alpha: 0.38)
        : scheme.surface.withValues(alpha: 0.72);
    final Color hoverTrackOff = Color.lerp(
      scheme.outline,
      scheme.onSurface,
      isDark ? 0.14 : 0.10,
    )!;
    final Color hoverTrackOn = Color.lerp(
      scheme.primary,
      isDark ? Colors.white : scheme.surface,
      0.10,
    )!;

    return OrionSwitchStyle(
      trackColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        final bool selected = states.contains(WidgetState.selected);
        final bool disabled = states.contains(WidgetState.disabled);
        final bool hovered = states.contains(WidgetState.hovered);
        if (selected) {
          if (disabled) return disabledTrackOn;
          return hovered ? hoverTrackOn : scheme.primary;
        }
        if (disabled) return disabledTrackOff;
        return hovered ? hoverTrackOff : scheme.outline;
      }),
      thumbColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return disabledThumb;
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.onPrimary;
        }
        // Keep the off-state thumb bright white in light mode (instead of
        // inverting to black onSurface) so it contrasts cleanly against the
        // track at rest AND never vanishes into a 50% gray midpoint mid-slide.
        return isDark ? scheme.onSurface : scheme.surface;
      }),
      trackBorderColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected) ||
            states.contains(WidgetState.disabled)) {
          return Colors.transparent;
        }
        return scheme.onSurface.withValues(alpha: isDark ? 0.14 : 0.08);
      }),
      trackBorderWidth: 1.0,
      thumbShadow: defaultThumbShadow,
      focusRingColor: scheme.primary.withValues(alpha: 0.45),
      activeIconColor: scheme.primary,
      inactiveIconColor: isDark ? scheme.surface : scheme.onSurfaceVariant,
      iconSize: iconSize,
      trackWidth: trackWidth,
      trackHeight: trackHeight,
      inset: inset,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      pressStretch: 0.18,
      pressSquish: 0.12,
      slideSpring: defaultSlideSpring,
      pressSpring: defaultPressSpring,
    );
  }
}
