import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionTooltipGeometry', () {
    const Size viewportSize = Size(800.0, 600.0);
    const EdgeInsets viewportPadding = EdgeInsets.all(8.0);
    const Size tooltipSize = Size(100.0, 30.0);
    const Size arrowSize = Size(10.0, 5.0);

    test('resolves preferred top placement when space is available', () {
      const Rect triggerRect = Rect.fromLTWH(350.0, 250.0, 100.0, 40.0);

      final layout = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: OrionTooltipPlacement.top,
        gap: 6.0,
        showArrow: true,
        arrowSize: arrowSize,
      );

      expect(layout.placement, OrionTooltipPlacement.top);
      expect(layout.isFlipped, isFalse);
      // y = triggerRect.top - effectiveGap - tooltipHeight
      // effectiveGap = 6.0 + 5.0 = 11.0
      expect(layout.offset.dy, 250.0 - 11.0 - 30.0);
      expect(layout.transformOrigin, Alignment.bottomCenter);
      expect(layout.arrowOffset, isNotNull);
    });

    test('resolves preferred bottom placement when space is available', () {
      const Rect triggerRect = Rect.fromLTWH(350.0, 200.0, 100.0, 40.0);

      final layout = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: OrionTooltipPlacement.bottom,
        gap: 6.0,
        showArrow: true,
        arrowSize: arrowSize,
      );

      expect(layout.placement, OrionTooltipPlacement.bottom);
      expect(layout.isFlipped, isFalse);
      // y = triggerRect.bottom + effectiveGap
      expect(layout.offset.dy, 240.0 + 11.0);
      expect(layout.transformOrigin, Alignment.topCenter);
    });

    test('auto-flips top to bottom when colliding with viewport top', () {
      // Trigger at y = 5 (collides with top)
      const Rect triggerRect = Rect.fromLTWH(350.0, 5.0, 100.0, 40.0);

      final layout = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: OrionTooltipPlacement.top,
        gap: 6.0,
        showArrow: true,
        arrowSize: arrowSize,
      );

      expect(layout.placement, OrionTooltipPlacement.bottom);
      expect(layout.isFlipped, isTrue);
      expect(layout.offset.dy, 45.0 + 11.0);
      expect(layout.transformOrigin, Alignment.topCenter);
    });

    test(
      'computes spatial transformOrigin relative to trigger center when clamped',
      () {
        // Trigger near the left edge at x = 10 (width 40, center 30)
        const Rect triggerRect = Rect.fromLTWH(10.0, 200.0, 40.0, 30.0);

        final layout = OrionTooltipGeometry.resolve(
          triggerRect: triggerRect,
          tooltipSize: const Size(120.0, 40.0),
          viewportSize: viewportSize,
          viewportPadding: viewportPadding,
          preferredPlacement: OrionTooltipPlacement.top,
          gap: 6.0,
          showArrow: false,
        );

        // Clamped to minX = 8.0
        expect(layout.offset.dx, 8.0);
        // Trigger center is 30.0. In local tooltip coordinates: 30.0 - 8.0 = 22.0
        // normX = 22.0 / 120.0 ≈ 0.1833
        // alignment X = (0.1833 * 2.0) - 1.0 ≈ -0.6333
        expect(layout.transformOrigin.x, closeTo(-0.633, 0.01));
        expect(layout.transformOrigin.y, 1.0); // bottom
      },
    );

    test('auto-flips bottom to top when colliding with viewport bottom', () {
      // Trigger near bottom
      const Rect triggerRect = Rect.fromLTWH(350.0, 560.0, 100.0, 40.0);

      final layout = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: OrionTooltipPlacement.bottom,
        gap: 6.0,
        showArrow: true,
        arrowSize: arrowSize,
      );

      expect(layout.placement, OrionTooltipPlacement.top);
      expect(layout.isFlipped, isTrue);
      expect(layout.transformOrigin, Alignment.bottomCenter);
    });

    test('auto-flips left to right when colliding with viewport left', () {
      // Trigger near left
      const Rect triggerRect = Rect.fromLTWH(2.0, 250.0, 50.0, 40.0);

      final layout = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: OrionTooltipPlacement.left,
        gap: 6.0,
        showArrow: true,
        arrowSize: arrowSize,
      );

      expect(layout.placement, OrionTooltipPlacement.right);
      expect(layout.isFlipped, isTrue);
      expect(layout.transformOrigin, Alignment.centerLeft);
    });

    test('auto-flips right to left when colliding with viewport right', () {
      // Trigger near right
      const Rect triggerRect = Rect.fromLTWH(760.0, 250.0, 35.0, 40.0);

      final layout = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: OrionTooltipPlacement.right,
        gap: 6.0,
        showArrow: true,
        arrowSize: arrowSize,
      );

      expect(layout.placement, OrionTooltipPlacement.left);
      expect(layout.isFlipped, isTrue);
      expect(layout.transformOrigin, Alignment.centerRight);
    });

    test('clamps tooltip coordinates within safe viewport boundaries', () {
      // Trigger right at extreme bottom right
      const Rect triggerRect = Rect.fromLTWH(790.0, 590.0, 10.0, 10.0);

      final layout = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        viewportPadding: viewportPadding,
        preferredPlacement: OrionTooltipPlacement.top,
        gap: 6.0,
        showArrow: false,
      );

      expect(
        layout.offset.dx,
        lessThanOrEqualTo(
          viewportSize.width - viewportPadding.right - tooltipSize.width,
        ),
      );
      expect(
        layout.offset.dy,
        lessThanOrEqualTo(
          viewportSize.height - viewportPadding.bottom - tooltipSize.height,
        ),
      );
    });

    test('resolves RTL-aware start and end placements', () {
      const Rect triggerRect = Rect.fromLTWH(350.0, 250.0, 100.0, 40.0);

      final ltrStart = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        preferredPlacement: OrionTooltipPlacement.start,
        textDirection: TextDirection.ltr,
      );
      final rtlStart = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        preferredPlacement: OrionTooltipPlacement.start,
        textDirection: TextDirection.rtl,
      );
      final rtlEnd = OrionTooltipGeometry.resolve(
        triggerRect: triggerRect,
        tooltipSize: tooltipSize,
        viewportSize: viewportSize,
        preferredPlacement: OrionTooltipPlacement.end,
        textDirection: TextDirection.rtl,
      );

      expect(ltrStart.placement, OrionTooltipPlacement.left);
      expect(rtlStart.placement, OrionTooltipPlacement.right);
      expect(rtlEnd.placement, OrionTooltipPlacement.left);
    });

    test(
      'falls back across axes to top/bottom on narrow mobile screens when neither horizontal side fits',
      () {
        const Size mobileViewport = Size(360.0, 780.0);
        // Wide centered button leaving only ~72px on each side
        const Rect wideTrigger = Rect.fromLTWH(80.0, 340.0, 200.0, 44.0);
        const Size wideTooltip = Size(220.0, 36.0);

        final fromLeft = OrionTooltipGeometry.resolve(
          triggerRect: wideTrigger,
          tooltipSize: wideTooltip,
          viewportSize: mobileViewport,
          preferredPlacement: OrionTooltipPlacement.left,
        );
        expect(fromLeft.placement, OrionTooltipPlacement.top);
        expect(fromLeft.isFlipped, isTrue);
        // Must sit cleanly above the trigger without overlapping it
        expect(
          fromLeft.offset.dy + wideTooltip.height,
          lessThan(wideTrigger.top),
        );

        // Near top edge where top also cannot fit -> falls back to bottom
        const Rect topTrigger = Rect.fromLTWH(80.0, 12.0, 200.0, 44.0);
        final fromRightNearTop = OrionTooltipGeometry.resolve(
          triggerRect: topTrigger,
          tooltipSize: wideTooltip,
          viewportSize: mobileViewport,
          preferredPlacement: OrionTooltipPlacement.right,
        );
        expect(fromRightNearTop.placement, OrionTooltipPlacement.bottom);
        expect(fromRightNearTop.isFlipped, isTrue);
        expect(fromRightNearTop.offset.dy, greaterThan(topTrigger.bottom));
      },
    );

    test(
      'clamps arrow offset inside corner-radius inset and stays safe on narrow tooltips',
      () {
        // Trigger pinned to extreme left edge
        const Rect edgeTrigger = Rect.fromLTWH(2.0, 250.0, 12.0, 32.0);
        final layout = OrionTooltipGeometry.resolve(
          triggerRect: edgeTrigger,
          tooltipSize: const Size(160.0, 36.0),
          viewportSize: viewportSize,
          preferredPlacement: OrionTooltipPlacement.top,
          showArrow: true,
          arrowSize: const Size(10.0, 5.0),
          arrowEdgeInset: 12.0,
        );
        expect(layout.arrowOffset!.dx, greaterThanOrEqualTo(12.0));

        // Very short tooltip in left placement where height < 2*inset + arrowWidth
        const Rect centerTrigger = Rect.fromLTWH(400.0, 250.0, 40.0, 40.0);
        final shortLayout = OrionTooltipGeometry.resolve(
          triggerRect: centerTrigger,
          tooltipSize: const Size(100.0, 22.0),
          viewportSize: viewportSize,
          preferredPlacement: OrionTooltipPlacement.left,
          showArrow: true,
          arrowSize: const Size(10.0, 5.0),
          arrowEdgeInset: 12.0,
        );
        // Safely centers arrow at (22 - 10) / 2 = 6.0 without RangeError
        expect(shortLayout.arrowOffset!.dy, closeTo(6.0, 0.01));
      },
    );

    test(
      'flips bottom to top when viewportPadding includes keyboard inset',
      () {
        const Rect triggerRect = Rect.fromLTWH(140.0, 440.0, 100.0, 44.0);
        final layout = OrionTooltipGeometry.resolve(
          triggerRect: triggerRect,
          tooltipSize: tooltipSize,
          viewportSize: const Size(400.0, 800.0),
          viewportPadding: const EdgeInsets.fromLTRB(8.0, 52.0, 8.0, 320.0),
          preferredPlacement: OrionTooltipPlacement.bottom,
        );

        expect(layout.placement, OrionTooltipPlacement.top);
        expect(layout.isFlipped, isTrue);
      },
    );

    test('OrionTooltipResolvedLayout value equality and hashCode', () {
      const a = OrionTooltipResolvedLayout(
        offset: Offset(10, 20),
        transformOrigin: Alignment.bottomCenter,
        isFlipped: false,
        placement: OrionTooltipPlacement.top,
        arrowOffset: Offset(45, 30),
      );
      const b = OrionTooltipResolvedLayout(
        offset: Offset(10, 20),
        transformOrigin: Alignment.bottomCenter,
        isFlipped: false,
        placement: OrionTooltipPlacement.top,
        arrowOffset: Offset(45, 30),
      );
      const c = OrionTooltipResolvedLayout(
        offset: Offset(10, 20),
        transformOrigin: Alignment.topCenter,
        isFlipped: true,
        placement: OrionTooltipPlacement.bottom,
        arrowOffset: Offset(45, -5),
      );

      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));
      expect(a, isNot(equals(c)));
    });
  });
}
