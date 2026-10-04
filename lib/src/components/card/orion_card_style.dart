import 'package:flutter/material.dart';

import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Resolved visual tokens for an [OrionCard].
@immutable
class OrionCardStyle {
  const OrionCardStyle({
    required this.background,
    required this.border,
    required this.radius,
    required this.padding,
    required this.shadow,
    this.blurSigma,
  });

  /// Surface tint painted above the static backdrop.
  final Color background;

  /// Surface border.
  final BorderSide border;

  /// Surface corner radius.
  final BorderRadius radius;

  /// Content padding.
  final EdgeInsetsGeometry padding;

  /// Surface shadow recipe.
  final List<BoxShadow> shadow;

  /// Backdrop blur sigma; null keeps the card opaque.
  final double? blurSigma;

  /// Resolves the style for a [frosted] card from ambient tokens.
  static OrionCardStyle resolve({
    required ColorScheme scheme,
    required OrionThemeData theme,
    required bool frosted,
  }) {
    return OrionCardStyle(
      background: frosted
          ? scheme.surface.withValues(alpha: 0.72)
          : scheme.surfaceContainer,
      border: BorderSide(color: scheme.outlineVariant),
      radius: BorderRadius.circular(theme.surfaceRadius),
      padding: const EdgeInsets.all(OrionSpacing.space16),
      shadow: theme.shadow,
      blurSigma: frosted ? theme.blurSigma : null,
    );
  }
}
