import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/card/orion_card_presets.dart';
import 'package:orion_ui/src/components/card/orion_card_style.dart';
import 'package:orion_ui/src/components/card/orion_card_theme.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Quiet inset surface with optional frosted glass and press feedback.
///
/// The frosted backdrop is a static, clipped layer behind the content: press
/// feedback compresses only the foreground, so live blur matrices never scale
/// with the animation (see the proposal's blur-isolation invariant).
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionCardPresets] for the [frosted] face, the ambient
/// [OrionCardTheme], and the [style] passed here - with [padding] and [radius]
/// as the shipped shortcuts, merged after the instance style so they keep
/// winning.
class OrionCard extends StatelessWidget {
  const OrionCard({
    super.key,
    required this.child,
    this.frosted = false,
    this.onTap,
    this.padding,
    this.radius,
    this.style,
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

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionCardTheme]. Only the fields set here change.
  final OrionCardStyle? style;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionCardStyle style = _resolve(theme, orion);
    final BorderRadius borderRadius =
        style.radius ?? BorderRadius.circular(OrionRadii.radius16);
    final Color background = style.background ?? scheme.secondary;
    final EdgeInsetsGeometry padding =
        style.padding ?? const EdgeInsets.all(OrionSpacing.space16);

    Widget foreground = Padding(padding: padding, child: child);
    if (onTap != null) {
      foreground = OrionPressable(
        onTap: onTap,
        pressedScale: style.pressScale ?? orion.pressScale,
        springSpec: style.pressSpring ?? orion.pressSpring,
        releaseSpringSpec: style.releaseSpring ?? orion.releaseSpring,
        hapticType: orion.selectionHaptic,
        child: foreground,
      );
    }

    final double? blurSigma = style.blurSigma;
    final Widget backdrop = blurSigma == null
        ? ColoredBox(color: background)
        : BackdropFilter(
            filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
            child: ColoredBox(color: background),
          );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.fromBorderSide(style.border ?? BorderSide.none),
        boxShadow: style.shadow ?? const <BoxShadow>[],
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

  OrionCardStyle _resolve(ThemeData theme, OrionThemeData orion) {
    final OrionCardTheme cardTheme =
        theme.extension<OrionCardTheme>() ?? OrionCardTheme.fallback;
    final OrionCardStyle sugar = padding == null && radius == null
        ? const OrionCardStyle()
        : OrionCardStyle(
            padding: padding,
            radius: radius == null ? null : BorderRadius.circular(radius!),
          );
    return OrionCardPresets.resolve(
      scheme: theme.colorScheme,
      frosted: frosted,
      blurSigma: orion.blurSigma,
    ).merge(cardTheme.defaultStyle).merge(style).merge(sugar);
  }
}
