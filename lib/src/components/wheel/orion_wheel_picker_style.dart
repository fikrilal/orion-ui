import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionWheelPicker] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionWheelPickerPresets`, the theme's `OrionWheelPickerTheme`,
/// and the instance style passed to the widget. Every field is nullable; a
/// null field falls through to the layer beneath it, so an override changes
/// exactly what it names.
@immutable
class OrionWheelPickerStyle {
  const OrionWheelPickerStyle({
    this.selectedColor,
    this.idleColor,
    this.textStyle,
    this.radius,
    this.itemExtent,
    this.edgeScale,
    this.projectionSeconds,
    this.endResistance,
    this.focusRingColor,
    this.focusRingWidth,
    this.settleSpring,
  });

  /// The centred row's colour, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? selectedColor;

  /// The other rows' colour, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? idleColor;

  /// The rows' text style; a row's label inherits it.
  final TextStyle? textStyle;

  /// The wheel box's corner radius.
  final BorderRadius? radius;

  /// One row's extent. Every row is its own tap target, so the wheel is
  /// `visibleItemCount` extents tall with no per-item measurement.
  final double? itemExtent;

  /// Scale of a row at the edge of the band, where the falloff is zero.
  final double? edgeScale;

  /// How much of the release velocity projects into the landing distance, in
  /// seconds. This is the wheel's flick feel.
  final double? projectionSeconds;

  /// How much of an out-of-range drag reaches the wheel, as a fraction.
  final double? endResistance;

  /// The focus ring's colour. The ring is drawn over the box, so showing focus
  /// never moves a row.
  final Color? focusRingColor;

  /// The focus ring's width.
  final double? focusRingWidth;

  /// Spring the settle rides. Critically damped by default, because an
  /// underdamped settle overshoots far enough to cross the next boundary - the
  /// wheel would ring past the detent it aimed at and tick again.
  final OrionSpringSpec? settleSpring;

  /// Returns a copy with the provided fields replaced.
  OrionWheelPickerStyle copyWith({
    WidgetStateProperty<Color?>? selectedColor,
    WidgetStateProperty<Color?>? idleColor,
    TextStyle? textStyle,
    BorderRadius? radius,
    double? itemExtent,
    double? edgeScale,
    double? projectionSeconds,
    double? endResistance,
    Color? focusRingColor,
    double? focusRingWidth,
    OrionSpringSpec? settleSpring,
  }) {
    return OrionWheelPickerStyle(
      selectedColor: selectedColor ?? this.selectedColor,
      idleColor: idleColor ?? this.idleColor,
      textStyle: textStyle ?? this.textStyle,
      radius: radius ?? this.radius,
      itemExtent: itemExtent ?? this.itemExtent,
      edgeScale: edgeScale ?? this.edgeScale,
      projectionSeconds: projectionSeconds ?? this.projectionSeconds,
      endResistance: endResistance ?? this.endResistance,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      settleSpring: settleSpring ?? this.settleSpring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionWheelPickerStyle merge(OrionWheelPickerStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionWheelPickerStyle(
      selectedColor: other.selectedColor ?? selectedColor,
      idleColor: other.idleColor ?? idleColor,
      textStyle: other.textStyle ?? textStyle,
      radius: other.radius ?? radius,
      itemExtent: other.itemExtent ?? itemExtent,
      edgeScale: other.edgeScale ?? edgeScale,
      projectionSeconds: other.projectionSeconds ?? projectionSeconds,
      endResistance: other.endResistance ?? endResistance,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      settleSpring: other.settleSpring ?? settleSpring,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  static OrionWheelPickerStyle from({
    Color? selectedColor,
    Color? idleColor,
    TextStyle? textStyle,
    BorderRadius? radius,
    double? itemExtent,
    double? edgeScale,
    double? projectionSeconds,
    double? endResistance,
    Color? focusRingColor,
    double? focusRingWidth,
    OrionSpringSpec? settleSpring,
  }) {
    return OrionWheelPickerStyle(
      selectedColor: selectedColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(selectedColor),
      idleColor: idleColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(idleColor),
      textStyle: textStyle,
      radius: radius,
      itemExtent: itemExtent,
      edgeScale: edgeScale,
      projectionSeconds: projectionSeconds,
      endResistance: endResistance,
      focusRingColor: focusRingColor,
      focusRingWidth: focusRingWidth,
      settleSpring: settleSpring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionWheelPickerStyle &&
        other.selectedColor == selectedColor &&
        other.idleColor == idleColor &&
        other.textStyle == textStyle &&
        other.radius == radius &&
        other.itemExtent == itemExtent &&
        other.edgeScale == edgeScale &&
        other.projectionSeconds == projectionSeconds &&
        other.endResistance == endResistance &&
        other.focusRingColor == focusRingColor &&
        other.focusRingWidth == focusRingWidth &&
        other.settleSpring == settleSpring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    selectedColor,
    idleColor,
    textStyle,
    radius,
    itemExtent,
    edgeScale,
    projectionSeconds,
    endResistance,
    focusRingColor,
    focusRingWidth,
    settleSpring,
  ]);
}
