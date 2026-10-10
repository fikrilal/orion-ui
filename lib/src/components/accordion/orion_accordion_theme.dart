import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/accordion/orion_accordion_style.dart';

/// Theme-level defaults for every accordion.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionAccordionTheme(...)])` - so a
/// project re-skins its rows in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the instance style passed to
/// the widget; when no extension is registered the rows fall back to
/// [fallback] and behave exactly as they do without this class.
@immutable
class OrionAccordionTheme extends ThemeExtension<OrionAccordionTheme> {
  const OrionAccordionTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionAccordionStyle? defaultStyle;

  /// Used when no [OrionAccordionTheme] is registered: no overrides.
  static const OrionAccordionTheme fallback = OrionAccordionTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionAccordionTheme copyWith({OrionAccordionStyle? defaultStyle}) {
    return OrionAccordionTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionAccordionTheme lerp(
    ThemeExtension<OrionAccordionTheme>? other,
    double t,
  ) {
    if (other is! OrionAccordionTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionAccordionTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
