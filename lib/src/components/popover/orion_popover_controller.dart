import 'package:flutter/foundation.dart';

/// Programmatic controller for an [OrionPopover] or [OrionMenu].
class OrionPopoverController extends ChangeNotifier {
  bool _isOpen = false;
  VoidCallback? _onShow;
  VoidCallback? _onHide;

  /// Whether the popover is currently mounted or in the process of opening.
  bool get isOpen => _isOpen;

  /// Attaches internal presentation callbacks from the popover state.
  void attach({required VoidCallback onShow, required VoidCallback onHide}) {
    _onShow = onShow;
    _onHide = onHide;
  }

  /// Detaches presentation callbacks when the popover state is unmounted.
  void detach() {
    _onShow = null;
    _onHide = null;
  }

  /// Internal state updater called by the popover state.
  void updateOpenState(bool open) {
    if (_isOpen == open) return;
    _isOpen = open;
    notifyListeners();
  }

  /// Opens the popover.
  void show() {
    if (_isOpen) return;
    _onShow?.call();
  }

  /// Closes the popover.
  void hide() {
    if (!_isOpen) return;
    _onHide?.call();
  }

  /// Toggles the popover between open and closed.
  void toggle() {
    if (_isOpen) {
      hide();
    } else {
      show();
    }
  }
}
