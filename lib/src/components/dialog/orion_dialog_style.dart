import 'dart:ui' show lerpDouble;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The visual and physical styling contract for [OrionDialog].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionDialogPresets`, the ambient `OrionDialogTheme`, and the
/// instance style passed to the dialog.
@immutable
class OrionDialogStyle {
  const OrionDialogStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.shadow,
    this.frosted,
    this.barrierColor,
    this.padding,
    this.maxWidth,
    this.contentSpacing,
    this.actionSpacing,
    this.springSpec,
    this.dismissSpringSpec,
  });

  /// Dialog container background color.
  final Color? backgroundColor;

  /// Dialog border outline color.
  final Color? borderColor;

  /// Dialog border outline width.
  final double? borderWidth;

  /// Dialog corner radius.
  final BorderRadius? borderRadius;

  /// Elevation drop shadow list.
  final List<BoxShadow>? shadow;

  /// Whether to render a static frosted blur behind the dialog content.
  final bool? frosted;

  /// Color of the modal backdrop scrim barrier.
  final Color? barrierColor;

  /// Internal padding around the dialog body.
  final EdgeInsetsGeometry? padding;

  /// Maximum width constraint of the dialog surface card.
  final double? maxWidth;

  /// Vertical spacing between header, body content, and action footer.
  final double? contentSpacing;

  /// Spacing between action buttons (horizontal or vertical).
  final double? actionSpacing;

  /// Spring specification for open transitions.
  final OrionSpringSpec? springSpec;

  /// Spring specification for close transitions.
  final OrionSpringSpec? dismissSpringSpec;

  /// Convenience factory creating a style with only named properties.
  factory OrionDialogStyle.from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    bool? frosted,
    Color? barrierColor,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
    double? contentSpacing,
    double? actionSpacing,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? dismissSpringSpec,
  }) {
    return OrionDialogStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      shadow: shadow,
      frosted: frosted,
      barrierColor: barrierColor,
      padding: padding,
      maxWidth: maxWidth,
      contentSpacing: contentSpacing,
      actionSpacing: actionSpacing,
      springSpec: springSpec,
      dismissSpringSpec: dismissSpringSpec,
    );
  }

  /// Returns a copy with the provided fields replaced.
  OrionDialogStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    bool? frosted,
    Color? barrierColor,
    EdgeInsetsGeometry? padding,
    double? maxWidth,
    double? contentSpacing,
    double? actionSpacing,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? dismissSpringSpec,
  }) {
    return OrionDialogStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadow: shadow ?? this.shadow,
      frosted: frosted ?? this.frosted,
      barrierColor: barrierColor ?? this.barrierColor,
      padding: padding ?? this.padding,
      maxWidth: maxWidth ?? this.maxWidth,
      contentSpacing: contentSpacing ?? this.contentSpacing,
      actionSpacing: actionSpacing ?? this.actionSpacing,
      springSpec: springSpec ?? this.springSpec,
      dismissSpringSpec: dismissSpringSpec ?? this.dismissSpringSpec,
    );
  }

  /// Merges this style with [other], where [other]'s non-null fields take precedence.
  OrionDialogStyle merge(OrionDialogStyle? other) {
    if (other == null) return this;
    return OrionDialogStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      frosted: other.frosted ?? frosted,
      barrierColor: other.barrierColor ?? barrierColor,
      padding: other.padding ?? padding,
      maxWidth: other.maxWidth ?? maxWidth,
      contentSpacing: other.contentSpacing ?? contentSpacing,
      actionSpacing: other.actionSpacing ?? actionSpacing,
      springSpec: other.springSpec ?? springSpec,
      dismissSpringSpec: other.dismissSpringSpec ?? dismissSpringSpec,
    );
  }

  /// Linearly interpolates between two [OrionDialogStyle]s.
  static OrionDialogStyle? lerp(
    OrionDialogStyle? a,
    OrionDialogStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null) return b;
    if (b == null) return a;
    return OrionDialogStyle(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
      frosted: t < 0.5 ? a.frosted : b.frosted,
      barrierColor: Color.lerp(a.barrierColor, b.barrierColor, t),
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      maxWidth: lerpDouble(a.maxWidth, b.maxWidth, t),
      contentSpacing: lerpDouble(a.contentSpacing, b.contentSpacing, t),
      actionSpacing: lerpDouble(a.actionSpacing, b.actionSpacing, t),
      springSpec: t < 0.5 ? a.springSpec : b.springSpec,
      dismissSpringSpec: t < 0.5 ? a.dismissSpringSpec : b.dismissSpringSpec,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrionDialogStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          listEquals(shadow, other.shadow) &&
          frosted == other.frosted &&
          barrierColor == other.barrierColor &&
          padding == other.padding &&
          maxWidth == other.maxWidth &&
          contentSpacing == other.contentSpacing &&
          actionSpacing == other.actionSpacing &&
          springSpec == other.springSpec &&
          dismissSpringSpec == other.dismissSpringSpec;

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    shadow == null ? null : Object.hashAll(shadow!),
    frosted,
    barrierColor,
    padding,
    maxWidth,
    contentSpacing,
    actionSpacing,
    springSpec,
    dismissSpringSpec,
  );
}
