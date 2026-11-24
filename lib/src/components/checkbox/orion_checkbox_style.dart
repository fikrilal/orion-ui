import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionCheckbox] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionCheckboxPresets`, the theme's `OrionCheckboxTheme`, and the
/// instance style passed to the widget. Every field is nullable; a null field
/// falls through to the layer beneath it, so an override changes exactly what
/// it names.
///
/// The colour fields resolve through the box's live [WidgetState]s -
/// [WidgetState.disabled], [WidgetState.selected] and [WidgetState.error] -
/// so a skin can tint each state without restating the rest.
@immutable
class OrionCheckboxStyle {
  const OrionCheckboxStyle({
    this.fillColor,
    this.borderColor,
    this.markColor,
    this.size,
    this.radius,
    this.borderWidth,
    this.markSize,
    this.barWidth,
    this.barHeight,
    this.pressedScale,
    this.focusOverlayColor,
    this.spring,
  });

  /// Box fill, resolved with [WidgetState.disabled], [WidgetState.selected]
  /// and [WidgetState.error]. An unchecked box is transparent whatever the
  /// state, so the border carries it.
  final WidgetStateProperty<Color?>? fillColor;

  /// Border colour, resolved with the same states.
  final WidgetStateProperty<Color?>? borderColor;

  /// Mark colour (the check, or the indeterminate bar), resolved with the
  /// same states.
  final WidgetStateProperty<Color?>? markColor;

  /// Box dimension. The 44 pt hit target does not change with it.
  final double? size;

  /// Box corner radius.
  final BorderRadius? radius;

  /// Border width, constant across states.
  final double? borderWidth;

  /// Check glyph size inside the box.
  final double? markSize;

  /// Indeterminate bar length.
  final double? barWidth;

  /// Indeterminate bar thickness.
  final double? barHeight;

  /// Target scale while the checkbox is held down (default 0.90 for a crisp
  /// micro-tactile dip on the compact box).
  final double? pressedScale;

  /// The focus overlay painted under the box. Focus is a translucent
  /// affordance on the surface, not a second border.
  final Color? focusOverlayColor;

  /// Spring the state travel rides.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionCheckboxStyle copyWith({
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<Color?>? markColor,
    double? size,
    BorderRadius? radius,
    double? borderWidth,
    double? markSize,
    double? barWidth,
    double? barHeight,
    double? pressedScale,
    Color? focusOverlayColor,
    OrionSpringSpec? spring,
  }) {
    return OrionCheckboxStyle(
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      markColor: markColor ?? this.markColor,
      size: size ?? this.size,
      radius: radius ?? this.radius,
      borderWidth: borderWidth ?? this.borderWidth,
      markSize: markSize ?? this.markSize,
      barWidth: barWidth ?? this.barWidth,
      barHeight: barHeight ?? this.barHeight,
      pressedScale: pressedScale ?? this.pressedScale,
      focusOverlayColor: focusOverlayColor ?? this.focusOverlayColor,
      spring: spring ?? this.spring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionCheckboxStyle merge(OrionCheckboxStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionCheckboxStyle(
      fillColor: other.fillColor ?? fillColor,
      borderColor: other.borderColor ?? borderColor,
      markColor: other.markColor ?? markColor,
      size: other.size ?? size,
      radius: other.radius ?? radius,
      borderWidth: other.borderWidth ?? borderWidth,
      markSize: other.markSize ?? markSize,
      barWidth: other.barWidth ?? barWidth,
      barHeight: other.barHeight ?? barHeight,
      pressedScale: other.pressedScale ?? pressedScale,
      focusOverlayColor: other.focusOverlayColor ?? focusOverlayColor,
      spring: other.spring ?? spring,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  /// [fillColor] is the one exception: it is the selected fill, and every
  /// other state stays transparent, so an unchecked box never fills. A
  /// resting fill needs the state-resolved constructor.
  static OrionCheckboxStyle from({
    Color? fillColor,
    Color? borderColor,
    Color? markColor,
    double? size,
    BorderRadius? radius,
    double? borderWidth,
    double? markSize,
    double? barWidth,
    double? barHeight,
    double? pressedScale,
    Color? focusOverlayColor,
    OrionSpringSpec? spring,
  }) {
    return OrionCheckboxStyle(
      fillColor: fillColor == null
          ? null
          : WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? fillColor
                  : Colors.transparent,
            ),
      borderColor: borderColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(borderColor),
      markColor: markColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(markColor),
      size: size,
      radius: radius,
      borderWidth: borderWidth,
      markSize: markSize,
      barWidth: barWidth,
      barHeight: barHeight,
      pressedScale: pressedScale,
      focusOverlayColor: focusOverlayColor,
      spring: spring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCheckboxStyle &&
        other.fillColor == fillColor &&
        other.borderColor == borderColor &&
        other.markColor == markColor &&
        other.size == size &&
        other.radius == radius &&
        other.borderWidth == borderWidth &&
        other.markSize == markSize &&
        other.barWidth == barWidth &&
        other.barHeight == barHeight &&
        other.pressedScale == pressedScale &&
        other.focusOverlayColor == focusOverlayColor &&
        other.spring == spring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    fillColor,
    borderColor,
    markColor,
    size,
    radius,
    borderWidth,
    markSize,
    barWidth,
    barHeight,
    pressedScale,
    focusOverlayColor,
    spring,
  ]);
}
