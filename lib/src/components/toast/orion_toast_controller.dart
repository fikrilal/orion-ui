import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:orion_ui/src/components/toast/orion_toast_data.dart';

/// State controller and timer manager for the active toast stack.
class OrionToastController extends ChangeNotifier {
  OrionToastController._();

  /// The shared default instance.
  static final OrionToastController instance = OrionToastController._();

  final List<OrionToastData> _toasts = <OrionToastData>[];
  final Map<String, Timer> _timers = <String, Timer>{};
  final Map<String, Duration> _remaining = <String, Duration>{};
  final Map<String, DateTime> _timerStarts = <String, DateTime>{};
  bool _paused = false;
  DateTime? _pausedAt;
  int _idCounter = 0;

  /// The list of active toasts, in addition order (oldest first, newest last).
  List<OrionToastData> get toasts => List<OrionToastData>.unmodifiable(_toasts);

  /// Shows or updates a toast. Returns the assigned toast id.
  String show(OrionToastData data) {
    final String toastId = data.id.isNotEmpty
        ? data.id
        : 'toast-${++_idCounter}';
    final OrionToastData effective = data.copyWith(id: toastId);

    final int existingIndex = _toasts.indexWhere((t) => t.id == toastId);
    if (existingIndex >= 0) {
      // Update in place without altering stack position
      _toasts[existingIndex] = effective;
      _cancelTimer(toastId);
      _scheduleAutoDismiss(effective);
      notifyListeners();
      return toastId;
    }

    _toasts.add(effective);
    _scheduleAutoDismiss(effective);
    notifyListeners();
    return toastId;
  }

  /// Dismisses a toast by [id]. If [id] is null, dismisses the frontmost toast.
  ///
  /// The toast leaves the queue here and now; the card that was showing it keeps
  /// its place for one more glide and is gone once that glide lands.
  void dismiss([String? id]) {
    if (id == null) {
      if (_toasts.isNotEmpty) {
        final String frontId = _toasts.last.id;
        _removeToast(frontId);
      }
      return;
    }
    _removeToast(id);
  }

  /// Dismisses and clears all active toasts immediately.
  ///
  /// The queue is empty on return; any cards on screen leave with their exit
  /// motion. The hold is released with them, because nothing is left to hold.
  void clear() {
    for (final timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _remaining.clear();
    _timerStarts.clear();
    _toasts.clear();
    _paused = false;
    _pausedAt = null;
    notifyListeners();
  }

  /// Pauses auto-dismiss timers while an interaction (press/drag) is ongoing.
  void pauseTimers() {
    if (_paused) return;
    _paused = true;
    final DateTime now = DateTime.now();
    _pausedAt = now;
    for (final entry in _timers.entries) {
      final String id = entry.key;
      entry.value.cancel();
      final DateTime? start = _timerStarts[id];
      final Duration? prevRemaining = _remaining[id];
      if (start != null && prevRemaining != null) {
        final Duration elapsed = now.difference(start);
        final Duration rem = prevRemaining - elapsed;
        _remaining[id] = rem > Duration.zero ? rem : Duration.zero;
      }
    }
    _timers.clear();
  }

  /// Resumes auto-dismiss timers once touch interaction completes.
  ///
  /// Pausing holds the clock still for the toasts already on screen. A toast
  /// that arrives while the stack is held is different: it was never given a
  /// running timer, so the time it spent waiting is spent budget, and releasing
  /// the stack dismisses it if that budget is already gone. Leaving it out would
  /// hand such a toast a timer it can never outlive.
  void resumeTimers() {
    if (!_paused) return;
    _paused = false;
    final DateTime now = DateTime.now();
    final DateTime? pausedAt = _pausedAt;
    _pausedAt = null;
    final List<String> spent = <String>[];
    for (final toast in _toasts) {
      final Duration? rem = _remaining[toast.id];
      if (rem == null) {
        continue;
      }
      final DateTime? start = _timerStarts[toast.id];
      final Duration held =
          start != null && pausedAt != null && start.isAfter(pausedAt)
          ? now.difference(start)
          : Duration.zero;
      final Duration left = rem - held;
      if (left > Duration.zero) {
        _timerStarts[toast.id] = now;
        _timers[toast.id] = Timer(left, () => dismiss(toast.id));
      } else {
        spent.add(toast.id);
      }
    }
    for (final String id in spent) {
      _removeToast(id);
    }
  }

  void _scheduleAutoDismiss(OrionToastData data) {
    _cancelTimer(data.id);
    final Duration? duration = data.duration;
    if (duration == null || duration <= Duration.zero) {
      return;
    }

    _remaining[data.id] = duration;
    _timerStarts[data.id] = DateTime.now();

    if (!_paused) {
      _timers[data.id] = Timer(duration, () => dismiss(data.id));
    }
  }

  void _cancelTimer(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _remaining.remove(id);
    _timerStarts.remove(id);
  }

  void _removeToast(String id) {
    _cancelTimer(id);
    final int index = _toasts.indexWhere((t) => t.id == id);
    if (index >= 0) {
      _toasts.removeAt(index);
      notifyListeners();
    }
  }
}
