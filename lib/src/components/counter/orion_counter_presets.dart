import 'package:orion_ui/src/components/counter/orion_counter_style.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// The built-in look and feel for the counter.
///
/// This is the bottom layer of the counter's three-layer resolution. It takes
/// no arguments, unlike its siblings: the counter paints no surface and
/// resolves no scheme roles, so there is nothing to resolve against. The
/// default text style is the ambient one, the roll deforms by the shipped
/// numbers, and the travel rides the gentle spring, whose ~3.8 % of one row
/// stays inside the resolved leading and so needs no cap.
abstract final class OrionCounterPresets {
  /// Resolves the built-in style.
  static OrionCounterStyle resolve() {
    return const OrionCounterStyle(
      rollStretchX: 0.06,
      rollSquashY: 0.10,
      spring: OrionSpringSpec.gentle,
    );
  }
}
