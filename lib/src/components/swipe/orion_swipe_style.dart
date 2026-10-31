import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// How revealed action buttons move while an [OrionSwipeActionRow] is dragged.
enum OrionSwipeMotion {
  /// Actions stretch proportionally across the exact exposed width (native iOS
  /// Mail feel). The default.
  stretch,

  /// Actions slide out attached to the trailing/leading edge of the content
  /// like a drawer, stretching only past their resting extent.
  drawer,

  /// Actions stay stationary behind the content and are progressively revealed
  /// strictly inside the exposed strip, stretching only past their resting
  /// extent.
  behind,
}

/// The overridable visual and motion contract for [OrionSwipeActionRow].
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in [defaults], the ambient `OrionSwipeTheme`, and the instance style
/// passed to the row. Every field is nullable so overrides only change what
/// they name.
@immutable
class OrionSwipeStyle {
  const OrionSwipeStyle({
    this.actionExtent,
    this.borderRadius,
    this.actionGap,
    this.actionRadius,
    this.motion,
    this.iconSize,
    this.labelStyle,
    this.revealSpring,
    this.fullSwipeThreshold,
    this.hapticType,
    this.fullSwipeHapticType,
  });

  /// Resting width of a single flex-1 action button. Defaults to `74`.
  final double? actionExtent;

  /// Outer corner radius clipping the row and its revealed panes. Defaults to
  /// [BorderRadius.zero].
  final BorderRadius? borderRadius;

  /// Spacing between the sliding content and the action pane, and between
  /// individual actions when `> 0` (ideal for floating pill cards).
  final double? actionGap;

  /// Corner radius applied to each individual action button. Defaults to
  /// [BorderRadius.zero].
  final BorderRadius? actionRadius;

  /// Reveal choreography for the action pane. Defaults to
  /// [OrionSwipeMotion.stretch].
  final OrionSwipeMotion? motion;

  /// Icon size inside each action button. Defaults to `20`.
  final double? iconSize;

  /// Label typography inside each action button. Falls back to the ambient
  /// `labelSmall`.
  final TextStyle? labelStyle;

  /// Spring governing open, close, and snap-back settle animations.
  final OrionSpringSpec? revealSpring;

  /// Fraction of the row width (`0.35` to `0.85`) required to arm full-swipe
  /// commit when full swipe is enabled on a side. Defaults to `0.58`.
  final double? fullSwipeThreshold;

  /// Haptic cue emitted at the reveal threshold and when activating an action.
  /// Falls back to `OrionThemeData.selectionHaptic` when null.
  final OrionHapticType? hapticType;

  /// Stronger haptic cue emitted when crossing the full-swipe arm threshold.
  /// Defaults to [OrionHapticType.mediumImpact].
  final OrionHapticType? fullSwipeHapticType;

  /// Default reveal spring: crisp, silky, minimal overshoot.
  static const OrionSpringSpec defaultRevealSpring = OrionSpringSpec(
    stiffness: 420.0,
    dampingRatio: 0.88,
  );

  /// Built-in defaults for [OrionSwipeActionRow].
  static OrionSwipeStyle defaults({TextStyle? labelStyle}) {
    return OrionSwipeStyle(
      actionExtent: 74.0,
      borderRadius: BorderRadius.zero,
      actionGap: 0.0,
      actionRadius: BorderRadius.zero,
      motion: OrionSwipeMotion.stretch,
      iconSize: 20.0,
      labelStyle: labelStyle,
      revealSpring: defaultRevealSpring,
      fullSwipeThreshold: 0.58,
      fullSwipeHapticType: OrionHapticType.mediumImpact,
    );
  }

  /// Returns a copy with the provided fields replaced.
  OrionSwipeStyle copyWith({
    double? actionExtent,
    BorderRadius? borderRadius,
    double? actionGap,
    BorderRadius? actionRadius,
    OrionSwipeMotion? motion,
    double? iconSize,
    TextStyle? labelStyle,
    OrionSpringSpec? revealSpring,
    double? fullSwipeThreshold,
    OrionHapticType? hapticType,
    OrionHapticType? fullSwipeHapticType,
  }) {
    return OrionSwipeStyle(
      actionExtent: actionExtent ?? this.actionExtent,
      borderRadius: borderRadius ?? this.borderRadius,
      actionGap: actionGap ?? this.actionGap,
      actionRadius: actionRadius ?? this.actionRadius,
      motion: motion ?? this.motion,
      iconSize: iconSize ?? this.iconSize,
      labelStyle: labelStyle ?? this.labelStyle,
      revealSpring: revealSpring ?? this.revealSpring,
      fullSwipeThreshold: fullSwipeThreshold ?? this.fullSwipeThreshold,
      hapticType: hapticType ?? this.hapticType,
      fullSwipeHapticType: fullSwipeHapticType ?? this.fullSwipeHapticType,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  OrionSwipeStyle merge(OrionSwipeStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionSwipeStyle(
      actionExtent: other.actionExtent ?? actionExtent,
      borderRadius: other.borderRadius ?? borderRadius,
      actionGap: other.actionGap ?? actionGap,
      actionRadius: other.actionRadius ?? actionRadius,
      motion: other.motion ?? motion,
      iconSize: other.iconSize ?? iconSize,
      labelStyle: other.labelStyle ?? labelStyle,
      revealSpring: other.revealSpring ?? revealSpring,
      fullSwipeThreshold: other.fullSwipeThreshold ?? fullSwipeThreshold,
      hapticType: other.hapticType ?? hapticType,
      fullSwipeHapticType: other.fullSwipeHapticType ?? fullSwipeHapticType,
    );
  }

  /// Linearly interpolates between two swipe styles.
  static OrionSwipeStyle? lerp(
    OrionSwipeStyle? a,
    OrionSwipeStyle? b,
    double t,
  ) {
    if (identical(a, b)) {
      return a;
    }
    return OrionSwipeStyle(
      actionExtent: lerpDouble(a?.actionExtent, b?.actionExtent, t),
      borderRadius: BorderRadius.lerp(a?.borderRadius, b?.borderRadius, t),
      actionGap: lerpDouble(a?.actionGap, b?.actionGap, t),
      actionRadius: BorderRadius.lerp(a?.actionRadius, b?.actionRadius, t),
      motion: t < 0.5 ? a?.motion : b?.motion,
      iconSize: lerpDouble(a?.iconSize, b?.iconSize, t),
      labelStyle: TextStyle.lerp(a?.labelStyle, b?.labelStyle, t),
      revealSpring: t < 0.5 ? a?.revealSpring : b?.revealSpring,
      fullSwipeThreshold: lerpDouble(
        a?.fullSwipeThreshold,
        b?.fullSwipeThreshold,
        t,
      ),
      hapticType: t < 0.5 ? a?.hapticType : b?.hapticType,
      fullSwipeHapticType: t < 0.5
          ? a?.fullSwipeHapticType
          : b?.fullSwipeHapticType,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionSwipeStyle &&
        other.actionExtent == actionExtent &&
        other.borderRadius == borderRadius &&
        other.actionGap == actionGap &&
        other.actionRadius == actionRadius &&
        other.motion == motion &&
        other.iconSize == iconSize &&
        other.labelStyle == labelStyle &&
        other.revealSpring == revealSpring &&
        other.fullSwipeThreshold == fullSwipeThreshold &&
        other.hapticType == hapticType &&
        other.fullSwipeHapticType == fullSwipeHapticType;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    actionExtent,
    borderRadius,
    actionGap,
    actionRadius,
    motion,
    iconSize,
    labelStyle,
    revealSpring,
    fullSwipeThreshold,
    hapticType,
    fullSwipeHapticType,
  ]);
}
