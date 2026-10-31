import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/swipe/orion_swipe_style.dart';

/// Theme-level defaults for every [OrionSwipeActionRow].
///
/// Install through `OrionTheme.apply(base, extensions: [OrionSwipeTheme(...)])`
/// to standardize action widths, corner radii, floating pill gaps, or motion
/// styles across an app.
@immutable
class OrionSwipeTheme extends ThemeExtension<OrionSwipeTheme> {
  const OrionSwipeTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionSwipeStyle? defaultStyle;

  /// Used when no [OrionSwipeTheme] is registered: no overrides.
  static const OrionSwipeTheme fallback = OrionSwipeTheme();

  @override
  OrionSwipeTheme copyWith({OrionSwipeStyle? defaultStyle}) {
    return OrionSwipeTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionSwipeTheme lerp(ThemeExtension<OrionSwipeTheme>? other, double t) {
    if (other is! OrionSwipeTheme) {
      return this;
    }
    return OrionSwipeTheme(
      defaultStyle: OrionSwipeStyle.lerp(defaultStyle, other.defaultStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSwipeTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
