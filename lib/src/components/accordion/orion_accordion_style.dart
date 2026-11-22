import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionAccordion] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionAccordionPresets`, the theme's `OrionAccordionTheme`, and
/// the instance style passed to the widget. Every field is nullable; a null
/// field falls through to the layer beneath it, so an override changes exactly
/// what it names.
///
/// The fields are plain values, not [WidgetStateProperty]: the row's only
/// state is disabled, and disabled is an opacity over arbitrary host content
/// rather than a recolour.
@immutable
class OrionAccordionStyle {
  const OrionAccordionStyle({
    this.headerPadding,
    this.contentPadding,
    this.pressedScale,
    this.headerPressedColor,
    this.headerHoverColor,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.focusRingColor,
    this.focusRingWidth,
    this.disabledOpacity,
    this.iconColor,
    this.expandSpring,
    this.collapseSpring,
  });

  /// The header's inner padding.
  final EdgeInsetsGeometry? headerPadding;

  /// The panel's content padding. Defaults to matching the header's horizontal
  /// inset with bottom breathing room so the header text and expanded content
  /// share a single vertical alignment axis without crowding the bottom edge.
  final EdgeInsetsGeometry? contentPadding;

  /// Scale factor applied during header press. Defaults to 1.0 (no text
  /// shrinking on full-width disclosure rows; press feedback is carried by
  /// [headerPressedColor]).
  final double? pressedScale;

  /// Subtle wash painted behind the header while pressed.
  final Color? headerPressedColor;

  /// Subtle wash painted behind the header while hovered.
  final Color? headerHoverColor;

  /// Optional card container background color. Null renders as a quiet
  /// borderless row.
  final Color? backgroundColor;

  /// Optional card container border color.
  final Color? borderColor;

  /// Container border width.
  final double? borderWidth;

  /// Container border radius.
  final BorderRadius? borderRadius;

  /// The focus ring's colour. The ring is drawn over the header, so showing
  /// focus never moves the content the caller put there.
  final Color? focusRingColor;

  /// The focus ring's width.
  final double? focusRingWidth;

  /// How far a disabled row's header is dimmed.
  final double? disabledOpacity;

  /// The default chevron's colour; null keeps the ambient icon theme.
  final Color? iconColor;

  /// Spring the reveal rides when the panel opens. Critically damped and
  /// clamped by default so the panel settles cleanly without pushing sibling
  /// rows past their resting position.
  final OrionSpringSpec? expandSpring;

  /// Spring the collapse rides. Critically damped and clamped so a shut panel
  /// closes crisply without bouncing.
  final OrionSpringSpec? collapseSpring;

  /// Returns a copy with the provided fields replaced.
  OrionAccordionStyle copyWith({
    EdgeInsetsGeometry? headerPadding,
    EdgeInsetsGeometry? contentPadding,
    double? pressedScale,
    Color? headerPressedColor,
    Color? headerHoverColor,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? focusRingColor,
    double? focusRingWidth,
    double? disabledOpacity,
    Color? iconColor,
    OrionSpringSpec? expandSpring,
    OrionSpringSpec? collapseSpring,
  }) {
    return OrionAccordionStyle(
      headerPadding: headerPadding ?? this.headerPadding,
      contentPadding: contentPadding ?? this.contentPadding,
      pressedScale: pressedScale ?? this.pressedScale,
      headerPressedColor: headerPressedColor ?? this.headerPressedColor,
      headerHoverColor: headerHoverColor ?? this.headerHoverColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      disabledOpacity: disabledOpacity ?? this.disabledOpacity,
      iconColor: iconColor ?? this.iconColor,
      expandSpring: expandSpring ?? this.expandSpring,
      collapseSpring: collapseSpring ?? this.collapseSpring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionAccordionStyle merge(OrionAccordionStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionAccordionStyle(
      headerPadding: other.headerPadding ?? headerPadding,
      contentPadding: other.contentPadding ?? contentPadding,
      pressedScale: other.pressedScale ?? pressedScale,
      headerPressedColor: other.headerPressedColor ?? headerPressedColor,
      headerHoverColor: other.headerHoverColor ?? headerHoverColor,
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      disabledOpacity: other.disabledOpacity ?? disabledOpacity,
      iconColor: other.iconColor ?? iconColor,
      expandSpring: other.expandSpring ?? expandSpring,
      collapseSpring: other.collapseSpring ?? collapseSpring,
    );
  }

  /// Builds a style from plain values.
  static OrionAccordionStyle from({
    EdgeInsetsGeometry? headerPadding,
    EdgeInsetsGeometry? contentPadding,
    double? pressedScale,
    Color? headerPressedColor,
    Color? headerHoverColor,
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    Color? focusRingColor,
    double? focusRingWidth,
    double? disabledOpacity,
    Color? iconColor,
    OrionSpringSpec? expandSpring,
    OrionSpringSpec? collapseSpring,
  }) {
    return OrionAccordionStyle(
      headerPadding: headerPadding,
      contentPadding: contentPadding,
      pressedScale: pressedScale,
      headerPressedColor: headerPressedColor,
      headerHoverColor: headerHoverColor,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      focusRingColor: focusRingColor,
      focusRingWidth: focusRingWidth,
      disabledOpacity: disabledOpacity,
      iconColor: iconColor,
      expandSpring: expandSpring,
      collapseSpring: collapseSpring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionAccordionStyle &&
        other.headerPadding == headerPadding &&
        other.contentPadding == contentPadding &&
        other.pressedScale == pressedScale &&
        other.headerPressedColor == headerPressedColor &&
        other.headerHoverColor == headerHoverColor &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.focusRingColor == focusRingColor &&
        other.focusRingWidth == focusRingWidth &&
        other.disabledOpacity == disabledOpacity &&
        other.iconColor == iconColor &&
        other.expandSpring == expandSpring &&
        other.collapseSpring == collapseSpring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    headerPadding,
    contentPadding,
    pressedScale,
    headerPressedColor,
    headerHoverColor,
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    focusRingColor,
    focusRingWidth,
    disabledOpacity,
    iconColor,
    expandSpring,
    collapseSpring,
  ]);
}
