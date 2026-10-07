import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Visual treatment of a button, orthogonal to size and color roles.
enum OrionButtonVariant {
  /// Filled with [ColorScheme.primary].
  solid,

  /// Transparent with an outline border and primary label.
  bordered,

  /// Filled with a soft primary glow shadow.
  glow,

  /// Transparent with a primary label and no border.
  flat,
}

/// Control height of a button.
enum OrionButtonSize { small, medium, large }

/// The overridable contract for how a button looks and feels.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in preset (`OrionButtonPresets`), the theme's `OrionButtonTheme`, and
/// the instance style passed to the widget. Every field is nullable; a null
/// field falls through to the layer beneath it, so an override changes exactly
/// what it names and nothing else.
///
/// The four visual fields resolve through the widget's live [WidgetState]s
/// (`disabled`, `focused`, `hovered`, `pressed`), which is where state-specific
/// colors belong. [OrionButtonStyle.from] is the flat sugar for the common
/// case: one value per field, applied to every state.
@immutable
class OrionButtonStyle {
  const OrionButtonStyle({
    this.background,
    this.foreground,
    this.border,
    this.shadow,
    this.borderRadius,
    this.height,
    this.padding,
    this.minWidth,
    this.textStyle,
    this.iconSize,
    this.gap,
    this.pressedScale,
    this.pressSpring,
    this.releaseSpring,
    this.hapticType,
    this.impactHapticType,
  });

  /// Surface color, resolved through the live [WidgetState]s.
  final WidgetStateProperty<Color?>? background;

  /// Label, icon and progress color, resolved through the live [WidgetState]s.
  final WidgetStateProperty<Color?>? foreground;

  /// Surface border, including the focus ring, resolved through the live
  /// [WidgetState]s.
  final WidgetStateProperty<BorderSide?>? border;

  /// Outer shadow, resolved through the live [WidgetState]s.
  final WidgetStateProperty<List<BoxShadow>?>? shadow;

  /// Surface corner radius.
  final BorderRadius? borderRadius;

  /// Visual control height before hit-target padding.
  final double? height;

  /// Content padding.
  final EdgeInsetsGeometry? padding;

  /// Smallest painted width; the 44 pt hit-target floor still applies on top.
  final double? minWidth;

  /// Label text style, taken from the host [TextTheme].
  final TextStyle? textStyle;

  /// Icon size passed to the leading and trailing slots through [IconTheme].
  final double? iconSize;

  /// Space between the leading slot, the label and the trailing slot.
  final double? gap;

  /// Target scale while the button is held. Falls back to the theme's
  /// `OrionThemeData.pressScale` when null.
  final double? pressedScale;

  /// Spring governing compression on pointer down. Falls back to the theme's
  /// `OrionThemeData.pressSpring` when null.
  final OrionSpringSpec? pressSpring;

  /// Spring governing release on pointer up or cancel. Falls back to the
  /// theme's `OrionThemeData.releaseSpring` when null.
  final OrionSpringSpec? releaseSpring;

  /// Tactile tick on an accepted tap. Falls back to the theme's
  /// `OrionThemeData.selectionHaptic` when null.
  final OrionHapticType? hapticType;

  /// Tactile cue on long-press recognition. Falls back to the theme's
  /// `OrionThemeData.impactHaptic` when null.
  final OrionHapticType? impactHapticType;

  /// Returns a copy with the provided fields replaced.
  OrionButtonStyle copyWith({
    WidgetStateProperty<Color?>? background,
    WidgetStateProperty<Color?>? foreground,
    WidgetStateProperty<BorderSide?>? border,
    WidgetStateProperty<List<BoxShadow>?>? shadow,
    BorderRadius? borderRadius,
    double? height,
    EdgeInsetsGeometry? padding,
    double? minWidth,
    TextStyle? textStyle,
    double? iconSize,
    double? gap,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
    OrionHapticType? impactHapticType,
  }) {
    return OrionButtonStyle(
      background: background ?? this.background,
      foreground: foreground ?? this.foreground,
      border: border ?? this.border,
      shadow: shadow ?? this.shadow,
      borderRadius: borderRadius ?? this.borderRadius,
      height: height ?? this.height,
      padding: padding ?? this.padding,
      minWidth: minWidth ?? this.minWidth,
      textStyle: textStyle ?? this.textStyle,
      iconSize: iconSize ?? this.iconSize,
      gap: gap ?? this.gap,
      pressedScale: pressedScale ?? this.pressedScale,
      pressSpring: pressSpring ?? this.pressSpring,
      releaseSpring: releaseSpring ?? this.releaseSpring,
      hapticType: hapticType ?? this.hapticType,
      impactHapticType: impactHapticType ?? this.impactHapticType,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  ///
  /// This is the layer merge: preset, then theme, then instance. A null field
  /// in [other] never erases a value resolved beneath it.
  OrionButtonStyle merge(OrionButtonStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionButtonStyle(
      background: other.background ?? background,
      foreground: other.foreground ?? foreground,
      border: other.border ?? border,
      shadow: other.shadow ?? shadow,
      borderRadius: other.borderRadius ?? borderRadius,
      height: other.height ?? height,
      padding: other.padding ?? padding,
      minWidth: other.minWidth ?? minWidth,
      textStyle: other.textStyle ?? textStyle,
      iconSize: other.iconSize ?? iconSize,
      gap: other.gap ?? gap,
      pressedScale: other.pressedScale ?? pressedScale,
      pressSpring: other.pressSpring ?? pressSpring,
      releaseSpring: other.releaseSpring ?? releaseSpring,
      hapticType: other.hapticType ?? hapticType,
      impactHapticType: other.impactHapticType ?? impactHapticType,
    );
  }

  /// Builds a style from plain values, each applied to every state.
  ///
  /// The flat sugar for the common case: one value per field, wrapped in
  /// [WidgetStatePropertyAll]. Use the main constructor when a value must
  /// differ by state - a plain value here, including for a disabled button,
  /// is exactly what the caller asked for.
  static OrionButtonStyle from({
    Color? backgroundColor,
    Color? foregroundColor,
    Color? borderColor,
    List<BoxShadow>? shadow,
    BorderRadius? borderRadius,
    double? height,
    EdgeInsetsGeometry? padding,
    double? minWidth,
    TextStyle? textStyle,
    double? iconSize,
    double? gap,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
    OrionHapticType? impactHapticType,
  }) {
    return OrionButtonStyle(
      background: backgroundColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(backgroundColor),
      foreground: foregroundColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(foregroundColor),
      border: borderColor == null
          ? null
          : WidgetStatePropertyAll<BorderSide?>(BorderSide(color: borderColor)),
      shadow: shadow == null
          ? null
          : WidgetStatePropertyAll<List<BoxShadow>?>(shadow),
      borderRadius: borderRadius,
      height: height,
      padding: padding,
      minWidth: minWidth,
      textStyle: textStyle,
      iconSize: iconSize,
      gap: gap,
      pressedScale: pressedScale,
      pressSpring: pressSpring,
      releaseSpring: releaseSpring,
      hapticType: hapticType,
      impactHapticType: impactHapticType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionButtonStyle &&
        other.background == background &&
        other.foreground == foreground &&
        other.border == border &&
        other.shadow == shadow &&
        other.borderRadius == borderRadius &&
        other.height == height &&
        other.padding == padding &&
        other.minWidth == minWidth &&
        other.textStyle == textStyle &&
        other.iconSize == iconSize &&
        other.gap == gap &&
        other.pressedScale == pressedScale &&
        other.pressSpring == pressSpring &&
        other.releaseSpring == releaseSpring &&
        other.hapticType == hapticType &&
        other.impactHapticType == impactHapticType;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    background,
    foreground,
    border,
    shadow,
    borderRadius,
    height,
    padding,
    minWidth,
    textStyle,
    iconSize,
    gap,
    pressedScale,
    pressSpring,
    releaseSpring,
    hapticType,
    impactHapticType,
  ]);
}
