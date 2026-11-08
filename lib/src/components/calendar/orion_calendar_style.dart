import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Geometry and month motion for [OrionCalendar].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in presets, the ambient theme, and the instance style. Every field
/// is nullable; a null field falls through, so an override changes only what
/// it names. Paint comes from the [ColorScheme], not from this style.
@immutable
class OrionCalendarStyle {
  /// Creates a style, leaving every unnamed field to the layer below.
  const OrionCalendarStyle({
    this.dayExtent,
    this.selectedExtent,
    this.todayDotSize,
    this.monthSlide,
    this.monthExitSlide,
    this.headerGap,
    this.weekdayGap,
    this.focusRingWidth,
    this.spring,
  });

  /// Height of one day row.
  final double? dayExtent;

  /// Diameter of the selected-day circle.
  final double? selectedExtent;

  /// Diameter of the today dot.
  final double? todayDotSize;

  /// How far the incoming month starts from rest, in logical pixels.
  final double? monthSlide;

  /// How far the outgoing month travels as it leaves.
  final double? monthExitSlide;

  /// Gap under the month header.
  final double? headerGap;

  /// Gap under the weekday captions.
  final double? weekdayGap;

  /// Width of the keyboard cursor ring.
  final double? focusRingWidth;

  /// Spring that carries a month change. The travel is the whole nudge, so
  /// the preset is critically damped.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionCalendarStyle copyWith({
    double? dayExtent,
    double? selectedExtent,
    double? todayDotSize,
    double? monthSlide,
    double? monthExitSlide,
    double? headerGap,
    double? weekdayGap,
    double? focusRingWidth,
    OrionSpringSpec? spring,
  }) {
    return OrionCalendarStyle(
      dayExtent: dayExtent ?? this.dayExtent,
      selectedExtent: selectedExtent ?? this.selectedExtent,
      todayDotSize: todayDotSize ?? this.todayDotSize,
      monthSlide: monthSlide ?? this.monthSlide,
      monthExitSlide: monthExitSlide ?? this.monthExitSlide,
      headerGap: headerGap ?? this.headerGap,
      weekdayGap: weekdayGap ?? this.weekdayGap,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      spring: spring ?? this.spring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionCalendarStyle merge(OrionCalendarStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionCalendarStyle(
      dayExtent: other.dayExtent ?? dayExtent,
      selectedExtent: other.selectedExtent ?? selectedExtent,
      todayDotSize: other.todayDotSize ?? todayDotSize,
      monthSlide: other.monthSlide ?? monthSlide,
      monthExitSlide: other.monthExitSlide ?? monthExitSlide,
      headerGap: other.headerGap ?? headerGap,
      weekdayGap: other.weekdayGap ?? weekdayGap,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      spring: other.spring ?? spring,
    );
  }

  /// Linearly interpolates between two styles.
  static OrionCalendarStyle? lerp(
    OrionCalendarStyle? a,
    OrionCalendarStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null) {
      return b;
    }
    if (b == null) {
      return a;
    }
    return OrionCalendarStyle(
      dayExtent: lerpDouble(a.dayExtent, b.dayExtent, t),
      selectedExtent: lerpDouble(a.selectedExtent, b.selectedExtent, t),
      todayDotSize: lerpDouble(a.todayDotSize, b.todayDotSize, t),
      monthSlide: lerpDouble(a.monthSlide, b.monthSlide, t),
      monthExitSlide: lerpDouble(a.monthExitSlide, b.monthExitSlide, t),
      headerGap: lerpDouble(a.headerGap, b.headerGap, t),
      weekdayGap: lerpDouble(a.weekdayGap, b.weekdayGap, t),
      focusRingWidth: lerpDouble(a.focusRingWidth, b.focusRingWidth, t),
      spring: t < 0.5 ? a.spring : b.spring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCalendarStyle &&
        other.dayExtent == dayExtent &&
        other.selectedExtent == selectedExtent &&
        other.todayDotSize == todayDotSize &&
        other.monthSlide == monthSlide &&
        other.monthExitSlide == monthExitSlide &&
        other.headerGap == headerGap &&
        other.weekdayGap == weekdayGap &&
        other.focusRingWidth == focusRingWidth &&
        other.spring == spring;
  }

  @override
  int get hashCode => Object.hash(
    dayExtent,
    selectedExtent,
    todayDotSize,
    monthSlide,
    monthExitSlide,
    headerGap,
    weekdayGap,
    focusRingWidth,
    spring,
  );
}
