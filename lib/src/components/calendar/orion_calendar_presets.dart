import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/calendar/orion_calendar_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for [OrionCalendar].
///
/// This is the bottom layer of the calendar's three-layer resolution. The
/// month slide uses a crisp critically-damped spring so numerals glide cleanly
/// without ringing.
abstract final class OrionCalendarPresets {
  /// Month travel. Crisp critically-damped spring (k = 440, zeta = 1).
  static const OrionSpringSpec month = OrionSpringSpec(
    stiffness: 440,
    dampingRatio: 1,
    clampOvershoot: true,
  );

  /// Resolves the built-in geometry and color defaults.
  static OrionCalendarStyle resolve({ColorScheme? scheme}) {
    return OrionCalendarStyle(
      dayExtent: OrionSizing.minHitTarget,
      selectedExtent: 38,
      todayDotSize: 4,
      monthSlide: 36,
      monthExitSlide: 24,
      headerGap: OrionSpacing.space12,
      weekdayGap: OrionSpacing.space8,
      focusRingWidth: 1.5,
      rangeFillColor: scheme?.primary.withValues(alpha: 0.11),
      rangeTextColor: scheme?.onSurface,
      strikethroughDisabled: true,
      spring: month,
    );
  }
}
