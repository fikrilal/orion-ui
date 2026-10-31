import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show
        DragStartBehavior,
        HorizontalDragGestureRecognizer,
        PointerHoverEvent,
        TapGestureRecognizer,
        TapUpDetails;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/slider/orion_slider.dart';
import 'package:orion_ui/src/components/slider/orion_slider_presets.dart';
import 'package:orion_ui/src/components/slider/orion_slider_style.dart';
import 'package:orion_ui/src/components/slider/orion_slider_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

enum _RangeThumb { start, end }

/// A dual-thumb horizontal range slider sharing [OrionSliderStyle],
/// [OrionSliderPresets], and [OrionSliderTheme].
///
/// The parent owns [values] (`RangeValues`). Each thumb has an independent
/// lift spring and critically damped settle spring, smart closest-thumb
/// selection with drag-direction tie-breaking when stacked, [minSpan]
/// separation enforcement, discrete [step] snapping with optional tick dots,
/// detent/bound haptics, floating value bubbles, RTL support, and independent
/// keyboard focus & accessibility semantics per thumb.
class OrionRangeSlider extends StatefulWidget {
  /// Creates a controlled dual-thumb range slider.
  const OrionRangeSlider({
    super.key,
    required this.values,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.step,
    this.minSpan = 0.0,
    this.size = OrionSliderSize.medium,
    this.showTicks = false,
    this.showValueIndicator = OrionSliderValueIndicator.never,
    this.valueLabelBuilder,
    this.allowTrackTap = false,
    this.semanticLabel,
    this.startSemanticLabel,
    this.endSemanticLabel,
    this.semanticFormatter,
    this.startFocusNode,
    this.endFocusNode,
    this.style,
  }) : assert(min <= max, 'min must not exceed max'),
       assert(step == null || step > 0, 'step must be positive'),
       assert(minSpan >= 0, 'minSpan must be non-negative');

  /// Currently selected `[start, end]` range. Non-finite or inverted values
  /// are clamped and ordered safely for display.
  final RangeValues values;

  /// Called with updated range values while dragging, on release, on track tap
  /// (when [allowTrackTap] is true), and from the keyboard. Null disables the
  /// slider.
  final ValueChanged<RangeValues>? onChanged;

  /// Called once when a drag or track tap begins.
  final ValueChanged<RangeValues>? onChangeStart;

  /// Called once when a drag finishes/cancels or a track tap settles.
  final ValueChanged<RangeValues>? onChangeEnd;

  /// Lower bound of the slider range.
  final double min;

  /// Upper bound of the slider range.
  final double max;

  /// Optional discrete increment for release snapping, ticks, and keyboard
  /// movement.
  final double? step;

  /// Minimum enforced distance between `values.start` and `values.end`.
  final double minSpan;

  /// Size preset controlling thumb diameter and track height.
  final OrionSliderSize size;

  /// Whether to paint subtle discrete step dots along the track when [step] is
  /// set (up to 100 steps).
  final bool showTicks;

  /// Controls when floating value pills appear above the thumbs.
  final OrionSliderValueIndicator showValueIndicator;

  /// Formats the floating value pill text. Falls back to [semanticFormatter]
  /// and then a trimmed number.
  final String Function(double value)? valueLabelBuilder;

  /// Whether tapping directly on the track moves the nearest thumb smoothly to
  /// the tapped position. Defaults to `false`.
  final bool allowTrackTap;

  /// Optional group spoken label for screen readers.
  final String? semanticLabel;

  /// Spoken label for the start thumb. Defaults to `'Minimum'`.
  final String? startSemanticLabel;

  /// Spoken label for the end thumb. Defaults to `'Maximum'`.
  final String? endSemanticLabel;

  /// Formats spoken values for accessibility announcements.
  final String Function(double value)? semanticFormatter;

  /// Optional focus node for the start thumb.
  final FocusNode? startFocusNode;

  /// Optional focus node for the end thumb.
  final FocusNode? endFocusNode;

  /// Instance-level overrides merged over [OrionSliderPresets] and
  /// [OrionSliderTheme].
  final OrionSliderStyle? style;

  @override
  State<OrionRangeSlider> createState() => _OrionRangeSliderState();
}

class _OrionRangeSliderState extends State<OrionRangeSlider>
    with TickerProviderStateMixin {
  static const OrionSpringSpec _settle = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );
  static const double _keyboardDivisions = 20;
  static const int _pageMultiplier = 5;

  late final OrionSpringDriver _startDriver;
  late final OrionSpringDriver _endDriver;
  late final OrionSpringDriver _startLift;
  late final OrionSpringDriver _endLift;
  final ValueNotifier<bool> _draggingNotifier = ValueNotifier<bool>(false);

  bool _startFocused = false;
  bool _endFocused = false;
  _RangeThumb? _hoveredThumb;
  bool _dragging = false;
  _RangeThumb? _activeThumb;
  bool _pendingTieBreak = false;
  double _tieBreakOriginX = 0.0;

  RangeValues _lastReported = const RangeValues(0, 0);
  int? _lastStepDetent;
  int _lastBound = 0;

  bool get _enabled => widget.onChanged != null;

  double get _safeMin => widget.min.isFinite ? widget.min : 0.0;

  double get _safeMax =>
      (widget.max.isFinite && widget.max >= _safeMin) ? widget.max : _safeMin;

  double get _span => _safeMax - _safeMin;

  double get _safeMinSpan =>
      widget.minSpan.isFinite ? widget.minSpan.clamp(0.0, _span).toDouble() : 0;

  double? get _safeStep {
    final double? step = widget.step;
    if (step == null || !step.isFinite || step <= 0) {
      return null;
    }
    return step;
  }

  RangeValues get _values {
    double s = widget.values.start.isFinite
        ? widget.values.start.clamp(_safeMin, _safeMax).toDouble()
        : _safeMin;
    double e = widget.values.end.isFinite
        ? widget.values.end.clamp(_safeMin, _safeMax).toDouble()
        : _safeMax;
    if (s > e) {
      final double tmp = s;
      s = e;
      e = tmp;
    }
    if (e - s < _safeMinSpan) {
      e = math.min(_safeMax, s + _safeMinSpan);
      s = math.max(_safeMin, e - _safeMinSpan);
    }
    return RangeValues(s, e);
  }

  double get _keyboardStep => _safeStep ?? _span / _keyboardDivisions;

  @override
  void initState() {
    super.initState();
    final RangeValues initial = _values;
    _startDriver = OrionSpringDriver(
      vsync: this,
      initialValue: _normalized(initial.start),
      springSpec: _settle,
    );
    _endDriver = OrionSpringDriver(
      vsync: this,
      initialValue: _normalized(initial.end),
      springSpec: _settle,
    );
    _startLift = OrionSpringDriver(
      vsync: this,
      springSpec: OrionSpringSpec.snappy,
      initialValue: 0,
    );
    _endLift = OrionSpringDriver(
      vsync: this,
      springSpec: OrionSpringSpec.snappy,
      initialValue: 0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_startDriver.reducedMotion;
    _startDriver.reducedMotion = reduce;
    _endDriver.reducedMotion = reduce;
    _startLift.reducedMotion = reduce;
    _endLift.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_startDriver.reducedMotion) {
          return;
        }
        final RangeValues current = _values;
        _startDriver.jumpTo(_normalized(current.start));
        _endDriver.jumpTo(_normalized(current.end));
      });
    }
  }

  @override
  void didUpdateWidget(OrionRangeSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (!_enabled) {
      if (_dragging) {
        _dragging = false;
        _activeThumb = null;
        _pendingTieBreak = false;
        _draggingNotifier.value = false;
        _liftThumb(_RangeThumb.start, 0);
        _liftThumb(_RangeThumb.end, 0);
        widget.onChangeEnd?.call(_lastReported);
      }
      _startFocused = false;
      _endFocused = false;
      _hoveredThumb = null;
    }
    _sync();
  }

  @override
  void dispose() {
    _startDriver.dispose();
    _endDriver.dispose();
    _startLift.dispose();
    _endLift.dispose();
    _draggingNotifier.dispose();
    super.dispose();
  }

  OrionSliderStyle _resolve(ThemeData theme) {
    final OrionSliderTheme sliderTheme =
        theme.extension<OrionSliderTheme>() ?? OrionSliderTheme.fallback;
    return OrionSliderPresets.resolve(
      size: widget.size,
      scheme: theme.colorScheme,
    ).merge(sliderTheme.defaultStyle).merge(widget.style);
  }

  void _syncMotion() {
    final OrionSliderStyle style = _resolve(Theme.of(context));
    final OrionSpringSpec settle = style.settleSpring ?? _settle;
    final OrionSpringSpec lift = style.liftSpring ?? OrionSpringSpec.snappy;
    _startDriver.springSpec = settle;
    _endDriver.springSpec = settle;
    _startLift.springSpec = lift;
    _endLift.springSpec = lift;
  }

  double _normalized(double value) {
    final double span = _span;
    if (span <= 0 || !value.isFinite) {
      return 0;
    }
    return ((value - _safeMin) / span).clamp(0.0, 1.0).toDouble();
  }

  double _cleanDecimal(double value) {
    if (!value.isFinite) {
      return _safeMin;
    }
    final double cleaned = double.parse(value.toStringAsFixed(6));
    return cleaned.clamp(_safeMin, _safeMax).toDouble();
  }

  double _fractionAt(
    double localX,
    double width,
    double direction,
    double thumb,
  ) {
    final double travel = width - thumb;
    if (travel <= 0) {
      return 0;
    }
    final double fromStart = ((localX - thumb / 2) / travel)
        .clamp(0.0, 1.0)
        .toDouble();
    return direction < 0 ? 1 - fromStart : fromStart;
  }

  double _valueAt(double localX, double width, double direction, double thumb) {
    if (_span <= 0) {
      return _safeMin;
    }
    final double fraction = _fractionAt(localX, width, direction, thumb);
    return (_safeMin + fraction * _span).clamp(_safeMin, _safeMax).toDouble();
  }

  double _snapped(
    double value, {
    required double lower,
    required double upper,
  }) {
    final double clamped = value.isFinite
        ? value.clamp(lower, upper).toDouble()
        : lower;
    final double? step = _safeStep;
    if (step == null || _span <= 0) {
      return clamped;
    }
    final double steps = ((clamped - _safeMin) / step).roundToDouble();
    double candidate = _cleanDecimal(_safeMin + steps * step);
    if (candidate < _safeMax &&
        (clamped - _safeMax).abs() <= (clamped - candidate).abs() &&
        _safeMax <= upper + 1e-9) {
      candidate = _safeMax;
    }
    if (candidate < lower) {
      final double ceilSteps = ((lower - _safeMin) / step).ceilToDouble();
      candidate = _cleanDecimal(_safeMin + ceilSteps * step);
    }
    if (candidate > upper) {
      final double floorSteps = ((upper - _safeMin) / step).floorToDouble();
      candidate = _cleanDecimal(_safeMin + floorSteps * step);
    }
    return candidate.clamp(lower, upper).toDouble();
  }

  int? _stepIndexOf(double value) {
    final double? step = _safeStep;
    if (step == null || _span <= 0) {
      return null;
    }
    if ((value - _safeMax).abs() < 1e-9) {
      return (_span / step).ceil();
    }
    return ((value - _safeMin) / step).round();
  }

  int _boundOf(double value, double lower, double upper) {
    if (upper <= lower) {
      return 0;
    }
    if (value <= lower + 1e-9) {
      return -1;
    }
    if (value >= upper - 1e-9) {
      return 1;
    }
    return 0;
  }

  void _liftThumb(_RangeThumb thumb, double target) {
    final OrionSpringDriver lift = thumb == _RangeThumb.start
        ? _startLift
        : _endLift;
    if (lift.reducedMotion) {
      lift.jumpTo(target);
    } else {
      lift.retarget(target);
    }
  }

  void _settleBoth(RangeValues target) {
    final double s = _normalized(target.start);
    final double e = _normalized(target.end);
    if (_startDriver.target != s) {
      _startDriver.retarget(s);
    }
    if (_endDriver.target != e) {
      _endDriver.retarget(e);
    }
  }

  void _sync() {
    if (_dragging) {
      return;
    }
    _settleBoth(_values);
  }

  _RangeThumb _closestThumb(double pointerFraction) {
    final double startDist = (pointerFraction - _startDriver.value).abs();
    final double endDist = (pointerFraction - _endDriver.value).abs();
    return startDist <= endDist ? _RangeThumb.start : _RangeThumb.end;
  }

  void _startDrag(
    double localX,
    double width,
    double direction,
    double thumbSize,
    OrionHapticType haptic,
  ) {
    if (!mounted) {
      return;
    }
    final RangeValues current = _values;
    final double pointerFraction = _fractionAt(
      localX,
      width,
      direction,
      thumbSize,
    );
    final double startDist = (pointerFraction - _startDriver.value).abs();
    final double endDist = (pointerFraction - _endDriver.value).abs();

    _dragging = true;
    _draggingNotifier.value = true;
    _lastReported = current;
    _pendingTieBreak = false;

    if ((startDist - endDist).abs() < 0.001 &&
        (_startDriver.value - _endDriver.value).abs() < 0.001) {
      if (current.start <= _safeMin + 1e-6) {
        _activeThumb = _RangeThumb.end;
      } else if (current.end >= _safeMax - 1e-6) {
        _activeThumb = _RangeThumb.start;
      } else {
        _activeThumb = null;
        _pendingTieBreak = true;
        _tieBreakOriginX = localX;
      }
    } else {
      _activeThumb = startDist < endDist ? _RangeThumb.start : _RangeThumb.end;
    }

    widget.onChangeStart?.call(current);

    if (_activeThumb != null) {
      _liftThumb(_activeThumb!, 1);
      final double activeVal = _activeThumb == _RangeThumb.start
          ? current.start
          : current.end;
      _lastStepDetent = _stepIndexOf(activeVal);
      _lastBound = _boundOf(activeVal, _safeMin, _safeMax);
      _applyPointer(localX, width, direction, thumbSize, haptic);
    }
  }

  void _applyPointer(
    double localX,
    double width,
    double direction,
    double thumbSize,
    OrionHapticType haptic,
  ) {
    if (!mounted || !_dragging) {
      return;
    }

    if (_pendingTieBreak) {
      final double dx = (localX - _tieBreakOriginX) * direction;
      if (dx.abs() < 0.5) {
        return;
      }
      _pendingTieBreak = false;
      _activeThumb = dx > 0 ? _RangeThumb.end : _RangeThumb.start;
      _liftThumb(_activeThumb!, 1);
      final double activeVal = _activeThumb == _RangeThumb.start
          ? _lastReported.start
          : _lastReported.end;
      _lastStepDetent = _stepIndexOf(activeVal);
      _lastBound = _boundOf(activeVal, _safeMin, _safeMax);
    }

    final _RangeThumb? active = _activeThumb;
    if (active == null) {
      return;
    }

    final double raw = _valueAt(localX, width, direction, thumbSize);
    final double lower;
    final double upper;
    if (active == _RangeThumb.start) {
      lower = _safeMin;
      upper = math.max(_safeMin, _lastReported.end - _safeMinSpan);
    } else {
      lower = math.min(_safeMax, _lastReported.start + _safeMinSpan);
      upper = _safeMax;
    }

    final double clamped = raw.clamp(lower, upper).toDouble();
    if (active == _RangeThumb.start) {
      _startDriver.jumpTo(_normalized(clamped));
    } else {
      _endDriver.jumpTo(_normalized(clamped));
    }

    if (_safeStep != null) {
      final int? nextDetent = _stepIndexOf(
        _snapped(clamped, lower: lower, upper: upper),
      );
      if (nextDetent != null && nextDetent != _lastStepDetent) {
        _lastStepDetent = nextDetent;
        if (haptic != OrionHapticType.none) {
          OrionHaptics.trigger(haptic);
        }
      }
    } else {
      final int nextBound = _boundOf(clamped, lower, upper);
      if (nextBound != 0 && nextBound != _lastBound) {
        if (haptic != OrionHapticType.none) {
          OrionHaptics.trigger(haptic);
        }
      }
      _lastBound = nextBound;
    }

    final RangeValues next = active == _RangeThumb.start
        ? RangeValues(clamped, _lastReported.end)
        : RangeValues(_lastReported.start, clamped);
    if (next != _lastReported) {
      _lastReported = next;
      widget.onChanged?.call(next);
    }
  }

  void _finishDrag() {
    if (!mounted || !_dragging) {
      return;
    }
    final _RangeThumb? active = _activeThumb;
    _dragging = false;
    _activeThumb = null;
    _pendingTieBreak = false;
    _draggingNotifier.value = false;
    _liftThumb(_RangeThumb.start, 0);
    _liftThumb(_RangeThumb.end, 0);

    RangeValues target = _lastReported;
    if (active == _RangeThumb.start) {
      final double upper = math.max(_safeMin, target.end - _safeMinSpan);
      final double snappedStart = _snapped(
        target.start,
        lower: _safeMin,
        upper: upper,
      );
      target = RangeValues(snappedStart, target.end);
    } else if (active == _RangeThumb.end) {
      final double lower = math.min(_safeMax, target.start + _safeMinSpan);
      final double snappedEnd = _snapped(
        target.end,
        lower: lower,
        upper: _safeMax,
      );
      target = RangeValues(target.start, snappedEnd);
    }

    if (target != _lastReported) {
      _lastReported = target;
      widget.onChanged?.call(target);
    }
    widget.onChangeEnd?.call(target);
    _settleBoth(target);
  }

  void _handleTrackTap(
    double localX,
    double width,
    double direction,
    double thumbSize,
    OrionHapticType haptic,
  ) {
    if (!mounted || !_enabled || !widget.allowTrackTap) {
      return;
    }
    final RangeValues current = _values;
    final double pointerFraction = _fractionAt(
      localX,
      width,
      direction,
      thumbSize,
    );
    final _RangeThumb thumb = _closestThumb(pointerFraction);
    final double raw = _valueAt(localX, width, direction, thumbSize);

    final RangeValues next;
    if (thumb == _RangeThumb.start) {
      final double upper = math.max(_safeMin, current.end - _safeMinSpan);
      final double val = _snapped(raw, lower: _safeMin, upper: upper);
      next = RangeValues(val, current.end);
    } else {
      final double lower = math.min(_safeMax, current.start + _safeMinSpan);
      final double val = _snapped(raw, lower: lower, upper: _safeMax);
      next = RangeValues(current.start, val);
    }
    if (next == current) {
      return;
    }
    widget.onChangeStart?.call(current);
    if (haptic != OrionHapticType.none) {
      OrionHaptics.trigger(haptic);
    }
    widget.onChanged?.call(next);
    widget.onChangeEnd?.call(next);
    _settleBoth(next);
  }

  RangeValues _steppedRange(
    _RangeThumb thumb,
    int direction, {
    int multiplier = 1,
  }) {
    final RangeValues current = _values;
    final double delta = _keyboardStep * multiplier;
    if (delta <= 0 || !delta.isFinite) {
      return current;
    }
    if (thumb == _RangeThumb.start) {
      final double upper = math.max(_safeMin, current.end - _safeMinSpan);
      final double nextStart = _cleanDecimal(
        current.start + direction * delta,
      ).clamp(_safeMin, upper).toDouble();
      return RangeValues(nextStart, current.end);
    } else {
      final double lower = math.min(_safeMax, current.start + _safeMinSpan);
      final double nextEnd = _cleanDecimal(
        current.end + direction * delta,
      ).clamp(lower, _safeMax).toDouble();
      return RangeValues(current.start, nextEnd);
    }
  }

  void _nudge(_RangeThumb thumb, int direction, {int multiplier = 1}) {
    if (!_enabled) {
      return;
    }
    final RangeValues current = _values;
    final RangeValues next = _steppedRange(
      thumb,
      direction,
      multiplier: multiplier,
    );
    if (next == current) {
      return;
    }
    widget.onChanged!(next);
    _settleBoth(next);
  }

  void _jumpThumb(_RangeThumb thumb, {required bool toMin}) {
    if (!_enabled) {
      return;
    }
    final RangeValues current = _values;
    final RangeValues next;
    if (thumb == _RangeThumb.start) {
      final double upper = math.max(_safeMin, current.end - _safeMinSpan);
      next = RangeValues(toMin ? _safeMin : upper, current.end);
    } else {
      final double lower = math.min(_safeMax, current.start + _safeMinSpan);
      next = RangeValues(current.start, toMin ? lower : _safeMax);
    }
    if (next == current) {
      return;
    }
    widget.onChanged!(next);
    _settleBoth(next);
  }

  KeyEventResult _onThumbKey(_RangeThumb thumb, KeyEvent event) {
    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) || !_enabled) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey key = event.logicalKey;
    final int? direction = switch (key) {
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      LogicalKeyboardKey.arrowUp => 1,
      LogicalKeyboardKey.arrowDown => -1,
      _ => null,
    };
    if (direction != null) {
      _nudge(thumb, direction);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _nudge(thumb, 1, multiplier: _pageMultiplier);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _nudge(thumb, -1, multiplier: _pageMultiplier);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _jumpThumb(thumb, toMin: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _jumpThumb(thumb, toMin: false);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  String _format(double value) {
    if (!value.isFinite) {
      return '0';
    }
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    String text = value.toStringAsFixed(4);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    return text.endsWith('.') ? text.substring(0, text.length - 1) : text;
  }

  String _spoken(double value) =>
      widget.semanticFormatter?.call(value) ?? _format(value);

  String _indicatorText(double value) =>
      widget.valueLabelBuilder?.call(value) ?? _spoken(value);

  List<double> _tickFractions() {
    final double? step = _safeStep;
    final double span = _span;
    if (!widget.showTicks || step == null || span <= 0) {
      return const <double>[];
    }
    final int count = (span / step).floor();
    if (count <= 1 || count > 100) {
      return const <double>[];
    }
    final List<double> ticks = <double>[];
    for (int i = 1; i < count; i++) {
      final double fraction = (i * step) / span;
      if (fraction > 0.001 && fraction < 0.999) {
        ticks.add(fraction);
      }
    }
    return ticks;
  }

  void _updateHover(
    PointerHoverEvent event,
    double width,
    double direction,
    double thumbSize,
  ) {
    if (!_enabled) {
      return;
    }
    final double pointerFraction = _fractionAt(
      event.localPosition.dx,
      width,
      direction,
      thumbSize,
    );
    final _RangeThumb nearest = _closestThumb(pointerFraction);
    if (nearest != _hoveredThumb) {
      setState(() => _hoveredThumb = nearest);
    }
  }

  List<Widget> _buildThumbWidgets({
    required _RangeThumb thumb,
    required double thumbSize,
    required double hitHeight,
    required double overlaySize,
    required double travel,
    required double direction,
    required double liftScale,
    required bool enabled,
    required bool focused,
    required bool hovered,
    required Color focusOverlay,
    required Color hoverOverlay,
    required Widget thumbDecoration,
    required OrionSpringDriver driver,
    required OrionSpringDriver lift,
    required FocusNode? focusNode,
  }) {
    final RangeValues current = _values;
    final double currentVal = thumb == _RangeThumb.start
        ? current.start
        : current.end;
    final RangeValues inc = _steppedRange(thumb, 1);
    final RangeValues dec = _steppedRange(thumb, -1);
    final double incVal = thumb == _RangeThumb.start ? inc.start : inc.end;
    final double decVal = thumb == _RangeThumb.start ? dec.start : dec.end;
    final String label = thumb == _RangeThumb.start
        ? (widget.startSemanticLabel ?? 'Minimum')
        : (widget.endSemanticLabel ?? 'Maximum');

    return <Widget>[
      if ((focused || hovered) && enabled)
        PositionedDirectional(
          start: -OrionSpacing.space8,
          top: (hitHeight - overlaySize) / 2,
          width: overlaySize,
          height: overlaySize,
          child: IgnorePointer(
            child: AnimatedBuilder(
              animation: driver,
              child: ClipOval(
                child: ColoredBox(color: focused ? focusOverlay : hoverOverlay),
              ),
              builder: (BuildContext context, Widget? child) {
                return Transform.translate(
                  offset: Offset(direction * driver.value * travel, 0),
                  child: child,
                );
              },
            ),
          ),
        ),
      PositionedDirectional(
        start: 0,
        top: (hitHeight - thumbSize) / 2,
        width: thumbSize,
        height: thumbSize,
        child: Semantics(
          container: true,
          slider: true,
          enabled: enabled,
          label: label,
          value: _spoken(currentVal),
          increasedValue: _spoken(incVal),
          decreasedValue: _spoken(decVal),
          hint: 'Between ${_spoken(_safeMin)} and ${_spoken(_safeMax)}',
          onIncrease: enabled ? () => _nudge(thumb, 1) : null,
          onDecrease: enabled ? () => _nudge(thumb, -1) : null,
          child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (FocusNode node, KeyEvent event) =>
                _onThumbKey(thumb, event),
            child: FocusableActionDetector(
              enabled: enabled,
              focusNode: focusNode,
              onShowFocusHighlight: (bool isFocused) {
                if (thumb == _RangeThumb.start && isFocused != _startFocused) {
                  setState(() => _startFocused = isFocused);
                } else if (thumb == _RangeThumb.end &&
                    isFocused != _endFocused) {
                  setState(() => _endFocused = isFocused);
                }
              },
              child: AnimatedBuilder(
                animation: Listenable.merge(<Listenable>[driver, lift]),
                child: thumbDecoration,
                builder: (BuildContext context, Widget? child) {
                  final double scale = 1 + (liftScale - 1) * lift.value;
                  return Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.diagonal3Values(scale, scale, 1)
                      ..setTranslationRaw(
                        direction * driver.value * travel,
                        0,
                        0,
                      ),
                    child: child,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildValueBubble({
    required _RangeThumb thumb,
    required double thumbSize,
    required double hitHeight,
    required double travel,
    required double direction,
    required Color indicatorBg,
    required TextStyle indicatorStyle,
  }) {
    final OrionSpringDriver driver = thumb == _RangeThumb.start
        ? _startDriver
        : _endDriver;
    final OrionSpringDriver lift = thumb == _RangeThumb.start
        ? _startLift
        : _endLift;
    final bool always =
        widget.showValueIndicator == OrionSliderValueIndicator.always;

    return PositionedDirectional(
      start: thumbSize / 2 - 80,
      top: (hitHeight - thumbSize) / 2 - 36,
      width: 160,
      height: 28,
      child: IgnorePointer(
        child: ExcludeSemantics(
          child: AnimatedBuilder(
            animation: Listenable.merge(<Listenable>[
              _startDriver,
              _endDriver,
              lift,
            ]),
            builder: (BuildContext context, Widget? _) {
              final double rawLift = always ? 1.0 : lift.value.clamp(0.0, 1.0);
              if (rawLift <= 0.01) {
                return const SizedBox.shrink();
              }
              final double scale = always ? 1.0 : (0.82 + 0.18 * rawLift);
              final double liveValue =
                  _safeMin + driver.value.clamp(0.0, 1.0) * _span;

              // Gently separate colliding pills when both are shown together.
              double repel = 0.0;
              if (always && travel > 0) {
                final double gapPx =
                    (_endDriver.value - _startDriver.value).abs() * travel;
                const double minBubbleGap = 48.0;
                if (gapPx < minBubbleGap) {
                  final double push = (minBubbleGap - gapPx) / 2;
                  repel = thumb == _RangeThumb.start ? -push : push;
                }
              }

              return Transform.translate(
                offset: Offset(direction * (driver.value * travel + repel), 0),
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Opacity(
                    opacity: rawLift,
                    child: Transform.scale(
                      scale: scale,
                      alignment: Alignment.bottomCenter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: OrionSpacing.space8,
                          vertical: OrionSpacing.space4,
                        ),
                        decoration: BoxDecoration(
                          color: indicatorBg,
                          borderRadius: BorderRadius.circular(
                            OrionRadii.radiusPill,
                          ),
                          boxShadow: const <BoxShadow>[
                            BoxShadow(
                              color: Color(0x26000000),
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          _indicatorText(liveValue),
                          maxLines: 1,
                          style: indicatorStyle,
                        ),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionSliderStyle style = _resolve(theme);
    final bool enabled = _enabled;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final double direction = rtl ? -1 : 1;

    final Set<WidgetState> states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_hoveredThumb != null && enabled) WidgetState.hovered,
    };
    final Color trackColor =
        style.trackColor?.resolve(states) ?? scheme.outline;
    final Color fillColor = style.fillColor?.resolve(states) ?? scheme.primary;
    final Color thumbColor =
        style.thumbColor?.resolve(states) ?? scheme.primary;
    final BorderSide thumbBorder = style.thumbBorder ?? BorderSide.none;
    final List<BoxShadow>? thumbShadow = style.thumbShadow;
    final Color focusOverlay =
        style.focusOverlayColor ?? scheme.onSurface.withValues(alpha: 0.12);
    final Color hoverOverlay =
        style.hoverOverlayColor ?? scheme.onSurface.withValues(alpha: 0.06);
    final Color activeTickColor =
        style.activeTickColor ?? scheme.onPrimary.withValues(alpha: 0.55);
    final Color inactiveTickColor =
        style.inactiveTickColor ??
        scheme.onSurfaceVariant.withValues(alpha: 0.45);
    final Color indicatorBg = style.valueIndicatorColor ?? scheme.onSurface;
    final Color indicatorFg = style.valueIndicatorTextColor ?? scheme.surface;
    final TextStyle indicatorStyle =
        (style.valueIndicatorTextStyle ??
                theme.textTheme.labelSmall ??
                const TextStyle(fontSize: 11, fontWeight: FontWeight.w600))
            .copyWith(
              color: indicatorFg,
              fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
            );
    final OrionHapticType haptic =
        style.hapticType ?? OrionTheme.of(context).selectionHaptic;

    final double thumbSize = math.max(0.0, style.thumbSize ?? 20);
    final double trackHeight = math.max(
      0.0,
      style.trackHeight ?? OrionSpacing.space4,
    );
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final double liftScale = style.liftScale ?? 1.2;
    final double overlaySize = thumbSize + OrionSpacing.space16;
    final double hitHeight = math.max(
      OrionSizing.minHitTarget,
      math.max(thumbSize, trackHeight),
    );
    final List<double> ticks = _tickFractions();
    final bool showIndicator =
        widget.showValueIndicator != OrionSliderValueIndicator.never;

    final Widget thumbDecoration = DecoratedBox(
      decoration: BoxDecoration(
        color: thumbColor,
        shape: BoxShape.circle,
        border: thumbBorder == BorderSide.none
            ? null
            : Border.fromBorderSide(thumbBorder),
        boxShadow: thumbShadow,
      ),
    );

    return Semantics(
      container: true,
      label: widget.semanticLabel,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          assert(
            constraints.hasBoundedWidth,
            'OrionRangeSlider requires a bounded width.',
          );
          final double width = constraints.maxWidth;
          final double travel = math.max(0.0, width - thumbSize);
          final double trackInset = math.min(thumbSize / 2, width / 2);

          final Map<Type, GestureRecognizerFactory>
          gestures = <Type, GestureRecognizerFactory>{
            HorizontalDragGestureRecognizer:
                GestureRecognizerFactoryWithHandlers<
                  HorizontalDragGestureRecognizer
                >(
                  () =>
                      HorizontalDragGestureRecognizer(debugOwner: this)
                        ..onlyAcceptDragOnThreshold = true,
                  (HorizontalDragGestureRecognizer instance) {
                    instance
                      ..dragStartBehavior = DragStartBehavior.down
                      ..onStart = enabled
                          ? (DragStartDetails details) => _startDrag(
                              details.localPosition.dx,
                              width,
                              direction,
                              thumbSize,
                              haptic,
                            )
                          : null
                      ..onUpdate = enabled
                          ? (DragUpdateDetails details) => _applyPointer(
                              details.localPosition.dx,
                              width,
                              direction,
                              thumbSize,
                              haptic,
                            )
                          : null
                      ..onEnd = enabled
                          ? (DragEndDetails details) => _finishDrag()
                          : null
                      ..onCancel = enabled ? _finishDrag : null;
                  },
                ),
            if (widget.allowTrackTap)
              TapGestureRecognizer:
                  GestureRecognizerFactoryWithHandlers<TapGestureRecognizer>(
                    () => TapGestureRecognizer(debugOwner: this),
                    (TapGestureRecognizer instance) {
                      instance.onTapUp = enabled
                          ? (TapUpDetails details) => _handleTrackTap(
                              details.localPosition.dx,
                              width,
                              direction,
                              thumbSize,
                              haptic,
                            )
                          : null;
                    },
                  ),
          };

          return MouseRegion(
            onHover: (PointerHoverEvent event) =>
                _updateHover(event, width, direction, thumbSize),
            onExit: (_) {
              if (mounted && _hoveredThumb != null) {
                setState(() => _hoveredThumb = null);
              }
            },
            child: RawGestureDetector(
              behavior: HitTestBehavior.opaque,
              excludeFromSemantics: true,
              gestures: gestures,
              child: SizedBox(
                width: width,
                height: hitHeight,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    PositionedDirectional(
                      start: trackInset,
                      end: trackInset,
                      top: (hitHeight - trackHeight) / 2,
                      height: trackHeight,
                      child: ClipRRect(
                        borderRadius: radius,
                        child: CustomPaint(
                          painter: _RangeTrackPainter(
                            startDriver: _startDriver,
                            endDriver: _endDriver,
                            rtl: rtl,
                            trackColor: trackColor,
                            fillColor: fillColor,
                            ticks: ticks,
                            activeTickColor: enabled
                                ? activeTickColor
                                : scheme.surface.withValues(alpha: 0.45),
                            inactiveTickColor: enabled
                                ? inactiveTickColor
                                : scheme.onSurface.withValues(alpha: 0.20),
                          ),
                        ),
                      ),
                    ),
                    if (showIndicator) ...<Widget>[
                      _buildValueBubble(
                        thumb: _RangeThumb.start,
                        thumbSize: thumbSize,
                        hitHeight: hitHeight,
                        travel: travel,
                        direction: direction,
                        indicatorBg: indicatorBg,
                        indicatorStyle: indicatorStyle,
                      ),
                      _buildValueBubble(
                        thumb: _RangeThumb.end,
                        thumbSize: thumbSize,
                        hitHeight: hitHeight,
                        travel: travel,
                        direction: direction,
                        indicatorBg: indicatorBg,
                        indicatorStyle: indicatorStyle,
                      ),
                    ],
                    ..._buildThumbWidgets(
                      thumb: _RangeThumb.start,
                      thumbSize: thumbSize,
                      hitHeight: hitHeight,
                      overlaySize: overlaySize,
                      travel: travel,
                      direction: direction,
                      liftScale: liftScale,
                      enabled: enabled,
                      focused: _startFocused,
                      hovered: _hoveredThumb == _RangeThumb.start,
                      focusOverlay: focusOverlay,
                      hoverOverlay: hoverOverlay,
                      thumbDecoration: thumbDecoration,
                      driver: _startDriver,
                      lift: _startLift,
                      focusNode: widget.startFocusNode,
                    ),
                    ..._buildThumbWidgets(
                      thumb: _RangeThumb.end,
                      thumbSize: thumbSize,
                      hitHeight: hitHeight,
                      overlaySize: overlaySize,
                      travel: travel,
                      direction: direction,
                      liftScale: liftScale,
                      enabled: enabled,
                      focused: _endFocused,
                      hovered: _hoveredThumb == _RangeThumb.end,
                      focusOverlay: focusOverlay,
                      hoverOverlay: hoverOverlay,
                      thumbDecoration: thumbDecoration,
                      driver: _endDriver,
                      lift: _endLift,
                      focusNode: widget.endFocusNode,
                    ),
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _draggingNotifier,
                        builder: (BuildContext context, Widget? _) {
                          return MouseRegion(
                            opaque: false,
                            hitTestBehavior: HitTestBehavior.translucent,
                            cursor: !enabled
                                ? MouseCursor.defer
                                : _draggingNotifier.value
                                ? SystemMouseCursors.grabbing
                                : SystemMouseCursors.grab,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RangeTrackPainter extends CustomPainter {
  _RangeTrackPainter({
    required this.startDriver,
    required this.endDriver,
    required this.rtl,
    required this.trackColor,
    required this.fillColor,
    required this.ticks,
    required this.activeTickColor,
    required this.inactiveTickColor,
  }) : super(repaint: Listenable.merge(<Listenable>[startDriver, endDriver]));

  final OrionSpringDriver startDriver;
  final OrionSpringDriver endDriver;
  final bool rtl;
  final Color trackColor;
  final Color fillColor;
  final List<double> ticks;
  final Color activeTickColor;
  final Color inactiveTickColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint trackPaint = Paint()..color = trackColor;
    canvas.drawRect(Offset.zero & size, trackPaint);

    final double s = startDriver.value.clamp(0.0, 1.0);
    final double e = endDriver.value.clamp(0.0, 1.0);
    final double leftFraction = rtl ? (1.0 - e) : s;
    final double rightFraction = rtl ? (1.0 - s) : e;

    if (rightFraction > leftFraction) {
      final Paint fillPaint = Paint()..color = fillColor;
      canvas.drawRect(
        Rect.fromLTRB(
          leftFraction * size.width,
          0,
          rightFraction * size.width,
          size.height,
        ),
        fillPaint,
      );
    }

    if (ticks.isNotEmpty) {
      final double radius = (size.height * 0.28).clamp(1.0, 2.0);
      final double centerY = size.height / 2;
      final Paint activePaint = Paint()..color = activeTickColor;
      final Paint inactivePaint = Paint()..color = inactiveTickColor;

      for (final double fraction in ticks) {
        final double x = rtl
            ? size.width * (1.0 - fraction)
            : size.width * fraction;
        final bool isActive = fraction >= s - 1e-6 && fraction <= e + 1e-6;
        canvas.drawCircle(
          Offset(x, centerY),
          radius,
          isActive ? activePaint : inactivePaint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_RangeTrackPainter oldDelegate) {
    return oldDelegate.startDriver != startDriver ||
        oldDelegate.endDriver != endDriver ||
        oldDelegate.rtl != rtl ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.fillColor != fillColor ||
        oldDelegate.ticks != ticks ||
        oldDelegate.activeTickColor != activeTickColor ||
        oldDelegate.inactiveTickColor != inactiveTickColor;
  }
}
