import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The visual and physical styling contract for [OrionPopover] and [OrionMenu].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionPopoverPresets`, the ambient `OrionPopoverTheme`, and the
/// instance style passed to the popover.
@immutable
class OrionPopoverStyle {
  const OrionPopoverStyle({
    this.backgroundColor,
    this.borderColor,
    this.borderWidth,
    this.borderRadius,
    this.shadow,
    this.frosted,
    this.gap,
    this.padding,
    this.arrowSize,
    this.showArrow,
    this.springSpec,
    this.dismissSpringSpec,
    this.minWidth,
    this.maxWidth,
    this.minHeight,
    this.maxHeight,
  });

  /// Popover container background color.
  final Color? backgroundColor;

  /// Popover outline border color.
  final Color? borderColor;

  /// Popover outline border width.
  final double? borderWidth;

  /// Popover container border radius.
  final BorderRadius? borderRadius;

  /// Elevation box shadow list.
  final List<BoxShadow>? shadow;

  /// Whether to render a static frosted blur behind the popover content.
  final bool? frosted;

  /// Space in logical pixels between the trigger rect and the popover surface.
  final double? gap;

  /// Internal padding for popover body content.
  final EdgeInsetsGeometry? padding;

  /// Size of the pointed caret arrow (width, height).
  final Size? arrowSize;

  /// Whether to show the pointed caret arrow toward the trigger.
  final bool? showArrow;

  /// Spring specification for open transitions.
  final OrionSpringSpec? springSpec;

  /// Spring specification for close transitions.
  final OrionSpringSpec? dismissSpringSpec;

  /// Minimum width constraint.
  final double? minWidth;

  /// Maximum width constraint.
  final double? maxWidth;

  /// Minimum height constraint.
  final double? minHeight;

  /// Maximum height constraint.
  final double? maxHeight;

  /// Convenience factory creating a style with only specified properties.
  factory OrionPopoverStyle.from({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    bool? frosted,
    double? gap,
    EdgeInsetsGeometry? padding,
    Size? arrowSize,
    bool? showArrow,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? dismissSpringSpec,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return OrionPopoverStyle(
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      borderWidth: borderWidth,
      borderRadius: borderRadius,
      shadow: shadow,
      frosted: frosted,
      gap: gap,
      padding: padding,
      arrowSize: arrowSize,
      showArrow: showArrow,
      springSpec: springSpec,
      dismissSpringSpec: dismissSpringSpec,
      minWidth: minWidth,
      maxWidth: maxWidth,
      minHeight: minHeight,
      maxHeight: maxHeight,
    );
  }

  /// Returns a copy with the provided fields replaced.
  OrionPopoverStyle copyWith({
    Color? backgroundColor,
    Color? borderColor,
    double? borderWidth,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadow,
    bool? frosted,
    double? gap,
    EdgeInsetsGeometry? padding,
    Size? arrowSize,
    bool? showArrow,
    OrionSpringSpec? springSpec,
    OrionSpringSpec? dismissSpringSpec,
    double? minWidth,
    double? maxWidth,
    double? minHeight,
    double? maxHeight,
  }) {
    return OrionPopoverStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      borderRadius: borderRadius ?? this.borderRadius,
      shadow: shadow ?? this.shadow,
      frosted: frosted ?? this.frosted,
      gap: gap ?? this.gap,
      padding: padding ?? this.padding,
      arrowSize: arrowSize ?? this.arrowSize,
      showArrow: showArrow ?? this.showArrow,
      springSpec: springSpec ?? this.springSpec,
      dismissSpringSpec: dismissSpringSpec ?? this.dismissSpringSpec,
      minWidth: minWidth ?? this.minWidth,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      maxHeight: maxHeight ?? this.maxHeight,
    );
  }

  /// Returns a new style merging this style with [other], where non-null
  /// values in [other] override values in this style.
  OrionPopoverStyle merge(OrionPopoverStyle? other) {
    if (other == null) return this;
    return copyWith(
      backgroundColor: other.backgroundColor,
      borderColor: other.borderColor,
      borderWidth: other.borderWidth,
      borderRadius: other.borderRadius,
      shadow: other.shadow,
      frosted: other.frosted,
      gap: other.gap,
      padding: other.padding,
      arrowSize: other.arrowSize,
      showArrow: other.showArrow,
      springSpec: other.springSpec,
      dismissSpringSpec: other.dismissSpringSpec,
      minWidth: other.minWidth,
      maxWidth: other.maxWidth,
      minHeight: other.minHeight,
      maxHeight: other.maxHeight,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionPopoverStyle &&
        other.backgroundColor == backgroundColor &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        other.borderRadius == borderRadius &&
        listEquals(other.shadow, shadow) &&
        other.frosted == frosted &&
        other.gap == gap &&
        other.padding == padding &&
        other.arrowSize == arrowSize &&
        other.showArrow == showArrow &&
        other.springSpec == springSpec &&
        other.dismissSpringSpec == dismissSpringSpec &&
        other.minWidth == minWidth &&
        other.maxWidth == maxWidth &&
        other.minHeight == minHeight &&
        other.maxHeight == maxHeight;
  }

  @override
  int get hashCode => Object.hash(
    backgroundColor,
    borderColor,
    borderWidth,
    borderRadius,
    shadow == null ? null : Object.hashAll(shadow!),
    frosted,
    gap,
    padding,
    arrowSize,
    showArrow,
    springSpec,
    dismissSpringSpec,
    minWidth,
    maxWidth,
    minHeight,
    maxHeight,
  );
}
