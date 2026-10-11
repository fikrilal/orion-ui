import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  group('OrionPopoverGeometry', () {
    const viewportSize = Size(400.0, 800.0);
    const popoverSize = Size(180.0, 120.0);
    const padding = EdgeInsets.all(12.0);

    test('positions popover below trigger when space permits', () {
      const triggerRect = Rect.fromLTWH(50.0, 100.0, 100.0, 40.0);

      final layout = OrionPopoverGeometry.resolve(
        triggerRect: triggerRect,
        popoverSize: popoverSize,
        viewportSize: viewportSize,
        viewportPadding: padding,
        preferredPlacement: OrionPopoverPlacement.bottomStart,
        gap: 8.0,
      );

      expect(layout.isFlipped, isFalse);
      expect(layout.placement, OrionPopoverPlacement.bottomStart);
      expect(layout.offset.dx, 50.0);
      expect(layout.offset.dy, 148.0); // 100 + 40 + 8
      // Origin should be near top-center of trigger relative to popover
      expect(layout.transformOrigin.y, -1.0); // Top of popover
    });

    test('auto-flips to top when trigger is near the bottom of viewport', () {
      const triggerRect = Rect.fromLTWH(50.0, 720.0, 100.0, 40.0);

      final layout = OrionPopoverGeometry.resolve(
        triggerRect: triggerRect,
        popoverSize: popoverSize,
        viewportSize: viewportSize,
        viewportPadding: padding,
        preferredPlacement: OrionPopoverPlacement.bottomStart,
        gap: 8.0,
        autoFlip: true,
      );

      expect(layout.isFlipped, isTrue);
      expect(layout.placement, OrionPopoverPlacement.topStart);
      expect(layout.offset.dx, 50.0);
      expect(layout.offset.dy, 720.0 - 8.0 - 120.0); // 592.0
      expect(layout.transformOrigin.y, 1.0); // Bottom of popover
    });

    test(
      'clamps horizontal position when trigger is at the extreme screen edge',
      () {
        const triggerRect = Rect.fromLTWH(350.0, 100.0, 40.0, 40.0);

        final layout = OrionPopoverGeometry.resolve(
          triggerRect: triggerRect,
          popoverSize: popoverSize,
          viewportSize: viewportSize,
          viewportPadding: padding,
          preferredPlacement: OrionPopoverPlacement.bottomStart,
          gap: 8.0,
        );

        // Max allowable X is 400 - 12 - 180 = 208.0
        expect(layout.offset.dx, 208.0);
      },
    );

    test('computes arrow offset along the edge', () {
      const triggerRect = Rect.fromLTWH(50.0, 100.0, 80.0, 40.0);

      final layout = OrionPopoverGeometry.resolve(
        triggerRect: triggerRect,
        popoverSize: popoverSize,
        viewportSize: viewportSize,
        viewportPadding: padding,
        preferredPlacement: OrionPopoverPlacement.bottomStart,
        gap: 8.0,
        showArrow: true,
        arrowSize: const Size(14.0, 7.0),
      );

      expect(layout.arrowOffset, isNotNull);
      // Trigger center X is 90. Popover X is 50. Arrow center X is 90 - 50 - 7 = 33.0
      expect(layout.arrowOffset!.dx, 33.0);
      expect(layout.arrowOffset!.dy, -7.0); // Sits right above top edge
    });

    test(
      'auto-flips to top when neither side fits completely but spaceAbove > spaceBelow',
      () {
        // spaceBelow is 100 pt, spaceAbove is 280 pt, popover height is 300 pt
        const triggerRect = Rect.fromLTWH(50.0, 300.0, 80.0, 40.0);
        const constrainedViewport = Size(400.0, 440.0);
        const largePopover = Size(180.0, 300.0);

        final layout = OrionPopoverGeometry.resolve(
          triggerRect: triggerRect,
          popoverSize: largePopover,
          viewportSize: constrainedViewport,
          viewportPadding: padding,
          preferredPlacement: OrionPopoverPlacement.bottomStart,
          gap: 8.0,
          autoFlip: true,
        );

        expect(layout.isFlipped, isTrue);
        expect(layout.placement, OrionPopoverPlacement.topStart);
        expect(layout.transformOrigin.y, 1.0); // Origin at bottom edge
      },
    );
  });
}
