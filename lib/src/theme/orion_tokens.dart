/// Primitive design tokens for Orion UI.
///
/// Values intentionally mirror the host application's scales
/// (`AppSpacing`/`AppRadii`/`AppSizing`) so an adoption adapter is a straight
/// mapping rather than a redesign.
library;

/// Fixed spacing scale on the 4 pt grid.
abstract final class OrionSpacing {
  static const double space4 = 4.0;
  static const double space8 = 8.0;
  static const double space12 = 12.0;
  static const double space16 = 16.0;
  static const double space20 = 20.0;
  static const double space24 = 24.0;
  static const double space32 = 32.0;
  static const double space40 = 40.0;
  static const double space48 = 48.0;
}

/// Corner radii for controls and surfaces.
abstract final class OrionRadii {
  static const double radius4 = 4.0;
  static const double radius6 = 6.0;
  static const double radius8 = 8.0;
  static const double radius12 = 12.0;
  static const double radius16 = 16.0;
  static const double radius24 = 24.0;
  static const double radiusPill = 999.0;
}

/// Control sizing and accessibility floors.
abstract final class OrionSizing {
  static const double controlHeightSmall = 32.0;
  static const double controlHeightMedium = 40.0;
  static const double controlHeightLarge = 48.0;

  static const double iconSmall = 16.0;
  static const double iconMedium = 24.0;
  static const double iconLarge = 32.0;

  /// Minimum interactive hit target (44 x 44 pt).
  static const double minHitTarget = 44.0;
}
