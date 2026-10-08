import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/badge/orion_badge.dart';
import 'package:orion_ui/src/components/badge/orion_badge_style.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for every [OrionBadgeVariant] and [OrionBadgeSize].
///
/// This is the bottom layer of the badge's three-layer resolution; the
/// variant pairs are scheme roles, and the size steps are the pill's padding
/// and type.
abstract final class OrionBadgePresets {
  /// Resolves the built-in style against the ambient scheme and type scale.
  static OrionBadgeStyle resolve({
    required OrionBadgeVariant variant,
    required OrionBadgeSize size,
    required ColorScheme scheme,
    required TextTheme textTheme,
  }) {
    final (EdgeInsets padding, TextStyle? textStyle) = switch (size) {
      OrionBadgeSize.small => (
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space4,
          vertical: OrionSpacing.space4,
        ),
        textTheme.labelSmall,
      ),
      OrionBadgeSize.medium => (
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space8,
          vertical: OrionSpacing.space4,
        ),
        textTheme.labelSmall,
      ),
      OrionBadgeSize.large => (
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space12,
          vertical: OrionSpacing.space8,
        ),
        textTheme.labelMedium,
      ),
    };
    final (
      Color background,
      Color foreground,
      BorderSide? border,
    ) = switch (variant) {
      OrionBadgeVariant.neutral => (
        scheme.surfaceContainerHighest,
        scheme.onSurfaceVariant,
        null,
      ),
      OrionBadgeVariant.primary => (scheme.primary, scheme.onPrimary, null),
      OrionBadgeVariant.secondary => (
        scheme.secondary,
        scheme.onSecondary,
        null,
      ),
      OrionBadgeVariant.error => (scheme.error, scheme.onError, null),
      OrionBadgeVariant.outline => (
        scheme.surface,
        scheme.onSurface,
        BorderSide(color: scheme.outline),
      ),
    };
    return OrionBadgeStyle(
      background: background,
      foreground: foreground,
      border: border,
      padding: padding,
      textStyle: textStyle,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      dotSize: 8,
      popScale: 1.1,
    );
  }
}
