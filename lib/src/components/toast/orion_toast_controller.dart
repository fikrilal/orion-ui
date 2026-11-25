import 'dart:async';
import 'package:flutter/foundation.dart';

import 'package:orion_ui/src/components/toast/orion_toast_data.dart';

/// State controller and pauseable timer manager for an `OrionToaster` stack.
///
/// Most apps use the shared [OrionToastController.instance] through the
/// [OrionToast] facade, while scoped widgets and tests may instantiate their
/// own [OrionToastController] and pass it to `OrionToaster(controller: ...)`.
class OrionToastController extends ChangeNotifier {
  /// Creates an isolated toast controller.
  OrionToastController();

  /// The shared default instance used by the `OrionToast` facade.
  static final OrionToastController instance = OrionToastController();

  final List<OrionToastData> _toasts = <OrionToastData>[];
  final Map<String, Timer> _timers = <String, Timer>{};
  final Map<String, Duration> _remaining = <String, Duration>{};
  final Map<String, DateTime> _timerStarts = <String, DateTime>{};
  bool _paused = false;
  DateTime? _pausedAt;
  int _idCounter = 0;

  /// Active toasts in insertion order (oldest first, newest last).
  List<OrionToastData> get toasts => List<OrionToastData>.unmodifiable(_toasts);

  /// Whether auto-dismiss timers are currently paused by hover or hold/expand.
  bool get isPaused => _paused;

  /// Whether a toast with [id] is currently active in the queue.
  bool contains(String id) => _toasts.any((OrionToastData t) => t.id == id);

  /// Remaining auto-dismiss duration snapshot for [id], or null if persistent.
  Duration? remainingDurationOf(String id) {
    final Duration? base = _remaining[id];
    if (base == null) return null;
    if (_paused) return base;
    final DateTime? start = _timerStarts[id];
    if (start == null) return base;
    final Duration rem = base - DateTime.now().difference(start);
    return rem > Duration.zero ? rem : Duration.zero;
  }

  /// Shows a new toast or updates an existing toast with the same [id] in place.
  /// Returns the assigned toast id.
  String show(OrionToastData data) {
    final String toastId = data.id.isNotEmpty
        ? data.id
        : 'toast-${++_idCounter}';
    final OrionToastData effective = data.copyWith(id: toastId);

    final int existingIndex = _toasts.indexWhere(
      (OrionToastData t) => t.id == toastId,
    );
    if (existingIndex >= 0) {
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

  /// Dismisses a toast by [id] (or the newest/frontmost toast when [id] is
  /// null), reporting [reason] to its `onDismissed` callback.
  void dismiss([
    String? id,
    OrionToastDismissReason reason = OrionToastDismissReason.programmatic,
  ]) {
    if (id == null) {
      if (_toasts.isNotEmpty) {
        _removeToast(_toasts.last.id, reason: reason);
      }
      return;
    }
    _removeToast(id, reason: reason);
  }

  /// Dismisses and clears all active toasts immediately.
  void clear() {
    if (_toasts.isEmpty && _timers.isEmpty && !_paused) {
      return;
    }
    final List<OrionToastData> removed = List<OrionToastData>.of(_toasts);
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _remaining.clear();
    _timerStarts.clear();
    _toasts.clear();
    _paused = false;
    _pausedAt = null;
    notifyListeners();
    for (final OrionToastData toast in removed) {
      toast.onDismissed?.call(OrionToastDismissReason.cleared);
    }
  }

  /// Pauses auto-dismiss timers while an interaction (hover, press, or pinned
  /// expansion) is active.
  void pauseTimers() {
    if (_paused) return;
    _paused = true;
    final DateTime now = DateTime.now();
    _pausedAt = now;
    for (final MapEntry<String, Timer> entry in _timers.entries) {
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
    notifyListeners();
  }

  /// Resumes auto-dismiss timers once all hold/hover/expand interactions end.
  void resumeTimers() {
    if (!_paused) return;
    _paused = false;
    final DateTime now = DateTime.now();
    final DateTime? pausedAt = _pausedAt;
    _pausedAt = null;
    final List<String> spent = <String>[];
    for (final OrionToastData toast in _toasts) {
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
        _remaining[toast.id] = left;
        _timerStarts[toast.id] = now;
        _timers[toast.id] = Timer(
          left,
          () => dismiss(toast.id, OrionToastDismissReason.timeout),
        );
      } else {
        spent.add(toast.id);
      }
    }
    for (final String id in spent) {
      _removeToast(id, reason: OrionToastDismissReason.timeout);
    }
    if (spent.isEmpty) {
      notifyListeners();
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
      _timers[data.id] = Timer(
        duration,
        () => dismiss(data.id, OrionToastDismissReason.timeout),
      );
    }
  }

  void _cancelTimer(String id) {
    _timers[id]?.cancel();
    _timers.remove(id);
    _remaining.remove(id);
    _timerStarts.remove(id);
  }

  void _removeToast(String id, {required OrionToastDismissReason reason}) {
    _cancelTimer(id);
    final int index = _toasts.indexWhere((OrionToastData t) => t.id == id);
    if (index >= 0) {
      final OrionToastData removed = _toasts.removeAt(index);
      notifyListeners();
      removed.onDismissed?.call(reason);
    }
  }

  @override
  void dispose() {
    for (final Timer timer in _timers.values) {
      timer.cancel();
    }
    _timers.clear();
    _remaining.clear();
    _timerStarts.clear();
    _toasts.clear();
    super.dispose();
  }
}
