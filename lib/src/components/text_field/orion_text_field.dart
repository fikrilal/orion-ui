import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/text_field/orion_text_field_presets.dart';
import 'package:orion_ui/src/components/text_field/orion_text_field_style.dart';
import 'package:orion_ui/src/components/text_field/orion_text_field_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The field's face.
enum OrionTextFieldVariant {
  /// A surface face with a hairline that darkens on focus. The default.
  outline,

  /// A container-filled face with no resting hairline.
  filled,

  /// A transparent face with a bottom line, Telegram's classic.
  underline,
}

/// The field's size step.
enum OrionTextFieldSize { small, medium, large }

/// The field's behaviour preset.
///
/// A type derives the keyboard, the action, autocorrect and suggestions, the
/// autofill hints and the formatters (a numeric filter, a phone filter, and a
/// length limit when `maxLength` is set). Explicit parameters always win.
enum OrionTextFieldType {
  /// Free text.
  text,

  /// An email address: email keyboard, no autocorrect, email autofill.
  email,

  /// A password: obscured with a reveal toggle, no suggestions, password
  /// autofill.
  password,

  /// A number: the number keyboard and a digits-only filter.
  number,

  /// A phone number: the phone keyboard and a `+ - space ( )` filter.
  phone,

  /// A URL: url keyboard, no autocorrect.
  url,

  /// Multiple lines: the multiline keyboard, a newline action and a face that
  /// grows with its content.
  multiline,

  /// A search field: a search action and suggestions kept on.
  search,
}

/// A single-line field. The parent owns the string.
///
/// The hairline carries focus: it darkens to the focus colour and steps half a
/// point wider on a critically damped, clamped spring, and losing focus
/// retreats the same way rather than flashing back on. The caret stays the
/// platform caret. A non-empty [error] replaces [helper] and paints the border
/// with the error colour; a [validator] runs through a [FormField], so a
/// [Form] can validate the field and its message paints the same way. A
/// [maxLength] adds a counter at the caption row's end.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionTextFieldPresets] for the [variant] and [size], the ambient
/// [OrionTextFieldTheme], and the [style] passed here. Anything an override
/// does not name falls through.
class OrionTextField extends StatefulWidget {
  /// Creates a single-line field.
  const OrionTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
    this.readOnly = false,
    this.variant = OrionTextFieldVariant.outline,
    this.size = OrionTextFieldSize.medium,
    this.type = OrionTextFieldType.text,
    this.label,
    this.hint,
    this.error,
    this.helper,
    this.obscureText = false,
    this.showPasswordToggle = true,
    this.keyboardType,
    this.textInputAction,
    this.autocorrect,
    this.enableSuggestions,
    this.autofillHints,
    this.inputFormatters,
    this.maxLength,
    this.maxLines,
    this.prefix,
    this.suffix,
    this.reserveCaption = false,
    this.validator,
    this.autovalidateMode,
    this.onSubmitted,
    this.onTap,
    this.autofocus = false,
    this.style,
  });

  /// Optional controller. When omitted, the field owns one.
  final TextEditingController? controller;

  /// Optional focus node. When omitted, the field owns one.
  final FocusNode? focusNode;

  /// Called with the field text after each edit.
  final ValueChanged<String>? onChanged;

  /// False mutes the field and ignores edits.
  final bool enabled;

  /// True keeps the text but stops edits; pair it with [onTap] for a picker
  /// face that opens a sheet instead of the keyboard.
  final bool readOnly;

  /// The face. Defaults to [OrionTextFieldVariant.outline].
  final OrionTextFieldVariant variant;

  /// The size step. Defaults to [OrionTextFieldSize.medium].
  final OrionTextFieldSize size;

  /// The behaviour preset. Defaults to [OrionTextFieldType.text]. Explicit
  /// parameters over [keyboardType] and the like always win.
  final OrionTextFieldType type;

  /// Text shown above the face.
  final String? label;

  /// Placeholder shown while the field is empty.
  final String? hint;

  /// Non-empty paints an error border and replaces [helper]; it wins over a
  /// [validator]'s message.
  final String? error;

  /// Quiet note under the face. Hidden while [error] is non-empty.
  final String? helper;

  /// Hides the characters, for a password.
  final bool obscureText;

  /// Shows the reveal toggle on a [OrionTextFieldType.password] field.
  final bool showPasswordToggle;

  /// Keyboard layout override; the [type] derives it otherwise.
  final TextInputType? keyboardType;

  /// Action button override; the [type] derives it otherwise.
  final TextInputAction? textInputAction;

  /// Autocorrect override; the [type] derives it otherwise.
  final bool? autocorrect;

  /// Suggestions override; the [type] derives it otherwise.
  final bool? enableSuggestions;

  /// Autofill hints override; the [type] derives them otherwise.
  final Iterable<String>? autofillHints;

  /// Extra formatters, applied after the ones the [type] derives.
  final List<TextInputFormatter>? inputFormatters;

  /// Caps the text and shows a `n/max` counter at the caption row's end.
  final int? maxLength;

  /// Line cap override; a [OrionTextFieldType.multiline] field grows with its
  /// content otherwise.
  final int? maxLines;

  /// Leading content inside the face, before the text.
  final Widget? prefix;

  /// Trailing content inside the face, after the text (and after the password
  /// toggle, when one shows).
  final Widget? suffix;

  /// Reserves the caption row's line even when nothing is captioned, so an
  /// error appearing later cannot reflow what is below the field.
  final bool reserveCaption;

  /// Validates the text through the field's [FormField]; the message paints
  /// like [error] unless [error] is set.
  final FormFieldValidator<String>? validator;

  /// When the field validates itself. Off by default.
  final AutovalidateMode? autovalidateMode;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Called when the face is tapped; defaults to focusing the field.
  final VoidCallback? onTap;

  /// Whether the field requests focus on first build.
  final bool autofocus;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionTextFieldTheme]. Only the fields set here change.
  final OrionTextFieldStyle? style;

  @override
  State<OrionTextField> createState() => _OrionTextFieldState();
}

class _OrionTextFieldState extends State<OrionTextField>
    with SingleTickerProviderStateMixin {
  /// Focus is not a press: the line should arrive, not bounce. The reference
  /// corpus's FOCUS_SPRING is critically damped and applied to both focus and
  /// blur, and clamping keeps the colour and the half-point width step from
  /// overshooting their targets.
  static const OrionSpringSpec _focus = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
    clampOvershoot: true,
  );

  late final OrionSpringDriver _driver;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  late bool _obscured;
  bool _ownsController = false;
  bool _ownsFocus = false;
  bool _focusBound = false;
  bool _controllerBound = false;

  @override
  void initState() {
    super.initState();
    _obscured = _startsObscured;
    _bindController(widget.controller);
    _bindFocus(widget.focusNode);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: _focus,
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
    }
    if (widget.obscureText != oldWidget.obscureText ||
        widget.type != oldWidget.type) {
      _obscured = _startsObscured;
    }
    var retarget = false;
    if (widget.focusNode != oldWidget.focusNode) {
      _bindFocus(widget.focusNode);
      retarget = true;
    }
    if (widget.enabled != oldWidget.enabled) {
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

  double get _target => widget.enabled && _focusNode.hasFocus ? 1 : 0;

  void _bindController(TextEditingController? incoming) {
    if (_controllerBound) {
      _controller.removeListener(_onControllerChanged);
      if (_ownsController) {
        _controller.dispose();
      }
    }
    _ownsController = incoming == null;
    _controller = incoming ?? TextEditingController();
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

  /// The counter is the only reason the field rebuilds with its text; every
  /// other change is the host's to react to.
  void _onControllerChanged() {
    if (widget.maxLength != null && mounted) {
      setState(() {});
    }
  }

  void _onFocus() {
    _sync();
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
    _driver.springSpec = style.spring ?? _focus;
  }

  bool get _obscures => widget.type == OrionTextFieldType.password
      ? _obscured
      : widget.obscureText;

  /// A password type starts hidden; the toggle owns it from there.
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
      _ => null,
    };
  }

  /// The digits filter follows the effective keyboard, so an explicit numeric
  /// [keyboardType] without a [type] is filtered too.
  List<TextInputFormatter> get _formatters => <TextInputFormatter>[
    if (widget.type == OrionTextFieldType.number ||
        _keyboardType == TextInputType.number)
      FilteringTextInputFormatter.digitsOnly,
    if (widget.type == OrionTextFieldType.phone)
      FilteringTextInputFormatter.allow(RegExp(r'[0-9+\-\s()]')),
    if (widget.maxLength != null)
      LengthLimitingTextInputFormatter(widget.maxLength),
    ...?widget.inputFormatters,
  ];

  int? get _maxLines =>
      widget.maxLines ??
      (widget.type == OrionTextFieldType.multiline ? null : 1);

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      initialValue: _controller.text,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      builder: (FormFieldState<String> field) => _build(context, field),
    );
  }

  Widget _build(BuildContext context, FormFieldState<String> field) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionTextFieldStyle style = _resolve(theme);
    final bool enabled = widget.enabled;
    final String? errorText = widget.error != null && widget.error!.isNotEmpty
        ? widget.error
        : field.errorText;
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final String? caption = hasError ? errorText : widget.helper;
    final String? counter = widget.maxLength == null
        ? null
        : '${_controller.text.characters.length}/${widget.maxLength}';
    final bool counterAtCap =
        widget.maxLength != null &&
        _controller.text.characters.length >= widget.maxLength!;

    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (hasError) WidgetState.error,
    };
    final Set<WidgetState> focusedStates = <WidgetState>{
      WidgetState.focused,
      ...restingStates,
    };
    final Color fill =
        style.fillColor?.resolve(restingStates) ?? scheme.surface;
    final Color borderRest =
        style.borderColor?.resolve(restingStates) ?? scheme.outline;
    final Color borderFocused =
        style.borderColor?.resolve(focusedStates) ?? scheme.primary;
    final double borderWidth = style.borderWidth ?? 1;
    final Color textColor =
        style.textColor?.resolve(restingStates) ?? scheme.onSurface;
    final Color hintColor =
        style.hintColor?.resolve(restingStates) ?? scheme.onSurfaceVariant;
    final TextStyle textStyle = style.textStyle ?? const TextStyle();
    final TextStyle labelStyle =
        style.labelStyle ?? theme.textTheme.labelMedium ?? const TextStyle();
    final TextStyle captionStyle =
        style.captionStyle ?? theme.textTheme.bodySmall ?? const TextStyle();
    final EdgeInsets padding =
        (style.padding ??
                const EdgeInsets.symmetric(horizontal: OrionSpacing.space12))
            .resolve(Directionality.of(context));
    final bool underline = widget.variant == OrionTextFieldVariant.underline;

    final Widget editor = Semantics(
      label: widget.label,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        enabled: enabled,
        readOnly: widget.readOnly,
        onChanged: enabled
            ? (String value) {
                field.didChange(value);
                widget.onChanged?.call(value);
              }
            : null,
        obscureText: _obscures,
        obscuringCharacter: '•',
        keyboardType: _keyboardType,
        textInputAction: _textInputAction,
        autocorrect: _autocorrect,
        enableSuggestions: _suggestions,
        autofillHints: _autofillHints,
        inputFormatters: _formatters,
        maxLines: _maxLines,
        onSubmitted: widget.onSubmitted,
        onTap: widget.onTap,
        autofocus: widget.autofocus,
        style: textStyle.copyWith(color: textColor),
        cursorColor: style.cursorColor ?? scheme.onSurface,
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: textStyle.copyWith(color: hintColor),
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: labelStyle.copyWith(color: textColor),
            ),
          ),
          SizedBox(height: style.labelGap ?? OrionSpacing.space8),
        ],
        MouseRegion(
          cursor: enabled ? SystemMouseCursors.text : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            excludeFromSemantics: true,
            onTap: enabled
                ? (widget.onTap ?? () => _focusNode.requestFocus())
                : null,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: style.height ?? OrionSizing.controlHeightLarge,
              ),
              child: AnimatedBuilder(
                animation: _driver,
                child: Padding(
                  padding: padding,
                  child: Row(
                    children: <Widget>[
                      if (widget.prefix != null) ...<Widget>[
                        widget.prefix!,
                        const SizedBox(width: OrionSpacing.space8),
                      ],
                      Expanded(child: Center(child: editor)),
                      if (widget.type == OrionTextFieldType.password &&
                          widget.showPasswordToggle) ...<Widget>[
                        const SizedBox(width: OrionSpacing.space8),
                        _FieldToggle(
                          obscured: _obscured,
                          color: hintColor,
                          semanticsEnabled: enabled,
                          onPressed: enabled
                              ? () => setState(() => _obscured = !_obscured)
                              : null,
                        ),
                      ],
                      if (widget.suffix != null) ...<Widget>[
                        const SizedBox(width: OrionSpacing.space8),
                        widget.suffix!,
                      ],
                    ],
                  ),
                ),
                builder: (BuildContext context, Widget? child) {
                  final double progress = _driver.value.clamp(0.0, 1.0);
                  final Color borderColor = Color.lerp(
                    borderRest,
                    borderFocused,
                    progress,
                  )!;
                  final double width = borderWidth + 0.5 * progress;
                  return DecoratedBox(
                    decoration: BoxDecoration(
                      color: fill,
                      borderRadius: style.radius,
                      border: underline
                          ? Border(
                              bottom: BorderSide(
                                color: borderColor,
                                width: width,
                              ),
                            )
                          : Border.all(color: borderColor, width: width),
                    ),
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
        if (caption != null ||
            counter != null ||
            widget.reserveCaption) ...<Widget>[
          SizedBox(height: style.captionGap ?? OrionSpacing.space8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Text(
                  caption ?? '',
                  style: captionStyle.copyWith(
                    color: hasError ? scheme.error : scheme.onSurfaceVariant,
                  ),
                ),
              ),
              if (counter != null)
                Text(
                  counter,
                  style: captionStyle.copyWith(
                    color: counterAtCap
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }
}

/// The password reveal toggle: a 44 pt target that compresses on press like
/// every other kit control, with a toggled semantics state.
///
/// The two labels are the kit's English defaults; a host that localizes hides
/// this toggle (`showPasswordToggle: false`) and composes its own in `suffix`.
class _FieldToggle extends StatelessWidget {
  const _FieldToggle({
    required this.obscured,
    required this.color,
    required this.semanticsEnabled,
    required this.onPressed,
  });

  final bool obscured;
  final Color color;
  final bool semanticsEnabled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: semanticsEnabled,
      toggled: !obscured,
      label: obscured ? 'Show password' : 'Hide password',
      child: OrionPressable(
        onTap: onPressed,
        pressedScale: 0.9,
        hapticType: OrionHapticType.selectionClick,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            obscured
                ? Icons.visibility_outlined
                : Icons.visibility_off_outlined,
            size: 20,
            color: color,
          ),
        ),
      ),
    );
  }
}
