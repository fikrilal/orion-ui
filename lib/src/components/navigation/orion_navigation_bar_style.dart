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
    this.padding,
    this.ringColor,
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

  /// The chip's inner padding.
  final EdgeInsetsGeometry? padding;

  /// The ring drawn around the chip; the bar resolves the default to its own
  /// background so the badge reads as cut out of the icon.
  final Color? ringColor;

  /// Returns a copy with the provided fields replaced.
  OrionNavigationBadgeStyle copyWith({
    WidgetStateProperty<Color?>? fill,
    WidgetStateProperty<Color?>? ink,
    TextStyle? textStyle,
    double? height,
    double? minWidth,
    EdgeInsetsGeometry? padding,
    Color? ringColor,
  }) {
    return OrionNavigationBadgeStyle(
      fill: fill ?? this.fill,
      ink: ink ?? this.ink,
      textStyle: textStyle ?? this.textStyle,
      height: height ?? this.height,
      minWidth: minWidth ?? this.minWidth,
      padding: padding ?? this.padding,
      ringColor: ringColor ?? this.ringColor,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionNavigationBadgeStyle merge(OrionNavigationBadgeStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionNavigationBadgeStyle(
      fill: other.fill ?? fill,
      ink: other.ink ?? ink,
      textStyle: other.textStyle ?? textStyle,
      height: other.height ?? height,
      minWidth: other.minWidth ?? minWidth,
      padding: other.padding ?? padding,
      ringColor: other.ringColor ?? ringColor,
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
    EdgeInsetsGeometry? padding,
    Color? ringColor,
  }) {
    return OrionNavigationBadgeStyle(
      fill: fill == null ? null : WidgetStatePropertyAll<Color?>(fill),
      ink: ink == null ? null : WidgetStatePropertyAll<Color?>(ink),
      textStyle: textStyle,
      height: height,
      minWidth: minWidth,
      padding: padding,
      ringColor: ringColor,
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
      padding: const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
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
        other.padding == padding &&
        other.ringColor == ringColor;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    fill,
    ink,
    textStyle,
    height,
    minWidth,
    padding,
    ringColor,
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
/// destination's live [WidgetState]s - `disabled` and `selected` - and the
/// build lerps between the resolved off and on destination colours with the
/// proximity factor.
@immutable
class OrionNavigationBarStyle {
  const OrionNavigationBarStyle({
    this.background,
    this.borderColor,
    this.selectionColor,
    this.destinationColor,
    this.focusRingColor,
    this.maxWidth,
    this.minHeight,
    this.iconSize,
    this.radius,
    this.padding,
    this.labelStyle,
    this.labelMode,
    this.selectionSpring,
    this.hideSpring,
    this.hideSlide,
    this.hideScale,
    this.badge,
  });

  /// The capsule's fill.
  final Color? background;

  /// The capsule's hairline border.
  final Color? borderColor;

  /// The pill behind the selected slot, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? selectionColor;

  /// Destination icon and label colour, resolved per destination with its live
  /// states: [WidgetState.selected] and [WidgetState.disabled]. The build
  /// lerps between the resolved off and on colours with the proximity factor.
  final WidgetStateProperty<Color?>? destinationColor;

  /// The 2 pt focus ring drawn on the capsule.
  final Color? focusRingColor;

  /// The capsule's maximum width.
  final double? maxWidth;

  /// The capsule's minimum height; falls back to 64 with labels, or 52
  /// without them, so a label-less bar hugs its icons.
  final double? minHeight;

  /// Destination icon size, applied through [IconTheme].
  final double? iconSize;

  /// The capsule's corner radius.
  final BorderRadius? radius;

  /// The capsule's inner padding; the slots are laid out inside it.
  final EdgeInsetsGeometry? padding;

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

  /// Spring the show/hide of the capsule rides.
  final OrionSpringSpec? hideSpring;

  /// How far the capsule slides down when hidden.
  final double? hideSlide;

  /// How far the capsule shrinks when hidden.
  final double? hideScale;

  /// The destination badge chip's styling.
  final OrionNavigationBadgeStyle? badge;

  /// Returns a copy with the provided fields replaced.
  OrionNavigationBarStyle copyWith({
    Color? background,
    Color? borderColor,
    WidgetStateProperty<Color?>? selectionColor,
    WidgetStateProperty<Color?>? destinationColor,
    Color? focusRingColor,
    double? maxWidth,
    double? minHeight,
    double? iconSize,
    BorderRadius? radius,
    EdgeInsetsGeometry? padding,
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
      selectionColor: selectionColor ?? this.selectionColor,
      destinationColor: destinationColor ?? this.destinationColor,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      maxWidth: maxWidth ?? this.maxWidth,
      minHeight: minHeight ?? this.minHeight,
      iconSize: iconSize ?? this.iconSize,
      radius: radius ?? this.radius,
      padding: padding ?? this.padding,
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
  /// The nested [badge] style merges deeply, so a layer that sets only the
  /// chip's fill keeps everything else from the layer beneath.
  OrionNavigationBarStyle merge(OrionNavigationBarStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionNavigationBarStyle(
      background: other.background ?? background,
      borderColor: other.borderColor ?? borderColor,
      selectionColor: other.selectionColor ?? selectionColor,
      destinationColor: other.destinationColor ?? destinationColor,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      maxWidth: other.maxWidth ?? maxWidth,
      minHeight: other.minHeight ?? minHeight,
      iconSize: other.iconSize ?? iconSize,
      radius: other.radius ?? radius,
      padding: other.padding ?? padding,
      labelStyle: other.labelStyle ?? labelStyle,
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
    Color? selectionColor,
    Color? destinationColor,
    Color? focusRingColor,
    double? maxWidth,
    double? minHeight,
    double? iconSize,
    BorderRadius? radius,
    EdgeInsetsGeometry? padding,
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
      selectionColor: selectionColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(selectionColor),
      destinationColor: destinationColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(destinationColor),
      focusRingColor: focusRingColor,
      maxWidth: maxWidth,
      minHeight: minHeight,
      iconSize: iconSize,
      radius: radius,
      padding: padding,
      labelStyle: labelStyle,
      labelMode: labelMode,
      selectionSpring: selectionSpring,
      hideSpring: hideSpring,
      hideSlide: hideSlide,
      hideScale: hideScale,
      badge: badge,
    );
  }

  /// The built-in look: exactly what the bar shipped before this contract
  /// existed, resolved against the ambient scheme and type scale.
  static OrionNavigationBarStyle defaults({
    required ColorScheme scheme,
    TextStyle? labelStyle,
  }) {
    return OrionNavigationBarStyle(
      background: scheme.surface,
      borderColor: scheme.outlineVariant.a < 1
          ? scheme.outlineVariant
          : scheme.outlineVariant.withValues(alpha: 0.22),
      selectionColor: WidgetStateProperty.resolveWith<Color?>(
        (Set<WidgetState> states) => scheme.onSurface.withValues(
          alpha: states.contains(WidgetState.disabled) ? 0.04 : 0.08,
        ),
      ),
      destinationColor: WidgetStateProperty.resolveWith<Color?>((
        Set<WidgetState> states,
      ) {
        if (states.contains(WidgetState.disabled)) {
          return scheme.onSurface.withValues(alpha: 0.38);
        }
        return states.contains(WidgetState.selected)
            ? scheme.primary
            : scheme.onSurfaceVariant;
      }),
      focusRingColor: scheme.onSurface,
      maxWidth: 360,
      iconSize: 20,
      radius: BorderRadius.circular(OrionRadii.radiusPill),
      padding: const EdgeInsets.all(OrionSpacing.space4),
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
        other.selectionColor == selectionColor &&
        other.destinationColor == destinationColor &&
        other.focusRingColor == focusRingColor &&
        other.maxWidth == maxWidth &&
        other.minHeight == minHeight &&
        other.iconSize == iconSize &&
        other.radius == radius &&
        other.padding == padding &&
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
    selectionColor,
    destinationColor,
    focusRingColor,
    maxWidth,
    minHeight,
    iconSize,
    radius,
    padding,
    labelStyle,
    labelMode,
    selectionSpring,
    hideSpring,
    hideSlide,
    hideScale,
    badge,
  ]);
}
