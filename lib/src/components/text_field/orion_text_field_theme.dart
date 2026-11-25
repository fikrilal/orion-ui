import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/text_field/orion_text_field_style.dart';

/// Theme-level defaults for every text field.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionTextFieldTheme(...)])` - so a
/// project re-skins its fields in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the instance style passed to
/// the widget; when no extension is registered the fields fall back to
/// [fallback].
@immutable
class OrionTextFieldTheme extends ThemeExtension<OrionTextFieldTheme> {
  const OrionTextFieldTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionTextFieldStyle? defaultStyle;

  /// Used when no [OrionTextFieldTheme] is registered: no overrides.
  static const OrionTextFieldTheme fallback = OrionTextFieldTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionTextFieldTheme copyWith({OrionTextFieldStyle? defaultStyle}) {
    return OrionTextFieldTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionTextFieldTheme lerp(
    ThemeExtension<OrionTextFieldTheme>? other,
    double t,
  ) {
    if (other is! OrionTextFieldTheme) {
      return this;
    }
    return OrionTextFieldTheme(
      defaultStyle: OrionTextFieldStyle.lerp(
        defaultStyle,
        other.defaultStyle,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionTextFieldTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
