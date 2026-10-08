import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/badge/orion_badge.dart';
import 'package:orion_ui/src/components/badge/orion_badge_style.dart';

/// Theme-level defaults for every [OrionBadge].
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionBadgeTheme(...)])` - so a
/// project re-skins its badges in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the [variantStyles] entry for
/// the badge's variant, then the instance style; when no extension is
/// registered the badge falls back to [fallback] and behaves exactly as it
/// does without this class.
@immutable
class OrionBadgeTheme extends ThemeExtension<OrionBadgeTheme> {
  const OrionBadgeTheme({this.defaultStyle, this.variantStyles});

  /// Style applied before the per-variant entries and any instance overrides.
  final OrionBadgeStyle? defaultStyle;

  /// Per-variant overrides, applied on top of [defaultStyle].
  final Map<OrionBadgeVariant, OrionBadgeStyle>? variantStyles;

  /// Used when no [OrionBadgeTheme] is registered: no overrides.
  static const OrionBadgeTheme fallback = OrionBadgeTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionBadgeTheme copyWith({
    OrionBadgeStyle? defaultStyle,
    Map<OrionBadgeVariant, OrionBadgeStyle>? variantStyles,
  }) {
    return OrionBadgeTheme(
      defaultStyle: defaultStyle ?? this.defaultStyle,
      variantStyles: variantStyles ?? this.variantStyles,
    );
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionBadgeTheme lerp(ThemeExtension<OrionBadgeTheme>? other, double t) {
    if (other is! OrionBadgeTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionBadgeTheme &&
        other.defaultStyle == defaultStyle &&
        mapEquals(other.variantStyles, variantStyles);
  }

  @override
  int get hashCode => Object.hash(defaultStyle, variantStyles);
}
