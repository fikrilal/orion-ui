import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The overridable contract shared by the progress family.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in [defaults], the theme's `OrionProgressTheme`, and the instance
/// style passed to the widget. Every field is nullable; a null field falls
/// through to the layer beneath it, so an override changes exactly what it
/// names.
///
/// [gap] applies to the segmented bar only, and [bufferColor] to the linear
/// bar only; the rest are painted by both.
@immutable
class OrionProgressStyle {
  const OrionProgressStyle({
    this.trackColor,
    this.fillColor,
    this.bufferColor,
    this.height,
    this.gap,
    this.radius,
    this.spring,
  });

  /// The empty track behind the fill.
  final Color? trackColor;

  /// The determinate fill, and the sweeping fill while indeterminate.
  final Color? fillColor;

  /// The buffered (cached) layer between track and fill, painted by the
  /// linear bar from its `bufferedValue`.
  final Color? bufferColor;

  /// Bar height.
  final double? height;

  /// Space between segments, on the segmented bar.
  final double? gap;

  /// Corner radius of the track and its fills.
  final BorderRadius? radius;

  /// Settle spec for determinate value changes. The indeterminate sweep runs
  /// on its own linear clock; a progress fill that must reach its target and
  /// stay there settles critically damped by default.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionProgressStyle copyWith({
    Color? trackColor,
    Color? fillColor,
    Color? bufferColor,
    double? height,
    double? gap,
    BorderRadius? radius,
    OrionSpringSpec? spring,
  }) {
    return OrionProgressStyle(
      trackColor: trackColor ?? this.trackColor,
      fillColor: fillColor ?? this.fillColor,
      bufferColor: bufferColor ?? this.bufferColor,
      height: height ?? this.height,
      gap: gap ?? this.gap,
      radius: radius ?? this.radius,
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
      spring: other.spring ?? spring,
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
    OrionSpringSpec? spring,
  }) {
    return OrionProgressStyle(
      trackColor: trackColor,
      fillColor: fillColor,
      bufferColor: bufferColor,
      height: height,
      gap: gap,
      radius: radius,
      spring: spring,
    );
  }

  /// The built-in look: the segmented bar's shipped geometry and colours,
  /// with [height] supplied by the component that resolves it.
  static OrionProgressStyle defaults({
    required ColorScheme scheme,
    required double height,
  }) {
    return OrionProgressStyle(
      trackColor: scheme.secondary,
      fillColor: scheme.primary,
      bufferColor: scheme.primary.withValues(alpha: 0.24),
      height: height,
      gap: OrionSpacing.space4,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
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
    spring,
  ]);
}
