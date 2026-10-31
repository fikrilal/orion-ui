import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The visual and physical styling contract for [OrionOtpField].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionOtpPresets`, the ambient `OrionOtpTheme`, and the
/// instance style passed to the field.
@immutable
class OrionOtpStyle {
  const OrionOtpStyle({
    this.slotWidth,
    this.slotHeight,
    this.slotBorderRadius,
    this.slotBorderWidth,
    this.activeBorderWidth,
    this.slotSpacing,
    this.groupSpacing,
    this.backgroundColor,
    this.activeBackgroundColor,
    this.filledBackgroundColor,
    this.errorBackgroundColor,
    this.successBackgroundColor,
    this.disabledBackgroundColor,
    this.hoverBackgroundColor,
    this.borderColor,
    this.activeBorderColor,
    this.filledBorderColor,
    this.errorBorderColor,
    this.successBorderColor,
    this.disabledBorderColor,
    this.hoverBorderColor,
    this.textStyle,
    this.disabledTextColor,
    this.placeholderTextStyle,
    this.labelStyle,
    this.captionStyle,
    this.caretColor,
    this.caretWidth,
    this.caretHeight,
    this.shakeSpringSpec,
    this.slotSpringSpec,
  });

  /// Width of each slot tile.
  final double? slotWidth;

  /// Height of each slot tile.
  final double? slotHeight;

  /// Corner radius of each slot tile.
  final BorderRadius? slotBorderRadius;

  /// Inactive/resting outline or underline width. Set to `0` to omit borders.
  final double? slotBorderWidth;

  /// Focused/active, error, or success border width.
  final double? activeBorderWidth;

  /// Horizontal spacing between consecutive slots within the same group.
  final double? slotSpacing;

  /// Extra horizontal spacing between separated groups (e.g. 3 + 3 slots).
  final double? groupSpacing;

  /// Background color of an empty, unfocused slot.
  final Color? backgroundColor;

  /// Background color of the currently focused slot.
  final Color? activeBackgroundColor;

  /// Background color of a filled slot.
  final Color? filledBackgroundColor;

  /// Background color of slots when in an error state.
  final Color? errorBackgroundColor;

  /// Background color of slots when in a success state.
  final Color? successBackgroundColor;

  /// Background color of slots when the field is disabled.
  final Color? disabledBackgroundColor;

  /// Subtle overlay or fill tint when a pointer hovers over an enabled field.
  final Color? hoverBackgroundColor;

  /// Outline or underline color of an empty, unfocused slot.
  final Color? borderColor;

  /// Outline or underline color of the active slot.
  final Color? activeBorderColor;

  /// Outline or underline color of an already filled slot.
  final Color? filledBorderColor;

  /// Outline or underline color when in an error state.
  final Color? errorBorderColor;

  /// Outline or underline color when in a success state.
  final Color? successBorderColor;

  /// Outline or underline color when disabled.
  final Color? disabledBorderColor;

  /// Outline or underline color of empty slots when pointer-hovered.
  final Color? hoverBorderColor;

  /// Typography styling for the displayed digits or bullet marks.
  final TextStyle? textStyle;

  /// Foreground color for digits when disabled.
  final Color? disabledTextColor;

  /// Typography styling for optional empty-slot placeholder glyphs.
  final TextStyle? placeholderTextStyle;

  /// Typography styling for the optional field label.
  final TextStyle? labelStyle;

  /// Typography styling for the optional helper or error caption.
  final TextStyle? captionStyle;

  /// Color of the breathing caret bar in the active slot.
  final Color? caretColor;

  /// Width of the caret bar.
  final double? caretWidth;

  /// Height of the caret bar.
  final double? caretHeight;

  /// Spring specification driving the horizontal error shake animation.
  final OrionSpringSpec? shakeSpringSpec;

  /// Spring specification driving the slot tile character insertion micro-bounce.
  final OrionSpringSpec? slotSpringSpec;

  /// Convenience factory creating a style with only named properties.
  factory OrionOtpStyle.from({
    double? slotWidth,
    double? slotHeight,
    BorderRadius? slotBorderRadius,
    double? slotBorderWidth,
    double? activeBorderWidth,
    double? slotSpacing,
    double? groupSpacing,
    Color? backgroundColor,
    Color? activeBackgroundColor,
    Color? filledBackgroundColor,
    Color? errorBackgroundColor,
    Color? successBackgroundColor,
    Color? disabledBackgroundColor,
    Color? hoverBackgroundColor,
    Color? borderColor,
    Color? activeBorderColor,
    Color? filledBorderColor,
    Color? errorBorderColor,
    Color? successBorderColor,
    Color? disabledBorderColor,
    Color? hoverBorderColor,
    TextStyle? textStyle,
    Color? disabledTextColor,
    TextStyle? placeholderTextStyle,
    TextStyle? labelStyle,
    TextStyle? captionStyle,
    Color? caretColor,
    double? caretWidth,
    double? caretHeight,
    OrionSpringSpec? shakeSpringSpec,
    OrionSpringSpec? slotSpringSpec,
  }) {
    return OrionOtpStyle(
      slotWidth: slotWidth,
      slotHeight: slotHeight,
      slotBorderRadius: slotBorderRadius,
      slotBorderWidth: slotBorderWidth,
      activeBorderWidth: activeBorderWidth,
      slotSpacing: slotSpacing,
      groupSpacing: groupSpacing,
      backgroundColor: backgroundColor,
      activeBackgroundColor: activeBackgroundColor,
      filledBackgroundColor: filledBackgroundColor,
      errorBackgroundColor: errorBackgroundColor,
      successBackgroundColor: successBackgroundColor,
      disabledBackgroundColor: disabledBackgroundColor,
      hoverBackgroundColor: hoverBackgroundColor,
      borderColor: borderColor,
      activeBorderColor: activeBorderColor,
      filledBorderColor: filledBorderColor,
      errorBorderColor: errorBorderColor,
      successBorderColor: successBorderColor,
      disabledBorderColor: disabledBorderColor,
      hoverBorderColor: hoverBorderColor,
      textStyle: textStyle,
      disabledTextColor: disabledTextColor,
      placeholderTextStyle: placeholderTextStyle,
      labelStyle: labelStyle,
      captionStyle: captionStyle,
      caretColor: caretColor,
      caretWidth: caretWidth,
      caretHeight: caretHeight,
      shakeSpringSpec: shakeSpringSpec,
      slotSpringSpec: slotSpringSpec,
    );
  }

  /// Returns a copy with the provided fields replaced.
  OrionOtpStyle copyWith({
    double? slotWidth,
    double? slotHeight,
    BorderRadius? slotBorderRadius,
    double? slotBorderWidth,
    double? activeBorderWidth,
    double? slotSpacing,
    double? groupSpacing,
    Color? backgroundColor,
    Color? activeBackgroundColor,
    Color? filledBackgroundColor,
    Color? errorBackgroundColor,
    Color? successBackgroundColor,
    Color? disabledBackgroundColor,
    Color? hoverBackgroundColor,
    Color? borderColor,
    Color? activeBorderColor,
    Color? filledBorderColor,
    Color? errorBorderColor,
    Color? successBorderColor,
    Color? disabledBorderColor,
    Color? hoverBorderColor,
    TextStyle? textStyle,
    Color? disabledTextColor,
    TextStyle? placeholderTextStyle,
    TextStyle? labelStyle,
    TextStyle? captionStyle,
    Color? caretColor,
    double? caretWidth,
    double? caretHeight,
    OrionSpringSpec? shakeSpringSpec,
    OrionSpringSpec? slotSpringSpec,
  }) {
    return OrionOtpStyle(
      slotWidth: slotWidth ?? this.slotWidth,
      slotHeight: slotHeight ?? this.slotHeight,
      slotBorderRadius: slotBorderRadius ?? this.slotBorderRadius,
      slotBorderWidth: slotBorderWidth ?? this.slotBorderWidth,
      activeBorderWidth: activeBorderWidth ?? this.activeBorderWidth,
      slotSpacing: slotSpacing ?? this.slotSpacing,
      groupSpacing: groupSpacing ?? this.groupSpacing,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      activeBackgroundColor:
          activeBackgroundColor ?? this.activeBackgroundColor,
      filledBackgroundColor:
          filledBackgroundColor ?? this.filledBackgroundColor,
      errorBackgroundColor: errorBackgroundColor ?? this.errorBackgroundColor,
      successBackgroundColor:
          successBackgroundColor ?? this.successBackgroundColor,
      disabledBackgroundColor:
          disabledBackgroundColor ?? this.disabledBackgroundColor,
      hoverBackgroundColor: hoverBackgroundColor ?? this.hoverBackgroundColor,
      borderColor: borderColor ?? this.borderColor,
      activeBorderColor: activeBorderColor ?? this.activeBorderColor,
      filledBorderColor: filledBorderColor ?? this.filledBorderColor,
      errorBorderColor: errorBorderColor ?? this.errorBorderColor,
      successBorderColor: successBorderColor ?? this.successBorderColor,
      disabledBorderColor: disabledBorderColor ?? this.disabledBorderColor,
      hoverBorderColor: hoverBorderColor ?? this.hoverBorderColor,
      textStyle: textStyle ?? this.textStyle,
      disabledTextColor: disabledTextColor ?? this.disabledTextColor,
      placeholderTextStyle: placeholderTextStyle ?? this.placeholderTextStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      captionStyle: captionStyle ?? this.captionStyle,
      caretColor: caretColor ?? this.caretColor,
      caretWidth: caretWidth ?? this.caretWidth,
      caretHeight: caretHeight ?? this.caretHeight,
      shakeSpringSpec: shakeSpringSpec ?? this.shakeSpringSpec,
      slotSpringSpec: slotSpringSpec ?? this.slotSpringSpec,
    );
  }

  /// Merges this style with [other], where [other]'s non-null fields take
  /// precedence. [TextStyle] fields merge via [TextStyle.merge] so partial
  /// overrides preserve inherited font color and metrics.
  OrionOtpStyle merge(OrionOtpStyle? other) {
    if (other == null) return this;
    return OrionOtpStyle(
      slotWidth: other.slotWidth ?? slotWidth,
      slotHeight: other.slotHeight ?? slotHeight,
      slotBorderRadius: other.slotBorderRadius ?? slotBorderRadius,
      slotBorderWidth: other.slotBorderWidth ?? slotBorderWidth,
      activeBorderWidth: other.activeBorderWidth ?? activeBorderWidth,
      slotSpacing: other.slotSpacing ?? slotSpacing,
      groupSpacing: other.groupSpacing ?? groupSpacing,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      activeBackgroundColor:
          other.activeBackgroundColor ?? activeBackgroundColor,
      filledBackgroundColor:
          other.filledBackgroundColor ?? filledBackgroundColor,
      errorBackgroundColor: other.errorBackgroundColor ?? errorBackgroundColor,
      successBackgroundColor:
          other.successBackgroundColor ?? successBackgroundColor,
      disabledBackgroundColor:
          other.disabledBackgroundColor ?? disabledBackgroundColor,
      hoverBackgroundColor: other.hoverBackgroundColor ?? hoverBackgroundColor,
      borderColor: other.borderColor ?? borderColor,
      activeBorderColor: other.activeBorderColor ?? activeBorderColor,
      filledBorderColor: other.filledBorderColor ?? filledBorderColor,
      errorBorderColor: other.errorBorderColor ?? errorBorderColor,
      successBorderColor: other.successBorderColor ?? successBorderColor,
      disabledBorderColor: other.disabledBorderColor ?? disabledBorderColor,
      hoverBorderColor: other.hoverBorderColor ?? hoverBorderColor,
      textStyle: textStyle == null
          ? other.textStyle
          : textStyle!.merge(other.textStyle),
      disabledTextColor: other.disabledTextColor ?? disabledTextColor,
      placeholderTextStyle: placeholderTextStyle == null
          ? other.placeholderTextStyle
          : placeholderTextStyle!.merge(other.placeholderTextStyle),
      labelStyle: labelStyle == null
          ? other.labelStyle
          : labelStyle!.merge(other.labelStyle),
      captionStyle: captionStyle == null
          ? other.captionStyle
          : captionStyle!.merge(other.captionStyle),
      caretColor: other.caretColor ?? caretColor,
      caretWidth: other.caretWidth ?? caretWidth,
      caretHeight: other.caretHeight ?? caretHeight,
      shakeSpringSpec: other.shakeSpringSpec ?? shakeSpringSpec,
      slotSpringSpec: other.slotSpringSpec ?? slotSpringSpec,
    );
  }

  /// Linearly interpolates between two [OrionOtpStyle]s.
  static OrionOtpStyle? lerp(OrionOtpStyle? a, OrionOtpStyle? b, double t) {
    if (identical(a, b)) return a;
    if (a == null) return b;
    if (b == null) return a;
    return OrionOtpStyle(
      slotWidth: lerpDouble(a.slotWidth, b.slotWidth, t),
      slotHeight: lerpDouble(a.slotHeight, b.slotHeight, t),
      slotBorderRadius: BorderRadius.lerp(
        a.slotBorderRadius,
        b.slotBorderRadius,
        t,
      ),
      slotBorderWidth: lerpDouble(a.slotBorderWidth, b.slotBorderWidth, t),
      activeBorderWidth: lerpDouble(
        a.activeBorderWidth,
        b.activeBorderWidth,
        t,
      ),
      slotSpacing: lerpDouble(a.slotSpacing, b.slotSpacing, t),
      groupSpacing: lerpDouble(a.groupSpacing, b.groupSpacing, t),
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      activeBackgroundColor: Color.lerp(
        a.activeBackgroundColor,
        b.activeBackgroundColor,
        t,
      ),
      filledBackgroundColor: Color.lerp(
        a.filledBackgroundColor,
        b.filledBackgroundColor,
        t,
      ),
      errorBackgroundColor: Color.lerp(
        a.errorBackgroundColor,
        b.errorBackgroundColor,
        t,
      ),
      successBackgroundColor: Color.lerp(
        a.successBackgroundColor,
        b.successBackgroundColor,
        t,
      ),
      disabledBackgroundColor: Color.lerp(
        a.disabledBackgroundColor,
        b.disabledBackgroundColor,
        t,
      ),
      hoverBackgroundColor: Color.lerp(
        a.hoverBackgroundColor,
        b.hoverBackgroundColor,
        t,
      ),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      activeBorderColor: Color.lerp(
        a.activeBorderColor,
        b.activeBorderColor,
        t,
      ),
      filledBorderColor: Color.lerp(
        a.filledBorderColor,
        b.filledBorderColor,
        t,
      ),
      errorBorderColor: Color.lerp(a.errorBorderColor, b.errorBorderColor, t),
      successBorderColor: Color.lerp(
        a.successBorderColor,
        b.successBorderColor,
        t,
      ),
      disabledBorderColor: Color.lerp(
        a.disabledBorderColor,
        b.disabledBorderColor,
        t,
      ),
      hoverBorderColor: Color.lerp(a.hoverBorderColor, b.hoverBorderColor, t),
      textStyle: TextStyle.lerp(a.textStyle, b.textStyle, t),
      disabledTextColor: Color.lerp(
        a.disabledTextColor,
        b.disabledTextColor,
        t,
      ),
      placeholderTextStyle: TextStyle.lerp(
        a.placeholderTextStyle,
        b.placeholderTextStyle,
        t,
      ),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      captionStyle: TextStyle.lerp(a.captionStyle, b.captionStyle, t),
      caretColor: Color.lerp(a.caretColor, b.caretColor, t),
      caretWidth: lerpDouble(a.caretWidth, b.caretWidth, t),
      caretHeight: lerpDouble(a.caretHeight, b.caretHeight, t),
      shakeSpringSpec: t < 0.5 ? a.shakeSpringSpec : b.shakeSpringSpec,
      slotSpringSpec: t < 0.5 ? a.slotSpringSpec : b.slotSpringSpec,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrionOtpStyle &&
          runtimeType == other.runtimeType &&
          slotWidth == other.slotWidth &&
          slotHeight == other.slotHeight &&
          slotBorderRadius == other.slotBorderRadius &&
          slotBorderWidth == other.slotBorderWidth &&
          activeBorderWidth == other.activeBorderWidth &&
          slotSpacing == other.slotSpacing &&
          groupSpacing == other.groupSpacing &&
          backgroundColor == other.backgroundColor &&
          activeBackgroundColor == other.activeBackgroundColor &&
          filledBackgroundColor == other.filledBackgroundColor &&
          errorBackgroundColor == other.errorBackgroundColor &&
          successBackgroundColor == other.successBackgroundColor &&
          disabledBackgroundColor == other.disabledBackgroundColor &&
          hoverBackgroundColor == other.hoverBackgroundColor &&
          borderColor == other.borderColor &&
          activeBorderColor == other.activeBorderColor &&
          filledBorderColor == other.filledBorderColor &&
          errorBorderColor == other.errorBorderColor &&
          successBorderColor == other.successBorderColor &&
          disabledBorderColor == other.disabledBorderColor &&
          hoverBorderColor == other.hoverBorderColor &&
          textStyle == other.textStyle &&
          disabledTextColor == other.disabledTextColor &&
          placeholderTextStyle == other.placeholderTextStyle &&
          labelStyle == other.labelStyle &&
          captionStyle == other.captionStyle &&
          caretColor == other.caretColor &&
          caretWidth == other.caretWidth &&
          caretHeight == other.caretHeight &&
          shakeSpringSpec == other.shakeSpringSpec &&
          slotSpringSpec == other.slotSpringSpec;

  @override
  int get hashCode => Object.hashAll(<Object?>[
    slotWidth,
    slotHeight,
    slotBorderRadius,
    slotBorderWidth,
    activeBorderWidth,
    slotSpacing,
    groupSpacing,
    backgroundColor,
    activeBackgroundColor,
    filledBackgroundColor,
    errorBackgroundColor,
    successBackgroundColor,
    disabledBackgroundColor,
    hoverBackgroundColor,
    borderColor,
    activeBorderColor,
    filledBorderColor,
    errorBorderColor,
    successBorderColor,
    disabledBorderColor,
    hoverBorderColor,
    textStyle,
    disabledTextColor,
    placeholderTextStyle,
    labelStyle,
    captionStyle,
    caretColor,
    caretWidth,
    caretHeight,
    shakeSpringSpec,
    slotSpringSpec,
  ]);
}
