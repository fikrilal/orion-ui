import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/progress/orion_progress_style.dart';

/// Theme-level defaults for every progress bar.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionProgressTheme(...)])` - so a
/// project re-skins its progress in one place. The effective style resolves
/// the built-in defaults, then [defaultStyle], then the instance style passed
/// to the widget; when no extension is registered the bars fall back to
/// [fallback] and behave exactly as they do without this class.
@immutable
class OrionProgressTheme extends ThemeExtension<OrionProgressTheme> {
  const OrionProgressTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionProgressStyle? defaultStyle;

  /// Used when no [OrionProgressTheme] is registered: no overrides.
  static const OrionProgressTheme fallback = OrionProgressTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionProgressTheme copyWith({OrionProgressStyle? defaultStyle}) {
    return OrionProgressTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionProgressTheme lerp(ThemeExtension<OrionProgressTheme>? other, double t) {
    if (other is! OrionProgressTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionProgressTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
