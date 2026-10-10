import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The overridable contract for how an [OrionCard] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionCardPresets` for the [frosted] face, the theme's
/// `OrionCardTheme`, and the instance style passed to the widget. Every field
/// is nullable; a null field falls through to the layer beneath it, so an
/// override changes exactly what it names. [OrionCard.padding] and
/// [OrionCard.radius] are the shipped shortcuts and merge after the instance
/// style, so they keep winning.
@immutable
class OrionCardStyle {
  const OrionCardStyle({
    this.background,
    this.border,
    this.radius,
    this.padding,
    this.shadow,
    this.blurSigma,
    this.pressScale,
    this.pressSpring,
    this.releaseSpring,
  });

  /// Surface fill.
  final Color? background;

  /// Surface border; null draws none.
  final BorderSide? border;

  /// Surface corner radius, shared by the decoration and the clip.
  final BorderRadius? radius;

  /// Content padding.
  final EdgeInsetsGeometry? padding;

  /// Surface shadow recipe; null draws none.
  final List<BoxShadow>? shadow;

  /// Backdrop blur sigma; null keeps the card opaque, and a non-null value
  /// paints a static clipped blur behind the content.
  final double? blurSigma;

  /// Compression of the card while it is pressed.
  final double? pressScale;

  /// Spring the press compression rides.
  final OrionSpringSpec? pressSpring;

  /// Spring the release rides.
  final OrionSpringSpec? releaseSpring;

  /// Returns a copy with the provided fields replaced.
  OrionCardStyle copyWith({
    Color? background,
    BorderSide? border,
    BorderRadius? radius,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? shadow,
    double? blurSigma,
    double? pressScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
  }) {
    return OrionCardStyle(
      background: background ?? this.background,
      border: border ?? this.border,
      radius: radius ?? this.radius,
      padding: padding ?? this.padding,
      shadow: shadow ?? this.shadow,
      blurSigma: blurSigma ?? this.blurSigma,
      pressScale: pressScale ?? this.pressScale,
      pressSpring: pressSpring ?? this.pressSpring,
      releaseSpring: releaseSpring ?? this.releaseSpring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionCardStyle merge(OrionCardStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionCardStyle(
      background: other.background ?? background,
      border: other.border ?? border,
      radius: other.radius ?? radius,
      padding: other.padding ?? padding,
      shadow: other.shadow ?? shadow,
      blurSigma: other.blurSigma ?? blurSigma,
      pressScale: other.pressScale ?? pressScale,
      pressSpring: other.pressSpring ?? pressSpring,
      releaseSpring: other.releaseSpring ?? releaseSpring,
    );
  }

  /// Builds a style from plain values.
  static OrionCardStyle from({
    Color? background,
    BorderSide? border,
    BorderRadius? radius,
    EdgeInsetsGeometry? padding,
    List<BoxShadow>? shadow,
    double? blurSigma,
    double? pressScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
  }) {
    return OrionCardStyle(
      background: background,
      border: border,
      radius: radius,
      padding: padding,
      shadow: shadow,
      blurSigma: blurSigma,
      pressScale: pressScale,
      pressSpring: pressSpring,
      releaseSpring: releaseSpring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCardStyle &&
        other.background == background &&
        other.border == border &&
        other.radius == radius &&
        other.padding == padding &&
        other.shadow == shadow &&
        other.blurSigma == blurSigma &&
        other.pressScale == pressScale &&
        other.pressSpring == pressSpring &&
        other.releaseSpring == releaseSpring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    background,
    border,
    radius,
    padding,
    shadow,
    blurSigma,
    pressScale,
    pressSpring,
    releaseSpring,
  ]);
}
