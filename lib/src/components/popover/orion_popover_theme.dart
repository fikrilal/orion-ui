import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/popover/orion_popover_style.dart';

/// An ambient theme extension configuring defaults for [OrionPopover] and [OrionMenu].
class OrionPopoverTheme extends ThemeExtension<OrionPopoverTheme> {
  const OrionPopoverTheme({this.defaultStyle});

  /// Default fallback theme.
  static const OrionPopoverTheme fallback = OrionPopoverTheme();

  /// Default instance style overrides.
  final OrionPopoverStyle? defaultStyle;

  @override
  OrionPopoverTheme copyWith({OrionPopoverStyle? defaultStyle}) {
    return OrionPopoverTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  @override
  OrionPopoverTheme lerp(ThemeExtension<OrionPopoverTheme>? other, double t) {
    if (other is! OrionPopoverTheme) return this;
    return OrionPopoverTheme(defaultStyle: defaultStyle);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionPopoverTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
