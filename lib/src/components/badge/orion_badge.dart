import 'package:flutter/material.dart';

import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Small pill-shaped label or status indicator.
///
/// Typography is host-owned: the badge applies the ambient `labelSmall` style
/// through [DefaultTextStyle], so a plain `Text` child inherits it.
class OrionBadge extends StatelessWidget {
  const OrionBadge({
    super.key,
    required this.child,
    this.backgroundColor,
    this.foregroundColor,
  });

  /// Badge content.
  final Widget child;

  /// Overrides the default container color.
  final Color? backgroundColor;

  /// Overrides the default label color.
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;

    return DefaultTextStyle(
      style: (theme.textTheme.labelSmall ?? const TextStyle()).copyWith(
        color: foregroundColor ?? scheme.onSurfaceVariant,
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor ?? scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: OrionSpacing.space8,
            vertical: OrionSpacing.space4,
          ),
          child: child,
        ),
      ),
    );
  }
}
