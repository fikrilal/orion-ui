import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Preferred placement of an [OrionTooltip] relative to its trigger anchor.
enum OrionTooltipPlacement {
  /// Centered above the trigger.
  top,

  /// Centered below the trigger.
  bottom,

  /// Centered to the left of the trigger.
  left,

  /// Centered to the right of the trigger.
  right,
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

  /// Global position of the tooltip's top-left corner in the viewport.
  final Offset offset;

  /// Normalized [Alignment] representing the transform origin for micro-scale spring entrance.
  final Alignment transformOrigin;

  /// Whether the tooltip auto-flipped to the opposite side to prevent viewport clipping.
  final bool isFlipped;

  /// The final effective placement after collision resolution.
  final OrionTooltipPlacement placement;

  /// The local offset for the caret arrow along the tooltip boundary edge.
  final Offset? arrowOffset;
}

/// Pure geometric positioning calculator for micro-contextual tooltips.
abstract final class OrionTooltipGeometry {
  /// Computes the optimal position, collision auto-flip, and transform origin.
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

    OrionTooltipPlacement effectivePlacement = preferredPlacement;
    bool isFlipped = false;

    // 1. Viewport Collision & Auto-Flip Resolution
    if (autoFlip) {
      switch (preferredPlacement) {
        case OrionTooltipPlacement.top:
          final double topY =
              triggerRect.top - effectiveGap - tooltipSize.height;
          if (topY < minY) {
            final double bottomSpace =
                viewportSize.height -
                viewportPadding.bottom -
                triggerRect.bottom;
            final double topSpace = triggerRect.top - viewportPadding.top;
            if (bottomSpace >= tooltipSize.height + effectiveGap ||
                bottomSpace > topSpace) {
              effectivePlacement = OrionTooltipPlacement.bottom;
              isFlipped = true;
            }
          }
        case OrionTooltipPlacement.bottom:
          final double bottomY = triggerRect.bottom + effectiveGap;
          if (bottomY + tooltipSize.height >
              viewportSize.height - viewportPadding.bottom) {
            final double topSpace = triggerRect.top - viewportPadding.top;
            final double bottomSpace =
                viewportSize.height -
                viewportPadding.bottom -
                triggerRect.bottom;
            if (topSpace >= tooltipSize.height + effectiveGap ||
                topSpace > bottomSpace) {
              effectivePlacement = OrionTooltipPlacement.top;
              isFlipped = true;
            }
          }
        case OrionTooltipPlacement.left:
          final double leftX =
              triggerRect.left - effectiveGap - tooltipSize.width;
          if (leftX < minX) {
            final double rightSpace =
                viewportSize.width - viewportPadding.right - triggerRect.right;
            final double leftSpace = triggerRect.left - viewportPadding.left;
            if (rightSpace >= tooltipSize.width + effectiveGap ||
                rightSpace > leftSpace) {
              effectivePlacement = OrionTooltipPlacement.right;
              isFlipped = true;
            }
          }
        case OrionTooltipPlacement.right:
          final double rightX = triggerRect.right + effectiveGap;
          if (rightX + tooltipSize.width >
              viewportSize.width - viewportPadding.right) {
            final double leftSpace = triggerRect.left - viewportPadding.left;
            final double rightSpace =
                viewportSize.width - viewportPadding.right - triggerRect.right;
            if (leftSpace >= tooltipSize.width + effectiveGap ||
                leftSpace > rightSpace) {
              effectivePlacement = OrionTooltipPlacement.left;
              isFlipped = true;
            }
          }
      }
    }

    // 2. Position Calculation & Coordinate Clamping
    double x = 0.0;
    double y = 0.0;
    Alignment transformOrigin = Alignment.center;
    Offset? arrowOffset;

    switch (effectivePlacement) {
      case OrionTooltipPlacement.top:
        x = triggerRect.center.dx - (tooltipSize.width / 2.0);
        x = x.clamp(minX, maxX);
        y = triggerRect.top - effectiveGap - tooltipSize.height;
        final double normXTop = tooltipSize.width > 0
            ? ((triggerRect.center.dx - x) / tooltipSize.width).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment((normXTop * 2.0) - 1.0, 1.0);

        if (showArrow) {
          final double triggerCenterLocal = triggerRect.center.dx - x;
          final double arrowX = (triggerCenterLocal - (arrowSize.width / 2.0))
              .clamp(
                4.0,
                math.max(4.0, tooltipSize.width - arrowSize.width - 4.0),
              );
          arrowOffset = Offset(arrowX, tooltipSize.height);
        }

      case OrionTooltipPlacement.bottom:
        x = triggerRect.center.dx - (tooltipSize.width / 2.0);
        x = x.clamp(minX, maxX);
        y = triggerRect.bottom + effectiveGap;
        final double normXBottom = tooltipSize.width > 0
            ? ((triggerRect.center.dx - x) / tooltipSize.width).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment((normXBottom * 2.0) - 1.0, -1.0);

        if (showArrow) {
          final double triggerCenterLocal = triggerRect.center.dx - x;
          final double arrowX = (triggerCenterLocal - (arrowSize.width / 2.0))
              .clamp(
                4.0,
                math.max(4.0, tooltipSize.width - arrowSize.width - 4.0),
              );
          arrowOffset = Offset(arrowX, -arrowSize.height);
        }

      case OrionTooltipPlacement.left:
        x = triggerRect.left - effectiveGap - tooltipSize.width;
        x = x.clamp(minX, maxX);
        y = triggerRect.center.dy - (tooltipSize.height / 2.0);
        y = y.clamp(minY, maxY);
        final double normYLeft = tooltipSize.height > 0
            ? ((triggerRect.center.dy - y) / tooltipSize.height).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment(1.0, (normYLeft * 2.0) - 1.0);

        if (showArrow) {
          final double triggerCenterLocal = triggerRect.center.dy - y;
          final double arrowY = (triggerCenterLocal - (arrowSize.width / 2.0))
              .clamp(
                4.0,
                math.max(4.0, tooltipSize.height - arrowSize.width - 4.0),
              );
          arrowOffset = Offset(tooltipSize.width, arrowY);
        }

      case OrionTooltipPlacement.right:
        x = triggerRect.right + effectiveGap;
        x = x.clamp(minX, maxX);
        y = triggerRect.center.dy - (tooltipSize.height / 2.0);
        y = y.clamp(minY, maxY);
        final double normYRight = tooltipSize.height > 0
            ? ((triggerRect.center.dy - y) / tooltipSize.height).clamp(0.0, 1.0)
            : 0.5;
        transformOrigin = Alignment(-1.0, (normYRight * 2.0) - 1.0);

        if (showArrow) {
          final double triggerCenterLocal = triggerRect.center.dy - y;
          final double arrowY = (triggerCenterLocal - (arrowSize.width / 2.0))
              .clamp(
                4.0,
                math.max(4.0, tooltipSize.height - arrowSize.width - 4.0),
              );
          arrowOffset = Offset(-arrowSize.height, arrowY);
        }
    }

    // Safety clamp Y for top/bottom
    y = y.clamp(minY, maxY);

    return OrionTooltipResolvedLayout(
      offset: Offset(x, y),
      transformOrigin: transformOrigin,
      isFlipped: isFlipped,
      placement: effectivePlacement,
      arrowOffset: arrowOffset,
    );
  }
}
