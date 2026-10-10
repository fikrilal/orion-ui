import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/card/orion_card_style.dart';

/// Theme-level defaults for every card.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionCardTheme(...)])` - so a project
/// re-skins its surfaces in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the instance style passed to
/// the widget; the `padding` and `radius` params merge last. When no extension
/// is registered the cards fall back to [fallback] and behave exactly as they
/// do without this class.
@immutable
class OrionCardTheme extends ThemeExtension<OrionCardTheme> {
  const OrionCardTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionCardStyle? defaultStyle;

  /// Used when no [OrionCardTheme] is registered: no overrides.
  static const OrionCardTheme fallback = OrionCardTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionCardTheme copyWith({OrionCardStyle? defaultStyle}) {
    return OrionCardTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionCardTheme lerp(ThemeExtension<OrionCardTheme>? other, double t) {
    if (other is! OrionCardTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCardTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
