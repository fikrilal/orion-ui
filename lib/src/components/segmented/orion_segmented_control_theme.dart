import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/segmented/orion_segmented_control_style.dart';

/// Theme-level defaults for every [OrionSegmentedControl].
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionSegmentedControlTheme(...)])` -
/// so a project re-skins its segmented controls in one place. The effective
/// style resolves the built-in defaults, then [defaultStyle], then the
/// instance style passed to the widget; when no extension is registered the
/// control falls back to [fallback] and behaves exactly as it does without
/// this class.
@immutable
class OrionSegmentedControlTheme
    extends ThemeExtension<OrionSegmentedControlTheme> {
  const OrionSegmentedControlTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionSegmentedControlStyle? defaultStyle;

  /// Used when no [OrionSegmentedControlTheme] is registered: no overrides.
  static const OrionSegmentedControlTheme fallback =
      OrionSegmentedControlTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionSegmentedControlTheme copyWith({
    OrionSegmentedControlStyle? defaultStyle,
  }) {
    return OrionSegmentedControlTheme(
      defaultStyle: defaultStyle ?? this.defaultStyle,
    );
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionSegmentedControlTheme lerp(
    ThemeExtension<OrionSegmentedControlTheme>? other,
    double t,
  ) {
    if (other is! OrionSegmentedControlTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSegmentedControlTheme &&
        other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
