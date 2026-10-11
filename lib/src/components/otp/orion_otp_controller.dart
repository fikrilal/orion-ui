import 'package:flutter/foundation.dart';

/// Programmatic controller for [OrionOtpField].
///
/// Manages the text value, focus state, clearing, and triggers the
/// horizontal error shake animation.
class OrionOtpController extends ChangeNotifier {
  OrionOtpController({String? initialValue}) : _value = initialValue ?? '';

  String _value;
  VoidCallback? _shakeCallback;
  VoidCallback? _focusCallback;
  VoidCallback? _unfocusCallback;
  VoidCallback? _clearCallback;

  /// The current OTP passcode string.
  String get value => _value;

  /// Updates the value and notifies listeners.
  set value(String newValue) {
    if (_value == newValue) return;
    _value = newValue;
    notifyListeners();
  }

  /// Clears the input and resets all slots.
  void clear() {
    _value = '';
    _clearCallback?.call();
    notifyListeners();
  }

  /// Triggers the physics-driven horizontal error shake animation.
  void shake() {
    _shakeCallback?.call();
  }

  /// Requests focus and displays the soft keyboard.
  void focus() {
    _focusCallback?.call();
  }

  /// Dismisses focus and hides the soft keyboard.
  void unfocus() {
    _unfocusCallback?.call();
  }

  /// Internal attachment method called by [OrionOtpFieldState].
  void attach({
    required VoidCallback onShake,
    required VoidCallback onFocus,
    required VoidCallback onUnfocus,
    required VoidCallback onClear,
  }) {
    _shakeCallback = onShake;
    _focusCallback = onFocus;
    _unfocusCallback = onUnfocus;
    _clearCallback = onClear;
  }

  /// Internal detachment method called when [OrionOtpFieldState] unmounts.
  void detach() {
    _shakeCallback = null;
    _focusCallback = null;
    _unfocusCallback = null;
    _clearCallback = null;
  }
}
