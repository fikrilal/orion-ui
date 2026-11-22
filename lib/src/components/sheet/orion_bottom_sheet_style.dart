import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Visual presentation layout for [OrionBottomSheet].
enum OrionBottomSheetVariant {
  /// Full-width sheet anchored directly to the bottom edge.
  edgeToEdge,

  /// Inset, rounded card sheet floating slightly above the bottom and side edges.
  floating,
}

/// The overridable visual and physical styling contract for [OrionBottomSheet].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionBottomSheetPresets`, the ambient `OrionBottomSheetTheme`, and the
/// instance style passed to the sheet.
@immutable
class OrionBottomSheetStyle {
  const OrionBottomSheetStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.floatingMargin,
    this.handleColor,
    this.handleSize,
    this.barrierColor,
    this.shadow,
    this.frosted,
    this.detentSpring,
    this.dismissSpring,
    this.rubberBandFactor,
    this.dismissThreshold,
  });

  /// Sheet container background color.
  final Color? backgroundColor;

  /// Sheet container outline border color.
  final Color? borderColor;

  /// Sheet container outline border width.
  final double? borderWidth;

  /// Sheet corner border radius.
  final BorderRadius? borderRadius;

  /// Outer inset margin applied when using [OrionBottomSheetVariant.floating].
  final EdgeInsetsGeometry? floatingMargin;

  /// Pill grab handle color.
  final Color? handleColor;

  /// Pill grab handle dimensions (width, height).
  final Size? handleSize;

  /// Modal barrier scrim color.
  final Color? barrierColor;

  /// Elevation box shadow recipe.
  final List<BoxShadow>? shadow;

  /// Whether to render a static frosted blur behind the sheet surface.
  final bool? frosted;

  /// Spring specification for transitions between snap detents and bounce back.
  final OrionSpringSpec? detentSpring;

  /// Spring specification for downward dismissal.
  final OrionSpringSpec? dismissSpring;

  /// Elastic drag resistance factor when pulled above the highest detent (default 0.15).
  final double? rubberBandFactor;

  /// Distance in logical pixels past the lowest detent required to trigger dismiss (default 96).
  final double? dismissThreshold;

  /// Returns a copy with the provided fields replaced.
  OrionBottomSheetStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? floatingMargin,
    Color? handleColor,
    Size? handleSize,
    Color? barrierColor,
    List<BoxShadow>? shadow,
    bool? frosted,
    OrionSpringSpec? detentSpring,
    OrionSpringSpec? dismissSpring,
    double? rubberBandFactor,
    double? dismissThreshold,
  }) {
    return OrionBottomSheetStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      floatingMargin: floatingMargin ?? this.floatingMargin,
      handleColor: handleColor ?? this.handleColor,
      handleSize: handleSize ?? this.handleSize,
      barrierColor: barrierColor ?? this.barrierColor,
      shadow: shadow ?? this.shadow,
      frosted: frosted ?? this.frosted,
      detentSpring: detentSpring ?? this.detentSpring,
      dismissSpring: dismissSpring ?? this.dismissSpring,
      rubberBandFactor: rubberBandFactor ?? this.rubberBandFactor,
      dismissThreshold: dismissThreshold ?? this.dismissThreshold,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionBottomSheetStyle merge(OrionBottomSheetStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionBottomSheetStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      floatingMargin: other.floatingMargin ?? floatingMargin,
      handleColor: other.handleColor ?? handleColor,
      handleSize: other.handleSize ?? handleSize,
      barrierColor: other.barrierColor ?? barrierColor,
      shadow: other.shadow ?? shadow,
      frosted: other.frosted ?? frosted,
      detentSpring: other.detentSpring ?? detentSpring,
      dismissSpring: other.dismissSpring ?? dismissSpring,
      rubberBandFactor: other.rubberBandFactor ?? rubberBandFactor,
      dismissThreshold: other.dismissThreshold ?? dismissThreshold,
    );
  }

  /// Builds a style from plain values.
  static OrionBottomSheetStyle from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    EdgeInsetsGeometry? floatingMargin,
    Color? handleColor,
    Size? handleSize,
    Color? barrierColor,
    List<BoxShadow>? shadow,
    bool? frosted,
    OrionSpringSpec? detentSpring,
    OrionSpringSpec? dismissSpring,
    double? rubberBandFactor,
    double? dismissThreshold,
  }) {
    return OrionBottomSheetStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      floatingMargin: floatingMargin,
      handleColor: handleColor,
      handleSize: handleSize,
      barrierColor: barrierColor,
      shadow: shadow,
      frosted: frosted,
      detentSpring: detentSpring,
      dismissSpring: dismissSpring,
      rubberBandFactor: rubberBandFactor,
      dismissThreshold: dismissThreshold,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionBottomSheetStyle &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        other.floatingMargin == floatingMargin &&
        other.handleColor == handleColor &&
        other.handleSize == handleSize &&
        other.barrierColor == barrierColor &&
        other.shadow == shadow &&
        other.frosted == frosted &&
        other.detentSpring == detentSpring &&
        other.dismissSpring == dismissSpring &&
        other.rubberBandFactor == rubberBandFactor &&
        other.dismissThreshold == dismissThreshold;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    floatingMargin,
    handleColor,
    handleSize,
    barrierColor,
    shadow,
    frosted,
    detentSpring,
    dismissSpring,
    rubberBandFactor,
    dismissThreshold,
  ]);
}
