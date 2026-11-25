import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Preferred placement of an [OrionTooltip] relative to its trigger anchor.
enum OrionTooltipPlacement {
  /// Centered above the trigger.
  top,

  /// Centered below the trigger.
  bottom,

  /// Centered physically to the left of the trigger.
  left,

  /// Centered physically to the right of the trigger.
  right,

  /// Centered on the reading-order start side (left in LTR, right in RTL).
  start,

  /// Centered on the reading-order end side (right in LTR, left in RTL).
  end,
}

/// Resolved spatial layout for an [OrionTooltip].
@immutable
class OrionTooltipResolvedLayout {
  const OrionTooltipResolvedLayout({
    required this.offset,
    required this.transformOrigin,
    required this.isFlipped,
    required this.placement,
    this.arrowOffset,
  });

  /// Overlay-local position of the tooltip's top-left corner.
  final Offset offset;

  /// Normalized [Alignment] representing the transform origin for spring scale.
  final Alignment transformOrigin;

  /// Whether the tooltip auto-flipped or fell back across axes to prevent
  /// viewport clipping or overlapping its trigger.
  final bool isFlipped;

  /// The final physical placement (`top`, `bottom`, `left`, or `right`).
  final OrionTooltipPlacement placement;

  /// The local offset for the caret arrow along the tooltip boundary edge.
  final Offset? arrowOffset;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionTooltipResolvedLayout &&
        other.offset == offset &&
        other.transformOrigin == transformOrigin &&
        other.isFlipped == isFlipped &&
        other.placement == placement &&
        other.arrowOffset == arrowOffset;
  }

  @override
  int get hashCode =>
      Object.hash(offset, transformOrigin, isFlipped, placement, arrowOffset);
}

/// Pure geometric positioning calculator for micro-contextual tooltips.
abstract final class OrionTooltipGeometry {
  /// Resolves logical placements ([OrionTooltipPlacement.start] /
  /// [OrionTooltipPlacement.end]) into physical sides according to
  /// [textDirection].
  static OrionTooltipPlacement resolvePhysicalPlacement(
    OrionTooltipPlacement placement, {
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final bool isRtl = textDirection == TextDirection.rtl;
    return switch (placement) {
      OrionTooltipPlacement.start =>
        isRtl ? OrionTooltipPlacement.right : OrionTooltipPlacement.left,
      OrionTooltipPlacement.end =>
        isRtl ? OrionTooltipPlacement.left : OrionTooltipPlacement.right,
      _ => placement,
    };
  }

  /// Computes the optimal position, collision auto-flip (including cross-axis
  /// mobile fallback when neither horizontal side fits), arrow offset, and
  /// transform origin.
  static OrionTooltipResolvedLayout resolve({
    required Rect triggerRect,
    required Size tooltipSize,
    required Size viewportSize,
    EdgeInsets viewportPadding = const EdgeInsets.all(8.0),
    OrionTooltipPlacement preferredPlacement = OrionTooltipPlacement.top,
    double gap = 6.0,
    bool autoFlip = true,
    bool showArrow = true,
    Size arrowSize = const Size(10.0, 5.0),
    double arrowEdgeInset = 8.0,
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final double minX = viewportPadding.left;
    final double maxX = math.max(
      minX,
      viewportSize.width - viewportPadding.right - tooltipSize.width,
    );
    final double minY = viewportPadding.top;
    final double maxY = math.max(
      minY,
      viewportSize.height - viewportPadding.bottom - tooltipSize.height,
    );

    final double effectiveGap = showArrow ? gap + arrowSize.height : gap;
    final double requiredY = tooltipSize.height + effectiveGap;
    final double requiredX = tooltipSize.width + effectiveGap;

    final double topSpace = triggerRect.top - viewportPadding.top;
    final double bottomSpace =
        viewportSize.height - viewportPadding.bottom - triggerRect.bottom;
    final double leftSpace = triggerRect.left - viewportPadding.left;
    final double rightSpace =
        viewportSize.width - viewportPadding.right - triggerRect.right;

    OrionTooltipPlacement effectivePlacement = resolvePhysicalPlacement(
      preferredPlacement,
      textDirection: textDirection,
    );
    bool isFlipped = false;

    // 1. Viewport Collision, Opposite Flip & Cross-Axis Mobile Fallback
    if (autoFlip) {
      switch (effectivePlacement) {
        case OrionTooltipPlacement.top:
          if (topSpace < requiredY &&
              (bottomSpace >= requiredY || bottomSpace > topSpace)) {
            effectivePlacement = OrionTooltipPlacement.bottom;
            isFlipped = true;
          }
        case OrionTooltipPlacement.bottom:
          if (bottomSpace < requiredY &&
              (topSpace >= requiredY || topSpace > bottomSpace)) {
            effectivePlacement = OrionTooltipPlacement.top;
            isFlipped = true;
          }
        case OrionTooltipPlacement.left:
          if (leftSpace < requiredX) {
            if (rightSpace >= requiredX) {
              effectivePlacement = OrionTooltipPlacement.right;
              isFlipped = true;
            } else if (topSpace >= requiredY || bottomSpace >= requiredY) {
              effectivePlacement = topSpace >= requiredY
                  ? OrionTooltipPlacement.top
                  : OrionTooltipPlacement.bottom;
              isFlipped = true;
            } else if (rightSpace > leftSpace) {
              effectivePlacement = OrionTooltipPlacement.right;
              isFlipped = true;
            }
          }
        case OrionTooltipPlacement.right:
          if (rightSpace < requiredX) {
            if (leftSpace >= requiredX) {
              effectivePlacement = OrionTooltipPlacement.left;
              isFlipped = true;
            } else if (topSpace >= requiredY || bottomSpace >= requiredY) {
              effectivePlacement = topSpace >= requiredY
                  ? OrionTooltipPlacement.top
                  : OrionTooltipPlacement.bottom;
              isFlipped = true;
            } else if (leftSpace > rightSpace) {
              effectivePlacement = OrionTooltipPlacement.left;
              isFlipped = true;
            }
          }
        case OrionTooltipPlacement.start:
        case OrionTooltipPlacement.end:
          break;
      }
    }

    // 2. Position Calculation & Coordinate Clamping
    double x = 0.0;
    double y = 0.0;
    Alignment transformOrigin = Alignment.center;
    Offset? arrowOffset;

    double clampArrowAlongEdge(double centerLocal, double edgeLength) {
      final double maxPos = edgeLength - arrowSize.width;
      if (maxPos <= 0.0) {
        return maxPos / 2.0;
      }
      final double safeInset = math.min(
        math.max(0.0, arrowEdgeInset),
        maxPos / 2.0,
      );
      return (centerLocal - (arrowSize.width / 2.0)).clamp(
        safeInset,
        maxPos - safeInset,
      );
    }

    switch (effectivePlacement) {
      case OrionTooltipPlacement.top:
        x = (triggerRect.center.dx - (tooltipSize.width / 2.0)).clamp(
          minX,
          maxX,
        );
        y = (triggerRect.top - effectiveGap - tooltipSize.height).clamp(
          minY,
          maxY,
        );
        final double normX = tooltipSize.width > 0
            ? ((triggerRect.center.dx - x) / tooltipSize.width).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment((normX * 2.0) - 1.0, 1.0);
        if (showArrow) {
          final double arrowX = clampArrowAlongEdge(
            triggerRect.center.dx - x,
            tooltipSize.width,
          );
          arrowOffset = Offset(arrowX, tooltipSize.height);
        }

      case OrionTooltipPlacement.bottom:
        x = (triggerRect.center.dx - (tooltipSize.width / 2.0)).clamp(
          minX,
          maxX,
        );
        y = (triggerRect.bottom + effectiveGap).clamp(minY, maxY);
        final double normX = tooltipSize.width > 0
            ? ((triggerRect.center.dx - x) / tooltipSize.width).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment((normX * 2.0) - 1.0, -1.0);
        if (showArrow) {
          final double arrowX = clampArrowAlongEdge(
            triggerRect.center.dx - x,
            tooltipSize.width,
          );
          arrowOffset = Offset(arrowX, -arrowSize.height);
        }

      case OrionTooltipPlacement.left:
        x = (triggerRect.left - effectiveGap - tooltipSize.width).clamp(
          minX,
          maxX,
        );
        y = (triggerRect.center.dy - (tooltipSize.height / 2.0)).clamp(
          minY,
          maxY,
        );
        final double normY = tooltipSize.height > 0
            ? ((triggerRect.center.dy - y) / tooltipSize.height).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment(1.0, (normY * 2.0) - 1.0);
        if (showArrow) {
          final double arrowY = clampArrowAlongEdge(
            triggerRect.center.dy - y,
            tooltipSize.height,
          );
          arrowOffset = Offset(tooltipSize.width, arrowY);
        }

      case OrionTooltipPlacement.right:
        x = (triggerRect.right + effectiveGap).clamp(minX, maxX);
        y = (triggerRect.center.dy - (tooltipSize.height / 2.0)).clamp(
          minY,
          maxY,
        );
        final double normY = tooltipSize.height > 0
            ? ((triggerRect.center.dy - y) / tooltipSize.height).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment(-1.0, (normY * 2.0) - 1.0);
        if (showArrow) {
          final double arrowY = clampArrowAlongEdge(
            triggerRect.center.dy - y,
            tooltipSize.height,
          );
          arrowOffset = Offset(-arrowSize.height, arrowY);
        }

      case OrionTooltipPlacement.start:
      case OrionTooltipPlacement.end:
        break;
    }

    return OrionTooltipResolvedLayout(
      offset: Offset(x, y),
      transformOrigin: transformOrigin,
      isFlipped: isFlipped,
      placement: effectivePlacement,
      arrowOffset: arrowOffset,
    );
  }
}
