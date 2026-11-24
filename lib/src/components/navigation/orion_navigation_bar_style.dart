import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/navigation/orion_navigation_bar.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The badge chip's styling inside an [OrionNavigationBarStyle].
///
/// [fill] and [ink] resolve through the destination's live [WidgetState]s -
/// [WidgetState.disabled] and [WidgetState.selected] - and [ringColor] paints
/// the cut-out ring that separates the chip from the icon beneath it (the
/// reference's pixel clear, spelled as a border).
@immutable
class OrionNavigationBadgeStyle {
  const OrionNavigationBadgeStyle({
    this.fill,
    this.ink,
    this.textStyle,
    this.height,
    this.minWidth,
    this.dotSize,
    this.padding,
    this.ringColor,
    this.ringWidth,
  });

  /// Chip background, resolved per destination through its live states.
  final WidgetStateProperty<Color?>? fill;

  /// Chip content colour, resolved per destination through its live states.
  final WidgetStateProperty<Color?>? ink;

  /// Chip content text style; falls back to the bar's label style.
  final TextStyle? textStyle;

  /// Chip height.
  final double? height;

  /// Chip minimum width, so a single digit still reads as a pill.
  final double? minWidth;

  /// Diameter of a status-dot badge (`OrionNavigationDestination.badgeDot`).
  final double? dotSize;

  /// The chip's inner padding.
  final EdgeInsetsGeometry? padding;

  /// The ring drawn around the chip; when null, the bar resolves it to the
  /// live surface beneath each destination (including the active selection
  /// pill) so the badge reads as cut out of the icon.
  final Color? ringColor;

  /// Width of the cut-out ring around the badge. Set to `0` to omit the ring.
  final double? ringWidth;

  /// Returns a copy with the provided fields replaced.
  OrionNavigationBadgeStyle copyWith({
    WidgetStateProperty<Color?>? fill,
    WidgetStateProperty<Color?>? ink,
    TextStyle? textStyle,
    double? height,
    double? minWidth,
    double? dotSize,
    EdgeInsetsGeometry? padding,
    Color? ringColor,
    double? ringWidth,
  }) {
    return OrionNavigationBadgeStyle(
      fill: fill ?? this.fill,
      ink: ink ?? this.ink,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      dotSize: dotSize ?? this.dotSize,
      padding: padding ?? this.padding,
      ringColor: ringColor ?? this.ringColor,
      ringWidth: ringWidth ?? this.ringWidth,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  ///
  /// [textStyle] merges field-by-field via [TextStyle.merge], so an override
  /// that sets only `fontSize` keeps the inherited typography underneath.
  OrionNavigationBadgeStyle merge(OrionNavigationBadgeStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionNavigationBadgeStyle(
      fill: other.fill ?? fill,
      ink: other.ink ?? ink,
      textStyle: textStyle == null
          ? other.textStyle
          : textStyle!.merge(other.textStyle),
      height: other.height ?? height,
      minWidth: other.minWidth ?? minWidth,
      dotSize: other.dotSize ?? dotSize,
      padding: other.padding ?? padding,
      ringColor: other.ringColor ?? ringColor,
      ringWidth: other.ringWidth ?? ringWidth,
    );
  }

  /// Builds a badge style from plain values, each colour applied to every
  /// state.
  static OrionNavigationBadgeStyle from({
    Color? fill,
    Color? ink,
    TextStyle? textStyle,
    double? height,
    double? minWidth,
    double? dotSize,
    EdgeInsetsGeometry? padding,
    Color? ringColor,
    double? ringWidth,
  }) {
    return OrionNavigationBadgeStyle(
      fill: fill == null ? null : WidgetStatePropertyAll<Color?>(fill),
      ink: ink == null ? null : WidgetStatePropertyAll<Color?>(ink),
      textStyle: textStyle,
      height: height,
      minWidth: minWidth,
      dotSize: dotSize,
      padding: padding,
      ringColor: ringColor,
      ringWidth: ringWidth,
    );
  }

  /// The built-in chip: a `primary` pill of `onPrimary` content. It stays at
  /// full strength when the bar is disabled - it annotates the icon, and a
  /// muted chip merges with the muted icon beneath it.
  static OrionNavigationBadgeStyle defaults({required ColorScheme scheme}) {
    return OrionNavigationBadgeStyle(
      fill: WidgetStatePropertyAll<Color?>(scheme.primary),
      ink: WidgetStatePropertyAll<Color?>(scheme.onPrimary),
      height: 16,
      minWidth: 16,
      dotSize: 8,
      padding: const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
      ringWidth: 1.33,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionNavigationBadgeStyle &&
        other.fill == fill &&
        other.ink == ink &&
        other.textStyle == textStyle &&
        other.height == height &&
        other.minWidth == minWidth &&
        other.dotSize == dotSize &&
        other.padding == padding &&
        other.ringColor == ringColor &&
        other.ringWidth == ringWidth;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    fill,
    ink,
    textStyle,
    height,
    minWidth,
    dotSize,
    padding,
    ringColor,
    ringWidth,
  ]);
}

/// The overridable contract for how an [OrionNavigationBar] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in [defaults], the theme's `OrionNavigationTheme`, and the instance
/// style passed to the widget. Every field is nullable; a null field falls
/// through to the layer beneath it, so an override changes exactly what it
/// names.
///
/// [selectionColor] and [destinationColor] resolve through the bar's and each
/// destination's live [WidgetState]s - `disabled`, `hovered`, and `selected` -
/// and the build lerps between the resolved off and on destination colours with
/// the proximity factor.
@immutable
class OrionNavigationBarStyle {
  const OrionNavigationBarStyle({
    this.background,
    this.borderColor,
    this.borderWidth,
    this.shadows,
    this.frosted,
    this.selectionColor,
    this.hoverColor,
    this.destinationColor,
    this.focusRingColor,
    this.maxWidth,
    this.minHeight,
    this.iconSize,
    this.radius,
    this.padding,
    this.itemPadding,
    this.iconLabelGap,
    this.labelStyle,
    this.labelMode,
    this.selectionSpring,
    this.hideSpring,
    this.hideSlide,
    this.hideScale,
    this.badge,
  });

  /// The bar's surface fill.
  final Color? background;

  /// The bar's hairline border colour.
  final Color? borderColor;

  /// Width of the hairline border. Set to `0` to omit the border cleanly.
  final double? borderWidth;

  /// Elevation shadows painted behind the bar. Pass an empty list for a flat
  /// surface.
  final List<BoxShadow>? shadows;

  /// Whether the bar surface renders with a translucent frosted-glass backdrop.
  final bool? frosted;

  /// The pill behind the selected slot, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? selectionColor;

  /// Subtle background overlay painted over a hovered destination on pointer
  /// devices.
  final Color? hoverColor;

  /// Destination icon and label colour, resolved per destination with its live
  /// states: [WidgetState.selected], [WidgetState.hovered], and
  /// [WidgetState.disabled]. The build lerps between the resolved off and on
  /// colours with the proximity factor.
  final WidgetStateProperty<Color?>? destinationColor;

  /// The 2 pt focus ring drawn on the bar when keyboard-focused.
  final Color? focusRingColor;

  /// The capsule's maximum width (ignored in [OrionNavigationBarVariant.docked]
  /// unless explicitly overridden).
  final double? maxWidth;

  /// The bar's minimum height; falls back to 64 with labels, or 52 without
  /// them, so a label-less bar hugs its icons.
  final double? minHeight;

  /// Destination icon size, applied through [IconTheme].
  final double? iconSize;

  /// The bar's corner radius. Inner selection pills automatically reduce
  /// concentrically when non-pill radii are supplied.
  final BorderRadius? radius;

  /// The bar's inner padding; the slots are laid out inside it.
  final EdgeInsetsGeometry? padding;

  /// Optional override for each destination slot's inner padding. When null,
  /// the bar picks an adaptive padding per [labelMode] that compresses cleanly
  /// in narrow widths.
  final EdgeInsetsGeometry? itemPadding;

  /// Spacing between icon and label. Defaults to 4 pt stacked (`all`) and 8 pt
  /// inline (`selected`).
  final double? iconLabelGap;

  /// Destination label text style; falls back to the ambient `labelSmall`.
  final TextStyle? labelStyle;

  /// How destinations present their labels. [OrionNavigationLabelMode.all] by
  /// default; `none` renders an icon-only bar and `selected` expands the
  /// selected destination into a label pill. The label stays the
  /// destination's spoken name in every mode.
  final OrionNavigationLabelMode? labelMode;

  /// Spring the selection pill rides; the immediate spec by default, because
  /// a press spring's overshoot reads as a wobble on a lateral travel.
  final OrionSpringSpec? selectionSpring;

  /// Spring the show/hide of the bar rides.
  final OrionSpringSpec? hideSpring;

  /// How far the bar slides down when hidden.
  final double? hideSlide;

  /// How far the bar shrinks when hidden.
  final double? hideScale;

  /// The destination badge chip's styling.
  final OrionNavigationBadgeStyle? badge;

  /// Returns a copy with the provided fields replaced.
  OrionNavigationBarStyle copyWith({
    Color? background,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadows,
    bool? frosted,
    WidgetStateProperty<Color?>? selectionColor,
    Color? hoverColor,
    WidgetStateProperty<Color?>? destinationColor,
    Color? focusRingColor,
    double? maxWidth,
    double? minHeight,
    double? iconSize,
    BorderRadius? radius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? itemPadding,
    double? iconLabelGap,
    TextStyle? labelStyle,
    OrionNavigationLabelMode? labelMode,
    OrionSpringSpec? selectionSpring,
    OrionSpringSpec? hideSpring,
    double? hideSlide,
    double? hideScale,
    OrionNavigationBadgeStyle? badge,
  }) {
    return OrionNavigationBarStyle(
      background: background ?? this.background,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      shadows: shadows ?? this.shadows,
      frosted: frosted ?? this.frosted,
      selectionColor: selectionColor ?? this.selectionColor,
      hoverColor: hoverColor ?? this.hoverColor,
      destinationColor: destinationColor ?? this.destinationColor,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      iconSize: iconSize ?? this.iconSize,
      radius: radius ?? this.radius,
      padding: padding ?? this.padding,
      itemPadding: itemPadding ?? this.itemPadding,
      iconLabelGap: iconLabelGap ?? this.iconLabelGap,
      labelStyle: labelStyle ?? this.labelStyle,
      labelMode: labelMode ?? this.labelMode,
      selectionSpring: selectionSpring ?? this.selectionSpring,
      hideSpring: hideSpring ?? this.hideSpring,
      hideSlide: hideSlide ?? this.hideSlide,
      hideScale: hideScale ?? this.hideScale,
      badge: badge ?? this.badge,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  ///
  /// [labelStyle] merges field-by-field via [TextStyle.merge], and the nested
  /// [badge] style merges deeply, so a layer that sets only one attribute keeps
  /// everything else from the layer beneath.
  OrionNavigationBarStyle merge(OrionNavigationBarStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionNavigationBarStyle(
      background: other.background ?? background,
      borderColor: other.borderColor ?? borderColor,
      borderWidth: other.borderWidth ?? borderWidth,
      shadows: other.shadows ?? shadows,
      frosted: other.frosted ?? frosted,
      selectionColor: other.selectionColor ?? selectionColor,
      hoverColor: other.hoverColor ?? hoverColor,
      destinationColor: other.destinationColor ?? destinationColor,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      maxWidth: other.maxWidth ?? maxWidth,
      minHeight: other.minHeight ?? minHeight,
      iconSize: other.iconSize ?? iconSize,
      radius: other.radius ?? radius,
      padding: other.padding ?? padding,
      itemPadding: other.itemPadding ?? itemPadding,
      iconLabelGap: other.iconLabelGap ?? iconLabelGap,
      labelStyle: labelStyle == null
          ? other.labelStyle
          : labelStyle!.merge(other.labelStyle),
      labelMode: other.labelMode ?? labelMode,
      selectionSpring: other.selectionSpring ?? selectionSpring,
      hideSpring: other.hideSpring ?? hideSpring,
      hideSlide: other.hideSlide ?? hideSlide,
      hideScale: other.hideScale ?? hideScale,
      badge: badge == null ? other.badge : badge!.merge(other.badge),
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  ///
  /// Use the main constructor with [WidgetStateProperty] values when a colour
  /// must differ by state; [from] is the flat, one-value-per-field sugar.
  static OrionNavigationBarStyle from({
    Color? background,
    Color? borderColor,
    double? borderWidth,
    List<BoxShadow>? shadows,
    bool? frosted,
    Color? selectionColor,
    Color? hoverColor,
    Color? destinationColor,
    Color? focusRingColor,
    double? maxWidth,
    double? minHeight,
    double? iconSize,
    BorderRadius? radius,
    EdgeInsetsGeometry? padding,
    EdgeInsetsGeometry? itemPadding,
    double? iconLabelGap,
    TextStyle? labelStyle,
    OrionNavigationLabelMode? labelMode,
    OrionSpringSpec? selectionSpring,
    OrionSpringSpec? hideSpring,
    double? hideSlide,
    double? hideScale,
    OrionNavigationBadgeStyle? badge,
  }) {
    return OrionNavigationBarStyle(
      background: background,
      borderColor: borderColor,
      borderWidth: borderWidth,
      shadows: shadows,
      frosted: frosted,
      selectionColor: selectionColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(selectionColor),
      hoverColor: hoverColor,
      destinationColor: destinationColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(destinationColor),
      focusRingColor: focusRingColor,
      maxWidth: maxWidth,
      minHeight: minHeight,
      iconSize: iconSize,
      radius: radius,
      padding: padding,
      itemPadding: itemPadding,
      iconLabelGap: iconLabelGap,
      labelStyle: labelStyle,
      labelMode: labelMode,
      selectionSpring: selectionSpring,
      hideSpring: hideSpring,
      hideSlide: hideSlide,
      hideScale: hideScale,
      badge: badge,
    );
  }

  /// The built-in look, resolved against the ambient scheme, type scale, and
  /// layout [variant].
  static OrionNavigationBarStyle defaults({
    required ColorScheme scheme,
    TextStyle? labelStyle,
    OrionNavigationBarVariant variant = OrionNavigationBarVariant.floating,
  }) {
    final bool isDark = scheme.brightness == Brightness.dark;
    final bool docked = variant == OrionNavigationBarVariant.docked;
    final List<BoxShadow> defaultShadows = docked
        ? const <BoxShadow>[]
        : <BoxShadow>[
            BoxShadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.42 : 0.14),
              blurRadius: OrionSpacing.space24,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: scheme.shadow.withValues(alpha: isDark ? 0.24 : 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ];

    return OrionNavigationBarStyle(
      background: scheme.surfaceContainer,
      borderColor: scheme.outlineVariant,
      borderWidth: 1,
      shadows: defaultShadows,
      frosted: false,
      selectionColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => scheme.onSurface.withValues(
          alpha: states.contains(WidgetState.disabled) ? 0.04 : 0.08,
        ),
      ),
      hoverColor: scheme.onSurface.withValues(alpha: 0.05),
      destinationColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return scheme.primary;
        }
        if (states.contains(WidgetState.hovered)) {
          return scheme.onSurface;
        }
        return scheme.onSurfaceVariant;
      }),
      focusRingColor: scheme.onSurface,
      maxWidth: docked ? double.infinity : 360,
      iconSize: 20,
      radius: docked
          ? BorderRadius.zero
          : BorderRadius.circular(OrionRadii.radiusPill),
      padding: docked
          ? const EdgeInsets.symmetric(
              horizontal: OrionSpacing.space8,
              vertical: OrionSpacing.space4,
            )
          : const EdgeInsets.all(OrionSpacing.space4),
      labelStyle: labelStyle,
      labelMode: OrionNavigationLabelMode.all,
      selectionSpring: OrionSpringSpec.immediate,
      hideSpring: const OrionSpringSpec(stiffness: 380, dampingRatio: 1),
      hideSlide: 8,
      hideScale: 0.98,
      badge: OrionNavigationBadgeStyle.defaults(scheme: scheme),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionNavigationBarStyle &&
        other.background == background &&
        other.borderColor == borderColor &&
        other.borderWidth == borderWidth &&
        listEquals(other.shadows, shadows) &&
        other.frosted == frosted &&
        other.selectionColor == selectionColor &&
        other.hoverColor == hoverColor &&
        other.destinationColor == destinationColor &&
        other.focusRingColor == focusRingColor &&
        other.maxWidth == maxWidth &&
        other.minHeight == minHeight &&
        other.iconSize == iconSize &&
        other.radius == radius &&
        other.padding == padding &&
        other.itemPadding == itemPadding &&
        other.iconLabelGap == iconLabelGap &&
        other.labelStyle == labelStyle &&
        other.labelMode == labelMode &&
        other.selectionSpring == selectionSpring &&
        other.hideSpring == hideSpring &&
        other.hideSlide == hideSlide &&
        other.hideScale == hideScale &&
        other.badge == badge;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    background,
    borderColor,
    borderWidth,
    shadows == null ? null : Object.hashAll(shadows!),
    frosted,
    selectionColor,
    hoverColor,
    destinationColor,
    focusRingColor,
    maxWidth,
    minHeight,
    iconSize,
    radius,
    padding,
    itemPadding,
    iconLabelGap,
    labelStyle,
    labelMode,
    selectionSpring,
    hideSpring,
    hideSlide,
    hideScale,
    badge,
  ]);
}
