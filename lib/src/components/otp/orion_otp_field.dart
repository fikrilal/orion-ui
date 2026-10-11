import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/otp/orion_otp_controller.dart';
import 'package:orion_ui/src/components/otp/orion_otp_presets.dart';
import 'package:orion_ui/src/components/otp/orion_otp_style.dart';
import 'package:orion_ui/src/components/otp/orion_otp_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Validation and visual status for [OrionOtpField].
enum OrionOtpStatus {
  /// Default resting input state.
  idle,

  /// Error state: tints borders red and triggers horizontal shake physics.
  error,

  /// Success state: tints borders with the success/primary role.
  success,
}

/// A physics-driven One-Time Password and PIN passcode field.
///
/// Features:
/// - Single invisible [TextField] architecture capturing all native keyboard
///   events, hardware keystrokes, SMS autofill, and clipboard paste.
/// - Tactile micro-bounce slot spring physics upon character entry.
/// - Breathing caret bar in the active slot (static when motion is reduced, stopped when unfocused or full).
/// - Delayed secure dot masking (`delayedObscure: true`) for transaction PIN privacy.
/// - Damped sinusoidal horizontal error shake physics on invalid submission.
/// - Grouped slot layouts (e.g. 3 + 3 slots with custom spacing or separator).
/// - Reduced motion support (immediate settlement on frame 0).
class OrionOtpField extends StatefulWidget {
  const OrionOtpField({
    super.key,
    this.length = 6,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onCompleted,
    this.status = OrionOtpStatus.idle,
    this.obscureText = false,
    this.delayedObscure = true,
    this.obscureCharacter = '●',
    this.delayedObscureDuration = const Duration(milliseconds: 400),
    this.digitsOnly = true,
    this.groupLength,
    this.groupSeparator,
    this.autoFocus = false,
    this.enabled = true,
    this.style,
  }) : assert(length > 0, 'length must be greater than zero'),
       assert(
         groupLength == null || groupLength > 0,
         'groupLength must be greater than zero if specified',
       );

  /// Number of code slots to display (typically 4 or 6).
  final int length;

  /// Optional programmatic controller.
  final OrionOtpController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Callback invoked on every text change.
  final ValueChanged<String>? onChanged;

  /// Callback fired when all slots are completely filled.
  final ValueChanged<String>? onCompleted;

  /// Visual status of the field (idle, error, success).
  final OrionOtpStatus status;

  /// Whether characters are obscured for security.
  final bool obscureText;

  /// When true, displays newly typed characters for a brief peek duration
  /// before masking into [obscureCharacter].
  final bool delayedObscure;

  /// Character displayed when obscured (default '●').
  final String obscureCharacter;

  /// Duration to show the raw digit before masking when [delayedObscure] is true.
  final Duration delayedObscureDuration;

  /// Whether only numeric digits `0-9` are accepted.
  final bool digitsOnly;

  /// Optional slot grouping length (e.g. 3 splits 6 slots into 3 + 3).
  final int? groupLength;

  /// Optional separator widget rendered between slot groups.
  final Widget? groupSeparator;

  /// Whether to automatically focus the field and request keyboard.
  final bool autoFocus;

  /// Whether the field is interactable.
  final bool enabled;

  /// Instance style overrides.
  final OrionOtpStyle? style;

  /// Whether caret blinking is replaced with a static visible caret.
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

  // Caret pulsing timer
  Timer? _caretTimer;
  bool _caretVisible = true;

  // Track delayed obscure peek timers per slot
  final Map<int, Timer> _peekTimers = <int, Timer>{};
  final Set<int> _revealedSlots = <int>{};

  // Micro-bounce springs per slot
  final Map<int, OrionSpringDriver> _slotDrivers = <int, OrionSpringDriver>{};

  String _lastText = '';
  bool _completedFired = false;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(
      text: widget.controller?.value ?? '',
    );
    _lastText = _textEditingController.text;
    _focusNode = widget.focusNode ?? FocusNode();

    _shakeDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.65),
    );

    _attachController();
    _effectiveController.addListener(_handleControllerChanged);
    _textEditingController.addListener(_handleTextChanged);
    _focusNode.addListener(_handleFocusChanged);

    if (widget.status == OrionOtpStatus.error) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _shake());
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncCaretTicker();
  }

  @override
  void didUpdateWidget(OrionOtpField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.removeListener(_handleControllerChanged);
      oldWidget.controller?.detach();
      _attachController();
      _effectiveController.addListener(_handleControllerChanged);
    }

    if (widget.focusNode != oldWidget.focusNode) {
      if (oldWidget.focusNode == null) {
        _focusNode.removeListener(_handleFocusChanged);
        _focusNode.dispose();
      } else {
        oldWidget.focusNode!.removeListener(_handleFocusChanged);
      }
      _focusNode = widget.focusNode ?? FocusNode();
      _focusNode.addListener(_handleFocusChanged);
    }

    if (widget.status != oldWidget.status &&
        widget.status == OrionOtpStatus.error) {
      _shake();
    }

    _syncCaretTicker();
  }

  @override
  void dispose() {
    for (final timer in _peekTimers.values) {
      timer.cancel();
    }
    _peekTimers.clear();

    for (final driver in _slotDrivers.values) {
      driver.dispose();
    }
    _slotDrivers.clear();

    _shakeDriver.dispose();
    _stopCaretBlink();

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

  void _startCaretBlink() {
    _caretTimer?.cancel();
    _caretVisible = true;
    _caretTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _caretVisible = !_caretVisible;
      });
    });
  }

  void _stopCaretBlink() {
    _caretTimer?.cancel();
    _caretTimer = null;
    _caretVisible = false;
  }

  void _syncCaretTicker() {
    if (!mounted) return;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool shouldBlink =
        widget.enabled &&
        _focusNode.hasFocus &&
        _textEditingController.text.length < widget.length &&
        !reduced &&
        !(OrionOtpField.debugDeterministicCaret ?? false);

    if (shouldBlink) {
      if (_caretTimer == null || !_caretTimer!.isActive) {
        _startCaretBlink();
      }
    } else {
      _stopCaretBlink();
    }
  }

  void _handleControllerChanged() {
    if (_textEditingController.text != _effectiveController.value) {
      _textEditingController.text = _effectiveController.value;
    }
  }

  void _attachController() {
    _effectiveController.attach(
      onShake: _shake,
      onFocus: () => _focusNode.requestFocus(),
      onUnfocus: () => _focusNode.unfocus(),
      onClear: () {
        for (final timer in _peekTimers.values) {
          timer.cancel();
        }
        _peekTimers.clear();
        _revealedSlots.clear();
        _textEditingController.clear();
      },
    );
  }

  void _shake() {
    if (!mounted) return;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) return;

    final theme = Theme.of(context);
    final style = _resolveStyle(theme);
    final OrionSpringSpec shakeSpec =
        style.shakeSpringSpec ??
        const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.65);

    OrionHaptics.trigger(OrionHapticType.heavyImpact);
    _shakeDriver.springSpec = shakeSpec;
    _shakeDriver.retarget(0.0, velocity: 180.0);
  }

  void _handleFocusChanged() {
    _syncCaretTicker();
    setState(() {});
  }

  void _handleTextChanged() {
    final String current = _textEditingController.text;
    if (current == _lastText) return;

    final String old = _lastText;
    _lastText = current;
    _effectiveController.value = current;
    widget.onChanged?.call(current);

    final theme = Theme.of(context);
    final style = _resolveStyle(theme);

    // If characters were added, trigger slot springs and peek timers
    if (current.length > old.length) {
      OrionHaptics.trigger(OrionHapticType.selectionClick);

      for (int i = old.length; i < current.length; i++) {
        _triggerSlotSpring(i, style);
        if (widget.obscureText && widget.delayedObscure) {
          _triggerDelayedObscure(i);
        }
      }
    } else {
      // Characters removed
      for (int i = current.length; i < old.length; i++) {
        _peekTimers[i]?.cancel();
        _peekTimers.remove(i);
        _revealedSlots.remove(i);
      }
    }

    // Fire onCompleted when full
    if (current.length == widget.length) {
      if (!_completedFired || current != old) {
        _completedFired = true;
        widget.onCompleted?.call(current);
      }
    } else {
      _completedFired = false;
    }

    _syncCaretTicker();
    setState(() {});
  }

  void _triggerSlotSpring(int index, OrionOtpStyle style) {
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduced) return;

    final OrionSpringSpec slotSpec =
        style.slotSpringSpec ??
        const OrionSpringSpec(stiffness: 450.0, dampingRatio: 0.80);

    final driver = _slotDrivers.putIfAbsent(
      index,
      () => OrionSpringDriver(
        vsync: this,
        initialValue: 1.0,
        springSpec: slotSpec,
      ),
    );

    driver.springSpec = slotSpec;
    driver.retarget(1.0, velocity: -8.0);
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

  OrionOtpStyle _resolveStyle(ThemeData theme) {
    final OrionOtpTheme otpTheme =
        theme.extension<OrionOtpTheme>() ?? OrionOtpTheme.fallback;
    return OrionOtpPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(otpTheme.defaultStyle).merge(widget.style);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = _resolveStyle(theme);

    final String text = _textEditingController.text;
    final bool hasFocus = _focusNode.hasFocus;
    final int activeIndex = (hasFocus && text.length < widget.length)
        ? text.length
        : -1;

    final List<Widget> slotWidgets = <Widget>[];

    for (int i = 0; i < widget.length; i++) {
      final bool hasChar = i < text.length;
      final String char = hasChar ? text[i] : '';
      final bool isActive = i == activeIndex;

      final Widget slotTile = _buildSlotTile(
        index: i,
        char: char,
        isActive: isActive,
        hasChar: hasChar,
        style: style,
      );

      slotWidgets.add(slotTile);

      // Check for group spacing / separator
      if (widget.groupLength != null &&
          i < widget.length - 1 &&
          (i + 1) % widget.groupLength! == 0) {
        if (widget.groupSeparator != null) {
          slotWidgets.add(
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: (style.groupSpacing ?? 14.0) / 4,
              ),
              child: widget.groupSeparator,
            ),
          );
        } else {
          slotWidgets.add(SizedBox(width: style.groupSpacing ?? 14.0));
        }
      } else if (i < widget.length - 1) {
        slotWidgets.add(SizedBox(width: style.slotSpacing ?? 6.0));
      }
    }

    return AnimatedBuilder(
      animation: _shakeDriver,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(_shakeDriver.value, 0.0),
          child: child,
        );
      },
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.text
            : SystemMouseCursors.basic,
        child: Semantics(
          textField: true,
          label: 'One-time passcode, ${widget.length} digits',
          value: text,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (!widget.enabled) return;
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              } else {
                SystemChannels.textInput.invokeMethod<void>('TextInput.show');
              }
            },
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Visual slot row
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: slotWidgets,
                ),

                // Single invisible input capturing all typing and paste
                Positioned.fill(
                  child: Opacity(
                    opacity: 0.0,
                    alwaysIncludeSemantics: true,
                    child: TextField(
                      controller: _textEditingController,
                      focusNode: _focusNode,
                      keyboardType: widget.digitsOnly
                          ? TextInputType.number
                          : TextInputType.text,
                      inputFormatters: [
                        LengthLimitingTextInputFormatter(widget.length),
                        if (widget.digitsOnly)
                          FilteringTextInputFormatter.digitsOnly,
                      ],
                      autofillHints: const [AutofillHints.oneTimeCode],
                      enableInteractiveSelection: false,
                      autofocus: widget.autoFocus,
                      enabled: widget.enabled,
                      cursorColor: Colors.transparent,
                      showCursor: false,
                      style: const TextStyle(
                        color: Colors.transparent,
                        fontSize: 1,
                      ),
                      decoration: const InputDecoration.collapsed(hintText: ''),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotTile({
    required int index,
    required String char,
    required bool isActive,
    required bool hasChar,
    required OrionOtpStyle style,
  }) {
    Color borderColor;
    double borderWidth = style.slotBorderWidth ?? 1.0;
    Color bgColor;

    if (widget.status == OrionOtpStatus.error) {
      borderColor = style.errorBorderColor ?? Colors.red;
      borderWidth = style.activeBorderWidth ?? 2.0;
      bgColor = style.backgroundColor ?? Colors.transparent;
    } else if (widget.status == OrionOtpStatus.success) {
      borderColor = style.successBorderColor ?? Colors.green;
      borderWidth = style.activeBorderWidth ?? 2.0;
      bgColor = style.backgroundColor ?? Colors.transparent;
    } else if (isActive) {
      borderColor = style.activeBorderColor ?? Colors.blue;
      borderWidth = style.activeBorderWidth ?? 2.0;
      bgColor = style.activeBackgroundColor ?? Colors.transparent;
    } else if (hasChar) {
      borderColor = style.filledBorderColor ?? Colors.grey;
      bgColor = style.filledBackgroundColor ?? Colors.transparent;
    } else {
      borderColor = style.borderColor ?? Colors.grey;
      bgColor = style.backgroundColor ?? Colors.transparent;
    }

    final double width = style.slotWidth ?? 42.0;
    final double height = style.slotHeight ?? 52.0;
    final BorderRadius radius =
        style.slotBorderRadius ?? BorderRadius.circular(OrionRadii.radius12);

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

    final driver = _slotDrivers[index];

    return AnimatedBuilder(
      animation: driver ?? const AlwaysStoppedAnimation<double>(1.0),
      builder: (context, child) {
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
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Centered Caret Bar
            if (isActive && !hasChar && widget.enabled)
              Opacity(
                opacity:
                    _caretVisible ||
                        (MediaQuery.maybeDisableAnimationsOf(context) ??
                            false) ||
                        (OrionOtpField.debugDeterministicCaret ?? false)
                    ? 1.0
                    : 0.0,
                child: Container(
                  width: style.caretWidth ?? 2.0,
                  height: style.caretHeight ?? 22.0,
                  decoration: BoxDecoration(
                    color: style.caretColor ?? Colors.blue,
                    borderRadius: BorderRadius.circular(1.0),
                  ),
                ),
              ),

            // Digit or Bullet
            if (hasChar)
              Text(
                displayChar,
                textAlign: TextAlign.center,
                style:
                    style.textStyle ??
                    const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.w600,
                    ),
              ),
          ],
        ),
      ),
    );
  }
}
