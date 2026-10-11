import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/sheet/orion_bottom_sheet_style.dart';

/// Theme-level defaults for every bottom sheet in the application.
///
/// Installed through the theme's extension list - typically:
/// `OrionTheme.apply(base, extensions: [OrionBottomSheetTheme(...)])`
@immutable
class OrionBottomSheetTheme extends ThemeExtension<OrionBottomSheetTheme> {
  const OrionBottomSheetTheme({this.defaultStyle});

  /// Style applied before any per-instance bottom sheet overrides.
  final OrionBottomSheetStyle? defaultStyle;

  /// Neutral fallback used when no [OrionBottomSheetTheme] is registered.
  static const OrionBottomSheetTheme fallback = OrionBottomSheetTheme();

  @override
  OrionBottomSheetTheme copyWith({OrionBottomSheetStyle? defaultStyle}) {
    return OrionBottomSheetTheme(
      defaultStyle: defaultStyle ?? this.defaultStyle,
    );
  }

  @override
  OrionBottomSheetTheme lerp(
    ThemeExtension<OrionBottomSheetTheme>? other,
    double t,
  ) {
    if (other is! OrionBottomSheetTheme) return this;
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionBottomSheetTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
