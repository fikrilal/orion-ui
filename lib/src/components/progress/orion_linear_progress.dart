import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/progress/orion_progress_style.dart';
import 'package:orion_ui/src/components/progress/orion_progress_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

double _clampUnit(double value) => value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

/// A continuous progress bar from 0 through 1, determinate or indeterminate.
///
/// [value] is clamped to 0 through 1. A null [value] reads as indeterminate:
/// a pill-capped bar that grows out of the leading edge, stretches across the
/// track and sweeps through, with the next already growing before the previous
/// leaves (Material's linear-indicator rhythm), resting as a static centred
/// fill under reduced motion. [bufferedValue] animates smoothly behind [value]
/// on the same critically-damped spring and is ignored while indeterminate. The
/// parent owns the values, the bar does not take taps, and a bounded width is
/// required.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionProgressStyle.defaults], the ambient [OrionProgressTheme],
/// and the [style] passed here. Anything an override does not name falls
/// through.
class OrionLinearProgress extends StatefulWidget {
  /// Creates a continuous progress bar.
  const OrionLinearProgress({
    super.key,
    this.value,
    this.bufferedValue,
    this.tone = OrionProgressTone.primary,
    this.semanticLabel,
    this.semanticValue,
    this.style,
  });

  /// Progress from 0 through 1, clamped (non-finite values map to 0). Null
  /// reads as indeterminate.
  final double? value;

  /// Buffered progress from 0 through 1, smoothly animated behind [value] and
  /// clamped. Null paints no cache layer; ignored while indeterminate.
  final double? bufferedValue;

  /// Semantic colour tone. Defaults to [OrionProgressTone.primary].
  final OrionProgressTone tone;

  /// Spoken name. Defaults to "Progress".
  final String? semanticLabel;

  /// Optional spoken value override (e.g. `"340 MB of 1 GB"`). Defaults to the
  /// rounded percentage when determinate, or null when indeterminate.
  final String? semanticValue;

  /// Instance-level overrides, merged over the defaults and the ambient
  /// [OrionProgressTheme]. Only the fields set here change.
  final OrionProgressStyle? style;

  @override
  State<OrionLinearProgress> createState() => _OrionLinearProgressState();
}

class _OrionLinearProgressState extends State<OrionLinearProgress>
    with TickerProviderStateMixin {
  /// The continuous bar's default height: a hairline next to the segmented
  /// bar's 8.
  static const double _defaultHeight = 4;

  /// Critically damped. A progress fill must reach its target and stay there.
  static const OrionSpringSpec _settle = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  /// One full pass of the indeterminate loop, matching Material's linear
  /// indicator.
  static const Duration _sweepDuration = Duration(milliseconds: 1800);

  late final OrionSpringDriver _driver;
  late final OrionSpringDriver _bufferDriver;
  late final AnimationController _sweep;
  late double _paintMin;
  late double _paintMax;
  late double _bufferPaintMin;
  late double _bufferPaintMax;
  bool _reduced = false;

  bool get _indeterminate => widget.value == null;

  @override
  void initState() {
    super.initState();
    final double initial = widget.value == null
        ? 0.0
        : _clampUnit(widget.value!);
    final double initialBuffer = widget.bufferedValue == null
        ? 0.0
        : _clampUnit(widget.bufferedValue!);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: initial,
      springSpec: _settle,
    );
    _bufferDriver = OrionSpringDriver(
      vsync: this,
      initialValue: initialBuffer,
      springSpec: _settle,
    );
    _paintMin = initial;
    _paintMax = initial;
    _bufferPaintMin = initialBuffer;
    _bufferPaintMax = initialBuffer;
    _sweep = AnimationController(vsync: this, duration: _sweepDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncMotion();
    final bool becameReduced = _reduced && !_driver.reducedMotion;
    _driver.reducedMotion = _reduced;
    _bufferDriver.reducedMotion = _reduced;
    if (becameReduced && !_indeterminate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion || _indeterminate) {
          return;
        }
        final double target = _clampUnit(widget.value!);
        _paintMin = target;
        _paintMax = target;
        _driver.jumpTo(target);
        if (widget.bufferedValue != null) {
          final double bufTarget = _clampUnit(widget.bufferedValue!);
          _bufferPaintMin = bufTarget;
          _bufferPaintMax = bufTarget;
          _bufferDriver.jumpTo(bufTarget);
        }
      });
    }
    _syncSweep();
  }

  @override
  void didUpdateWidget(OrionLinearProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();

    final bool wasIndeterminate = oldWidget.value == null;
    if (wasIndeterminate != _indeterminate) {
      _syncSweep();
      if (_indeterminate) {
        // Stop and reset determinate drivers while indeterminate so a later
        // return to determinate always advances forward from 0 cleanly.
        _paintMin = 0.0;
        _paintMax = 0.0;
        _driver.jumpTo(0.0);
        _bufferPaintMin = 0.0;
        _bufferPaintMax = 0.0;
        _bufferDriver.jumpTo(0.0);
        return;
      }
      _syncValue();
      _syncBuffer(snapIfNew: true);
      return;
    }

    if (!_indeterminate) {
      if (widget.value != oldWidget.value) {
        _syncValue();
      }
      if (widget.bufferedValue != oldWidget.bufferedValue) {
        _syncBuffer(snapIfNew: oldWidget.bufferedValue == null);
      }
    }
  }

  @override
  void dispose() {
    _sweep.dispose();
    _bufferDriver.dispose();
    _driver.dispose();
    super.dispose();
  }

  void _syncMotion() {
    final OrionProgressStyle style = _resolve(Theme.of(context));
    final OrionSpringSpec spec = style.spring ?? _settle;
    _driver.springSpec = spec;
    _bufferDriver.springSpec = spec;
  }

  void _syncValue() {
    final double target = _clampUnit(widget.value!);
    if (_driver.target == target && _driver.value == target) {
      return;
    }
    _paintMin = math.min(_driver.value, target);
    _paintMax = math.max(_driver.value, target);
    if (_driver.reducedMotion) {
      _driver.jumpTo(target);
    } else {
      _driver.retarget(target);
    }
  }

  void _syncBuffer({required bool snapIfNew}) {
    if (widget.bufferedValue == null) {
      _bufferPaintMin = 0.0;
      _bufferPaintMax = 0.0;
      _bufferDriver.jumpTo(0.0);
      return;
    }
    final double target = _clampUnit(widget.bufferedValue!);
    if (snapIfNew || _bufferDriver.reducedMotion) {
      _bufferPaintMin = target;
      _bufferPaintMax = target;
      _bufferDriver.jumpTo(target);
      return;
    }
    if (_bufferDriver.target == target) {
      return;
    }
    _bufferPaintMin = math.min(_bufferDriver.value, target);
    _bufferPaintMax = math.max(_bufferDriver.value, target);
    _bufferDriver.retarget(target);
  }

  double _painted(double current) => current.clamp(_paintMin, _paintMax);

  double _paintedBuffer(double current) =>
      current.clamp(_bufferPaintMin, _bufferPaintMax);

  void _syncSweep() {
    final bool shouldRun = _indeterminate && !_reduced;
    if (shouldRun) {
      if (!_sweep.isAnimating) {
        _sweep.repeat();
      }
    } else if (_sweep.isAnimating) {
      _sweep.stop();
      _sweep.value = 0;
    }
  }

  OrionProgressStyle _resolve(ThemeData theme) {
    final OrionProgressTheme progressTheme =
        theme.extension<OrionProgressTheme>() ?? OrionProgressTheme.fallback;
    return OrionProgressStyle.defaults(
      scheme: theme.colorScheme,
      height: _defaultHeight,
      tone: widget.tone,
    ).merge(progressTheme.defaultStyle).merge(widget.style);
  }

  String? _valueText() {
    if (widget.semanticValue != null) {
      return widget.semanticValue;
    }
    final double? value = widget.value;
    if (value == null) {
      return null;
    }
    return '${(_clampUnit(value) * 100).round()}%';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionProgressStyle style = _resolve(theme);
    final double height = style.height ?? _defaultHeight;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final Color trackColor = style.trackColor ?? scheme.secondary;
    final Color fillColor = style.fillColor ?? scheme.primary;
    final Color bufferColor =
        style.bufferColor ?? fillColor.withValues(alpha: 0.24);
    final bool determinate = !_indeterminate;
    final bool hasBuffer = determinate && widget.bufferedValue != null;

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? 'Progress',
      value: _valueText(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          assert(
            constraints.hasBoundedWidth,
            'OrionLinearProgress requires a bounded width.',
          );
          final double width = constraints.maxWidth;
          return SizedBox(
            width: width,
            height: height,
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  DecoratedBox(decoration: BoxDecoration(color: trackColor)),
                  if (hasBuffer)
                    AnimatedBuilder(
                      animation: _bufferDriver,
                      builder: (BuildContext context, Widget? child) {
                        final double amount = _paintedBuffer(
                          _bufferDriver.value,
                        ).clamp(0.0, 1.0);
                        return Align(
                          alignment: AlignmentDirectional.centerStart,
                          child: SizedBox(
                            width: width * amount,
                            height: double.infinity,
                            child: child,
                          ),
                        );
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: bufferColor),
                      ),
                    ),
                  if (determinate)
                    AnimatedBuilder(
                      animation: _driver,
                      builder: (BuildContext context, Widget? child) {
                        final double amount = _painted(
                          _driver.value,
                        ).clamp(0.0, 1.0);
                        return Transform.scale(
                          alignment: AlignmentDirectional.centerStart,
                          scaleX: amount,
                          child: child,
                        );
                      },
                      child: DecoratedBox(
                        decoration: BoxDecoration(color: fillColor),
                      ),
                    )
                  else
                    _IndeterminateSweep(
                      controller: _sweep,
                      reduced: _reduced,
                      width: width,
                      color: fillColor,
                      radius: radius,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The indeterminate fill, built on Material's linear indicator: two lines
/// whose head and tail endpoints travel on the curve pairs below, so one bar
/// grows out of the leading edge, stretches across the track, sweeps through
/// and exits while the next one is already growing. It rests as a static
/// centred fill under reduced motion.
class _IndeterminateSweep extends StatelessWidget {
  const _IndeterminateSweep({
    required this.controller,
    required this.reduced,
    required this.width,
    required this.color,
    required this.radius,
  });

  final AnimationController controller;
  final bool reduced;

  /// The track's width, which the segment fractions resolve against.
  final double width;
  final Color color;
  final BorderRadius radius;

  /// The static fill's width under reduced motion, as a fraction of the track.
  static const double _reducedFraction = 0.3;

  /// The two lines' leading (head) and trailing (tail) endpoints over one
  /// loop, as Material's indeterminate linear defines them.
  static const Curve _firstHead = Interval(
    0,
    750 / 1800,
    curve: Cubic(0.2, 0.0, 0.8, 1.0),
  );
  static const Curve _firstTail = Interval(
    333 / 1800,
    1083 / 1800,
    curve: Cubic(0.4, 0.0, 1.0, 1.0),
  );
  static const Curve _secondHead = Interval(
    1000 / 1800,
    1567 / 1800,
    curve: Cubic(0.0, 0.0, 0.65, 1.0),
  );
  static const Curve _secondTail = Interval(
    1267 / 1800,
    1,
    curve: Cubic(0.10, 0.0, 0.45, 1.0),
  );

  @override
  Widget build(BuildContext context) {
    if (reduced) {
      return Align(
        alignment: AlignmentDirectional.center,
        child: SizedBox(
          width: width * _reducedFraction,
          height: double.infinity,
          child: DecoratedBox(
            decoration: BoxDecoration(color: color, borderRadius: radius),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, Widget? child) {
        final double t = controller.value;
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            ..._line(_secondTail.transform(t), _secondHead.transform(t)),
            ..._line(_firstTail.transform(t), _firstHead.transform(t)),
          ],
        );
      },
    );
  }

  /// One line, from its trailing to its leading endpoint; a line whose
  /// endpoints have met draws nothing.
  List<Widget> _line(double tail, double head) {
    if (head - tail <= 0) {
      return const <Widget>[];
    }
    return <Widget>[
      PositionedDirectional(
        start: tail * width,
        width: (head - tail) * width,
        top: 0,
        bottom: 0,
        child: DecoratedBox(
          decoration: BoxDecoration(color: color, borderRadius: radius),
        ),
      ),
    ];
  }
}
