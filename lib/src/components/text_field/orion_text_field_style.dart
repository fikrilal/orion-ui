import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionTextField] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionTextFieldPresets`, the theme's `OrionTextFieldTheme`, and
/// the instance style passed to the widget. Every field is nullable; a null
/// field falls through to the layer beneath it, so an override changes exactly
/// what it names.
///
/// The colour fields resolve through the field's live [WidgetState]s -
/// [WidgetState.disabled], [WidgetState.focused] and [WidgetState.error] -
/// so a skin can tint each state without restating the rest. Focus is carried
/// by the line itself: the focused [borderColor] is the colour the hairline
/// travels to, and it steps half a point wider there.
@immutable
class OrionTextFieldStyle {
  const OrionTextFieldStyle({
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.textColor,
    this.hintColor,
    this.cursorColor,
    this.height,
    this.padding,
    this.radius,
    this.labelGap,
    this.captionGap,
    this.textStyle,
    this.labelStyle,
    this.captionStyle,
    this.spring,
  });

  /// Face fill, resolved with [WidgetState.disabled], [WidgetState.focused]
  /// and [WidgetState.error].
  final WidgetStateProperty<Color?>? fillColor;

  /// The face's line, resolved with the same states. The focused value is the
  /// colour focus travels to, and the underline variant paints only its
  /// bottom edge from it.
  final WidgetStateProperty<Color?>? borderColor;

  /// Line width at rest; focus adds half a point.
  final double? borderWidth;

  /// Entered text colour, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? textColor;

  /// Hint colour, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? hintColor;

  /// Caret colour.
  final Color? cursorColor;

  /// Face height; a growing multiline face treats it as a minimum.
  final double? height;

  /// The face's inner padding.
  final EdgeInsetsGeometry? padding;

  /// Face corner radius; the underline variant presets square corners.
  final BorderRadius? radius;

  /// Gap between the label and the face.
  final double? labelGap;

  /// Gap between the face and the caption row.
  final double? captionGap;

  /// Entered and hint text style.
  final TextStyle? textStyle;

  /// Label text style.
  final TextStyle? labelStyle;

  /// Helper, error and counter text style.
  final TextStyle? captionStyle;

  /// Spring the focus line rides. Critically damped by default: the line
  /// should arrive, not bounce.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionTextFieldStyle copyWith({
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? borderColor,
    double? borderWidth,
    WidgetStateProperty<Color?>? textColor,
    WidgetStateProperty<Color?>? hintColor,
    Color? cursorColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? labelGap,
    double? captionGap,
    TextStyle? textStyle,
    TextStyle? labelStyle,
    TextStyle? captionStyle,
    OrionSpringSpec? spring,
  }) {
    return OrionTextFieldStyle(
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      textColor: textColor ?? this.textColor,
      hintColor: hintColor ?? this.hintColor,
      cursorColor: cursorColor ?? this.cursorColor,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
      labelGap: labelGap ?? this.labelGap,
      captionGap: captionGap ?? this.captionGap,
      textStyle: textStyle ?? this.textStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      captionStyle: captionStyle ?? this.captionStyle,
      spring: spring ?? this.spring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionTextFieldStyle merge(OrionTextFieldStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionTextFieldStyle(
      fillColor: other.fillColor ?? fillColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      textColor: other.textColor ?? textColor,
      hintColor: other.hintColor ?? hintColor,
      cursorColor: other.cursorColor ?? cursorColor,
      height: other.height ?? height,
      padding: other.padding ?? padding,
      radius: other.radius ?? radius,
      labelGap: other.labelGap ?? labelGap,
      captionGap: other.captionGap ?? captionGap,
      textStyle: other.textStyle ?? textStyle,
      labelStyle: other.labelStyle ?? labelStyle,
      captionStyle: other.captionStyle ?? captionStyle,
      spring: other.spring ?? spring,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionTextFieldStyle from({
    Color? fillColor,
    Color? borderColor,
    double? borderWidth,
    Color? textColor,
    Color? hintColor,
    Color? cursorColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? labelGap,
    double? captionGap,
    TextStyle? textStyle,
    TextStyle? labelStyle,
    TextStyle? captionStyle,
    OrionSpringSpec? spring,
  }) {
    return OrionTextFieldStyle(
      fillColor: fillColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(fillColor),
      borderColor: borderColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(borderColor),
      borderWidth: borderWidth,
      textColor: textColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(textColor),
      hintColor: hintColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(hintColor),
      cursorColor: cursorColor,
      height: height,
      padding: padding,
      radius: radius,
      labelGap: labelGap,
      captionGap: captionGap,
      textStyle: textStyle,
      labelStyle: labelStyle,
      captionStyle: captionStyle,
      spring: spring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionTextFieldStyle &&
        other.fillColor == fillColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.textColor == textColor &&
        other.hintColor == hintColor &&
        other.cursorColor == cursorColor &&
        other.height == height &&
        other.padding == padding &&
        other.radius == radius &&
        other.labelGap == labelGap &&
        other.captionGap == captionGap &&
        other.textStyle == textStyle &&
        other.labelStyle == labelStyle &&
        other.captionStyle == captionStyle &&
        other.spring == spring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    fillColor,
    borderColor,
    borderWidth,
    textColor,
    hintColor,
    cursorColor,
    height,
    padding,
    radius,
    labelGap,
    captionGap,
    textStyle,
    labelStyle,
    captionStyle,
    spring,
  ]);
}
