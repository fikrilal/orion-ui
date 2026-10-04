import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OrionSpringDriver', () {
    test('initializes with default resting value', () {
      final vsync = const TestVSync();
      final driver = OrionSpringDriver(vsync: vsync, initialValue: 1.0);

      expect(driver.value, 1.0);
      expect(driver.target, 1.0);
      expect(driver.isAnimating, isFalse);
      driver.dispose();
    });

    test('jumpTo stops animation and sets value immediately', () {
      final vsync = const TestVSync();
      final driver = OrionSpringDriver(vsync: vsync, initialValue: 1.0);

      driver.jumpTo(0.96);
      expect(driver.value, 0.96);
      expect(driver.target, 0.96);
      expect(driver.isAnimating, isFalse);
      driver.dispose();
    });

    testWidgets(
      'mid-flight retarget preserves position and velocity without snapping',
      (tester) async {
        final driver = OrionSpringDriver(
          vsync: const TestVSync(),
          initialValue: 1.0,
        );
        addTearDown(driver.dispose);

        driver.retarget(0.96);
        await tester.pump();
        for (var i = 0; i < 5; i++) {
          await tester.pump(const Duration(milliseconds: 16));
        }

        final before = driver.value;
        final vBefore = driver.velocity;
        expect(before, lessThan(1.0));
        expect(vBefore, lessThan(0.0));

        // Mid-flight retarget toward 1.0
        driver.retarget(1.0);
        // Value at the exact instant of retarget matches position before (zero jump)
        expect(driver.value, closeTo(before, 1e-12));
        expect(driver.velocity, closeTo(vBefore, 1e-9));

        var previous = driver.value;
        var frames = 0;
        while (driver.isAnimating && frames < 300) {
          await tester.pump(const Duration(milliseconds: 16));
          expect((driver.value - previous).abs(), lessThan(0.05));
          previous = driver.value;
          frames++;
        }
        expect(driver.value, 1.0);
      },
    );

    test('updating springSpec retargets running animation', () {
      final vsync = const TestVSync();
      final driver = OrionSpringDriver(vsync: vsync, initialValue: 1.0);

      driver.retarget(0.96);
      driver.springSpec = OrionSpringSpec.gentle;

      expect(driver.springSpec, OrionSpringSpec.gentle);
      expect(driver.target, 0.96);
      driver.dispose();
    });
  });
}
