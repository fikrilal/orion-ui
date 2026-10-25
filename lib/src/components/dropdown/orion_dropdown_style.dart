import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The face of the dropdown trigger.
///
/// The variants mirror [OrionTextFieldVariant] so a dropdown sits beside a text
/// field without a visual seam.
enum OrionDropdownVariant {
  /// Border on every edge, surface fill.
  outline,

  /// Filled container, border only on focus.
  filled,

  /// Bottom hairline only.
  underline,
}

/// The size step of the trigger face.
enum OrionDropdownSize { small, medium, large }

/// The visual and physical styling contract for [OrionDropdown].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionDropdownPresets`, the ambient `OrionDropdownTheme`, and the
/// instance style passed to the component.
@immutable
class OrionDropdownStyle {
  const OrionDropdownStyle({
    this.fillColor,
    this.borderColor,
    this.borderWidth,
    this.textColor,
    this.hintColor,
    this.height,
    this.padding,
    this.radius,
    this.labelGap,
    this.captionGap,
    this.textStyle,
    this.labelStyle,
    this.captionStyle,
    this.iconSize,
    this.chevronColor,
    this.panelColor,
    this.panelBorderColor,
    this.panelBorderWidth,
    this.panelBorderRadius,
    this.panelShadow,
    this.panelPadding,
    this.panelGap,
    this.panelMaxWidth,
    this.panelMaxHeight,
    this.rowMinHeight,
    this.rowPadding,
    this.rowTitleStyle,
    this.rowDescriptionStyle,
    this.labelColor,
    this.selectedLabelColor,
    this.descriptionColor,
    this.activeRowColor,
    this.activeRowRadius,
    this.checkColor,
    this.springSpec,
    this.separationSpringSpec,
    this.dismissSpringSpec,
    this.highlightSpringSpec,
    this.pressScale,
    this.pressSpring,
    this.releaseSpring,
    this.hapticType,
  });

  /// Trigger face fill, resolved through `WidgetState` (disabled, error).
  final WidgetStateProperty<Color?>? fillColor;

  /// Trigger face border, resolved through `WidgetState` (focused, disabled,
  /// error). Focus steps the line to the resolved focused color.
  final WidgetStateProperty<Color?>? borderColor;

  /// Resting border width. Focus adds half a point on the clamped spring.
  final double? borderWidth;

  /// Trigger label color, resolved through `WidgetState`.
  final WidgetStateProperty<Color?>? textColor;

  /// Placeholder color, resolved through `WidgetState`.
  final WidgetStateProperty<Color?>? hintColor;

  /// Minimum trigger height (the face is at least this tall).
  final double? height;

  /// Internal horizontal padding of the trigger face.
  final EdgeInsetsGeometry? padding;

  /// Trigger corner radius. The edge that faces the panel is pinched flat while
  /// the panel is attached, whatever this value says.
  final BorderRadius? radius;

  /// Gap between the field label and the face.
  final double? labelGap;

  /// Gap between the face and the caption row.
  final double? captionGap;

  /// Label and selected-value text style.
  final TextStyle? textStyle;

  /// Style of the label above the face.
  final TextStyle? labelStyle;

  /// Style of the helper/error caption below the face.
  final TextStyle? captionStyle;

  /// Size of the option leading icons and the trailing check.
  final double? iconSize;

  /// Color of the trailing chevron.
  final Color? chevronColor;

  /// Panel surface color.
  final Color? panelColor;

  /// Panel border color.
  final Color? panelBorderColor;

  /// Panel border width.
  final double? panelBorderWidth;

  /// Panel corner radius. The edge facing the field starts flat and rounds as
  /// the panel separates.
  final BorderRadius? panelBorderRadius;

  /// Panel elevation shadow, faded in as the panel separates.
  final List<BoxShadow>? panelShadow;

  /// Internal panel padding around the option list.
  final EdgeInsetsGeometry? panelPadding;

  /// Final gap between the field and the separated panel.
  final double? panelGap;

  /// Upper bound of the panel width (the panel matches the field up to this).
  final double? panelMaxWidth;

  /// Upper bound of the panel height; the option list scrolls beyond it.
  final double? panelMaxHeight;

  /// Minimum height of an option row (the 44 pt touch target floor).
  final double? rowMinHeight;

  /// Internal padding of an option row.
  final EdgeInsetsGeometry? rowPadding;

  /// Option title style.
  final TextStyle? rowTitleStyle;

  /// Option description style.
  final TextStyle? rowDescriptionStyle;

  /// Title color of an unselected, enabled option.
  final Color? labelColor;

  /// Title color of the selected option.
  final Color? selectedLabelColor;

  /// Description color of an enabled option.
  final Color? descriptionColor;

  /// Fill of the gliding highlight that follows the keyboard or pointer cursor.
  final Color? activeRowColor;

  /// Corner radius of the gliding highlight.
  final BorderRadius? activeRowRadius;

  /// Color of the selected option's trailing check.
  final Color? checkColor;

  /// Spring governing the unfold of the panel extent (a layout edge, so it is
  /// clamped and never passes its target).
  final OrionSpringSpec? springSpec;

  /// Spring governing the separation: the gap opening and the facing edges
  /// rounding back out.
  final OrionSpringSpec? separationSpringSpec;

  /// Spring governing the dismissal of both the separation and the extent.
  final OrionSpringSpec? dismissSpringSpec;

  /// Spring governing the gliding highlight as the active option moves.
  final OrionSpringSpec? highlightSpringSpec;

  /// Micro-scale applied to an option row under a finger.
  final double? pressScale;

  /// Spring governing row compression on pointer down.
  final OrionSpringSpec? pressSpring;

  /// Spring governing row release on pointer up.
  final OrionSpringSpec? releaseSpring;

  /// Tactile feedback for opening and for committing a changed value.
  final OrionHapticType? hapticType;

  /// Convenience factory creating a style with only named properties.
  factory OrionDropdownStyle.from({
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? borderColor,
    double? borderWidth,
    WidgetStateProperty<Color?>? textColor,
    WidgetStateProperty<Color?>? hintColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? labelGap,
    double? captionGap,
    TextStyle? textStyle,
    TextStyle? labelStyle,
    TextStyle? captionStyle,
    double? iconSize,
    Color? chevronColor,
    Color? panelColor,
    Color? panelBorderColor,
    double? panelBorderWidth,
    BorderRadius? panelBorderRadius,
    List<BoxShadow>? panelShadow,
    EdgeInsetsGeometry? panelPadding,
    double? panelGap,
    double? panelMaxWidth,
    double? panelMaxHeight,
    double? rowMinHeight,
    EdgeInsetsGeometry? rowPadding,
    TextStyle? rowTitleStyle,
    TextStyle? rowDescriptionStyle,
    Color? labelColor,
    Color? selectedLabelColor,
    Color? descriptionColor,
    Color? activeRowColor,
    BorderRadius? activeRowRadius,
    Color? checkColor,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? separationSpringSpec,
    OrionSpringSpec? dismissSpringSpec,
    OrionSpringSpec? highlightSpringSpec,
    double? pressScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionDropdownStyle(
      fillColor: fillColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      textColor: textColor,
      hintColor: hintColor,
      height: height,
      padding: padding,
      radius: radius,
      labelGap: labelGap,
      captionGap: captionGap,
      textStyle: textStyle,
      labelStyle: labelStyle,
      captionStyle: captionStyle,
      iconSize: iconSize,
      chevronColor: chevronColor,
      panelColor: panelColor,
      panelBorderColor: panelBorderColor,
      panelBorderWidth: panelBorderWidth,
      panelBorderRadius: panelBorderRadius,
      panelShadow: panelShadow,
      panelPadding: panelPadding,
      panelGap: panelGap,
      panelMaxWidth: panelMaxWidth,
      panelMaxHeight: panelMaxHeight,
      rowMinHeight: rowMinHeight,
      rowPadding: rowPadding,
      rowTitleStyle: rowTitleStyle,
      rowDescriptionStyle: rowDescriptionStyle,
      labelColor: labelColor,
      selectedLabelColor: selectedLabelColor,
      descriptionColor: descriptionColor,
      activeRowColor: activeRowColor,
      activeRowRadius: activeRowRadius,
      checkColor: checkColor,
      springSpec: springSpec,
      separationSpringSpec: separationSpringSpec,
      dismissSpringSpec: dismissSpringSpec,
      highlightSpringSpec: highlightSpringSpec,
      pressScale: pressScale,
      pressSpring: pressSpring,
      releaseSpring: releaseSpring,
      hapticType: hapticType,
    );
  }

  /// Returns a copy with the provided fields replaced.
  OrionDropdownStyle copyWith({
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? borderColor,
    double? borderWidth,
    WidgetStateProperty<Color?>? textColor,
    WidgetStateProperty<Color?>? hintColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? labelGap,
    double? captionGap,
    TextStyle? textStyle,
    TextStyle? labelStyle,
    TextStyle? captionStyle,
    double? iconSize,
    Color? chevronColor,
    Color? panelColor,
    Color? panelBorderColor,
    double? panelBorderWidth,
    BorderRadius? panelBorderRadius,
    List<BoxShadow>? panelShadow,
    EdgeInsetsGeometry? panelPadding,
    double? panelGap,
    double? panelMaxWidth,
    double? panelMaxHeight,
    double? rowMinHeight,
    EdgeInsetsGeometry? rowPadding,
    TextStyle? rowTitleStyle,
    TextStyle? rowDescriptionStyle,
    Color? labelColor,
    Color? selectedLabelColor,
    Color? descriptionColor,
    Color? activeRowColor,
    BorderRadius? activeRowRadius,
    Color? checkColor,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? separationSpringSpec,
    OrionSpringSpec? dismissSpringSpec,
    OrionSpringSpec? highlightSpringSpec,
    double? pressScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionDropdownStyle(
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      textColor: textColor ?? this.textColor,
      hintColor: hintColor ?? this.hintColor,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
      labelGap: labelGap ?? this.labelGap,
      captionGap: captionGap ?? this.captionGap,
      textStyle: textStyle ?? this.textStyle,
      labelStyle: labelStyle ?? this.labelStyle,
      captionStyle: captionStyle ?? this.captionStyle,
      iconSize: iconSize ?? this.iconSize,
      chevronColor: chevronColor ?? this.chevronColor,
      panelColor: panelColor ?? this.panelColor,
      panelBorderColor: panelBorderColor ?? this.panelBorderColor,
      panelBorderWidth: panelBorderWidth ?? this.panelBorderWidth,
      panelBorderRadius: panelBorderRadius ?? this.panelBorderRadius,
      panelShadow: panelShadow ?? this.panelShadow,
      panelPadding: panelPadding ?? this.panelPadding,
      panelGap: panelGap ?? this.panelGap,
      panelMaxWidth: panelMaxWidth ?? this.panelMaxWidth,
      panelMaxHeight: panelMaxHeight ?? this.panelMaxHeight,
      rowMinHeight: rowMinHeight ?? this.rowMinHeight,
      rowPadding: rowPadding ?? this.rowPadding,
      rowTitleStyle: rowTitleStyle ?? this.rowTitleStyle,
      rowDescriptionStyle: rowDescriptionStyle ?? this.rowDescriptionStyle,
      labelColor: labelColor ?? this.labelColor,
      selectedLabelColor: selectedLabelColor ?? this.selectedLabelColor,
      descriptionColor: descriptionColor ?? this.descriptionColor,
      activeRowColor: activeRowColor ?? this.activeRowColor,
      activeRowRadius: activeRowRadius ?? this.activeRowRadius,
      checkColor: checkColor ?? this.checkColor,
      springSpec: springSpec ?? this.springSpec,
      separationSpringSpec: separationSpringSpec ?? this.separationSpringSpec,
      dismissSpringSpec: dismissSpringSpec ?? this.dismissSpringSpec,
      highlightSpringSpec: highlightSpringSpec ?? this.highlightSpringSpec,
      pressScale: pressScale ?? this.pressScale,
      pressSpring: pressSpring ?? this.pressSpring,
      releaseSpring: releaseSpring ?? this.releaseSpring,
      hapticType: hapticType ?? this.hapticType,
    );
  }

  /// Merges this style with [other], where [other]'s non-null fields win.
  OrionDropdownStyle merge(OrionDropdownStyle? other) {
    if (other == null) return this;
    return copyWith(
      fillColor: other.fillColor,
      borderColor: other.borderColor,
      borderWidth: other.borderWidth,
      textColor: other.textColor,
      hintColor: other.hintColor,
      height: other.height,
      padding: other.padding,
      radius: other.radius,
      labelGap: other.labelGap,
      captionGap: other.captionGap,
      textStyle: other.textStyle,
      labelStyle: other.labelStyle,
      captionStyle: other.captionStyle,
      iconSize: other.iconSize,
      chevronColor: other.chevronColor,
      panelColor: other.panelColor,
      panelBorderColor: other.panelBorderColor,
      panelBorderWidth: other.panelBorderWidth,
      panelBorderRadius: other.panelBorderRadius,
      panelShadow: other.panelShadow,
      panelPadding: other.panelPadding,
      panelGap: other.panelGap,
      panelMaxWidth: other.panelMaxWidth,
      panelMaxHeight: other.panelMaxHeight,
      rowMinHeight: other.rowMinHeight,
      rowPadding: other.rowPadding,
      rowTitleStyle: other.rowTitleStyle,
      rowDescriptionStyle: other.rowDescriptionStyle,
      labelColor: other.labelColor,
      selectedLabelColor: other.selectedLabelColor,
      descriptionColor: other.descriptionColor,
      activeRowColor: other.activeRowColor,
      activeRowRadius: other.activeRowRadius,
      checkColor: other.checkColor,
      springSpec: other.springSpec,
      separationSpringSpec: other.separationSpringSpec,
      dismissSpringSpec: other.dismissSpringSpec,
      highlightSpringSpec: other.highlightSpringSpec,
      pressScale: other.pressScale,
      pressSpring: other.pressSpring,
      releaseSpring: other.releaseSpring,
      hapticType: other.hapticType,
    );
  }

  /// Linearly interpolates between two [OrionDropdownStyle] instances.
  ///
  /// Springs, haptics, and state-resolved color functions cannot blend; they
  /// swap at the midpoint.
  static OrionDropdownStyle? lerp(
    OrionDropdownStyle? a,
    OrionDropdownStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null) return b;
    if (b == null) return a;
    return OrionDropdownStyle(
      fillColor: t < 0.5 ? a.fillColor : b.fillColor,
      borderColor: t < 0.5 ? a.borderColor : b.borderColor,
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t),
      textColor: t < 0.5 ? a.textColor : b.textColor,
      hintColor: t < 0.5 ? a.hintColor : b.hintColor,
      height: lerpDouble(a.height, b.height, t),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      radius: BorderRadius.lerp(a.radius, b.radius, t),
      labelGap: lerpDouble(a.labelGap, b.labelGap, t),
      captionGap: lerpDouble(a.captionGap, b.captionGap, t),
      textStyle: TextStyle.lerp(a.textStyle, b.textStyle, t),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      captionStyle: TextStyle.lerp(a.captionStyle, b.captionStyle, t),
      iconSize: lerpDouble(a.iconSize, b.iconSize, t),
      chevronColor: Color.lerp(a.chevronColor, b.chevronColor, t),
      panelColor: Color.lerp(a.panelColor, b.panelColor, t),
      panelBorderColor: Color.lerp(a.panelBorderColor, b.panelBorderColor, t),
      panelBorderWidth: lerpDouble(a.panelBorderWidth, b.panelBorderWidth, t),
      panelBorderRadius: BorderRadius.lerp(
        a.panelBorderRadius,
        b.panelBorderRadius,
        t,
      ),
      panelShadow: BoxShadow.lerpList(a.panelShadow, b.panelShadow, t),
      panelPadding: EdgeInsetsGeometry.lerp(a.panelPadding, b.panelPadding, t),
      panelGap: lerpDouble(a.panelGap, b.panelGap, t),
      panelMaxWidth: lerpDouble(a.panelMaxWidth, b.panelMaxWidth, t),
      panelMaxHeight: lerpDouble(a.panelMaxHeight, b.panelMaxHeight, t),
      rowMinHeight: lerpDouble(a.rowMinHeight, b.rowMinHeight, t),
      rowPadding: EdgeInsetsGeometry.lerp(a.rowPadding, b.rowPadding, t),
      rowTitleStyle: TextStyle.lerp(a.rowTitleStyle, b.rowTitleStyle, t),
      rowDescriptionStyle: TextStyle.lerp(
        a.rowDescriptionStyle,
        b.rowDescriptionStyle,
        t,
      ),
      labelColor: Color.lerp(a.labelColor, b.labelColor, t),
      selectedLabelColor: Color.lerp(
        a.selectedLabelColor,
        b.selectedLabelColor,
        t,
      ),
      descriptionColor: Color.lerp(a.descriptionColor, b.descriptionColor, t),
      activeRowColor: Color.lerp(a.activeRowColor, b.activeRowColor, t),
      activeRowRadius: BorderRadius.lerp(
        a.activeRowRadius,
        b.activeRowRadius,
        t,
      ),
      checkColor: Color.lerp(a.checkColor, b.checkColor, t),
      springSpec: t < 0.5 ? a.springSpec : b.springSpec,
      separationSpringSpec: t < 0.5
          ? a.separationSpringSpec
          : b.separationSpringSpec,
      dismissSpringSpec: t < 0.5 ? a.dismissSpringSpec : b.dismissSpringSpec,
      highlightSpringSpec: t < 0.5
          ? a.highlightSpringSpec
          : b.highlightSpringSpec,
      pressScale: lerpDouble(a.pressScale, b.pressScale, t),
      pressSpring: t < 0.5 ? a.pressSpring : b.pressSpring,
      releaseSpring: t < 0.5 ? a.releaseSpring : b.releaseSpring,
      hapticType: t < 0.5 ? a.hapticType : b.hapticType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrionDropdownStyle &&
          runtimeType == other.runtimeType &&
          fillColor == other.fillColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          textColor == other.textColor &&
          hintColor == other.hintColor &&
          height == other.height &&
          padding == other.padding &&
          radius == other.radius &&
          labelGap == other.labelGap &&
          captionGap == other.captionGap &&
          textStyle == other.textStyle &&
          labelStyle == other.labelStyle &&
          captionStyle == other.captionStyle &&
          iconSize == other.iconSize &&
          chevronColor == other.chevronColor &&
          panelColor == other.panelColor &&
          panelBorderColor == other.panelBorderColor &&
          panelBorderWidth == other.panelBorderWidth &&
          panelBorderRadius == other.panelBorderRadius &&
          listEquals(panelShadow, other.panelShadow) &&
          panelPadding == other.panelPadding &&
          panelGap == other.panelGap &&
          panelMaxWidth == other.panelMaxWidth &&
          panelMaxHeight == other.panelMaxHeight &&
          rowMinHeight == other.rowMinHeight &&
          rowPadding == other.rowPadding &&
          rowTitleStyle == other.rowTitleStyle &&
          rowDescriptionStyle == other.rowDescriptionStyle &&
          labelColor == other.labelColor &&
          selectedLabelColor == other.selectedLabelColor &&
          descriptionColor == other.descriptionColor &&
          activeRowColor == other.activeRowColor &&
          activeRowRadius == other.activeRowRadius &&
          checkColor == other.checkColor &&
          springSpec == other.springSpec &&
          separationSpringSpec == other.separationSpringSpec &&
          dismissSpringSpec == other.dismissSpringSpec &&
          highlightSpringSpec == other.highlightSpringSpec &&
          pressScale == other.pressScale &&
          pressSpring == other.pressSpring &&
          releaseSpring == other.releaseSpring &&
          hapticType == other.hapticType;

  @override
  int get hashCode => Object.hashAll([
    fillColor,
    borderColor,
    borderWidth,
    textColor,
    hintColor,
    height,
    padding,
    radius,
    labelGap,
    captionGap,
    textStyle,
    labelStyle,
    captionStyle,
    iconSize,
    chevronColor,
    panelColor,
    panelBorderColor,
    panelBorderWidth,
    panelBorderRadius,
    panelShadow == null ? null : Object.hashAll(panelShadow!),
    panelPadding,
    panelGap,
    panelMaxWidth,
    panelMaxHeight,
    rowMinHeight,
    rowPadding,
    rowTitleStyle,
    rowDescriptionStyle,
    labelColor,
    selectedLabelColor,
    descriptionColor,
    activeRowColor,
    activeRowRadius,
    checkColor,
    springSpec,
    separationSpringSpec,
    dismissSpringSpec,
    highlightSpringSpec,
    pressScale,
    pressSpring,
    releaseSpring,
    hapticType,
  ]);
}
