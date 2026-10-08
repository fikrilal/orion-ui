import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionBadge] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionBadgePresets.resolve`, the theme's `OrionBadgeTheme`
/// (`defaultStyle`, then the variant entry), and the instance style passed to
/// the widget. Every field is nullable; a null field falls through to the
/// layer beneath it, so an override changes exactly what it names.
@immutable
class OrionBadgeStyle {
  const OrionBadgeStyle({
    this.background,
    this.foreground,
    this.border,
    this.padding,
    this.textStyle,
    this.radius,
    this.dotSize,
    this.popScale,
    this.popSpring,
  });

  /// Pill fill.
  final Color? background;

  /// Label, figure and icon colour.
  final Color? foreground;

  /// Outline drawn inside the pill. Null falls through a merge; pass
  /// [BorderSide.none] to remove an inherited border, and a zero-width side
  /// paints nothing.
  final BorderSide? border;

  /// The pill's inner padding.
  final EdgeInsetsGeometry? padding;

  /// Label text style; the preset takes it from the ambient [TextTheme].
  final TextStyle? textStyle;

  /// Pill corner radius.
  final BorderRadius? radius;

  /// The `OrionBadge.dot` circle's diameter.
  final double? dotSize;

  /// Scale a count pops to on change. The preset is 1.1 - the +10 % pop
  /// Telegram's counters use on an incremental change.
  final double? popScale;

  /// Spring the pop rides. Falls back to the theme's
  /// `OrionThemeData.pressSpring` when null.
  final OrionSpringSpec? popSpring;

  /// Returns a copy with the provided fields replaced.
  OrionBadgeStyle copyWith({
    Color? background,
    Color? foreground,
    BorderSide? border,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    BorderRadius? radius,
    double? dotSize,
    double? popScale,
    OrionSpringSpec? popSpring,
  }) {
    return OrionBadgeStyle(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      border: border ?? this.border,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      radius: radius ?? this.radius,
      dotSize: dotSize ?? this.dotSize,
      popScale: popScale ?? this.popScale,
      popSpring: popSpring ?? this.popSpring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionBadgeStyle merge(OrionBadgeStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionBadgeStyle(
      background: other.background ?? background,
      foreground: other.foreground ?? foreground,
      border: other.border ?? border,
      padding: other.padding ?? padding,
      textStyle: other.textStyle ?? textStyle,
      radius: other.radius ?? radius,
      dotSize: other.dotSize ?? dotSize,
      popScale: other.popScale ?? popScale,
      popSpring: other.popSpring ?? popSpring,
    );
  }

  /// Builds a style from plain values.
  static OrionBadgeStyle from({
    Color? background,
    Color? foreground,
    BorderSide? border,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    BorderRadius? radius,
    double? dotSize,
    double? popScale,
    OrionSpringSpec? popSpring,
  }) {
    return OrionBadgeStyle(
      background: background,
      foreground: foreground,
      border: border,
      padding: padding,
      textStyle: textStyle,
      radius: radius,
      dotSize: dotSize,
      popScale: popScale,
      popSpring: popSpring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionBadgeStyle &&
        other.background == background &&
        other.foreground == foreground &&
        other.border == border &&
        other.padding == padding &&
        other.textStyle == textStyle &&
        other.radius == radius &&
        other.dotSize == dotSize &&
        other.popScale == popScale &&
        other.popSpring == popSpring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    background,
    foreground,
    border,
    padding,
    textStyle,
    radius,
    dotSize,
    popScale,
    popSpring,
  ]);
}
