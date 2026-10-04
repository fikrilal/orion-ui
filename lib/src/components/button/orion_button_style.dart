import 'package:flutter/material.dart';

import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Visual treatment of an [OrionButton], orthogonal to size and color roles.
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

/// Control height of an [OrionButton].
enum OrionButtonSize { small, medium, large }

/// Resolved visual tokens for an [OrionButton].
@immutable
class OrionButtonStyle {
  const OrionButtonStyle({
    required this.foreground,
    this.background,
    this.border,
    this.shadow,
    this.height,
    this.padding,
    this.radius,
    this.textStyle,
  });

  /// Label, icon, and progress color.
  final Color foreground;

  /// Surface color; null keeps the button transparent.
  final Color? background;

  /// Surface border, including the focus ring when focused.
  final BorderSide? border;

  /// Outer shadow, used by the glow variant.
  final List<BoxShadow>? shadow;

  /// Visual control height before hit-target padding.
  final double? height;

  /// Content padding.
  final EdgeInsetsGeometry? padding;

  /// Surface corner radius.
  final BorderRadius? radius;

  /// Label text style, taken from the host [TextTheme].
  final TextStyle? textStyle;

  /// Resolves the style for [variant] and [size] from ambient tokens.
  static OrionButtonStyle resolve({
    required OrionButtonVariant variant,
    required OrionButtonSize size,
    required ColorScheme scheme,
    required OrionThemeData theme,
    required TextTheme textTheme,
    required bool enabled,
    required bool focused,
  }) {
    final (
      double height,
      EdgeInsetsGeometry padding,
      TextStyle? textStyle,
    ) = switch (size) {
      OrionButtonSize.small => (
        OrionSizing.controlHeightSmall,
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space12),
        textTheme.labelMedium,
      ),
      OrionButtonSize.medium => (
        OrionSizing.controlHeightMedium,
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space16),
        textTheme.labelLarge,
      ),
      OrionButtonSize.large => (
        OrionSizing.controlHeightLarge,
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space20),
        textTheme.titleMedium,
      ),
    };

    final Color disabledContainer = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledForeground = scheme.onSurface.withValues(alpha: 0.38);

    Color? background;
    Color? foreground;
    BorderSide? border;
    List<BoxShadow>? shadow;

    switch (variant) {
      case OrionButtonVariant.solid:
        background = enabled ? scheme.primary : disabledContainer;
        foreground = enabled ? scheme.onPrimary : disabledForeground;
      case OrionButtonVariant.bordered:
        foreground = enabled ? scheme.primary : disabledForeground;
        border = BorderSide(
          color: enabled ? scheme.outline : disabledContainer,
        );
      case OrionButtonVariant.glow:
        background = enabled ? scheme.primary : disabledContainer;
        foreground = enabled ? scheme.onPrimary : disabledForeground;
        shadow = [
          BoxShadow(
            color: scheme.primary.withValues(alpha: enabled ? 0.35 : 0.12),
            blurRadius: 16.0,
            spreadRadius: -2.0,
          ),
        ];
      case OrionButtonVariant.flat:
        foreground = enabled ? scheme.primary : disabledForeground;
    }

    if (focused && enabled) {
      final Color ring = switch (variant) {
        OrionButtonVariant.solid || OrionButtonVariant.glow => scheme.onSurface,
        OrionButtonVariant.bordered ||
        OrionButtonVariant.flat => scheme.primary,
      };
      border = BorderSide(color: ring, width: 2.0);
    }

    return OrionButtonStyle(
      foreground: foreground,
      background: background,
      border: border,
      shadow: shadow,
      height: height,
      padding: padding,
      radius: BorderRadius.circular(theme.controlRadius),
      textStyle: textStyle,
    );
  }
}
