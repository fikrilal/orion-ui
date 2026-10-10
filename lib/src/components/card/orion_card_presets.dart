import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/card/orion_card_style.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for both card faces.
///
/// This is the bottom layer of the card's three-layer resolution. An opaque
/// card is a quiet inset panel: muted fill, no hairline, no shadow. A frosted
/// card keeps a translucent surface, the same outline, and the ambient blur
/// sigma; its backdrop stays a static clipped layer behind the content, never
/// inside the press transform.
abstract final class OrionCardPresets {
  /// Resolves the built-in style from ambient tokens.
  static OrionCardStyle resolve({
    required ColorScheme scheme,
    required bool frosted,
    required double blurSigma,
  }) {
    return OrionCardStyle(
      background: frosted
          ? scheme.surface.withValues(alpha: 0.72)
          : scheme.secondary,
      border: BorderSide.none,
      radius: BorderRadius.circular(OrionRadii.radius16),
      padding: const EdgeInsets.all(OrionSpacing.space16),
      shadow: const <BoxShadow>[],
      blurSigma: frosted ? blurSigma : null,
    );
  }
}
