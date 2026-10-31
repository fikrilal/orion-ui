import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/progress/orion_progress_style.dart';
import 'package:orion_ui/src/components/progress/orion_progress_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

double _clampUnit(double value) => value.isFinite ? value.clamp(0.0, 1.0) : 0.0;

/// A circular progress ring from 0 through 1, determinate or indeterminate.
///
/// [value] is clamped to 0 through 1 and sweeps clockwise from 12 o'clock on a
/// critically-damped spring so determinate progress never wobbles or overshoots.
/// A null [value] renders a continuous, C1-smooth indeterminate spinner that
/// rests as a static quarter-arc under reduced motion.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionProgressStyle.defaults], the ambient [OrionProgressTheme],
/// and the [style] passed here (with [size] and [strokeWidth] shorthands taking
/// final precedence).
class OrionCircularProgress extends StatefulWidget {
  /// Creates a circular progress indicator.
  const OrionCircularProgress({
    super.key,
    this.value,
    this.tone = OrionProgressTone.primary,
    this.size,
    this.strokeWidth,
    this.child,
    this.semanticLabel,
    this.semanticValue,
    this.style,
  }) : assert(size == null || size > 0, 'size must be positive'),
       assert(
         strokeWidth == null || strokeWidth > 0,
         'strokeWidth must be positive',
       );

  /// Progress from 0 through 1, clamped (non-finite values map to 0). Null
  /// renders an indeterminate spinner.
  final double? value;

  /// Semantic colour tone. Defaults to [OrionProgressTone.primary].
  final OrionProgressTone tone;

  /// Optional outer diameter shorthand overriding `style.size` (default `40`).
  final double? size;

  /// Optional stroke thickness shorthand overriding `style.strokeWidth`
  /// (default `4`).
  final double? strokeWidth;

  /// Optional centered content inside the ring (such as a percentage label or
  /// completion icon). Held static across animation ticks.
  final Widget? child;

  /// Spoken name. Defaults to "Progress".
  final String? semanticLabel;

  /// Optional spoken value override. Defaults to the rounded percentage when
  /// determinate, or null when indeterminate.
  final String? semanticValue;

  /// Instance-level style overrides.
  final OrionProgressStyle? style;

  @override
  State<OrionCircularProgress> createState() => _OrionCircularProgressState();
}

class _OrionCircularProgressState extends State<OrionCircularProgress>
    with TickerProviderStateMixin {
  static const double _defaultSize = 40.0;
  static const double _defaultStrokeWidth = 4.0;

  static const OrionSpringSpec _settle = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  static const Duration _spinDuration = Duration(milliseconds: 1350);

  static const Curve _headCurve = Interval(
    0.0,
    0.5,
    curve: Curves.easeInOutCubic,
  );
  static const Curve _tailCurve = Interval(
    0.5,
    1.0,
    curve: Curves.easeInOutCubic,
  );

  late final OrionSpringDriver _driver;
  late final AnimationController _spin;
  late double _paintMin;
  late double _paintMax;
  bool _reduced = false;

  bool get _indeterminate => widget.value == null;

  @override
  void initState() {
    super.initState();
    final double initial = widget.value == null
        ? 0.0
        : _clampUnit(widget.value!);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: initial,
      springSpec: _settle,
    );
    _paintMin = initial;
    _paintMax = initial;
    _spin = AnimationController(vsync: this, duration: _spinDuration);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncMotion();
    final bool becameReduced = _reduced && !_driver.reducedMotion;
    _driver.reducedMotion = _reduced;
    if (becameReduced && !_indeterminate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion || _indeterminate) {
          return;
        }
        final double target = _clampUnit(widget.value!);
        _paintMin = target;
        _paintMax = target;
        _driver.jumpTo(target);
      });
    }
    _syncSpin();
  }

  @override
  void didUpdateWidget(OrionCircularProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();

    final bool wasIndeterminate = oldWidget.value == null;
    if (wasIndeterminate != _indeterminate) {
      _syncSpin();
      if (_indeterminate) {
        _paintMin = 0.0;
        _paintMax = 0.0;
        _driver.jumpTo(0.0);
        return;
      }
      _syncValue();
      return;
    }

    if (!_indeterminate && widget.value != oldWidget.value) {
      _syncValue();
    }
  }

  @override
  void dispose() {
    _spin.dispose();
    _driver.dispose();
    super.dispose();
  }

  void _syncMotion() {
    final OrionProgressStyle style = _resolve(Theme.of(context));
    _driver.springSpec = style.spring ?? _settle;
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

  void _syncSpin() {
    final bool shouldRun = _indeterminate && !_reduced;
    if (shouldRun) {
      if (!_spin.isAnimating) {
        _spin.repeat();
      }
    } else if (_spin.isAnimating) {
      _spin.stop();
      _spin.value = 0;
    }
  }

  double _painted(double current) => current.clamp(_paintMin, _paintMax);

  OrionProgressStyle _resolve(ThemeData theme) {
    final OrionProgressTheme progressTheme =
        theme.extension<OrionProgressTheme>() ?? OrionProgressTheme.fallback;
    return OrionProgressStyle.defaults(
      scheme: theme.colorScheme,
      height: _defaultStrokeWidth,
      tone: widget.tone,
      size: _defaultSize,
      strokeWidth: _defaultStrokeWidth,
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

    final double diameter = widget.size ?? style.size ?? _defaultSize;
    final double strokeWidth =
        widget.strokeWidth ?? style.strokeWidth ?? _defaultStrokeWidth;
    final Color trackColor = style.trackColor ?? scheme.secondary;
    final Color fillColor = style.fillColor ?? scheme.primary;
    final StrokeCap strokeCap = style.strokeCap ?? StrokeCap.round;

    final Widget? centeredChild = widget.child == null
        ? null
        : Center(child: widget.child);

    final Widget ring;
    if (!_indeterminate) {
      ring = AnimatedBuilder(
        animation: _driver,
        child: centeredChild,
        builder: (BuildContext context, Widget? child) {
          final double amount = _painted(_driver.value).clamp(0.0, 1.0);
          return CustomPaint(
            painter: _OrionCircularProgressPainter(
              startAngle: -math.pi / 2.0,
              sweepAngle: amount * math.pi * 2.0,
              trackColor: trackColor,
              fillColor: fillColor,
              strokeWidth: strokeWidth,
              strokeCap: strokeCap,
            ),
            child: child,
          );
        },
      );
    } else if (_reduced) {
      ring = CustomPaint(
        painter: _OrionCircularProgressPainter(
          startAngle: -math.pi / 2.0,
          sweepAngle: math.pi * 0.5,
          trackColor: trackColor,
          fillColor: fillColor,
          strokeWidth: strokeWidth,
          strokeCap: strokeCap,
        ),
        child: centeredChild,
      );
    } else {
      ring = AnimatedBuilder(
        animation: _spin,
        child: centeredChild,
        builder: (BuildContext context, Widget? child) {
          final double t = _spin.value;
          const double twoPi = math.pi * 2.0;
          const double minArc = 0.12 * twoPi;
          const double maxExtraArc = 0.75 * twoPi;
          final double head = _headCurve.transform(t) * maxExtraArc;
          final double tail = _tailCurve.transform(t) * maxExtraArc;
          final double rotation = t * 0.25 * twoPi;

          return CustomPaint(
            painter: _OrionCircularProgressPainter(
              startAngle: -math.pi / 2.0 + tail + rotation,
              sweepAngle: minArc + (head - tail),
              trackColor: trackColor,
              fillColor: fillColor,
              strokeWidth: strokeWidth,
              strokeCap: strokeCap,
            ),
            child: child,
          );
        },
      );
    }

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? 'Progress',
      value: _valueText(),
      child: SizedBox(width: diameter, height: diameter, child: ring),
    );
  }
}

class _OrionCircularProgressPainter extends CustomPainter {
  const _OrionCircularProgressPainter({
    required this.startAngle,
    required this.sweepAngle,
    required this.trackColor,
    required this.fillColor,
    required this.strokeWidth,
    required this.strokeCap,
  });

  final double startAngle;
  final double sweepAngle;
  final Color trackColor;
  final Color fillColor;
  final double strokeWidth;
  final StrokeCap strokeCap;

  @override
  void paint(Canvas canvas, Size size) {
    final double effectiveStroke = math.min(strokeWidth, size.shortestSide / 2);
    if (effectiveStroke <= 0) return;

    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - effectiveStroke) / 2.0;
    if (radius <= 0) return;

    final Paint trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveStroke;
    canvas.drawCircle(center, radius, trackPaint);

    if (sweepAngle <= 0.0001) return;

    final Paint fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = effectiveStroke
      ..strokeCap = sweepAngle >= (math.pi * 2.0 - 0.001)
          ? StrokeCap.butt
          : strokeCap;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle.clamp(0.0, math.pi * 2.0),
      false,
      fillPaint,
    );
  }

  @override
  bool shouldRepaint(_OrionCircularProgressPainter oldDelegate) {
    return startAngle != oldDelegate.startAngle ||
        sweepAngle != oldDelegate.sweepAngle ||
        trackColor != oldDelegate.trackColor ||
        fillColor != oldDelegate.fillColor ||
        strokeWidth != oldDelegate.strokeWidth ||
        strokeCap != oldDelegate.strokeCap;
  }
}
