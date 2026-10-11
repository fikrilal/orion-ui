import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/dialog/orion_dialog_style.dart';

/// An ambient theme extension configuring defaults for [OrionDialog].
class OrionDialogTheme extends ThemeExtension<OrionDialogTheme> {
  const OrionDialogTheme({this.defaultStyle});

  /// Default fallback theme.
  static const OrionDialogTheme fallback = OrionDialogTheme();

  /// Default instance style overrides.
  final OrionDialogStyle? defaultStyle;

  @override
  OrionDialogTheme copyWith({OrionDialogStyle? defaultStyle}) {
    return OrionDialogTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionDialogTheme lerp(ThemeExtension<OrionDialogTheme>? other, double t) {
    if (other is! OrionDialogTheme) return this;
    return OrionDialogTheme(
      defaultStyle: OrionDialogStyle.lerp(defaultStyle, other.defaultStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionDialogTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
