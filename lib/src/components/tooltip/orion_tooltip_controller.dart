import 'package:flutter/foundation.dart';

/// Programmatic controller for [OrionTooltip].
///
/// Exposes imperative methods to show, hide, or toggle the tooltip
/// surface and monitors its logical open state.
class OrionTooltipController extends ChangeNotifier {
  bool _isOpen = false;
  VoidCallback? _showCallback;
  VoidCallback? _hideCallback;

  /// Whether the tooltip is currently open (or animating open).
  bool get isOpen => _isOpen;

  /// Shows the tooltip programmatically.
  void show() {
    _showCallback?.call();
  }

  /// Hides the tooltip programmatically.
  void hide() {
    _hideCallback?.call();
  }

  /// Toggles between open and hidden states.
  void toggle() {
    if (_isOpen) {
      hide();
    } else {
      show();
    }
  }

  /// Internal attachment method called by [OrionTooltipState].
  void attach({required VoidCallback onShow, required VoidCallback onHide}) {
    _showCallback = onShow;
    _hideCallback = onHide;
  }

  /// Internal detachment method called when [OrionTooltipState] unmounts.
  void detach() {
    _showCallback = null;
    _hideCallback = null;
  }

  /// Internal state updater called by the host tooltip.
  ///
  /// Pass `notify: false` during tree teardown or `didUpdateWidget` swaps to
  /// avoid triggering synchronous listener rebuilds while the widget tree is
  /// locked.
  void updateOpenState(bool open, {bool notify = true}) {
    if (_isOpen == open) return;
    _isOpen = open;
    if (notify) {
      notifyListeners();
    }
  }
}
