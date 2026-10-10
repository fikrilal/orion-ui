import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/toast/orion_toast_style.dart';

/// Theme-level defaults for every toast in the application.
///
/// Installed through the theme's extension list - typically:
/// `OrionTheme.apply(base, extensions: [OrionToastTheme(...)])`
@immutable
class OrionToastTheme extends ThemeExtension<OrionToastTheme> {
  const OrionToastTheme({this.defaultStyle});

  /// Style applied before any per-instance toast overrides.
  final OrionToastStyle? defaultStyle;

  /// Neutral fallback used when no [OrionToastTheme] is registered.
  static const OrionToastTheme fallback = OrionToastTheme();

  @override
  OrionToastTheme copyWith({OrionToastStyle? defaultStyle}) {
    return OrionToastTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionToastTheme lerp(ThemeExtension<OrionToastTheme>? other, double t) {
    if (other is! OrionToastTheme) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionToastTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
