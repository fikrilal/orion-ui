import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/checkbox/orion_checkbox.dart';
import 'package:orion_ui/src/components/checkbox/orion_checkbox_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionCheckboxSize].
///
/// This is the bottom layer of the box's three-layer resolution: the size
/// steps the box, its radius, the mark and the indeterminate bar as real
/// geometry, the medium size reproduces the shipped 24 pt box exactly, and
/// the state travel keeps the kit's gentle spring.
abstract final class OrionCheckboxPresets {
  /// Default crisp spring for checkbox state transitions.
  static const OrionSpringSpec defaultSpring = OrionSpringSpec(
    stiffness: 520.0,
    dampingRatio: 0.80,
  );

  /// Resolves the built-in style against the ambient scheme.
  static OrionCheckboxStyle resolve({
    required OrionCheckboxSize size,
    required ColorScheme scheme,
  }) {
    final (
      double box,
      BorderRadius radius,
      double mark,
      double bar,
    ) = switch (size) {
      OrionCheckboxSize.small => (
        20,
        BorderRadius.circular(OrionRadii.radius4),
        12,
        OrionSpacing.space8,
      ),
      OrionCheckboxSize.medium => (
        OrionSizing.iconMedium,
        BorderRadius.circular(OrionRadii.radius6),
        OrionSizing.iconSmall,
        OrionSpacing.space12,
      ),
      OrionCheckboxSize.large => (
        28,
        BorderRadius.circular(OrionRadii.radius8),
        18,
        OrionSpacing.space16,
      ),
    };

    final Color muted = scheme.onSurface.withValues(alpha: 0.12);
    final Color mutedMark = scheme.onSurface.withValues(alpha: 0.38);

    return OrionCheckboxStyle(
      fillColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        final bool selected = states.contains(WidgetState.selected);
        if (!selected) {
          return Colors.transparent;
        }
        if (states.contains(WidgetState.disabled)) {
          return muted;
        }
        return states.contains(WidgetState.error)
            ? scheme.error
            : scheme.primary;
      }),
      borderColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return muted;
        }
        if (states.contains(WidgetState.error)) {
          return scheme.error;
        }
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.outline;
      }),
      markColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return mutedMark;
        }
        return states.contains(WidgetState.error)
            ? scheme.onError
            : scheme.onPrimary;
      }),
      size: box,
      radius: radius,
      borderWidth: 1.75,
      markSize: mark,
      barWidth: bar,
      barHeight: 2,
      pressedScale: 0.90,
      focusOverlayColor: scheme.onSurface.withValues(alpha: 0.12),
      spring: defaultSpring,
    );
  }
}
