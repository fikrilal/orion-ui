import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/checkbox/orion_checkbox_style.dart';

/// Theme-level defaults for every checkbox.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionCheckboxTheme(...)])` - so a
/// project re-skins its boxes in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the instance style passed to
/// the widget; when no extension is registered the boxes fall back to
/// [fallback] and behave exactly as they do without this class.
@immutable
class OrionCheckboxTheme extends ThemeExtension<OrionCheckboxTheme> {
  const OrionCheckboxTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionCheckboxStyle? defaultStyle;

  /// Used when no [OrionCheckboxTheme] is registered: no overrides.
  static const OrionCheckboxTheme fallback = OrionCheckboxTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionCheckboxTheme copyWith({OrionCheckboxStyle? defaultStyle}) {
    return OrionCheckboxTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionCheckboxTheme lerp(ThemeExtension<OrionCheckboxTheme>? other, double t) {
    if (other is! OrionCheckboxTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCheckboxTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
