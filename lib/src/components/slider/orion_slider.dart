import 'dart:math' as math;

import 'package:flutter/gestures.dart'
    show
        DragStartBehavior,
        HorizontalDragGestureRecognizer,
        TapGestureRecognizer,
        TapUpDetails;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/slider/orion_slider_presets.dart';
import 'package:orion_ui/src/components/slider/orion_slider_style.dart';
import 'package:orion_ui/src/components/slider/orion_slider_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The slider's size step.
enum OrionSliderSize { small, medium, large }

/// A single thumb that slides along a horizontal track.
///
/// The parent owns [value]. The slider reports a number through [onChanged],
/// and a null callback disables it. There is no internal source of truth.
///
/// The drag is exact and the spring only settles:
/// - While the finger is down, every drag update maps the pointer to a value
///   and jumps the thumb straight to it. Following the pointer on a spring
///   would read as lag and break precision, so the drag never smooths.
/// - On release the spring takes over for what is left. With [step] set, the
///   slider reports the nearest step and glides onto it; without a step there
///   is nothing to settle and the thumb stays where the pointer left it.
///
/// The gesture claims horizontal drags only, so a slider inside a vertical
/// scroll view lets the list keep its vertical drags. By default a tap does
/// not move the thumb (keeping vertical scroll lists safe from stray taps);
/// pass `allowTrackTap: true` for click-to-seek controls. Crossing a [step]
/// detent or reaching [min]/[max] during a drag emits a selection haptic tick;
/// keyboard navigation stays silent.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionSliderPresets] for the [size], the ambient
/// [OrionSliderTheme], and the [style] passed here. Anything an override does
/// not name falls through; [semanticFormatter] phrases the spoken value, and
/// focus/hover paint translucent state layers under the thumb.
class OrionSlider extends StatefulWidget {
  /// Creates a controlled slider.
  const OrionSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.onChangeStart,
    this.onChangeEnd,
    this.min = 0.0,
    this.max = 1.0,
    this.step,
    this.showTicks = false,
    this.showValueIndicator = OrionSliderValueIndicator.never,
    this.valueLabelBuilder,
    this.allowTrackTap = false,
    this.semanticLabel,
    this.semanticFormatter,
    this.size = OrionSliderSize.medium,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(min <= max, 'min must not exceed max'),
       assert(step == null || step > 0, 'step must be positive');

  /// Current value. Values outside [min] and [max] (or non-finite values) are
  /// clamped safely for display.
  final double value;

  /// Called with the new value while dragging, on release, on track tap (when
  /// [allowTrackTap] is true), and from the keyboard. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Called once when the user begins dragging the slider (or taps the track
  /// when [allowTrackTap] is true) with the value at the start of the gesture.
  final ValueChanged<double>? onChangeStart;

  /// Called once when the user finishes or cancels a drag (or completes a
  /// track tap) with the final settled value.
  final ValueChanged<double>? onChangeEnd;

  /// Lower bound of the range. Both bounds are finite numbers.
  final double min;

  /// Upper bound of the range.
  final double max;

  /// Optional increment. When set, a release reports the nearest step, and the
  /// arrow keys and accessibility actions move by it. Null keeps the slider
  /// continuous and gives the keyboard a twentieth of the range.
  final double? step;

  /// Whether to paint subtle discrete tick dots along the track when [step] is
  /// set. Ignored when [step] is null or the step count exceeds 100.
  final bool showTicks;

  /// Controls when a floating value pill appears above the thumb.
  final OrionSliderValueIndicator showValueIndicator;

  /// Formats the text inside the floating value indicator. Falls back to
  /// [semanticFormatter] and then a trimmed decimal string when null.
  final String Function(double value)? valueLabelBuilder;

  /// Whether tapping directly on the track jumps the thumb smoothly to the
  /// tapped position. Defaults to `false` to protect scrollable layouts from
  /// stray taps.
  final bool allowTrackTap;

  /// Spoken name. The value and the bounds are announced separately.
  final String? semanticLabel;

  /// Phrases the spoken value - the value, the increased and decreased values,
  /// and the bounds in the hint. Null trims the number instead, so `0.30` is
  /// spoken as `0.3` rather than `0.30000000000000004`.
  final String Function(double value)? semanticFormatter;

  /// The size step. Defaults to [OrionSliderSize.medium], the shipped pair.
  final OrionSliderSize size;

  /// Optional focus node for keyboard movement.
  final FocusNode? focusNode;

  /// Whether the slider requests focus on first build.
  final bool autofocus;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionSliderTheme]. Only the fields set here change.
  final OrionSliderStyle? style;

  @override
  State<OrionSlider> createState() => _OrionSliderState();
}

class _OrionSliderState extends State<OrionSlider>
    with TickerProviderStateMixin {
  /// Fallback settle spring, used before the style resolves.
  static const OrionSpringSpec _settle = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  /// Keyboard travel without a step: twenty presses cross the range.
  static const double _keyboardDivisions = 20;

  /// PageUp / PageDown multiplier relative to a single step.
  static const int _pageMultiplier = 5;

  late final OrionSpringDriver _driver;

  /// Drives the thumb's lift (and `onDrag` value bubble) while dragging.
  late final OrionSpringDriver _lift;
  final ValueNotifier<bool> _draggingNotifier = ValueNotifier<bool>(false);
  bool _focused = false;
  bool _hovered = false;
  bool _dragging = false;

  /// The last number handed to [OrionSlider.onChanged] during an active drag.
  double _lastReported = 0;

  /// Tracks detent & bound crossings during drag to avoid duplicate haptics.
  int? _lastStepDetent;
  int _lastBound = 0;

  bool get _enabled => widget.onChanged != null;

  double get _safeMin => widget.min.isFinite ? widget.min : 0.0;

  double get _safeMax =>
      (widget.max.isFinite && widget.max >= _safeMin) ? widget.max : _safeMin;

  double get _span => _safeMax - _safeMin;

  double get _value => widget.value.isFinite
      ? widget.value.clamp(_safeMin, _safeMax).toDouble()
      : _safeMin;

  double? get _safeStep {
    final double? step = widget.step;
    if (step == null || !step.isFinite || step <= 0) {
      return null;
    }
    return step;
  }

  /// Keyboard and accessibility increment.
  double get _keyboardStep => _safeStep ?? _span / _keyboardDivisions;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _normalized(_value),
      springSpec: _settle,
    );
    _lift = OrionSpringDriver(
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
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
    _lift.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion) {
          return;
        }
        _driver.jumpTo(_normalized(_value));
      });
    }
  }

  @override
  void didUpdateWidget(OrionSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (!_enabled) {
      if (_dragging) {
        _dragging = false;
        _draggingNotifier.value = false;
        _liftTo(0);
        widget.onChangeEnd?.call(_lastReported);
      }
      _hovered = false;
      _focused = false;
    }
    _sync();
  }

  @override
  void dispose() {
    _driver.dispose();
    _lift.dispose();
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
    _driver.springSpec = style.settleSpring ?? _settle;
    _lift.springSpec = style.liftSpring ?? OrionSpringSpec.snappy;
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

  /// Maps a pointer position inside a box [width] wide to a value.
  double _valueAt(double localX, double width, double direction, double thumb) {
    final double span = _span;
    final double travel = width - thumb;
    if (span <= 0 || travel <= 0) {
      return _safeMin;
    }
    final double fromStart = ((localX - thumb / 2) / travel)
        .clamp(0.0, 1.0)
        .toDouble();
    final double fromValue = direction < 0 ? 1 - fromStart : fromStart;
    return (_safeMin + fromValue * span).clamp(_safeMin, _safeMax).toDouble();
  }

  /// The nearest step when [OrionSlider.step] is set, clamped to the range.
  double _snapped(double value) {
    final double clamped = value.isFinite
        ? value.clamp(_safeMin, _safeMax).toDouble()
        : _safeMin;
    final double? step = _safeStep;
    if (step == null || _span <= 0) {
      return clamped;
    }
    final double steps = ((clamped - _safeMin) / step).roundToDouble();
    final double toGrid = _cleanDecimal(_safeMin + steps * step);
    final double toMax = _safeMax;
    if (toGrid < toMax && (clamped - toMax).abs() <= (clamped - toGrid).abs()) {
      return toMax;
    }
    return toGrid;
  }

  int? _stepIndexOf(double value) {
    final double? step = _safeStep;
    if (step == null || _span <= 0) {
      return null;
    }
    final double snapped = _snapped(value);
    if ((snapped - _safeMax).abs() < 1e-9) {
      return (_span / step).ceil();
    }
    return ((snapped - _safeMin) / step).round();
  }

  int _boundOf(double value) {
    if (_span <= 0) {
      return 0;
    }
    if (value <= _safeMin) {
      return -1;
    }
    if (value >= _safeMax) {
      return 1;
    }
    return 0;
  }

  /// Element of the keyboard and accessibility movement.
  double _stepped(double value, int direction, {int multiplier = 1}) {
    final double delta = _keyboardStep * multiplier;
    if (delta <= 0 || !delta.isFinite) {
      return value.clamp(_safeMin, _safeMax).toDouble();
    }
    return _cleanDecimal(value + direction * delta);
  }

  void _startDrag(
    double localX,
    double width,
    double direction,
    double thumb,
    OrionHapticType haptic,
  ) {
    if (!mounted) {
      return;
    }
    _dragging = true;
    _draggingNotifier.value = true;
    _liftTo(1);
    final double initial = _value;
    _lastReported = initial;
    _lastStepDetent = _stepIndexOf(initial);
    _lastBound = _boundOf(initial);
    widget.onChangeStart?.call(initial);
    _applyPointer(localX, width, direction, thumb, haptic);
  }

  void _applyPointer(
    double localX,
    double width,
    double direction,
    double thumb,
    OrionHapticType haptic,
  ) {
    if (!mounted || !_dragging) {
      return;
    }
    final double target = _valueAt(localX, width, direction, thumb);
    // Exact: the thumb is under the pointer, never chasing it on a spring.
    _driver.jumpTo(_normalized(target));

    if (_safeStep != null) {
      final int? nextDetent = _stepIndexOf(target);
      if (nextDetent != null && nextDetent != _lastStepDetent) {
        _lastStepDetent = nextDetent;
        if (haptic != OrionHapticType.none) {
          OrionHaptics.trigger(haptic);
        }
      }
    } else {
      final int nextBound = _boundOf(target);
      if (nextBound != 0 && nextBound != _lastBound) {
        if (haptic != OrionHapticType.none) {
          OrionHaptics.trigger(haptic);
        }
      }
      _lastBound = nextBound;
    }

    if (target != _lastReported) {
      _lastReported = target;
      widget.onChanged?.call(target);
    }
  }

  void _finishDrag() {
    if (!mounted || !_dragging) {
      return;
    }
    _dragging = false;
    _draggingNotifier.value = false;
    _liftTo(0);
    final double reported = _lastReported;
    final double target = _snapped(reported);
    if (target != reported) {
      _lastReported = target;
      widget.onChanged?.call(target);
    }
    widget.onChangeEnd?.call(target);
    _settleOn(target);
  }

  void _handleTrackTap(
    double localX,
    double width,
    double direction,
    double thumb,
    OrionHapticType haptic,
  ) {
    if (!mounted || !_enabled || !widget.allowTrackTap) {
      return;
    }
    final double current = _value;
    final double target = _snapped(_valueAt(localX, width, direction, thumb));
    if (target == current) {
      return;
    }
    widget.onChangeStart?.call(current);
    if (haptic != OrionHapticType.none) {
      OrionHaptics.trigger(haptic);
    }
    widget.onChanged?.call(target);
    widget.onChangeEnd?.call(target);
    _settleOn(target);
  }

  void _liftTo(double value) {
    if (_lift.reducedMotion) {
      _lift.jumpTo(value);
    } else {
      _lift.retarget(value);
    }
  }

  void _settleOn(double value) {
    final double target = _normalized(value);
    if (_driver.target == target) {
      return;
    }
    _driver.retarget(target);
  }

  void _sync() {
    if (_dragging) {
      return;
    }
    _settleOn(_value);
  }

  void _nudge(int direction, {int multiplier = 1}) {
    if (!_enabled) {
      return;
    }
    final double current = _value;
    final double target = _stepped(current, direction, multiplier: multiplier);
    if (target == current) {
      return;
    }
    widget.onChanged!(target);
    _settleOn(target);
  }

  void _jumpTo(double value) {
    if (!_enabled) {
      return;
    }
    final double target = value.clamp(_safeMin, _safeMax).toDouble();
    if (target == _value) {
      return;
    }
    widget.onChanged!(target);
    _settleOn(target);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
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
      _nudge(direction);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageUp) {
      _nudge(1, multiplier: _pageMultiplier);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.pageDown) {
      _nudge(-1, multiplier: _pageMultiplier);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      _jumpTo(_safeMin);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      _jumpTo(_safeMax);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Trims float noise so a spoken value reads as a number, not as
  /// `0.30000000000000004`.
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
      if (_hovered && enabled) WidgetState.hovered,
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

    // Built once per widget build. The ticker reuses these instances, so a
    // frame only moves transforms.
    final Widget track = DecoratedBox(
      decoration: BoxDecoration(color: trackColor),
    );
    final Widget fill = DecoratedBox(
      decoration: BoxDecoration(color: fillColor),
    );
    final Widget thumb = DecoratedBox(
      decoration: BoxDecoration(
        color: thumbColor,
        shape: BoxShape.circle,
        border: thumbBorder == BorderSide.none
            ? null
            : Border.fromBorderSide(thumbBorder),
        boxShadow: thumbShadow,
      ),
    );

    final bool showIndicator =
        widget.showValueIndicator != OrionSliderValueIndicator.never;

    return Semantics(
      container: true,
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _spoken(_value),
      increasedValue: _spoken(_stepped(_value, 1)),
      decreasedValue: _spoken(_stepped(_value, -1)),
      hint: 'Between ${_spoken(_safeMin)} and ${_spoken(_safeMax)}',
      onIncrease: enabled ? () => _nudge(1) : null,
      onDecrease: enabled ? () => _nudge(-1) : null,
      child: Focus(
        canRequestFocus: false,
        skipTraversal: true,
        onKeyEvent: _onKey,
        child: FocusableActionDetector(
          enabled: enabled,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onShowFocusHighlight: (bool focused) {
            if (focused != _focused) {
              setState(() => _focused = focused);
            }
          },
          child: MouseRegion(
            onEnter: (_) {
              if (mounted && enabled && !_hovered) {
                setState(() => _hovered = true);
              }
            },
            onExit: (_) {
              if (mounted && _hovered) {
                setState(() => _hovered = false);
              }
            },
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                assert(
                  constraints.hasBoundedWidth,
                  'OrionSlider requires a bounded width.',
                );
                final double width = constraints.maxWidth;
                final double travel = math.max(0.0, width - thumbSize);
                final double trackInset = math.min(thumbSize / 2, width / 2);

                final Map<Type, GestureRecognizerFactory> gestures =
                    <Type, GestureRecognizerFactory>{
                      HorizontalDragGestureRecognizer:
                          GestureRecognizerFactoryWithHandlers<
                            HorizontalDragGestureRecognizer
                          >(
                            () => HorizontalDragGestureRecognizer(
                              debugOwner: this,
                            )..onlyAcceptDragOnThreshold = true,
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
                                    ? (DragUpdateDetails details) =>
                                          _applyPointer(
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
                            GestureRecognizerFactoryWithHandlers<
                              TapGestureRecognizer
                            >(() => TapGestureRecognizer(debugOwner: this), (
                              TapGestureRecognizer instance,
                            ) {
                              instance.onTapUp = enabled
                                  ? (TapUpDetails details) => _handleTrackTap(
                                      details.localPosition.dx,
                                      width,
                                      direction,
                                      thumbSize,
                                      haptic,
                                    )
                                  : null;
                            }),
                    };

                return RawGestureDetector(
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
                            child: Stack(
                              fit: StackFit.expand,
                              children: <Widget>[
                                track,
                                AnimatedBuilder(
                                  animation: _driver,
                                  child: fill,
                                  builder:
                                      (BuildContext context, Widget? child) {
                                        return Transform.scale(
                                          alignment:
                                              AlignmentDirectional.centerStart,
                                          scaleX: _driver.value
                                              .clamp(0.0, 1.0)
                                              .toDouble(),
                                          child: child,
                                        );
                                      },
                                ),
                                if (ticks.isNotEmpty)
                                  CustomPaint(
                                    painter: _SliderTicksPainter(
                                      driver: _driver,
                                      ticks: ticks,
                                      rtl: rtl,
                                      activeColor: enabled
                                          ? activeTickColor
                                          : scheme.surface.withValues(
                                              alpha: 0.45,
                                            ),
                                      inactiveColor: enabled
                                          ? inactiveTickColor
                                          : scheme.onSurface.withValues(
                                              alpha: 0.20,
                                            ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                        if ((_focused || _hovered) && enabled)
                          PositionedDirectional(
                            start: -OrionSpacing.space8,
                            top: (hitHeight - overlaySize) / 2,
                            width: overlaySize,
                            height: overlaySize,
                            child: AnimatedBuilder(
                              animation: _driver,
                              child: ClipOval(
                                child: ColoredBox(
                                  color: _focused ? focusOverlay : hoverOverlay,
                                ),
                              ),
                              builder: (BuildContext context, Widget? child) {
                                return Transform.translate(
                                  offset: Offset(
                                    direction * _driver.value * travel,
                                    0,
                                  ),
                                  child: child,
                                );
                              },
                            ),
                          ),
                        if (showIndicator)
                          PositionedDirectional(
                            start: thumbSize / 2 - 80,
                            top: (hitHeight - thumbSize) / 2 - 36,
                            width: 160,
                            height: 28,
                            child: IgnorePointer(
                              child: ExcludeSemantics(
                                child: AnimatedBuilder(
                                  animation: Listenable.merge(<Listenable>[
                                    _driver,
                                    _lift,
                                  ]),
                                  builder: (BuildContext context, Widget? _) {
                                    final bool always =
                                        widget.showValueIndicator ==
                                        OrionSliderValueIndicator.always;
                                    final double rawLift = always
                                        ? 1.0
                                        : _lift.value.clamp(0.0, 1.0);
                                    if (rawLift <= 0.01) {
                                      return const SizedBox.shrink();
                                    }
                                    final double scale = always
                                        ? 1.0
                                        : (0.82 + 0.18 * rawLift);
                                    final double liveValue =
                                        _safeMin +
                                        _driver.value.clamp(0.0, 1.0) * _span;
                                    return Transform.translate(
                                      offset: Offset(
                                        direction * _driver.value * travel,
                                        0,
                                      ),
                                      child: Align(
                                        alignment: Alignment.bottomCenter,
                                        child: Opacity(
                                          opacity: rawLift,
                                          child: Transform.scale(
                                            scale: scale,
                                            alignment: Alignment.bottomCenter,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal:
                                                        OrionSpacing.space8,
                                                    vertical:
                                                        OrionSpacing.space4,
                                                  ),
                                              decoration: BoxDecoration(
                                                color: indicatorBg,
                                                borderRadius:
                                                    BorderRadius.circular(
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
                          ),
                        PositionedDirectional(
                          start: 0,
                          top: (hitHeight - thumbSize) / 2,
                          width: thumbSize,
                          height: thumbSize,
                          child: AnimatedBuilder(
                            animation: Listenable.merge(<Listenable>[
                              _driver,
                              _lift,
                            ]),
                            child: thumb,
                            builder: (BuildContext context, Widget? child) {
                              final double scale =
                                  1 + (liftScale - 1) * _lift.value;
                              return Transform(
                                alignment: Alignment.center,
                                transform:
                                    Matrix4.diagonal3Values(scale, scale, 1)
                                      ..setTranslationRaw(
                                        direction * _driver.value * travel,
                                        0,
                                        0,
                                      ),
                                child: child,
                              );
                            },
                          ),
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
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _SliderTicksPainter extends CustomPainter {
  _SliderTicksPainter({
    required this.driver,
    required this.ticks,
    required this.rtl,
    required this.activeColor,
    required this.inactiveColor,
  }) : super(repaint: driver);

  final OrionSpringDriver driver;
  final List<double> ticks;
  final bool rtl;
  final Color activeColor;
  final Color inactiveColor;

  @override
  void paint(Canvas canvas, Size size) {
    final double progress = driver.value.clamp(0.0, 1.0);
    final double radius = (size.height * 0.28).clamp(1.0, 2.0);
    final double centerY = size.height / 2;
    final Paint activePaint = Paint()..color = activeColor;
    final Paint inactivePaint = Paint()..color = inactiveColor;

    for (final double fraction in ticks) {
      final double x = rtl
          ? size.width * (1.0 - fraction)
          : size.width * fraction;
      final bool isActive = fraction <= progress + 1e-6;
      canvas.drawCircle(
        Offset(x, centerY),
        radius,
        isActive ? activePaint : inactivePaint,
      );
    }
  }

  @override
  bool shouldRepaint(_SliderTicksPainter oldDelegate) {
    return oldDelegate.driver != driver ||
        oldDelegate.ticks != ticks ||
        oldDelegate.rtl != rtl ||
        oldDelegate.activeColor != activeColor ||
        oldDelegate.inactiveColor != inactiveColor;
  }
}
