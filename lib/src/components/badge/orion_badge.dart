import 'package:flutter/material.dart';

import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Pill size. [medium] is the default and matches the original badge metrics.
enum OrionBadgeSize { small, medium, large }

/// Small pill-shaped label or status indicator.
///
/// Typography is host-owned. [OrionBadgeSize] selects a text style from the
/// ambient [TextTheme], and a plain `Text` child inherits it.
class OrionBadge extends StatelessWidget {
  const OrionBadge({
    super.key,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
    this.border,
    this.size = OrionBadgeSize.medium,
  });

  /// Badge content.
  final Widget child;

  /// Overrides the default container color.
  final Color? backgroundColor;

  /// Overrides the default label color.
  final Color? foregroundColor;

  /// Optional outline drawn inside the pill. Null draws no border.
  final BorderSide? border;

  /// Padding and text style step. Defaults to [OrionBadgeSize.medium].
  final OrionBadgeSize size;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final (EdgeInsets padding, TextStyle? textStyle) = switch (size) {
      OrionBadgeSize.small => (
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space4,
          vertical: OrionSpacing.space4,
        ),
        theme.textTheme.labelSmall,
      ),
      OrionBadgeSize.medium => (
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space8,
          vertical: OrionSpacing.space4,
        ),
        theme.textTheme.labelSmall,
      ),
      OrionBadgeSize.large => (
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space12,
          vertical: OrionSpacing.space8,
        ),
        theme.textTheme.labelMedium,
      ),
    };

    return DefaultTextStyle(
      style: (textStyle ?? const TextStyle()).copyWith(
        color: foregroundColor ?? scheme.onSurfaceVariant,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
          border: border == null ? null : Border.fromBorderSide(border!),
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
