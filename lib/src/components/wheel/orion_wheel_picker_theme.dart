import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/wheel/orion_wheel_picker_style.dart';

/// Theme-level defaults for every wheel picker.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionWheelPickerTheme(...)])` - so a
/// project re-skins its wheels in one place. The effective style resolves the
/// built-in presets, then [defaultStyle], then the instance style passed to
/// the widget; when no extension is registered the wheels fall back to
/// [fallback] and behave exactly as they do without this class.
@immutable
class OrionWheelPickerTheme extends ThemeExtension<OrionWheelPickerTheme> {
  const OrionWheelPickerTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionWheelPickerStyle? defaultStyle;

  /// Used when no [OrionWheelPickerTheme] is registered: no overrides.
  static const OrionWheelPickerTheme fallback = OrionWheelPickerTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionWheelPickerTheme copyWith({OrionWheelPickerStyle? defaultStyle}) {
    return OrionWheelPickerTheme(
      defaultStyle: defaultStyle ?? this.defaultStyle,
    );
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionWheelPickerTheme lerp(
    ThemeExtension<OrionWheelPickerTheme>? other,
    double t,
  ) {
    if (other is! OrionWheelPickerTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionWheelPickerTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
