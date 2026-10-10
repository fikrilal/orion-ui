import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionRadio] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionRadioPresets`, the theme's `OrionRadioTheme`, and the
/// instance style passed to the widget. Every field is nullable; a null field
/// falls through to the layer beneath it, so an override changes exactly what
/// it names.
///
/// The colour fields resolve through the circle's live [WidgetState]s -
/// [WidgetState.disabled], [WidgetState.selected] and [WidgetState.error] -
/// so a skin can tint each state without restating the rest.
@immutable
class OrionRadioStyle {
  const OrionRadioStyle({
    this.ringColor,
    this.dotColor,
    this.fillColor,
    this.size,
    this.dotSize,
    this.borderWidth,
    this.focusOverlayColor,
    this.spring,
  });

  /// The ring, resolved with [WidgetState.disabled], [WidgetState.selected]
  /// and [WidgetState.error].
  final WidgetStateProperty<Color?>? ringColor;

  /// The dot, resolved with the same states.
  final WidgetStateProperty<Color?>? dotColor;

  /// The interior, resolved with the same states. Transparent by default:
  /// the ring-plus-dot is what tells a radio apart from a checkbox.
  final WidgetStateProperty<Color?>? fillColor;

  /// Circle diameter. The 44 pt hit target does not change with it.
  final double? size;

  /// Dot diameter inside the circle.
  final double? dotSize;

  /// Ring width, constant across states.
  final double? borderWidth;

  /// The focus overlay painted under the circle. Focus is a translucent
  /// affordance on the surface, not a second ring.
  final Color? focusOverlayColor;

  /// Spring the selection travel rides. The trip is the whole 0 to 1 change,
  /// so the spec is the gentler travel spring rather than a press release.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionRadioStyle copyWith({
    WidgetStateProperty<Color?>? ringColor,
    WidgetStateProperty<Color?>? dotColor,
    WidgetStateProperty<Color?>? fillColor,
    double? size,
    double? dotSize,
    double? borderWidth,
    Color? focusOverlayColor,
    OrionSpringSpec? spring,
  }) {
    return OrionRadioStyle(
      ringColor: ringColor ?? this.ringColor,
      dotColor: dotColor ?? this.dotColor,
      fillColor: fillColor ?? this.fillColor,
      size: size ?? this.size,
      dotSize: dotSize ?? this.dotSize,
      borderWidth: borderWidth ?? this.borderWidth,
      focusOverlayColor: focusOverlayColor ?? this.focusOverlayColor,
      spring: spring ?? this.spring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionRadioStyle merge(OrionRadioStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionRadioStyle(
      ringColor: other.ringColor ?? ringColor,
      dotColor: other.dotColor ?? dotColor,
      fillColor: other.fillColor ?? fillColor,
      size: other.size ?? size,
      dotSize: other.dotSize ?? dotSize,
      borderWidth: other.borderWidth ?? borderWidth,
      focusOverlayColor: other.focusOverlayColor ?? focusOverlayColor,
      spring: other.spring ?? spring,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionRadioStyle from({
    Color? ringColor,
    Color? dotColor,
    Color? fillColor,
    double? size,
    double? dotSize,
    double? borderWidth,
    Color? focusOverlayColor,
    OrionSpringSpec? spring,
  }) {
    return OrionRadioStyle(
      ringColor: ringColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(ringColor),
      dotColor: dotColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(dotColor),
      fillColor: fillColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(fillColor),
      size: size,
      dotSize: dotSize,
      borderWidth: borderWidth,
      focusOverlayColor: focusOverlayColor,
      spring: spring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionRadioStyle &&
        other.ringColor == ringColor &&
        other.dotColor == dotColor &&
        other.fillColor == fillColor &&
        other.size == size &&
        other.dotSize == dotSize &&
        other.borderWidth == borderWidth &&
        other.focusOverlayColor == focusOverlayColor &&
        other.spring == spring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    ringColor,
    dotColor,
    fillColor,
    size,
    dotSize,
    borderWidth,
    focusOverlayColor,
    spring,
  ]);
}
