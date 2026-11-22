import 'package:flutter/foundation.dart';

/// Programmatic controller for an [OrionBottomSheet].
///
/// Allows external code to read the active height and detent state, and
/// command the sheet to snap between detents, expand, collapse, or dismiss.
class OrionSheetController extends ChangeNotifier {
  double _currentHeight = 0.0;
  double _currentFraction = 0.0;
  int _currentDetentIndex = 0;
  bool _isDismissed = false;

  void Function(int index)? _snapToDetentHandler;
  void Function(double fraction)? _snapToFractionHandler;
  void Function(Object? result)? _dismissHandler;

  /// Current visual height of the sheet in logical pixels.
  double get currentHeight => _currentHeight;

  /// Current height as a fraction (0.0 to 1.0) of available height.
  double get currentFraction => _currentFraction;

  /// Index of the current or nearest active detent.
  int get currentDetentIndex => _currentDetentIndex;

  /// Whether the sheet has been dismissed.
  bool get isDismissed => _isDismissed;

  /// Internal sync invoked by the sheet implementation on every frame.
  @internal
  void updateState({
    required double height,
    required double fraction,
    required int detentIndex,
    bool isDismissed = false,
  }) {
    if (_currentHeight == height &&
        _currentFraction == fraction &&
        _currentDetentIndex == detentIndex &&
        _isDismissed == isDismissed) {
      return;
    }
    _currentHeight = height;
    _currentFraction = fraction;
    _currentDetentIndex = detentIndex;
    _isDismissed = isDismissed;
    notifyListeners();
  }

  /// Internal handler registration for sheet commands.
  @internal
  void attach({
    required void Function(int index) onSnapToDetent,
    required void Function(double fraction) onSnapToFraction,
    required void Function(Object? result) onDismiss,
  }) {
    _snapToDetentHandler = onSnapToDetent;
    _snapToFractionHandler = onSnapToFraction;
    _dismissHandler = onDismiss;
  }

  /// Internal cleanup when the sheet unmounts.
  @internal
  void detach() {
    _snapToDetentHandler = null;
    _snapToFractionHandler = null;
    _dismissHandler = null;
  }

  /// Smoothly springs the sheet to the detent at [index].
  void snapToDetent(int index) {
    _snapToDetentHandler?.call(index);
  }

  /// Smoothly springs the sheet to [fraction] (0.0 to 1.0) of available height.
  void snapToFraction(double fraction) {
    _snapToFractionHandler?.call(fraction);
  }

  /// Springs the sheet to its highest configured detent.
  void expand() {
    snapToDetent(0x7fffffff); // clamped to highest index
  }

  /// Springs the sheet to its lowest configured detent.
  void collapse() {
    snapToDetent(0);
  }

  /// Smoothly animates the sheet downward and dismisses it, optionally
  /// passing [result] to the modal route's returned [Future].
  void dismiss([Object? result]) {
    _dismissHandler?.call(result);
  }
}
