import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/calendar/orion_calendar_style.dart';

/// An ambient theme extension configuring defaults for [OrionCalendar].
class OrionCalendarTheme extends ThemeExtension<OrionCalendarTheme> {
  /// Creates a theme that overrides the calendar's built-in style.
  const OrionCalendarTheme({this.defaultStyle});

  /// Default fallback theme.
  static const OrionCalendarTheme fallback = OrionCalendarTheme();

  /// Default instance style overrides applied to every calendar in the subtree.
  final OrionCalendarStyle? defaultStyle;

  @override
  OrionCalendarTheme copyWith({OrionCalendarStyle? defaultStyle}) {
    return OrionCalendarTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionCalendarTheme lerp(ThemeExtension<OrionCalendarTheme>? other, double t) {
    if (other is! OrionCalendarTheme) {
      return this;
    }
    return OrionCalendarTheme(
      defaultStyle: OrionCalendarStyle.lerp(
        defaultStyle,
        other.defaultStyle,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCalendarTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
