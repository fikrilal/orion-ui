import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Built-in looks: a variant x size resolved against the ambient scheme and
/// tokens.
///
/// This is the bottom layer of the style merge. It is inspectable on purpose -
/// a project can base a custom style on it
/// (`OrionButtonPresets.resolve(...).merge(custom)`) instead of copying colors
/// out of a private switch. Every value here is nullable and every visual
/// field resolves through the live states, so the layers above can override
/// exactly what they name.
abstract final class OrionButtonPresets {
  /// Resolves the built-in style for [variant] and [size].
  static OrionButtonStyle resolve({
    required OrionButtonVariant variant,
    required OrionButtonSize size,
    required ColorScheme scheme,
    required TextTheme textTheme,
    required OrionThemeData theme,
  }) {
    final (
      double height,
      EdgeInsetsGeometry padding,
      TextStyle? textStyle,
    ) = switch (size) {
      OrionButtonSize.small => (
        OrionSizing.controlHeightSmall,
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space12),
        textTheme.labelMedium,
      ),
      OrionButtonSize.medium => (
        OrionSizing.controlHeightMedium,
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space16),
        textTheme.labelLarge,
      ),
      OrionButtonSize.large => (
        OrionSizing.controlHeightLarge,
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space20),
        textTheme.titleMedium,
      ),
    };

    final Color disabledContainer = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledForeground = scheme.onSurface.withValues(alpha: 0.38);

    WidgetStateProperty<Color?> filledBackground() =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? disabledContainer
              : scheme.primary,
        );

    WidgetStateProperty<Color?> filledForeground() =>
        WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? disabledForeground
              : scheme.onPrimary,
        );

    WidgetStateProperty<BorderSide?> focusRing(Color ring) =>
        WidgetStateProperty.resolveWith<BorderSide?>(
          (Set<WidgetState> states) =>
              states.contains(WidgetState.focused) &&
                  !states.contains(WidgetState.disabled)
              ? BorderSide(color: ring, width: 2.0)
              : null,
        );

    WidgetStateProperty<Color?>? background;
    late WidgetStateProperty<Color?> foreground;
    WidgetStateProperty<BorderSide?>? border;
    WidgetStateProperty<List<BoxShadow>?>? shadow;

    switch (variant) {
      case OrionButtonVariant.solid:
        background = filledBackground();
        foreground = filledForeground();
        border = focusRing(scheme.onSurface);
      case OrionButtonVariant.bordered:
        foreground = WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? disabledForeground
              : scheme.primary,
        );
        border = WidgetStateProperty.resolveWith<BorderSide?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return BorderSide(color: disabledContainer);
          }
          if (states.contains(WidgetState.focused)) {
            return BorderSide(color: scheme.primary, width: 2.0);
          }
          return BorderSide(color: scheme.outline);
        });
      case OrionButtonVariant.glow:
        background = filledBackground();
        foreground = filledForeground();
        shadow = WidgetStateProperty.resolveWith<List<BoxShadow>?>(
          (Set<WidgetState> states) => <BoxShadow>[
            BoxShadow(
              color: scheme.primary.withValues(
                alpha: states.contains(WidgetState.disabled) ? 0.12 : 0.35,
              ),
              blurRadius: 16.0,
              spreadRadius: -2.0,
            ),
          ],
        );
        border = focusRing(scheme.onSurface);
      case OrionButtonVariant.flat:
        foreground = WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? disabledForeground
              : scheme.primary,
        );
        border = focusRing(scheme.primary);
    }

    return OrionButtonStyle(
      background: background,
      foreground: foreground,
      border: border,
      shadow: shadow,
      borderRadius: BorderRadius.circular(theme.controlRadius),
      height: height,
      padding: padding,
      textStyle: textStyle,
      gap: OrionSpacing.space8,
    );
  }
}
