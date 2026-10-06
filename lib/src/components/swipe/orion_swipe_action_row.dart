import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import 'package:orion_ui/src/components/swipe/orion_swipe_scope.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One action revealed by an [OrionSwipeActionRow].
@immutable
class OrionSwipeAction {
  /// Creates an action.
  const OrionSwipeAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background,
  });

  /// Icon shown in the pane. It is tinted for the background it sits on.
  final Widget icon;

  /// Spoken name, the visible caption, and the label of the accessibility action.
  final String label;

  /// Runs when the action is pressed. Null disables the action: it is inert in
  /// the pane and it contributes no accessibility action.
  final VoidCallback? onPressed;

  /// Pane colour. Defaults to [ColorScheme.error], the destructive role.
  final Color? background;
}

/// A row that reveals actions under a horizontal drag.
///
/// The row owns its own offset. Wrap rows in an [OrionSwipeScope] to get one open
/// row at a time and a closing tap on the surrounding surface.
///
/// ### Why the layer collapses
///
/// The panes are absolutely positioned behind the content and clipped by the row,
/// and they measure zero and paint nothing until the row is dragged open. Being
/// covered by the content is a property of a particular child; being collapsed is a
/// property of the row, so neither a narrow nor a translucent child can expose an
/// action.
///
/// ### Interaction
///
/// Only horizontal drags are claimed, so an enclosing scrollable keeps every vertical
/// drag. Travel is 1:1 across the actions. Past them the row keeps following the
/// finger at a fraction of the travel, and every action on that side grows by the
/// same amount, so a long pull stretches the buttons instead of leaving them rigid.
///
/// A release of at least 18 logical pixels springs back onto the resting actions,
/// however far the finger travelled, unless it is moving back toward closed faster
/// than 120 px/s. Each resting action is 74 logical pixels wide. Nothing runs until
/// an action is pressed.
///
/// While the row is open the content stops taking pointers, so a tap closes the row
/// instead of activating the content. The actions also stay reachable without touch:
/// every enabled action is a custom accessibility action on the row.
class OrionSwipeActionRow extends StatefulWidget {
  /// Creates a swipe action row.
  const OrionSwipeActionRow({
    super.key,
    required this.child,
    this.trailing = const <OrionSwipeAction>[],
    this.leading = const <OrionSwipeAction>[],
    this.enabled = true,
    this.onOpenChanged,
    this.semanticLabel,
  });

  /// Row content. It spans the row and hides the panes.
  final Widget child;

  /// Actions revealed by dragging toward the start edge, laid out after [child]
  /// at the end edge.
  final List<OrionSwipeAction> trailing;

  /// Actions revealed by dragging toward the end edge, laid out before [child]
  /// at the start edge.
  final List<OrionSwipeAction> leading;

  /// False mutes the row: it does not drag, and no action runs.
  final bool enabled;

  /// Reports every open and closed transition.
  final ValueChanged<bool>? onOpenChanged;

  /// Spoken name for the row.
  final String? semanticLabel;

  /// Key on the translated content, so tests and tooling can measure the offset
  /// without walking past the action buttons' own press transforms.
  static const Key contentKey = ValueKey<String>('orion-swipe-content');

  /// Width of one resting action. Wider than the 44 pt hit floor so an icon and
  /// a label are easy to hit, matching the reference mail row.
  static const double actionExtent = 74;

  @override
  State<OrionSwipeActionRow> createState() => _OrionSwipeActionRowState();
}

class _OrionSwipeActionRowState extends State<OrionSwipeActionRow>
    with SingleTickerProviderStateMixin {
  /// The smallest travel that reveals the actions.
  static const double _minOpenTranslation = 18;

  /// A release moving back toward closed faster than this closes the row.
  static const double _closeVelocity = 120;

  /// Past the actions the row follows this fraction of the finger, so the
  /// buttons stretch, and only past the cell does the travel rubber-band.
  static const double _elasticRatio = 0.42;
  static const double _rubberCoef = 0.55;

  /// Below this the row counts as closed, so a settling row behaves as closed.
  static const double _closedEpsilon = 0.5;

  /// Reveal spring. Gentle, so the settle onto the actions does not ring.
  static const OrionSpringSpec _travel = OrionSpringSpec.gentle;

  late final OrionSpringDriver _driver;
  final Object _token = Object();
  final Map<String, CustomSemanticsAction> _customActions =
      <String, CustomSemanticsAction>{};

  OrionSwipeScopeState? _scope;
  bool _reduceMotion = false;
  bool _dragging = false;
  bool _open = false;
  bool _revealed = false;

  /// The side the row opens to: -1 trails, +1 leads.
  int _side = -1;

  /// The row's measured width, cached for the gesture maths. It is a derived
  /// measurement rather than state, so assigning it must not schedule a rebuild.
  double _rowWidth = 0;

  /// The displacement the row is following, in logical pixels, accumulated from
  /// the drag's own deltas. Deltas rather than a position difference, because the
  /// recognizer only starts reporting once it has accepted, and which pointer
  /// position that lands on depends on what else is in the arena.
  double _dragOffset = 0;

  double get _leadingExtent =>
      widget.leading.length * OrionSwipeActionRow.actionExtent;

  double get _trailingExtent =>
      widget.trailing.length * OrionSwipeActionRow.actionExtent;

  double get _offset => _driver.value;

  /// Whether the row has left its closed rest.
  bool get _revealedNow => _offset.abs() >= _closedEpsilon;

  bool get _enabled =>
      widget.enabled &&
      (widget.leading.isNotEmpty || widget.trailing.isNotEmpty);

  OrionThemeData get _orion => OrionTheme.of(context);

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0,
      springSpec: _travel,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final OrionSwipeScopeState? scope = OrionSwipeScope.maybeOf(context);
    if (scope != _scope) {
      _scope?.unregisterRow(_token);
      _scope = scope;
      scope?.registerRow(_token, _close);
    }
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reduceMotion) {
          return;
        }
        _driver.jumpTo(_open ? _openTarget : 0);
      });
    }
  }

  @override
  void didUpdateWidget(OrionSwipeActionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Losing the actions on the open side cannot leave the row stranded open.
    if (_open && (_side < 0 ? _trailingExtent : _leadingExtent) == 0) {
      _setOpen(false);
    }
  }

  @override
  void dispose() {
    _scope?.unregisterRow(_token);
    _driver.dispose();
    super.dispose();
  }

  double get _openTarget => _side < 0 ? -_trailingExtent : _leadingExtent;

  /// Reference `rubberBand`: asymptotic, used once the finger passes the cell.
  double _rubberBand(double overflow, double dimension) {
    if (overflow <= 0 || dimension <= 0) {
      return 0;
    }
    return (1 - 1 / ((overflow * _rubberCoef) / dimension + 1)) * dimension;
  }

  /// Reference `shapeTranslation` with full swipe off.
  ///
  /// 1:1 through the actions, then an elastic follow so the buttons keep
  /// stretching with the finger. Past the cell the extra travel rubber-bands.
  double _shape(double raw, double limit, double cellWidth) {
    if (raw == 0) {
      return 0;
    }
    final double sign = raw.isNegative ? -1 : 1;
    final double abs = raw.abs();
    final double width = cellWidth > 0 ? cellWidth : 1;
    if (limit <= 0) {
      return sign * _rubberBand(abs, width);
    }
    if (abs <= limit) {
      return raw;
    }
    final double elasticPeak = limit + (width - limit) * _elasticRatio;
    if (abs <= width) {
      return sign * (limit + (abs - limit) * _elasticRatio);
    }
    final double refDim = math.max(width - elasticPeak, width * 0.2);
    return sign * (elasticPeak + _rubberBand(abs - width, refDim));
  }

  void _onDragStart(DragStartDetails details) {
    if (!_enabled) {
      return;
    }
    _dragging = true;
    _dragOffset = _offset;
    // Dragging one row closes whichever row the scope had open.
    _scope?.closeActive(except: _token);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) {
      return;
    }
    _dragOffset += details.delta.dx;
    final double limit = _dragOffset < 0 ? _trailingExtent : _leadingExtent;
    _driver.jumpTo(_shape(_dragOffset, limit, _rowWidth));
    _tickThresholds(limit);
  }

  /// One haptic when the actions are uncovered, with hysteresis so a finger
  /// resting on the line cannot chatter.
  void _tickThresholds(double limit) {
    final double abs = _offset.abs();
    if (limit > 0 && abs >= limit) {
      if (!_revealed) {
        _revealed = true;
        OrionHaptics.trigger(_orion.tapHaptic);
      }
    } else if (_revealed && abs < limit * 0.85) {
      _revealed = false;
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _settle(_offset, details.velocity.pixelsPerSecond.dx);
  }

  void _onDragCancel() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _settle(_offset, 0);
  }

  /// Decides where the row rests.
  ///
  /// A release of 18 px or more rests on the actions, however far it travelled,
  /// unless it is really moving closed. Distance never runs an action.
  void _settle(double offset, double velocity) {
    final int side = offset < 0 ? -1 : 1;
    final double limit = side < 0 ? _trailingExtent : _leadingExtent;
    if (limit <= 0) {
      _setOpen(false);
      return;
    }
    final double opening = side < 0 ? -velocity : velocity;
    final bool closing = opening < -_closeVelocity;
    _setOpen(offset.abs() >= _minOpenTranslation && !closing, side: side);
  }

  void _setOpen(bool open, {int? side}) {
    if (open && side != null) {
      _side = side;
    }
    final bool changed = open != _open;
    _open = open;
    _revealed = false;
    final double target = open ? _openTarget : 0;
    if (changed) {
      if (open) {
        _scope?.notifyOpened(_token);
      } else {
        _scope?.notifyClosed(_token);
      }
      widget.onOpenChanged?.call(open);
    }
    if (_reduceMotion) {
      _driver.jumpTo(target);
    } else {
      _driver.springSpec = _travel;
      _driver.retarget(target);
    }
  }

  /// The row's own tap: while open it closes instead of reaching the content, which
  /// is inert by then. While closed the content's own recognizer wins the arena, so
  /// this never runs.
  void _close() {
    if (!_open) {
      return;
    }
    OrionHaptics.trigger(_orion.tapHaptic);
    _setOpen(false);
  }

  /// Runs an action from the pane or from its accessibility action.
  void _invoke(OrionSwipeAction action) {
    if (!_enabled || action.onPressed == null) {
      return;
    }
    OrionHaptics.trigger(_orion.tapHaptic);
    action.onPressed!.call();
    _setOpen(false);
  }

  Map<CustomSemanticsAction, VoidCallback> _semanticsActions() {
    final Map<CustomSemanticsAction, VoidCallback> result =
        <CustomSemanticsAction, VoidCallback>{};
    if (!_enabled) {
      return result;
    }
    for (final OrionSwipeAction action in <OrionSwipeAction>[
      ...widget.leading,
      ...widget.trailing,
    ]) {
      if (action.onPressed == null) {
        continue;
      }
      final CustomSemanticsAction custom = _customActions.putIfAbsent(
        action.label,
        () => CustomSemanticsAction(label: action.label),
      );
      result[custom] = () => _invoke(action);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = _enabled;
    final double leadingExtent = _leadingExtent;
    final double trailingExtent = _trailingExtent;
    final double paneExtent = math.max(leadingExtent, trailingExtent);

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      customSemanticsActions: _semanticsActions(),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: enabled ? _onDragStart : null,
        onHorizontalDragUpdate: enabled ? _onDragUpdate : null,
        onHorizontalDragEnd: enabled ? _onDragEnd : null,
        onHorizontalDragCancel: enabled ? _onDragCancel : null,
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            assert(
              constraints.hasBoundedWidth,
              'OrionSwipeActionRow requires a bounded width.',
            );
            assert(
              !constraints.hasBoundedWidth ||
                  constraints.maxWidth >= paneExtent,
              'OrionSwipeActionRow needs $paneExtent logical pixels for its '
              'actions but was given ${constraints.maxWidth}.',
            );
            final double width = constraints.hasBoundedWidth
                ? constraints.maxWidth
                : paneExtent;
            _rowWidth = width;
            return ClipRect(
              child: Stack(
                children: <Widget>[
                  // Closing tap. It sits at the bottom of the stack so a revealed
                  // action still wins its own press, and it exists only while the
                  // row is open: a row that kept a tap recognizer while closed
                  // would win the arena against an ancestor that wants the tap,
                  // and `_close` would then do nothing with it. The gate follows
                  // the ticker, since a gate read once per build would stay shut
                  // as the row opens.
                  Positioned.fill(
                    child: AnimatedBuilder(
                      animation: _driver,
                      builder: (BuildContext context, Widget? child) {
                        return IgnorePointer(
                          ignoring: !enabled || !_revealedNow,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: _close,
                          ),
                        );
                      },
                    ),
                  ),
                  // The panes are behind the content and collapse to nothing while
                  // the row is closed, so nothing can expose them: not a narrow
                  // child, not a translucent one.
                  Positioned.fill(
                    child: _SwipePaneLayer(
                      driver: _driver,
                      side: -1,
                      extent: leadingExtent,
                      width: width,
                      child: _SwipeActionPane(
                        actions: widget.leading,
                        scheme: scheme,
                        theme: theme,
                        enabled: enabled,
                        onInvoke: _invoke,
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: _SwipePaneLayer(
                      driver: _driver,
                      side: 1,
                      extent: trailingExtent,
                      width: width,
                      child: _SwipeActionPane(
                        actions: widget.trailing,
                        scheme: scheme,
                        theme: theme,
                        enabled: enabled,
                        onInvoke: _invoke,
                      ),
                    ),
                  ),
                  // The content spans the row and is the ticker's stable child, so
                  // a frame only moves a transform. While the row is open it stops
                  // taking pointers.
                  AnimatedBuilder(
                    animation: _driver,
                    child: widget.child,
                    builder: (BuildContext context, Widget? child) {
                      return Transform.translate(
                        key: OrionSwipeActionRow.contentKey,
                        offset: Offset(_offset, 0),
                        child: SizedBox(
                          width: width,
                          child: IgnorePointer(
                            ignoring: _revealedNow,
                            child: child,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// One side's collapsing pane layer: it measures the exposed travel, paints nothing
/// while that is zero, and takes no pointer until the row is open.
class _SwipePaneLayer extends StatelessWidget {
  const _SwipePaneLayer({
    required this.driver,
    required this.side,
    required this.extent,
    required this.width,
    required this.child,
  });

  final OrionSpringDriver driver;
  final int side;
  final double extent;
  final double width;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: driver,
      child: child,
      builder: (BuildContext context, Widget? child) {
        if (extent == 0) {
          return const SizedBox.shrink();
        }
        final double raw = side < 0 ? driver.value : -driver.value;
        final double visible = math.max(0, raw);
        return Align(
          alignment: side < 0
              ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Opacity(
            opacity: visible > 0 ? 1 : 0,
            child: IgnorePointer(
              ignoring: visible < 0.5,
              child: SizedBox(
                width: math.max(extent, math.min(visible, width)),
                height: double.infinity,
                child: ClipRect(child: child),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// The buttons of one side. They share the exposed width equally, so a long
/// pull stretches every button and a release settles them back to
/// [OrionSwipeActionRow.actionExtent].
class _SwipeActionPane extends StatelessWidget {
  const _SwipeActionPane({
    required this.actions,
    required this.scheme,
    required this.theme,
    required this.enabled,
    required this.onInvoke,
  });

  final List<OrionSwipeAction> actions;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool enabled;
  final ValueChanged<OrionSwipeAction> onInvoke;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Row(
      textDirection: TextDirection.ltr,
      children: <Widget>[
        for (final OrionSwipeAction action in actions)
          Expanded(
            child: _SwipeActionButton(
              action: action,
              scheme: scheme,
              theme: theme,
              enabled: enabled && action.onPressed != null,
              onInvoke: () => onInvoke(action),
            ),
          ),
      ],
    );
  }
}

class _SwipeActionButton extends StatelessWidget {
  const _SwipeActionButton({
    required this.action,
    required this.scheme,
    required this.theme,
    required this.enabled,
    required this.onInvoke,
  });

  static const double _iconSize = 20;

  final OrionSwipeAction action;
  final ColorScheme scheme;
  final ThemeData theme;
  final bool enabled;
  final VoidCallback onInvoke;

  @override
  Widget build(BuildContext context) {
    final Color background = enabled
        ? (action.background ?? scheme.error)
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color foreground = enabled
        ? (action.background == null ? scheme.onError : scheme.onSurface)
        : scheme.onSurface.withValues(alpha: 0.38);

    // A disabled action is inert and silent: OrionPressable fires its haptic on the
    // press itself, so excluding the press entirely is what keeps it quiet. The tap
    // then falls through to the row, which closes it if it was open.
    return IgnorePointer(
      ignoring: !enabled,
      child: OrionPressable(
        onTap: enabled ? onInvoke : null,
        hapticType: OrionHapticType.none,
        child: ColoredBox(
          color: background,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                IconTheme.merge(
                  data: IconThemeData(color: foreground, size: _iconSize),
                  child: action.icon,
                ),
                const SizedBox(height: OrionSpacing.space4),
                Text(
                  action.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: (theme.textTheme.labelSmall ?? const TextStyle())
                      .copyWith(color: foreground),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
