import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// Visual indicator framing the active centre slot of an [OrionWheelPicker].
enum OrionWheelSelectionStyle {
  /// Soft translucent rounded band framing the active centre row.
  pill,

  /// Minimal top and bottom hairline dividers across the centre slot.
  hairlines,

  /// No centre slot indicator.
  none,
}

/// The overridable contract for how an [OrionWheelPicker] looks and moves.
///
/// Three layers produce the effective style, each overriding the last: the
/// built-in `OrionWheelPickerPresets`, the theme's `OrionWheelPickerTheme`,
/// and the instance style passed to the widget. Every field is nullable; a
/// null field falls through to the layer beneath it, so an override changes
/// exactly what it names.
@immutable
class OrionWheelPickerStyle {
  const OrionWheelPickerStyle({
    this.selectedColor,
    this.idleColor,
    this.textStyle,
    this.selectedTextStyle,
    this.selectionStyle,
    this.selectionColor,
    this.selectionBorderColor,
    this.selectionRadius,
    this.radius,
    this.itemExtent,
    this.edgeScale,
    this.diameterRatio,
    this.perspective,
    this.squeeze,
    this.offAxisFraction,
    this.edgeFade,
    this.horizontalPadding,
    this.projectionSeconds,
    this.endResistance,
    this.focusRingColor,
    this.focusRingWidth,
    this.settleSpring,
  });

  /// The centred row's colour, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? selectedColor;

  /// The other rows' colour, resolved with [WidgetState.disabled].
  final WidgetStateProperty<Color?>? idleColor;

  /// Base text style for all rows; a row's label inherits it.
  final TextStyle? textStyle;

  /// Optional text style overrides merged over [textStyle] on the centred row
  /// (for example, `FontWeight.w600` emphasis).
  final TextStyle? selectedTextStyle;

  /// Visual treatment of the centre selection indicator band.
  final OrionWheelSelectionStyle? selectionStyle;

  /// Fill colour for [OrionWheelSelectionStyle.pill].
  final Color? selectionColor;

  /// Hairline stroke colour for [OrionWheelSelectionStyle.hairlines].
  final Color? selectionBorderColor;

  /// Corner radius of [OrionWheelSelectionStyle.pill]. Override with one-sided
  /// radii (e.g. `BorderRadius.horizontal(left: ...)`) to join multi-column
  /// wheels into one continuous selection bar.
  final BorderRadius? selectionRadius;

  /// The wheel box's corner radius.
  final BorderRadius? radius;

  /// One row's extent. Every row is its own tap target, so the wheel is
  /// `visibleItemCount` extents tall with no per-item measurement.
  final double? itemExtent;

  /// Scale of a row at the edge of the band when rendered in flat 2D mode
  /// (`perspective == 0` or infinite `diameterRatio`).
  final double? edgeScale;

  /// Ratio between the simulated 3D cylinder's diameter and the wheel height,
  /// matching iOS `CupertinoPicker` (`1.07` by default). Smaller values curve
  /// more tightly; set to [double.infinity] (or `perspective: 0.0`) for flat 2D.
  final double? diameterRatio;

  /// Perspective depth factor passed to
  /// [MatrixUtils.createCylindricalProjectionTransform] (`0.003` by default,
  /// matching iOS `CupertinoPicker`). Set to `0.0` to switch to flat 2D mode.
  final double? perspective;

  /// Angular compactness of items along the 3D cylinder (`1.25` by default).
  /// Higher values pack more curved rows toward the top and bottom horizon.
  final double? squeeze;

  /// Horizontal vanishing-point shift (`0.0` centred). In multi-column pickers,
  /// use negative values on the left column (e.g. `-0.35`) and positive values
  /// on the right column (`+0.35`) so the columns curve inward as one drum.
  final double? offAxisFraction;

  /// Whether to dissolve top and bottom edges with a background-agnostic alpha
  /// gradient mask.
  final bool? edgeFade;

  /// Horizontal inset padding inside each row so wide labels do not touch edges.
  final double? horizontalPadding;

  /// How much of the release velocity projects into the landing distance, in
  /// seconds. This is the wheel's flick feel.
  final double? projectionSeconds;

  /// Initial resistance fraction for out-of-range drags before asymptotic cap.
  final double? endResistance;

  /// The focus ring's colour. The ring is drawn over the box, so showing focus
  /// never moves a row.
  final Color? focusRingColor;

  /// The focus ring's width.
  final double? focusRingWidth;

  /// Spring the settle rides. Critically damped by default, because an
  /// underdamped settle overshoots far enough to cross the next boundary - the
  /// wheel would ring past the detent it aimed at and tick again.
  final OrionSpringSpec? settleSpring;

  /// Returns a copy with the provided fields replaced.
  OrionWheelPickerStyle copyWith({
    WidgetStateProperty<Color?>? selectedColor,
    WidgetStateProperty<Color?>? idleColor,
    TextStyle? textStyle,
    TextStyle? selectedTextStyle,
    OrionWheelSelectionStyle? selectionStyle,
    Color? selectionColor,
    Color? selectionBorderColor,
    BorderRadius? selectionRadius,
    BorderRadius? radius,
    double? itemExtent,
    double? edgeScale,
    double? diameterRatio,
    double? perspective,
    double? squeeze,
    double? offAxisFraction,
    bool? edgeFade,
    double? horizontalPadding,
    double? projectionSeconds,
    double? endResistance,
    Color? focusRingColor,
    double? focusRingWidth,
    OrionSpringSpec? settleSpring,
  }) {
    return OrionWheelPickerStyle(
      selectedColor: selectedColor ?? this.selectedColor,
      idleColor: idleColor ?? this.idleColor,
      textStyle: textStyle ?? this.textStyle,
      selectedTextStyle: selectedTextStyle ?? this.selectedTextStyle,
      selectionStyle: selectionStyle ?? this.selectionStyle,
      selectionColor: selectionColor ?? this.selectionColor,
      selectionBorderColor: selectionBorderColor ?? this.selectionBorderColor,
      selectionRadius: selectionRadius ?? this.selectionRadius,
      radius: radius ?? this.radius,
      itemExtent: itemExtent ?? this.itemExtent,
      edgeScale: edgeScale ?? this.edgeScale,
      diameterRatio: diameterRatio ?? this.diameterRatio,
      perspective: perspective ?? this.perspective,
      squeeze: squeeze ?? this.squeeze,
      offAxisFraction: offAxisFraction ?? this.offAxisFraction,
      edgeFade: edgeFade ?? this.edgeFade,
      horizontalPadding: horizontalPadding ?? this.horizontalPadding,
      projectionSeconds: projectionSeconds ?? this.projectionSeconds,
      endResistance: endResistance ?? this.endResistance,
      focusRingColor: focusRingColor ?? this.focusRingColor,
      focusRingWidth: focusRingWidth ?? this.focusRingWidth,
      settleSpring: settleSpring ?? this.settleSpring,
    );
  }

  /// Returns this style with every non-null field of [other] applied on top.
  ///
  /// [textStyle] and [selectedTextStyle] merge via [TextStyle.merge] so partial
  /// overrides preserve preset typography and tabular numerals.
  OrionWheelPickerStyle merge(OrionWheelPickerStyle? other) {
    if (other == null) {
      return this;
    }
    return OrionWheelPickerStyle(
      selectedColor: other.selectedColor ?? selectedColor,
      idleColor: other.idleColor ?? idleColor,
      textStyle: textStyle != null && other.textStyle != null
          ? textStyle!.merge(other.textStyle)
          : (other.textStyle ?? textStyle),
      selectedTextStyle:
          selectedTextStyle != null && other.selectedTextStyle != null
          ? selectedTextStyle!.merge(other.selectedTextStyle)
          : (other.selectedTextStyle ?? selectedTextStyle),
      selectionStyle: other.selectionStyle ?? selectionStyle,
      selectionColor: other.selectionColor ?? selectionColor,
      selectionBorderColor: other.selectionBorderColor ?? selectionBorderColor,
      selectionRadius: other.selectionRadius ?? selectionRadius,
      radius: other.radius ?? radius,
      itemExtent: other.itemExtent ?? itemExtent,
      edgeScale: other.edgeScale ?? edgeScale,
      diameterRatio: other.diameterRatio ?? diameterRatio,
      perspective: other.perspective ?? perspective,
      squeeze: other.squeeze ?? squeeze,
      offAxisFraction: other.offAxisFraction ?? offAxisFraction,
      edgeFade: other.edgeFade ?? edgeFade,
      horizontalPadding: other.horizontalPadding ?? horizontalPadding,
      projectionSeconds: other.projectionSeconds ?? projectionSeconds,
      endResistance: other.endResistance ?? endResistance,
      focusRingColor: other.focusRingColor ?? focusRingColor,
      focusRingWidth: other.focusRingWidth ?? focusRingWidth,
      settleSpring: other.settleSpring ?? settleSpring,
    );
  }

  /// Linearly interpolates between two [OrionWheelPickerStyle]s.
  static OrionWheelPickerStyle? lerp(
    OrionWheelPickerStyle? a,
    OrionWheelPickerStyle? b,
    double t,
  ) {
    if (identical(a, b)) return a;
    if (a == null && b == null) return null;
    if (a == null) return t < 0.5 ? null : b;
    if (b == null) return t < 0.5 ? a : null;
    return OrionWheelPickerStyle(
      selectedColor: WidgetStateProperty.lerp<Color?>(
        a.selectedColor,
        b.selectedColor,
        t,
        Color.lerp,
      ),
      idleColor: WidgetStateProperty.lerp<Color?>(
        a.idleColor,
        b.idleColor,
        t,
        Color.lerp,
      ),
      textStyle: TextStyle.lerp(a.textStyle, b.textStyle, t),
      selectedTextStyle: TextStyle.lerp(
        a.selectedTextStyle,
        b.selectedTextStyle,
        t,
      ),
      selectionStyle: t < 0.5 ? a.selectionStyle : b.selectionStyle,
      selectionColor: Color.lerp(a.selectionColor, b.selectionColor, t),
      selectionBorderColor: Color.lerp(
        a.selectionBorderColor,
        b.selectionBorderColor,
        t,
      ),
      selectionRadius: BorderRadius.lerp(
        a.selectionRadius,
        b.selectionRadius,
        t,
      ),
      radius: BorderRadius.lerp(a.radius, b.radius, t),
      itemExtent: lerpDouble(a.itemExtent, b.itemExtent, t),
      edgeScale: lerpDouble(a.edgeScale, b.edgeScale, t),
      diameterRatio:
          (a.diameterRatio?.isInfinite ?? false) ||
              (b.diameterRatio?.isInfinite ?? false)
          ? (t < 0.5 ? a.diameterRatio : b.diameterRatio)
          : lerpDouble(a.diameterRatio, b.diameterRatio, t),
      perspective: lerpDouble(a.perspective, b.perspective, t),
      squeeze: lerpDouble(a.squeeze, b.squeeze, t),
      offAxisFraction: lerpDouble(a.offAxisFraction, b.offAxisFraction, t),
      edgeFade: t < 0.5 ? a.edgeFade : b.edgeFade,
      horizontalPadding: lerpDouble(
        a.horizontalPadding,
        b.horizontalPadding,
        t,
      ),
      projectionSeconds: lerpDouble(
        a.projectionSeconds,
        b.projectionSeconds,
        t,
      ),
      endResistance: lerpDouble(a.endResistance, b.endResistance, t),
      focusRingColor: Color.lerp(a.focusRingColor, b.focusRingColor, t),
      focusRingWidth: lerpDouble(a.focusRingWidth, b.focusRingWidth, t),
      settleSpring: t < 0.5 ? a.settleSpring : b.settleSpring,
    );
  }

  /// Builds a style from plain values, each colour applied to every state.
  static OrionWheelPickerStyle from({
    Color? selectedColor,
    Color? idleColor,
    TextStyle? textStyle,
    TextStyle? selectedTextStyle,
    OrionWheelSelectionStyle? selectionStyle,
    Color? selectionColor,
    Color? selectionBorderColor,
    BorderRadius? selectionRadius,
    BorderRadius? radius,
    double? itemExtent,
    double? edgeScale,
    double? diameterRatio,
    double? perspective,
    double? squeeze,
    double? offAxisFraction,
    bool? edgeFade,
    double? horizontalPadding,
    double? projectionSeconds,
    double? endResistance,
    Color? focusRingColor,
    double? focusRingWidth,
    OrionSpringSpec? settleSpring,
  }) {
    return OrionWheelPickerStyle(
      selectedColor: selectedColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(selectedColor),
      idleColor: idleColor == null
          ? null
          : WidgetStatePropertyAll<Color?>(idleColor),
      textStyle: textStyle,
      selectedTextStyle: selectedTextStyle,
      selectionStyle: selectionStyle,
      selectionColor: selectionColor,
      selectionBorderColor: selectionBorderColor,
      selectionRadius: selectionRadius,
      radius: radius,
      itemExtent: itemExtent,
      edgeScale: edgeScale,
      diameterRatio: diameterRatio,
      perspective: perspective,
      squeeze: squeeze,
      offAxisFraction: offAxisFraction,
      edgeFade: edgeFade,
      horizontalPadding: horizontalPadding,
      projectionSeconds: projectionSeconds,
      endResistance: endResistance,
      focusRingColor: focusRingColor,
      focusRingWidth: focusRingWidth,
      settleSpring: settleSpring,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) {
      return true;
    }
    return other is OrionWheelPickerStyle &&
        other.selectedColor == selectedColor &&
        other.idleColor == idleColor &&
        other.textStyle == textStyle &&
        other.selectedTextStyle == selectedTextStyle &&
        other.selectionStyle == selectionStyle &&
        other.selectionColor == selectionColor &&
        other.selectionBorderColor == selectionBorderColor &&
        other.selectionRadius == selectionRadius &&
        other.radius == radius &&
        other.itemExtent == itemExtent &&
        other.edgeScale == edgeScale &&
        other.diameterRatio == diameterRatio &&
        other.perspective == perspective &&
        other.squeeze == squeeze &&
        other.offAxisFraction == offAxisFraction &&
        other.edgeFade == edgeFade &&
        other.horizontalPadding == horizontalPadding &&
        other.projectionSeconds == projectionSeconds &&
        other.endResistance == endResistance &&
        other.focusRingColor == focusRingColor &&
        other.focusRingWidth == focusRingWidth &&
        other.settleSpring == settleSpring;
  }

  @override
  int get hashCode => Object.hashAll(<Object?>[
    selectedColor,
    idleColor,
    textStyle,
    selectedTextStyle,
    selectionStyle,
    selectionColor,
    selectionBorderColor,
    selectionRadius,
    radius,
    itemExtent,
    edgeScale,
    diameterRatio,
    perspective,
    squeeze,
    offAxisFraction,
    edgeFade,
    horizontalPadding,
    projectionSeconds,
    endResistance,
    focusRingColor,
    focusRingWidth,
    settleSpring,
  ]);
}
