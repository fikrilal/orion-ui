import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/accordion/orion_accordion_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for the accordion row.
///
/// This is the bottom layer of the accordion's three-layer resolution: the
/// shipped numbers, the `onSurface` focus ring drawn over the header, the
/// header's disabled dim, and the two deliberately different springs.
abstract final class OrionAccordionPresets {
  /// Resolves the built-in style against the ambient scheme.
  static OrionAccordionStyle resolve({required ColorScheme scheme}) {
    return OrionAccordionStyle(
      headerPadding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space16,
        vertical: OrionSpacing.space8,
      ),
      focusRingColor: scheme.onSurface,
      focusRingWidth: 2,
      disabledOpacity: 0.38,
      expandSpring: OrionSpringSpec.gentle,
      collapseSpring: const OrionSpringSpec(
        stiffness: 260,
        dampingRatio: 1,
        clampOvershoot: true,
      ),
    );
  }
}
