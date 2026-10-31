import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/otp/orion_otp_controller.dart';
import 'package:orion_ui/src/components/otp/orion_otp_presets.dart';
import 'package:orion_ui/src/components/otp/orion_otp_style.dart';
import 'package:orion_ui/src/components/otp/orion_otp_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Validation and visual status for [OrionOtpField].
enum OrionOtpStatus {
  /// Default resting input state.
  idle,

  /// Error state: tints slots with the error role and triggers horizontal shake
  /// physics.
  error,

  /// Success state: tints slots with the semantic success role.
  success,
}

/// Visual face of an [OrionOtpField].
enum OrionOtpVariant {
  /// Rounded bordered slot boxes. The default.
  outline,

  /// Soft container-filled tiles that highlight with a border on focus, error,
  /// or success.
  filled,

  /// Minimalist transparent slots with a bottom underline.
  underline,
}

/// A physics-driven One-Time Password and PIN passcode field.
///
/// Features:
/// - Single invisible [TextField] architecture capturing native keyboard
///   events, hardware keystrokes, SMS autofill, and formatted clipboard paste
///   (e.g. `"123-456"` or `"123 456"`).
/// - Mobile long-press native Paste toolbar without phantom selection handles.
/// - Three slot faces via [OrionOtpVariant]: `outline`, `filled`, and
///   `underline`, plus optional [label], [helper], and [error] captions.
/// - Responsive width scaling on narrow viewports so 6-8 digit or grouped codes
///   never overflow.
/// - Tactile micro-bounce slot spring physics upon character entry.
/// - Isolated breathing caret bar in the active slot (static under reduced
///   motion, stopped when unfocused, read-only, disabled, or full).
/// - Delayed secure dot masking (`delayedObscure: true`) for transaction PIN
///   privacy, with obscured accessibility semantics so PIN digits never leak.
/// - Damped sinusoidal horizontal error shake physics on invalid submission.
class OrionOtpField extends StatefulWidget {
  const OrionOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.onSubmitted,
    this.status = OrionOtpStatus.idle,
    this.variant = OrionOtpVariant.outline,
    this.label,
    this.helper,
    this.error,
    this.placeholder,
    this.obscureText = false,
    this.delayedObscure = true,
    this.obscureCharacter = '●',
    this.delayedObscureDuration = const Duration(milliseconds: 400),
    this.digitsOnly = true,
    this.keyboardType,
    this.textInputAction = TextInputAction.done,
    this.textCapitalization = TextCapitalization.none,
    this.inputFormatters,
    this.autofillHints,
    this.groupLength,
    this.groupSeparator,
    this.autoFocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.semanticLabel,
    this.style,
  }) : assert(length > 0, 'length must be greater than zero'),
       assert(
         groupLength == null || groupLength > 0,
         'groupLength must be greater than zero if specified',
       );

  /// Number of code slots to display (typically 4, 6, or 8).
  final int length;

  /// Optional programmatic controller.
  final OrionOtpController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Callback invoked on every text change.
  final ValueChanged<String>? onChanged;

  /// Callback fired when all slots are completely filled.
  final ValueChanged<String>? onCompleted;

  /// Callback fired when the user presses the keyboard's submit/done action.
  final ValueChanged<String>? onSubmitted;

  /// Visual status of the field (idle, error, success). A non-empty [error]
  /// string also activates error styling automatically.
  final OrionOtpStatus status;

  /// Visual face of the slots (`outline`, `filled`, or `underline`).
  final OrionOtpVariant variant;

  /// Optional label shown above the OTP slots.
  final String? label;

  /// Optional helper caption shown beneath the slots when [error] is empty.
  final String? helper;

  /// Optional error message shown beneath the slots. When non-empty, activates
  /// error borders, subtle error tint, and error shake automatically.
  final String? error;

  /// Optional single-character placeholder shown inside empty inactive slots
  /// (e.g. `'–'` or `'○'`).
  final String? placeholder;

  /// Whether characters are obscured for security.
  final bool obscureText;

  /// When true, displays newly typed characters for a brief peek duration
  /// before masking into [obscureCharacter].
  final bool delayedObscure;

  /// Character displayed when obscured (default `'●'`).
  final String obscureCharacter;

  /// Duration to show the raw character before masking when [delayedObscure]
  /// is true.
  final Duration delayedObscureDuration;

  /// Whether only numeric digits `0-9` are accepted.
  final bool digitsOnly;

  /// Optional keyboard type override. Defaults to [TextInputType.number] when
  /// [digitsOnly] is true, else [TextInputType.text].
  final TextInputType? keyboardType;

  /// Keyboard action button (defaults to [TextInputAction.done]).
  final TextInputAction textInputAction;

  /// Text capitalization for non-numeric codes.
  final TextCapitalization textCapitalization;

  /// Optional extra input formatters applied before the length limit.
  final List<TextInputFormatter>? inputFormatters;

  /// Optional autofill hints. Defaults to `[AutofillHints.oneTimeCode]` when
  /// [obscureText] is false and `null` when [obscureText] is true (so secret
  /// transaction PINs do not prompt SMS OTP autofill).
  final Iterable<String>? autofillHints;

  /// Optional slot grouping length (e.g. 3 splits 6 slots into 3 + 3).
  final int? groupLength;

  /// Optional separator widget rendered between slot groups.
  final Widget? groupSeparator;

  /// Whether to automatically focus the field and request keyboard.
  final bool autoFocus;

  /// Whether the field is interactable.
  final bool enabled;

  /// Whether the field can be focused and read without accepting edits.
  final bool readOnly;

  /// Optional screen-reader label override.
  final String? semanticLabel;

  /// Instance style overrides.
  final OrionOtpStyle? style;

  /// Whether caret breathing is replaced with a static visible caret.
  static bool? debugDeterministicCaret;

  @override
  State<OrionOtpField> createState() => _OrionOtpFieldState();
}

class _OrionOtpFieldState extends State<OrionOtpField>
    with TickerProviderStateMixin {
  late final TextEditingController _textEditingController;
  late FocusNode _focusNode;

  OrionOtpController? _internalController;
  OrionOtpController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionOtpController());

  // Shake spring driver
  late final OrionSpringDriver _shakeDriver;

  // Context menu for mobile long-press Paste
  final ContextMenuController _contextMenuController = ContextMenuController();

  // Track delayed obscure peek timers per slot
  final Map<int, Timer> _peekTimers = <int, Timer>{};
  final Set<int> _revealedSlots = <int>{};

  // Micro-bounce springs per slot
  final Map<int, OrionSpringDriver> _slotDrivers = <int, OrionSpringDriver>{};

  String _lastText = '';
  bool _completedFired = false;
  bool _hovered = false;

  bool get _hasError =>
      widget.status == OrionOtpStatus.error ||
      (widget.error != null && widget.error!.isNotEmpty);

  OrionOtpStatus get _effectiveStatus =>
      _hasError ? OrionOtpStatus.error : widget.status;

  List<TextInputFormatter> _buildInputFormatters() => <TextInputFormatter>[
    if (widget.digitsOnly) FilteringTextInputFormatter.digitsOnly,
    ...?widget.inputFormatters,
    LengthLimitingTextInputFormatter(widget.length),
  ];

  /// Applies the exact live [TextInputFormatter] chain so programmatic writes,
  /// clipboard pastes (e.g. `"123-456"`), and length changes stay consistent.
  String _sanitize(String raw) {
    TextEditingValue value = TextEditingValue(
      text: raw,
      selection: TextSelection.collapsed(offset: raw.length),
    );
    for (final TextInputFormatter formatter in _buildInputFormatters()) {
      value = formatter.formatEditUpdate(TextEditingValue.empty, value);
    }
    return value.text;
  }

  void _setTextWithEndSelection(String text) {
    _textEditingController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _clearAllPeeks() {
    for (final Timer timer in _peekTimers.values) {
      timer.cancel();
    }
    _peekTimers.clear();
    _revealedSlots.clear();
  }

  void _pruneSlotsBeyondLength() {
    final List<int> stalePeeks = _peekTimers.keys
        .where((int i) => i >= widget.length)
        .toList();
    for (final int i in stalePeeks) {
      _peekTimers.remove(i)?.cancel();
      _revealedSlots.remove(i);
    }
    final List<int> staleDrivers = _slotDrivers.keys
        .where((int i) => i >= widget.length)
        .toList();
    for (final int i in staleDrivers) {
      _slotDrivers.remove(i)?.dispose();
    }
  }

  @override
  void initState() {
    super.initState();
    final String initial = _sanitize(widget.controller?.value ?? '');
    if (widget.controller != null && widget.controller!.value != initial) {
      widget.controller!.value = initial;
    }
    _textEditingController = TextEditingController.fromValue(
      TextEditingValue(
        text: initial,
        selection: TextSelection.collapsed(offset: initial.length),
      ),
    );
    _lastText = initial;
    _completedFired = initial.length == widget.length;
    _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'OrionOtpField');

    _shakeDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: const OrionSpringSpec(stiffness: 900.0, dampingRatio: 0.28),
    );

    _attachController(_effectiveController);
    _effectiveController.addListener(_handleControllerChanged);
    _textEditingController.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);

    if (_hasError) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _shake());
    }
  }

  @override
  void didUpdateWidget(OrionOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.controller != oldWidget.controller) {
      final OrionOtpController? previous =
          oldWidget.controller ?? _internalController;
      previous?.removeListener(_handleControllerChanged);
      previous?.detach();

      if (oldWidget.controller == null && widget.controller != null) {
        _internalController?.dispose();
        _internalController = null;
      }

      final OrionOtpController next = _effectiveController;
      _attachController(next);
      next.addListener(_handleControllerChanged);

      final String synced = _sanitize(next.value);
      if (next.value != synced) {
        next.value = synced;
      }
      if (_textEditingController.text != synced) {
        _clearAllPeeks();
        _lastText = synced;
        _completedFired = synced.length == widget.length;
        _setTextWithEndSelection(synced);
      }
    }

    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.removeListener(_handleFocusChanged);
        _focusNode.dispose();
      } else {
        oldWidget.focusNode!.removeListener(_handleFocusChanged);
      }
      _focusNode = widget.focusNode ?? FocusNode(debugLabel: 'OrionOtpField');
      _focusNode.addListener(_handleFocusChanged);
    }

    if (widget.length != oldWidget.length ||
        widget.digitsOnly != oldWidget.digitsOnly) {
      _pruneSlotsBeyondLength();
      final String clamped = _sanitize(_textEditingController.text);
      if (clamped != _textEditingController.text) {
        _setTextWithEndSelection(clamped);
      }
    }

    if ((!widget.obscureText || !widget.delayedObscure) &&
        _revealedSlots.isNotEmpty) {
      _clearAllPeeks();
    }

    final bool oldHasError =
        oldWidget.status == OrionOtpStatus.error ||
        (oldWidget.error != null && oldWidget.error!.isNotEmpty);
    if (!oldHasError && _hasError) {
      _shake();
    }
  }

  @override
  void dispose() {
    _contextMenuController.remove();
    _clearAllPeeks();

    for (final OrionSpringDriver driver in _slotDrivers.values) {
      driver.dispose();
    }
    _slotDrivers.clear();

    _shakeDriver.dispose();

    _textEditingController.removeListener(_handleTextChanged);
    _textEditingController.dispose();

    _focusNode.removeListener(_handleFocusChanged);
    if (widget.focusNode == null) {
      _focusNode.dispose();
    }

    _effectiveController.removeListener(_handleControllerChanged);
    _effectiveController.detach();
    _internalController?.dispose();
    super.dispose();
  }

  void _handleControllerChanged() {
    final String sanitized = _sanitize(_effectiveController.value);
    if (_effectiveController.value != sanitized) {
      _effectiveController.value = sanitized;
    }
    if (_textEditingController.text != sanitized) {
      _setTextWithEndSelection(sanitized);
    }
  }

  void _attachController(OrionOtpController controller) {
    controller.attach(
      onShake: _shake,
      onFocus: () => _focusNode.requestFocus(),
      onUnfocus: () => _focusNode.unfocus(),
      onClear: () {
        _contextMenuController.remove();
        _clearAllPeeks();
        _setTextWithEndSelection('');
      },
    );
  }

  void _shake() {
    if (!mounted) return;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) return;

    final ThemeData theme = Theme.of(context);
    final OrionOtpStyle style = _resolveStyle(theme);
    final OrionSpringSpec shakeSpec =
        style.shakeSpringSpec ??
        const OrionSpringSpec(stiffness: 900.0, dampingRatio: 0.28);

    OrionHaptics.trigger(OrionTheme.of(context).impactHaptic);
    _shakeDriver.springSpec = shakeSpec;
    _shakeDriver.retarget(0.0, velocity: 380.0);
  }

  void _handleFocusChanged() {
    if (!_focusNode.hasFocus) {
      _contextMenuController.remove();
    } else {
      // Pin selection at end whenever focused so edits always append/delete
      // predictably at the trailing active slot.
      final String text = _textEditingController.text;
      if (_textEditingController.selection.baseOffset != text.length ||
          _textEditingController.selection.extentOffset != text.length) {
        _setTextWithEndSelection(text);
      }
    }
    setState(() {});
  }

  void _handleTextChanged() {
    final String current = _textEditingController.text;
    if (current == _lastText) return;

    _contextMenuController.remove();
    final String old = _lastText;
    _lastText = current;
    _effectiveController.value = current;
    widget.onChanged?.call(current);

    final ThemeData theme = Theme.of(context);
    final OrionOtpStyle style = _resolveStyle(theme);

    // If characters were added, trigger slot springs and peek timers.
    if (current.length > old.length) {
      OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);

      for (int i = old.length; i < current.length; i++) {
        _triggerSlotSpring(i, style);
        if (widget.obscureText && widget.delayedObscure) {
          _triggerDelayedObscure(i);
        }
      }
    } else {
      // Characters removed.
      for (int i = current.length; i < old.length; i++) {
        _peekTimers[i]?.cancel();
        _peekTimers.remove(i);
        _revealedSlots.remove(i);
      }
    }

    // Fire onCompleted when full.
    if (current.length == widget.length) {
      if (!_completedFired || current != old) {
        _completedFired = true;
        widget.onCompleted?.call(current);
      }
    } else {
      _completedFired = false;
    }

    setState(() {});
  }

  void _triggerSlotSpring(int index, OrionOtpStyle style) {
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) return;

    final OrionSpringSpec slotSpec =
        style.slotSpringSpec ??
        const OrionSpringSpec(stiffness: 600.0, dampingRatio: 0.85);

    final OrionSpringDriver driver = _slotDrivers.putIfAbsent(
      index,
      () => OrionSpringDriver(
        vsync: this,
        initialValue: 1.0,
        springSpec: slotSpec,
      ),
    );

    driver.springSpec = slotSpec;
    driver.retarget(1.0, velocity: -2.4);
  }

  void _triggerDelayedObscure(int index) {
    _peekTimers[index]?.cancel();
    _revealedSlots.add(index);

    _peekTimers[index] = Timer(widget.delayedObscureDuration, () {
      if (mounted) {
        setState(() {
          _revealedSlots.remove(index);
        });
      }
    });
  }

  void _handleTap() {
    if (!widget.enabled) return;
    _contextMenuController.remove();
    final String text = _textEditingController.text;
    if (_textEditingController.selection.baseOffset != text.length ||
        _textEditingController.selection.extentOffset != text.length) {
      _setTextWithEndSelection(text);
    }
    if (!_focusNode.hasFocus) {
      _focusNode.requestFocus();
    } else if (!widget.readOnly) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    }
  }

  Future<void> _pasteFromClipboard() async {
    if (!widget.enabled || widget.readOnly) return;
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final String sanitized = _sanitize(data?.text ?? '');
    if (sanitized.isEmpty) return;
    _focusNode.requestFocus();
    _setTextWithEndSelection(sanitized);
  }

  Future<void> _handleLongPressStart(LongPressStartDetails details) async {
    if (!widget.enabled || widget.readOnly) return;
    final ClipboardData? data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted) return;
    final String raw = data?.text ?? '';
    final String sanitized = _sanitize(raw);
    if (sanitized.isEmpty) return;

    _contextMenuController.show(
      context: context,
      contextMenuBuilder: (BuildContext menuContext) {
        return AdaptiveTextSelectionToolbar.buttonItems(
          anchors: TextSelectionToolbarAnchors(
            primaryAnchor: details.globalPosition,
          ),
          buttonItems: <ContextMenuButtonItem>[
            ContextMenuButtonItem(
              type: ContextMenuButtonType.paste,
              onPressed: () {
                ContextMenuController.removeAny();
                _focusNode.requestFocus();
                _setTextWithEndSelection(sanitized);
              },
            ),
          ],
        );
      },
    );
  }

  OrionOtpStyle _resolveStyle(ThemeData theme) {
    final OrionOtpTheme otpTheme =
        theme.extension<OrionOtpTheme>() ?? OrionOtpTheme.fallback;
    return OrionOtpPresets.resolve(
      scheme: theme.colorScheme,
      variant: widget.variant,
      textTheme: theme.textTheme,
    ).merge(otpTheme.defaultStyle).merge(widget.style);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionOtpStyle style = _resolveStyle(theme);
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final String text = _textEditingController.text;
    final bool hasFocus = _focusNode.hasFocus;
    final int activeIndex =
        (widget.enabled &&
            !widget.readOnly &&
            hasFocus &&
            text.length < widget.length)
        ? text.length
        : -1;

    final String? errorText = widget.error != null && widget.error!.isNotEmpty
        ? widget.error
        : null;
    final String? caption = errorText ?? widget.helper;

    final String effectiveSemanticLabel =
        widget.semanticLabel ??
        'One-time passcode, ${widget.length} '
            '${widget.digitsOnly ? 'digits' : 'characters'}';
    final String semanticValue = widget.obscureText
        ? widget.obscureCharacter * text.length
        : text;

    final Iterable<String>? effectiveAutofillHints =
        widget.autofillHints ??
        (widget.obscureText
            ? null
            : const <String>[AutofillHints.oneTimeCode]);

    final Widget slotField = MouseRegion(
      cursor: widget.enabled
          ? SystemMouseCursors.text
          : SystemMouseCursors.basic,
      onEnter: (_) {
        if (!_hovered) setState(() => _hovered = true);
      },
      onExit: (_) {
        if (_hovered) setState(() => _hovered = false);
      },
      child: Semantics(
        container: true,
        textField: true,
        enabled: widget.enabled,
        readOnly: widget.readOnly,
        obscured: widget.obscureText,
        label: effectiveSemanticLabel,
        value: semanticValue,
        hint: caption,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _handleTap,
          onLongPressStart: widget.enabled && !widget.readOnly
              ? _handleLongPressStart
              : null,
          child: AnimatedBuilder(
            animation: _shakeDriver,
            builder: (BuildContext context, Widget? child) {
              return Transform.translate(
                offset: Offset(_shakeDriver.value, 0.0),
                child: child,
              );
            },
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final double baseSlotWidth = style.slotWidth ?? 42.0;
                final double baseSlotHeight = style.slotHeight ?? 52.0;
                final double baseSlotSpacing = style.slotSpacing ?? 6.0;
                final double baseGroupSpacing = style.groupSpacing ?? 14.0;

                int groupBreaks = 0;
                int normalGaps = 0;
                for (int i = 0; i < widget.length - 1; i++) {
                  if (widget.groupLength != null &&
                      (i + 1) % widget.groupLength! == 0) {
                    groupBreaks++;
                  } else {
                    normalGaps++;
                  }
                }

                // Reserve unscaled room for custom separator widgets so scaling
                // only applies to slots and gaps, preventing sub-pixel overflow.
                final double unscaledSeparators = widget.groupSeparator != null
                    ? groupBreaks * 24.0
                    : 0.0;
                final double scalableIdealWidth =
                    widget.length * baseSlotWidth +
                    normalGaps * baseSlotSpacing +
                    groupBreaks *
                        (widget.groupSeparator != null
                            ? baseGroupSpacing / 2
                            : baseGroupSpacing);

                double widthScale = 1.0;
                if (constraints.hasBoundedWidth &&
                    scalableIdealWidth + unscaledSeparators >
                        constraints.maxWidth &&
                    scalableIdealWidth > 0) {
                  final double availableForScalable = math.max(
                    0.0,
                    constraints.maxWidth - unscaledSeparators,
                  );
                  widthScale = (availableForScalable / scalableIdealWidth)
                      .clamp(0.45, 1.0);
                }

                final double slotWidth = baseSlotWidth * widthScale;
                final double slotHeight = widthScale < 1.0
                    ? math.max(
                        40.0,
                        baseSlotHeight * math.max(0.82, widthScale),
                      )
                    : baseSlotHeight;
                final double slotSpacing = baseSlotSpacing * widthScale;
                final double groupSpacing = baseGroupSpacing * widthScale;

                final List<Widget> slotWidgets = <Widget>[];
                for (int i = 0; i < widget.length; i++) {
                  final bool hasChar = i < text.length;
                  final String char = hasChar ? text[i] : '';
                  final bool isActive = i == activeIndex;

                  slotWidgets.add(
                    _buildSlotTile(
                      index: i,
                      char: char,
                      isActive: isActive,
                      hasChar: hasChar,
                      width: slotWidth,
                      height: slotHeight,
                      reduced: reduced,
                      style: style,
                      scheme: scheme,
                    ),
                  );

                  if (widget.groupLength != null &&
                      i < widget.length - 1 &&
                      (i + 1) % widget.groupLength! == 0) {
                    if (widget.groupSeparator != null) {
                      slotWidgets.add(
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: groupSpacing / 4,
                          ),
                          child: widget.groupSeparator,
                        ),
                      );
                    } else {
                      slotWidgets.add(SizedBox(width: groupSpacing));
                    }
                  } else if (i < widget.length - 1) {
                    slotWidgets.add(SizedBox(width: slotSpacing));
                  }
                }

                final Widget slotRow = ExcludeSemantics(
                  child: Directionality(
                    textDirection: TextDirection.ltr,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: slotWidgets,
                    ),
                  ),
                );

                return Stack(
                  alignment: Alignment.center,
                  children: <Widget>[
                    // Visual slot row stays LTR even inside RTL locales so
                    // numeric codes always progress left-to-right, and scales
                    // down cleanly if a caller passes an oversized separator.
                    if (constraints.hasBoundedWidth)
                      ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: constraints.maxWidth,
                        ),
                        child: FittedBox(fit: BoxFit.scaleDown, child: slotRow),
                      )
                    else
                      slotRow,

                    // Single invisible input capturing all typing, autofill,
                    // and hardware clipboard paste. IgnorePointer keeps taps
                    // routed through the outer GestureDetector cleanly while
                    // preserving focus & keyboard input.
                    Positioned.fill(
                      child: ExcludeSemantics(
                        child: IgnorePointer(
                          child: Opacity(
                            opacity: 0.0,
                            child: Actions(
                              actions: <Type, Action<Intent>>{
                                PasteTextIntent:
                                    CallbackAction<PasteTextIntent>(
                                      onInvoke: (PasteTextIntent intent) {
                                        _pasteFromClipboard();
                                        return null;
                                      },
                                    ),
                              },
                              child: TextField(
                                controller: _textEditingController,
                                focusNode: _focusNode,
                                keyboardType:
                                    widget.keyboardType ??
                                    (widget.digitsOnly
                                        ? TextInputType.number
                                        : TextInputType.text),
                                keyboardAppearance: theme.brightness,
                                textInputAction: widget.textInputAction,
                                textCapitalization: widget.textCapitalization,
                                inputFormatters: _buildInputFormatters(),
                                autofillHints: effectiveAutofillHints,
                                obscureText: widget.obscureText,
                                autocorrect: false,
                                enableSuggestions: false,
                                smartDashesType: SmartDashesType.disabled,
                                smartQuotesType: SmartQuotesType.disabled,
                                enableInteractiveSelection: false,
                                autofocus: widget.autoFocus,
                                enabled: widget.enabled,
                                readOnly: widget.readOnly,
                                onSubmitted: widget.onSubmitted,
                                cursorColor: Colors.transparent,
                                showCursor: false,
                                style: const TextStyle(
                                  color: Colors.transparent,
                                  fontSize: 1,
                                ),
                                decoration: const InputDecoration.collapsed(
                                  hintText: '',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );

    if (widget.label == null && caption == null) {
      return slotField;
    }

    final TextStyle effectiveLabelStyle =
        style.labelStyle ??
        theme.textTheme.labelMedium ??
        TextStyle(fontSize: 13.0, color: scheme.onSurface);
    final TextStyle effectiveCaptionStyle =
        (style.captionStyle ??
                theme.textTheme.bodySmall ??
                const TextStyle(fontSize: 12.0))
            .copyWith(
              color: errorText != null
                  ? (style.errorBorderColor ?? scheme.error)
                  : (style.captionStyle?.color ?? scheme.onSurfaceVariant),
            );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          Text(
            widget.label!,
            style: widget.enabled
                ? effectiveLabelStyle
                : effectiveLabelStyle.copyWith(
                    color: style.disabledTextColor ??
                        scheme.onSurface.withValues(alpha: 0.38),
                  ),
          ),
          const SizedBox(height: OrionSpacing.space8),
        ],
        slotField,
        if (caption != null) ...<Widget>[
          const SizedBox(height: OrionSpacing.space8),
          Text(
            caption,
            textAlign: TextAlign.center,
            style: effectiveCaptionStyle,
          ),
        ],
      ],
    );
  }

  Widget _buildSlotTile({
    required int index,
    required String char,
    required bool isActive,
    required bool hasChar,
    required double width,
    required double height,
    required bool reduced,
    required OrionOtpStyle style,
    required ColorScheme scheme,
  }) {
    final bool hovered = _hovered && widget.enabled && !widget.readOnly;
    final OrionOtpStatus status = _effectiveStatus;

    Color borderColor;
    double borderWidth = style.slotBorderWidth ?? 1.0;
    Color bgColor;

    if (!widget.enabled) {
      borderColor =
          style.disabledBorderColor ?? scheme.onSurface.withValues(alpha: 0.12);
      bgColor =
          style.disabledBackgroundColor ??
          scheme.onSurface.withValues(alpha: 0.06);
    } else if (status == OrionOtpStatus.error) {
      borderColor = style.errorBorderColor ?? scheme.error;
      borderWidth = style.activeBorderWidth ?? 2.0;
      bgColor = style.errorBackgroundColor ?? Colors.transparent;
    } else if (status == OrionOtpStatus.success) {
      borderColor = style.successBorderColor ?? scheme.primary;
      borderWidth = style.activeBorderWidth ?? 2.0;
      bgColor = style.successBackgroundColor ?? Colors.transparent;
    } else if (isActive) {
      borderColor = style.activeBorderColor ?? scheme.primary;
      borderWidth = style.activeBorderWidth ?? 2.0;
      bgColor = style.activeBackgroundColor ?? scheme.surfaceContainer;
    } else if (hasChar) {
      borderColor = style.filledBorderColor ?? scheme.outline;
      bgColor = style.filledBackgroundColor ?? scheme.surfaceContainer;
    } else {
      borderColor = hovered
          ? (style.hoverBorderColor ?? style.borderColor ?? scheme.outline)
          : (style.borderColor ?? scheme.outline);
      bgColor = hovered && style.hoverBackgroundColor != null
          ? Color.alphaBlend(
              style.hoverBackgroundColor!,
              style.backgroundColor ?? Colors.transparent,
            )
          : (style.backgroundColor ?? Colors.transparent);
    }

    final BorderRadius radius =
        style.slotBorderRadius ??
        (widget.variant == OrionOtpVariant.underline
            ? BorderRadius.zero
            : BorderRadius.circular(OrionRadii.radius12));

    final Border? slotBorder;
    if (borderWidth <= 0 || borderColor.a == 0) {
      slotBorder = null;
    } else if (widget.variant == OrionOtpVariant.underline) {
      slotBorder = Border(
        bottom: BorderSide(color: borderColor, width: borderWidth),
      );
    } else {
      slotBorder = Border.all(color: borderColor, width: borderWidth);
    }

    final String displayChar;
    if (!hasChar) {
      displayChar = '';
    } else if (!widget.obscureText) {
      displayChar = char;
    } else if (widget.delayedObscure && _revealedSlots.contains(index)) {
      displayChar = char;
    } else {
      displayChar = widget.obscureCharacter;
    }

    final TextStyle resolvedTextStyle =
        (style.textStyle ??
                TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurface,
                ))
            .copyWith(
              color: widget.enabled
                  ? (style.textStyle?.color ?? scheme.onSurface)
                  : (style.disabledTextColor ??
                        scheme.onSurface.withValues(alpha: 0.38)),
            );

    final Duration transitionDuration = reduced
        ? Duration.zero
        : const Duration(milliseconds: 120);

    final OrionSpringDriver? driver = _slotDrivers[index];

    return AnimatedBuilder(
      animation: driver ?? const AlwaysStoppedAnimation<double>(1.0),
      builder: (BuildContext context, Widget? child) {
        final double scale = driver?.value ?? 1.0;
        return Transform.scale(
          scale: scale,
          alignment: Alignment.center,
          child: child,
        );
      },
      child: Container(
        width: width,
        height: height,
        clipBehavior: widget.variant == OrionOtpVariant.underline
            ? Clip.none
            : Clip.antiAlias,
        decoration: BoxDecoration(borderRadius: radius),
        child: Stack(
          alignment: Alignment.center,
          children: <Widget>[
            // Fill and border paint in Positioned.fill so changing border
            // width (0 -> 1 -> 2) never shifts the centered digit by 1 px.
            Positioned.fill(
              child: AnimatedContainer(
                duration: transitionDuration,
                curve: Curves.easeOutCubic,
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: radius,
                  border: slotBorder,
                ),
              ),
            ),

            // Isolated breathing caret bar in the active empty slot.
            if (isActive && !hasChar && widget.enabled && !widget.readOnly)
              _BreathingCaret(
                color: style.caretColor ?? scheme.primary,
                width: style.caretWidth ?? 2.0,
                height: style.caretHeight ?? 22.0,
                staticVisible:
                    reduced || (OrionOtpField.debugDeterministicCaret ?? false),
              ),

            // Optional empty-slot placeholder glyph.
            if (!hasChar && !isActive && widget.placeholder != null)
              Text(
                widget.placeholder!,
                textAlign: TextAlign.center,
                style:
                    style.placeholderTextStyle ??
                    TextStyle(
                      fontSize: 18.0,
                      color: scheme.onSurfaceVariant.withValues(alpha: 0.45),
                    ),
              ),

            // Digit or Bullet
            if (hasChar)
              Text(
                displayChar,
                textAlign: TextAlign.center,
                style: resolvedTextStyle,
              ),
          ],
        ),
      ),
    );
  }
}

/// Self-contained caret indicator that breathes smoothly on a periodic toggle
/// without triggering parent rebuilds or blocking [WidgetTester.pumpAndSettle].
class _BreathingCaret extends StatefulWidget {
  const _BreathingCaret({
    required this.color,
    required this.width,
    required this.height,
    required this.staticVisible,
  });

  final Color color;
  final double width;
  final double height;
  final bool staticVisible;

  @override
  State<_BreathingCaret> createState() => _BreathingCaretState();
}

class _BreathingCaretState extends State<_BreathingCaret> {
  Timer? _timer;
  bool _visible = true;

  @override
  void initState() {
    super.initState();
    _syncTimer();
  }

  @override
  void didUpdateWidget(_BreathingCaret oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.staticVisible != oldWidget.staticVisible) {
      _syncTimer();
    }
  }

  void _syncTimer() {
    _timer?.cancel();
    _timer = null;
    if (widget.staticVisible) {
      _visible = true;
      return;
    }
    _visible = true;
    _timer = Timer.periodic(const Duration(milliseconds: 530), (Timer timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() => _visible = !_visible);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final Widget bar = Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        color: widget.color,
        borderRadius: BorderRadius.circular(1.0),
      ),
    );

    if (widget.staticVisible) {
      return Opacity(opacity: 1.0, child: bar);
    }

    return AnimatedOpacity(
      opacity: _visible ? 1.0 : 0.12,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      child: bar,
    );
  }
}
