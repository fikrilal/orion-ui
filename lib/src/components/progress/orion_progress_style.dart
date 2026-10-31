import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Semantic colour tone for progress indicators.
enum OrionProgressTone {
  /// Default neutral/primary accent (`scheme.primary`).
  primary,

  /// Positive completion tone (semantic green).
  success,

  /// Cautionary progress tone (semantic amber).
  warning,

  /// Failure or stalled progress tone (`scheme.error`).
  error,
}

/// The overridable contract shared by the progress family
/// (`OrionLinearProgress`, `OrionSegmentedProgress`, and
/// `OrionCircularProgress`).
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in [defaults], the theme's `OrionProgressTheme`, and the instance
/// style passed to the widget. Every field is nullable; a null field falls
/// through to the layer beneath it, so an override changes exactly what it
/// names.
///
/// [gap] applies to the segmented bar, [bufferColor] applies to the linear bar,
/// and [size]/[strokeWidth]/[strokeCap] apply to the circular indicator; the
/// rest are shared across the family.
@immutable
class OrionProgressStyle {
  const OrionProgressStyle({
    this.trackColor,
    this.fillColor,
    this.bufferColor,
    this.height,
    this.gap,
    this.radius,
    this.size,
    this.strokeWidth,
    this.strokeCap,
    this.spring,
  });

  /// The empty track behind the fill.
  final Color? trackColor;

  /// The determinate fill, and the sweeping fill while indeterminate.
  final Color? fillColor;

  /// The buffered (cached) layer between track and fill, painted by the
  /// linear bar from its `bufferedValue`.
  final Color? bufferColor;

  /// Bar height (linear and segmented bars).
  final double? height;

  /// Space between segments (segmented bar).
  final double? gap;

  /// Corner radius of the track and its fills (linear and segmented bars).
  final BorderRadius? radius;

  /// Outer diameter of a circular progress ring.
  final double? size;

  /// Ring thickness of a circular progress ring.
  final double? strokeWidth;

  /// Cap shape at the ends of a circular progress arc.
  final StrokeCap? strokeCap;

  /// Settle spec for determinate value changes. Indeterminate sweeps run on
  /// their own continuous clocks; a progress fill that must reach its target
  /// and stay there settles critically damped by default.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionProgressStyle copyWith({
    Color? trackColor,
    Color? fillColor,
    Color? bufferColor,
    double? height,
    double? gap,
    BorderRadius? radius,
    double? size,
    double? strokeWidth,
    StrokeCap? strokeCap,
    OrionSpringSpec? spring,
  }) {
    return OrionProgressStyle(
      trackColor: trackColor ?? this.trackColor,
      fillColor: fillColor ?? this.fillColor,
      bufferColor: bufferColor ?? this.bufferColor,
      height: height ?? this.height,
      gap: gap ?? this.gap,
      radius: radius ?? this.radius,
      size: size ?? this.size,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      strokeCap: strokeCap ?? this.strokeCap,
      spring: spring ?? this.spring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionProgressStyle merge(OrionProgressStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionProgressStyle(
      trackColor: other.trackColor ?? trackColor,
      fillColor: other.fillColor ?? fillColor,
      bufferColor: other.bufferColor ?? bufferColor,
      height: other.height ?? height,
      gap: other.gap ?? gap,
      radius: other.radius ?? radius,
      size: other.size ?? size,
      strokeWidth: other.strokeWidth ?? strokeWidth,
      strokeCap: other.strokeCap ?? strokeCap,
      spring: other.spring ?? spring,
    );
  }

  /// Linearly interpolates between two [OrionProgressStyle]s.
  static OrionProgressStyle? lerp(
    OrionProgressStyle? a,
    OrionProgressStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null) return b;
    if (b == null) return a;
    return OrionProgressStyle(
      trackColor: Color.lerp(a.trackColor, b.trackColor, t),
      fillColor: Color.lerp(a.fillColor, b.fillColor, t),
      bufferColor: Color.lerp(a.bufferColor, b.bufferColor, t),
      height: lerpDouble(a.height, b.height, t),
      gap: lerpDouble(a.gap, b.gap, t),
      radius: BorderRadius.lerp(a.radius, b.radius, t),
      size: lerpDouble(a.size, b.size, t),
      strokeWidth: lerpDouble(a.strokeWidth, b.strokeWidth, t),
      strokeCap: t < 0.5 ? a.strokeCap : b.strokeCap,
      spring: t < 0.5 ? a.spring : b.spring,
    );
  }

  /// Builds a style from plain values.
  static OrionProgressStyle from({
    Color? trackColor,
    Color? fillColor,
    Color? bufferColor,
    double? height,
    double? gap,
    BorderRadius? radius,
    double? size,
    double? strokeWidth,
    StrokeCap? strokeCap,
    OrionSpringSpec? spring,
  }) {
    return OrionProgressStyle(
      trackColor: trackColor,
      fillColor: fillColor,
      bufferColor: bufferColor,
      height: height,
      gap: gap,
      radius: radius,
      size: size,
      strokeWidth: strokeWidth,
      strokeCap: strokeCap,
      spring: spring,
    );
  }

  /// Resolves the semantic fill colour for a given [tone] and [scheme].
  static Color resolveToneColor({
    required ColorScheme scheme,
    required OrionProgressTone tone,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    return switch (tone) {
      OrionProgressTone.primary => scheme.primary,
      OrionProgressTone.success =>
        isDark ? const Color(0xFF22C55E) : const Color(0xFF16A34A),
      OrionProgressTone.warning =>
        isDark ? const Color(0xFFF59E0B) : const Color(0xFFD97706),
      OrionProgressTone.error => scheme.error,
    };
  }

  /// The built-in look, with [height] and [tone] supplied by the component
  /// that resolves it.
  static OrionProgressStyle defaults({
    required ColorScheme scheme,
    required double height,
    OrionProgressTone tone = OrionProgressTone.primary,
    double size = 40.0,
    double strokeWidth = 4.0,
  }) {
    final Color fill = resolveToneColor(scheme: scheme, tone: tone);
    return OrionProgressStyle(
      trackColor: scheme.secondary,
      fillColor: fill,
      bufferColor: fill.withValues(alpha: 0.24),
      height: height,
      gap: OrionSpacing.space4,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      size: size,
      strokeWidth: strokeWidth,
      strokeCap: StrokeCap.round,
      spring: const OrionSpringSpec(stiffness: 380, dampingRatio: 1),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionProgressStyle &&
        other.trackColor == trackColor &&
        other.fillColor == fillColor &&
        other.bufferColor == bufferColor &&
        other.height == height &&
        other.gap == gap &&
        other.radius == radius &&
        other.size == size &&
        other.strokeWidth == strokeWidth &&
        other.strokeCap == strokeCap &&
        other.spring == spring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    trackColor,
    fillColor,
    bufferColor,
    height,
    gap,
    radius,
    size,
    strokeWidth,
    strokeCap,
    spring,
  ]);
}
