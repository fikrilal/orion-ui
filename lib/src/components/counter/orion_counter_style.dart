import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionCounter] looks and rolls.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionCounterPresets`, the theme's `OrionCounterTheme`, and the
/// instance style passed to the widget. Every field is nullable; a null field
/// falls through to the layer beneath it, so an override changes exactly what
/// it names.
@immutable
class OrionCounterStyle {
  const OrionCounterStyle({
    this.textStyle,
    this.rollStretchX,
    this.rollSquashY,
    this.fadeEdges,
    this.spring,
  });

  /// Overrides for the ambient text style. Unset attributes are inherited, and
  /// the counter pins every slot to the widest digit of the resolved style and
  /// requests tabular figures on top.
  final TextStyle? textStyle;

  /// How much a rolling digit widens at the midpoint of its travel.
  final double? rollStretchX;

  /// How much a rolling digit squashes at the midpoint of its travel.
  final double? rollSquashY;

  /// Whether rolling digits softly fade near the top and bottom clip edges
  /// while in motion. At rest, digits render at full opacity with no extra
  /// compositing layer.
  final bool? fadeEdges;

  /// Spring one row of digits rides.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionCounterStyle copyWith({
    TextStyle? textStyle,
    double? rollStretchX,
    double? rollSquashY,
    bool? fadeEdges,
    OrionSpringSpec? spring,
  }) {
    return OrionCounterStyle(
      textStyle: textStyle ?? this.textStyle,
      rollStretchX: rollStretchX ?? this.rollStretchX,
      rollSquashY: rollSquashY ?? this.rollSquashY,
      fadeEdges: fadeEdges ?? this.fadeEdges,
      spring: spring ?? this.spring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  ///
  /// When both layers provide a [textStyle], they are merged field-by-field via
  /// [TextStyle.merge] so an instance override (such as `fontSize`) preserves
  /// theme-level typography attributes (such as `fontWeight` or `fontFamily`).
  OrionCounterStyle merge(OrionCounterStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionCounterStyle(
      textStyle: textStyle == null
          ? other.textStyle
          : (other.textStyle == null
                ? textStyle
                : textStyle!.merge(other.textStyle)),
      rollStretchX: other.rollStretchX ?? rollStretchX,
      rollSquashY: other.rollSquashY ?? rollSquashY,
      fadeEdges: other.fadeEdges ?? fadeEdges,
      spring: other.spring ?? spring,
    );
  }

  /// Builds a style from plain values.
  static OrionCounterStyle from({
    TextStyle? textStyle,
    double? rollStretchX,
    double? rollSquashY,
    bool? fadeEdges,
    OrionSpringSpec? spring,
  }) {
    return OrionCounterStyle(
      textStyle: textStyle,
      rollStretchX: rollStretchX,
      rollSquashY: rollSquashY,
      fadeEdges: fadeEdges,
      spring: spring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCounterStyle &&
        other.textStyle == textStyle &&
        other.rollStretchX == rollStretchX &&
        other.rollSquashY == rollSquashY &&
        other.fadeEdges == fadeEdges &&
        other.spring == spring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    textStyle,
    rollStretchX,
    rollSquashY,
    fadeEdges,
    spring,
  ]);
}
