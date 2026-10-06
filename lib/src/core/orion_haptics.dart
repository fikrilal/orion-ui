import 'dart:async';

import 'package:flutter/services.dart';

/// Supported tactile haptic feedback types.
///
/// This is exactly the vocabulary the Flutter SDK exposes through [HapticFeedback]:
/// a selection tick and three impact weights. There is no success, warning, or error
/// haptic available without a platform channel of our own, so the theme maps meaning
/// onto these rather than naming feelings the platform cannot honour.
enum OrionHapticType {
  none,
  selectionClick,
  lightImpact,
  mediumImpact,
  heavyImpact,
}

/// Dispatches tactile haptic feedback.
abstract final class OrionHaptics {
  /// Dispatches the specified [type] of haptic feedback.
  ///
  /// Fire and forget: a caller never waits on a vibration, and the platform decides
  /// whether the device is actually able to deliver it. There is deliberately no global
  /// mute here - the system setting already owns that, and a static switch would be
  /// invisible to the widget tree that has to respect it.
  static void trigger(OrionHapticType type) {
    switch (type) {
      case OrionHapticType.selectionClick:
        unawaited(HapticFeedback.selectionClick());
      case OrionHapticType.lightImpact:
        unawaited(HapticFeedback.lightImpact());
      case OrionHapticType.mediumImpact:
        unawaited(HapticFeedback.mediumImpact());
      case OrionHapticType.heavyImpact:
        unawaited(HapticFeedback.heavyImpact());
      case OrionHapticType.none:
        break;
    }
  }
}
