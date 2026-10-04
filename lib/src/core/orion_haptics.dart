import 'package:flutter/services.dart';

/// Supported tactile haptic feedback types.
enum OrionHapticType {
  none,
  selectionClick,
  lightImpact,
  mediumImpact,
  heavyImpact,
}

/// Dispatches synchronized tactile haptic feedback.
abstract final class OrionHaptics {
  /// Global toggle to enable or disable haptic feedback across Orion UI.
  static bool enabled = true;

  /// Dispatches the specified [type] of haptic feedback.
  static Future<void> trigger(OrionHapticType type) async {
    if (!enabled || type == OrionHapticType.none) return;

    switch (type) {
      case OrionHapticType.selectionClick:
        await HapticFeedback.selectionClick();
      case OrionHapticType.lightImpact:
        await HapticFeedback.lightImpact();
      case OrionHapticType.mediumImpact:
        await HapticFeedback.mediumImpact();
      case OrionHapticType.heavyImpact:
        await HapticFeedback.heavyImpact();
      case OrionHapticType.none:
        break;
    }
  }
}
