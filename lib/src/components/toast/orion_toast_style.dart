import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable visual and physical contract for `OrionToast`.
///
/// Four layers produce the effective style, each overriding the last:
/// `OrionToastPresets` for the toast status, the ambient `OrionToastTheme`,
/// the host `OrionToaster.style`, and the per-toast `OrionToastData.style`.
@immutable
class OrionToastStyle {
  const OrionToastStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.padding,
    this.maxWidth,
    this.titleStyle,
    this.descriptionStyle,
    this.iconColor,
    this.iconBackgroundColor,
    this.closeButtonColor,
    this.progressBarColor,
    this.actionStyle,
    this.frosted,
    this.richColors,
    this.shadow,
    this.mountSpring,
    this.stackSpring,
    this.swipeSpring,
  });

  /// Surface background color.
  final Color? backgroundColor;

  /// Card border outline color.
  final Color? borderColor;

  /// Card border outline width (`<= 0` omits border).
  final double? borderWidth;

  /// Card corner radius.
  final BorderRadius? borderRadius;

  /// Inner card padding.
  final EdgeInsetsGeometry? padding;

  /// Maximum width of cards in the stack (defaults to `380`).
  final double? maxWidth;

  /// Title typography style.
  final TextStyle? titleStyle;

  /// Secondary description typography style.
  final TextStyle? descriptionStyle;

  /// Status icon color.
  final Color? iconColor;

  /// Subtle circular badge fill behind the status icon. Pass
  /// [Colors.transparent] to omit the badge.
  final Color? iconBackgroundColor;

  /// Dismiss close button icon color.
  final Color? closeButtonColor;

  /// Optional countdown progress bar color along the card's bottom edge.
  final Color? progressBarColor;

  /// Action button style override.
  final OrionButtonStyle? actionStyle;

  /// Whether to render a static Gaussian blur backdrop behind the card.
  final bool? frosted;

  /// Whether to tint the card surface and border with the semantic status color
  /// (info, success, warning, error).
  final bool? richColors;

  /// Elevation box shadow recipe.
  final List<BoxShadow>? shadow;

  /// Spring governing entrance mounting and anchor-edge exit motion.
  final OrionSpringSpec? mountSpring;

  /// Spring governing stack depth transitions (Y offset, scale, opacity).
  final OrionSpringSpec? stackSpring;

  /// Spring governing swipe-to-dismiss glide and snap-back.
  final OrionSpringSpec? swipeSpring;

  /// Returns a copy with the provided fields replaced.
  OrionToastStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    Color? iconColor,
    Color? iconBackgroundColor,
    Color? closeButtonColor,
    Color? progressBarColor,
    OrionButtonStyle? actionStyle,
    bool? frosted,
    bool? richColors,
    List<BoxShadow>? shadow,
    OrionSpringSpec? mountSpring,
    OrionSpringSpec? stackSpring,
    OrionSpringSpec? swipeSpring,
  }) {
    return OrionToastStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      padding: padding ?? this.padding,
      maxWidth: maxWidth ?? this.maxWidth,
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      iconColor: iconColor ?? this.iconColor,
      iconBackgroundColor: iconBackgroundColor ?? this.iconBackgroundColor,
      closeButtonColor: closeButtonColor ?? this.closeButtonColor,
      progressBarColor: progressBarColor ?? this.progressBarColor,
      actionStyle: actionStyle ?? this.actionStyle,
      frosted: frosted ?? this.frosted,
      richColors: richColors ?? this.richColors,
      shadow: shadow ?? this.shadow,
      mountSpring: mountSpring ?? this.mountSpring,
      stackSpring: stackSpring ?? this.stackSpring,
      swipeSpring: swipeSpring ?? this.swipeSpring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionToastStyle merge(OrionToastStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionToastStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      padding: other.padding ?? padding,
      maxWidth: other.maxWidth ?? maxWidth,
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
      iconColor: other.iconColor ?? iconColor,
      iconBackgroundColor: other.iconBackgroundColor ?? iconBackgroundColor,
      closeButtonColor: other.closeButtonColor ?? closeButtonColor,
      progressBarColor: other.progressBarColor ?? progressBarColor,
      actionStyle: other.actionStyle ?? actionStyle,
      frosted: other.frosted ?? frosted,
      richColors: other.richColors ?? richColors,
      shadow: other.shadow ?? shadow,
      mountSpring: other.mountSpring ?? mountSpring,
      stackSpring: other.stackSpring ?? stackSpring,
      swipeSpring: other.swipeSpring ?? swipeSpring,
    );
  }

  /// Builds a style from plain values.
  static OrionToastStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    Color? iconColor,
    Color? iconBackgroundColor,
    Color? closeButtonColor,
    Color? progressBarColor,
    OrionButtonStyle? actionStyle,
    bool? frosted,
    bool? richColors,
    List<BoxShadow>? shadow,
    OrionSpringSpec? mountSpring,
    OrionSpringSpec? stackSpring,
    OrionSpringSpec? swipeSpring,
  }) {
    return OrionToastStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      padding: padding,
      maxWidth: maxWidth,
      titleStyle: titleStyle,
      descriptionStyle: descriptionStyle,
      iconColor: iconColor,
      iconBackgroundColor: iconBackgroundColor,
      closeButtonColor: closeButtonColor,
      progressBarColor: progressBarColor,
      actionStyle: actionStyle,
      frosted: frosted,
      richColors: richColors,
      shadow: shadow,
      mountSpring: mountSpring,
      stackSpring: stackSpring,
      swipeSpring: swipeSpring,
    );
  }

  /// Linearly interpolates between two [OrionToastStyle] instances.
  static OrionToastStyle? lerp(
    OrionToastStyle? a,
    OrionToastStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null && b == null) return null;
    return OrionToastStyle(
      backgroundColor: Color.lerp(a?.backgroundColor, b?.backgroundColor, t),
      borderColor: Color.lerp(a?.borderColor, b?.borderColor, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      maxWidth: lerpDouble(a?.maxWidth, b?.maxWidth, t),
      titleStyle: TextStyle.lerp(a?.titleStyle, b?.titleStyle, t),
      descriptionStyle: TextStyle.lerp(
        a?.descriptionStyle,
        b?.descriptionStyle,
        t,
      ),
      iconColor: Color.lerp(a?.iconColor, b?.iconColor, t),
      iconBackgroundColor: Color.lerp(
        a?.iconBackgroundColor,
        b?.iconBackgroundColor,
        t,
      ),
      closeButtonColor: Color.lerp(a?.closeButtonColor, b?.closeButtonColor, t),
      progressBarColor: Color.lerp(a?.progressBarColor, b?.progressBarColor, t),
      actionStyle: t < 0.5 ? a?.actionStyle : b?.actionStyle,
      frosted: t < 0.5 ? a?.frosted : b?.frosted,
      richColors: t < 0.5 ? a?.richColors : b?.richColors,
      shadow: BoxShadow.lerpList(a?.shadow, b?.shadow, t),
      mountSpring: t < 0.5 ? a?.mountSpring : b?.mountSpring,
      stackSpring: t < 0.5 ? a?.stackSpring : b?.stackSpring,
      swipeSpring: t < 0.5 ? a?.swipeSpring : b?.swipeSpring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionToastStyle &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.padding == padding &&
        other.maxWidth == maxWidth &&
        other.titleStyle == titleStyle &&
        other.descriptionStyle == descriptionStyle &&
        other.iconColor == iconColor &&
        other.iconBackgroundColor == iconBackgroundColor &&
        other.closeButtonColor == closeButtonColor &&
        other.progressBarColor == progressBarColor &&
        other.actionStyle == actionStyle &&
        other.frosted == frosted &&
        other.richColors == richColors &&
        listEquals(other.shadow, shadow) &&
        other.mountSpring == mountSpring &&
        other.stackSpring == stackSpring &&
        other.swipeSpring == swipeSpring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    padding,
    maxWidth,
    titleStyle,
    descriptionStyle,
    iconColor,
    iconBackgroundColor,
    closeButtonColor,
    progressBarColor,
    actionStyle,
    frosted,
    richColors,
    shadow == null ? null : Object.hashAll(shadow!),
    mountSpring,
    stackSpring,
    swipeSpring,
  ]);
}
