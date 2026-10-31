import 'dart:ui' show lerpDouble;

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
/// [WidgetState.disabled], [WidgetState.selected], [WidgetState.error],
/// [WidgetState.hovered], and [WidgetState.focused] - so a skin can tint each
/// state without restating the rest.
@immutable
class OrionRadioStyle {
  const OrionRadioStyle({
    this.ringColor,
    this.dotColor,
    this.fillColor,
    this.size,
    this.dotSize,
    this.borderWidth,
    this.pressedScale,
    this.focusOverlayColor,
    this.hoverOverlayColor,
    this.spring,
  });

  /// The ring, resolved with [WidgetState.disabled], [WidgetState.selected],
  /// [WidgetState.error], [WidgetState.hovered], and [WidgetState.focused].
  final WidgetStateProperty<Color?>? ringColor;

  /// The dot, resolved with the same states.
  final WidgetStateProperty<Color?>? dotColor;

  /// The interior, resolved with the same states. Transparent by default:
  /// the ring-plus-dot is what tells a radio apart from a checkbox.
  final WidgetStateProperty<Color?>? fillColor;

  /// Circle diameter. Hit targets stay at least 44 pt and expand when [size]
  /// exceeds 44 pt so oversized circles are never clipped.
  final double? size;

  /// Dot diameter inside the circle.
  final double? dotSize;

  /// Ring width, constant across states. Values `<= 0` omit the border cleanly.
  final double? borderWidth;

  /// Target scale while the radio circle is held down (default `0.90` for a
  /// crisp micro-tactile dip matching `OrionCheckbox`).
  final double? pressedScale;

  /// The focus overlay painted under the circle. Focus is a translucent
  /// affordance on the surface, not a second ring.
  final Color? focusOverlayColor;

  /// The hover overlay painted under the circle while a pointer rests over it.
  final Color? hoverOverlayColor;

  /// Spring the selection travel rides.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionRadioStyle copyWith({
    WidgetStateProperty<Color?>? ringColor,
    WidgetStateProperty<Color?>? dotColor,
    WidgetStateProperty<Color?>? fillColor,
    double? size,
    double? dotSize,
    double? borderWidth,
    double? pressedScale,
    Color? focusOverlayColor,
    Color? hoverOverlayColor,
    OrionSpringSpec? spring,
  }) {
    return OrionRadioStyle(
      ringColor: ringColor ?? this.ringColor,
      dotColor: dotColor ?? this.dotColor,
      fillColor: fillColor ?? this.fillColor,
      size: size ?? this.size,
      dotSize: dotSize ?? this.dotSize,
      borderWidth: borderWidth ?? this.borderWidth,
      pressedScale: pressedScale ?? this.pressedScale,
      focusOverlayColor: focusOverlayColor ?? this.focusOverlayColor,
      hoverOverlayColor: hoverOverlayColor ?? this.hoverOverlayColor,
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
      pressedScale: other.pressedScale ?? pressedScale,
      focusOverlayColor: other.focusOverlayColor ?? focusOverlayColor,
      hoverOverlayColor: other.hoverOverlayColor ?? hoverOverlayColor,
      spring: other.spring ?? spring,
    );
  }

  /// Linearly interpolates between two radio styles.
  static OrionRadioStyle? lerp(
    OrionRadioStyle? a,
    OrionRadioStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return OrionRadioStyle(
      ringColor: WidgetStateProperty.lerp<Color?>(
        a?.ringColor,
        b?.ringColor,
        t,
        Color.lerp,
      ),
      dotColor: WidgetStateProperty.lerp<Color?>(
        a?.dotColor,
        b?.dotColor,
        t,
        Color.lerp,
      ),
      fillColor: WidgetStateProperty.lerp<Color?>(
        a?.fillColor,
        b?.fillColor,
        t,
        Color.lerp,
      ),
      size: lerpDouble(a?.size, b?.size, t),
      dotSize: lerpDouble(a?.dotSize, b?.dotSize, t),
      borderWidth: lerpDouble(a?.borderWidth, b?.borderWidth, t),
      pressedScale: lerpDouble(a?.pressedScale, b?.pressedScale, t),
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
      spring: t < 0.5 ? a?.spring : b?.spring,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state (such as disabled or error states); [from] is the
  /// flat, one-value-per-field sugar. [fillColor] is the one exception: it is
  /// the selected fill, and every other state stays transparent, matching the
  /// interior's transparent default.
  static OrionRadioStyle from({
    Color? ringColor,
    Color? dotColor,
    Color? fillColor,
    double? size,
    double? dotSize,
    double? borderWidth,
    double? pressedScale,
    Color? focusOverlayColor,
    Color? hoverOverlayColor,
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
          : WidgetStateProperty.resolveWith<Color?>(
              (Set<WidgetState> states) => states.contains(WidgetState.selected)
                  ? fillColor
                  : Colors.transparent,
            ),
      size: size,
      dotSize: dotSize,
      borderWidth: borderWidth,
      pressedScale: pressedScale,
      focusOverlayColor: focusOverlayColor,
      hoverOverlayColor: hoverOverlayColor,
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
        other.pressedScale == pressedScale &&
        other.focusOverlayColor == focusOverlayColor &&
        other.hoverOverlayColor == hoverOverlayColor &&
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
    pressedScale,
    focusOverlayColor,
    hoverOverlayColor,
    spring,
  ]);
}
