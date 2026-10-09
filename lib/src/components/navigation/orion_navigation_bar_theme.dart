import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/navigation/orion_navigation_bar_style.dart';

/// Theme-level defaults for every navigation bar.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionNavigationTheme(...)])` - so a
/// project re-skins its bars in one place. The effective style resolves the
/// built-in defaults, then [defaultStyle], then the instance style passed to
/// the widget; when no extension is registered the bar falls back to
/// [fallback] and behaves exactly as it does without this class.
@immutable
class OrionNavigationTheme extends ThemeExtension<OrionNavigationTheme> {
  const OrionNavigationTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionNavigationBarStyle? defaultStyle;

  /// Used when no [OrionNavigationTheme] is registered: no overrides.
  static const OrionNavigationTheme fallback = OrionNavigationTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionNavigationTheme copyWith({OrionNavigationBarStyle? defaultStyle}) {
    return OrionNavigationTheme(
      defaultStyle: defaultStyle ?? this.defaultStyle,
    );
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionNavigationTheme lerp(
    ThemeExtension<OrionNavigationTheme>? other,
    double t,
  ) {
    if (other is! OrionNavigationTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionNavigationTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
