import 'package:flutter/material.dart';

/// Standalone palettes for Orion when a host app does not supply a scheme.
///
/// Both schemes are the shadcn/ui default neutral theme
/// (https://ui.shadcn.com/docs/theming), converted from OKLCH to sRGB.
/// Components read the ambient [ColorScheme]. A host scheme still wins when
/// the surrounding theme supplies one.
///
/// `background` is [ColorScheme.surface], `card` is [ColorScheme.surfaceContainer],
/// `muted` is [ColorScheme.surfaceContainerHighest], and `muted-foreground` is
/// [ColorScheme.onSurfaceVariant]. `input` is [ColorScheme.outline] and
/// `border` is [ColorScheme.outlineVariant].
abstract final class OrionColors {
  /// shadcn neutral light roles. Primary is near-black, not a generated tint.
  static const ColorScheme lightScheme = ColorScheme(
    brightness: Brightness.light,
    primary: Color(0xFF171717),
    onPrimary: Color(0xFFFAFAFA),
    secondary: Color(0xFFF5F5F5),
    onSecondary: Color(0xFF171717),
    error: Color(0xFFE7000B),
    onError: Color(0xFFFAFAFA),
    surface: Color(0xFFFFFFFF),
    onSurface: Color(0xFF0A0A0A),
    surfaceContainer: Color(0xFFFFFFFF),
    surfaceContainerHighest: Color(0xFFF5F5F5),
    onSurfaceVariant: Color(0xFF737373),
    outline: Color(0xFFE5E5E5),
    outlineVariant: Color(0xFFE5E5E5),
  );

  /// shadcn neutral dark roles.
  ///
  /// Dark `input` is white at 15% and dark `border` is white at 10%.
  static const ColorScheme darkScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFFE5E5E5),
    onPrimary: Color(0xFF171717),
    secondary: Color(0xFF262626),
    onSecondary: Color(0xFFFAFAFA),
    error: Color(0xFFFF6467),
    onError: Color(0xFFFAFAFA),
    surface: Color(0xFF0A0A0A),
    onSurface: Color(0xFFFAFAFA),
    surfaceContainer: Color(0xFF171717),
    surfaceContainerHigh: Color(0xFF171717),
    surfaceContainerHighest: Color(0xFF262626),
    onSurfaceVariant: Color(0xFFA1A1A1),
    outline: Color(0x26FFFFFF),
    outlineVariant: Color(0x1AFFFFFF),
  );
}
