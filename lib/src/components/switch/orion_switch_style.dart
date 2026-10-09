import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The overridable contract for how a switch looks, deforms and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in [defaults], the theme's `OrionSwitchTheme`, and the instance style
/// passed to the widget. Every field is nullable; a null field falls through
/// to the layer beneath it, so an override changes exactly what it names.
///
/// [trackColor] and [thumbColor] resolve through the switch's live
/// [WidgetState]s - [WidgetState.disabled] and [WidgetState.selected] - and
/// the build lerps between the resolved off and on colours with the slide.
@immutable
class OrionSwitchStyle {
  const OrionSwitchStyle({
    this.trackColor,
    this.thumbColor,
    this.focusRingColor,
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

  /// Track colour, resolved with [WidgetState.disabled] and
  /// [WidgetState.selected].
  final WidgetStateProperty<Color?>? trackColor;

  /// Thumb colour, resolved with the same states; the thumb cross-fades
  /// between the resolved off and on colours with the slide.
  final WidgetStateProperty<Color?>? thumbColor;

  /// The 2 pt focus ring drawn on the track.
  final Color? focusRingColor;

  /// Track width; the thumb's travel is derived from it.
  final double? trackWidth;

  /// Track height; the thumb's diameter is derived from it.
  final double? trackHeight;

  /// The track's inner inset: the thumb's diameter is `trackHeight - 2 *
  /// inset`, and its travel is the width minus both insets.
  final double? inset;

  /// Track corner radius.
  final BorderRadius? radius;

  /// How far a held thumb stretches along its travel, as a fraction. The
  /// default matches the reference switches.
  final double? pressStretch;

  /// How far a held thumb squashes across its travel, as a fraction.
  final double? pressSquish;

  /// Spring the thumb rides when the value flips.
  final OrionSpringSpec? slideSpring;

  /// Spring the deformation rides while the thumb is held.
  final OrionSpringSpec? pressSpring;

  /// Tactile tick when the thumb flips. Falls back to the theme's
  /// `OrionThemeData.selectionHaptic` when null; [OrionHapticType.none]
  /// silences the switch.
  final OrionHapticType? hapticType;

  /// Returns a copy with the provided fields replaced.
  OrionSwitchStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? thumbColor,
    Color? focusRingColor,
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
      focusRingColor: focusRingColor ?? this.focusRingColor,
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
      focusRingColor: other.focusRingColor ?? focusRingColor,
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
    Color? focusRingColor,
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
      focusRingColor: focusRingColor,
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

  /// The built-in look: exactly what the switch shipped before this contract
  /// existed, resolved against the ambient scheme.
  static OrionSwitchStyle defaults({required ColorScheme scheme}) {
    final Color disabledContainer = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledContent = scheme.onSurface.withValues(alpha: 0.38);
    return OrionSwitchStyle(
      trackColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.selected)) {
          return states.contains(WidgetState.disabled)
              ? scheme.primary.withValues(alpha: 0.38)
              : scheme.primary;
        }
        return states.contains(WidgetState.disabled)
            ? disabledContainer
            : scheme.outline;
      }),
      thumbColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return disabledContent;
        }
        return states.contains(WidgetState.selected)
            ? scheme.onPrimary
            : scheme.onSurface;
      }),
      focusRingColor: scheme.onSurface,
      trackWidth: 52,
      trackHeight: OrionSizing.controlHeightSmall,
      inset: OrionSpacing.space4,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      pressStretch: 0.18,
      pressSquish: 0.12,
      slideSpring: OrionSpringSpec.gentle,
      pressSpring: OrionSpringSpec.snappy,
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
        other.focusRingColor == focusRingColor &&
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
    focusRingColor,
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
