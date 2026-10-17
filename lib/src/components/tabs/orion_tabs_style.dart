import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Visual treatment of the active indicator in an [OrionTabs] component.
enum OrionTabsVariant {
  /// Baseline horizontal accent line beneath the active tab.
  underline,

  /// Floating rounded capsule background behind the active tab.
  pill,

  /// Inset capsule inside a card track container.
  segment,
}

/// Sizing and layout distribution of tabs within [OrionTabs].
enum OrionTabsDistribution {
  /// Tabs measure their natural intrinsic content width; scrolls horizontally if overflowing.
  intrinsic,

  /// Tabs divide the available track width equally.
  equal,
}

/// The visual and physical styling contract for [OrionTabs].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionTabsPresets`, the ambient `OrionTabsTheme`, and the
/// instance style passed to the component.
@immutable
class OrionTabsStyle {
  const OrionTabsStyle({
    this.indicatorColor,
    this.indicatorHeight,
    this.indicatorRadius,
    this.trackColor,
    this.trackBorderRadius,
    this.activeLabelColor,
    this.inactiveLabelColor,
    this.disabledLabelColor,
    this.labelStyle,
    this.tabPadding,
    this.trackPadding,
    this.tabSpacing,
    this.springSpec,
    this.pressedScale,
    this.pressSpring,
    this.releaseSpring,
    this.hapticType,
    this.focusRingColor,
    this.iconSize,
  });

  /// Color of the moving active indicator.
  final Color? indicatorColor;

  /// Height/thickness of the indicator (primarily for [OrionTabsVariant.underline]).
  final double? indicatorHeight;

  /// Corner radius of the indicator.
  final BorderRadius? indicatorRadius;

  /// Background color of the tab bar track.
  final Color? trackColor;

  /// Corner radius of the overall tab bar track.
  final BorderRadius? trackBorderRadius;

  /// Text and icon color for the active selected tab.
  final Color? activeLabelColor;

  /// Text and icon color for inactive tabs.
  final Color? inactiveLabelColor;

  /// Text and icon color for disabled tabs.
  final Color? disabledLabelColor;

  /// Base typography style for tab labels.
  final TextStyle? labelStyle;

  /// Internal padding for each individual tab button.
  final EdgeInsetsGeometry? tabPadding;

  /// Padding surrounding the inner tab bar track.
  final EdgeInsetsGeometry? trackPadding;

  /// Horizontal spacing between adjacent tabs.
  final double? tabSpacing;

  /// Spring specification governing indicator travel.
  final OrionSpringSpec? springSpec;

  /// Micro-scale factor applied during pointer down press.
  final double? pressedScale;

  /// Spring specification for press down compression.
  final OrionSpringSpec? pressSpring;

  /// Spring specification for press up release recovery.
  final OrionSpringSpec? releaseSpring;

  /// Tactile feedback triggered when a tab is selected.
  final OrionHapticType? hapticType;

  /// Color of the focus outline ring when navigated via keyboard.
  final Color? focusRingColor;

  /// Size of tab leading icons.
  final double? iconSize;

  /// Convenience factory creating a style with only named properties.
  factory OrionTabsStyle.from({
    Color? indicatorColor,
    double? indicatorHeight,
    BorderRadius? indicatorRadius,
    Color? trackColor,
    BorderRadius? trackBorderRadius,
    Color? activeLabelColor,
    Color? inactiveLabelColor,
    Color? disabledLabelColor,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? tabPadding,
    EdgeInsetsGeometry? trackPadding,
    double? tabSpacing,
    OrionSpringSpec? springSpec,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
    Color? focusRingColor,
    double? iconSize,
  }) {
    return OrionTabsStyle(
      indicatorColor: indicatorColor,
      indicatorHeight: indicatorHeight,
      indicatorRadius: indicatorRadius,
      trackColor: trackColor,
      trackBorderRadius: trackBorderRadius,
      activeLabelColor: activeLabelColor,
      inactiveLabelColor: inactiveLabelColor,
      disabledLabelColor: disabledLabelColor,
      labelStyle: labelStyle,
      tabPadding: tabPadding,
      trackPadding: trackPadding,
      tabSpacing: tabSpacing,
      springSpec: springSpec,
      pressedScale: pressedScale,
      pressSpring: pressSpring,
      releaseSpring: releaseSpring,
      hapticType: hapticType,
      focusRingColor: focusRingColor,
      iconSize: iconSize,
    );
  }

  /// Returns a copy with the provided fields replaced.
  OrionTabsStyle copyWith({
    Color? indicatorColor,
    double? indicatorHeight,
    BorderRadius? indicatorRadius,
    Color? trackColor,
    BorderRadius? trackBorderRadius,
    Color? activeLabelColor,
    Color? inactiveLabelColor,
    Color? disabledLabelColor,
    TextStyle? labelStyle,
    EdgeInsetsGeometry? tabPadding,
    EdgeInsetsGeometry? trackPadding,
    double? tabSpacing,
    OrionSpringSpec? springSpec,
    double? pressedScale,
    OrionSpringSpec? pressSpring,
    OrionSpringSpec? releaseSpring,
    OrionHapticType? hapticType,
    Color? focusRingColor,
    double? iconSize,
  }) {
    return OrionTabsStyle(
      indicatorColor: indicatorColor ?? this.indicatorColor,
      indicatorHeight: indicatorHeight ?? this.indicatorHeight,
      indicatorRadius: indicatorRadius ?? this.indicatorRadius,
      trackColor: trackColor ?? this.trackColor,
      trackBorderRadius: trackBorderRadius ?? this.trackBorderRadius,
      activeLabelColor: activeLabelColor ?? this.activeLabelColor,
      inactiveLabelColor: inactiveLabelColor ?? this.inactiveLabelColor,
      disabledLabelColor: disabledLabelColor ?? this.disabledLabelColor,
      labelStyle: labelStyle ?? this.labelStyle,
      tabPadding: tabPadding ?? this.tabPadding,
      trackPadding: trackPadding ?? this.trackPadding,
      tabSpacing: tabSpacing ?? this.tabSpacing,
      springSpec: springSpec ?? this.springSpec,
      pressedScale: pressedScale ?? this.pressedScale,
      pressSpring: pressSpring ?? this.pressSpring,
      releaseSpring: releaseSpring ?? this.releaseSpring,
      hapticType: hapticType ?? this.hapticType,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      iconSize: iconSize ?? this.iconSize,
    );
  }

  /// Merges this style with [other], where [other]'s non-null fields take precedence.
  OrionTabsStyle merge(OrionTabsStyle? other) {
    if (other == null) return this;
    return OrionTabsStyle(
      indicatorColor: other.indicatorColor ?? indicatorColor,
      indicatorHeight: other.indicatorHeight ?? indicatorHeight,
      indicatorRadius: other.indicatorRadius ?? indicatorRadius,
      trackColor: other.trackColor ?? trackColor,
      trackBorderRadius: other.trackBorderRadius ?? trackBorderRadius,
      activeLabelColor: other.activeLabelColor ?? activeLabelColor,
      inactiveLabelColor: other.inactiveLabelColor ?? inactiveLabelColor,
      disabledLabelColor: other.disabledLabelColor ?? disabledLabelColor,
      labelStyle: other.labelStyle ?? labelStyle,
      tabPadding: other.tabPadding ?? tabPadding,
      trackPadding: other.trackPadding ?? trackPadding,
      tabSpacing: other.tabSpacing ?? tabSpacing,
      springSpec: other.springSpec ?? springSpec,
      pressedScale: other.pressedScale ?? pressedScale,
      pressSpring: other.pressSpring ?? pressSpring,
      releaseSpring: other.releaseSpring ?? releaseSpring,
      hapticType: other.hapticType ?? hapticType,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      iconSize: other.iconSize ?? iconSize,
    );
  }

  /// Linearly interpolates between two [OrionTabsStyle] instances.
  static OrionTabsStyle? lerp(OrionTabsStyle? a, OrionTabsStyle? b, double t) {
    if (identical(a, b)) return a;
    if (a == null) return b;
    if (b == null) return a;
    return OrionTabsStyle(
      indicatorColor: Color.lerp(a.indicatorColor, b.indicatorColor, t),
      indicatorHeight: lerpDouble(a.indicatorHeight, b.indicatorHeight, t),
      indicatorRadius: BorderRadius.lerp(
        a.indicatorRadius,
        b.indicatorRadius,
        t,
      ),
      trackColor: Color.lerp(a.trackColor, b.trackColor, t),
      trackBorderRadius: BorderRadius.lerp(
        a.trackBorderRadius,
        b.trackBorderRadius,
        t,
      ),
      activeLabelColor: Color.lerp(a.activeLabelColor, b.activeLabelColor, t),
      inactiveLabelColor: Color.lerp(
        a.inactiveLabelColor,
        b.inactiveLabelColor,
        t,
      ),
      disabledLabelColor: Color.lerp(
        a.disabledLabelColor,
        b.disabledLabelColor,
        t,
      ),
      labelStyle: TextStyle.lerp(a.labelStyle, b.labelStyle, t),
      tabPadding: EdgeInsetsGeometry.lerp(a.tabPadding, b.tabPadding, t),
      trackPadding: EdgeInsetsGeometry.lerp(a.trackPadding, b.trackPadding, t),
      tabSpacing: lerpDouble(a.tabSpacing, b.tabSpacing, t),
      springSpec: t < 0.5 ? a.springSpec : b.springSpec,
      pressedScale: lerpDouble(a.pressedScale, b.pressedScale, t),
      pressSpring: t < 0.5 ? a.pressSpring : b.pressSpring,
      releaseSpring: t < 0.5 ? a.releaseSpring : b.releaseSpring,
      hapticType: t < 0.5 ? a.hapticType : b.hapticType,
      focusRingColor: Color.lerp(a.focusRingColor, b.focusRingColor, t),
      iconSize: lerpDouble(a.iconSize, b.iconSize, t),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrionTabsStyle &&
          runtimeType == other.runtimeType &&
          indicatorColor == other.indicatorColor &&
          indicatorHeight == other.indicatorHeight &&
          indicatorRadius == other.indicatorRadius &&
          trackColor == other.trackColor &&
          trackBorderRadius == other.trackBorderRadius &&
          activeLabelColor == other.activeLabelColor &&
          inactiveLabelColor == other.inactiveLabelColor &&
          disabledLabelColor == other.disabledLabelColor &&
          labelStyle == other.labelStyle &&
          tabPadding == other.tabPadding &&
          trackPadding == other.trackPadding &&
          tabSpacing == other.tabSpacing &&
          springSpec == other.springSpec &&
          pressedScale == other.pressedScale &&
          pressSpring == other.pressSpring &&
          releaseSpring == other.releaseSpring &&
          hapticType == other.hapticType &&
          focusRingColor == other.focusRingColor &&
          iconSize == other.iconSize;

  @override
  int get hashCode => Object.hashAll([
    indicatorColor,
    indicatorHeight,
    indicatorRadius,
    trackColor,
    trackBorderRadius,
    activeLabelColor,
    inactiveLabelColor,
    disabledLabelColor,
    labelStyle,
    tabPadding,
    trackPadding,
    tabSpacing,
    springSpec,
    pressedScale,
    pressSpring,
    releaseSpring,
    hapticType,
    focusRingColor,
    iconSize,
  ]);
}
