import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/accordion/orion_accordion_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The built-in look for the accordion row.
///
/// This is the bottom layer of the accordion's three-layer resolution: the
/// shipped insets, subtle press/hover wash, `onSurface` focus ring drawn over
/// the header, disabled dim, and crisp critically-damped disclosure springs.
abstract final class OrionAccordionPresets {
  /// Default spring when expanding a disclosure panel.
  static const OrionSpringSpec defaultExpandSpring = OrionSpringSpec(
    stiffness: 460,
    dampingRatio: 1,
    clampOvershoot: true,
  );

  /// Default spring when collapsing a disclosure panel.
  static const OrionSpringSpec defaultCollapseSpring = OrionSpringSpec(
    stiffness: 520,
    dampingRatio: 1,
    clampOvershoot: true,
  );

  /// Resolves the built-in style against the ambient scheme.
  static OrionAccordionStyle resolve({required ColorScheme scheme}) {
    return OrionAccordionStyle(
      headerPadding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space16,
        vertical: OrionSpacing.space8,
      ),
      contentPadding: const EdgeInsets.fromLTRB(
        OrionSpacing.space16,
        0,
        OrionSpacing.space16,
        OrionSpacing.space12,
      ),
      pressedScale: 1.0,
      headerPressedColor: scheme.onSurface.withValues(alpha: 0.06),
      headerHoverColor: scheme.onSurface.withValues(alpha: 0.03),
      focusRingColor: scheme.onSurface,
      focusRingWidth: 2,
      disabledOpacity: 0.38,
      expandSpring: defaultExpandSpring,
      collapseSpring: defaultCollapseSpring,
    );
  }
}
