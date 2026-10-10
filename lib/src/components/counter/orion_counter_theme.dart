import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/counter/orion_counter_style.dart';

/// Theme-level defaults for every counter.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionCounterTheme(...)])` - so a
/// project re-skins its readouts in one place. The effective style resolves
/// the built-in presets, then [defaultStyle], then the instance style passed
/// to the widget; when no extension is registered the counters fall back to
/// [fallback] and behave exactly as they do without this class.
@immutable
class OrionCounterTheme extends ThemeExtension<OrionCounterTheme> {
  const OrionCounterTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionCounterStyle? defaultStyle;

  /// Used when no [OrionCounterTheme] is registered: no overrides.
  static const OrionCounterTheme fallback = OrionCounterTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionCounterTheme copyWith({OrionCounterStyle? defaultStyle}) {
    return OrionCounterTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionCounterTheme lerp(ThemeExtension<OrionCounterTheme>? other, double t) {
    if (other is! OrionCounterTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionCounterTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
