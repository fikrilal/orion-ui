import 'package:flutter/foundation.dart';

/// Programmatic controller for [OrionTabs].
///
/// Manages selection state, allows animated transitions via [animateTo] or
/// instant jumps via [jumpTo], and tracks the current selected [value] and [index].
class OrionTabsController<T> extends ChangeNotifier {
  OrionTabsController({T? initialValue}) : _value = initialValue;

  T? _value;
  int? _index;
  int _length = 0;

  ValueChanged<T>? _animateCallback;
  ValueChanged<T>? _jumpCallback;

  /// The currently selected value, or null if uninitialized.
  T? get value => _value;

  /// The 0-based index of the currently selected tab, or null if uninitialized.
  int? get index => _index;

  /// The total number of tabs currently managed by this controller.
  int get length => _length;

  /// Animates selection smoothly to the tab with [value].
  void animateTo(T value) {
    if (_value == value) return;
    _value = value;
    _animateCallback?.call(value);
    notifyListeners();
  }

  /// Immediately jumps selection to the tab with [value] without animation.
  void jumpTo(T value) {
    if (_value == value) return;
    _value = value;
    _jumpCallback?.call(value);
    notifyListeners();
  }

  /// Internal attachment hook called by [OrionTabsState].
  @internal
  void attach({
    required ValueChanged<T> onAnimateTo,
    required ValueChanged<T> onJumpTo,
  }) {
    _animateCallback = onAnimateTo;
    _jumpCallback = onJumpTo;
  }

  /// Internal detachment hook called when [OrionTabsState] unmounts.
  @internal
  void detach() {
    _animateCallback = null;
    _jumpCallback = null;
  }

  /// Internal state updater called by the host [OrionTabs] widget.
  @internal
  void updateSelection({required T value, required int index, int? length}) {
    bool changed = false;
    if (_value != value) {
      _value = value;
      changed = true;
    }
    if (_index != index) {
      _index = index;
      changed = true;
    }
    if (length != null && _length != length) {
      _length = length;
      changed = true;
    }
    if (changed) {
      notifyListeners();
    }
  }
}
