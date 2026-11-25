import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an `OrionTextField` looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionTextFieldPresets`, the theme's `OrionTextFieldTheme`, and
/// the instance style passed to the widget. Every field is nullable; a null
/// field falls through to the layer beneath it, so an override changes only
/// what it names.
///
/// The colour properties resolve through the field's live [WidgetState]s -
/// [WidgetState.disabled], [WidgetState.hovered], [WidgetState.focused], and
/// [WidgetState.error] - and interpolate smoothly along the focus spring.
@immutable
class OrionTextFieldStyle {
  const OrionTextFieldStyle({
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.focusedBorderWidth,
    this.focusRingColor,
    this.focusRingWidth,
    this.textColor,
    this.hintColor,
    this.labelColor,
    this.iconColor,
    this.errorColor,
    this.cursorColor,
    this.height,
    this.padding,
    this.radius,
    this.iconSize,
    this.labelGap,
    this.captionGap,
    this.textStyle,
    this.labelStyle,
    this.captionStyle,
    this.spring,
  });

  /// Face fill, resolved with [WidgetState.disabled], [WidgetState.hovered],
  /// [WidgetState.focused], and [WidgetState.error].
  final WidgetStateProperty<Color?>? fillColor;

  /// The face's border colour, resolved with the same states. The focused
  /// value is the colour focus travels to, and the underline variant paints
  /// only its bottom edge from it.
  final WidgetStateProperty<Color?>? borderColor;

  /// Border stroke width at rest.
  final double? borderWidth;

  /// Border stroke width at full focus. Defaults to `borderWidth + 0.5`.
  final double? focusedBorderWidth;

  /// Subtle outer focus halo painted around `outline` and `filled` faces on
  /// focus. Pass [Colors.transparent] or `focusRingWidth: 0` to omit.
  final Color? focusRingColor;

  /// Spread width of the outer focus halo in logical pixels.
  final double? focusRingWidth;

  /// Entered text colour, resolved with [WidgetState.disabled],
  /// [WidgetState.focused], and [WidgetState.error].
  final WidgetStateProperty<Color?>? textColor;

  /// Hint colour, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? hintColor;

  /// Label colour above the face, resolved with [WidgetState.disabled],
  /// [WidgetState.focused], and [WidgetState.error].
  final WidgetStateProperty<Color?>? labelColor;

  /// Colour automatically applied to prefix, suffix, clear, and reveal icons.
  final WidgetStateProperty<Color?>? iconColor;

  /// Accent colour used for error captions, required markers, and error focus
  /// halos. Falls back to `ColorScheme.error`.
  final Color? errorColor;

  /// Caret colour.
  final Color? cursorColor;

  /// Face height; a growing multiline face treats it as a minimum.
  final double? height;

  /// The face's inner padding (horizontal edges + vertical text padding).
  final EdgeInsetsGeometry? padding;

  /// Face corner radius; the underline variant presets square corners.
  final BorderRadius? radius;

  /// Default icon size applied to prefix, suffix, and inline action icons.
  final double? iconSize;

  /// Gap between the label and the face.
  final double? labelGap;

  /// Gap between the face and the caption row.
  final double? captionGap;

  /// Entered and hint text style.
  final TextStyle? textStyle;

  /// Label text style.
  final TextStyle? labelStyle;

  /// Helper, error, and counter text style.
  final TextStyle? captionStyle;

  /// Spring the focus hairline, fill, and ring ride. Critically damped by
  /// default: focus should arrive crisply without bouncing.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionTextFieldStyle copyWith({
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? borderColor,
    double? borderWidth,
    double? focusedBorderWidth,
    Color? focusRingColor,
    double? focusRingWidth,
    WidgetStateProperty<Color?>? textColor,
    WidgetStateProperty<Color?>? hintColor,
    WidgetStateProperty<Color?>? labelColor,
    WidgetStateProperty<Color?>? iconColor,
    Color? errorColor,
    Color? cursorColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? iconSize,
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
      focusedBorderWidth: focusedBorderWidth ?? this.focusedBorderWidth,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      textColor: textColor ?? this.textColor,
      hintColor: hintColor ?? this.hintColor,
      labelColor: labelColor ?? this.labelColor,
      iconColor: iconColor ?? this.iconColor,
      errorColor: errorColor ?? this.errorColor,
      cursorColor: cursorColor ?? this.cursorColor,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
      iconSize: iconSize ?? this.iconSize,
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
      focusedBorderWidth: other.focusedBorderWidth ?? focusedBorderWidth,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      textColor: other.textColor ?? textColor,
      hintColor: other.hintColor ?? hintColor,
      labelColor: other.labelColor ?? labelColor,
      iconColor: other.iconColor ?? iconColor,
      errorColor: other.errorColor ?? errorColor,
      cursorColor: other.cursorColor ?? cursorColor,
      height: other.height ?? height,
      padding: other.padding ?? padding,
      radius: other.radius ?? radius,
      iconSize: other.iconSize ?? iconSize,
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
    double? focusedBorderWidth,
    Color? focusRingColor,
    double? focusRingWidth,
    Color? textColor,
    Color? hintColor,
    Color? labelColor,
    Color? iconColor,
    Color? errorColor,
    Color? cursorColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? iconSize,
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
      focusedBorderWidth: focusedBorderWidth,
      focusRingColor: focusRingColor,
      focusRingWidth: focusRingWidth,
      textColor: textColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(textColor),
      hintColor: hintColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(hintColor),
      labelColor: labelColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(labelColor),
      iconColor: iconColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(iconColor),
      errorColor: errorColor,
      cursorColor: cursorColor,
      height: height,
      padding: padding,
      radius: radius,
      iconSize: iconSize,
      labelGap: labelGap,
      captionGap: captionGap,
      textStyle: textStyle,
      labelStyle: labelStyle,
      captionStyle: captionStyle,
      spring: spring,
    );
  }

  /// Linearly interpolates between two [OrionTextFieldStyle] instances.
  static OrionTextFieldStyle? lerp(
    OrionTextFieldStyle? a,
    OrionTextFieldStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null && b == null) {
      return null;
    }
    return OrionTextFieldStyle(
      fillColor: WidgetStateProperty.lerp<Color?>(
        a?.fillColor,
        b?.fillColor,
        t,
        Color.lerp,
      ),
      borderColor: WidgetStateProperty.lerp<Color?>(
        a?.borderColor,
        b?.borderColor,
        t,
        Color.lerp,
      ),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      focusedBorderWidth: lerpDouble(
        a?.focusedBorderWidth,
        b?.focusedBorderWidth,
        t,
      ),
      focusRingColor: Color.lerp(a?.focusRingColor, b?.focusRingColor, t),
      focusRingWidth: lerpDouble(a?.focusRingWidth, b?.focusRingWidth, t),
      textColor: WidgetStateProperty.lerp<Color?>(
        a?.textColor,
        b?.textColor,
        t,
        Color.lerp,
      ),
      hintColor: WidgetStateProperty.lerp<Color?>(
        a?.hintColor,
        b?.hintColor,
        t,
        Color.lerp,
      ),
      labelColor: WidgetStateProperty.lerp<Color?>(
        a?.labelColor,
        b?.labelColor,
        t,
        Color.lerp,
      ),
      iconColor: WidgetStateProperty.lerp<Color?>(
        a?.iconColor,
        b?.iconColor,
        t,
        Color.lerp,
      ),
      errorColor: Color.lerp(a?.errorColor, b?.errorColor, t),
      cursorColor: Color.lerp(a?.cursorColor, b?.cursorColor, t),
      height: lerpDouble(a?.height, b?.height, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      radius: BorderRadius.lerp(a?.radius, b?.radius, t),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      labelGap: lerpDouble(a?.labelGap, b?.labelGap, t),
      captionGap: lerpDouble(a?.captionGap, b?.captionGap, t),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      captionStyle: TextStyle.lerp(a?.captionStyle, b?.captionStyle, t),
      spring: t < 0.5 ? a?.spring : b?.spring,
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
        other.focusedBorderWidth == focusedBorderWidth &&
        other.focusRingColor == focusRingColor &&
        other.focusRingWidth == focusRingWidth &&
        other.textColor == textColor &&
        other.hintColor == hintColor &&
        other.labelColor == labelColor &&
        other.iconColor == iconColor &&
        other.errorColor == errorColor &&
        other.cursorColor == cursorColor &&
        other.height == height &&
        other.padding == padding &&
        other.radius == radius &&
        other.iconSize == iconSize &&
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
    focusedBorderWidth,
    focusRingColor,
    focusRingWidth,
    textColor,
    hintColor,
    labelColor,
    iconColor,
    errorColor,
    cursorColor,
    height,
    padding,
    radius,
    iconSize,
    labelGap,
    captionGap,
    textStyle,
    labelStyle,
    captionStyle,
    spring,
  ]);
}
