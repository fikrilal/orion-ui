import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/wheel/orion_wheel_picker_presets.dart';
import 'package:orion_ui/src/components/wheel/orion_wheel_picker_style.dart';
import 'package:orion_ui/src/components/wheel/orion_wheel_picker_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One option in an [OrionWheelPicker].
@immutable
class OrionWheelItem<T> {
  /// Creates a wheel option.
  const OrionWheelItem({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  /// Value reported when this item is centred.
  final T value;

  /// Visible content. A plain `Text` inherits the resolved row text style
  /// (tabular numerals by default, with stronger emphasis when centred).
  final Widget label;

  /// Spoken name of this item.
  ///
  /// [label] is a widget, so the picker cannot read its text. Pass this when the
  /// label is not a plain [Text]; otherwise the spoken value falls back to the
  /// `Text` data, then to the item's position ("3 of 12").
  final String? semanticLabel;
}

/// A cylindrical vertical wheel picker on one retargeted spring.
///
/// The offset is a single scalar in item units: an integer value means that item
/// is centred inside the selection loupe. A drag moves the offset directly so
/// the drum tracks the finger 1:1; releasing hands the finger's velocity into a
/// critically damped [OrionSpringDriver] settle that always finishes cleanly on
/// a detent. Touching down on a spinning wheel immediately arrests momentum.
///
/// Features:
/// - **Cylindrical 3D drum**: subtle X-axis perspective tilt, depth-curved
///   opacity falloff, and background-agnostic top/bottom edge dissolve.
/// - **Centre selection loupe**: translucent pill or precision hairline rules,
///   with configurable [OrionWheelPickerStyle.selectionRadius] for seamless
///   multi-column pickers (time, date, duration).
/// - **Infinite looping** (`looping: true`): seamless modular wrap-around with
///   shortest-path glides on tap and external value updates.
/// - **Asymptotic rubber-banding**: iOS-style hyperbolic end resistance when
///   not looping, so long pulls never drag rows off-screen.
/// - **Full desktop & a11y input**: mouse-wheel / trackpad scroll, hold-to-repeat
///   Arrow keys, PageUp/PageDown, Home/End, and one adjustable semantics node.
/// - **Zero-rebuild tick invariant**: row labels build only on detent crossings,
///   never on animation frames.
class OrionWheelPicker<T> extends StatefulWidget {
  /// Creates a controlled wheel picker.
  const OrionWheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.onActiveChanged,
    this.visibleItemCount = 5,
    this.looping = false,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  });

  /// Options, in wheel order. Must be non-empty, with unique values.
  final List<OrionWheelItem<T>> items;

  /// Currently centred value. Must equal one item's value.
  final T value;

  /// Called with the newly centred value once the wheel comes to rest on it.
  /// Null disables the wheel.
  final ValueChanged<T>? onChanged;

  /// Optional live callback invoked whenever the centred item changes while
  /// dragging or gliding, before the wheel settles and invokes [onChanged].
  final ValueChanged<T>? onActiveChanged;

  /// How many item slots the wheel spans. Must be odd and at least 3, so one
  /// slot is the centre.
  final int visibleItemCount;

  /// Whether the wheel wraps infinitely around the ends (ideal for hours,
  /// minutes, seconds, and months). Ignored when [items] has a single item.
  final bool looping;

  /// Spoken name for the wheel, such as "Month". The centred item is announced
  /// separately as its value.
  final String? semanticLabel;

  /// Optional focus node for arrow-key movement.
  final FocusNode? focusNode;

  /// Whether the wheel requests focus on first build.
  final bool autofocus;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionWheelPickerTheme]. Only the fields set here change.
  final OrionWheelPickerStyle? style;

  @override
  State<OrionWheelPicker<T>> createState() => _OrionWheelPickerState<T>();
}

class _OrionWheelPickerState<T> extends State<OrionWheelPicker<T>>
    with SingleTickerProviderStateMixin {
  static const double _itemExtent = OrionSizing.minHitTarget;
  static const double _edgeScale = 0.7;
  static const double _defaultDiameterRatio = 1.07;
  static const double _defaultPerspective = 0.003;
  static const double _defaultSqueeze = 1.25;
  static const double _projectionSeconds = 0.08;
  static const double _endResistance = 0.35;
  static const double _maxRubberBandOverscroll = 1.6;
  static const OrionSpringSpec _settleSpec = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  late final OrionSpringDriver _driver;
  final ValueNotifier<bool> _draggingNotifier = ValueNotifier<bool>(false);
  FocusNode? _ownedFocusNode;
  OrionHapticType _haptic = OrionHapticType.selectionClick;
  FocusHighlightMode _highlightMode = FocusHighlightMode.traditional;

  bool _dragging = false;
  bool _focused = false;
  bool _caughtOnPointerDown = false;
  bool _suppressNextRowTap = false;
  bool _normalizing = false;

  // Pointer-scroll accumulation with monotonic idle timeout (zero pending timers).
  final Stopwatch _scrollStopwatch = Stopwatch();
  double _scrollDeltaAccumulator = 0.0;

  late OrionWheelPickerStyle _style;

  double get _extent => _style.itemExtent ?? _itemExtent;

  double get _edgeScaleFor => _style.edgeScale ?? _edgeScale;

  double get _diameterRatio => _style.diameterRatio ?? _defaultDiameterRatio;

  double get _perspective => _style.perspective ?? _defaultPerspective;

  double get _squeeze => _style.squeeze ?? _defaultSqueeze;

  double get _offAxisFraction => _style.offAxisFraction ?? 0.0;

  bool get _useCylinder =>
      _perspective > 0.0 && _diameterRatio.isFinite && _diameterRatio > 0.0;

  bool get _edgeFade => _style.edgeFade ?? true;

  double get _horizontalPadding =>
      _style.horizontalPadding ?? OrionSpacing.space12;

  double get _projection => _style.projectionSeconds ?? _projectionSeconds;

  double get _resistance => _style.endResistance ?? _endResistance;

  /// True while movement comes from a discrete command (keyboard, tap, parent
  /// value change) rather than direct rolling.
  bool _silent = false;

  /// Accumulated finger position in virtual item units, including any
  /// out-of-range drag before asymptotic rubber-banding.
  double _rawOffset = 0;

  /// Virtual rounded slot index (unbounded when [_isLooping], clamped to
  /// `0.._lastIndex` otherwise).
  late int _virtualDetent;

  /// Last concrete item index (`0.._lastIndex`) reported to [OrionWheelPicker.onChanged].
  late int _committed;

  /// Last concrete item index emitted via [OrionWheelPicker.onActiveChanged]
  /// during the current drag/glide, so a parent echoing `onActiveChanged` back
  /// into `value` never retargets or perpetually pushes a looping spring.
  int? _lastEmittedActiveIndex;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  bool get _enabled => widget.onChanged != null;

  bool get _isLooping => widget.looping && widget.items.length > 1;

  int get _lastIndex => widget.items.length - 1;

  int _wrapIndex(int slotIndex) {
    final int n = widget.items.length;
    return ((slotIndex % n) + n) % n;
  }

  int _resolvedIndex(int slotIndex) =>
      _isLooping ? _wrapIndex(slotIndex) : slotIndex.clamp(0, _lastIndex);

  int get _sampleVirtualDetent {
    final int rounded = _driver.value.round();
    return _isLooping ? rounded : rounded.clamp(0, _lastIndex);
  }

  int get _activeIndex => _resolvedIndex(_virtualDetent);

  int _shortestDelta(int fromVirtual, int targetItemIndex) {
    final int n = widget.items.length;
    final int currentItem = _wrapIndex(fromVirtual);
    int delta = (targetItemIndex - currentItem) % n;
    if (delta > n / 2) {
      delta -= n;
    } else if (delta < -n / 2) {
      delta += n;
    }
    return delta;
  }

  @override
  void initState() {
    super.initState();
    _debugValidate();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    _highlightMode = FocusManager.instance.highlightMode;
    FocusManager.instance.addHighlightModeListener(_onHighlightModeChanged);

    final int index = math.max(_indexOf(widget.value), 0);
    _virtualDetent = index;
    _committed = index;
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: index.toDouble(),
      springSpec: _settleSpec,
    );
    _driver.addListener(_onTick);
    _driver.addStatusListener(_onStatus);
  }

  void _onHighlightModeChanged(FocusHighlightMode mode) {
    if (mode != _highlightMode && mounted) {
      setState(() => _highlightMode = mode);
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStyle();
    _haptic = OrionTheme.of(context).selectionHaptic;
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion) {
          return;
        }
        _driver.jumpTo(_driver.target);
        _commit();
      });
    }
  }

  @override
  void didUpdateWidget(OrionWheelPicker<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncStyle();
    _debugValidate();
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null) {
        _ownedFocusNode ??= FocusNode();
      } else {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
    }

    final int targetIndex = _indexOf(widget.value);
    final bool listChanged =
        widget.items.length != oldWidget.items.length ||
        !_sameItemValues(widget.items, oldWidget.items);

    // If looping was turned off or the list shrank, clamp immediately before
    // build() so _spokenValue / rows never index past _lastIndex.
    if (!_isLooping) {
      final int safeMax = _lastIndex;
      if (_virtualDetent < 0 || _virtualDetent > safeMax) {
        final int clamped = _virtualDetent.clamp(0, safeMax);
        _virtualDetent = clamped;
      }
      if (_committed < 0 || _committed > safeMax) {
        _committed = _committed.clamp(0, safeMax);
      }
      if (_driver.value < 0 || _driver.value > safeMax) {
        final double clampedVal = _driver.value.clamp(0.0, safeMax.toDouble());
        _normalizing = true;
        _driver.jumpTo(clampedVal);
        _normalizing = false;
      }
      if (_driver.target < 0 || _driver.target > safeMax) {
        final int clampedTarget = _driver.target.round().clamp(0, safeMax);
        _committed = clampedTarget;
        _settleOn(clampedTarget, silent: true);
      }
    }

    if (oldWidget.onChanged != null && !_enabled && _dragging) {
      _dragging = false;
      _settleOn(_sampleVirtualDetent, silent: true);
    }

    if (!_dragging && targetIndex >= 0) {
      final bool isLiveEcho =
          _driver.isAnimating &&
          (targetIndex == _activeIndex ||
              targetIndex == _lastEmittedActiveIndex);
      if (isLiveEcho) {
        _lastEmittedActiveIndex = null;
      } else {
        final int currentTargetItem = _resolvedIndex(_driver.target.round());
        if ((widget.value != oldWidget.value || listChanged) &&
            currentTargetItem != targetIndex) {
          _committed = targetIndex;
          final int anchorSlot = _driver.isAnimating
              ? _virtualDetent
              : _driver.target.round();
          final int nextSlot = _isLooping
              ? anchorSlot + _shortestDelta(anchorSlot, targetIndex)
              : targetIndex;
          _settleOn(nextSlot, silent: true);
        }
      }
    }
  }

  @override
  void dispose() {
    FocusManager.instance.removeHighlightModeListener(_onHighlightModeChanged);
    _driver.removeListener(_onTick);
    _driver.removeStatusListener(_onStatus);
    _driver.dispose();
    _draggingNotifier.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  int _indexOf(T value) =>
      widget.items.indexWhere((OrionWheelItem<T> item) => item.value == value);

  bool _sameItemValues(List<OrionWheelItem<T>> a, List<OrionWheelItem<T>> b) {
    if (identical(a, b)) return true;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].value != b[i].value) return false;
    }
    return true;
  }

  void _syncStyle() {
    final ThemeData theme = Theme.of(context);
    final OrionWheelPickerTheme wheelTheme =
        theme.extension<OrionWheelPickerTheme>() ??
        OrionWheelPickerTheme.fallback;
    _style = OrionWheelPickerPresets.resolve(
      scheme: theme.colorScheme,
      textTheme: theme.textTheme,
    ).merge(wheelTheme.defaultStyle).merge(widget.style);
  }

  void _debugValidate() {
    assert(widget.items.isNotEmpty, 'items must not be empty');
    assert(_valuesAreUnique(widget.items), 'item values must be unique');
    assert(_indexOf(widget.value) >= 0, 'value must match an item');
    assert(
      widget.visibleItemCount >= 3 && widget.visibleItemCount.isOdd,
      'visibleItemCount must be odd and at least 3',
    );
  }

  bool _valuesAreUnique(List<OrionWheelItem<T>> items) {
    final Set<T> seen = <T>{};
    for (final OrionWheelItem<T> item in items) {
      if (!seen.add(item.value)) {
        return false;
      }
    }
    return true;
  }

  /// Emits the crossing haptic, live callback, and updates the visible window.
  void _onTick() {
    if (_normalizing) return;
    final int virtualDetent = _sampleVirtualDetent;
    if (virtualDetent == _virtualDetent) {
      return;
    }
    final int previousIndex = _activeIndex;
    _virtualDetent = virtualDetent;
    final int currentIndex = _activeIndex;

    if (!_silent) {
      OrionHaptics.trigger(_haptic);
    }
    if (currentIndex != previousIndex) {
      _lastEmittedActiveIndex = currentIndex;
      widget.onActiveChanged?.call(widget.items[currentIndex].value);
    }
    setState(() {});
  }

  /// Reports the detent the wheel has come to rest on, once, and quietly
  /// normalizes virtual looping coordinates back into `[0, items.length - 1]`.
  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _lastEmittedActiveIndex = null;
    _commit();

    if (_isLooping && !_dragging && mounted) {
      final int wrapped = _wrapIndex(_virtualDetent);
      if (wrapped != _virtualDetent) {
        _normalizing = true;
        _virtualDetent = wrapped;
        _driver.jumpTo(wrapped.toDouble());
        _normalizing = false;
        setState(() {});
      }
    }
  }

  void _commit() {
    if (!mounted) {
      return;
    }
    final ValueChanged<T>? onChanged = widget.onChanged;
    if (onChanged == null) {
      return;
    }
    final int index = _resolvedIndex(_sampleVirtualDetent);
    if (index == _committed) {
      return;
    }
    _committed = index;
    onChanged(widget.items[index].value);
  }

  /// Hyperbolic asymptotic rubber-banding past either end (iOS-style).
  ///
  /// Initial slope matches [_resistance], smoothly approaching
  /// [_maxRubberBandOverscroll] so extreme drags never pull rows off-screen.
  double _rubberBand(double overscroll) {
    final double abs = overscroll.abs();
    final double r = _resistance;
    if (r <= 0.0 || abs == 0.0) return 0.0;
    const double cap = _maxRubberBandOverscroll;
    final double damped = (abs * r * cap) / (abs * r + cap);
    return overscroll.isNegative ? -damped : damped;
  }

  double _invertRubberBand(double damped) {
    final double abs = damped.abs();
    final double r = _resistance;
    if (r <= 0.0 || abs == 0.0) return 0.0;
    const double cap = _maxRubberBandOverscroll;
    final double safe = math.min(abs, cap - 0.01);
    final double raw = (safe * cap) / (r * (cap - safe));
    return damped.isNegative ? -raw : raw;
  }

  /// Drags the wheel toward [raw], with asymptotic resistance past either end
  /// when not looping.
  double _resisted(double raw) {
    if (_isLooping) return raw;
    if (raw < 0) {
      return _rubberBand(raw);
    }
    if (raw > _lastIndex) {
      return _lastIndex + _rubberBand(raw - _lastIndex);
    }
    return raw;
  }

  double _unresisted(double position) {
    if (_isLooping) return position;
    if (position < 0) {
      return _invertRubberBand(position);
    }
    if (position > _lastIndex) {
      return _lastIndex + _invertRubberBand(position - _lastIndex);
    }
    return position;
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!_enabled) return;
    if (_driver.isAnimating && !_dragging) {
      // Touching a flying wheel immediately catches momentum under the finger.
      _caughtOnPointerDown = true;
      _suppressNextRowTap = true;
      _driver.stop();
    } else {
      _caughtOnPointerDown = false;
      _suppressNextRowTap = false;
    }
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!_caughtOnPointerDown) return;
    _caughtOnPointerDown = false;
    Future<void>.microtask(() => _suppressNextRowTap = false);
    if (!_dragging) {
      _settleOn(_sampleVirtualDetent, silent: false);
    }
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!_caughtOnPointerDown) return;
    _caughtOnPointerDown = false;
    _suppressNextRowTap = false;
    if (!_dragging) {
      _settleOn(_sampleVirtualDetent, silent: false);
    }
  }

  void _onPointerSignal(PointerSignalEvent event) {
    if (!_enabled || event is! PointerScrollEvent) return;
    GestureBinding.instance.pointerSignalResolver.register(
      event,
      _handlePointerScroll,
    );
  }

  void _handlePointerScroll(PointerSignalEvent event) {
    if (!mounted || !_enabled || event is! PointerScrollEvent) return;
    final double dy = event.scrollDelta.dy;
    if (dy == 0.0) return;

    if (!_scrollStopwatch.isRunning ||
        _scrollStopwatch.elapsedMilliseconds > 180) {
      _scrollDeltaAccumulator = 0.0;
    }
    _scrollStopwatch
      ..reset()
      ..start();

    _scrollDeltaAccumulator += dy;
    final double extent = _extent;
    if (_scrollDeltaAccumulator.abs() >= extent) {
      final int steps = (_scrollDeltaAccumulator / extent).truncate();
      _scrollDeltaAccumulator -= steps * extent;
      _step(steps, silent: false);
    } else if (dy.abs() >= 28.0) {
      // Single discrete mouse-wheel notch slightly below row extent.
      _scrollDeltaAccumulator = 0.0;
      _step(dy > 0 ? 1 : -1, silent: false);
    }
  }

  void _onDragStart(DragStartDetails details) {
    if (!_enabled) {
      return;
    }
    _caughtOnPointerDown = false;
    _suppressNextRowTap = false;
    _dragging = true;
    _draggingNotifier.value = true;
    _silent = false;
    _rawOffset = _unresisted(_driver.value);
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_enabled || !_dragging) {
      return;
    }
    _rawOffset += -details.delta.dy / _extent;
    _driver.jumpTo(_resisted(_rawOffset));
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _draggingNotifier.value = false;
    final double itemsPerSecond = _itemsPerSecond(details.velocity);
    final int landing = _landingDetent(itemsPerSecond);
    final double travel = landing - _driver.value;
    _settleOn(
      landing,
      velocity: travel * itemsPerSecond > 0 ? itemsPerSecond : 0,
    );
  }

  void _onDragCancel() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _draggingNotifier.value = false;
    _settleOn(_sampleVirtualDetent);
  }

  double _itemsPerSecond(Velocity velocity) =>
      -velocity.pixelsPerSecond.dy / _extent;

  int _landingDetent(double itemsPerSecond) {
    // High-velocity flicks coast naturally further (iOS deceleration feel),
    // while gentle releases snap crisply using the base projection factor.
    // Cap total projected travel so extreme hardware flings always settle
    // predictably in under a second.
    final double speed = itemsPerSecond.abs();
    final double boost = 1.0 + ((speed - 18.0) / 36.0).clamp(0.0, 1.5);
    final double delta = (itemsPerSecond * _projection * boost).clamp(
      -24.0,
      24.0,
    );
    final double projected = _driver.value + delta;
    final int rounded = projected.round();
    return _isLooping ? rounded : rounded.clamp(0, _lastIndex);
  }

  void _onRowTap(int slotIndex) {
    if (!_enabled || _suppressNextRowTap) return;
    _settleOn(slotIndex, silent: true);
  }

  /// Retargets the spring onto [virtualDetent].
  ///
  /// Discrete commands (keyboard, tap, parent updates) pass `silent: true` so
  /// their crossings do not tick; direct drag/scroll glides keep ticking.
  void _settleOn(
    int virtualDetent, {
    bool silent = false,
    double velocity = 0,
  }) {
    final int target = _isLooping
        ? virtualDetent
        : virtualDetent.clamp(0, _lastIndex);
    _silent = silent;
    if (_driver.reducedMotion) {
      _driver.jumpTo(target.toDouble());
      _commit();
      return;
    }
    final OrionSpringSpec baseSpec = _style.settleSpring ?? _settleSpec;
    final double travel = (target - _driver.value).abs();
    // Long multi-item flicks use a slightly softer critically damped spring so
    // deceleration feels silky like UIKit rather than snapping abruptly.
    final OrionSpringSpec effectiveSpec = travel > 4.0
        ? OrionSpringSpec(
            stiffness: math.max(
              150.0,
              baseSpec.stiffness / (1.0 + (travel - 4.0) * 0.12),
            ),
            dampingRatio: baseSpec.dampingRatio,
            clampOvershoot: baseSpec.clampOvershoot,
          )
        : baseSpec;
    _driver.springSpec = effectiveSpec;
    _driver.retarget(target.toDouble(), velocity: velocity);
  }

  /// Moves [delta] detents from the last commanded target.
  void _step(int delta, {required bool silent}) {
    if (!_enabled || delta == 0) {
      return;
    }
    final int base = _driver.target.round();
    final int next = _isLooping
        ? base + delta
        : (base + delta).clamp(0, _lastIndex);
    _settleOn(next, silent: silent);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) || !_enabled) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _step(-1, silent: true);
      case LogicalKeyboardKey.arrowDown:
        _step(1, silent: true);
      case LogicalKeyboardKey.pageUp:
        _step(-widget.visibleItemCount, silent: true);
      case LogicalKeyboardKey.pageDown:
        _step(widget.visibleItemCount, silent: true);
      case LogicalKeyboardKey.home:
        final int next = _isLooping
            ? _driver.target.round() + _shortestDelta(_driver.target.round(), 0)
            : 0;
        _settleOn(next, silent: true);
      case LogicalKeyboardKey.end:
        final int next = _isLooping
            ? _driver.target.round() +
                  _shortestDelta(_driver.target.round(), _lastIndex)
            : _lastIndex;
        _settleOn(next, silent: true);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _spokenValue(int index) {
    final int safeIndex = index.clamp(0, _lastIndex);
    final OrionWheelItem<T> item = widget.items[safeIndex];
    final String? label = item.semanticLabel;
    if (label != null) {
      return label;
    }
    final Widget content = item.label;
    if (content is Text && content.data != null) {
      return content.data!;
    }
    return '${safeIndex + 1} of ${widget.items.length}';
  }

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = _enabled;
    final Set<WidgetState> states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
    };
    final Color selectedColor =
        _style.selectedColor?.resolve(states) ?? scheme.onSurface;
    final Color idleColor =
        _style.idleColor?.resolve(states) ?? scheme.onSurfaceVariant;
    final TextStyle baseTextStyle =
        _style.textStyle ?? theme.textTheme.bodyLarge ?? const TextStyle();
    final TextStyle selectedTextStyle = _style.selectedTextStyle != null
        ? baseTextStyle.merge(_style.selectedTextStyle)
        : baseTextStyle;
    final BorderRadius radius =
        _style.radius ?? BorderRadius.circular(OrionRadii.radius12);
    final double ringWidth = _style.focusRingWidth ?? 2;
    final OrionWheelSelectionStyle selectionStyle =
        _style.selectionStyle ?? OrionWheelSelectionStyle.pill;
    final Color selectionColor =
        _style.selectionColor ??
        scheme.onSurface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.10 : 0.06,
        );
    final Color selectionBorderColor =
        _style.selectionBorderColor ?? scheme.outlineVariant;
    final BorderRadius selectionRadius =
        _style.selectionRadius ?? BorderRadius.circular(OrionRadii.radius8);

    final int halo = (widget.visibleItemCount + 1) ~/ 2;
    final int firstSlot = _isLooping
        ? _virtualDetent - halo
        : math.max(0, _virtualDetent - halo);
    final int lastSlot = _isLooping
        ? _virtualDetent + halo
        : math.min(_lastIndex, _virtualDetent + halo);

    final List<Widget> rows = <Widget>[
      for (int slot = firstSlot; slot <= lastSlot; slot++)
        _WheelRow(
          key: ValueKey<int>(slot),
          label: widget.items[_resolvedIndex(slot)].label,
          textStyle: slot == _virtualDetent ? selectedTextStyle : baseTextStyle,
          color: slot == _virtualDetent ? selectedColor : idleColor,
          horizontalPadding: _horizontalPadding,
          enabled: enabled,
          onTap: enabled ? () => _onRowTap(slot) : null,
        ),
    ];

    final int activeIndex = _activeIndex;
    final bool canIncrease = _isLooping || activeIndex < _lastIndex;
    final bool canDecrease = _isLooping || activeIndex > 0;
    final int nextSemanticIndex = _isLooping
        ? _wrapIndex(activeIndex + 1)
        : math.min(_lastIndex, activeIndex + 1);
    final int prevSemanticIndex = _isLooping
        ? _wrapIndex(activeIndex - 1)
        : math.max(0, activeIndex - 1);

    final bool showFocusRing =
        _focused && enabled && _highlightMode == FocusHighlightMode.traditional;

    return Semantics(
      container: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _spokenValue(activeIndex),
      increasedValue: canIncrease ? _spokenValue(nextSemanticIndex) : null,
      decreasedValue: canDecrease ? _spokenValue(prevSemanticIndex) : null,
      onIncrease: enabled && canIncrease ? () => _step(1, silent: true) : null,
      onDecrease: enabled && canDecrease ? () => _step(-1, silent: true) : null,
      child: ExcludeSemantics(
        child: Focus(
          focusNode: _focusNode,
          autofocus: widget.autofocus,
          canRequestFocus: enabled,
          onFocusChange: (bool focused) {
            if (focused != _focused) {
              setState(() => _focused = focused);
            }
          },
          onKeyEvent: _onKey,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              assert(
                constraints.hasBoundedWidth,
                'OrionWheelPicker requires a bounded width.',
              );
              Widget drum = AnimatedBuilder(
                animation: _driver,
                // Rows are built once per detent crossing and only transformed
                // here, so animation frames never rebuild item labels.
                builder: (BuildContext context, Widget? child) {
                  final double sample = _driver.value;
                  return Stack(
                    children: <Widget>[
                      for (int i = 0; i < rows.length; i++)
                        _slot(
                          row: rows[i],
                          slotIndex: firstSlot + i,
                          sample: sample,
                          halo: halo,
                        ),
                    ],
                  );
                },
              );

              if (_edgeFade) {
                drum = ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: _edgeFadeShader,
                  child: drum,
                );
              }

              if (selectionStyle != OrionWheelSelectionStyle.none) {
                drum = CustomPaint(
                  painter: _WheelSelectionPainter(
                    selectionStyle: selectionStyle,
                    itemExtent: _extent,
                    visibleItemCount: widget.visibleItemCount,
                    fillColor: enabled
                        ? selectionColor
                        : selectionColor.withValues(
                            alpha: selectionColor.a * 0.55,
                          ),
                    borderColor: enabled
                        ? selectionBorderColor
                        : selectionBorderColor.withValues(alpha: 0.45),
                    selectionRadius: selectionRadius,
                    draggingListenable: _draggingNotifier,
                    enabled: enabled,
                  ),
                  child: drum,
                );
              }

              return Listener(
                behavior: HitTestBehavior.opaque,
                onPointerDown: _onPointerDown,
                onPointerUp: _onPointerUp,
                onPointerCancel: _onPointerCancel,
                onPointerSignal: _onPointerSignal,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onVerticalDragStart: enabled ? _onDragStart : null,
                  onVerticalDragUpdate: enabled ? _onDragUpdate : null,
                  onVerticalDragEnd: enabled ? _onDragEnd : null,
                  onVerticalDragCancel: enabled ? _onDragCancel : null,
                  child: SizedBox(
                    width: constraints.maxWidth,
                    height: _extent * widget.visibleItemCount,
                    child: DecoratedBox(
                      position: DecorationPosition.foreground,
                      decoration: BoxDecoration(
                        borderRadius: radius,
                        border: showFocusRing
                            ? Border.all(
                                color:
                                    _style.focusRingColor ?? scheme.onSurface,
                                width: ringWidth,
                              )
                            : null,
                      ),
                      child: ClipRRect(borderRadius: radius, child: drum),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  static Shader _edgeFadeShader(Rect bounds) {
    return const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: <Color>[
        Color(0x00FFFFFF),
        Color(0xFFFFFFFF),
        Color(0xFFFFFFFF),
        Color(0x00FFFFFF),
      ],
      stops: <double>[0.0, 0.16, 0.84, 1.0],
    ).createShader(bounds);
  }

  /// Places one row for the current spring sample using iOS-grade cylindrical
  /// 3D projection ([MatrixUtils.createCylindricalProjectionTransform]) or
  /// clean flat 2D layout when perspective is disabled.
  Widget _slot({
    required Widget row,
    required int slotIndex,
    required double sample,
    required int halo,
  }) {
    final double signedOffset = slotIndex - sample;
    final double distance = signedOffset.abs();
    final double falloff = (distance / halo).clamp(0.0, 1.0);
    final double wheelHeight = _extent * widget.visibleItemCount;

    if (!_useCylinder) {
      // Flat 2D mode: uniform linear spacing, zero tilt, optional edge scale.
      final double top =
          (signedOffset + (widget.visibleItemCount - 1) / 2) * _extent;
      final double opacity = (1.0 - falloff * 0.72).clamp(0.0, 1.0);
      final double scale = 1.0 - (1.0 - _edgeScaleFor) * falloff;
      return Positioned(
        top: top,
        left: 0,
        right: 0,
        height: _extent,
        child: Opacity(
          opacity: opacity,
          child: scale == 1.0 ? row : Transform.scale(scale: scale, child: row),
        ),
      );
    }

    // Authentic iOS CupertinoPicker cylindrical projection:
    // Each row sits on the front surface of a cylinder of radius
    // `wheelHeight * diameterRatio / 2`, rotated by `angle` around the drum
    // axis and projected through perspective.
    final double radius = wheelHeight * _diameterRatio / 2.0;
    final double maxVisibleRadian = _diameterRatio < 1.0
        ? math.pi / 2.0
        : math.asin(1.0 / _diameterRatio);
    final double rawAngle =
        -(signedOffset / widget.visibleItemCount) *
        2.0 *
        maxVisibleRadian /
        _squeeze;
    const double maxSafeAngle = math.pi / 2.0 - 0.04;
    final bool behindHorizon = rawAngle.abs() >= maxSafeAngle;
    final double angle = rawAngle.clamp(-maxSafeAngle, maxSafeAngle);

    final Matrix4 transform = MatrixUtils.createCylindricalProjectionTransform(
      radius: radius,
      angle: angle,
      perspective: _perspective,
    );

    // Calibrated iOS-style opacity curve: centre is crisp 1.0, curved
    // neighbours remain clearly legible so the 3D cylinder tilt reads immediately,
    // fading smoothly to 0 as rows approach the cylinder horizon.
    final double opacity = behindHorizon
        ? 0.0
        : (1.0 - (falloff * 0.76)).clamp(0.0, 1.0);

    // Transform sits directly inside Positioned.fill (full wheel bounds) so
    // RenderTransform inverts the 3D cylindrical matrix *before* Opacity /
    // _WheelRow hit-test their 44 pt bounds — keeping every curved row 100%
    // tappable at its exact projected screen pixels.
    return Positioned.fill(
      child: IgnorePointer(
        ignoring: behindHorizon,
        child: Transform(
          alignment: Alignment(-_offAxisFraction * 2.0, 0.0),
          transform: transform,
          child: Center(
            child: SizedBox(
              height: _extent,
              width: double.infinity,
              child: Opacity(opacity: opacity, child: row),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the centre selection indicator behind the scrolling rows without
/// introducing extra [DecoratedBox] widgets into the tree.
class _WheelSelectionPainter extends CustomPainter {
  const _WheelSelectionPainter({
    required this.selectionStyle,
    required this.itemExtent,
    required this.visibleItemCount,
    required this.fillColor,
    required this.borderColor,
    required this.selectionRadius,
    required this.draggingListenable,
    required this.enabled,
  }) : super(repaint: draggingListenable);

  final OrionWheelSelectionStyle selectionStyle;
  final double itemExtent;
  final int visibleItemCount;
  final Color fillColor;
  final Color borderColor;
  final BorderRadius selectionRadius;
  final ValueNotifier<bool> draggingListenable;
  final bool enabled;

  @override
  void paint(Canvas canvas, Size size) {
    final double centerTop = ((visibleItemCount - 1) / 2.0) * itemExtent;

    switch (selectionStyle) {
      case OrionWheelSelectionStyle.pill:
        final Color effectiveFill = enabled && draggingListenable.value
            ? fillColor.withValues(alpha: math.min(1.0, fillColor.a + 0.035))
            : fillColor;
        final Rect rect = Rect.fromLTWH(
          0.0,
          centerTop + 2.0,
          size.width,
          math.max(0.0, itemExtent - 4.0),
        );
        final RRect rrect = selectionRadius.toRRect(rect);
        canvas.drawRRect(rrect, Paint()..color = effectiveFill);

      case OrionWheelSelectionStyle.hairlines:
        final Paint rulePaint = Paint()
          ..color = borderColor
          ..strokeWidth = 1.0;
        final double yTop = centerTop + 0.5;
        final double yBottom = centerTop + itemExtent - 0.5;
        canvas.drawLine(Offset(0.0, yTop), Offset(size.width, yTop), rulePaint);
        canvas.drawLine(
          Offset(0.0, yBottom),
          Offset(size.width, yBottom),
          rulePaint,
        );

      case OrionWheelSelectionStyle.none:
        break;
    }
  }

  @override
  bool shouldRepaint(_WheelSelectionPainter oldDelegate) {
    return selectionStyle != oldDelegate.selectionStyle ||
        itemExtent != oldDelegate.itemExtent ||
        visibleItemCount != oldDelegate.visibleItemCount ||
        fillColor != oldDelegate.fillColor ||
        borderColor != oldDelegate.borderColor ||
        selectionRadius != oldDelegate.selectionRadius ||
        enabled != oldDelegate.enabled;
  }
}

/// One row of the wheel: a 44 pt tap target that centres its label.
class _WheelRow extends StatelessWidget {
  const _WheelRow({
    super.key,
    required this.label,
    required this.textStyle,
    required this.color,
    required this.horizontalPadding,
    required this.enabled,
    required this.onTap,
  });

  final Widget label;
  final TextStyle textStyle;
  final Color color;
  final double horizontalPadding;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Center(
            child: IconTheme.merge(
              data: IconThemeData(color: color, size: OrionSizing.iconMedium),
              child: DefaultTextStyle(
                style: textStyle.copyWith(color: color),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                child: label,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
