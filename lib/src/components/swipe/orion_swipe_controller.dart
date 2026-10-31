import 'package:flutter/foundation.dart';

/// Which side of an [OrionSwipeActionRow] is revealed.
enum OrionSwipeSide {
  /// Actions anchored at the start edge (left in LTR, right in RTL).
  leading,

  /// Actions anchored at the end edge (right in LTR, left in RTL).
  trailing,
}

/// Programmatic controller for an [OrionSwipeActionRow].
///
/// Lets host screens open or close a row imperatively (for example from an
/// "Edit" toolbar button, an onboarding peek animation, or after an async
/// confirmation dialog) and observe [isOpen] / [openSide] via [ChangeNotifier].
class OrionSwipeController extends ChangeNotifier {
  void Function(OrionSwipeSide side)? _onOpen;
  VoidCallback? _onClose;
  OrionSwipeSide? _openSide;

  /// Whether this controller is currently attached to a mounted row.
  bool get isAttached => _onOpen != null && _onClose != null;

  /// Which side is currently open, or `null` when closed.
  OrionSwipeSide? get openSide => _openSide;

  /// Whether the attached row is currently open on either side.
  bool get isOpen => _openSide != null;

  /// Programmatically opens the leading action pane (if the row has leading
  /// actions and is enabled).
  void openLeading() => open(OrionSwipeSide.leading);

  /// Programmatically opens the trailing action pane (if the row has trailing
  /// actions and is enabled).
  void openTrailing() => open(OrionSwipeSide.trailing);

  /// Programmatically opens the requested [side].
  void open(OrionSwipeSide side) {
    _onOpen?.call(side);
  }

  /// Programmatically closes the attached row.
  void close() {
    _onClose?.call();
  }

  /// Internal hook called by `OrionSwipeActionRow` on mount or controller swap.
  void attach({
    required void Function(OrionSwipeSide side) onOpen,
    required VoidCallback onClose,
    required OrionSwipeSide? initialOpenSide,
  }) {
    _onOpen = onOpen;
    _onClose = onClose;
    _openSide = initialOpenSide;
  }

  /// Internal hook called by `OrionSwipeActionRow` when its open state changes.
  void syncState(OrionSwipeSide? side) {
    if (_openSide == side) {
      return;
    }
    _openSide = side;
    notifyListeners();
  }

  /// Internal hook called by `OrionSwipeActionRow` on dispose or swap.
  void detach({required VoidCallback onClose}) {
    if (_onClose != onClose) {
      return;
    }
    _onOpen = null;
    _onClose = null;
    _openSide = null;
  }
}
