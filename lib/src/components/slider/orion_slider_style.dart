import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// When a slider displays its floating value bubble above the thumb.
enum OrionSliderValueIndicator {
  /// Never show a floating value bubble. The default.
  never,

  /// Fade and scale the value bubble in while dragging a thumb.
  onDrag,

  /// Keep the value bubble visible continuously above the thumb.
  always,
}

/// The overridable contract for how [OrionSlider] and `OrionRangeSlider` look
/// and move.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionSliderPresets`, the theme's `OrionSliderTheme`, and the
/// instance style passed to the widget. Every field is nullable; a null field
/// falls through to the layer beneath it, so an override changes exactly what
/// it names.
///
/// The colour fields resolve through the slider's live [WidgetState]s -
/// [WidgetState.disabled], [WidgetState.hovered], and [WidgetState.dragged].
@immutable
class OrionSliderStyle {
  const OrionSliderStyle({
    this.trackColor,
    this.fillColor,
    this.thumbColor,
    this.thumbBorder,
    this.thumbShadow,
    this.activeTickColor,
    this.inactiveTickColor,
    this.trackHeight,
    this.thumbSize,
    this.radius,
    this.focusOverlayColor,
    this.hoverOverlayColor,
    this.valueIndicatorColor,
    this.valueIndicatorTextColor,
    this.valueIndicatorTextStyle,
    this.settleSpring,
    this.liftSpring,
    this.liftScale,
    this.hapticType,
  });

  /// The unfilled track, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? trackColor;

  /// The filled portion, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? fillColor;

  /// The thumb, resolved with [WidgetState.disabled], [WidgetState.hovered],
  /// and [WidgetState.dragged].
  final WidgetStateProperty<Color?>? thumbColor;

  /// Optional hairline or ring border drawn around the thumb.
  final BorderSide? thumbBorder;

  /// Optional elevation shadows beneath the thumb. Null by default.
  final List<BoxShadow>? thumbShadow;

  /// Dot colour for discrete step ticks painted inside the active filled span.
  final Color? activeTickColor;

  /// Dot colour for discrete step ticks painted on the inactive track.
  final Color? inactiveTickColor;

  /// Thickness of the track.
  final double? trackHeight;

  /// Thumb diameter. The track is inset by half of it so the thumb centre
  /// reaches both ends, and the hit target stays at least 44 pt.
  final double? thumbSize;

  /// Track corner radius; the default is a pill.
  final BorderRadius? radius;

  /// The focus state layer painted under the thumb. Focus is a translucent
  /// affordance on the surface, not a ring around the thumb.
  final Color? focusOverlayColor;

  /// The hover state layer painted under the thumb while a pointer rests over
  /// the slider.
  final Color? hoverOverlayColor;

  /// Background colour of the floating value tooltip bubble.
  final Color? valueIndicatorColor;

  /// Text colour inside the floating value tooltip bubble.
  final Color? valueIndicatorTextColor;

  /// Typography of the floating value tooltip bubble.
  final TextStyle? valueIndicatorTextStyle;

  /// Spring the release snap and driven value changes ride. Critically damped
  /// by default: a thumb shows an exact value and must never overshoot it.
  final OrionSpringSpec? settleSpring;

  /// Spring the held thumb's lift rides.
  final OrionSpringSpec? liftSpring;

  /// How far the thumb grows while it is held.
  final double? liftScale;

  /// Tactile tick emitted on stepped detents and range bounds during drag.
  /// Falls back to `OrionThemeData.selectionHaptic` when null.
  final OrionHapticType? hapticType;

  /// Returns a copy with the provided fields replaced.
  OrionSliderStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? thumbColor,
    BorderSide? thumbBorder,
    List<BoxShadow>? thumbShadow,
    Color? activeTickColor,
    Color? inactiveTickColor,
    double? trackHeight,
    double? thumbSize,
    BorderRadius? radius,
    Color? focusOverlayColor,
    Color? hoverOverlayColor,
    Color? valueIndicatorColor,
    Color? valueIndicatorTextColor,
    TextStyle? valueIndicatorTextStyle,
    OrionSpringSpec? settleSpring,
    OrionSpringSpec? liftSpring,
    double? liftScale,
    OrionHapticType? hapticType,
  }) {
    return OrionSliderStyle(
      trackColor: trackColor ?? this.trackColor,
      fillColor: fillColor ?? this.fillColor,
      thumbColor: thumbColor ?? this.thumbColor,
      thumbBorder: thumbBorder ?? this.thumbBorder,
      thumbShadow: thumbShadow ?? this.thumbShadow,
      activeTickColor: activeTickColor ?? this.activeTickColor,
      inactiveTickColor: inactiveTickColor ?? this.inactiveTickColor,
      trackHeight: trackHeight ?? this.trackHeight,
      thumbSize: thumbSize ?? this.thumbSize,
      radius: radius ?? this.radius,
      focusOverlayColor: focusOverlayColor ?? this.focusOverlayColor,
      hoverOverlayColor: hoverOverlayColor ?? this.hoverOverlayColor,
      valueIndicatorColor: valueIndicatorColor ?? this.valueIndicatorColor,
      valueIndicatorTextColor:
          valueIndicatorTextColor ?? this.valueIndicatorTextColor,
      valueIndicatorTextStyle:
          valueIndicatorTextStyle ?? this.valueIndicatorTextStyle,
      settleSpring: settleSpring ?? this.settleSpring,
      liftSpring: liftSpring ?? this.liftSpring,
      liftScale: liftScale ?? this.liftScale,
      hapticType: hapticType ?? this.hapticType,
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
      thumbBorder: other.thumbBorder ?? thumbBorder,
      thumbShadow: other.thumbShadow ?? thumbShadow,
      activeTickColor: other.activeTickColor ?? activeTickColor,
      inactiveTickColor: other.inactiveTickColor ?? inactiveTickColor,
      trackHeight: other.trackHeight ?? trackHeight,
      thumbSize: other.thumbSize ?? thumbSize,
      radius: other.radius ?? radius,
      focusOverlayColor: other.focusOverlayColor ?? focusOverlayColor,
      hoverOverlayColor: other.hoverOverlayColor ?? hoverOverlayColor,
      valueIndicatorColor: other.valueIndicatorColor ?? valueIndicatorColor,
      valueIndicatorTextColor:
          other.valueIndicatorTextColor ?? valueIndicatorTextColor,
      valueIndicatorTextStyle:
          other.valueIndicatorTextStyle ?? valueIndicatorTextStyle,
      settleSpring: other.settleSpring ?? settleSpring,
      liftSpring: other.liftSpring ?? liftSpring,
      liftScale: other.liftScale ?? liftScale,
      hapticType: other.hapticType ?? hapticType,
    );
  }

  /// Linearly interpolates between two slider styles.
  static OrionSliderStyle? lerp(
    OrionSliderStyle? a,
    OrionSliderStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return OrionSliderStyle(
      trackColor: WidgetStateProperty.lerp<Color?>(
        a?.trackColor,
        b?.trackColor,
        t,
        Color.lerp,
      ),
      fillColor: WidgetStateProperty.lerp<Color?>(
        a?.fillColor,
        b?.fillColor,
        t,
        Color.lerp,
      ),
      thumbColor: WidgetStateProperty.lerp<Color?>(
        a?.thumbColor,
        b?.thumbColor,
        t,
        Color.lerp,
      ),
      thumbBorder: _lerpBorderSide(a?.thumbBorder, b?.thumbBorder, t),
      thumbShadow: BoxShadow.lerpList(a?.thumbShadow, b?.thumbShadow, t),
      activeTickColor: Color.lerp(a?.activeTickColor, b?.activeTickColor, t),
      inactiveTickColor: Color.lerp(
        a?.inactiveTickColor,
        b?.inactiveTickColor,
        t,
      ),
      trackHeight: lerpDouble(a?.trackHeight, b?.trackHeight, t),
      thumbSize: lerpDouble(a?.thumbSize, b?.thumbSize, t),
      radius: BorderRadius.lerp(a?.radius, b?.radius, t),
      focusOverlayColor: Color.lerp(
        a?.focusOverlayColor,
        b?.focusOverlayColor,
        t,
      ),
      hoverOverlayColor: Color.lerp(
        a?.hoverOverlayColor,
        b?.hoverOverlayColor,
        t,
      ),
      valueIndicatorColor: Color.lerp(
        a?.valueIndicatorColor,
        b?.valueIndicatorColor,
        t,
      ),
      valueIndicatorTextColor: Color.lerp(
        a?.valueIndicatorTextColor,
        b?.valueIndicatorTextColor,
        t,
      ),
      valueIndicatorTextStyle: TextStyle.lerp(
        a?.valueIndicatorTextStyle,
        b?.valueIndicatorTextStyle,
        t,
      ),
      settleSpring: t < 0.5 ? a?.settleSpring : b?.settleSpring,
      liftSpring: t < 0.5 ? a?.liftSpring : b?.liftSpring,
      liftScale: lerpDouble(a?.liftScale, b?.liftScale, t),
      hapticType: t < 0.5 ? a?.hapticType : b?.hapticType,
    );
  }

  static BorderSide? _lerpBorderSide(BorderSide? a, BorderSide? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return BorderSide.lerp(a ?? BorderSide.none, b ?? BorderSide.none, t);
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionSliderStyle from({
    Color? trackColor,
    Color? fillColor,
    Color? thumbColor,
    BorderSide? thumbBorder,
    List<BoxShadow>? thumbShadow,
    Color? activeTickColor,
    Color? inactiveTickColor,
    double? trackHeight,
    double? thumbSize,
    BorderRadius? radius,
    Color? focusOverlayColor,
    Color? hoverOverlayColor,
    Color? valueIndicatorColor,
    Color? valueIndicatorTextColor,
    TextStyle? valueIndicatorTextStyle,
    OrionSpringSpec? settleSpring,
    OrionSpringSpec? liftSpring,
    double? liftScale,
    OrionHapticType? hapticType,
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
      thumbBorder: thumbBorder,
      thumbShadow: thumbShadow,
      activeTickColor: activeTickColor,
      inactiveTickColor: inactiveTickColor,
      trackHeight: trackHeight,
      thumbSize: thumbSize,
      radius: radius,
      focusOverlayColor: focusOverlayColor,
      hoverOverlayColor: hoverOverlayColor,
      valueIndicatorColor: valueIndicatorColor,
      valueIndicatorTextColor: valueIndicatorTextColor,
      valueIndicatorTextStyle: valueIndicatorTextStyle,
      settleSpring: settleSpring,
      liftSpring: liftSpring,
      liftScale: liftScale,
      hapticType: hapticType,
    );
  }

  static bool _shadowListEquals(List<BoxShadow>? a, List<BoxShadow>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
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
        other.thumbBorder == thumbBorder &&
        _shadowListEquals(other.thumbShadow, thumbShadow) &&
        other.activeTickColor == activeTickColor &&
        other.inactiveTickColor == inactiveTickColor &&
        other.trackHeight == trackHeight &&
        other.thumbSize == thumbSize &&
        other.radius == radius &&
        other.focusOverlayColor == focusOverlayColor &&
        other.hoverOverlayColor == hoverOverlayColor &&
        other.valueIndicatorColor == valueIndicatorColor &&
        other.valueIndicatorTextColor == valueIndicatorTextColor &&
        other.valueIndicatorTextStyle == valueIndicatorTextStyle &&
        other.settleSpring == settleSpring &&
        other.liftSpring == liftSpring &&
        other.liftScale == liftScale &&
        other.hapticType == hapticType;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    trackColor,
    fillColor,
    thumbColor,
    thumbBorder,
    thumbShadow == null ? null : Object.hashAll(thumbShadow!),
    activeTickColor,
    inactiveTickColor,
    trackHeight,
    thumbSize,
    radius,
    focusOverlayColor,
    hoverOverlayColor,
    valueIndicatorColor,
    valueIndicatorTextColor,
    valueIndicatorTextStyle,
    settleSpring,
    liftSpring,
    liftScale,
    hapticType,
  ]);
}
