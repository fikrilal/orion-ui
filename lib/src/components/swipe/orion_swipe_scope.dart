import 'package:flutter/widgets.dart';

/// Coordinates the [OrionSwipeActionRow]s inside it so only one is open.
///
/// A row works without a scope; it simply cannot coordinate. Inside one, opening a
/// row closes whichever row was open, and a tap on the surrounding surface closes
/// the open row - the behaviour a list of rows has on a phone.
///
/// The surface tap is a translucent tap recognizer, so it loses the arena to any
/// recognizer in the content beneath it: it can close a row, but it cannot swallow
/// a tap meant for a child.
class OrionSwipeScope extends StatefulWidget {
  /// Wraps [child] in a scope.
  const OrionSwipeScope({super.key, required this.child});

  /// The rows and other content this scope coordinates.
  final Widget child;

  /// The nearest enclosing scope, or null when the subtree is unscoped.
  static OrionSwipeScopeState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_OrionSwipeScopeMarker>()
        ?.state;
  }

  @override
  State<OrionSwipeScope> createState() => OrionSwipeScopeState();
}

/// The registry behind an [OrionSwipeScope].
///
/// The members below are the row's contract, not the caller's: an
/// [OrionSwipeActionRow] registers itself, reports its transitions, and is closed
/// by the scope. Application code only ever needs [OrionSwipeScope] itself.
class OrionSwipeScopeState extends State<OrionSwipeScope> {
  final Map<Object, VoidCallback> _closers = <Object, VoidCallback>{};
  Object? _active;

  /// Registers [token] with the callback that closes its row.
  void registerRow(Object token, VoidCallback close) {
    _closers[token] = close;
  }

  /// Forgets a row that left the tree.
  void unregisterRow(Object token) {
    _closers.remove(token);
    if (_active == token) {
      _active = null;
    }
  }

  /// Reports that the row behind [token] left its closed rest.
  ///
  /// Closing the row that was open is the dragging row's job: it calls
  /// [closeActive] as its drag begins, which is earlier than any open transition
  /// and covers a drag that never reaches the extent.
  void notifyOpened(Object token) {
    _active = token;
  }

  /// Reports that the row behind [token] is closed again.
  void notifyClosed(Object token) {
    if (_active == token) {
      _active = null;
    }
  }

  /// Closes the open row, unless it is [except].
  void closeActive({Object? except}) {
    final Object? active = _active;
    if (active == null || active == except) {
      return;
    }
    _closers[active]?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _OrionSwipeScopeMarker(
      state: this,
      child: GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: closeActive,
        child: widget.child,
      ),
    );
  }
}

class _OrionSwipeScopeMarker extends InheritedWidget {
  const _OrionSwipeScopeMarker({required this.state, required super.child});

  final OrionSwipeScopeState state;

  @override
  bool updateShouldNotify(_OrionSwipeScopeMarker oldWidget) =>
      state != oldWidget.state;
}
