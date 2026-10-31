import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/slider/orion_slider.dart';
import 'package:orion_ui/src/components/slider/orion_slider_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionSliderSize].
///
/// This is the bottom layer of the slider's three-layer resolution: the size
/// steps the thumb and the track as real geometry, the medium size reproduces
/// the shipped 20 pt thumb on a 4 pt track exactly, and the motion keeps the
/// critically damped settle and the snappy lift.
abstract final class OrionSliderPresets {
  /// Resolves the built-in style against the ambient scheme.
  static OrionSliderStyle resolve({
    required OrionSliderSize size,
    required ColorScheme scheme,
  }) {
    final (double thumb, double track) = switch (size) {
      OrionSliderSize.small => (16, 3),
      OrionSliderSize.medium => (20, OrionSpacing.space4),
      OrionSliderSize.large => (24, 6),
    };

    final Color mutedTrack = scheme.onSurface.withValues(alpha: 0.12);
    final Color mutedFill = scheme.onSurface.withValues(alpha: 0.38);

    return OrionSliderStyle(
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.disabled) ? mutedTrack : scheme.outline,
      ),
      // The filled part keeps Material's disabled active-track value: the
      // track must stay lighter than the fill, or a disabled slider reads as
      // empty whatever its value. It always composites over the track, so its
      // translucency is stable.
      fillColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.disabled) ? mutedFill : scheme.primary,
      ),
      // The thumb is opaque: a translucent one composites against the fill on
      // one side and the bare track on the other, and reads as two halves.
      thumbColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? scheme.onSurfaceVariant
            : scheme.primary,
      ),
      activeTickColor: scheme.onPrimary.withValues(alpha: 0.55),
      inactiveTickColor: scheme.onSurfaceVariant.withValues(alpha: 0.45),
      trackHeight: track,
      thumbSize: thumb,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      focusOverlayColor: scheme.onSurface.withValues(alpha: 0.12),
      hoverOverlayColor: scheme.onSurface.withValues(alpha: 0.06),
      valueIndicatorColor: scheme.onSurface,
      valueIndicatorTextColor: scheme.surface,
      settleSpring: const OrionSpringSpec(stiffness: 380, dampingRatio: 1),
      liftSpring: OrionSpringSpec.snappy,
      liftScale: 1.2,
    );
  }
}
