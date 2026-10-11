import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/otp/orion_otp_style.dart';

/// An ambient theme extension configuring defaults for [OrionOtpField].
class OrionOtpTheme extends ThemeExtension<OrionOtpTheme> {
  const OrionOtpTheme({this.defaultStyle});

  /// Default fallback theme.
  static const OrionOtpTheme fallback = OrionOtpTheme();

  /// Default instance style overrides.
  final OrionOtpStyle? defaultStyle;

  @override
  OrionOtpTheme copyWith({OrionOtpStyle? defaultStyle}) {
    return OrionOtpTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionOtpTheme lerp(ThemeExtension<OrionOtpTheme>? other, double t) {
    if (other is! OrionOtpTheme) return this;
    return OrionOtpTheme(
      defaultStyle: OrionOtpStyle.lerp(defaultStyle, other.defaultStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionOtpTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
