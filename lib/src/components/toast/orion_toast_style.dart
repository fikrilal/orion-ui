import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable visual and physical contract for [OrionToast].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionToastPresets`, the ambient `OrionToastTheme`, and the
/// instance style passed to the toast.
@immutable
class OrionToastStyle {
  const OrionToastStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.titleStyle,
    this.descriptionStyle,
    this.iconColor,
    this.closeButtonColor,
    this.actionStyle,
    this.frosted,
    this.shadow,
    this.mountSpring,
    this.stackSpring,
    this.swipeSpring,
  });

  /// Surface background color.
  final Color? backgroundColor;

  /// Card border outline color.
  final Color? borderColor;

  /// Card border outline width.
  final double? borderWidth;

  /// Card corner radius.
  final BorderRadius? borderRadius;

  /// Title typography style.
  final TextStyle? titleStyle;

  /// Secondary description typography style.
  final TextStyle? descriptionStyle;

  /// Status icon color.
  final Color? iconColor;

  /// Dismiss close button color.
  final Color? closeButtonColor;

  /// Action button style override.
  final OrionButtonStyle? actionStyle;

  /// Whether to render a static Gaussian blur backdrop behind the card.
  final bool? frosted;

  /// Elevation box shadow recipe.
  final List<BoxShadow>? shadow;

  /// Spring governing entrance mounting motion.
  final OrionSpringSpec? mountSpring;

  /// Spring governing stack depth transitions (Y offset, scale, opacity).
  final OrionSpringSpec? stackSpring;

  /// Spring governing horizontal swipe-to-dismiss snap-back.
  final OrionSpringSpec? swipeSpring;

  /// Returns a copy with the provided fields replaced.
  OrionToastStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    Color? iconColor,
    Color? closeButtonColor,
    OrionButtonStyle? actionStyle,
    bool? frosted,
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
      titleStyle: titleStyle ?? this.titleStyle,
      descriptionStyle: descriptionStyle ?? this.descriptionStyle,
      iconColor: iconColor ?? this.iconColor,
      closeButtonColor: closeButtonColor ?? this.closeButtonColor,
      actionStyle: actionStyle ?? this.actionStyle,
      frosted: frosted ?? this.frosted,
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
      titleStyle: other.titleStyle ?? titleStyle,
      descriptionStyle: other.descriptionStyle ?? descriptionStyle,
      iconColor: other.iconColor ?? iconColor,
      closeButtonColor: other.closeButtonColor ?? closeButtonColor,
      actionStyle: other.actionStyle ?? actionStyle,
      frosted: other.frosted ?? frosted,
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
    TextStyle? titleStyle,
    TextStyle? descriptionStyle,
    Color? iconColor,
    Color? closeButtonColor,
    OrionButtonStyle? actionStyle,
    bool? frosted,
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
      titleStyle: titleStyle,
      descriptionStyle: descriptionStyle,
      iconColor: iconColor,
      closeButtonColor: closeButtonColor,
      actionStyle: actionStyle,
      frosted: frosted,
      shadow: shadow,
      mountSpring: mountSpring,
      stackSpring: stackSpring,
      swipeSpring: swipeSpring,
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
        other.titleStyle == titleStyle &&
        other.descriptionStyle == descriptionStyle &&
        other.iconColor == iconColor &&
        other.closeButtonColor == closeButtonColor &&
        other.actionStyle == actionStyle &&
        other.frosted == frosted &&
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
    titleStyle,
    descriptionStyle,
    iconColor,
    closeButtonColor,
    actionStyle,
    frosted,
    mountSpring,
    stackSpring,
    swipeSpring,
  ]);
}
