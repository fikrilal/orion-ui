import 'package:orion_ui/src/components/calendar/orion_calendar_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for [OrionCalendar].
///
/// This is the bottom layer of the calendar's three-layer resolution. The
/// month nudge uses a critically damped spring so the numerals do not ring.
abstract final class OrionCalendarPresets {
  /// Month travel. Stiffness 380 and damping ratio 1 match the kit's other
  /// critically damped moves.
  static const OrionSpringSpec month = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  /// Resolves the built-in geometry.
  static OrionCalendarStyle resolve() {
    return const OrionCalendarStyle(
      dayExtent: OrionSizing.controlHeightMedium,
      selectedExtent: 32,
      todayDotSize: 3,
      monthSlide: 12,
      monthExitSlide: 8,
      headerGap: OrionSpacing.space8,
      weekdayGap: OrionSpacing.space8,
      focusRingWidth: 1,
      spring: month,
    );
  }
}
