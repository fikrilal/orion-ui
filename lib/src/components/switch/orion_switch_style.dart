import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/switch/orion_switch_presets.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Size step for [OrionSwitch].
enum OrionSwitchSize {
  /// Compact 40 × 24 pill track for dense toolbars and cards.
  small,

  /// Standard 52 × 32 pill track (default).
  medium,

  /// Generous 64 × 38 pill track for prominent settings toggles.
  large,
}

/// Where the switch pill sits relative to its [label] and [subtitle].
enum OrionSwitchControlAffinity {
  /// Switch on the start edge, label and subtitle after it.
  leading,

  /// Label and subtitle on the start edge, switch on the trailing edge.
  trailing,
}

/// The overridable contract for how an `OrionSwitch` looks, deforms, and moves.
///
/// Three layers produce the effective style, each overriding the last:
/// [OrionSwitchPresets], `OrionSwitchTheme`, and the instance style passed to
/// the widget. Every field is nullable; a null field falls through to the layer
/// beneath it, so an override changes only what it names.
///
/// [trackColor], [thumbColor], and [trackBorderColor] resolve through the
/// switch's live [WidgetState]s (`selected`, `disabled`, `hovered`, `focused`,
/// `pressed`), and the switch lerps smoothly between off and on states during
/// slides and drags.
@immutable
class OrionSwitchStyle {
  const OrionSwitchStyle({
    this.trackColor,
    this.thumbColor,
    this.trackBorderColor,
    this.trackBorderWidth,
    this.thumbShadow,
    this.focusRingColor,
    this.activeIconColor,
    this.inactiveIconColor,
    this.iconSize,
    this.trackWidth,
    this.trackHeight,
    this.inset,
    this.radius,
    this.pressStretch,
    this.pressSquish,
    this.slideSpring,
    this.pressSpring,
    this.hapticType,
  });

  /// Track fill colour resolved with live [WidgetState]s.
  final WidgetStateProperty<Color?>? trackColor;

  /// Thumb fill colour resolved with live [WidgetState]s.
  final WidgetStateProperty<Color?>? thumbColor;

  /// Optional hairline track border resolved with live [WidgetState]s.
  final WidgetStateProperty<Color?>? trackBorderColor;

  /// Track border stroke width in logical pixels (`<= 0` omits the border).
  final double? trackBorderWidth;

  /// Elevation shadows painted beneath the enabled thumb capsule. Pass an
  /// empty list (`const []`) for a flat, shadowless thumb.
  final List<BoxShadow>? thumbShadow;

  /// Outer keyboard focus ring colour drawn around the track.
  final Color? focusRingColor;

  /// Default icon colour applied to `activeIcon` inside the thumb.
  final Color? activeIconColor;

  /// Default icon colour applied to `inactiveIcon` inside the thumb.
  final Color? inactiveIconColor;

  /// Default size applied to `activeIcon` and `inactiveIcon` inside the thumb.
  final double? iconSize;

  /// Track width; the thumb's travel is derived from it.
  final double? trackWidth;

  /// Track height; the thumb's diameter is derived from it.
  final double? trackHeight;

  /// The track's inner inset: the thumb's resting diameter is
  /// `trackHeight - 2 * inset`, and travel is `trackWidth - thumbSize - 2 * inset`.
  final double? inset;

  /// Track corner radius.
  final BorderRadius? radius;

  /// How far a held thumb elongates along its travel, as a fraction of its
  /// resting diameter.
  final double? pressStretch;

  /// How far a held thumb compresses across its travel, as a fraction of its
  /// resting diameter.
  final double? pressSquish;

  /// Spring the thumb rides when the value flips or a drag settles.
  final OrionSpringSpec? slideSpring;

  /// Spring the capsule elongation rides while the thumb is held or dragged.
  final OrionSpringSpec? pressSpring;

  /// Tactile tick when the thumb flips or crosses the midpoint during drag.
  /// Falls back to `OrionThemeData.selectionHaptic` when null;
  /// [OrionHapticType.none] silences the switch.
  final OrionHapticType? hapticType;

  /// Returns a copy with the provided fields replaced.
  OrionSwitchStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? thumbColor,
    WidgetStateProperty<Color?>? trackBorderColor,
    double? trackBorderWidth,
    List<BoxShadow>? thumbShadow,
    Color? focusRingColor,
    Color? activeIconColor,
    Color? inactiveIconColor,
    double? iconSize,
    double? trackWidth,
    double? trackHeight,
    double? inset,
    BorderRadius? radius,
    double? pressStretch,
    double? pressSquish,
    OrionSpringSpec? slideSpring,
    OrionSpringSpec? pressSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionSwitchStyle(
      trackColor: trackColor ?? this.trackColor,
      thumbColor: thumbColor ?? this.thumbColor,
      trackBorderColor: trackBorderColor ?? this.trackBorderColor,
      trackBorderWidth: trackBorderWidth ?? this.trackBorderWidth,
      thumbShadow: thumbShadow ?? this.thumbShadow,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      activeIconColor: activeIconColor ?? this.activeIconColor,
      inactiveIconColor: inactiveIconColor ?? this.inactiveIconColor,
      iconSize: iconSize ?? this.iconSize,
      trackWidth: trackWidth ?? this.trackWidth,
      trackHeight: trackHeight ?? this.trackHeight,
      inset: inset ?? this.inset,
      radius: radius ?? this.radius,
      pressStretch: pressStretch ?? this.pressStretch,
      pressSquish: pressSquish ?? this.pressSquish,
      slideSpring: slideSpring ?? this.slideSpring,
      pressSpring: pressSpring ?? this.pressSpring,
      hapticType: hapticType ?? this.hapticType,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionSwitchStyle merge(OrionSwitchStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionSwitchStyle(
      trackColor: other.trackColor ?? trackColor,
      thumbColor: other.thumbColor ?? thumbColor,
      trackBorderColor: other.trackBorderColor ?? trackBorderColor,
      trackBorderWidth: other.trackBorderWidth ?? trackBorderWidth,
      thumbShadow: other.thumbShadow ?? thumbShadow,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      activeIconColor: other.activeIconColor ?? activeIconColor,
      inactiveIconColor: other.inactiveIconColor ?? inactiveIconColor,
      iconSize: other.iconSize ?? iconSize,
      trackWidth: other.trackWidth ?? trackWidth,
      trackHeight: other.trackHeight ?? trackHeight,
      inset: other.inset ?? inset,
      radius: other.radius ?? radius,
      pressStretch: other.pressStretch ?? pressStretch,
      pressSquish: other.pressSquish ?? pressSquish,
      slideSpring: other.slideSpring ?? slideSpring,
      pressSpring: other.pressSpring ?? pressSpring,
      hapticType: other.hapticType ?? hapticType,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionSwitchStyle from({
    Color? trackColor,
    Color? thumbColor,
    Color? trackBorderColor,
    double? trackBorderWidth,
    List<BoxShadow>? thumbShadow,
    Color? focusRingColor,
    Color? activeIconColor,
    Color? inactiveIconColor,
    double? iconSize,
    double? trackWidth,
    double? trackHeight,
    double? inset,
    BorderRadius? radius,
    double? pressStretch,
    double? pressSquish,
    OrionSpringSpec? slideSpring,
    OrionSpringSpec? pressSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionSwitchStyle(
      trackColor: trackColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(trackColor),
      thumbColor: thumbColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(thumbColor),
      trackBorderColor: trackBorderColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(trackBorderColor),
      trackBorderWidth: trackBorderWidth,
      thumbShadow: thumbShadow,
      focusRingColor: focusRingColor,
      activeIconColor: activeIconColor,
      inactiveIconColor: inactiveIconColor,
      iconSize: iconSize,
      trackWidth: trackWidth,
      trackHeight: trackHeight,
      inset: inset,
      radius: radius,
      pressStretch: pressStretch,
      pressSquish: pressSquish,
      slideSpring: slideSpring,
      pressSpring: pressSpring,
      hapticType: hapticType,
    );
  }

  /// Resolves the built-in look for [size] against [scheme].
  static OrionSwitchStyle defaults({
    required ColorScheme scheme,
    OrionSwitchSize size = OrionSwitchSize.medium,
  }) {
    return OrionSwitchPresets.resolve(size: size, scheme: scheme);
  }

  /// Linearly interpolates between two [OrionSwitchStyle] instances.
  static OrionSwitchStyle? lerp(
    OrionSwitchStyle? a,
    OrionSwitchStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    if (a == null && b == null) {
      return null;
    }
    return OrionSwitchStyle(
      trackColor: WidgetStateProperty.lerp<Color?>(
        a?.trackColor,
        b?.trackColor,
        t,
        Color.lerp,
      ),
      thumbColor: WidgetStateProperty.lerp<Color?>(
        a?.thumbColor,
        b?.thumbColor,
        t,
        Color.lerp,
      ),
      trackBorderColor: WidgetStateProperty.lerp<Color?>(
        a?.trackBorderColor,
        b?.trackBorderColor,
        t,
        Color.lerp,
      ),
      trackBorderWidth: lerpDouble(a?.trackBorderWidth, b?.trackBorderWidth, t),
      thumbShadow: BoxShadow.lerpList(a?.thumbShadow, b?.thumbShadow, t),
      focusRingColor: Color.lerp(a?.focusRingColor, b?.focusRingColor, t),
      activeIconColor: Color.lerp(a?.activeIconColor, b?.activeIconColor, t),
      inactiveIconColor: Color.lerp(
        a?.inactiveIconColor,
        b?.inactiveIconColor,
        t,
      ),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      trackWidth: lerpDouble(a?.trackWidth, b?.trackWidth, t),
      trackHeight: lerpDouble(a?.trackHeight, b?.trackHeight, t),
      inset: lerpDouble(a?.inset, b?.inset, t),
      radius: BorderRadius.lerp(a?.radius, b?.radius, t),
      pressStretch: lerpDouble(a?.pressStretch, b?.pressStretch, t),
      pressSquish: lerpDouble(a?.pressSquish, b?.pressSquish, t),
      slideSpring: t < 0.5 ? a?.slideSpring : b?.slideSpring,
      pressSpring: t < 0.5 ? a?.pressSpring : b?.pressSpring,
      hapticType: t < 0.5 ? a?.hapticType : b?.hapticType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSwitchStyle &&
        other.trackColor == trackColor &&
        other.thumbColor == thumbColor &&
        other.trackBorderColor == trackBorderColor &&
        other.trackBorderWidth == trackBorderWidth &&
        listEquals(other.thumbShadow, thumbShadow) &&
        other.focusRingColor == focusRingColor &&
        other.activeIconColor == activeIconColor &&
        other.inactiveIconColor == inactiveIconColor &&
        other.iconSize == iconSize &&
        other.trackWidth == trackWidth &&
        other.trackHeight == trackHeight &&
        other.inset == inset &&
        other.radius == radius &&
        other.pressStretch == pressStretch &&
        other.pressSquish == pressSquish &&
        other.slideSpring == slideSpring &&
        other.pressSpring == pressSpring &&
        other.hapticType == hapticType;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    trackColor,
    thumbColor,
    trackBorderColor,
    trackBorderWidth,
    thumbShadow == null ? null : Object.hashAll(thumbShadow!),
    focusRingColor,
    activeIconColor,
    inactiveIconColor,
    iconSize,
    trackWidth,
    trackHeight,
    inset,
    radius,
    pressStretch,
    pressSquish,
    slideSpring,
    pressSpring,
    hapticType,
  ]);
}
