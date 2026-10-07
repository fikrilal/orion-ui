import 'package:flutter/foundation.dart' show mapEquals;
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button_style.dart';

/// Theme-level defaults for every button of a variant.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionButtonTheme(...)])` - so a
/// project re-skins its buttons in one place instead of at every call site.
/// The effective style resolves preset, then [defaultStyle], then the
/// variant's entry in [variantStyles], then the instance style passed to the
/// widget; when no extension is registered the button falls back to
/// [fallback] and behaves exactly as it does without this class.
@immutable
class OrionButtonTheme extends ThemeExtension<OrionButtonTheme> {
  const OrionButtonTheme({this.defaultStyle, this.variantStyles});

  /// Style applied to every variant before [variantStyles] refine it.
  final OrionButtonStyle? defaultStyle;

  /// Per-variant refinements, merged over [defaultStyle].
  final Map<OrionButtonVariant, OrionButtonStyle>? variantStyles;

  /// Used when no [OrionButtonTheme] is registered: no overrides at all.
  static const OrionButtonTheme fallback = OrionButtonTheme();

  /// The stacked style this theme contributes to [variant].
  OrionButtonStyle styleFor(OrionButtonVariant variant) {
    final OrionButtonStyle base = defaultStyle ?? const OrionButtonStyle();
    final OrionButtonStyle? variantStyle = variantStyles?[variant];
    return variantStyle == null ? base : base.merge(variantStyle);
  }

  /// Returns a copy with the provided fields replaced.
  @override
  OrionButtonTheme copyWith({
    OrionButtonStyle? defaultStyle,
    Map<OrionButtonVariant, OrionButtonStyle>? variantStyles,
  }) {
    return OrionButtonTheme(
      defaultStyle: defaultStyle ?? this.defaultStyle,
      variantStyles: variantStyles ?? this.variantStyles,
    );
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionButtonTheme lerp(ThemeExtension<OrionButtonTheme>? other, double t) {
    if (other is! OrionButtonTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionButtonTheme &&
        other.defaultStyle == defaultStyle &&
        mapEquals(other.variantStyles, variantStyles);
  }

  @override
  int get hashCode => Object.hash(defaultStyle, variantStyles);
}
