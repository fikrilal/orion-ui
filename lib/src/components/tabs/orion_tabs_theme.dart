import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/tabs/orion_tabs_style.dart';

/// An ambient theme extension configuring defaults for [OrionTabs].
class OrionTabsTheme extends ThemeExtension<OrionTabsTheme> {
  const OrionTabsTheme({this.defaultStyle});

  /// Default fallback theme.
  static const OrionTabsTheme fallback = OrionTabsTheme();

  /// Default instance style overrides applied to all tabs in the subtree.
  final OrionTabsStyle? defaultStyle;

  @override
  OrionTabsTheme copyWith({OrionTabsStyle? defaultStyle}) {
    return OrionTabsTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionTabsTheme lerp(ThemeExtension<OrionTabsTheme>? other, double t) {
    if (other is! OrionTabsTheme) return this;
    return OrionTabsTheme(
      defaultStyle: OrionTabsStyle.lerp(defaultStyle, other.defaultStyle, t),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionTabsTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
