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
    this.focusRingColor,
    this.focusRingWidth,
    this.disabledOpacity,
    this.iconColor,
    this.expandSpring,
    this.collapseSpring,
  });

  /// The header's inner padding.
  final EdgeInsetsGeometry? headerPadding;

  /// The focus ring's colour. The ring is drawn over the header, so showing
  /// focus never moves the content the caller put there.
  final Color? focusRingColor;

  /// The focus ring's width.
  final double? focusRingWidth;

  /// How far a disabled row's header is dimmed.
  final double? disabledOpacity;

  /// The default chevron's colour; null keeps the ambient icon theme.
  final Color? iconColor;

  /// Spring the reveal rides when the panel opens. The gentle default lets the
  /// panel settle a hair taller than its content for a frame or two, matching
  /// the chip's check and the checkbox's mark.
  final OrionSpringSpec? expandSpring;

  /// Spring the collapse rides. Closing is a collapse, not a reveal run
  /// backwards: the default is critically damped and clamped so a shut panel
  /// never bounces and the clip never grows past the content it reveals.
  final OrionSpringSpec? collapseSpring;

  /// Returns a copy with the provided fields replaced.
  OrionAccordionStyle copyWith({
    EdgeInsetsGeometry? headerPadding,
    Color? focusRingColor,
    double? focusRingWidth,
    double? disabledOpacity,
    Color? iconColor,
    OrionSpringSpec? expandSpring,
    OrionSpringSpec? collapseSpring,
  }) {
    return OrionAccordionStyle(
      headerPadding: headerPadding ?? this.headerPadding,
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
    Color? focusRingColor,
    double? focusRingWidth,
    double? disabledOpacity,
    Color? iconColor,
    OrionSpringSpec? expandSpring,
    OrionSpringSpec? collapseSpring,
  }) {
    return OrionAccordionStyle(
      headerPadding: headerPadding,
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
    focusRingColor,
    focusRingWidth,
    disabledOpacity,
    iconColor,
    expandSpring,
    collapseSpring,
  ]);
}
