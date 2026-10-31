import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/slider/orion_slider_style.dart';

/// Theme-level defaults for every [OrionSlider] and `OrionRangeSlider`.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionSliderTheme(...)])` - so a project
/// re-skins its sliders in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the instance style passed to
/// the widget; when no extension is registered the sliders fall back to
/// [fallback] and behave exactly as they do without this class.
@immutable
class OrionSliderTheme extends ThemeExtension<OrionSliderTheme> {
  const OrionSliderTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionSliderStyle? defaultStyle;

  /// Used when no [OrionSliderTheme] is registered: no overrides.
  static const OrionSliderTheme fallback = OrionSliderTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionSliderTheme copyWith({OrionSliderStyle? defaultStyle}) {
    return OrionSliderTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionSliderTheme lerp(ThemeExtension<OrionSliderTheme>? other, double t) {
    if (other is! OrionSliderTheme) {
      return this;
    }
    return OrionSliderTheme(
      defaultStyle: OrionSliderStyle.lerp(defaultStyle, other.defaultStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSliderTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
