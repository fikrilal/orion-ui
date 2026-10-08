import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The badge chip's styling inside an [OrionSegmentedControlStyle].
///
/// [fill] and [ink] resolve through the segment's live states -
/// [WidgetState.disabled] and [WidgetState.selected] - so a skin can tint the
/// chip differently on the selected slot. Every field is nullable; a merge
/// keeps the value from the layer beneath for anything the override does not
/// name.
@immutable
class OrionSegmentBadgeStyle {
  const OrionSegmentBadgeStyle({
    this.fill,
    this.ink,
    this.textStyle,
    this.height,
    this.minWidth,
    this.padding,
    this.gap,
  });

  /// Chip background, resolved per segment through its live states.
  final WidgetStateProperty<Color?>? fill;

  /// Chip content colour, resolved per segment through its live states.
  final WidgetStateProperty<Color?>? ink;

  /// Chip content text style; the control falls back to the ambient
  /// `labelSmall`.
  final TextStyle? textStyle;

  /// Chip height.
  final double? height;

  /// Chip minimum width, so a single digit still reads as a pill.
  final double? minWidth;

  /// The chip's inner padding.
  final EdgeInsetsGeometry? padding;

  /// Space between the label and the chip.
  final double? gap;

  /// Returns a copy with the provided fields replaced.
  OrionSegmentBadgeStyle copyWith({
    WidgetStateProperty<Color?>? fill,
    WidgetStateProperty<Color?>? ink,
    TextStyle? textStyle,
    double? height,
    double? minWidth,
    EdgeInsetsGeometry? padding,
    double? gap,
  }) {
    return OrionSegmentBadgeStyle(
      fill: fill ?? this.fill,
      ink: ink ?? this.ink,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      padding: padding ?? this.padding,
      gap: gap ?? this.gap,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionSegmentBadgeStyle merge(OrionSegmentBadgeStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionSegmentBadgeStyle(
      fill: other.fill ?? fill,
      ink: other.ink ?? ink,
      textStyle: other.textStyle ?? textStyle,
      height: other.height ?? height,
      minWidth: other.minWidth ?? minWidth,
      padding: other.padding ?? padding,
      gap: other.gap ?? gap,
    );
  }

  /// Builds a badge style from plain values, each applied to every state.
  static OrionSegmentBadgeStyle from({
    Color? fill,
    Color? ink,
    TextStyle? textStyle,
    double? height,
    double? minWidth,
    EdgeInsetsGeometry? padding,
    double? gap,
  }) {
    return OrionSegmentBadgeStyle(
      fill: fill == null ? null : WidgetStatePropertyAll<Color?>(fill),
      ink: ink == null ? null : WidgetStatePropertyAll<Color?>(ink),
      textStyle: textStyle,
      height: height,
      minWidth: minWidth,
      padding: padding,
      gap: gap,
    );
  }

  /// The built-in chip: a `primary` pill of `onPrimary` content, muted with
  /// the control when disabled.
  static OrionSegmentBadgeStyle defaults({required ColorScheme scheme}) {
    return OrionSegmentBadgeStyle(
      fill: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? scheme.onSurface.withValues(alpha: 0.38)
            : scheme.primary,
      ),
      ink: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? scheme.surface
            : scheme.onPrimary,
      ),
      height: 18,
      minWidth: 18,
      padding: const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
      gap: OrionSpacing.space4,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSegmentBadgeStyle &&
        other.fill == fill &&
        other.ink == ink &&
        other.textStyle == textStyle &&
        other.height == height &&
        other.minWidth == minWidth &&
        other.padding == padding &&
        other.gap == gap;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    fill,
    ink,
    textStyle,
    height,
    minWidth,
    padding,
    gap,
  ]);
}

/// The overridable contract for how an [OrionSegmentedControl] looks and feels.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in [defaults], the theme's `OrionSegmentedControlTheme`, and the
/// instance style passed to the widget. Every field is nullable; a null field
/// falls through to the layer beneath it, so an override changes exactly what
/// it names.
///
/// The colour fields resolve through the segment's live [WidgetState]s: the
/// track and pill see `disabled` (and the pill sees `selected`), while the
/// label and badge resolve per segment with `{disabled, selected}`.
@immutable
class OrionSegmentedControlStyle {
  const OrionSegmentedControlStyle({
    this.trackColor,
    this.pillColor,
    this.labelColor,
    this.focusRingColor,
    this.height,
    this.inset,
    this.radius,
    this.labelStyle,
    this.iconSize,
    this.badge,
    this.pressedScale,
    this.pressSpring,
    this.releaseSpring,
    this.hapticType,
  });

  /// Track surface, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? trackColor;

  /// The sliding pill, which stands for the selected slot; resolved with
  /// [WidgetState.selected] and [WidgetState.disabled].
  final WidgetStateProperty<Color?>? pillColor;

  /// Label and icon colour, resolved per segment with its live states:
  /// [WidgetState.selected] and [WidgetState.disabled].
  final WidgetStateProperty<Color?>? labelColor;

  /// The 2 pt focus ring drawn on the track.
  final Color? focusRingColor;

  /// Track height.
  final double? height;

  /// The bar's inner padding; the pill is inset by the same amount.
  final double? inset;

  /// Track and pill corner radius.
  final BorderRadius? radius;

  /// Label text style; falls back to the ambient `labelMedium`.
  final TextStyle? labelStyle;

  /// Icon size applied through [IconTheme].
  final double? iconSize;

  /// The optional badge chip's styling.
  final OrionSegmentBadgeStyle? badge;

  /// Target scale while a segment is pressed. Falls back to the theme's
  /// `OrionThemeData.pressScale` when null.
  final double? pressedScale;

  /// Spring governing compression on pointer down. Falls back to the theme's
  /// `OrionThemeData.pressSpring` when null.
  final OrionSpringSpec? pressSpring;

  /// Spring governing release on pointer up or cancel. Falls back to the
  /// theme's `OrionThemeData.releaseSpring` when null.
  final OrionSpringSpec? releaseSpring;

  /// Tactile tick on an accepted selection. Falls back to the theme's
  /// `OrionThemeData.selectionHaptic` when null.
  final OrionHapticType? hapticType;

  /// Returns a copy with the provided fields replaced.
  OrionSegmentedControlStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    WidgetStateProperty<Color?>? pillColor,
    WidgetStateProperty<Color?>? labelColor,
    Color? focusRingColor,
    double? height,
    double? inset,
    BorderRadius? radius,
    TextStyle? labelStyle,
    double? iconSize,
    OrionSegmentBadgeStyle? badge,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionSegmentedControlStyle(
      trackColor: trackColor ?? this.trackColor,
      pillColor: pillColor ?? this.pillColor,
      labelColor: labelColor ?? this.labelColor,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      height: height ?? this.height,
      inset: inset ?? this.inset,
      radius: radius ?? this.radius,
      labelStyle: labelStyle ?? this.labelStyle,
      iconSize: iconSize ?? this.iconSize,
      badge: badge ?? this.badge,
      pressedScale: pressedScale ?? this.pressedScale,
      pressSpring: pressSpring ?? this.pressSpring,
      releaseSpring: releaseSpring ?? this.releaseSpring,
      hapticType: hapticType ?? this.hapticType,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  ///
  /// The nested [badge] style merges deeply, so a layer that sets only the
  /// chip's fill keeps everything else from the layer beneath.
  OrionSegmentedControlStyle merge(OrionSegmentedControlStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionSegmentedControlStyle(
      trackColor: other.trackColor ?? trackColor,
      pillColor: other.pillColor ?? pillColor,
      labelColor: other.labelColor ?? labelColor,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      height: other.height ?? height,
      inset: other.inset ?? inset,
      radius: other.radius ?? radius,
      labelStyle: other.labelStyle ?? labelStyle,
      iconSize: other.iconSize ?? iconSize,
      badge: badge == null ? other.badge : badge!.merge(other.badge),
      pressedScale: other.pressedScale ?? pressedScale,
      pressSpring: other.pressSpring ?? pressSpring,
      releaseSpring: other.releaseSpring ?? releaseSpring,
      hapticType: other.hapticType ?? hapticType,
    );
  }

  /// Builds a style from plain values, each applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionSegmentedControlStyle from({
    Color? trackColor,
    Color? pillColor,
    Color? labelColor,
    Color? focusRingColor,
    double? height,
    double? inset,
    BorderRadius? radius,
    TextStyle? labelStyle,
    double? iconSize,
    OrionSegmentBadgeStyle? badge,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionSegmentedControlStyle(
      trackColor: trackColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(trackColor),
      pillColor: pillColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(pillColor),
      labelColor: labelColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(labelColor),
      focusRingColor: focusRingColor,
      height: height,
      inset: inset,
      radius: radius,
      labelStyle: labelStyle,
      iconSize: iconSize,
      badge: badge,
      pressedScale: pressedScale,
      pressSpring: pressSpring,
      releaseSpring: releaseSpring,
      hapticType: hapticType,
    );
  }

  /// The built-in look: exactly what the control painted before this contract
  /// existed, resolved against the ambient scheme and tokens.
  static OrionSegmentedControlStyle defaults({
    required ColorScheme scheme,
    TextStyle? labelStyle,
  }) {
    final Color disabledContainer = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledContent = scheme.onSurface.withValues(alpha: 0.38);
    return OrionSegmentedControlStyle(
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? disabledContainer
            : scheme.secondary,
      ),
      pillColor: WidgetStatePropertyAll<Color?>(scheme.surface),
      labelColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return disabledContent;
        }
        return states.contains(WidgetState.selected)
            ? scheme.onSurface
            : scheme.onSurfaceVariant;
      }),
      focusRingColor: scheme.onSurface,
      height: OrionSizing.minHitTarget,
      inset: OrionSpacing.space4,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      labelStyle: labelStyle,
      iconSize: OrionSizing.iconSmall,
      badge: OrionSegmentBadgeStyle.defaults(scheme: scheme),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSegmentedControlStyle &&
        other.trackColor == trackColor &&
        other.pillColor == pillColor &&
        other.labelColor == labelColor &&
        other.focusRingColor == focusRingColor &&
        other.height == height &&
        other.inset == inset &&
        other.radius == radius &&
        other.labelStyle == labelStyle &&
        other.iconSize == iconSize &&
        other.badge == badge &&
        other.pressedScale == pressedScale &&
        other.pressSpring == pressSpring &&
        other.releaseSpring == releaseSpring &&
        other.hapticType == hapticType;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    trackColor,
    pillColor,
    labelColor,
    focusRingColor,
    height,
    inset,
    radius,
    labelStyle,
    iconSize,
    badge,
    pressedScale,
    pressSpring,
    releaseSpring,
    hapticType,
  ]);
}
