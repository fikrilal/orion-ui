import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/radio/orion_radio_style.dart';

/// Theme-level defaults for every radio.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionRadioTheme(...)])` - so a project
/// re-skins its circles in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the instance style passed to
/// the widget; when no extension is registered the circles fall back to
/// [fallback] and behave exactly as they do without this class.
@immutable
class OrionRadioTheme extends ThemeExtension<OrionRadioTheme> {
  const OrionRadioTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionRadioStyle? defaultStyle;

  /// Used when no [OrionRadioTheme] is registered: no overrides.
  static const OrionRadioTheme fallback = OrionRadioTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionRadioTheme copyWith({OrionRadioStyle? defaultStyle}) {
    return OrionRadioTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionRadioTheme lerp(ThemeExtension<OrionRadioTheme>? other, double t) {
    if (other is! OrionRadioTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionRadioTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
