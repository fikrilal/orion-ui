import 'package:flutter/gestures.dart'
    show DragStartBehavior, HorizontalDragGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/slider/orion_slider_presets.dart';
import 'package:orion_ui/src/components/slider/orion_slider_style.dart';
import 'package:orion_ui/src/components/slider/orion_slider_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
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
/// scroll view lets the list keep its vertical drags. The whole track takes the
/// drag, not just the thumb, and a tap does not move the thumb: the recognizer
/// waits for the drag to pass the touch slop, so it never answers to a stray
/// tap the way a bare drag recognizer would. The keyboard moves by [step], or
/// by a twentieth of the range when [step] is null, and Home and End jump to
/// the bounds; right and left follow [Directionality], so they reverse in
/// right-to-left layouts.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionSliderPresets] for the [size], the ambient
/// [OrionSliderTheme], and the [style] passed here. Anything an override does
/// not name falls through; [semanticFormatter] phrases the spoken value, and
/// focus paints a translucent state layer under the thumb rather than a ring.
class OrionSlider extends StatefulWidget {
  /// Creates a controlled slider.
  const OrionSlider({
    super.key,
    required this.value,
    required this.onChanged,
    this.min = 0.0,
    this.max = 1.0,
    this.step,
    this.semanticLabel,
    this.semanticFormatter,
    this.size = OrionSliderSize.medium,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(min <= max, 'min must not exceed max'),
       assert(step == null || step > 0, 'step must be positive');

  /// Current value. Values outside [min] and [max] are clamped for display.
  final double value;

  /// Called with the new value while dragging, on release, and from the
  /// keyboard. Null disables the slider.
  final ValueChanged<double>? onChanged;

  /// Lower bound of the range. Both bounds are finite numbers.
  final double min;

  /// Upper bound of the range.
  final double max;

  /// Optional increment. When set, a release reports the nearest step, and the
  /// arrow keys and accessibility actions move by it. Null keeps the slider
  /// continuous and gives the keyboard a twentieth of the range.
  final double? step;

  /// Spoken name. The value and the bounds are announced separately.
  final String? semanticLabel;

  /// Phrases the spoken value - the value, the increased and decreased values,
  /// and the bounds in the hint. Null trims the number instead, so `0.30` is
  /// spoken as `0.3` rather than `0.30000000000000004`. Use this to say `42%`
  /// or `$12`.
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
  ///
  /// Critically damped, like the segmented progress fill and the navigation
  /// bar's hide motion. The kit's underdamped presets are sized for short
  /// travel: over a full travel [OrionSpringSpec.snappy] overshoots by about 30
  /// percent and [OrionSpringSpec.gentle] by about 3.8 percent. A slider
  /// travels the whole track and a driven change can span the whole range, so
  /// an overshoot of a few percent would carry the thumb past the end of a
  /// control whose job is showing an exact value.
  static const OrionSpringSpec _settle = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  /// Keyboard travel without a step: twenty presses cross the range.
  static const double _keyboardDivisions = 20;

  late final OrionSpringDriver _driver;

  /// Drives the thumb's lift while a drag is in progress.
  late final OrionSpringDriver _lift;
  bool _focused = false;
  bool _dragging = false;

  /// The last number handed to [OrionSlider.onChanged]. It is not the source of
  /// truth: it only keeps a drag from reporting the same value twice and lets
  /// the release compare the snapped value against what the parent already has.
  double _lastReported = 0;

  bool get _enabled => widget.onChanged != null;

  double get _span => widget.max - widget.min;

  double get _value => widget.value.clamp(widget.min, widget.max).toDouble();

  /// Keyboard and accessibility increment.
  double get _keyboardStep => widget.step ?? _span / _keyboardDivisions;

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
      // Motion was just turned off mid-flight: land where the value already is.
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
    if (!_enabled && _dragging) {
      // The drag can no longer report, so stop treating the pointer as the authority
      // instead of leaving a stale flag behind - and drop the lift, because a disabled
      // slider's recognizer delivers no end or cancel to drop it later.
      _dragging = false;
      _liftTo(0);
    }
    _sync();
  }

  @override
  void dispose() {
    _driver.dispose();
    _lift.dispose();
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
    if (span <= 0) {
      return 0;
    }
    return ((value - widget.min) / span).clamp(0.0, 1.0).toDouble();
  }

  /// Maps a pointer position inside a box [width] wide to a value.
  ///
  /// The thumb center travels from half a thumb in from the leading edge to
  /// half a thumb in from the trailing edge, and [direction] mirrors the
  /// mapping for right-to-left layouts.
  double _valueAt(double localX, double width, double direction, double thumb) {
    final double span = _span;
    final double travel = width - thumb;
    if (span <= 0 || travel <= 0) {
      return widget.min;
    }
    final double fromStart = ((localX - thumb / 2) / travel)
        .clamp(0.0, 1.0)
        .toDouble();
    final double fromValue = direction < 0 ? 1 - fromStart : fromStart;
    return (widget.min + fromValue * span)
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  /// The nearest step when [OrionSlider.step] is set, clamped to the range.
  ///
  /// The grid is snapped on a fixed decimal grid so float dust cannot keep a
  /// value off it, and the maximum is a candidate of its own: when the step
  /// does not divide the range the last whole step sits below the top, so a
  /// release at the far right must still be able to report [OrionSlider.max].
  double _snapped(double value) {
    final double clamped = value.clamp(widget.min, widget.max).toDouble();
    final double? step = widget.step;
    if (step == null || _span <= 0) {
      return clamped;
    }
    final double steps = ((clamped - widget.min) / step).roundToDouble();
    final double toGrid = double.parse(
      (widget.min + steps * step).toStringAsFixed(6),
    ).clamp(widget.min, widget.max).toDouble();
    final double toMax = widget.max;
    if (toGrid < toMax && (clamped - toMax).abs() <= (clamped - toGrid).abs()) {
      return toMax;
    }
    return toGrid;
  }

  /// Element of the keyboard and accessibility movement.
  double _stepped(double value, int direction) {
    final double target = value + direction * _keyboardStep;
    return target.clamp(widget.min, widget.max).toDouble();
  }

  void _startDrag(double localX, double width, double direction, double thumb) {
    if (!mounted) {
      return;
    }
    _dragging = true;
    _liftTo(1);
    _lastReported = _value;
    _applyPointer(localX, width, direction, thumb);
  }

  void _applyPointer(
    double localX,
    double width,
    double direction,
    double thumb,
  ) {
    if (!mounted || !_dragging) {
      return;
    }
    final double target = _valueAt(localX, width, direction, thumb);
    // Exact: the thumb is under the pointer, never chasing it on a spring.
    _driver.jumpTo(_normalized(target));
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
    // Also the cancel path, so a cancelled drag drops the lift too.
    _liftTo(0);
    final double reported = _lastReported;
    final double target = _snapped(reported);
    if (target != reported) {
      _lastReported = target;
      widget.onChanged?.call(target);
    }
    _settleOn(target);
  }

  /// Retargets the driver toward [value], or jumps when motion is reduced.
  /// Grows or drops the thumb. Reduced motion lands it in the same frame.
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
      // The pointer owns the position while it is down.
      return;
    }
    _settleOn(_value);
  }

  void _nudge(int direction) {
    if (!_enabled) {
      return;
    }
    final double current = _value;
    final double target = _stepped(current, direction);
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
    final double target = value.clamp(widget.min, widget.max).toDouble();
    if (target == _value) {
      return;
    }
    widget.onChanged!(target);
    _settleOn(target);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_enabled) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int? direction = switch (event.logicalKey) {
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
    if (event.logicalKey == LogicalKeyboardKey.home) {
      _jumpTo(widget.min);
      return KeyEventResult.handled;
    }
    if (event.logicalKey == LogicalKeyboardKey.end) {
      _jumpTo(widget.max);
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  /// Trims float noise so a spoken value reads as a number, not as
  /// `0.30000000000000004`.
  String _format(double value) {
    if (value == value.roundToDouble()) {
      return value.toInt().toString();
    }
    String text = value.toStringAsFixed(4);
    while (text.endsWith('0')) {
      text = text.substring(0, text.length - 1);
    }
    return text.endsWith('.') ? text.substring(0, text.length - 1) : text;
  }

  /// The spoken form: the host's phrasing when given, the trimmed number
  /// otherwise.
  String _spoken(double value) =>
      widget.semanticFormatter?.call(value) ?? _format(value);

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OrionSliderStyle style = _resolve(theme);
    final bool enabled = _enabled;
    final double direction = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;

    final Set<WidgetState> states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
    };
    final Color trackColor =
        style.trackColor?.resolve(states) ?? theme.colorScheme.outline;
    final Color fillColor =
        style.fillColor?.resolve(states) ?? theme.colorScheme.primary;
    final Color thumbColor =
        style.thumbColor?.resolve(states) ?? theme.colorScheme.primary;
    final Color overlayColor =
        style.focusOverlayColor ??
        theme.colorScheme.onSurface.withValues(alpha: 0.12);
    final double thumbSize = style.thumbSize ?? 20;
    final double trackHeight = style.trackHeight ?? OrionSpacing.space4;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final double liftScale = style.liftScale ?? 1.2;
    final double overlaySize = thumbSize + OrionSpacing.space16;

    // Built once per widget build. The ticker reuses both instances, so a frame
    // only moves a transform.
    final Widget track = DecoratedBox(
      decoration: BoxDecoration(color: trackColor),
    );
    final Widget fill = DecoratedBox(
      decoration: BoxDecoration(color: fillColor),
    );
    final Widget thumb = DecoratedBox(
      decoration: BoxDecoration(color: thumbColor, shape: BoxShape.circle),
    );

    return Semantics(
      container: true,
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _spoken(_value),
      increasedValue: _spoken(_stepped(_value, 1)),
      decreasedValue: _spoken(_stepped(_value, -1)),
      hint: 'Between ${_spoken(widget.min)} and ${_spoken(widget.max)}',
      onIncrease: enabled ? () => _nudge(1) : null,
      onDecrease: enabled ? () => _nudge(-1) : null,
      // The slider node wraps the focus machinery, so assistive technology
      // lands on the value and the bounds first, the way the checkbox and the
      // chip order their own semantics.
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        canRequestFocus: enabled,
        onFocusChange: (bool focused) {
          if (focused != _focused) {
            setState(() => _focused = focused);
          }
        },
        onKeyEvent: _onKey,
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: LayoutBuilder(
            builder: (BuildContext context, BoxConstraints constraints) {
              assert(
                constraints.hasBoundedWidth,
                'OrionSlider requires a bounded width.',
              );
              final double width = constraints.maxWidth;
              final double travel = width - thumbSize;
              return RawGestureDetector(
                behavior: HitTestBehavior.opaque,
                // The slider node above carries the value, the bounds, and the
                // increment actions. Left in, the drag recognizer's default
                // delegate would also advertise scroll actions that a slider
                // does not have.
                excludeFromSemantics: true,
                gestures: <Type, GestureRecognizerFactory>{
                  HorizontalDragGestureRecognizer:
                      GestureRecognizerFactoryWithHandlers<
                        HorizontalDragGestureRecognizer
                      >(
                        // A bare drag recognizer also wins the arena sweep on
                        // pointer up, which would turn a tap into a jump to the
                        // touch point. Waiting for the threshold keeps the
                        // slider on real drags only.
                        () =>
                            HorizontalDragGestureRecognizer(debugOwner: this)
                              ..onlyAcceptDragOnThreshold = true,
                        (HorizontalDragGestureRecognizer instance) {
                          instance
                            // Report the finger's landing point rather than
                            // where the slop was crossed.
                            ..dragStartBehavior = DragStartBehavior.down
                            ..onStart = enabled
                                ? (DragStartDetails details) => _startDrag(
                                    details.localPosition.dx,
                                    width,
                                    direction,
                                    thumbSize,
                                  )
                                : null
                            ..onUpdate = enabled
                                ? (DragUpdateDetails details) => _applyPointer(
                                    details.localPosition.dx,
                                    width,
                                    direction,
                                    thumbSize,
                                  )
                                : null
                            ..onEnd = enabled
                                ? (DragEndDetails details) => _finishDrag()
                                : null
                            ..onCancel = enabled ? _finishDrag : null;
                        },
                      ),
                },
                child: SizedBox(
                  width: width,
                  height: OrionSizing.minHitTarget,
                  child: Stack(
                    // The focus state layer is wider than the thumb and hangs
                    // half its slack off each end of the box, so it must be
                    // free to paint there.
                    clipBehavior: Clip.none,
                    children: <Widget>[
                      PositionedDirectional(
                        start: thumbSize / 2,
                        end: thumbSize / 2,
                        top: (OrionSizing.minHitTarget - trackHeight) / 2,
                        height: trackHeight,
                        // The pill is a static clip, so the fill can be a plain
                        // scaled rectangle: scaling a rounded rect would squash
                        // its cap, and clipping avoids a custom painter and its
                        // per-frame paint allocations.
                        child: ClipRRect(
                          borderRadius: radius,
                          child: Stack(
                            fit: StackFit.expand,
                            children: <Widget>[
                              track,
                              AnimatedBuilder(
                                animation: _driver,
                                child: fill,
                                builder: (BuildContext context, Widget? child) {
                                  return Transform.scale(
                                    alignment: AlignmentDirectional.centerStart,
                                    scaleX: _driver.value
                                        .clamp(0.0, 1.0)
                                        .toDouble(),
                                    child: child,
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      // The focus state layer sits under the thumb, so the
                      // thumb stays legible and focus never draws a ring.
                      if (_focused && enabled)
                        PositionedDirectional(
                          start: -OrionSpacing.space8,
                          top: (OrionSizing.minHitTarget - overlaySize) / 2,
                          width: overlaySize,
                          height: overlaySize,
                          child: AnimatedBuilder(
                            animation: _driver,
                            child: ClipOval(
                              child: ColoredBox(color: overlayColor),
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
                      PositionedDirectional(
                        start: 0,
                        top: (OrionSizing.minHitTarget - thumbSize) / 2,
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
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
