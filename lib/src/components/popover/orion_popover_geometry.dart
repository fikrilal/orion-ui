import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Preferred placement of a popover relative to its anchor trigger.
enum OrionPopoverPlacement {
  topStart,
  topCenter,
  topEnd,
  bottomStart,
  bottomCenter,
  bottomEnd,
}

/// Resolved spatial layout for an [OrionPopover].
@immutable
class OrionPopoverResolvedLayout {
  const OrionPopoverResolvedLayout({
    required this.offset,
    required this.transformOrigin,
    required this.isFlipped,
    required this.placement,
    this.arrowOffset,
  });

  /// Global position of the popover's top-left corner in the viewport.
  final Offset offset;

  /// Normalized [Alignment] representing the transform origin for spring scale.
  final Alignment transformOrigin;

  /// Whether the popover auto-flipped to the opposite vertical side to avoid screen collision.
  final bool isFlipped;

  /// The final effective placement.
  final OrionPopoverPlacement placement;

  /// The horizontal or vertical offset for the caret arrow along the popover edge, if visible.
  final Offset? arrowOffset;

  /// Whether this resolved placement sits above the trigger.
  bool get isTop =>
      placement == OrionPopoverPlacement.topStart ||
      placement == OrionPopoverPlacement.topCenter ||
      placement == OrionPopoverPlacement.topEnd;
}

/// Pure geometric positioning calculator for popovers and floating menus.
abstract final class OrionPopoverGeometry {
  /// Computes the optimal position, auto-flip, and transform origin for a popover.
  static OrionPopoverResolvedLayout resolve({
    required Rect triggerRect,
    required Size popoverSize,
    required Size viewportSize,
    EdgeInsets viewportPadding = const EdgeInsets.all(12.0),
    OrionPopoverPlacement preferredPlacement =
        OrionPopoverPlacement.bottomStart,
    double gap = 8.0,
    bool autoFlip = true,
    bool showArrow = false,
    Size arrowSize = const Size(14.0, 7.0),
    TextDirection textDirection = TextDirection.ltr,
  }) {
    final double minX = viewportPadding.left;
    final double maxX = math.max(
      minX,
      viewportSize.width - viewportPadding.right - popoverSize.width,
    );
    final double minY = viewportPadding.top;
    final double maxY = math.max(
      minY,
      viewportSize.height - viewportPadding.bottom - popoverSize.height,
    );

    final double effectiveGap = showArrow ? gap + arrowSize.height : gap;

    // 1. Determine Vertical Placement (Top vs Bottom)
    final bool preferredIsTop =
        preferredPlacement == OrionPopoverPlacement.topStart ||
        preferredPlacement == OrionPopoverPlacement.topCenter ||
        preferredPlacement == OrionPopoverPlacement.topEnd;

    bool isTop = preferredIsTop;
    bool isFlipped = false;

    final double spaceBelow =
        viewportSize.height - viewportPadding.bottom - triggerRect.bottom;
    final double spaceAbove = triggerRect.top - viewportPadding.top;
    final double requiredY = popoverSize.height + effectiveGap;

    if (autoFlip) {
      if (preferredIsTop) {
        if (spaceAbove < requiredY &&
            (spaceBelow >= requiredY || spaceBelow > spaceAbove)) {
          isTop = false;
          isFlipped = true;
        }
      } else {
        if (spaceBelow < requiredY &&
            (spaceAbove >= requiredY || spaceAbove > spaceBelow)) {
          isTop = true;
          isFlipped = true;
        }
      }
    }

    final double targetY;
    if (isTop) {
      targetY = triggerRect.top - effectiveGap - popoverSize.height;
    } else {
      targetY = triggerRect.bottom + effectiveGap;
    }

    final double resolvedY = targetY.clamp(minY, maxY);

    // 2. Determine Horizontal Placement (respecting textDirection for start/end)
    final bool isStart =
        preferredPlacement == OrionPopoverPlacement.topStart ||
        preferredPlacement == OrionPopoverPlacement.bottomStart;
    final bool isCenter =
        preferredPlacement == OrionPopoverPlacement.topCenter ||
        preferredPlacement == OrionPopoverPlacement.bottomCenter;
    final bool isEnd =
        preferredPlacement == OrionPopoverPlacement.topEnd ||
        preferredPlacement == OrionPopoverPlacement.bottomEnd;

    final bool rtl = textDirection == TextDirection.rtl;
    final double targetX;
    if (isStart) {
      targetX = rtl ? triggerRect.right - popoverSize.width : triggerRect.left;
    } else if (isEnd) {
      targetX = rtl ? triggerRect.left : triggerRect.right - popoverSize.width;
    } else if (isCenter) {
      targetX = triggerRect.center.dx - (popoverSize.width / 2.0);
    } else {
      targetX = triggerRect.left;
    }

    final double resolvedX = targetX.clamp(minX, maxX);

    // 3. Compute Dynamic Transform Origin
    // The normalized point on the popover box corresponding to the trigger's center.
    final double triggerMidX = triggerRect.center.dx;
    final double normalizedOriginX = popoverSize.width > 0
        ? ((triggerMidX - resolvedX) / popoverSize.width).clamp(0.0, 1.0)
        : 0.5;

    // In Flutter Alignment, -1.0 is left/top, 0.0 is center, +1.0 is right/bottom.
    final double alignX = (normalizedOriginX * 2.0) - 1.0;
    final double alignY = isTop ? 1.0 : -1.0;

    // 4. Compute Arrow Offset
    Offset? arrowOffset;
    if (showArrow) {
      final double inset = math.min(
        14.0,
        math.max(0.0, (popoverSize.width - arrowSize.width) / 2.0),
      );
      final double arrowX = (triggerMidX - resolvedX - (arrowSize.width / 2.0))
          .clamp(
            inset,
            math.max(inset, popoverSize.width - inset - arrowSize.width),
          );
      final double arrowY = isTop ? popoverSize.height : -arrowSize.height;
      arrowOffset = Offset(arrowX, arrowY);
    }

    // 5. Effective Placement
    final OrionPopoverPlacement effectivePlacement;
    if (isTop) {
      if (isStart) {
        effectivePlacement = OrionPopoverPlacement.topStart;
      } else if (isEnd) {
        effectivePlacement = OrionPopoverPlacement.topEnd;
      } else {
        effectivePlacement = OrionPopoverPlacement.topCenter;
      }
    } else {
      if (isStart) {
        effectivePlacement = OrionPopoverPlacement.bottomStart;
      } else if (isEnd) {
        effectivePlacement = OrionPopoverPlacement.bottomEnd;
      } else {
        effectivePlacement = OrionPopoverPlacement.bottomCenter;
      }
    }

    return OrionPopoverResolvedLayout(
      offset: Offset(resolvedX, resolvedY),
      transformOrigin: Alignment(alignX, alignY),
      isFlipped: isFlipped,
      placement: effectivePlacement,
      arrowOffset: arrowOffset,
    );
  }
}
