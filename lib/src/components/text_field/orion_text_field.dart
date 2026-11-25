import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/text_field/orion_text_field_presets.dart';
import 'package:orion_ui/src/components/text_field/orion_text_field_style.dart';
import 'package:orion_ui/src/components/text_field/orion_text_field_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Key for the painted input face container inside [OrionTextField].
const Key orionTextFieldFaceKey = Key('orion_text_field_face');

/// Key for the inline clear action button inside [OrionTextField].
const Key orionTextFieldClearButtonKey = Key('orion_text_field_clear_button');

/// Key for the inline password visibility toggle inside [OrionTextField].
const Key orionTextFieldPasswordToggleKey = Key(
  'orion_text_field_password_toggle',
);

/// The field's face treatment.
enum OrionTextFieldVariant {
  /// A surface face with a hairline border that darkens on focus. The default.
  outline,

  /// A container-filled face with no resting hairline.
  filled,

  /// A transparent face with a bottom line.
  underline,
}

/// The field's size step.
enum OrionTextFieldSize {
  /// Compact 40 pt height with 13 pt input text.
  small,

  /// Standard 48 pt height with 14 pt input text (default).
  medium,

  /// Generous 56 pt height with 15 pt input text.
  large,
}

/// The field's semantic input preset.
///
/// A type derives keyboard layout, action button, autocorrect/suggestions,
/// autofill hints, default line counts, clear button visibility, and input
/// filters. Explicit parameters always override preset defaults.
enum OrionTextFieldType {
  /// Free text.
  text,

  /// An email address: email keyboard, no autocorrect, email autofill.
  email,

  /// A password: obscured with a reveal toggle, no suggestions, password
  /// autofill.
  password,

  /// A number: numeric keyboard and filter respecting decimal/signed options.
  number,

  /// A phone number: phone keyboard, phone autofill, and `+ - space ( )` filter.
  phone,

  /// A URL: url keyboard, no autocorrect, URL autofill.
  url,

  /// Multiple lines: multiline keyboard, newline action, and a growing textarea
  /// starting at 3 lines by default.
  multiline,

  /// A search field: search action, suggestions kept on, and an automatic
  /// clear button while non-empty.
  search,
}

/// A form-integrated single-line or multiline text input.
///
/// Focus drives the border colour, stroke width, fill lift, and optional outer
/// focus ring along a critically damped, clamped spring so focus arrives
/// cleanly without bouncing or flashing back on blur.
///
/// Integrates fully with Flutter's [Form] (`validate()`, `save()`, `reset()`,
/// `initialValue`, and bidirectional synchronization with programmatic
/// [TextEditingController] updates).
///
/// Look and feel resolve in three layers, each overriding the last:
/// [OrionTextFieldPresets] for [variant] and [size], the ambient
/// [OrionTextFieldTheme], and the instance [style] passed here.
class OrionTextField extends StatefulWidget {
  /// Creates a text field.
  const OrionTextField({
    super.key,
    this.controller,
    this.initialValue,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.onEditingComplete,
    this.onSaved,
    this.onTap,
    this.onTapOutside,
    this.onCleared,
    this.enabled = true,
    this.readOnly = false,
    this.required = false,
    this.variant = OrionTextFieldVariant.outline,
    this.size = OrionTextFieldSize.medium,
    this.type = OrionTextFieldType.text,
    this.label,
    this.hint,
    this.error,
    this.helper,
    this.semanticLabel,
    this.obscureText = false,
    this.obscuringCharacter = '•',
    this.showPasswordToggle = true,
    this.showClearButton,
    this.keyboardType,
    this.textInputAction,
    this.textCapitalization = TextCapitalization.none,
    this.textAlign = TextAlign.start,
    this.textDirection,
    this.autocorrect,
    this.enableSuggestions,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines,
    this.expands = false,
    this.prefix,
    this.suffix,
    this.reserveCaption = false,
    this.validator,
    this.autovalidateMode,
    this.autofocus = false,
    this.enableInteractiveSelection,
    this.showCursor,
    this.mouseCursor,
    this.scrollController,
    this.scrollPadding = const EdgeInsets.all(20.0),
    this.undoController,
    this.contextMenuBuilder,
    this.style,
  }) : assert(
         controller == null || initialValue == null,
         'Cannot provide both a controller and an initialValue.',
       ),
       assert(
         obscuringCharacter.length == 1,
         'obscuringCharacter must be a single character.',
       );

  /// Optional controller. When omitted, the field owns one initialized with
  /// [initialValue].
  final TextEditingController? controller;

  /// Initial text when [controller] is omitted.
  final String? initialValue;

  /// Optional focus node. When omitted, the field owns one.
  final FocusNode? focusNode;

  /// Called with the field text after each user edit or clear action.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Called when the user finishes editing (e.g., presses keyboard action).
  final VoidCallback? onEditingComplete;

  /// Called when an enclosing [Form] calls `save()`.
  final FormFieldSetter<String>? onSaved;

  /// Called when the face is tapped; defaults to focusing the field.
  final VoidCallback? onTap;

  /// Called when a tap occurs outside this text field while focused.
  final TapRegionCallback? onTapOutside;

  /// Called after the built-in clear button empties the field.
  final VoidCallback? onCleared;

  /// False mutes the field and ignores edits.
  final bool enabled;

  /// True keeps text legible while preventing edits; pair with [onTap] for
  /// picker triggers (dates, dropdown sheets, selectors).
  final bool readOnly;

  /// Displays a required asterisk beside [label]. Does not auto-validate; pair
  /// with [validator] or [error] for validation feedback.
  final bool required;

  /// The face treatment. Defaults to [OrionTextFieldVariant.outline].
  final OrionTextFieldVariant variant;

  /// The size step. Defaults to [OrionTextFieldSize.medium].
  final OrionTextFieldSize size;

  /// The semantic input preset. Defaults to [OrionTextFieldType.text].
  final OrionTextFieldType type;

  /// Label displayed above the face. Tapping it focuses the field.
  final String? label;

  /// Placeholder shown while the field is empty.
  final String? hint;

  /// Non-empty paints error state and replaces [helper]; wins over a
  /// [validator]'s message.
  final String? error;

  /// Supporting caption under the face. Hidden while an error is active.
  final String? helper;

  /// Spoken label override for screen readers. Defaults to [label].
  final String? semanticLabel;

  /// Hides characters (always single-line).
  final bool obscureText;

  /// Character used when text is obscured. Defaults to `'•'`.
  final String obscuringCharacter;

  /// Shows the inline reveal toggle on [OrionTextFieldType.password] fields.
  final bool showPasswordToggle;

  /// Shows an animated clear (`×`) button when non-empty and editable.
  /// Defaults to `true` for [OrionTextFieldType.search] and `false` otherwise.
  final bool? showClearButton;

  /// Keyboard layout override; [type] derives it otherwise.
  final TextInputType? keyboardType;

  /// Action button override; [type] derives it otherwise.
  final TextInputAction? textInputAction;

  /// Configures platform keyboard capitalization.
  final TextCapitalization textCapitalization;

  /// Horizontal text alignment within the input.
  final TextAlign textAlign;

  /// Optional explicit text direction for the input text.
  final TextDirection? textDirection;

  /// Autocorrect override; [type] derives it otherwise.
  final bool? autocorrect;

  /// Suggestions override; [type] derives it otherwise.
  final bool? enableSuggestions;

  /// Autofill hints override; [type] derives them otherwise.
  final Iterable<String>? autofillHints;

  /// Extra input formatters applied after any preset-derived formatters.
  final List<TextInputFormatter>? inputFormatters;

  /// Caps input length and shows a tabular `n/max` counter at the caption end.
  final int? maxLength;

  /// Minimum visible lines for multiline inputs. Defaults to `3` on
  /// [OrionTextFieldType.multiline].
  final int? minLines;

  /// Maximum visible lines before scrolling. Defaults to `null` (grows freely)
  /// on [OrionTextFieldType.multiline] and `1` otherwise.
  final int? maxLines;

  /// Whether the input expands to fill its parent's height constraints.
  final bool expands;

  /// Leading widget inside the face before the text, automatically themed with
  /// [OrionTextFieldStyle.iconSize] and [OrionTextFieldStyle.iconColor].
  final Widget? prefix;

  /// Trailing widget inside the face after inline actions, automatically themed
  /// with [OrionTextFieldStyle.iconSize] and [OrionTextFieldStyle.iconColor].
  final Widget? suffix;

  /// Reserves the caption line even when empty so errors cannot cause vertical
  /// layout shift below the field.
  final bool reserveCaption;

  /// Validates the text through the enclosing [Form]; its message paints like
  /// [error] unless [error] is explicitly set.
  final FormFieldValidator<String>? validator;

  /// When validation runs automatically. Defaults to [AutovalidateMode.disabled].
  final AutovalidateMode? autovalidateMode;

  /// Whether the field requests focus on first build.
  final bool autofocus;

  /// Overrides whether text selection handles/gestures are enabled.
  final bool? enableInteractiveSelection;

  /// Overrides whether the text caret is displayed. Defaults to `false` when
  /// [readOnly] and [onTap] are both set (picker trigger mode).
  final bool? showCursor;

  /// Mouse cursor override. Defaults to [SystemMouseCursors.click] for
  /// read-only picker faces, [SystemMouseCursors.text] when enabled, and
  /// [MouseCursor.defer] when disabled.
  final MouseCursor? mouseCursor;

  /// Optional scroll controller for the underlying [TextField].
  final ScrollController? scrollController;

  /// Padding around the field when scrolled into view for the keyboard.
  final EdgeInsets scrollPadding;

  /// Optional undo history controller.
  final UndoHistoryController? undoController;

  /// Optional custom selection context menu builder.
  final EditableTextContextMenuBuilder? contextMenuBuilder;

  /// Instance-level overrides merged over presets and [OrionTextFieldTheme].
  final OrionTextFieldStyle? style;

  @override
  State<OrionTextField> createState() => _OrionTextFieldState();
}

class _OrionTextFieldState extends State<OrionTextField>
    with SingleTickerProviderStateMixin {
  final GlobalKey<FormFieldState<String>> _formFieldKey =
      GlobalKey<FormFieldState<String>>();

  late final OrionSpringDriver _driver;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _obscured;
  late String _initialFormValue;

  bool _ownsController = false;
  bool _ownsFocus = false;
  bool _focusBound = false;
  bool _controllerBound = false;
  bool _hovered = false;
  bool _hasText = false;
  bool _syncingFormReset = false;

  @override
  void initState() {
    super.initState();
    _obscured = _startsObscured;
    _bindController(widget.controller);
    _initialFormValue = _controller.text;
    _hasText = _controller.text.isNotEmpty;
    _bindFocus(widget.focusNode);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: OrionTextFieldPresets.defaultFocusSpring,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion) {
          return;
        }
        _driver.jumpTo(_target);
      });
    }
  }

  @override
  void didUpdateWidget(OrionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();

    if (widget.controller != oldWidget.controller) {
      _bindController(widget.controller);
      _hasText = _controller.text.isNotEmpty;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final FormFieldState<String>? field = _formFieldKey.currentState;
        if (field != null && field.value != _controller.text) {
          field.didChange(_controller.text);
        }
      });
    }

    if (widget.obscureText != oldWidget.obscureText ||
        widget.type != oldWidget.type) {
      _obscured = _startsObscured;
    }

    bool retarget = false;
    if (widget.focusNode != oldWidget.focusNode) {
      _bindFocus(widget.focusNode);
      retarget = true;
    }
    if (widget.enabled != oldWidget.enabled) {
      if (!widget.enabled && _hovered) {
        _hovered = false;
      }
      retarget = true;
    }
    if (retarget) {
      _sync();
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _focusNode.removeListener(_onFocus);
    if (_ownsFocus) {
      _focusNode.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    _driver.dispose();
    super.dispose();
  }

  double get _target => widget.enabled && _focusNode.hasFocus ? 1.0 : 0.0;

  bool get _effectiveShowClearButton =>
      widget.showClearButton ?? (widget.type == OrionTextFieldType.search);

  void _bindController(TextEditingController? incoming) {
    if (_controllerBound) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) {
        _controller.dispose();
      }
    }
    _ownsController = incoming == null;
    _controller = incoming ?? TextEditingController(text: widget.initialValue);
    _controller.addListener(_onControllerChanged);
    _controllerBound = true;
  }

  void _bindFocus(FocusNode? incoming) {
    if (_focusBound) {
      _focusNode.removeListener(_onFocus);
      if (_ownsFocus) {
        _focusNode.dispose();
      }
    }
    _ownsFocus = incoming == null;
    _focusNode = incoming ?? FocusNode();
    _focusNode.addListener(_onFocus);
    _focusBound = true;
  }

  void _onControllerChanged() {
    if (!mounted) return;

    final String currentText = _controller.text;
    if (!_syncingFormReset) {
      final FormFieldState<String>? field = _formFieldKey.currentState;
      if (field != null && field.value != currentText) {
        field.didChange(currentText);
      }
    }

    final bool nowHasText = currentText.isNotEmpty;
    final bool needsClearUpdate =
        _effectiveShowClearButton && nowHasText != _hasText;
    _hasText = nowHasText;

    if (widget.maxLength != null || needsClearUpdate) {
      setState(() {});
    }
  }

  void _handleFormReset() {
    _syncingFormReset = true;
    try {
      final String resetText = widget.initialValue ?? _initialFormValue;
      _controller.value = TextEditingValue(
        text: resetText,
        selection: TextSelection.collapsed(offset: resetText.length),
      );
      _hasText = resetText.isNotEmpty;
    } finally {
      _syncingFormReset = false;
    }
    if (mounted) {
      setState(() {});
    }
  }

  void _onFocus() {
    _sync();
    if (mounted) {
      setState(() {});
    }
  }

  void _sync() {
    if (_driver.reducedMotion) {
      _driver.jumpTo(_target);
      return;
    }
    _driver.retarget(_target);
  }

  OrionTextFieldStyle _resolve(ThemeData theme) {
    final OrionTextFieldTheme fieldTheme =
        theme.extension<OrionTextFieldTheme>() ?? OrionTextFieldTheme.fallback;
    return OrionTextFieldPresets.resolve(
      variant: widget.variant,
      size: widget.size,
      scheme: theme.colorScheme,
      textTheme: theme.textTheme,
    ).merge(fieldTheme.defaultStyle).merge(widget.style);
  }

  void _syncMotion() {
    final OrionTextFieldStyle style = _resolve(Theme.of(context));
    _driver.springSpec =
        style.spring ?? OrionTextFieldPresets.defaultFocusSpring;
  }

  bool get _obscures => widget.type == OrionTextFieldType.password
      ? _obscured
      : widget.obscureText;

  bool get _startsObscured =>
      widget.obscureText || widget.type == OrionTextFieldType.password;

  TextInputType? get _keyboardType {
    if (widget.keyboardType != null) {
      return widget.keyboardType;
    }
    return switch (widget.type) {
      OrionTextFieldType.email => TextInputType.emailAddress,
      OrionTextFieldType.password => TextInputType.visiblePassword,
      OrionTextFieldType.number => TextInputType.number,
      OrionTextFieldType.phone => TextInputType.phone,
      OrionTextFieldType.url => TextInputType.url,
      OrionTextFieldType.multiline => TextInputType.multiline,
      OrionTextFieldType.text || OrionTextFieldType.search => null,
    };
  }

  TextInputAction? get _textInputAction {
    if (widget.textInputAction != null) {
      return widget.textInputAction;
    }
    return switch (widget.type) {
      OrionTextFieldType.multiline => TextInputAction.newline,
      OrionTextFieldType.search => TextInputAction.search,
      _ => null,
    };
  }

  bool get _autocorrect {
    return switch (widget.type) {
      OrionTextFieldType.email ||
      OrionTextFieldType.password ||
      OrionTextFieldType.url ||
      OrionTextFieldType.number ||
      OrionTextFieldType.phone => widget.autocorrect ?? false,
      _ => widget.autocorrect ?? true,
    };
  }

  bool get _suggestions {
    return switch (widget.type) {
      OrionTextFieldType.password => widget.enableSuggestions ?? false,
      _ => widget.enableSuggestions ?? true,
    };
  }

  Iterable<String>? get _autofillHints {
    if (widget.autofillHints != null) {
      return widget.autofillHints;
    }
    return switch (widget.type) {
      OrionTextFieldType.email => const <String>[AutofillHints.email],
      OrionTextFieldType.password => const <String>[AutofillHints.password],
      OrionTextFieldType.phone => const <String>[AutofillHints.telephoneNumber],
      OrionTextFieldType.url => const <String>[AutofillHints.url],
      _ => null,
    };
  }

  List<TextInputFormatter> get _formatters {
    final TextInputType? kb = _keyboardType;
    final bool isNumeric =
        widget.type == OrionTextFieldType.number ||
        (kb != null && kb.index == TextInputType.number.index);
    final bool allowDecimal = kb?.decimal ?? false;
    final bool allowSigned = kb?.signed ?? false;

    final TextInputFormatter? numericFormatter;
    if (!isNumeric) {
      numericFormatter = null;
    } else if (allowDecimal && allowSigned) {
      numericFormatter = FilteringTextInputFormatter.allow(
        RegExp(r'[0-9.,\-]'),
      );
    } else if (allowDecimal) {
      numericFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'));
    } else if (allowSigned) {
      numericFormatter = FilteringTextInputFormatter.allow(RegExp(r'[0-9\-]'));
    } else {
      numericFormatter = FilteringTextInputFormatter.digitsOnly;
    }

    return <TextInputFormatter>[
      ?numericFormatter,
      if (widget.type == OrionTextFieldType.phone)
        FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
      if (widget.maxLength != null)
        LengthLimitingTextInputFormatter(widget.maxLength),
      ...?widget.inputFormatters,
    ];
  }

  void _handleClear(FormFieldState<String> field) {
    if (!widget.enabled || widget.readOnly) return;
    _controller.clear();
    if (field.value != '') {
      field.didChange('');
    }
    widget.onChanged?.call('');
    widget.onCleared?.call();
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    }
  }

  void _handleFaceTap() {
    if (!widget.enabled) return;
    if (widget.onTap != null) {
      widget.onTap!();
      return;
    }
    if (!widget.readOnly) {
      _focusNode.requestFocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      key: _formFieldKey,
      initialValue: _initialFormValue,
      validator: widget.validator,
      onSaved: widget.onSaved,
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      onReset: _handleFormReset,
      builder: (FormFieldState<String> field) => _build(context, field),
    );
  }

  Widget _build(BuildContext context, FormFieldState<String> field) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionTextFieldStyle style = _resolve(theme);
    final bool enabled = widget.enabled;
    final bool isPickerMode = widget.readOnly && widget.onTap != null;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final String? errorText = widget.error != null && widget.error!.isNotEmpty
        ? widget.error
        : field.errorText;
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final String? caption = hasError ? errorText : widget.helper;
    final int charCount = _controller.text.characters.length;
    final String? counter = widget.maxLength == null
        ? null
        : '$charCount/${widget.maxLength}';
    final bool counterAtCap =
        widget.maxLength != null && charCount >= widget.maxLength!;

    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_hovered && enabled) WidgetState.hovered,
      if (hasError) WidgetState.error,
    };
    final Set<WidgetState> focusedStates = <WidgetState>{
      WidgetState.focused,
      if (!enabled) WidgetState.disabled,
      if (_hovered && enabled) WidgetState.hovered,
      if (hasError) WidgetState.error,
    };
    final Set<WidgetState> liveStates = _focusNode.hasFocus && enabled
        ? focusedStates
        : restingStates;

    final Color errorColor = style.errorColor ?? scheme.error;
    final Color fillRest =
        style.fillColor?.resolve(restingStates) ?? scheme.surface;
    final Color fillFocused =
        style.fillColor?.resolve(focusedStates) ?? fillRest;
    final Color borderRest =
        style.borderColor?.resolve(restingStates) ?? scheme.outline;
    final Color borderFocused =
        style.borderColor?.resolve(focusedStates) ?? scheme.primary;
    final double borderWidth = math.max(0.0, style.borderWidth ?? 1.0);
    final double focusedBorderWidth = math.max(
      borderWidth,
      style.focusedBorderWidth ?? (borderWidth + 0.5),
    );
    final double focusRingWidth = math.max(0.0, style.focusRingWidth ?? 0.0);
    final Color baseFocusRingColor = hasError
        ? errorColor.withValues(
            alpha: scheme.brightness == Brightness.dark ? 0.28 : 0.16,
          )
        : (style.focusRingColor ?? Colors.transparent);

    final Color textColor =
        style.textColor?.resolve(liveStates) ?? scheme.onSurface;
    final Color hintColor =
        style.hintColor?.resolve(liveStates) ?? scheme.onSurfaceVariant;
    final Color labelColor =
        style.labelColor?.resolve(liveStates) ??
        (hasError ? errorColor : textColor);
    final Color iconColor = style.iconColor?.resolve(liveStates) ?? hintColor;
    final double iconSize = math.max(12.0, style.iconSize ?? 18.0);

    final TextStyle textStyle = style.textStyle ?? const TextStyle();
    final TextStyle labelStyle =
        style.labelStyle ?? theme.textTheme.labelMedium ?? const TextStyle();
    final TextStyle captionStyle =
        style.captionStyle ?? theme.textTheme.bodySmall ?? const TextStyle();

    final EdgeInsets padding =
        (style.padding ??
                const EdgeInsets.symmetric(
                  horizontal: OrionSpacing.space12,
                  vertical: 12.0,
                ))
            .resolve(Directionality.of(context));

    final bool underline = widget.variant == OrionTextFieldVariant.underline;
    final BorderRadius? effectiveRadius = underline
        ? BorderRadius.zero
        : style.radius;

    // Crash-proof line & obscure guards: Flutter forbids multiline obscured
    // inputs and requires minLines <= maxLines (or both null when expands).
    final bool effectiveObscure = !widget.expands && _obscures;
    final int? effectiveMaxLines = widget.expands
        ? null
        : (effectiveObscure
              ? 1
              : (widget.maxLines ??
                    (widget.type == OrionTextFieldType.multiline ? null : 1)));
    final int? rawMinLines = widget.expands || effectiveObscure
        ? null
        : (widget.minLines ??
              (widget.type == OrionTextFieldType.multiline ? 3 : null));
    final int? effectiveMinLines =
        rawMinLines != null && effectiveMaxLines != null
        ? math.min(rawMinLines, effectiveMaxLines)
        : rawMinLines;
    final bool isMultiline =
        widget.expands || effectiveMaxLines == null || effectiveMaxLines > 1;

    final bool showPasswordAction =
        widget.type == OrionTextFieldType.password && widget.showPasswordToggle;
    final bool canShowClear =
        _effectiveShowClearButton && enabled && !widget.readOnly && _hasText;
    final bool hasInlineAction = showPasswordAction || canShowClear;

    final MouseCursor effectiveCursor =
        widget.mouseCursor ??
        (!enabled
            ? MouseCursor.defer
            : (isPickerMode
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.text));

    final Widget editor = Semantics(
      label: widget.semanticLabel ?? widget.label,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: enabled,
        readOnly: widget.readOnly,
        showCursor: widget.showCursor ?? (isPickerMode ? false : null),
        enableInteractiveSelection:
            widget.enableInteractiveSelection ?? (isPickerMode ? false : null),
        mouseCursor: effectiveCursor,
        onChanged: enabled
            ? (String value) {
                if (field.value != value) {
                  field.didChange(value);
                }
                widget.onChanged?.call(value);
              }
            : null,
        obscureText: effectiveObscure,
        obscuringCharacter: widget.obscuringCharacter,
        keyboardType: _keyboardType,
        textInputAction: _textInputAction,
        textCapitalization: widget.textCapitalization,
        textAlign: widget.textAlign,
        textAlignVertical: isMultiline
            ? TextAlignVertical.top
            : TextAlignVertical.center,
        textDirection: widget.textDirection,
        autocorrect: _autocorrect,
        enableSuggestions: _suggestions,
        autofillHints: _autofillHints,
        inputFormatters: _formatters,
        minLines: effectiveMinLines,
        maxLines: effectiveMaxLines,
        expands: widget.expands,
        onSubmitted: widget.onSubmitted,
        onEditingComplete: widget.onEditingComplete,
        onTap: widget.onTap,
        onTapOutside: widget.onTapOutside,
        autofocus: widget.autofocus,
        scrollController: widget.scrollController,
        scrollPadding: widget.scrollPadding,
        undoController: widget.undoController,
        contextMenuBuilder: widget.contextMenuBuilder,
        style: textStyle.copyWith(color: textColor),
        cursorColor: style.cursorColor ?? scheme.primary,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: textStyle.copyWith(color: hintColor),
          isDense: true,
          contentPadding: EdgeInsets.only(
            top: padding.top,
            bottom: padding.bottom,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );

    final double trailingOuterPad = (hasInlineAction && widget.suffix == null)
        ? math.max(OrionSpacing.space4, padding.right - 6.0)
        : padding.right;

    final Widget affixRow = Padding(
      padding: EdgeInsets.only(left: padding.left, right: trailingOuterPad),
      child: IconTheme.merge(
        data: IconThemeData(color: iconColor, size: iconSize),
        child: DefaultTextStyle.merge(
          style: textStyle.copyWith(color: iconColor),
          child: Row(
            crossAxisAlignment: isMultiline
                ? CrossAxisAlignment.start
                : CrossAxisAlignment.center,
            children: <Widget>[
              if (widget.prefix != null) ...<Widget>[
                Padding(
                  padding: isMultiline
                      ? EdgeInsets.only(top: padding.top)
                      : EdgeInsets.zero,
                  child: widget.prefix!,
                ),
                const SizedBox(width: OrionSpacing.space8),
              ],
              Expanded(child: editor),
              if (_effectiveShowClearButton)
                Padding(
                  padding: isMultiline
                      ? EdgeInsets.only(top: math.max(0.0, padding.top - 6.0))
                      : EdgeInsets.zero,
                  child: _AnimatedClearSlot(
                    visible: canShowClear,
                    reducedMotion: reduced,
                    color: iconColor,
                    iconSize: iconSize,
                    onPressed: () => _handleClear(field),
                  ),
                ),
              if (showPasswordAction) ...<Widget>[
                const SizedBox(width: OrionSpacing.space4),
                Padding(
                  padding: isMultiline
                      ? EdgeInsets.only(top: math.max(0.0, padding.top - 6.0))
                      : EdgeInsets.zero,
                  child: _FieldActionButton(
                    key: orionTextFieldPasswordToggleKey,
                    icon: _obscured
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    iconSize: iconSize,
                    color: iconColor,
                    semanticLabel: _obscured
                        ? 'Show password'
                        : 'Hide password',
                    toggled: !_obscured,
                    enabled: enabled,
                    onPressed: enabled
                        ? () => setState(() => _obscured = !_obscured)
                        : null,
                  ),
                ),
              ],
              if (widget.suffix != null) ...<Widget>[
                const SizedBox(width: OrionSpacing.space8),
                Padding(
                  padding: isMultiline
                      ? EdgeInsets.only(top: padding.top)
                      : EdgeInsets.zero,
                  child: widget.suffix!,
                ),
              ],
            ],
          ),
        ),
      ),
    );

    final Widget faceBox = MouseRegion(
      cursor: effectiveCursor,
      onEnter: (_) {
        if (mounted && enabled && !_hovered) {
          setState(() => _hovered = true);
        }
      },
      onExit: (_) {
        if (mounted && _hovered) {
          setState(() => _hovered = false);
        }
      },
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: enabled ? _handleFaceTap : null,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: math.max(
              0.0,
              style.height ?? OrionSizing.controlHeightLarge,
            ),
          ),
          child: AnimatedBuilder(
            animation: _driver,
            child: affixRow,
            builder: (BuildContext context, Widget? child) {
              final double progress = _driver.value.clamp(0.0, 1.0);
              final Color liveFill = Color.lerp(
                fillRest,
                fillFocused,
                progress,
              )!;
              final Color liveBorder = Color.lerp(
                borderRest,
                borderFocused,
                progress,
              )!;
              final double liveWidth =
                  borderWidth + (focusedBorderWidth - borderWidth) * progress;
              final bool paintHalo =
                  !underline &&
                  enabled &&
                  focusRingWidth > 0 &&
                  baseFocusRingColor.a > 0 &&
                  progress > 0.001;

              return DecoratedBox(
                key: orionTextFieldFaceKey,
                decoration: BoxDecoration(
                  color: liveFill,
                  borderRadius: effectiveRadius,
                  border: underline
                      ? Border(
                          bottom: BorderSide(
                            color: liveBorder,
                            width: liveWidth,
                          ),
                        )
                      : (liveWidth > 0
                            ? Border.all(color: liveBorder, width: liveWidth)
                            : null),
                  boxShadow: paintHalo
                      ? <BoxShadow>[
                          BoxShadow(
                            color: baseFocusRingColor.withValues(
                              alpha: baseFocusRingColor.a * progress,
                            ),
                            spreadRadius: focusRingWidth * progress,
                            blurRadius: 0.0,
                          ),
                        ]
                      : null,
                ),
                child: child,
              );
            },
          ),
        ),
      ),
    );

    final Widget? labelWidget = widget.label == null
        ? null
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: enabled ? _handleFaceTap : null,
            child: ExcludeSemantics(
              child: Text.rich(
                TextSpan(
                  text: widget.label!,
                  style: labelStyle.copyWith(color: labelColor),
                  children: <InlineSpan>[
                    if (widget.required)
                      TextSpan(
                        text: ' *',
                        style: labelStyle.copyWith(color: errorColor),
                      ),
                  ],
                ),
              ),
            ),
          );

    return Column(
      mainAxisSize: widget.expands ? MainAxisSize.max : MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (labelWidget != null) ...<Widget>[
          labelWidget,
          SizedBox(height: style.labelGap ?? 6.0),
        ],
        if (widget.expands) Expanded(child: faceBox) else faceBox,
        if (caption != null ||
            counter != null ||
            widget.reserveCaption) ...<Widget>[
          SizedBox(height: style.captionGap ?? 6.0),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Semantics(
                  liveRegion: hasError,
                  child: Text(
                    caption ?? '',
                    style: captionStyle.copyWith(
                      color: hasError ? errorColor : scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
              if (counter != null) ...<Widget>[
                const SizedBox(width: OrionSpacing.space8),
                Text(
                  counter,
                  style: captionStyle.copyWith(
                    fontFeatures: const <FontFeature>[
                      FontFeature.tabularFigures(),
                    ],
                    color: counterAtCap ? errorColor : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// Smoothly reveals or collapses the inline clear button without layout jumps.
class _AnimatedClearSlot extends StatelessWidget {
  const _AnimatedClearSlot({
    required this.visible,
    required this.reducedMotion,
    required this.color,
    required this.iconSize,
    required this.onPressed,
  });

  final bool visible;
  final bool reducedMotion;
  final Color color;
  final double iconSize;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final Widget button = visible
        ? Padding(
            padding: const EdgeInsets.only(left: OrionSpacing.space4),
            child: _FieldActionButton(
              key: orionTextFieldClearButtonKey,
              icon: Icons.close_rounded,
              iconSize: math.max(14.0, iconSize - 2.0),
              color: color,
              semanticLabel: 'Clear text',
              enabled: true,
              onPressed: onPressed,
            ),
          )
        : const SizedBox.shrink();

    if (reducedMotion) {
      return button;
    }

    return AnimatedSize(
      duration: const Duration(milliseconds: 160),
      curve: Curves.easeOutCubic,
      alignment: Alignment.center,
      child: AnimatedOpacity(
        opacity: visible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 120),
        child: button,
      ),
    );
  }
}

/// Tactile inline action button (password reveal / clear text) sized cleanly
/// to fit `small` (40 pt), `medium` (48 pt), and `large` (56 pt) inputs without
/// stretching field height.
class _FieldActionButton extends StatefulWidget {
  const _FieldActionButton({
    super.key,
    required this.icon,
    required this.iconSize,
    required this.color,
    required this.semanticLabel,
    required this.enabled,
    required this.onPressed,
    this.toggled,
  });

  final IconData icon;
  final double iconSize;
  final Color color;
  final String semanticLabel;
  final bool enabled;
  final VoidCallback? onPressed;
  final bool? toggled;

  @override
  State<_FieldActionButton> createState() => _FieldActionButtonState();
}

class _FieldActionButtonState extends State<_FieldActionButton> {
  bool _hovered = false;

  @override
  void didUpdateWidget(_FieldActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _hovered) {
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final Color hoverFill = scheme.onSurface.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.10 : 0.06,
    );

    return Semantics(
      button: true,
      enabled: widget.enabled,
      toggled: widget.toggled,
      label: widget.semanticLabel,
      child: Tooltip(
        message: widget.semanticLabel,
        child: MouseRegion(
          cursor: widget.enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: (_) {
            if (mounted && widget.enabled && !_hovered) {
              setState(() => _hovered = true);
            }
          },
          onExit: (_) {
            if (mounted && _hovered) {
              setState(() => _hovered = false);
            }
          },
          child: OrionPressable(
            onTap: widget.onPressed,
            pressedScale: 0.90,
            hapticType: OrionHapticType.selectionClick,
            child: SizedBox(
              width: 32.0,
              height: 32.0,
              child: _hovered && widget.enabled
                  ? DecoratedBox(
                      decoration: BoxDecoration(
                        color: hoverFill,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        widget.icon,
                        size: widget.iconSize,
                        color: widget.color,
                      ),
                    )
                  : Icon(
                      widget.icon,
                      size: widget.iconSize,
                      color: widget.color,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}
