import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Themeable Orion tokens that Material's theme cannot express.
///
/// Role colors stay in [ColorScheme] and typography in [TextTheme]; this
/// extension carries the physics-aligned values Layer 3 components consume:
/// motion (springs, press scale, haptics), corner radii, surface blur, and the
/// elevation recipe for raised surfaces.
///
/// Register it through [ThemeData.extensions] (see `OrionTheme.apply`) and
/// read it with `OrionTheme.of(context)`.
@immutable
class OrionThemeData extends ThemeExtension<OrionThemeData> {
  const OrionThemeData({
    this.pressScale = 0.96,
    this.pressSpring = OrionSpringSpec.snappy,
    this.releaseSpring = OrionSpringSpec.snappy,
    this.tapHaptic = OrionHapticType.selectionClick,
    this.longPressHaptic = OrionHapticType.mediumImpact,
    this.controlRadius = OrionRadii.radius12,
    this.surfaceRadius = OrionRadii.radius24,
    this.blurSigma = 12.0,
    this.shadow = defaultShadow,
  }) : assert(
         pressScale > 0.0 && pressScale <= 1.0,
         'pressScale must be between 0.0 and 1.0',
       ),
       assert(blurSigma >= 0.0, 'blurSigma must not be negative');

  /// Neutral fallback used when no [OrionThemeData] is registered.
  static const OrionThemeData fallback = OrionThemeData();

  /// Default elevation recipe for cards and other raised surfaces.
  static const List<BoxShadow> defaultShadow = <BoxShadow>[
    BoxShadow(color: Color(0x14000000), blurRadius: 12.0, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 2.0, offset: Offset(0, 1)),
  ];

  /// Target scale while a pressable is held down.
  final double pressScale;

  /// Spring governing compression on pointer down.
  final OrionSpringSpec pressSpring;

  /// Spring governing release on pointer up or cancel.
  final OrionSpringSpec releaseSpring;

  /// Haptic emitted when a tap completes.
  final OrionHapticType tapHaptic;

  /// Haptic emitted when a long press is recognized.
  final OrionHapticType longPressHaptic;

  /// Corner radius for controls (buttons, tiles).
  final double controlRadius;

  /// Corner radius for surfaces (cards, sheets).
  final double surfaceRadius;

  /// Gaussian blur sigma for frosted surfaces.
  final double blurSigma;

  /// Elevation recipe for raised surfaces.
  final List<BoxShadow> shadow;

  /// Returns a copy with the provided fields replaced.
  @override
  OrionThemeData copyWith({
    double? pressScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? tapHaptic,
    OrionHapticType? longPressHaptic,
    double? controlRadius,
    double? surfaceRadius,
    double? blurSigma,
    List<BoxShadow>? shadow,
  }) {
    return OrionThemeData(
      pressScale: pressScale ?? this.pressScale,
      pressSpring: pressSpring ?? this.pressSpring,
      releaseSpring: releaseSpring ?? this.releaseSpring,
      tapHaptic: tapHaptic ?? this.tapHaptic,
      longPressHaptic: longPressHaptic ?? this.longPressHaptic,
      controlRadius: controlRadius ?? this.controlRadius,
      surfaceRadius: surfaceRadius ?? this.surfaceRadius,
      blurSigma: blurSigma ?? this.blurSigma,
      shadow: shadow ?? this.shadow,
    );
  }

  @override
  OrionThemeData lerp(ThemeExtension<OrionThemeData>? other, double t) {
    if (other is! OrionThemeData) return this;
    return OrionThemeData(
      pressScale: pressScale + (other.pressScale - pressScale) * t,
      // Springs and haptics are discrete specs; swap at the midpoint.
      pressSpring: t < 0.5 ? pressSpring : other.pressSpring,
      releaseSpring: t < 0.5 ? releaseSpring : other.releaseSpring,
      tapHaptic: t < 0.5 ? tapHaptic : other.tapHaptic,
      longPressHaptic: t < 0.5 ? longPressHaptic : other.longPressHaptic,
      controlRadius: controlRadius + (other.controlRadius - controlRadius) * t,
      surfaceRadius: surfaceRadius + (other.surfaceRadius - surfaceRadius) * t,
      blurSigma: blurSigma + (other.blurSigma - blurSigma) * t,
      shadow: BoxShadow.lerpList(shadow, other.shadow, t)!,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionThemeData &&
        other.pressScale == pressScale &&
        other.pressSpring == pressSpring &&
        other.releaseSpring == releaseSpring &&
        other.tapHaptic == tapHaptic &&
        other.longPressHaptic == longPressHaptic &&
        other.controlRadius == controlRadius &&
        other.surfaceRadius == surfaceRadius &&
        other.blurSigma == blurSigma &&
        listEquals(other.shadow, shadow);
  }

  @override
  int get hashCode => Object.hash(
    pressScale,
    pressSpring,
    releaseSpring,
    tapHaptic,
    longPressHaptic,
    controlRadius,
    surfaceRadius,
    blurSigma,
    Object.hashAll(shadow),
  );
}
