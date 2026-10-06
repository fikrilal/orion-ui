import 'package:flutter/gestures.dart'
    show DragStartBehavior, HorizontalDragGestureRecognizer;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

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
    this.focusNode,
    this.autofocus = false,
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

  /// Optional focus node for keyboard movement.
  final FocusNode? focusNode;

  /// Whether the slider requests focus on first build.
  final bool autofocus;

  @override
  State<OrionSlider> createState() => _OrionSliderState();
}

class _OrionSliderState extends State<OrionSlider>
    with SingleTickerProviderStateMixin {
  /// Visual thumb diameter. The track is inset by half of it, so the thumb
  /// center reaches both ends of the track.
  static const double _thumbSize = 20;

  static const double _trackHeight = OrionSpacing.space4;

  /// Settle spring for the release snap and for driven value changes.
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
  bool _reduceMotion = false;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reduceMotion) {
          return;
        }
        _driver.jumpTo(_normalized(_value));
      });
    }
  }

  @override
  void didUpdateWidget(OrionSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_enabled && _dragging) {
      // The drag can no longer report, so stop treating the pointer as the
      // authority instead of leaving a stale flag behind.
      _dragging = false;
    }
    _sync();
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
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
  double _valueAt(double localX, double width, double direction) {
    final double span = _span;
    final double travel = width - _thumbSize;
    if (span <= 0 || travel <= 0) {
      return widget.min;
    }
    final double fromStart = ((localX - _thumbSize / 2) / travel)
        .clamp(0.0, 1.0)
        .toDouble();
    final double fromValue = direction < 0 ? 1 - fromStart : fromStart;
    return (widget.min + fromValue * span)
        .clamp(widget.min, widget.max)
        .toDouble();
  }

  /// The nearest step when [OrionSlider.step] is set, clamped to the range.
  double _snapped(double value) {
    final double clamped = value.clamp(widget.min, widget.max).toDouble();
    final double? step = widget.step;
    if (step == null || _span <= 0) {
      return clamped;
    }
    final double steps = ((clamped - widget.min) / step).roundToDouble();
    return (widget.min + steps * step).clamp(widget.min, widget.max).toDouble();
  }

  /// Element of the keyboard and accessibility movement.
  double _stepped(double value, int direction) {
    final double target = value + direction * _keyboardStep;
    return target.clamp(widget.min, widget.max).toDouble();
  }

  void _startDrag(double localX, double width, double direction) {
    if (!mounted) {
      return;
    }
    _dragging = true;
    _lastReported = _value;
    _applyPointer(localX, width, direction);
  }

  void _applyPointer(double localX, double width, double direction) {
    if (!mounted || !_dragging) {
      return;
    }
    final double target = _valueAt(localX, width, direction);
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
    final double reported = _lastReported;
    final double target = _snapped(reported);
    if (target != reported) {
      _lastReported = target;
      widget.onChanged?.call(target);
    }
    _settleOn(target);
  }

  /// Retargets the driver toward [value], or jumps when motion is reduced.
  void _settleOn(double value) {
    final double target = _normalized(value);
    if (_driver.target == target) {
      return;
    }
    if (_reduceMotion) {
      _driver.jumpTo(target);
    } else {
      _driver.retarget(target);
    }
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

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = _enabled;
    final double direction = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    final BorderRadius radius = BorderRadius.circular(OrionRadii.radiusPill);

    final Color trackColor = enabled
        ? scheme.outline
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color fillColor = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color thumbColor = enabled
        ? scheme.primary
        : scheme.onSurface.withValues(alpha: 0.38);

    // Built once per widget build. The ticker reuses both instances, so a frame
    // only moves a transform.
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
        // The halo sits outside the thumb: a ring drawn inside a primary fill
        // would disappear into it, the reason the checkbox and the chip record.
        boxShadow: _focused && enabled
            ? <BoxShadow>[BoxShadow(color: scheme.onSurface, spreadRadius: 2)]
            : null,
      ),
    );

    return Semantics(
      container: true,
      slider: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _format(_value),
      increasedValue: _format(_stepped(_value, 1)),
      decreasedValue: _format(_stepped(_value, -1)),
      hint: 'Between ${_format(widget.min)} and ${_format(widget.max)}',
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
              final double travel = width - _thumbSize;
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
                                  )
                                : null
                            ..onUpdate = enabled
                                ? (DragUpdateDetails details) => _applyPointer(
                                    details.localPosition.dx,
                                    width,
                                    direction,
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
                    children: <Widget>[
                      PositionedDirectional(
                        start: _thumbSize / 2,
                        end: _thumbSize / 2,
                        top: (OrionSizing.minHitTarget - _trackHeight) / 2,
                        height: _trackHeight,
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
                      PositionedDirectional(
                        start: 0,
                        top: (OrionSizing.minHitTarget - _thumbSize) / 2,
                        width: _thumbSize,
                        height: _thumbSize,
                        child: AnimatedBuilder(
                          animation: _driver,
                          child: thumb,
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
