import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/switch/orion_switch_style.dart';

/// Theme-level defaults for every switch.
///
/// Installed through the theme's extension list - typically
/// `OrionTheme.apply(base, extensions: [OrionSwitchTheme(...)])` - so a
/// project re-skins its switches in one place. The effective style resolves
/// `OrionSwitchPresets`, then [defaultStyle], then the instance style passed
/// to the widget; when no extension is registered the switch falls back to
/// [fallback].
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

  @override
  OrionSwitchTheme lerp(ThemeExtension<OrionSwitchTheme>? other, double t) {
    if (other is! OrionSwitchTheme) {
      return this;
    }
    return OrionSwitchTheme(
      defaultStyle: OrionSwitchStyle.lerp(defaultStyle, other.defaultStyle, t),
    );
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
