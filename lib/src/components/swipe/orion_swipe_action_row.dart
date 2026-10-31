import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart' show CustomSemanticsAction;

import 'package:orion_ui/src/components/swipe/orion_swipe_controller.dart';
import 'package:orion_ui/src/components/swipe/orion_swipe_scope.dart';
import 'package:orion_ui/src/components/swipe/orion_swipe_style.dart';
import 'package:orion_ui/src/components/swipe/orion_swipe_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One action revealed by an [OrionSwipeActionRow].
@immutable
class OrionSwipeAction {
  /// Creates a swipe action button.
  const OrionSwipeAction({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.background,
    this.foreground,
    this.autoClose = true,
    this.showLabel = true,
    this.flex = 1,
    this.semanticLabel,
  }) : assert(flex > 0, 'flex must be positive');

  /// Icon shown in the action button. Inherits [foreground] and the row's
  /// resolved `iconSize`.
  final Widget icon;

  /// Visible caption (when [showLabel] is true) and default accessibility
  /// action name.
  final String label;

  /// Runs when the action is tapped, triggered via full-swipe commit, or
  /// invoked through assistive technology. Null disables the action.
  final VoidCallback? onPressed;

  /// Action button background colour. Defaults to [ColorScheme.error].
  final Color? background;

  /// Optional explicit icon and label colour. When omitted, automatically
  /// selects high-contrast ink based on [background]'s luminance (or
  /// [ColorScheme.onError] when [background] is null).
  final Color? foreground;

  /// Whether triggering this action automatically closes the row. Defaults to
  /// `true`; set `false` for inline toggles or multi-step confirmation flows.
  final bool autoClose;

  /// Whether to show [label] beneath [icon]. Defaults to `true`.
  final bool showLabel;

  /// Relative width weight for this action button. Defaults to `1`.
  final int flex;

  /// Optional spoken override for screen readers. Defaults to [label].
  final String? semanticLabel;
}

/// A row that reveals leading and/or trailing actions under a horizontal drag.
///
/// Features:
/// - **Unified reading-direction physics**: full LTR and RTL support with
///   reversible elastic resistance (zero sticky pull-back dead-zone) and
///   separate open vs. close thresholds so closing an open row feels natural.
/// - **Zero-bleed progressive panes**: action panes clip strictly to the
///   exposed strip (`0..visible`), preventing bleed behind rounded cards or
///   translucent children across `stretch`, `drawer`, and `behind` motions.
/// - **Opt-in full-swipe commit**: set [leadingFullSwipe] or
///   [trailingFullSwipe] to let a deep swipe smoothly morph the outermost
///   action across the full pane with a medium-impact haptic lock and commit on
///   release (retracting cleanly if dragged back).
/// - **Programmatic control & scope coordination**: pass [controller] for
///   imperative open/close, and wrap lists in [OrionSwipeScope] for single-open
///   coordination plus automatic close on scroll or outside touch.
/// - **Style & theme contract**: customize action extent, outer/action border
///   radii, floating pill gaps, motion style, and springs via
///   [OrionSwipeStyle] and [OrionSwipeTheme].
class OrionSwipeActionRow extends StatefulWidget {
  /// Creates a swipe action row.
  const OrionSwipeActionRow({
    super.key,
    required this.child,
    this.trailing = const <OrionSwipeAction>[],
    this.leading = const <OrionSwipeAction>[],
    this.leadingFullSwipe = false,
    this.trailingFullSwipe = false,
    this.enabled = true,
    this.controller,
    this.style,
    this.onOpenChanged,
    this.onSideChanged,
    this.semanticLabel,
  });

  /// Row content. Spans the full row width and slides to expose action panes.
  final Widget child;

  /// Actions anchored at the end edge (right in LTR, left in RTL), revealed by
  /// dragging opposite the reading direction.
  final List<OrionSwipeAction> trailing;

  /// Actions anchored at the start edge (left in LTR, right in RTL), revealed
  /// by dragging in the reading direction.
  final List<OrionSwipeAction> leading;

  /// Whether pulling far past [leading] arms and commits `leading.first` on
  /// release. Defaults to `false`.
  final bool leadingFullSwipe;

  /// Whether pulling far past [trailing] arms and commits `trailing.last` on
  /// release. Defaults to `false`.
  final bool trailingFullSwipe;

  /// False disables dragging, programmatic opening, and all actions.
  final bool enabled;

  /// Optional controller for programmatic open/close and state observation.
  final OrionSwipeController? controller;

  /// Instance-level overrides merged over [OrionSwipeStyle.defaults] and
  /// [OrionSwipeTheme].
  final OrionSwipeStyle? style;

  /// Called whenever the row transitions between closed and open.
  final ValueChanged<bool>? onOpenChanged;

  /// Called whenever the open side changes (`leading`, `trailing`, or `null`
  /// when closed).
  final ValueChanged<OrionSwipeSide?>? onSideChanged;

  /// Spoken name for the row.
  final String? semanticLabel;

  /// Key on the translated content wrapper for geometry inspection.
  static const Key contentKey = ValueKey<String>('orion-swipe-content');

  /// Default width of a single flex-1 resting action.
  static const double actionExtent = 74;

  @override
  State<OrionSwipeActionRow> createState() => _OrionSwipeActionRowState();
}

class _OrionSwipeActionRowState extends State<OrionSwipeActionRow>
    with TickerProviderStateMixin {
  static const double _openFlickVelocity = 260.0;
  static const double _closeFlickVelocity = 220.0;
  static const double _minFlickTravel = 14.0;
  static const double _closedEpsilon = 0.5;
  static const double _armHysteresis = 18.0;

  static const OrionSpringSpec _armSpring = OrionSpringSpec(
    stiffness: 520.0,
    dampingRatio: 0.86,
  );

  final GlobalKey _rowKey = GlobalKey();
  final Object _token = Object();
  final Map<String, CustomSemanticsAction> _customActions =
      <String, CustomSemanticsAction>{};

  /// Logical displacement in reading-direction space:
  /// `> 0` reveals leading actions, `< 0` reveals trailing actions.
  late final OrionSpringDriver _driver;

  /// Drives full-swipe primary-action expansion (`0.0` normal -> `1.0` armed).
  late final OrionSpringDriver _armDriver;

  OrionSwipeScopeState? _scope;
  bool _reduceMotion = false;
  bool _dragging = false;
  bool _open = false;
  OrionSwipeSide? _openSide;
  bool _wasOpenAtDragStart = false;
  OrionSwipeSide? _sideAtDragStart;
  bool _revealTicked = false;
  bool _fullSwipeArmed = false;
  double _rowWidth = 0.0;

  bool get _enabled =>
      widget.enabled &&
      (widget.leading.isNotEmpty || widget.trailing.isNotEmpty);

  double get _offset => _driver.value;

  bool get _revealedNow => _offset.abs() >= _closedEpsilon;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionSwipeStyle.defaultRevealSpring,
    );
    _armDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: _armSpring,
    );
    _attachController(widget.controller);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final OrionSwipeScopeState? scope = OrionSwipeScope.maybeOf(context);
    if (scope != _scope) {
      _scope?.unregisterRow(_token);
      _scope = scope;
      scope?.registerRow(_token, _closeFromScope, hitTest: _hitTestRow);
    }

    _syncMotion();

    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
    _driver.reducedMotion = reduce;
    _armDriver.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reduceMotion) {
          return;
        }
        final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
        _driver.jumpTo(
          _open && _openSide != null ? _targetForSide(_openSide!, style) : 0.0,
        );
        _armDriver.jumpTo(_fullSwipeArmed ? 1.0 : 0.0);
      });
    }
  }

  @override
  void didUpdateWidget(OrionSwipeActionRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach(onClose: _closeProgrammatically);
      _attachController(widget.controller);
    }
    _syncMotion();

    if (!_enabled) {
      if (_dragging) {
        _dragging = false;
      }
      if (_open || _offset.abs() > 0) {
        _setOpen(false);
      }
      return;
    }

    if (_open && _openSide != null) {
      final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
      final double extent = _extentForSide(_openSide!, style);
      if (extent <= 0) {
        _setOpen(false);
      } else if (!_dragging) {
        final double nextTarget = _targetForSide(_openSide!, style);
        if ((_driver.target - nextTarget).abs() > 0.5) {
          _animateDriver(nextTarget, style);
        }
      }
    }
  }

  @override
  void dispose() {
    widget.controller?.detach(onClose: _closeProgrammatically);
    _scope?.unregisterRow(_token);
    _driver.dispose();
    _armDriver.dispose();
    super.dispose();
  }

  void _attachController(OrionSwipeController? controller) {
    controller?.attach(
      onOpen: _openProgrammatically,
      onClose: _closeProgrammatically,
      initialOpenSide: _open ? _openSide : null,
    );
  }

  OrionSwipeStyle _resolveStyle(ThemeData theme) {
    final OrionSwipeTheme swipeTheme =
        theme.extension<OrionSwipeTheme>() ?? OrionSwipeTheme.fallback;
    return OrionSwipeStyle.defaults(
      labelStyle: theme.textTheme.labelSmall,
    ).merge(swipeTheme.defaultStyle).merge(widget.style);
  }

  void _syncMotion() {
    final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
    _driver.springSpec =
        style.revealSpring ?? OrionSwipeStyle.defaultRevealSpring;
  }

  double _baseActionExtent(OrionSwipeStyle style) =>
      math.max(44.0, style.actionExtent ?? OrionSwipeActionRow.actionExtent);

  double _actionGap(OrionSwipeStyle style) =>
      math.max(0.0, style.actionGap ?? 0.0);

  double _extentForActions(
    List<OrionSwipeAction> actions,
    OrionSwipeStyle style,
  ) {
    if (actions.isEmpty) {
      return 0.0;
    }
    final double unit = _baseActionExtent(style);
    final double gap = _actionGap(style);
    int totalFlex = 0;
    for (final OrionSwipeAction action in actions) {
      totalFlex += action.flex;
    }
    return totalFlex * unit + actions.length * gap;
  }

  double _extentForSide(OrionSwipeSide side, OrionSwipeStyle style) {
    return side == OrionSwipeSide.leading
        ? _extentForActions(widget.leading, style)
        : _extentForActions(widget.trailing, style);
  }

  double _targetForSide(OrionSwipeSide side, OrionSwipeStyle style) {
    final double extent = _extentForSide(side, style);
    return side == OrionSwipeSide.leading ? extent : -extent;
  }

  OrionSwipeAction? _primaryActionFor(OrionSwipeSide side) {
    if (side == OrionSwipeSide.leading) {
      if (!widget.leadingFullSwipe || widget.leading.isEmpty) {
        return null;
      }
      final OrionSwipeAction first = widget.leading.first;
      return first.onPressed != null ? first : null;
    } else {
      if (!widget.trailingFullSwipe || widget.trailing.isEmpty) {
        return null;
      }
      final OrionSwipeAction last = widget.trailing.last;
      return last.onPressed != null ? last : null;
    }
  }

  double _fullSwipePx(
    OrionSwipeSide side,
    OrionSwipeStyle style,
    double width,
  ) {
    final double limit = _extentForSide(side, style);
    final double ratio = (style.fullSwipeThreshold ?? 0.58).clamp(0.35, 0.85);
    final double desired = math.max(limit + 36.0, width * ratio);
    return math.min(math.max(limit + 12.0, width * 0.86), desired);
  }

  OrionHapticType _resolveHaptic(OrionSwipeStyle style) =>
      style.hapticType ?? OrionTheme.of(context).selectionHaptic;

  OrionHapticType _resolveFullSwipeHaptic(OrionSwipeStyle style) =>
      style.fullSwipeHapticType ?? OrionHapticType.mediumImpact;

  void _triggerHaptic(OrionHapticType type) {
    if (type != OrionHapticType.none) {
      OrionHaptics.trigger(type);
    }
  }

  bool _hitTestRow(Offset globalPosition) {
    final RenderObject? ro = _rowKey.currentContext?.findRenderObject();
    if (ro is! RenderBox || !ro.hasSize || !ro.attached) {
      return false;
    }
    final Offset local = ro.globalToLocal(globalPosition);
    return (Offset.zero & ro.size).contains(local);
  }

  void _animateArm(double target) {
    if (_reduceMotion) {
      _armDriver.jumpTo(target);
    } else {
      _armDriver.retarget(target);
    }
  }

  void _animateDriver(
    double target,
    OrionSwipeStyle style, {
    double? velocity,
  }) {
    if (_reduceMotion) {
      _driver.jumpTo(target);
    } else {
      _driver.springSpec =
          style.revealSpring ?? OrionSwipeStyle.defaultRevealSpring;
      _driver.retarget(target, velocity: velocity?.clamp(-1800.0, 1800.0));
    }
  }

  double _applyIncrementalDrag(
    double current,
    double logicalDelta,
    OrionSwipeStyle style,
    double width,
  ) {
    if (logicalDelta == 0.0) {
      return current;
    }
    final double nextRaw = current + logicalDelta;
    final OrionSwipeSide side = nextRaw >= 0
        ? OrionSwipeSide.leading
        : OrionSwipeSide.trailing;
    final double limit = _extentForSide(side, style);
    final double safeWidth = math.max(width, math.max(limit, 1.0));
    final bool pullingOutward =
        current == 0.0 ||
        (logicalDelta > 0 && current > 0) ||
        (logicalDelta < 0 && current < 0);

    // Side has no actions: short subtle rubber-band resistance outward, 1:1 back.
    if (limit <= 0.0) {
      if (!pullingOutward) {
        // Crossing back toward zero.
        return (current > 0 && nextRaw < 0) || (current < 0 && nextRaw > 0)
            ? 0.0
            : nextRaw;
      }
      final double absCur = current.abs();
      final double factor = 0.22 / (1.0 + absCur / 36.0);
      final double maxNoActionBounce = math.min(34.0, safeWidth * 0.12);
      final double next = current + logicalDelta * factor;
      return next.clamp(-maxNoActionBounce, maxNoActionBounce).toDouble();
    }

    final bool hasFullSwipe = _primaryActionFor(side) != null;
    final double absCur = current.abs();

    // Returning inward from overscroll responds immediately with zero dead-zone.
    if (!pullingOutward) {
      if (absCur > limit) {
        return current + logicalDelta * 0.92;
      }
      return nextRaw;
    }

    // Pulling outward: split any single frame that crosses `limit` so big moves
    // damp past the extent identically to small incremental moves.
    final double sign = nextRaw < 0 ? -1.0 : 1.0;
    double position = absCur;
    double remaining = logicalDelta.abs();

    if (position < limit) {
      final double toLimit = math.min(remaining, limit - position);
      position += toLimit;
      remaining -= toLimit;
    }

    if (remaining <= 0.0) {
      return sign * position;
    }

    if (hasFullSwipe) {
      final double softCap = safeWidth * 0.92;
      if (position < softCap) {
        final double toSoftCap = math.min(remaining * 0.85, softCap - position);
        position += toSoftCap;
        remaining = math.max(0.0, remaining - toSoftCap / 0.85);
      }
      if (remaining > 0.0) {
        final double over = position - softCap;
        final double factor = 0.20 / (1.0 + (over + remaining * 0.5) / 40.0);
        position += remaining * factor;
      }
      return sign * position;
    }

    // Non-full-swipe elastic stretch: smooth asymptotic resistance.
    final double over = position - limit;
    final double denom = math.max(120.0, safeWidth * 0.55);
    final double factor = 0.42 / (1.0 + (over + remaining * 0.5) / denom);
    position += remaining * factor;
    return sign * position;
  }

  void _onDragStart(DragStartDetails details) {
    if (!_enabled) {
      return;
    }
    _dragging = true;
    _wasOpenAtDragStart = _open;
    _sideAtDragStart = _open ? _openSide : null;
    _revealTicked = _open;
    _fullSwipeArmed = false;
    _animateArm(0.0);
    // Stop any running spring in place so picking up mid-flight never snaps.
    _driver.jumpTo(_driver.value);
    _scope?.closeActive(except: _token);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_dragging) {
      return;
    }
    final ThemeData theme = Theme.of(context);
    final OrionSwipeStyle style = _resolveStyle(theme);
    final double dirSign = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final double logicalDelta = details.delta.dx * dirSign;

    final double nextX = _applyIncrementalDrag(
      _driver.value,
      logicalDelta,
      style,
      _rowWidth,
    );
    _driver.jumpTo(nextX);
    _updateDragThresholds(nextX, style);
  }

  void _updateDragThresholds(double x, OrionSwipeStyle style) {
    final double absX = x.abs();
    if (absX < _closedEpsilon) {
      if (_fullSwipeArmed) {
        _fullSwipeArmed = false;
        _animateArm(0.0);
      }
      _revealTicked = false;
      return;
    }

    final OrionSwipeSide side = x > 0
        ? OrionSwipeSide.leading
        : OrionSwipeSide.trailing;
    final double limit = _extentForSide(side, style);
    if (limit <= 0) {
      return;
    }

    final OrionHapticType haptic = _resolveHaptic(style);

    // Reveal threshold tick with hysteresis.
    if (absX >= limit) {
      if (!_revealTicked) {
        _revealTicked = true;
        _triggerHaptic(haptic);
      }
    } else if (_revealTicked && absX < limit * 0.80) {
      _revealTicked = false;
    }

    // Full-swipe commit threshold with hysteresis.
    if (_primaryActionFor(side) != null && _rowWidth > 0) {
      final double armPx = _fullSwipePx(side, style, _rowWidth);
      if (!_fullSwipeArmed && absX >= armPx) {
        _fullSwipeArmed = true;
        _animateArm(1.0);
        _triggerHaptic(_resolveFullSwipeHaptic(style));
      } else if (_fullSwipeArmed && absX < armPx - _armHysteresis) {
        _fullSwipeArmed = false;
        _animateArm(0.0);
        _triggerHaptic(haptic);
      }
    } else if (_fullSwipeArmed) {
      _fullSwipeArmed = false;
      _animateArm(0.0);
    }
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    final double dirSign = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;
    final double logicalVelocity =
        details.velocity.pixelsPerSecond.dx * dirSign;
    _settle(_driver.value, logicalVelocity);
  }

  void _onDragCancel() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _settle(_driver.value, 0.0);
  }

  void _settle(double x, double logicalVelocity) {
    final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
    final OrionSwipeSide side = x >= 0
        ? OrionSwipeSide.leading
        : OrionSwipeSide.trailing;
    final double limit = _extentForSide(side, style);

    if (limit <= 0.0) {
      _fullSwipeArmed = false;
      _animateArm(0.0);
      _setOpen(false);
      return;
    }

    final double absX = x.abs();
    final double openingVel = side == OrionSwipeSide.leading
        ? logicalVelocity
        : -logicalVelocity;

    // Commit full-swipe primary action when armed and not flicked back closed.
    final OrionSwipeAction? primary = _primaryActionFor(side);
    if (_fullSwipeArmed && primary != null && openingVel > -250.0) {
      _fullSwipeArmed = false;
      _animateArm(0.0);
      _commitAction(primary, haptic: OrionHapticType.none);
      return;
    }

    if (_fullSwipeArmed) {
      _fullSwipeArmed = false;
      _animateArm(0.0);
    }

    final bool startedOpenSameSide =
        _wasOpenAtDragStart && _sideAtDragStart == side;

    final bool shouldOpen;
    if (startedOpenSameSide) {
      // Starting open: dragging 28% back or flicking closed closes naturally.
      final bool flickClosed = openingVel <= -_closeFlickVelocity;
      final bool draggedClosed =
          openingVel < _openFlickVelocity && absX < limit * 0.72;
      shouldOpen = !flickClosed && !draggedClosed;
    } else {
      // Starting closed (or switched sides): require intentional travel or flick.
      final double openThreshold = math.min(limit * 0.42, 64.0);
      final bool flickOpen =
          openingVel >= _openFlickVelocity && absX >= _minFlickTravel;
      final bool draggedOpen =
          openingVel > -_closeFlickVelocity && absX >= openThreshold;
      shouldOpen = flickOpen || draggedOpen;
    }

    _setOpen(
      shouldOpen,
      side: shouldOpen ? side : null,
      velocity: logicalVelocity,
    );
  }

  void _setOpen(bool open, {OrionSwipeSide? side, double? velocity}) {
    final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
    final OrionSwipeSide? nextSide = open ? (side ?? _openSide) : null;
    final bool effectiveOpen =
        open && nextSide != null && _extentForSide(nextSide, style) > 0;
    final OrionSwipeSide? resolvedSide = effectiveOpen ? nextSide : null;

    final bool openChanged = effectiveOpen != _open;
    final bool sideChanged = resolvedSide != _openSide;

    _open = effectiveOpen;
    _openSide = resolvedSide;
    _revealTicked = effectiveOpen;
    if (!effectiveOpen && _fullSwipeArmed) {
      _fullSwipeArmed = false;
      _animateArm(0.0);
    }

    if (effectiveOpen) {
      _scope?.notifyOpened(_token);
    } else {
      _scope?.notifyClosed(_token);
    }

    widget.controller?.syncState(resolvedSide);

    if (openChanged) {
      widget.onOpenChanged?.call(effectiveOpen);
    }
    if (sideChanged) {
      widget.onSideChanged?.call(resolvedSide);
    }

    final double target = effectiveOpen && resolvedSide != null
        ? _targetForSide(resolvedSide, style)
        : 0.0;
    _animateDriver(target, style, velocity: velocity);
  }

  void _openProgrammatically(OrionSwipeSide side) {
    if (!mounted || !_enabled) {
      return;
    }
    final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
    if (_extentForSide(side, style) <= 0) {
      return;
    }
    _scope?.closeActive(except: _token);
    _setOpen(true, side: side);
  }

  void _closeProgrammatically() {
    if (!mounted) {
      return;
    }
    if (_open || _offset.abs() >= _closedEpsilon) {
      _setOpen(false);
    }
  }

  void _closeFromScope() {
    if (!mounted) {
      return;
    }
    if (_open || _offset.abs() >= _closedEpsilon) {
      _setOpen(false);
    }
  }

  void _closeFromTap() {
    if (!_open) {
      return;
    }
    final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
    _triggerHaptic(_resolveHaptic(style));
    _setOpen(false);
  }

  void _invokeFromPane(OrionSwipeAction action) {
    // Guard against rapid double-taps during the animated close tail.
    if (!_enabled || !_open || action.onPressed == null) {
      return;
    }
    final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
    _commitAction(action, haptic: _resolveHaptic(style));
  }

  void _invokeFromSemantics(OrionSwipeAction action) {
    if (!_enabled || action.onPressed == null) {
      return;
    }
    final OrionSwipeStyle style = _resolveStyle(Theme.of(context));
    _commitAction(action, haptic: _resolveHaptic(style));
  }

  void _commitAction(
    OrionSwipeAction action, {
    required OrionHapticType haptic,
  }) {
    _triggerHaptic(haptic);
    if (action.autoClose) {
      _setOpen(false);
    } else if (_openSide != null) {
      // Snap back cleanly from full-swipe overscroll while keeping tray open.
      _setOpen(true, side: _openSide);
    }
    action.onPressed?.call();
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
      final String spoken = action.semanticLabel ?? action.label;
      final CustomSemanticsAction custom = _customActions.putIfAbsent(
        spoken,
        () => CustomSemanticsAction(label: spoken),
      );
      result[custom] = () => _invokeFromSemantics(action);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionSwipeStyle style = _resolveStyle(theme);
    final bool enabled = _enabled;
    final TextDirection textDirection = Directionality.of(context);
    final double dirSign = textDirection == TextDirection.rtl ? -1.0 : 1.0;

    final double leadingExtent = _extentForActions(widget.leading, style);
    final double trailingExtent = _extentForActions(widget.trailing, style);
    final double maxExtent = math.max(leadingExtent, trailingExtent);
    final BorderRadius outerRadius = style.borderRadius ?? BorderRadius.zero;
    final BorderRadius actionRadius = style.actionRadius ?? BorderRadius.zero;
    final double actionGap = _actionGap(style);
    final OrionSwipeMotion motion = style.motion ?? OrionSwipeMotion.stretch;
    final double iconSize = style.iconSize ?? 20.0;
    final TextStyle labelStyle =
        style.labelStyle ?? theme.textTheme.labelSmall ?? const TextStyle();

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      customSemanticsActions: _semanticsActions(),
      child: KeyedSubtree(
        key: _rowKey,
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
              final double width = constraints.hasBoundedWidth
                  ? constraints.maxWidth
                  : maxExtent;
              _rowWidth = width;

              final Widget contentStack = Stack(
                children: <Widget>[
                  if (widget.leading.isNotEmpty)
                    Positioned.fill(
                      child: _SwipePaneLayer(
                        driver: _driver,
                        armDriver: _armDriver,
                        side: OrionSwipeSide.leading,
                        actions: widget.leading,
                        primaryIndex:
                            _primaryActionFor(OrionSwipeSide.leading) != null
                            ? 0
                            : null,
                        extent: leadingExtent,
                        actionGap: actionGap,
                        actionRadius: actionRadius,
                        motion: motion,
                        width: width,
                        iconSize: iconSize,
                        labelStyle: labelStyle,
                        scheme: scheme,
                        enabled: enabled,
                        onInvoke: _invokeFromPane,
                        onBackgroundTap: _closeFromTap,
                      ),
                    ),
                  if (widget.trailing.isNotEmpty)
                    Positioned.fill(
                      child: _SwipePaneLayer(
                        driver: _driver,
                        armDriver: _armDriver,
                        side: OrionSwipeSide.trailing,
                        actions: widget.trailing,
                        primaryIndex:
                            _primaryActionFor(OrionSwipeSide.trailing) != null
                            ? widget.trailing.length - 1
                            : null,
                        extent: trailingExtent,
                        actionGap: actionGap,
                        actionRadius: actionRadius,
                        motion: motion,
                        width: width,
                        iconSize: iconSize,
                        labelStyle: labelStyle,
                        scheme: scheme,
                        enabled: enabled,
                        onInvoke: _invokeFromPane,
                        onBackgroundTap: _closeFromTap,
                      ),
                    ),
                  AnimatedBuilder(
                    animation: _driver,
                    child: widget.child,
                    builder: (BuildContext context, Widget? child) {
                      final double screenOffset = _offset * dirSign;
                      final bool openOrMoving = _revealedNow;
                      return Transform.translate(
                        key: OrionSwipeActionRow.contentKey,
                        offset: Offset(screenOffset, 0.0),
                        child: SizedBox(
                          width: width,
                          child: Stack(
                            children: <Widget>[
                              IgnorePointer(
                                ignoring: openOrMoving,
                                child: SizedBox(width: width, child: child),
                              ),
                              if (openOrMoving && enabled)
                                Positioned.fill(
                                  child: GestureDetector(
                                    behavior: HitTestBehavior.opaque,
                                    onTap: _closeFromTap,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              );

              if (outerRadius == BorderRadius.zero) {
                return ClipRect(child: contentStack);
              }
              return ClipRRect(borderRadius: outerRadius, child: contentStack);
            },
          ),
        ),
      ),
    );
  }
}

class _SwipePaneLayer extends StatelessWidget {
  const _SwipePaneLayer({
    required this.driver,
    required this.armDriver,
    required this.side,
    required this.actions,
    required this.primaryIndex,
    required this.extent,
    required this.actionGap,
    required this.actionRadius,
    required this.motion,
    required this.width,
    required this.iconSize,
    required this.labelStyle,
    required this.scheme,
    required this.enabled,
    required this.onInvoke,
    required this.onBackgroundTap,
  });

  final OrionSpringDriver driver;
  final OrionSpringDriver armDriver;
  final OrionSwipeSide side;
  final List<OrionSwipeAction> actions;
  final int? primaryIndex;
  final double extent;
  final double actionGap;
  final BorderRadius actionRadius;
  final OrionSwipeMotion motion;
  final double width;
  final double iconSize;
  final TextStyle labelStyle;
  final ColorScheme scheme;
  final bool enabled;
  final ValueChanged<OrionSwipeAction> onInvoke;
  final VoidCallback onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    final bool isLeading = side == OrionSwipeSide.leading;
    final AlignmentGeometry outerAlign = isLeading
        ? AlignmentDirectional.centerStart
        : AlignmentDirectional.centerEnd;
    final AlignmentGeometry contentEdgeAlign = isLeading
        ? AlignmentDirectional.centerEnd
        : AlignmentDirectional.centerStart;

    return AnimatedBuilder(
      animation: Listenable.merge(<Listenable>[driver, armDriver]),
      builder: (BuildContext context, Widget? _) {
        if (extent <= 0.0) {
          return const SizedBox.shrink();
        }
        final double raw = isLeading ? driver.value : -driver.value;
        final double visible = raw.clamp(0.0, width).toDouble();
        if (visible <= 0.01) {
          return const SizedBox.shrink();
        }

        final double effectiveEdgeGap = actionGap > 0.0
            ? math.min(actionGap, visible)
            : 0.0;
        final double exposedPaneWidth = math.max(
          0.0,
          visible - effectiveEdgeGap,
        );
        if (exposedPaneWidth <= 0.01) {
          return const SizedBox.shrink();
        }

        final double restingPaneWidth = math.max(0.0, extent - actionGap);
        final double arm = primaryIndex != null
            ? armDriver.value.clamp(0.0, 1.0)
            : 0.0;

        final double laidOutWidth = switch (motion) {
          OrionSwipeMotion.stretch => exposedPaneWidth,
          OrionSwipeMotion.drawer || OrionSwipeMotion.behind => math.max(
            restingPaneWidth,
            exposedPaneWidth,
          ),
        };

        final Widget pane = _SwipeActionPane(
          actions: actions,
          primaryIndex: primaryIndex,
          arm: arm,
          availableWidth: laidOutWidth,
          actionGap: actionGap,
          actionRadius: actionRadius,
          iconSize: iconSize,
          labelStyle: labelStyle,
          scheme: scheme,
          enabled: enabled,
          onInvoke: onInvoke,
          onBackgroundTap: onBackgroundTap,
        );

        Widget clipped;
        if (motion == OrionSwipeMotion.stretch) {
          clipped = SizedBox(
            width: exposedPaneWidth,
            height: double.infinity,
            child: ClipRect(child: pane),
          );
        } else {
          final AlignmentGeometry overflowAlign =
              motion == OrionSwipeMotion.drawer ? contentEdgeAlign : outerAlign;
          clipped = SizedBox(
            width: exposedPaneWidth,
            height: double.infinity,
            child: ClipRect(
              child: OverflowBox(
                minWidth: laidOutWidth,
                maxWidth: laidOutWidth,
                alignment: overflowAlign,
                child: SizedBox(width: laidOutWidth, child: pane),
              ),
            ),
          );
        }

        return Align(
          alignment: outerAlign,
          child: IgnorePointer(ignoring: visible < 0.5, child: clipped),
        );
      },
    );
  }
}

class _SwipeActionPane extends StatelessWidget {
  const _SwipeActionPane({
    required this.actions,
    required this.primaryIndex,
    required this.arm,
    required this.availableWidth,
    required this.actionGap,
    required this.actionRadius,
    required this.iconSize,
    required this.labelStyle,
    required this.scheme,
    required this.enabled,
    required this.onInvoke,
    required this.onBackgroundTap,
  });

  final List<OrionSwipeAction> actions;
  final int? primaryIndex;
  final double arm;
  final double availableWidth;
  final double actionGap;
  final BorderRadius actionRadius;
  final double iconSize;
  final TextStyle labelStyle;
  final ColorScheme scheme;
  final bool enabled;
  final ValueChanged<OrionSwipeAction> onInvoke;
  final VoidCallback onBackgroundTap;

  @override
  Widget build(BuildContext context) {
    if (actions.isEmpty || availableWidth <= 0.0) {
      return const SizedBox.shrink();
    }

    final int count = actions.length;
    final double desiredGap = count > 1 ? actionGap * (1.0 - arm) : 0.0;
    final double maxSafeGap = count > 1
        ? math.max(0.0, (availableWidth - count) / (count - 1))
        : 0.0;
    final double effectiveGap = math.min(desiredGap, maxSafeGap);
    final double totalGaps = effectiveGap * (count - 1);
    final double contentBudget = math.max(0.0, availableWidth - totalGaps);

    int totalFlex = 0;
    for (final OrionSwipeAction a in actions) {
      totalFlex += a.flex;
    }

    final List<double> widths = List<double>.filled(count, 0.0);
    if (primaryIndex != null && arm > 0.0 && count > 1) {
      final double primaryNormal =
          contentBudget * (actions[primaryIndex!].flex / totalFlex);
      final double primaryWidth =
          primaryNormal + (contentBudget - primaryNormal) * arm;
      final double siblingBudget = math.max(0.0, contentBudget - primaryWidth);
      final int siblingFlex = totalFlex - actions[primaryIndex!].flex;
      for (int i = 0; i < count; i++) {
        if (i == primaryIndex) {
          widths[i] = primaryWidth;
        } else {
          widths[i] = siblingFlex > 0
              ? siblingBudget * (actions[i].flex / siblingFlex)
              : 0.0;
        }
      }
    } else {
      for (int i = 0; i < count; i++) {
        widths[i] = totalFlex > 0
            ? contentBudget * (actions[i].flex / totalFlex)
            : 0.0;
      }
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (int i = 0; i < count; i++) ...<Widget>[
          if (i > 0 && effectiveGap > 0.01) SizedBox(width: effectiveGap),
          if (widths[i] > 0.01)
            SizedBox(
              width: widths[i],
              child: _SwipeActionButton(
                action: actions[i],
                width: widths[i],
                armedScale: (i == primaryIndex && arm > 0.0)
                    ? 1.0 + 0.10 * arm
                    : 1.0,
                contentOpacity: (primaryIndex != null && i != primaryIndex)
                    ? (1.0 - arm * 2.0).clamp(0.0, 1.0)
                    : 1.0,
                actionRadius: actionRadius,
                iconSize: iconSize,
                labelStyle: labelStyle,
                scheme: scheme,
                enabled: enabled && actions[i].onPressed != null,
                onInvoke: () => onInvoke(actions[i]),
                onDisabledTap: onBackgroundTap,
              ),
            ),
        ],
      ],
    );
  }
}

class _SwipeActionButton extends StatefulWidget {
  const _SwipeActionButton({
    required this.action,
    required this.width,
    required this.armedScale,
    required this.contentOpacity,
    required this.actionRadius,
    required this.iconSize,
    required this.labelStyle,
    required this.scheme,
    required this.enabled,
    required this.onInvoke,
    required this.onDisabledTap,
  });

  final OrionSwipeAction action;
  final double width;
  final double armedScale;
  final double contentOpacity;
  final BorderRadius actionRadius;
  final double iconSize;
  final TextStyle labelStyle;
  final ColorScheme scheme;
  final bool enabled;
  final VoidCallback onInvoke;
  final VoidCallback onDisabledTap;

  @override
  State<_SwipeActionButton> createState() => _SwipeActionButtonState();
}

class _SwipeActionButtonState extends State<_SwipeActionButton> {
  bool _hovered = false;

  @override
  void didUpdateWidget(_SwipeActionButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _hovered) {
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrionSwipeAction action = widget.action;
    final ColorScheme scheme = widget.scheme;
    final bool enabled = widget.enabled;

    final Color baseBackground = enabled
        ? (action.background ?? scheme.error)
        : scheme.onSurface.withValues(alpha: 0.12);

    final Color foreground;
    if (!enabled) {
      foreground = scheme.onSurface.withValues(alpha: 0.38);
    } else if (action.foreground != null) {
      foreground = action.foreground!;
    } else if (action.background == null) {
      foreground = scheme.onError;
    } else {
      final Brightness bgBrightness = ThemeData.estimateBrightnessForColor(
        baseBackground,
      );
      foreground = bgBrightness == Brightness.dark
          ? Colors.white
          : const Color(0xFF0A0A0A);
    }

    final Color hoverOverlay =
        ThemeData.estimateBrightnessForColor(baseBackground) == Brightness.dark
        ? Colors.white.withValues(alpha: 0.10)
        : Colors.black.withValues(alpha: 0.06);

    final Color effectiveBackground = (_hovered && enabled)
        ? Color.alphaBlend(hoverOverlay, baseBackground)
        : baseBackground;

    final double revealAlpha = (widget.width / 32.0).clamp(0.0, 1.0);
    final double totalOpacity = revealAlpha * widget.contentOpacity;

    Widget surface = DecoratedBox(
      decoration: BoxDecoration(
        color: effectiveBackground,
        borderRadius: widget.actionRadius == BorderRadius.zero
            ? null
            : widget.actionRadius,
      ),
      child: ClipRect(
        child: Center(
          child: Opacity(
            opacity: totalOpacity,
            child: Transform.scale(
              scale: widget.armedScale,
              child: OverflowBox(
                minWidth: 0.0,
                maxWidth: math.max(widget.width - 8.0, 48.0),
                minHeight: 0.0,
                maxHeight: double.infinity,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconTheme.merge(
                      data: IconThemeData(
                        color: foreground,
                        size: widget.iconSize,
                      ),
                      child: action.icon,
                    ),
                    if (action.showLabel) ...<Widget>[
                      const SizedBox(height: OrionSpacing.space4),
                      Text(
                        action.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: widget.labelStyle.copyWith(color: foreground),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!enabled) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onDisabledTap,
        child: surface,
      );
    }

    return Semantics(
      button: true,
      enabled: true,
      label: action.semanticLabel ?? action.label,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) {
          if (mounted && !_hovered) {
            setState(() => _hovered = true);
          }
        },
        onExit: (_) {
          if (mounted && _hovered) {
            setState(() => _hovered = false);
          }
        },
        child: OrionPressable(
          onTap: widget.onInvoke,
          hapticType: OrionHapticType.none,
          child: surface,
        ),
      ),
    );
  }
}
