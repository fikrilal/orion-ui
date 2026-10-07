import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpField(
  WidgetTester tester, {
  TextEditingController? controller,
  FocusNode? focusNode,
  ValueChanged<String>? onChanged,
  bool enabled = true,
  String? label,
  String? hint,
  String? error,
  String? helper,
  bool obscureText = false,
  bool autofocus = false,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: OrionTheme.light(),
      home: Scaffold(
        body: OrionTextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          enabled: enabled,
          label: label,
          hint: hint,
          error: error,
          helper: helper,
          obscureText: obscureText,
          autofocus: autofocus,
        ),
      ),
    ),
  );
}

BoxDecoration _face(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(OrionTextField),
      matching: find.byType(DecoratedBox),
    ),
  );
  return box.decoration as BoxDecoration;
}

double _ringAlpha(WidgetTester tester) {
  final List<BoxShadow>? shadows = _face(tester).boxShadow;
  if (shadows == null || shadows.isEmpty) {
    return 0;
  }
  return shadows.first.color.a;
}

void main() {
  group('OrionTextField', () {
    testWidgets('shows the label and the hint', (tester) async {
      await _pumpField(tester, label: 'Name', hint: 'Ada Lovelace');

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Ada Lovelace'), findsOneWidget);
    });

    testWidgets('reports entered text', (tester) async {
      String? seen;
      await _pumpField(
        tester,
        label: 'Name',
        onChanged: (String value) => seen = value,
      );

      await tester.enterText(find.byType(EditableText), 'Ada');

      expect(seen, 'Ada');
    });

    testWidgets('paints an error border and replaces the helper', (
      tester,
    ) async {
      await _pumpField(
        tester,
        label: 'Name',
        helper: 'Keep it short',
        error: 'Name is required',
      );

      expect(find.text('Name is required'), findsOneWidget);
      expect(find.text('Keep it short'), findsNothing);
      final ColorScheme scheme = OrionTheme.light().colorScheme;
      final Border border = _face(tester).border! as Border;
      expect(border.top.color, scheme.error);
      expect(_ringAlpha(tester), 0);
    });

    testWidgets('disabled editor ignores edits', (tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpField(tester, controller: controller, enabled: false);

      await tester.enterText(find.byType(EditableText), 'nope');

      expect(controller.text, isEmpty);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
    });

    testWidgets('the focus ring arrives without overshooting', (tester) async {
      await _pumpField(tester, label: 'Name');

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      final double early = _ringAlpha(tester);
      expect(early, greaterThan(0));
      expect(early, lessThan(0.16));

      double peak = early;
      for (int frame = 0; frame < 30; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double now = _ringAlpha(tester);
        if (now > peak) {
          peak = now;
        }
      }
      await tester.pumpAndSettle();

      expect(
        peak,
        lessThanOrEqualTo(0.161),
        reason:
            'a focus ring arrives; the corpus damps it critically and we clamp it',
      );
      expect(_ringAlpha(tester), closeTo(0.16, 0.02));
    });

    testWidgets('a tap on the face focuses the field', (tester) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await _pumpField(tester, focusNode: node, label: 'Name');

      final Rect face = tester.getRect(find.byType(DecoratedBox));
      await tester.tapAt(face.topCenter + const Offset(0, 4));
      await tester.pump();
      expect(node.hasFocus, isTrue);

      node.unfocus();
      await tester.pump();
      await tester.tapAt(face.bottomCenter + const Offset(0, -4));
      await tester.pump();
      expect(node.hasFocus, isTrue);

      node.unfocus();
      await tester.pump();
      await tester.tapAt(face.centerLeft + const Offset(4, 0));
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });

    testWidgets('the focus ring does not flash back on after unfocus', (
      tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await _pumpField(tester, focusNode: node, label: 'Name');
      node.requestFocus();
      await tester.pumpAndSettle();

      node.unfocus();
      await tester.pump();
      double previous = _ringAlpha(tester);
      for (var frame = 0; frame < 50; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double alpha = _ringAlpha(tester);
        expect(alpha, lessThanOrEqualTo(previous + 0.001));
        previous = alpha;
      }
      await tester.pumpAndSettle();
      expect(_ringAlpha(tester), 0);
    });

    testWidgets('the field name is the accessible label', (tester) async {
      await _pumpField(tester, label: 'Full Name', hint: 'e.g. John Doe');

      final SemanticsData data = tester
          .getSemantics(find.byType(EditableText))
          .getSemanticsData();
      expect(data.label, contains('Full Name'));
    });

    testWidgets('an empty error keeps the helper and the idle border', (
      tester,
    ) async {
      await _pumpField(tester, helper: 'Keep it short', error: '');

      expect(find.text('Keep it short'), findsOneWidget);
      final ColorScheme scheme = OrionTheme.light().colorScheme;
      final Border border = _face(tester).border! as Border;
      expect(border.top.color, scheme.outline);
    });

    testWidgets('keeps an external controller after dispose', (tester) async {
      final TextEditingController controller = TextEditingController(
        text: 'kept',
      );
      addTearDown(controller.dispose);
      await _pumpField(tester, controller: controller);

      await tester.pumpWidget(const SizedBox.shrink());

      expect(controller.text, 'kept');
    });
  });
}
