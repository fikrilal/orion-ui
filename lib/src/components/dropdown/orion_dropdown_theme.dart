import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/dropdown/orion_dropdown_style.dart';

/// An ambient theme extension configuring defaults for [OrionDropdown].
class OrionDropdownTheme extends ThemeExtension<OrionDropdownTheme> {
  const OrionDropdownTheme({this.defaultStyle});

  /// Default fallback theme.
  static const OrionDropdownTheme fallback = OrionDropdownTheme();

  /// Default instance style overrides applied to all dropdowns in the subtree.
  final OrionDropdownStyle? defaultStyle;

  @override
  OrionDropdownTheme copyWith({OrionDropdownStyle? defaultStyle}) {
    return OrionDropdownTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionDropdownTheme lerp(ThemeExtension<OrionDropdownTheme>? other, double t) {
    if (other is! OrionDropdownTheme) return this;
    return OrionDropdownTheme(
      defaultStyle: OrionDropdownStyle.lerp(
        defaultStyle,
        other.defaultStyle,
        t,
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionDropdownTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
