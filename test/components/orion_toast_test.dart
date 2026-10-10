import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpToaster(
  WidgetTester tester, {
  OrionToastPosition position = OrionToastPosition.bottomCenter,
  int maxVisible = 3,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: OrionToaster(position: position, maxVisible: maxVisible),
      ),
    ),
  );
}

/// Shows a toast and lets its entrance land.
Future<void> _show(
  WidgetTester tester,
  String title, {
  String? description,
  Duration? duration,
  OrionToastStatus status = OrionToastStatus.neutral,
}) async {
  OrionToast.show(
    title,
    description: description,
    duration: duration,
    status: status,
  );
  await tester.pump();
  await tester.pumpAndSettle();
}

Finder get _cards => find.byType(OrionToastCard);

/// The card's contents, which sit inside the swipe transform.
///
/// A drag moves the card's child, not the card's own box, so anything asserting
/// on swipe travel has to measure inside the card.
Finder _face([Finder? of]) =>
    find.descendant(of: of ?? _cards, matching: find.byType(ClipRRect)).first;

double _opacityOf(WidgetTester tester, int index) {
  final Finder opacity = find
      .ancestor(of: _cards.at(index), matching: find.byType(Opacity))
      .first;
  return tester.widget<Opacity>(opacity).opacity;
}

void main() {
  setUp(() {
    OrionToast.clear();
  });

  tearDown(() {
    OrionToast.clear();
  });

  group('OrionToastController & Facade', () {
    test('show adds a toast and clear removes all', () {
      final controller = OrionToastController.instance;
      expect(controller.toasts, isEmpty);

      final id = OrionToast.show(
        'File uploaded',
        description: 'Saved to cloud',
      );
      expect(id, isNotEmpty);
      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.first.title, 'File uploaded');
      expect(controller.toasts.first.description, 'Saved to cloud');

      OrionToast.clear();
      expect(controller.toasts, isEmpty);
    });

    test('updating existing toast id updates in place without duplicating', () {
      final controller = OrionToastController.instance;
      final id = OrionToast.loading('Syncing...');
      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.first.status, OrionToastStatus.loading);

      OrionToast.success('Sync complete', id: id);
      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.first.id, id);
      expect(controller.toasts.first.title, 'Sync complete');
      expect(controller.toasts.first.status, OrionToastStatus.success);
    });

    test('an in-place update drops content the new payload omits', () {
      final controller = OrionToastController.instance;
      final id = OrionToast.loading('Uploading', description: '3 files');
      expect(controller.toasts.first.description, '3 files');

      OrionToast.success('Uploaded', id: id);

      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.first.description, isNull);
      expect(controller.toasts.first.action, isNull);
    });

    test('a toast differs when only its action or icon differs', () {
      const OrionToastData base = OrionToastData(id: 'toast-1', title: 'Saved');
      final OrionToastData withAction = base.copyWith(
        action: OrionToastAction(label: 'Undo', onPressed: _noop),
      );
      final OrionToastData withIcon = base.copyWith(
        icon: const Icon(Icons.star),
      );

      expect(withAction, isNot(base));
      expect(withIcon, isNot(base));
      expect(base.copyWith(), base);
    });

    test(
      'a toast arriving while the stack is held still goes when released',
      () async {
        final controller = OrionToastController.instance;
        controller.pauseTimers();
        controller.show(
          const OrionToastData(
            id: '',
            title: 'Arrived',
            duration: Duration(milliseconds: 40),
          ),
        );
        await Future<void>.delayed(const Duration(milliseconds: 90));

        expect(controller.toasts, hasLength(1));
        controller.resumeTimers();

        // Its budget was spent while it was held: the hold cannot make it stay.
        expect(controller.toasts, isEmpty);
      },
    );

    test('typed helper facades set corresponding semantic status', () {
      final controller = OrionToastController.instance;

      final successId = OrionToast.success('Saved');
      expect(controller.toasts.last.status, OrionToastStatus.success);

      OrionToast.error('Failed');
      expect(controller.toasts.last.status, OrionToastStatus.error);

      OrionToast.info('Update available');
      expect(controller.toasts.last.status, OrionToastStatus.info);

      OrionToast.warning('Battery low');
      expect(controller.toasts.last.status, OrionToastStatus.warning);

      expect(controller.toasts, hasLength(4));
      OrionToast.dismiss(successId);
      expect(
        controller.toasts.any((OrionToastData t) => t.id == successId),
        isFalse,
      );
    });

    test('promise resolves loading toast to success upon completion', () async {
      final controller = OrionToastController.instance;

      final Future<String> task = Future<String>.delayed(
        const Duration(milliseconds: 100),
        () => 'file_data',
      );

      final taskFuture = OrionToast.promise(
        task,
        loading: 'Processing...',
        success: (String result) => 'Done: $result',
        error: (Object err) => 'Failed: $err',
      );

      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.first.status, OrionToastStatus.loading);
      expect(controller.toasts.first.title, 'Processing...');

      final String result = await taskFuture;
      expect(result, 'file_data');
      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.first.status, OrionToastStatus.success);
      expect(controller.toasts.first.title, 'Done: file_data');
    });

    test('promise resolves loading toast to error upon rejection', () async {
      final controller = OrionToastController.instance;

      final Future<String> failingTask = Future<String>.delayed(
        const Duration(milliseconds: 50),
        () => throw Exception('Network timeout'),
      );

      final taskFuture = OrionToast.promise(
        failingTask,
        loading: 'Connecting...',
        success: (String result) => 'Success',
        error: (Object err) => 'Connection failed',
      );

      expect(controller.toasts, hasLength(1));
      expect(controller.toasts.first.status, OrionToastStatus.loading);

      try {
        await taskFuture;
        fail('Should have thrown');
      } catch (e) {
        expect(controller.toasts, hasLength(1));
        expect(controller.toasts.first.status, OrionToastStatus.error);
        expect(controller.toasts.first.title, 'Connection failed');
      }
    });
  });

  group('Stack depth', () {
    testWidgets('each tier attenuates scale, opacity and offset', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'Toast 1', duration: null);
      await _show(tester, 'Toast 2', duration: null);
      await _show(tester, 'Toast 3', duration: null);

      // Tree order is back to front: index 0 is the newest card's neighbour.
      final Rect back = tester.getRect(_cards.at(0));
      final Rect middle = tester.getRect(_cards.at(1));
      final Rect front = tester.getRect(_cards.at(2));

      expect(back.height / front.height, moreOrLessEquals(0.86, epsilon: 0.01));
      expect(
        middle.height / front.height,
        moreOrLessEquals(0.93, epsilon: 0.01),
      );
      expect(front.height / front.height, 1.0);

      expect(_opacityOf(tester, 0), moreOrLessEquals(0.75, epsilon: 0.01));
      expect(_opacityOf(tester, 1), moreOrLessEquals(0.90, epsilon: 0.01));
      expect(_opacityOf(tester, 2), 1.0);

      // Anchored at the bottom, cards behind the front one peek above it.
      expect(
        front.bottom - middle.bottom,
        moreOrLessEquals(14.0, epsilon: 0.5),
      );
      expect(front.bottom - back.bottom, moreOrLessEquals(28.0, epsilon: 0.5));
      expect(back.bottom, lessThan(middle.bottom));
      expect(middle.bottom, lessThan(front.bottom));
    });

    testWidgets('a card enters with motion instead of at rest', (tester) async {
      await _pumpToaster(tester);
      OrionToast.show('Entrance', duration: null);
      await tester.pump();

      final Rect entering = tester.getRect(_cards);
      expect(_opacityOf(tester, 0), 0.0);

      await tester.pumpAndSettle();
      final Rect atRest = tester.getRect(_cards);

      // Anchored at the bottom, the card travels the last stretch into place.
      expect(entering.top - atRest.top, moreOrLessEquals(16.0, epsilon: 0.5));
      expect(_opacityOf(tester, 0), 1.0);
    });

    testWidgets('a top anchored card enters from above', (tester) async {
      await _pumpToaster(tester, position: OrionToastPosition.topCenter);
      OrionToast.show('Entrance', duration: null);
      await tester.pump();

      final Rect entering = tester.getRect(_cards);

      await tester.pumpAndSettle();
      expect(
        entering.top - tester.getRect(_cards).top,
        moreOrLessEquals(-16.0, epsilon: 0.5),
      );
    });

    testWidgets('a toast arriving while held still lands on its stack slot', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'First', duration: null);

      final TestGesture hold = await tester.startGesture(
        tester.getCenter(find.text('First')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      OrionToast.show('Second', duration: null);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 900));

      final Rect back = tester.getRect(_cards.at(0));
      final Rect front = tester.getRect(_cards.at(1));
      // Expanded: the two cards sit clear of each other.
      expect(back.bottom, lessThanOrEqualTo(front.top));

      await hold.up();
      await tester.pumpAndSettle();
    });

    testWidgets('maxVisible caps the stack and keeps the newest', (
      tester,
    ) async {
      await _pumpToaster(tester, maxVisible: 2);
      await _show(tester, 'Oldest', duration: null);
      await _show(tester, 'Middle', duration: null);
      await _show(tester, 'Newest', duration: null);

      expect(_cards, findsNWidgets(2));
      expect(find.text('Oldest'), findsNothing);
      expect(find.text('Middle'), findsOneWidget);
      expect(find.text('Newest'), findsOneWidget);
    });

    testWidgets('animation frames move the transform without rebuilding', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'First', duration: null);

      final Finder first = find.ancestor(
        of: find.text('First'),
        matching: _cards,
      );

      OrionToast.show('Second', duration: null);
      // The arrival measures the new card; once that has landed the stack only
      // animates, and no frame of that animation rebuilds a card.
      await tester.pump();
      await tester.pump();

      final OrionToastCard before = tester.widget<OrionToastCard>(first);
      final Rect beforeRect = tester.getRect(first);

      for (int i = 0; i < 6; i++) {
        await tester.pump(const Duration(milliseconds: 16));
        expect(identical(tester.widget<OrionToastCard>(first), before), isTrue);
      }
      expect(tester.getRect(first), isNot(beforeRect));
    });
  });

  group('Swipe to dismiss', () {
    testWidgets(
      'a release past the distance threshold glides off before the item leaves',
      (tester) async {
        await _pumpToaster(tester);
        await _show(tester, 'Swipe me away', duration: null);

        final TestGesture gesture = await tester.startGesture(
          tester.getCenter(find.text('Swipe me away')),
        );
        await gesture.moveBy(const Offset(150, 0));
        await tester.pump();
        final Rect atRelease = tester.getRect(_face());

        await gesture.up();
        await tester.pump(const Duration(milliseconds: 16));
        final Rect tickZero = tester.getRect(_face());
        await tester.pump(const Duration(milliseconds: 16));
        final Rect firstMove = tester.getRect(_face());
        await tester.pump(const Duration(milliseconds: 16));
        final Rect secondMove = tester.getRect(_face());

        // Still on screen and still travelling: the exit is animated, not a cut.
        // It also leaves from where the finger let go, with no jump.
        expect(find.text('Swipe me away'), findsOneWidget);
        expect(tickZero.left, moreOrLessEquals(atRelease.left, epsilon: 0.5));
        expect(firstMove.left, greaterThan(tickZero.left));
        expect(secondMove.left, greaterThan(firstMove.left));

        await tester.pumpAndSettle();
        expect(find.text('Swipe me away'), findsNothing);
        expect(OrionToastController.instance.toasts, isEmpty);
      },
    );

    testWidgets('a flick dismisses without a long drag', (tester) async {
      await _pumpToaster(tester);
      await _show(tester, 'Flick me', duration: null);

      // A flick throws the card away on speed alone: it travels 40 pt, well
      // under the 72 pt distance threshold.
      await tester.fling(find.text('Flick me'), const Offset(40, 0), 1500);
      await tester.pumpAndSettle();

      expect(find.text('Flick me'), findsNothing);
      expect(OrionToastController.instance.toasts, isEmpty);
    });

    testWidgets('a short drag returns the card exactly home and keeps it', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'Keep me', duration: null);
      final double restX = tester.getRect(_face()).left;

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Keep me')),
      );
      for (int i = 0; i < 12; i++) {
        await gesture.moveBy(const Offset(5, 0));
        await tester.pump(const Duration(milliseconds: 24));
      }
      expect(
        tester.getRect(_face()).left - restX,
        moreOrLessEquals(60, epsilon: 1),
      );
      await gesture.up();
      await tester.pumpAndSettle();

      expect(find.text('Keep me'), findsOneWidget);
      expect(
        tester.getRect(_face()).left - restX,
        moreOrLessEquals(0.0, epsilon: 0.01),
      );
    });

    testWidgets(
      'catching a moving card continues it instead of snapping home',
      (tester) async {
        await _pumpToaster(tester);
        await _show(tester, 'Catch me', duration: null);
        final double restX = tester.getRect(_face()).left;

        final TestGesture drag = await tester.startGesture(
          tester.getCenter(find.text('Catch me')),
        );
        for (int i = 0; i < 12; i++) {
          await drag.moveBy(const Offset(5, 0));
          await tester.pump(const Duration(milliseconds: 24));
        }
        await drag.up();

        // Mid-flight: caught while the spring is still bringing it home.
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 80));
        final double carried = tester.getRect(_face()).left - restX;
        expect(carried, greaterThan(0.5));

        final TestGesture grab = await tester.startGesture(
          tester.getCenter(find.text('Catch me')),
        );
        await tester.pump(const Duration(milliseconds: 16));
        final double afterGrab = tester.getRect(_face()).left - restX;
        expect(afterGrab, moreOrLessEquals(carried, epsilon: 0.5));

        await grab.up();
        await tester.pumpAndSettle();
        expect(
          tester.getRect(_face()).left - restX,
          moreOrLessEquals(0.0, epsilon: 0.01),
        );
      },
    );

    testWidgets('a vertical flick is not a dismissal', (tester) async {
      await _pumpToaster(tester);
      await _show(tester, 'Scroll by', duration: null);

      final Offset start = tester.getCenter(find.text('Scroll by'));
      // A fast, purely vertical drag carries no horizontal velocity to dismiss
      // with, however hard it is thrown.
      await tester.flingFrom(start, const Offset(0, -80), 1500);
      await tester.pumpAndSettle();

      expect(find.text('Scroll by'), findsOneWidget);
    });

    testWidgets('a withdrawal buzzes once and a cancel never buzzes', (
      tester,
    ) async {
      final List<String> buzzes = <String>[];
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (MethodCall call) async {
          if (call.method == 'HapticFeedback.vibrate') {
            buzzes.add('${call.arguments}');
          }
          return null;
        },
      );

      await _pumpToaster(tester);
      await _show(tester, 'No buzz', duration: null);

      final TestGesture cancel = await tester.startGesture(
        tester.getCenter(find.text('No buzz')),
      );
      await cancel.moveBy(const Offset(30, 0));
      await tester.pump();
      await cancel.up();
      await tester.pumpAndSettle();
      expect(buzzes, isEmpty);

      final TestGesture dismiss = await tester.startGesture(
        tester.getCenter(find.text('No buzz')),
      );
      await dismiss.moveBy(const Offset(150, 0));
      await tester.pump();
      await dismiss.up();
      await tester.pump();
      expect(buzzes, hasLength(1));

      await tester.pumpAndSettle();

      // A toast that simply times out leaves in silence.
      OrionToast.show('Quiet', duration: const Duration(milliseconds: 200));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pumpAndSettle();
      expect(buzzes, hasLength(1));
      expect(find.text('Quiet'), findsNothing);
    });

    testWidgets('pressing the close button dismisses the toast', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'Close button test', duration: null);

      final Finder close = find.byIcon(Icons.close_rounded);
      expect(close, findsOneWidget);
      await tester.tap(close);
      await tester.pumpAndSettle();

      expect(find.text('Close button test'), findsNothing);
    });

    testWidgets('the close target is a labelled 44 point button', (
      tester,
    ) async {
      final SemanticsHandle handle = tester.ensureSemantics();
      await _pumpToaster(tester);
      await _show(tester, 'Target test', duration: null);

      final Finder close = find.byIcon(Icons.close_rounded);
      expect(close, findsOneWidget);
      expect(tester.widget<Icon>(close).size, OrionSizing.iconSmall);

      final Finder button = find
          .ancestor(of: close, matching: find.byType(MergeSemantics))
          .first;
      final Rect rect = tester.getRect(
        find.descendant(of: button, matching: find.byType(SizedBox)).first,
      );
      expect(rect.width, greaterThanOrEqualTo(OrionSizing.minHitTarget));
      expect(rect.height, greaterThanOrEqualTo(OrionSizing.minHitTarget));

      final SemanticsNode node = tester.getSemantics(button);
      expect(node.label, 'Close');
      expect(node.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);

      handle.dispose();
    });

    testWidgets('the action button runs its callback then dismisses', (
      tester,
    ) async {
      var actionFired = false;
      await _pumpToaster(tester);
      OrionToast.show(
        'Item deleted',
        duration: null,
        action: OrionToastAction(
          label: 'Undo',
          onPressed: () => actionFired = true,
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('Undo'), findsOneWidget);
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();

      expect(actionFired, isTrue);
      expect(find.text('Item deleted'), findsNothing);
    });
  });

  group('Hold and expand', () {
    testWidgets('the expanded column spaces cards by measured height', (
      tester,
    ) async {
      await _pumpToaster(tester);
      const String body = 'A description that wraps onto a second line.';
      await _show(tester, 'Toast 1', description: body, duration: null);
      await _show(tester, 'Toast 2', description: body, duration: null);
      await _show(tester, 'Toast 3', description: body, duration: null);

      final List<Rect> collapsed = <Rect>[
        for (int i = 0; i < 3; i++) tester.getRect(_cards.at(i)),
      ];
      // Collapsed, the cards behind overlap the front one on purpose.
      expect(collapsed[0].bottom, greaterThan(collapsed[2].top));

      final TestGesture hold = await tester.startGesture(
        tester.getCenter(find.text('Toast 3')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump(const Duration(milliseconds: 800));

      final List<Rect> expanded = <Rect>[
        for (int i = 0; i < 3; i++) tester.getRect(_cards.at(i)),
      ];
      // Expanded, no card may cover another: the spacing follows real heights,
      // which are taller than any fixed estimate.
      expect(expanded[0].bottom, lessThanOrEqualTo(expanded[1].top));
      expect(expanded[1].bottom, lessThanOrEqualTo(expanded[2].top));
      for (final Rect card in expanded) {
        expect(card.height, greaterThan(64.0));
      }

      await hold.up();
      await tester.pumpAndSettle();
    });

    testWidgets(
      'the peek strip expands the stack instead of reaching the app',
      (tester) async {
        var behindTaps = 0;
        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionToaster(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 32),
                    child: SizedBox(
                      height: 200,
                      width: double.infinity,
                      child: TextButton(
                        onPressed: () => behindTaps++,
                        child: const Text('BEHIND'),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );

        await _show(tester, 'Front', duration: null);
        await _show(tester, 'Behind', duration: null);

        final Rect front = tester.getRect(_cards.at(1));
        final Offset peek = Offset(front.center.dx, front.top - 7);

        // With nothing on screen that point belongs to the button behind.
        OrionToast.clear();
        await tester.pumpAndSettle();
        await tester.tapAt(peek);
        await tester.pumpAndSettle();
        expect(behindTaps, 1);

        await _show(tester, 'Front', duration: null);
        await _show(tester, 'Behind', duration: null);

        final TestGesture touch = await tester.startGesture(peek);
        await tester.pump();
        final Rect raised = tester.getRect(_cards.at(0));
        await tester.pump(const Duration(milliseconds: 800));

        // The strip is part of the stack: it expands, and it swallows the tap.
        expect(tester.getRect(_cards.at(0)).top, lessThan(raised.top));
        final int tapsWhileCovered = behindTaps;
        await touch.up();
        await tester.pumpAndSettle();
        expect(tapsWhileCovered, 1);
      },
    );

    testWidgets('reduced motion lands the stack on the next frame', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: OrionToaster()),
          ),
        ),
      );
      await _show(tester, 'One', duration: null);
      await _show(tester, 'Two', duration: null);
      final Rect collapsed = tester.getRect(_cards.at(0));

      final TestGesture hold = await tester.startGesture(
        tester.getCenter(find.text('Two')),
      );
      await tester.pump();

      // Both directions land on the frame they are asked for.
      final Rect expanded = tester.getRect(_cards.at(0));
      expect(
        expanded.bottom,
        lessThanOrEqualTo(tester.getRect(_cards.at(1)).top),
      );
      expect(expanded.top, lessThan(collapsed.top));

      await hold.up();
      await tester.pump();
      expect(
        tester.getRect(_cards.at(0)).top,
        moreOrLessEquals(collapsed.top, epsilon: 0.5),
      );
    });

    testWidgets('timers pause while held and resume on release', (
      tester,
    ) async {
      await _pumpToaster(tester);
      OrionToast.show('Hold me', duration: const Duration(milliseconds: 600));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Hold me'), findsOneWidget);

      final TestGesture hold = await tester.startGesture(
        tester.getCenter(find.text('Hold me')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 1500));
      expect(find.text('Hold me'), findsOneWidget);

      await hold.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));
      await tester.pump();
      // The queue has let it go; the card is still gliding out of sight.
      expect(OrionToastController.instance.toasts, isEmpty);

      await tester.pumpAndSettle();
      expect(find.text('Hold me'), findsNothing);
    });

    testWidgets('hovering the stack expands it', (tester) async {
      await _pumpToaster(tester);
      await _show(tester, 'One', duration: null);
      await _show(tester, 'Two', duration: null);

      final Rect collapsed = tester.getRect(_cards.at(0));
      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: const Offset(5, 5));
      await tester.pump();
      await mouse.moveTo(tester.getCenter(find.text('Two')));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(tester.getRect(_cards.at(0)).top, lessThan(collapsed.top));

      await mouse.removePointer();
      await tester.pumpAndSettle();
    });
  });

  group('Lifecycle', () {
    testWidgets('a toast auto-dismisses when its duration runs out', (
      tester,
    ) async {
      await _pumpToaster(tester);
      OrionToast.show(
        'Action committed',
        duration: const Duration(milliseconds: 500),
      );
      await tester.pump();
      expect(find.text('Action committed'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 700));
      await tester.pumpAndSettle();
      expect(find.text('Action committed'), findsNothing);
    });

    testWidgets('leaving the tree mid-glide disposes every driver', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'Glide', duration: null);

      final TestGesture gesture = await tester.startGesture(
        tester.getCenter(find.text('Glide')),
      );
      await gesture.moveBy(const Offset(150, 0));
      await tester.pump();
      await gesture.up();
      await tester.pump(const Duration(milliseconds: 32));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 32));
    });

    testWidgets('the front toast is announced, including an in-place update', (
      tester,
    ) async {
      final List<String> announcements = <String>[];
      tester.binding.defaultBinaryMessenger
          .setMockDecodedMessageHandler<Object?>(SystemChannels.accessibility, (
            Object? message,
          ) async {
            announcements.add('$message');
            return null;
          });
      tester.binding.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures(supportsAnnounce: true);
      addTearDown(
        tester.binding.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );

      await _pumpToaster(tester);
      final String id = OrionToast.loading('Syncing');
      await tester.pump();
      expect(announcements, hasLength(1));
      expect(announcements.single, contains('Syncing'));

      // The same toast with a new message is a new thing to say.
      OrionToast.success('Synced', id: id, duration: Duration.zero);
      await tester.pump();
      expect(announcements, hasLength(2));
      expect(announcements.last, contains('Synced'));

      // Re-sending the same message says nothing twice.
      OrionToast.success('Synced', id: id, duration: Duration.zero);
      await tester.pump();
      expect(announcements, hasLength(2));
    });
  });

  group('Leaving the screen', () {
    testWidgets('a timed-out toast leaves with motion, not a cut', (
      tester,
    ) async {
      await _pumpToaster(tester);
      OrionToast.show('Fading', duration: const Duration(milliseconds: 300));
      await tester.pump();

      // The timer fires: the queue lets go, the card does not.
      await tester.pump(const Duration(milliseconds: 400));
      expect(OrionToastController.instance.toasts, isEmpty);
      expect(find.text('Fading'), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 16));
      final Rect tickZero = tester.getRect(_face());
      await tester.pump(const Duration(milliseconds: 16));
      final Rect leaving = tester.getRect(_face());
      await tester.pump(const Duration(milliseconds: 16));
      final Rect goneFurther = tester.getRect(_face());

      expect(leaving.left, greaterThan(tickZero.left));
      expect(goneFurther.left, greaterThan(leaving.left));

      await tester.pumpAndSettle();
      expect(find.text('Fading'), findsNothing);
      expect(_cards, findsNothing);
    });

    testWidgets('clearing the stack still lets the cards leave', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'One', duration: null);
      await _show(tester, 'Two', duration: null);

      OrionToast.clear();
      await tester.pump();

      // The queue is empty at once; the cards are on their way out.
      expect(OrionToastController.instance.toasts, isEmpty);
      expect(_cards, findsNWidgets(2));

      await tester.pumpAndSettle();
      expect(_cards, findsNothing);
      expect(find.text('One'), findsNothing);
      expect(find.text('Two'), findsNothing);
    });
  });

  group('Host lifecycle', () {
    testWidgets('a release after the toaster is gone does not throw', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'Held', duration: null);

      final TestGesture hold = await tester.startGesture(
        tester.getCenter(find.text('Held')),
      );
      await tester.pump();

      // The host navigates away with a finger still down. The framework still
      // delivers the lift to the stack it went down on.
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
      await hold.up();
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('dropping a toast mid-drag leaves nothing to act on', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'Dropped', duration: null);

      final TestGesture drag = await tester.startGesture(
        tester.getCenter(find.text('Dropped')),
      );
      await drag.moveBy(const Offset(150, 0));
      await tester.pump();

      OrionToast.clear();
      await tester.pump();
      await drag.up();
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(OrionToastController.instance.toasts, isEmpty);
      expect(_cards, findsNothing);
    });

    testWidgets('the stack stays open while another finger is still on it', (
      tester,
    ) async {
      await _pumpToaster(tester);
      await _show(tester, 'One', duration: null);
      await _show(tester, 'Two', duration: null);
      final Rect collapsed = tester.getRect(_cards.at(0));

      final TestGesture first = await tester.startGesture(
        tester.getCenter(find.text('Two')),
        pointer: 1,
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.getRect(_cards.at(0)).top, lessThan(collapsed.top));

      final TestGesture second = await tester.startGesture(
        tester.getCenter(find.text('Two')),
        pointer: 2,
      );
      await tester.pump();
      await second.up();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // A finger is still down: the stack must not have counted that as a lift.
      expect(tester.getRect(_cards.at(0)).top, lessThan(collapsed.top));

      await first.up();
      await tester.pumpAndSettle();
      expect(
        tester.getRect(_cards.at(0)).top,
        moreOrLessEquals(collapsed.top, epsilon: 0.5),
      );
    });
  });

  group('OrionToastStyle & Themes', () {
    test('presets reproduce the light scheme default', () {
      final style = OrionToastPresets.resolve(
        scheme: OrionColors.lightScheme,
        textTheme: Typography.material2021().black,
        status: OrionToastStatus.success,
      );

      expect(style.iconColor, const Color(0xFF16A34A));
      expect(style.borderRadius, BorderRadius.circular(OrionRadii.radius16));
      expect(style.mountSpring?.stiffness, 380);
      expect(style.stackSpring?.dampingRatio, 0.95);
    });

    test('style merge overrides only specified properties', () {
      final base = OrionToastStyle.from(
        borderWidth: 2.0,
        backgroundColor: Colors.white,
      );

      final merged = base.merge(
        OrionToastStyle.from(backgroundColor: Colors.black),
      );

      expect(merged.borderWidth, 2.0);
      expect(merged.backgroundColor, Colors.black);
    });

    test('the resolver carries all four layers, motion included', () {
      const OrionSpringSpec instanceSwipe = OrionSpringSpec(
        stiffness: 111,
        dampingRatio: 0.5,
      );
      final ThemeData theme = OrionTheme.light().copyWith(
        extensions: <ThemeExtension<dynamic>>[
          OrionToastTheme(
            defaultStyle: OrionToastStyle.from(backgroundColor: Colors.green),
          ),
        ],
      );

      final style = OrionToastPresets.resolveFor(
        theme,
        status: OrionToastStatus.success,
        stackStyle: OrionToastStyle.from(borderWidth: 3.0),
        instanceStyle: OrionToastStyle.from(swipeSpring: instanceSwipe),
      );

      expect(style.backgroundColor, Colors.green);
      expect(style.borderWidth, 3.0);
      expect(style.swipeSpring, instanceSwipe);
      // Untouched layers keep the presets.
      expect(style.stackSpring?.dampingRatio, 0.95);
      expect(style.mountSpring?.dampingRatio, 0.85);
    });
  });
}

void _noop() {}
