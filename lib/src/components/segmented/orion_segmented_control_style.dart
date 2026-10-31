import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Visual size step for [OrionSegmentedControl].
enum OrionSegmentedControlSize {
  /// Compact 36 pt track for dense toolbars and inline filters.
  small,

  /// Standard 44 pt track meeting the 44 pt touch-target floor. The default.
  medium,

  /// Spacious 52 pt track for prominent primary mode switchers.
  large,
}

/// The badge chip's styling inside an [OrionSegmentedControlStyle].
///
/// [fill] and [ink] resolve through the segment's live states -
/// [WidgetState.disabled], [WidgetState.selected], and [WidgetState.hovered] -
/// so a skin can tint the chip differently on the selected slot. Every field is
/// nullable; a merge keeps the value from the layer beneath for anything the
/// override does not name.
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

  /// Linearly interpolates between two badge styles.
  static OrionSegmentBadgeStyle? lerp(
    OrionSegmentBadgeStyle? a,
    OrionSegmentBadgeStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return OrionSegmentBadgeStyle(
      fill: WidgetStateProperty.lerp<Color?>(a?.fill, b?.fill, t, Color.lerp),
      ink: WidgetStateProperty.lerp<Color?>(a?.ink, b?.ink, t, Color.lerp),
      textStyle: TextStyle.lerp(a?.textStyle, b?.textStyle, t),
      height: lerpDouble(a?.height, b?.height, t),
      minWidth: lerpDouble(a?.minWidth, b?.minWidth, t),
      padding: EdgeInsetsGeometry.lerp(a?.padding, b?.padding, t),
      gap: lerpDouble(a?.gap, b?.gap, t),
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
  static OrionSegmentBadgeStyle defaults({
    required ColorScheme scheme,
    OrionSegmentedControlSize size = OrionSegmentedControlSize.medium,
  }) {
    final double chipSize = switch (size) {
      OrionSegmentedControlSize.small => 16,
      OrionSegmentedControlSize.medium => 18,
      OrionSegmentedControlSize.large => 20,
    };
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
      height: chipSize,
      minWidth: chipSize,
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
/// label and badge resolve per segment with `{disabled, selected, hovered}`.
@immutable
class OrionSegmentedControlStyle {
  const OrionSegmentedControlStyle({
    this.trackColor,
    this.trackBorder,
    this.pillColor,
    this.pillBorder,
    this.pillShadow,
    this.hoverColor,
    this.labelColor,
    this.focusRingColor,
    this.height,
    this.inset,
    this.segmentPadding,
    this.radius,
    this.labelStyle,
    this.iconSize,
    this.badge,
    this.pressedScale,
    this.pressSpring,
    this.releaseSpring,
    this.travelSpring,
    this.hapticType,
  });

  /// Track surface, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? trackColor;

  /// Optional subtle hairline border drawn around the track.
  final BorderSide? trackBorder;

  /// The sliding pill, which stands for the selected slot; resolved with
  /// [WidgetState.selected] and [WidgetState.disabled].
  final WidgetStateProperty<Color?>? pillColor;

  /// Optional subtle hairline border drawn around the active pill.
  final BorderSide? pillBorder;

  /// Optional soft elevation shadows beneath the active pill when enabled.
  final List<BoxShadow>? pillShadow;

  /// Subtle translucent highlight painted behind hovered unselected segments.
  final Color? hoverColor;

  /// Label and icon colour, resolved per segment with its live states:
  /// [WidgetState.selected], [WidgetState.hovered], and [WidgetState.disabled].
  final WidgetStateProperty<Color?>? labelColor;

  /// The 2 pt focus ring drawn on the track under keyboard focus.
  final Color? focusRingColor;

  /// Track height.
  final double? height;

  /// The bar's inner padding; the pill is inset by the same amount and shrinks
  /// its corner radius concentrically.
  final double? inset;

  /// Inner horizontal padding inside each segment slot so long labels and
  /// badges never collide with the pill edges.
  final EdgeInsetsGeometry? segmentPadding;

  /// Outer track corner radius. The inner pill derives a concentric radius
  /// automatically (`outer - inset`, preserving full pill radii).
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

  /// Spring governing the sliding pill travel between segments. Falls back to
  /// [OrionSpringSpec.immediate] when null.
  final OrionSpringSpec? travelSpring;

  /// Tactile tick on an accepted selection or drag detent. Falls back to the
  /// theme's `OrionThemeData.selectionHaptic` when null.
  final OrionHapticType? hapticType;

  /// Returns a copy with the provided fields replaced.
  OrionSegmentedControlStyle copyWith({
    WidgetStateProperty<Color?>? trackColor,
    BorderSide? trackBorder,
    WidgetStateProperty<Color?>? pillColor,
    BorderSide? pillBorder,
    List<BoxShadow>? pillShadow,
    Color? hoverColor,
    WidgetStateProperty<Color?>? labelColor,
    Color? focusRingColor,
    double? height,
    double? inset,
    EdgeInsetsGeometry? segmentPadding,
    BorderRadius? radius,
    TextStyle? labelStyle,
    double? iconSize,
    OrionSegmentBadgeStyle? badge,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionSpringSpec? travelSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionSegmentedControlStyle(
      trackColor: trackColor ?? this.trackColor,
      trackBorder: trackBorder ?? this.trackBorder,
      pillColor: pillColor ?? this.pillColor,
      pillBorder: pillBorder ?? this.pillBorder,
      pillShadow: pillShadow ?? this.pillShadow,
      hoverColor: hoverColor ?? this.hoverColor,
      labelColor: labelColor ?? this.labelColor,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      height: height ?? this.height,
      inset: inset ?? this.inset,
      segmentPadding: segmentPadding ?? this.segmentPadding,
      radius: radius ?? this.radius,
      labelStyle: labelStyle ?? this.labelStyle,
      iconSize: iconSize ?? this.iconSize,
      badge: badge ?? this.badge,
      pressedScale: pressedScale ?? this.pressedScale,
      pressSpring: pressSpring ?? this.pressSpring,
      releaseSpring: releaseSpring ?? this.releaseSpring,
      travelSpring: travelSpring ?? this.travelSpring,
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
      trackBorder: other.trackBorder ?? trackBorder,
      pillColor: other.pillColor ?? pillColor,
      pillBorder: other.pillBorder ?? pillBorder,
      pillShadow: other.pillShadow ?? pillShadow,
      hoverColor: other.hoverColor ?? hoverColor,
      labelColor: other.labelColor ?? labelColor,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      height: other.height ?? height,
      inset: other.inset ?? inset,
      segmentPadding: other.segmentPadding ?? segmentPadding,
      radius: other.radius ?? radius,
      labelStyle: other.labelStyle ?? labelStyle,
      iconSize: other.iconSize ?? iconSize,
      badge: badge == null ? other.badge : badge!.merge(other.badge),
      pressedScale: other.pressedScale ?? pressedScale,
      pressSpring: other.pressSpring ?? pressSpring,
      releaseSpring: other.releaseSpring ?? releaseSpring,
      travelSpring: other.travelSpring ?? travelSpring,
      hapticType: other.hapticType ?? hapticType,
    );
  }

  /// Linearly interpolates between two segmented control styles.
  static OrionSegmentedControlStyle? lerp(
    OrionSegmentedControlStyle? a,
    OrionSegmentedControlStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return OrionSegmentedControlStyle(
      trackColor: WidgetStateProperty.lerp<Color?>(
        a?.trackColor,
        b?.trackColor,
        t,
        Color.lerp,
      ),
      trackBorder: _lerpBorderSide(a?.trackBorder, b?.trackBorder, t),
      pillColor: WidgetStateProperty.lerp<Color?>(
        a?.pillColor,
        b?.pillColor,
        t,
        Color.lerp,
      ),
      pillBorder: _lerpBorderSide(a?.pillBorder, b?.pillBorder, t),
      pillShadow: BoxShadow.lerpList(a?.pillShadow, b?.pillShadow, t),
      hoverColor: Color.lerp(a?.hoverColor, b?.hoverColor, t),
      labelColor: WidgetStateProperty.lerp<Color?>(
        a?.labelColor,
        b?.labelColor,
        t,
        Color.lerp,
      ),
      focusRingColor: Color.lerp(a?.focusRingColor, b?.focusRingColor, t),
      height: lerpDouble(a?.height, b?.height, t),
      inset: lerpDouble(a?.inset, b?.inset, t),
      segmentPadding: EdgeInsetsGeometry.lerp(
        a?.segmentPadding,
        b?.segmentPadding,
        t,
      ),
      radius: BorderRadius.lerp(a?.radius, b?.radius, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      badge: OrionSegmentBadgeStyle.lerp(a?.badge, b?.badge, t),
      pressedScale: lerpDouble(a?.pressedScale, b?.pressedScale, t),
      pressSpring: t < 0.5 ? a?.pressSpring : b?.pressSpring,
      releaseSpring: t < 0.5 ? a?.releaseSpring : b?.releaseSpring,
      travelSpring: t < 0.5 ? a?.travelSpring : b?.travelSpring,
      hapticType: t < 0.5 ? a?.hapticType : b?.hapticType,
    );
  }

  static BorderSide? _lerpBorderSide(BorderSide? a, BorderSide? b, double t) {
    if (a == null && b == null) {
      return null;
    }
    return BorderSide.lerp(a ?? BorderSide.none, b ?? BorderSide.none, t);
  }

  /// Builds a style from plain values, each applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionSegmentedControlStyle from({
    Color? trackColor,
    BorderSide? trackBorder,
    Color? pillColor,
    BorderSide? pillBorder,
    List<BoxShadow>? pillShadow,
    Color? hoverColor,
    Color? labelColor,
    Color? focusRingColor,
    double? height,
    double? inset,
    EdgeInsetsGeometry? segmentPadding,
    BorderRadius? radius,
    TextStyle? labelStyle,
    double? iconSize,
    OrionSegmentBadgeStyle? badge,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionSpringSpec? travelSpring,
    OrionHapticType? hapticType,
  }) {
    return OrionSegmentedControlStyle(
      trackColor: trackColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(trackColor),
      trackBorder: trackBorder,
      pillColor: pillColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(pillColor),
      pillBorder: pillBorder,
      pillShadow: pillShadow,
      hoverColor: hoverColor,
      labelColor: labelColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(labelColor),
      focusRingColor: focusRingColor,
      height: height,
      inset: inset,
      segmentPadding: segmentPadding,
      radius: radius,
      labelStyle: labelStyle,
      iconSize: iconSize,
      badge: badge,
      pressedScale: pressedScale,
      pressSpring: pressSpring,
      releaseSpring: releaseSpring,
      travelSpring: travelSpring,
      hapticType: hapticType,
    );
  }

  /// The built-in look resolved against the ambient scheme, tokens, and [size].
  static OrionSegmentedControlStyle defaults({
    required ColorScheme scheme,
    TextStyle? labelStyle,
    OrionSegmentedControlSize size = OrionSegmentedControlSize.medium,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final Color disabledContainer = scheme.onSurface.withValues(alpha: 0.12);
    final Color disabledContent = scheme.onSurface.withValues(alpha: 0.38);

    final (
      double height,
      double inset,
      double iconSize,
      double hPad,
    ) = switch (size) {
      OrionSegmentedControlSize.small => (36.0, 3.0, 15.0, OrionSpacing.space8),
      OrionSegmentedControlSize.medium => (
        OrionSizing.minHitTarget,
        OrionSpacing.space4,
        OrionSizing.iconSmall,
        OrionSpacing.space8,
      ),
      OrionSegmentedControlSize.large => (
        52.0,
        OrionSpacing.space4,
        18.0,
        OrionSpacing.space12,
      ),
    };

    final Color restingTrack = isDark
        ? Color.alphaBlend(
            Colors.black.withValues(alpha: 0.35),
            scheme.surfaceContainer,
          )
        : scheme.secondary;

    final Color restingPill = isDark
        ? Color.alphaBlend(
            scheme.onSurface.withValues(alpha: 0.13),
            scheme.surfaceContainer,
          )
        : scheme.surface;

    final Color disabledPill = isDark
        ? scheme.onSurface.withValues(alpha: 0.10)
        : scheme.surface.withValues(alpha: 0.65);

    return OrionSegmentedControlStyle(
      trackColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => states.contains(WidgetState.disabled)
            ? disabledContainer
            : restingTrack,
      ),
      trackBorder: isDark
          ? BorderSide(color: scheme.outlineVariant, width: 1)
          : BorderSide.none,
      pillColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) =>
            states.contains(WidgetState.disabled) ? disabledPill : restingPill,
      ),
      pillBorder: isDark
          ? BorderSide(color: scheme.outlineVariant, width: 1)
          : BorderSide.none,
      pillShadow: isDark
          ? const <BoxShadow>[]
          : const <BoxShadow>[
              BoxShadow(
                color: Color(0x14000000),
                blurRadius: 4,
                offset: Offset(0, 1),
              ),
              BoxShadow(
                color: Color(0x0A000000),
                blurRadius: 1,
                offset: Offset(0, 0.5),
              ),
            ],
      hoverColor: scheme.onSurface.withValues(alpha: isDark ? 0.06 : 0.04),
      labelColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return disabledContent;
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.onSurface;
        }
        if (states.contains(WidgetState.hovered)) {
          return Color.lerp(scheme.onSurfaceVariant, scheme.onSurface, 0.5);
        }
        return scheme.onSurfaceVariant;
      }),
      focusRingColor: scheme.onSurface,
      height: height,
      inset: inset,
      segmentPadding: EdgeInsets.symmetric(horizontal: hPad),
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      labelStyle: labelStyle,
      iconSize: iconSize,
      badge: OrionSegmentBadgeStyle.defaults(scheme: scheme, size: size),
      travelSpring: OrionSpringSpec.immediate,
    );
  }

  static bool _shadowListEquals(List<BoxShadow>? a, List<BoxShadow>? b) {
    if (identical(a, b)) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) {
        return false;
      }
    }
    return true;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSegmentedControlStyle &&
        other.trackColor == trackColor &&
        other.trackBorder == trackBorder &&
        other.pillColor == pillColor &&
        other.pillBorder == pillBorder &&
        _shadowListEquals(other.pillShadow, pillShadow) &&
        other.hoverColor == hoverColor &&
        other.labelColor == labelColor &&
        other.focusRingColor == focusRingColor &&
        other.height == height &&
        other.inset == inset &&
        other.segmentPadding == segmentPadding &&
        other.radius == radius &&
        other.labelStyle == labelStyle &&
        other.iconSize == iconSize &&
        other.badge == badge &&
        other.pressedScale == pressedScale &&
        other.pressSpring == pressSpring &&
        other.releaseSpring == releaseSpring &&
        other.travelSpring == travelSpring &&
        other.hapticType == hapticType;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    trackColor,
    trackBorder,
    pillColor,
    pillBorder,
    pillShadow == null ? null : Object.hashAll(pillShadow!),
    hoverColor,
    labelColor,
    focusRingColor,
    height,
    inset,
    segmentPadding,
    radius,
    labelStyle,
    iconSize,
    badge,
    pressedScale,
    pressSpring,
    releaseSpring,
    travelSpring,
    hapticType,
  ]);
}
