import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/radio/orion_radio.dart';
import 'package:orion_ui/src/components/radio/orion_radio_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionRadioSize].
///
/// This is the bottom layer of the circle's three-layer resolution: the size
/// steps the circle and the dot as real geometry, the medium size reproduces
/// the shipped 24 pt circle exactly, and the selection travel keeps the kit's
/// gentle spring.
abstract final class OrionRadioPresets {
  /// Resolves the built-in style against the ambient scheme.
  static OrionRadioStyle resolve({
    required OrionRadioSize size,
    required ColorScheme scheme,
  }) {
    final (double circle, double dot) = switch (size) {
      OrionRadioSize.small => (20, 7),
      OrionRadioSize.medium => (
        OrionSizing.iconMedium,
        OrionSizing.iconSmall * 0.5,
      ),
      OrionRadioSize.large => (28, 10),
    };

    final Color muted = scheme.onSurface.withValues(alpha: 0.12);
    final Color mutedDot = scheme.onSurface.withValues(alpha: 0.38);

    return OrionRadioStyle(
      ringColor: WidgetStateProperty.resolveWith<Color?>((
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
      dotColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return mutedDot;
        }
        return states.contains(WidgetState.error)
            ? scheme.error
            : scheme.primary;
      }),
      fillColor: WidgetStatePropertyAll<Color?>(Colors.transparent),
      size: circle,
      dotSize: dot,
      borderWidth: 2,
      focusOverlayColor: scheme.onSurface.withValues(alpha: 0.12),
      spring: OrionSpringSpec.gentle,
    );
  }
}
