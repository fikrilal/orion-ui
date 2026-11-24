import 'package:orion_ui/src/components/counter/orion_counter_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The built-in look and feel for the counter.
///
/// This is the bottom layer of the counter's three-layer resolution. It takes
/// no arguments, unlike its siblings: the counter paints no surface and
/// resolves no scheme roles, so there is nothing to resolve against. The
/// default text style is the ambient one, the roll deforms by the shipped
/// numbers with motion-aware edge fading, and the travel rides [defaultSpring],
/// whose ~1.1% overshoot stays well inside the resolved leading and needs no cap.
abstract final class OrionCounterPresets {
  /// Default travel spring for one row of digits.
  ///
  /// Crisper than [OrionSpringSpec.gentle] for responsive stepping while
  /// preserving a subtle (~1.1%) tactile settle bounce.
  static const OrionSpringSpec defaultSpring = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 0.82,
  );

  /// Resolves the built-in style.
  static OrionCounterStyle resolve() {
    return const OrionCounterStyle(
      rollStretchX: 0.06,
      rollSquashY: 0.10,
      fadeEdges: true,
      spring: defaultSpring,
    );
  }
}
