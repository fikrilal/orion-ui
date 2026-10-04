import 'package:flutter/material.dart';

import 'package:orion_ui/src/theme/orion_colors.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';

/// Ambient access to Orion theme tokens.
///
/// This is a thin facade over [ThemeData.extensions]: registering
/// [OrionThemeData] keeps Material's theme resolution, lerp, and animation
/// behavior intact while exposing a single, type-safe accessor.
abstract final class OrionTheme {
  /// Returns the registered [OrionThemeData], falling back to
  /// [OrionThemeData.fallback] when none is registered.
  static OrionThemeData of(BuildContext context) =>
      Theme.of(context).extension<OrionThemeData>() ?? OrionThemeData.fallback;

  /// Returns the registered [OrionThemeData], or null when none is registered.
  static OrionThemeData? maybeOf(BuildContext context) =>
      Theme.of(context).extension<OrionThemeData>();

  /// Registers [data] on [base], preserving every other theme extension.
  ///
  /// When [data] is null an already registered [OrionThemeData] is kept;
  /// [OrionThemeData.fallback] is installed only when none exists.
  static ThemeData apply(ThemeData base, {OrionThemeData? data}) {
    final existing = base.extension<OrionThemeData>();
    return base.copyWith(
      extensions: [
        ...base.extensions.values.where(
          (themeExtension) => themeExtension is! OrionThemeData,
        ),
        data ?? existing ?? OrionThemeData.fallback,
      ],
    );
  }

  /// Default light theme using the neutral Orion palette.
  static ThemeData light() => apply(
    ThemeData(
      brightness: Brightness.light,
      colorScheme: OrionColors.lightScheme,
    ),
  );

  /// Default dark theme using the neutral Orion palette.
  static ThemeData dark() => apply(
    ThemeData(brightness: Brightness.dark, colorScheme: OrionColors.darkScheme),
  );
}

/// Ergonomic accessor for Orion tokens: `context.orion`.
extension OrionThemeContext on BuildContext {
  OrionThemeData get orion => OrionTheme.of(this);
}
