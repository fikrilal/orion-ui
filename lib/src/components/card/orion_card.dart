import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/card/orion_card_style.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';

/// Quiet inset surface with optional frosted glass and press feedback.
///
/// The frosted backdrop is a static, clipped layer behind the content: press
/// feedback compresses only the foreground, so live blur matrices never scale
/// with the animation (see the proposal's blur-isolation invariant).
class OrionCard extends StatelessWidget {
  const OrionCard({
    super.key,
    required this.child,
    this.frosted = false,
    this.onTap,
    this.padding,
    this.radius,
  });

  /// Card content.
  final Widget child;

  /// Whether the backdrop blurs and tints what is behind the card.
  final bool frosted;

  /// Optional tap callback; enables press feedback on the foreground content.
  final VoidCallback? onTap;

  /// Overrides the default content padding.
  final EdgeInsetsGeometry? padding;

  /// Overrides the default corner radius.
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionCardStyle style = OrionCardStyle.resolve(
      scheme: scheme,
      theme: orion,
      frosted: frosted,
    );
    final BorderRadius borderRadius = radius == null
        ? style.radius
        : BorderRadius.circular(radius!);

    Widget foreground = Padding(
      padding: padding ?? style.padding,
      child: child,
    );
    if (onTap != null) {
      foreground = OrionPressable(
        onTap: onTap,
        pressedScale: orion.pressScale,
        springSpec: orion.pressSpring,
        releaseSpringSpec: orion.releaseSpring,
        hapticType: orion.tapHaptic,
        child: foreground,
      );
    }

    final double? blurSigma = style.blurSigma;
    final Widget backdrop = blurSigma == null
        ? ColoredBox(color: style.background)
        : BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: ColoredBox(color: style.background),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.fromBorderSide(style.border),
        boxShadow: style.shadow,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Positioned.fill(child: backdrop),
            foreground,
          ],
        ),
      ),
    );
  }
}
