import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

OrionSpringDriver _driver({
  OrionSpringSpec spec = OrionSpringSpec.gentle,
  double initial = 0,
}) {
  return OrionSpringDriver(
    vsync: const TestVSync(),
    springSpec: spec,
    initialValue: initial,
  );
}

void main() {
  group('motion core', () {
    testWidgets('a release carries the velocity of the gesture', (
      tester,
    ) async {
      final OrionSpringDriver driver = _driver();
      addTearDown(driver.dispose);

      driver.retarget(1, velocity: 40);
      await tester.pump();

      // The simulation starts with the finger's velocity, not from rest.
      expect(driver.velocity, closeTo(40, 1));
      await tester.pumpAndSettle();
      expect(driver.value, closeTo(1, 0.001));
    });

    testWidgets('retargeting in flight does not restart the simulation', (
      tester,
    ) async {
      final OrionSpringDriver driver = _driver();
      addTearDown(driver.dispose);
      final List<AnimationStatus> statuses = <AnimationStatus>[];
      driver.addStatusListener(statuses.add);

      driver.retarget(1);
      await tester.pump(); // the ticker's first tick lands at t = 0
      double previous = driver.value;
      for (int frame = 0; frame < 5; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        // The clock keeps running. Restarting it per retarget stalls the value here.
        expect(driver.value, greaterThan(previous));
        previous = driver.value;
        driver.retarget(1);
        expect(driver.isAnimating, isTrue);
      }
      await tester.pumpAndSettle();

      expect(
        statuses.where((AnimationStatus s) => s == AnimationStatus.forward),
        hasLength(1),
        reason: 'the status is announced once and only on a real change',
      );
      expect(statuses.last, AnimationStatus.completed);
    });

    testWidgets('reduced motion lands in the same frame', (tester) async {
      final OrionSpringDriver driver = _driver();
      addTearDown(driver.dispose);

      driver.reducedMotion = true;
      driver.retarget(1);
      expect(driver.value, 1);
      expect(driver.isAnimating, isFalse);

      // Turned on mid-flight, it settles where it was going rather than at the origin.
      driver.reducedMotion = false;
      driver.retarget(0);
      await tester.pump(const Duration(milliseconds: 16));
      expect(driver.isAnimating, isTrue);
      driver.reducedMotion = true;
      expect(driver.value, 0);
      expect(driver.isAnimating, isFalse);
    });

    testWidgets('a clamped spec never passes its target', (tester) async {
      final OrionSpringDriver driver = _driver(
        spec: const OrionSpringSpec(
          stiffness: 380,
          dampingRatio: 0.36,
          clampOvershoot: true,
        ),
      );
      addTearDown(driver.dispose);

      double peak = 0;
      driver.addListener(() {
        if (driver.value > peak) {
          peak = driver.value;
        }
      });
      driver.retarget(1, velocity: 6);
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 16));
      // The clamp limits the endpoint; it does not skip the travel.
      expect(driver.value, lessThan(0.99));

      for (int frame = 0; frame < 90; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(peak, lessThanOrEqualTo(1.0));
      expect(driver.value, closeTo(1, 0.01));
    });

    testWidgets('a clamped spec holds a downward travel', (tester) async {
      final OrionSpringDriver driver = _driver(
        spec: const OrionSpringSpec(
          stiffness: 380,
          dampingRatio: 0.36,
          clampOvershoot: true,
        ),
        initial: 1,
      );
      addTearDown(driver.dispose);

      double trough = 1;
      driver.addListener(() {
        if (driver.value < trough) {
          trough = driver.value;
        }
      });
      driver.retarget(0, velocity: -6);
      for (int frame = 0; frame < 90; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
      }

      expect(trough, greaterThanOrEqualTo(0.0));
      expect(driver.value, closeTo(0, 0.01));
    });

    testWidgets('stop lands the status without announcing it', (tester) async {
      final OrionSpringDriver driver = _driver();
      addTearDown(driver.dispose);
      final List<AnimationStatus> statuses = <AnimationStatus>[];
      driver.addStatusListener(statuses.add);

      driver.retarget(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      expect(statuses, <AnimationStatus>[AnimationStatus.forward]);

      driver.stop();
      expect(driver.status, AnimationStatus.completed);
      expect(driver.isAnimating, isFalse);
      expect(statuses, <AnimationStatus>[
        AnimationStatus.forward,
      ], reason: 'an interruption is not an arrival, so nothing is announced');
    });

    testWidgets('a retarget after a mid-flight jump announces nothing new', (
      tester,
    ) async {
      final OrionSpringDriver driver = _driver();
      addTearDown(driver.dispose);
      final List<AnimationStatus> statuses = <AnimationStatus>[];
      driver.addStatusListener(statuses.add);

      driver.retarget(1);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      // A drag repositions without arriving, then another drag retargets: the status is
      // already forward, so the dedupe stays quiet instead of re-announcing.
      driver.jumpTo(0.5);
      driver.retarget(0);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));

      expect(statuses, <AnimationStatus>[AnimationStatus.forward]);
      driver.stop();
    });

    testWidgets('a per-frame retarget tracks a moving target', (tester) async {
      final OrionSpringDriver driver = _driver();
      addTearDown(driver.dispose);

      for (int frame = 1; frame <= 30; frame++) {
        driver.retarget(frame * 0.1);
        await tester.pump(const Duration(milliseconds: 16));
      }

      // Followed, not fought: the value closes on a target that ran to 3.0, lagging it
      // by the spring's steady-state error rather than falling behind or running away.
      expect(driver.value, greaterThan(2.0));
      expect(driver.value, lessThan(4.0));

      // A test that leaves a ticker scheduled fails the binding's own check, so land it.
      driver.stop();
    });
  });
}
