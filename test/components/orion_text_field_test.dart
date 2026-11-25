import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:orion_ui/orion_ui.dart';

Future<void> _pumpField(
  WidgetTester tester, {
  TextEditingController? controller,
  FocusNode? focusNode,
  ValueChanged<String>? onChanged,
  bool enabled = true,
  bool readOnly = false,
  VoidCallback? onTap,
  String? label,
  String? hint,
  String? error,
  String? helper,
  bool obscureText = false,
  bool showPasswordToggle = true,
  bool autofocus = false,
  OrionTextFieldVariant variant = OrionTextFieldVariant.outline,
  OrionTextFieldSize size = OrionTextFieldSize.medium,
  OrionTextFieldType type = OrionTextFieldType.text,
  TextInputType? keyboardType,
  List<TextInputFormatter>? inputFormatters,
  int? maxLength,
  bool reserveCaption = false,
  Widget? prefix,
  Widget? suffix,
  FormFieldValidator<String>? validator,
  AutovalidateMode? autovalidateMode,
  OrionTextFieldStyle? style,
  ThemeData? theme,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme ?? OrionTheme.light(),
      home: Scaffold(
        body: OrionTextField(
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          enabled: enabled,
          readOnly: readOnly,
          onTap: onTap,
          label: label,
          hint: hint,
          error: error,
          helper: helper,
          obscureText: obscureText,
          showPasswordToggle: showPasswordToggle,
          autofocus: autofocus,
          variant: variant,
          size: size,
          type: type,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLength: maxLength,
          reserveCaption: reserveCaption,
          prefix: prefix,
          suffix: suffix,
          validator: validator,
          autovalidateMode: autovalidateMode,
          style: style,
        ),
      ),
    ),
  );
}

BoxDecoration _face(WidgetTester tester) {
  final DecoratedBox box = tester.widget<DecoratedBox>(
    find.descendant(
      of: find.byType(OrionTextField),
      matching: find.byKey(orionTextFieldFaceKey),
    ),
  );
  return box.decoration as BoxDecoration;
}

Border _border(WidgetTester tester) => _face(tester).border! as Border;

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
      expect(border.top.width, 1);
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

    testWidgets(
      'the focus line sweeps to the focus colour without overshooting',
      (tester) async {
        final ColorScheme scheme = OrionTheme.light().colorScheme;
        await _pumpField(tester, label: 'Name');

        await tester.tap(find.byType(EditableText));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 16));
        await tester.pump(const Duration(milliseconds: 16));
        final Color early = _border(tester).top.color;
        expect(early, isNot(scheme.outline));
        expect(early, isNot(scheme.primary));
        expect(_border(tester).top.width, greaterThan(1));
        expect(_border(tester).top.width, lessThan(1.5));

        double previous = early.computeLuminance();
        for (int frame = 0; frame < 40; frame++) {
          await tester.pump(const Duration(milliseconds: 16));
          final double luminance = _border(tester).top.color.computeLuminance();
          expect(
            luminance,
            lessThanOrEqualTo(previous + 0.001),
            reason: 'the corpus damps focus critically and we clamp it',
          );
          previous = luminance;
        }
        await tester.pumpAndSettle();

        expect(_border(tester).top.color, scheme.primary);
        expect(_border(tester).top.width, 1.5);
      },
    );

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

    testWidgets('the focus line retreats on unfocus without flashing back', (
      tester,
    ) async {
      final ColorScheme scheme = OrionTheme.light().colorScheme;
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await _pumpField(tester, focusNode: node, label: 'Name');
      node.requestFocus();
      await tester.pumpAndSettle();

      node.unfocus();
      await tester.pump();
      double previous = _border(tester).top.color.computeLuminance();
      for (var frame = 0; frame < 50; frame++) {
        await tester.pump(const Duration(milliseconds: 16));
        final double luminance = _border(tester).top.color.computeLuminance();
        expect(luminance, greaterThanOrEqualTo(previous - 0.001));
        previous = luminance;
      }
      await tester.pumpAndSettle();
      expect(_border(tester).top.color, scheme.outline);
      expect(_border(tester).top.width, 1);
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

    testWidgets('resolves through the theme and the instance style', (
      tester,
    ) async {
      final ThemeData themed = OrionTheme.apply(
        OrionTheme.light(),
        extensions: <ThemeExtension<dynamic>>[
          OrionTextFieldTheme(
            defaultStyle: OrionTextFieldStyle.from(
              borderColor: const Color(0xFF00AA00),
            ),
          ),
        ],
      );

      await _pumpField(tester, theme: themed);
      expect(
        (_face(tester).border! as Border).top.color,
        const Color(0xFF00AA00),
      );

      await _pumpField(
        tester,
        theme: themed,
        style: OrionTextFieldStyle.from(borderColor: const Color(0xFFAA0000)),
      );
      expect(
        (_face(tester).border! as Border).top.color,
        const Color(0xFFAA0000),
      );
    });

    testWidgets('paints the filled and underline faces and the size steps', (
      tester,
    ) async {
      final ColorScheme scheme = OrionTheme.light().colorScheme;
      await _pumpField(
        tester,
        variant: OrionTextFieldVariant.filled,
        size: OrionTextFieldSize.large,
      );
      expect(_face(tester).color, scheme.surfaceContainerHighest);
      expect(tester.getSize(find.byType(DecoratedBox)).height, 56);

      await _pumpField(tester, variant: OrionTextFieldVariant.underline);
      final Border border = _face(tester).border! as Border;
      expect(border.top, BorderSide.none);
      expect(border.bottom.color, scheme.outline);
      expect(_face(tester).borderRadius, BorderRadius.zero);
    });

    testWidgets('derives behaviour from the type', (tester) async {
      TextField field() => tester.widget<TextField>(find.byType(TextField));

      await _pumpField(tester, type: OrionTextFieldType.number);
      expect(field().keyboardType, TextInputType.number);
      expect(field().inputFormatters, isNotEmpty);

      await _pumpField(tester, type: OrionTextFieldType.email);
      expect(field().keyboardType, TextInputType.emailAddress);
      expect(field().autocorrect, isFalse);
      expect(field().autofillHints, contains(AutofillHints.email));

      await _pumpField(
        tester,
        type: OrionTextFieldType.phone,
        keyboardType: TextInputType.datetime,
      );
      expect(
        field().keyboardType,
        TextInputType.datetime,
        reason: 'an explicit keyboard wins over the derived one',
      );

      await _pumpField(tester, keyboardType: TextInputType.number);
      expect(
        field().inputFormatters,
        isNotEmpty,
        reason: 'the digits filter follows the effective keyboard',
      );
    });

    testWidgets('caps the text and shows the counter', (tester) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpField(tester, controller: controller, maxLength: 5);

      expect(find.text('0/5'), findsOneWidget);

      await tester.enterText(find.byType(EditableText), 'abcdef');
      await tester.pump();

      expect(controller.text, 'abcde');
      expect(find.text('5/5'), findsOneWidget);
    });

    testWidgets('reserves the caption line', (tester) async {
      await _pumpField(tester, reserveCaption: true);
      expect(
        find.byWidgetPredicate(
          (Widget widget) => widget is Text && widget.data == '',
        ),
        findsOneWidget,
      );
    });

    testWidgets('composes prefix, suffix and the password toggle', (
      tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);
      await _pumpField(
        tester,
        focusNode: node,
        type: OrionTextFieldType.password,
        prefix: const Icon(Icons.link),
        suffix: const Text('!'),
      );

      expect(find.byIcon(Icons.link), findsOneWidget);
      expect(find.text('!'), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isTrue,
      );
      expect(
        tester
            .getSemantics(find.byType(OrionPressable))
            .getSemanticsData()
            .label,
        contains('Show password'),
      );

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).obscureText,
        isFalse,
      );
      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(node.hasFocus, isFalse, reason: 'the reveal is not a focus');
    });

    testWidgets('validates through a Form', (tester) async {
      final GlobalKey<FormState> form = GlobalKey<FormState>();
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Form(
              key: form,
              child: OrionTextField(
                label: 'Name',
                validator: (String? value) =>
                    value == null || value.isEmpty ? 'Required' : null,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Required'), findsNothing);
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);
    });

    testWidgets('read-only reports taps without editing', (tester) async {
      var taps = 0;
      await _pumpField(
        tester,
        readOnly: true,
        onTap: () => taps++,
        label: 'Plan',
      );

      final Rect face = tester.getRect(find.byType(DecoratedBox));
      await tester.tapAt(face.center);
      await tester.pump();
      expect(taps, 1);

      await tester.enterText(find.byType(EditableText), 'nope');
      expect(
        tester.widget<EditableText>(find.byType(EditableText)).readOnly,
        isTrue,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).mouseCursor,
        SystemMouseCursors.click,
      );
      expect(
        tester.widget<TextField>(find.byType(TextField)).showCursor,
        isFalse,
      );
    });

    testWidgets('syncs programmatic controller edits and Form.reset/save', (
      tester,
    ) async {
      final GlobalKey<FormState> form = GlobalKey<FormState>();
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      String? saved;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Form(
              key: form,
              child: OrionTextField(
                controller: controller,
                label: 'Email',
                validator: (String? v) =>
                    v == null || v.isEmpty ? 'Required' : null,
                onSaved: (String? v) => saved = v,
              ),
            ),
          ),
        ),
      );

      // Initially invalid.
      expect(form.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('Required'), findsOneWidget);

      // Programmatic controller update must sync FormField without user typing.
      controller.text = 'ada@orion.dev';
      await tester.pump();
      expect(form.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('Required'), findsNothing);

      // Form.save receives latest text.
      form.currentState!.save();
      expect(saved, 'ada@orion.dev');

      // Form.reset resets both controller text and FormField state.
      form.currentState!.reset();
      await tester.pump();
      expect(controller.text, isEmpty);
    });

    testWidgets('initialValue works without controller and resets cleanly', (
      tester,
    ) async {
      final GlobalKey<FormState> form = GlobalKey<FormState>();
      String? saved;

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: Form(
              key: form,
              child: OrionTextField(
                initialValue: 'Ada',
                onSaved: (String? v) => saved = v,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Ada'), findsOneWidget);
      await tester.enterText(find.byType(EditableText), 'Grace');
      await tester.pump();
      form.currentState!.save();
      expect(saved, 'Grace');

      form.currentState!.reset();
      await tester.pump();
      expect(find.text('Ada'), findsOneWidget);
    });

    testWidgets('guards multiline+obscure, underline+radius, and expands', (
      tester,
    ) async {
      // Multiline + obscureText must not throw Flutter's !obscureText || maxLines == 1 assert.
      await _pumpField(
        tester,
        type: OrionTextFieldType.multiline,
        obscureText: true,
      );
      expect(tester.takeException(), isNull);
      expect(tester.widget<TextField>(find.byType(TextField)).maxLines, 1);

      // Underline + non-zero custom radius must not throw non-uniform border assert.
      await _pumpField(
        tester,
        variant: OrionTextFieldVariant.underline,
        style: OrionTextFieldStyle.from(radius: BorderRadius.circular(12)),
      );
      expect(tester.takeException(), isNull);

      // expands: true fills fixed parent cleanly.
      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: const Scaffold(
            body: SizedBox(
              height: 160,
              child: OrionTextField(expands: true, hint: 'Notes'),
            ),
          ),
        ),
      );
      expect(tester.takeException(), isNull);
    });

    testWidgets(
      'refined typography (13/14/15 pt) and small password keeps 40 pt height',
      (tester) async {
        await _pumpField(
          tester,
          size: OrionTextFieldSize.small,
          type: OrionTextFieldType.password,
        );
        expect(
          tester.widget<TextField>(find.byType(TextField)).style?.fontSize,
          13.0,
        );
        expect(
          tester.getSize(find.byKey(orionTextFieldFaceKey)).height,
          closeTo(40.0, 0.5),
        );

        await _pumpField(tester, size: OrionTextFieldSize.medium);
        expect(
          tester.widget<TextField>(find.byType(TextField)).style?.fontSize,
          14.0,
        );
        // TextField owns vertical padding so its hit height spans the box.
        expect(
          tester.getSize(find.byType(TextField)).height,
          greaterThanOrEqualTo(40.0),
        );

        await _pumpField(tester, size: OrionTextFieldSize.large);
        expect(
          tester.widget<TextField>(find.byType(TextField)).style?.fontSize,
          15.0,
        );
      },
    );

    testWidgets('multiline defaults to 3 lines with vertical padding', (
      tester,
    ) async {
      await _pumpField(tester, type: OrionTextFieldType.multiline);
      final TextField tf = tester.widget<TextField>(find.byType(TextField));
      expect(tf.minLines, 3);
      expect(tf.maxLines, isNull);
      final EdgeInsetsGeometry? pad = tf.decoration?.contentPadding;
      expect(pad, isNotNull);
      expect(pad!.resolve(TextDirection.ltr).top, greaterThan(0));
      expect(pad.resolve(TextDirection.ltr).bottom, greaterThan(0));
    });

    testWidgets('number respects decimal and signed keyboard options', (
      tester,
    ) async {
      final TextEditingController controller = TextEditingController();
      addTearDown(controller.dispose);
      await _pumpField(
        tester,
        controller: controller,
        type: OrionTextFieldType.number,
        keyboardType: const TextInputType.numberWithOptions(
          decimal: true,
          signed: true,
        ),
      );

      await tester.enterText(find.byType(EditableText), '-12.50abc');
      await tester.pump();
      expect(controller.text, '-12.50');
    });

    testWidgets(
      'search auto-shows clear button, clears text, and fires hooks',
      (tester) async {
        final TextEditingController controller = TextEditingController();
        addTearDown(controller.dispose);
        final List<String> changed = <String>[];
        int cleared = 0;

        await tester.pumpWidget(
          MaterialApp(
            theme: OrionTheme.light(),
            home: Scaffold(
              body: OrionTextField(
                controller: controller,
                type: OrionTextFieldType.search,
                onChanged: changed.add,
                onCleared: () => cleared++,
              ),
            ),
          ),
        );

        expect(find.byKey(orionTextFieldClearButtonKey), findsNothing);

        await tester.enterText(find.byType(EditableText), 'orion');
        await tester.pumpAndSettle();
        expect(find.byKey(orionTextFieldClearButtonKey), findsOneWidget);

        await tester.tap(find.byKey(orionTextFieldClearButtonKey));
        await tester.pumpAndSettle();
        expect(controller.text, isEmpty);
        expect(cleared, 1);
        expect(changed.last, isEmpty);
        expect(find.byKey(orionTextFieldClearButtonKey), findsNothing);
      },
    );

    testWidgets('hover, focused fill/ring, clickable label, and required marker', (
      tester,
    ) async {
      final FocusNode node = FocusNode();
      addTearDown(node.dispose);

      await tester.pumpWidget(
        MaterialApp(
          theme: OrionTheme.light(),
          home: Scaffold(
            body: OrionTextField(
              focusNode: node,
              variant: OrionTextFieldVariant.filled,
              label: 'Workspace',
              required: true,
              prefix: const Icon(Icons.workspaces_outline),
            ),
          ),
        ),
      );

      // Required renders '*' alongside label; tapping label focuses the input.
      expect(find.textContaining('Workspace *'), findsOneWidget);
      await tester.tap(find.textContaining('Workspace *'));
      await tester.pumpAndSettle();
      expect(node.hasFocus, isTrue);

      // Default focus relies solely on the crisp expanding hairline (no outer halo).
      expect(_face(tester).boxShadow, isNull);

      // Unfocus and test pointer hover state.
      node.unfocus();
      await tester.pumpAndSettle();
      final Color restFill = _face(tester).color!;

      final TestGesture mouse = await tester.createGesture(
        kind: PointerDeviceKind.mouse,
      );
      await mouse.addPointer(location: Offset.zero);
      addTearDown(mouse.removePointer);

      await mouse.moveTo(tester.getCenter(find.byKey(orionTextFieldFaceKey)));
      await tester.pump();
      expect(_face(tester).color, isNot(restFill));

      // Opt-in focusRingColor + focusRingWidth renders halo when explicitly styled.
      await _pumpField(
        tester,
        focusNode: node,
        style: const OrionTextFieldStyle(
          focusRingColor: Color(0x330000FF),
          focusRingWidth: 3.0,
        ),
      );
      node.requestFocus();
      await tester.pumpAndSettle();
      expect(_face(tester).boxShadow, isNotEmpty);
    });
  });

  group('OrionTextFieldStyle', () {
    test('a merge only changes the fields it names', () {
      final OrionTextFieldStyle base = OrionTextFieldStyle.from(
        borderColor: const Color(0xFF111111),
        radius: BorderRadius.circular(8),
      );
      final OrionTextFieldStyle merged = base.merge(
        OrionTextFieldStyle.from(borderColor: const Color(0xFF333333)),
      );

      expect(
        merged.borderColor?.resolve(const <WidgetState>{}),
        const Color(0xFF333333),
      );
      expect(merged.radius, base.radius);
    });

    test('presets reproduce refined medium typography and face tokens', () {
      final OrionTextFieldStyle style = OrionTextFieldPresets.resolve(
        variant: OrionTextFieldVariant.outline,
        size: OrionTextFieldSize.medium,
        scheme: OrionColors.lightScheme,
        textTheme: OrionTheme.light().textTheme,
      );

      expect(style.height, OrionSizing.controlHeightLarge);
      expect(style.textStyle?.fontSize, 14.0);
      expect(style.labelStyle?.fontSize, 13.0);
      expect(style.iconSize, 18.0);
      expect(
        style.borderColor?.resolve(const <WidgetState>{}),
        OrionColors.lightScheme.outline,
      );
      expect(
        style.borderColor?.resolve(const <WidgetState>{WidgetState.focused}),
        OrionColors.lightScheme.primary,
      );
      expect(
        style.borderColor?.resolve(const <WidgetState>{WidgetState.error}),
        OrionColors.lightScheme.error,
      );
    });

    test('lerp smoothly interpolates style and theme values', () {
      final OrionTextFieldTheme a = OrionTextFieldTheme(
        defaultStyle: OrionTextFieldStyle.from(
          height: 40,
          borderWidth: 1,
          borderColor: const Color(0xFF000000),
        ),
      );
      final OrionTextFieldTheme b = OrionTextFieldTheme(
        defaultStyle: OrionTextFieldStyle.from(
          height: 56,
          borderWidth: 3,
          borderColor: const Color(0xFFFFFFFF),
        ),
      );

      final OrionTextFieldTheme mid = a.lerp(b, 0.5);
      expect(mid.defaultStyle?.height, closeTo(48.0, 0.01));
      expect(mid.defaultStyle?.borderWidth, closeTo(2.0, 0.01));
      expect(
        mid.defaultStyle?.borderColor?.resolve(const <WidgetState>{}),
        Color.lerp(const Color(0xFF000000), const Color(0xFFFFFFFF), 0.5),
      );
    });
  });
}
