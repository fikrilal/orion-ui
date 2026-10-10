import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionSlider] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionSliderPresets`, the theme's `OrionSliderTheme`, and the
/// instance style passed to the widget. Every field is nullable; a null field
/// falls through to the layer beneath it, so an override changes exactly what
/// it names.
///
/// The colour fields resolve through the slider's live [WidgetState]s. A
/// slider is always on, so the only state is [WidgetState.disabled] - there is
/// no selected, indeterminate or error look to tint.
@immutable
class OrionSliderStyle {
  const OrionSliderStyle({
    this.trackColor,
    this.fillColor,
    this.thumbColor,
    this.trackHeight,
    this.thumbSize,
    this.radius,
    this.focusOverlayColor,
    this.settleSpring,
    this.liftSpring,
    this.liftScale,
  });

  /// The unfilled track, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? trackColor;

  /// The filled portion, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? fillColor;

  /// The thumb, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? thumbColor;

  /// Thickness of the track.
  final double? trackHeight;

  /// Thumb diameter. The track is inset by half of it, so the thumb centre
  /// reaches both ends, and the hit target stays 44 pt whatever this is.
  final double? thumbSize;

  /// Track corner radius; the default is a pill.
  final BorderRadius? radius;

  /// The focus state layer painted under the thumb. Focus is a translucent
  /// affordance on the surface, not a ring around the thumb.
  final Color? focusOverlayColor;

  /// Spring the release snap and driven value changes ride. Critically damped
  /// by default: a thumb shows an exact value and must never overshoot it.
  final OrionSpringSpec? settleSpring;

  /// Spring the held thumb's lift rides.
  final OrionSpringSpec? liftSpring;

  /// How far the thumb grows while it is held.
  final double? liftScale;

  /// Returns a copy with the provided fields replaced.
  OrionSliderStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? thumbColor,
    double? trackHeight,
    double? thumbSize,
    BorderRadius? radius,
    Color? focusOverlayColor,
    OrionSpringSpec? settleSpring,
    OrionSpringSpec? liftSpring,
    double? liftScale,
  }) {
    return OrionSliderStyle(
      trackColor: trackColor ?? this.trackColor,
      fillColor: fillColor ?? this.fillColor,
      thumbColor: thumbColor ?? this.thumbColor,
      trackHeight: trackHeight ?? this.trackHeight,
      thumbSize: thumbSize ?? this.thumbSize,
      radius: radius ?? this.radius,
      focusOverlayColor: focusOverlayColor ?? this.focusOverlayColor,
      settleSpring: settleSpring ?? this.settleSpring,
      liftSpring: liftSpring ?? this.liftSpring,
      liftScale: liftScale ?? this.liftScale,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionSliderStyle merge(OrionSliderStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionSliderStyle(
      trackColor: other.trackColor ?? trackColor,
      fillColor: other.fillColor ?? fillColor,
      thumbColor: other.thumbColor ?? thumbColor,
      trackHeight: other.trackHeight ?? trackHeight,
      thumbSize: other.thumbSize ?? thumbSize,
      radius: other.radius ?? radius,
      focusOverlayColor: other.focusOverlayColor ?? focusOverlayColor,
      settleSpring: other.settleSpring ?? settleSpring,
      liftSpring: other.liftSpring ?? liftSpring,
      liftScale: other.liftScale ?? liftScale,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionSliderStyle from({
    Color? trackColor,
    Color? fillColor,
    Color? thumbColor,
    double? trackHeight,
    double? thumbSize,
    BorderRadius? radius,
    Color? focusOverlayColor,
    OrionSpringSpec? settleSpring,
    OrionSpringSpec? liftSpring,
    double? liftScale,
  }) {
    return OrionSliderStyle(
      trackColor: trackColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(trackColor),
      fillColor: fillColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(fillColor),
      thumbColor: thumbColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(thumbColor),
      trackHeight: trackHeight,
      thumbSize: thumbSize,
      radius: radius,
      focusOverlayColor: focusOverlayColor,
      settleSpring: settleSpring,
      liftSpring: liftSpring,
      liftScale: liftScale,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSliderStyle &&
        other.trackColor == trackColor &&
        other.fillColor == fillColor &&
        other.thumbColor == thumbColor &&
        other.trackHeight == trackHeight &&
        other.thumbSize == thumbSize &&
        other.radius == radius &&
        other.focusOverlayColor == focusOverlayColor &&
        other.settleSpring == settleSpring &&
        other.liftSpring == liftSpring &&
        other.liftScale == liftScale;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    trackColor,
    fillColor,
    thumbColor,
    trackHeight,
    thumbSize,
    radius,
    focusOverlayColor,
    settleSpring,
    liftSpring,
    liftScale,
  ]);
}
