import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/tooltip/orion_tooltip_style.dart';

/// An ambient theme extension configuring defaults for [OrionTooltip].
class OrionTooltipTheme extends ThemeExtension<OrionTooltipTheme> {
  const OrionTooltipTheme({this.defaultStyle});

  /// Default fallback theme.
  static const OrionTooltipTheme fallback = OrionTooltipTheme();

  /// Default instance style overrides.
  final OrionTooltipStyle? defaultStyle;

  @override
  OrionTooltipTheme copyWith({OrionTooltipStyle? defaultStyle}) {
    return OrionTooltipTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionTooltipTheme lerp(ThemeExtension<OrionTooltipTheme>? other, double t) {
    if (other is! OrionTooltipTheme) return this;
    return OrionTooltipTheme(
      defaultStyle: OrionTooltipStyle.lerp(defaultStyle, other.defaultStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionTooltipTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
