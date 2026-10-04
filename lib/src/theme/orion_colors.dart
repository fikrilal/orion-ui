import 'package:flutter/material.dart';

/// Neutral default palettes for standalone Orion usage.
///
/// Orion components consume the ambient Material [ColorScheme]; these defaults
/// exist so the package can stand alone (demos, tests) without an application
/// palette. Host applications remain free to supply their own [ColorScheme]
/// and register [OrionThemeData] on top of it.
abstract final class OrionColors {
  /// Neutral slate seed used to derive the default light and dark schemes.
  static const Color seed = Color(0xFF5B6472);

  /// Default light scheme derived from [seed].
  static final ColorScheme lightScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.light,
  );

  /// Default dark scheme derived from [seed].
  static final ColorScheme darkScheme = ColorScheme.fromSeed(
    seedColor: seed,
    brightness: Brightness.dark,
  );
}
