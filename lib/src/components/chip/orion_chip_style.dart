import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionChip] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionChipPresets`, the theme's `OrionChipTheme`, and the instance
/// style passed to the widget. Every field is nullable; a null field falls
/// through to the layer beneath it, so an override changes exactly what it
/// names.
///
/// The colour fields resolve through the chip's live [WidgetState]s -
/// [WidgetState.disabled], [WidgetState.selected] and [WidgetState.focused] -
/// so a skin can tint each state without restating the rest. The presets
/// ignore `focused`: the default focus signal is the translucent overlay.
@immutable
class OrionChipStyle {
  const OrionChipStyle({
    this.fillColor,
    this.borderColor,
    this.labelColor,
    this.checkColor,
    this.height,
    this.padding,
    this.radius,
    this.borderWidth,
    this.checkSize,
    this.checkGap,
    this.focusOverlayColor,
    this.spring,
  });

  /// Pill fill, resolved with [WidgetState.disabled], [WidgetState.selected]
  /// and [WidgetState.focused].
  final WidgetStateProperty<Color?>? fillColor;

  /// Hairline colour, resolved with the same states.
  final WidgetStateProperty<Color?>? borderColor;

  /// Label colour, resolved with the same states; the widget lerps the idle
  /// and selected ends on the travel sample, so the label never snaps over a
  /// still-light pill.
  final WidgetStateProperty<Color?>? labelColor;

  /// Check colour, resolved with the same states. The check is the one mark
  /// that can carry a colour the label does not.
  final WidgetStateProperty<Color?>? checkColor;

  /// Pill height. The hit target stays 44 pt whatever this is.
  final double? height;

  /// Pill inner padding.
  final EdgeInsetsGeometry? padding;

  /// Pill corner radius; the default is a pill.
  final BorderRadius? radius;

  /// Hairline width, constant across states.
  final double? borderWidth;

  /// Check glyph size.
  final double? checkSize;

  /// Gap between the check and the label while the check is shown.
  final double? checkGap;

  /// The focus state layer painted over the pill's surface inside its clip.
  /// Focus is a translucent affordance, not a second concentric edge.
  final Color? focusOverlayColor;

  /// Spring the state travel rides. The trip is the whole 0 to 1 change, so
  /// the spec is the gentler travel spring rather than a press release.
  final OrionSpringSpec? spring;

  /// Returns a copy with the provided fields replaced.
  OrionChipStyle copyWith({
    WidgetStateProperty<Color?>? fillColor,
    WidgetStateProperty<Color?>? borderColor,
    WidgetStateProperty<Color?>? labelColor,
    WidgetStateProperty<Color?>? checkColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? borderWidth,
    double? checkSize,
    double? checkGap,
    Color? focusOverlayColor,
    OrionSpringSpec? spring,
  }) {
    return OrionChipStyle(
      fillColor: fillColor ?? this.fillColor,
      borderColor: borderColor ?? this.borderColor,
      labelColor: labelColor ?? this.labelColor,
      checkColor: checkColor ?? this.checkColor,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      radius: radius ?? this.radius,
      borderWidth: borderWidth ?? this.borderWidth,
      checkSize: checkSize ?? this.checkSize,
      checkGap: checkGap ?? this.checkGap,
      focusOverlayColor: focusOverlayColor ?? this.focusOverlayColor,
      spring: spring ?? this.spring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionChipStyle merge(OrionChipStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionChipStyle(
      fillColor: other.fillColor ?? fillColor,
      borderColor: other.borderColor ?? borderColor,
      labelColor: other.labelColor ?? labelColor,
      checkColor: other.checkColor ?? checkColor,
      height: other.height ?? height,
      padding: other.padding ?? padding,
      radius: other.radius ?? radius,
      borderWidth: other.borderWidth ?? borderWidth,
      checkSize: other.checkSize ?? checkSize,
      checkGap: other.checkGap ?? checkGap,
      focusOverlayColor: other.focusOverlayColor ?? focusOverlayColor,
      spring: other.spring ?? spring,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionChipStyle from({
    Color? fillColor,
    Color? borderColor,
    Color? labelColor,
    Color? checkColor,
    double? height,
    EdgeInsetsGeometry? padding,
    BorderRadius? radius,
    double? borderWidth,
    double? checkSize,
    double? checkGap,
    Color? focusOverlayColor,
    OrionSpringSpec? spring,
  }) {
    return OrionChipStyle(
      fillColor: fillColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(fillColor),
      borderColor: borderColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(borderColor),
      labelColor: labelColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(labelColor),
      checkColor: checkColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(checkColor),
      height: height,
      padding: padding,
      radius: radius,
      borderWidth: borderWidth,
      checkSize: checkSize,
      checkGap: checkGap,
      focusOverlayColor: focusOverlayColor,
      spring: spring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionChipStyle &&
        other.fillColor == fillColor &&
        other.borderColor == borderColor &&
        other.labelColor == labelColor &&
        other.checkColor == checkColor &&
        other.height == height &&
        other.padding == padding &&
        other.radius == radius &&
        other.borderWidth == borderWidth &&
        other.checkSize == checkSize &&
        other.checkGap == checkGap &&
        other.focusOverlayColor == focusOverlayColor &&
        other.spring == spring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    fillColor,
    borderColor,
    labelColor,
    checkColor,
    height,
    padding,
    radius,
    borderWidth,
    checkSize,
    checkGap,
    focusOverlayColor,
    spring,
  ]);
}
