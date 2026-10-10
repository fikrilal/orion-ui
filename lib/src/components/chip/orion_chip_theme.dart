import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/chip/orion_chip_style.dart';

/// Theme-level defaults for every chip.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionChipTheme(...)])` - so a project
/// re-skins its chips in one place. The effective style resolves the built-in
/// presets, then [defaultStyle], then the instance style passed to the widget;
/// when no extension is registered the chips fall back to [fallback] and
/// behave exactly as they do without this class.
@immutable
class OrionChipTheme extends ThemeExtension<OrionChipTheme> {
  const OrionChipTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionChipStyle? defaultStyle;

  /// Used when no [OrionChipTheme] is registered: no overrides.
  static const OrionChipTheme fallback = OrionChipTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionChipTheme copyWith({OrionChipStyle? defaultStyle}) {
    return OrionChipTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionChipTheme lerp(ThemeExtension<OrionChipTheme>? other, double t) {
    if (other is! OrionChipTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionChipTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
