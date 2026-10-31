import 'package:flutter/widgets.dart';

/// Coordinates the [OrionSwipeActionRow]s inside it so at most one row stays
/// open at a time.
///
/// Inside an [OrionSwipeScope]:
/// - Dragging or opening one row closes whichever row was previously open.
/// - Touching anywhere outside the active open row closes it immediately via a
///   passive [Listener] (without stealing taps from sibling rows or buttons).
/// - Starting a scroll in either a descendant or enclosing [Scrollable] closes
///   the active open row so rows never stay stranded open mid-scroll.
class OrionSwipeScope extends StatefulWidget {
  /// Wraps [child] in a swipe coordination scope.
  const OrionSwipeScope({super.key, required this.child});

  /// The rows and surrounding content this scope coordinates.
  final Widget child;

  /// The nearest enclosing scope, or `null` when the subtree is unscoped.
  static OrionSwipeScopeState? maybeOf(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_OrionSwipeScopeMarker>()
        ?.state;
  }

  /// Closes whichever row is currently open inside the nearest enclosing
  /// [OrionSwipeScope], if any.
  static void closeAll(BuildContext context) {
    maybeOf(context)?.closeActive();
  }

  @override
  State<OrionSwipeScope> createState() => OrionSwipeScopeState();
}

/// The coordination registry behind an [OrionSwipeScope].
class OrionSwipeScopeState extends State<OrionSwipeScope> {
  final Map<Object, VoidCallback> _closers = <Object, VoidCallback>{};
  final Map<Object, bool Function(Offset globalPosition)> _hitTesters =
      <Object, bool Function(Offset globalPosition)>{};
  Object? _active;
  ScrollPosition? _ancestorScrollPosition;

  /// Whether any coordinated row is currently open.
  bool get hasActiveRow => _active != null;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ScrollPosition? position = Scrollable.maybeOf(context)?.position;
    if (position != _ancestorScrollPosition) {
      _ancestorScrollPosition?.isScrollingNotifier.removeListener(
        _onAncestorScrollChanged,
      );
      _ancestorScrollPosition = position;
      _ancestorScrollPosition?.isScrollingNotifier.addListener(
        _onAncestorScrollChanged,
      );
    }
  }

  @override
  void dispose() {
    _ancestorScrollPosition?.isScrollingNotifier.removeListener(
      _onAncestorScrollChanged,
    );
    _ancestorScrollPosition = null;
    _closers.clear();
    _hitTesters.clear();
    super.dispose();
  }

  void _onAncestorScrollChanged() {
    if (_ancestorScrollPosition?.isScrollingNotifier.value ?? false) {
      closeActive();
    }
  }

  /// Registers [token] with its close callback and an optional screen-space
  /// hit-test predicate used to detect outside pointer taps.
  void registerRow(
    Object token,
    VoidCallback close, {
    bool Function(Offset globalPosition)? hitTest,
  }) {
    _closers[token] = close;
    if (hitTest != null) {
      _hitTesters[token] = hitTest;
    } else {
      _hitTesters.remove(token);
    }
  }

  /// Forgets a row that left the tree.
  void unregisterRow(Object token) {
    _closers.remove(token);
    _hitTesters.remove(token);
    if (_active == token) {
      _active = null;
    }
  }

  /// Marks [token] as the single open row in this scope.
  void notifyOpened(Object token) {
    if (_active != null && _active != token) {
      _closers[_active]?.call();
    }
    _active = token;
  }

  /// Clears [token] if it was the active open row.
  void notifyClosed(Object token) {
    if (_active == token) {
      _active = null;
    }
  }

  /// Closes the currently open row, unless it is [except].
  void closeActive({Object? except}) {
    final Object? active = _active;
    if (active == null || active == except) {
      return;
    }
    _active = null;
    _closers[active]?.call();
  }

  void _handlePointerDown(PointerDownEvent event) {
    final Object? active = _active;
    if (active == null) {
      return;
    }
    final bool Function(Offset)? hitTest = _hitTesters[active];
    if (hitTest != null && hitTest(event.position)) {
      return;
    }
    closeActive();
  }

  bool _handleScrollStart(ScrollStartNotification notification) {
    if (notification.dragDetails != null) {
      closeActive();
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return _OrionSwipeScopeMarker(
      state: this,
      child: NotificationListener<ScrollStartNotification>(
        onNotification: _handleScrollStart,
        child: Listener(
          behavior: HitTestBehavior.translucent,
          onPointerDown: _handlePointerDown,
          child: widget.child,
        ),
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
