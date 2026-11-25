import 'dart:ui' show lerpDouble;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Visual surface tone for an [OrionTooltip].
enum OrionTooltipTone {
  /// High-contrast inverted pill (`inverseSurface` / `onInverseSurface`).
  /// Ideal for concise icon labels and keyboard shortcuts.
  inverted,

  /// Elevated card surface with a hairline border (`surface` in light mode,
  /// `surfaceContainerHighest` in dark mode). Ideal for rich contextual
  /// bubbles containing avatars, status lines, or multi-line explanations.
  surface,
}

/// The visual and physical styling contract for [OrionTooltip].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionTooltipPresets`, the ambient `OrionTooltipTheme`, and the
/// instance style passed to the tooltip.
@immutable
class OrionTooltipStyle {
  const OrionTooltipStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.shadow,
    this.frosted,
    this.padding,
    this.textStyle,
    this.gap,
    this.showArrow,
    this.arrowSize,
    this.maxWidth,
    this.springSpec,
    this.dismissSpringSpec,
  });

  /// Tooltip container background fill color.
  final Color? backgroundColor;

  /// Optional hairline border stroke color around the tooltip and arrow.
  final Color? borderColor;

  /// Stroke width of the tooltip border (`0.0` disables the border).
  final double? borderWidth;

  /// Tooltip container border radius.
  final BorderRadius? borderRadius;

  /// Elevation drop shadow list.
  final List<BoxShadow>? shadow;

  /// Whether to render a static frosted blur behind the tooltip content.
  final bool? frosted;

  /// Internal padding for tooltip text or rich content.
  final EdgeInsetsGeometry? padding;

  /// Typography style for the tooltip message and default foreground color for
  /// `richMessage` subtrees.
  final TextStyle? textStyle;

  /// Space in logical pixels between trigger boundary and tooltip surface.
  final double? gap;

  /// Whether to render a pointing caret arrow toward the trigger.
  final bool? showArrow;

  /// Dimensions of the pointing caret arrow (width along edge, height toward trigger).
  final Size? arrowSize;

  /// Maximum width constraint for tooltip content.
  final double? maxWidth;

  /// Spring specification for open transitions.
  final OrionSpringSpec? springSpec;

  /// Spring specification for close transitions.
  final OrionSpringSpec? dismissSpringSpec;

  /// Convenience factory creating a style with only named properties.
  factory OrionTooltipStyle.from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    bool? frosted,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    double? gap,
    bool? showArrow,
    Size? arrowSize,
    double? maxWidth,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? dismissSpringSpec,
  }) {
    return OrionTooltipStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      shadow: shadow,
      frosted: frosted,
      padding: padding,
      textStyle: textStyle,
      gap: gap,
      showArrow: showArrow,
      arrowSize: arrowSize,
      maxWidth: maxWidth,
      springSpec: springSpec,
      dismissSpringSpec: dismissSpringSpec,
    );
  }

  /// Returns a copy with the provided fields replaced.
  OrionTooltipStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    bool? frosted,
    EdgeInsetsGeometry? padding,
    TextStyle? textStyle,
    double? gap,
    bool? showArrow,
    Size? arrowSize,
    double? maxWidth,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? dismissSpringSpec,
  }) {
    return OrionTooltipStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadow: shadow ?? this.shadow,
      frosted: frosted ?? this.frosted,
      padding: padding ?? this.padding,
      textStyle: textStyle ?? this.textStyle,
      gap: gap ?? this.gap,
      showArrow: showArrow ?? this.showArrow,
      arrowSize: arrowSize ?? this.arrowSize,
      maxWidth: maxWidth ?? this.maxWidth,
      springSpec: springSpec ?? this.springSpec,
      dismissSpringSpec: dismissSpringSpec ?? this.dismissSpringSpec,
    );
  }

  /// Merges this style with [other], where [other]'s non-null fields take precedence.
  ///
  /// When both styles provide a [textStyle], they are merged via
  /// [TextStyle.merge] so partial overrides (e.g. changing only `fontSize`)
  /// preserve the preset foreground color and typography defaults.
  OrionTooltipStyle merge(OrionTooltipStyle? other) {
    if (other == null) return this;
    return OrionTooltipStyle(
      backgroundColor: other.backgroundColor ?? backgroundColor,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      borderRadius: other.borderRadius ?? borderRadius,
      shadow: other.shadow ?? shadow,
      frosted: other.frosted ?? frosted,
      padding: other.padding ?? padding,
      textStyle: textStyle != null && other.textStyle != null
          ? textStyle!.merge(other.textStyle)
          : (other.textStyle ?? textStyle),
      gap: other.gap ?? gap,
      showArrow: other.showArrow ?? showArrow,
      arrowSize: other.arrowSize ?? arrowSize,
      maxWidth: other.maxWidth ?? maxWidth,
      springSpec: other.springSpec ?? springSpec,
      dismissSpringSpec: other.dismissSpringSpec ?? dismissSpringSpec,
    );
  }

  /// Linearly interpolates between two [OrionTooltipStyle]s.
  static OrionTooltipStyle? lerp(
    OrionTooltipStyle? a,
    OrionTooltipStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null && b == null) return null;
    if (a == null) return t < 0.5 ? null : b;
    if (b == null) return t < 0.5 ? a : null;
    return OrionTooltipStyle(
      backgroundColor: Color.lerp(a.backgroundColor, b.backgroundColor, t),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      borderWidth: lerpDouble(a.borderWidth, b.borderWidth, t),
      borderRadius: BorderRadius.lerp(a.borderRadius, b.borderRadius, t),
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t),
      frosted: t < 0.5 ? a.frosted : b.frosted,
      padding: EdgeInsetsGeometry.lerp(a.padding, b.padding, t),
      textStyle: TextStyle.lerp(a.textStyle, b.textStyle, t),
      gap: lerpDouble(a.gap, b.gap, t),
      showArrow: t < 0.5 ? a.showArrow : b.showArrow,
      arrowSize: Size.lerp(a.arrowSize, b.arrowSize, t),
      maxWidth: lerpDouble(a.maxWidth, b.maxWidth, t),
      springSpec: t < 0.5 ? a.springSpec : b.springSpec,
      dismissSpringSpec: t < 0.5 ? a.dismissSpringSpec : b.dismissSpringSpec,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrionTooltipStyle &&
          runtimeType == other.runtimeType &&
          backgroundColor == other.backgroundColor &&
          borderColor == other.borderColor &&
          borderWidth == other.borderWidth &&
          borderRadius == other.borderRadius &&
          listEquals(shadow, other.shadow) &&
          frosted == other.frosted &&
          padding == other.padding &&
          textStyle == other.textStyle &&
          gap == other.gap &&
          showArrow == other.showArrow &&
          arrowSize == other.arrowSize &&
          maxWidth == other.maxWidth &&
          springSpec == other.springSpec &&
          dismissSpringSpec == other.dismissSpringSpec;

  @override
  int get hashCode => Object.hashAll([
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    shadow == null ? null : Object.hashAll(shadow!),
    frosted,
    padding,
    textStyle,
    gap,
    showArrow,
    arrowSize,
    maxWidth,
    springSpec,
    dismissSpringSpec,
  ]);
}
