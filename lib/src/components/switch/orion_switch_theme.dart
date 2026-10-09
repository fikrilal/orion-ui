import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/switch/orion_switch_style.dart';

/// Theme-level defaults for every switch.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionSwitchTheme(...)])` - so a
/// project re-skins its switches in one place. The effective style resolves
/// the built-in defaults, then [defaultStyle], then the instance style passed
/// to the widget; when no extension is registered the switch falls back to
/// [fallback] and behaves exactly as it does without this class.
@immutable
class OrionSwitchTheme extends ThemeExtension<OrionSwitchTheme> {
  const OrionSwitchTheme({this.defaultStyle});

  /// Style applied before any instance overrides.
  final OrionSwitchStyle? defaultStyle;

  /// Used when no [OrionSwitchTheme] is registered: no overrides.
  static const OrionSwitchTheme fallback = OrionSwitchTheme();

  /// Returns a copy with the provided fields replaced.
  @override
  OrionSwitchTheme copyWith({OrionSwitchStyle? defaultStyle}) {
    return OrionSwitchTheme(defaultStyle: defaultStyle ?? this.defaultStyle);
  }

  /// Styles are discrete specs, not interpolable numbers; the theme animation
  /// swaps at the midpoint, the same way the kit's springs do.
  @override
  OrionSwitchTheme lerp(ThemeExtension<OrionSwitchTheme>? other, double t) {
    if (other is! OrionSwitchTheme) {
      return this;
    }
    return t < 0.5 ? this : other;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSwitchTheme && other.defaultStyle == defaultStyle;
  }

  @override
  int get hashCode => defaultStyle.hashCode;
}
