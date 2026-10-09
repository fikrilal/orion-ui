import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/progress/orion_progress_style.dart';
import 'package:orion_ui/src/components/progress/orion_progress_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Equal segments that fill from the start as [value] advances.
///
/// The parent owns [value]. The bar does not take taps. A bounded width is
/// required.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionProgressStyle.defaults], the ambient [OrionProgressTheme],
/// and the [style] passed here. Anything an override does not name falls
/// through.
class OrionSegmentedProgress extends StatefulWidget {
  /// Creates a segmented progress bar.
  const OrionSegmentedProgress({
    super.key,
    required this.count,
    required this.value,
    this.semanticLabel,
    this.style,
  });

  /// Number of equal segments. Must be at least 1.
  final int count;

  /// Progress from 0 through [count]. Whole numbers fill that many segments.
  /// A fraction fills the next segment by that fraction.
  final double value;

  /// Spoken name. Defaults to "Progress".
  final String? semanticLabel;

  /// Instance-level overrides, merged over the defaults and the ambient
  /// [OrionProgressTheme]. Only the fields set here change.
  final OrionProgressStyle? style;

  @override
  State<OrionSegmentedProgress> createState() => _OrionSegmentedProgressState();
}

class _OrionSegmentedProgressState extends State<OrionSegmentedProgress>
    with SingleTickerProviderStateMixin {
  /// The segmented bar's shipped height.
  static const double _defaultHeight = 8;

  /// Critically damped. A progress fill must reach its target and stay there.
  static const OrionSpringSpec _settle = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  late final OrionSpringDriver _driver;
  late double _paintMin;
  late double _paintMax;

  @override
  void initState() {
    super.initState();
    _debugValidate();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: widget.value,
      springSpec: _settle,
    );
    _paintMin = widget.value;
    _paintMax = widget.value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion) {
          return;
        }
        _driver.jumpTo(widget.value);
      });
    }
  }

  @override
  void didUpdateWidget(OrionSegmentedProgress oldWidget) {
    super.didUpdateWidget(oldWidget);
    _debugValidate();
    _syncMotion();
    _sync();
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  void _debugValidate() {
    assert(widget.count >= 1, 'count must be at least 1');
    assert(
      widget.value >= 0 && widget.value <= widget.count,
      'value must be from 0 through count',
    );
  }

  void _syncMotion() {
    final OrionProgressStyle style = _resolve(Theme.of(context));
    _driver.springSpec = style.spring ?? _settle;
  }

  void _sync() {
    final double target = widget.value;
    if (_driver.target == target) {
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

  double _painted(double current) => current.clamp(_paintMin, _paintMax);

  String _valueText() {
    final double value = widget.value;
    final String shown = value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
    return '$shown of ${widget.count}';
  }

  OrionProgressStyle _resolve(ThemeData theme) {
    final OrionProgressTheme progressTheme =
        theme.extension<OrionProgressTheme>() ?? OrionProgressTheme.fallback;
    return OrionProgressStyle.defaults(
      scheme: theme.colorScheme,
      height: _defaultHeight,
    ).merge(progressTheme.defaultStyle).merge(widget.style);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionProgressStyle style = _resolve(theme);
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final double gap = style.gap ?? OrionSpacing.space4;
    return Semantics(
      container: true,
      label: widget.semanticLabel ?? 'Progress',
      value: _valueText(),
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          assert(
            constraints.hasBoundedWidth,
            'OrionSegmentedProgress requires a bounded width.',
          );
          return SizedBox(
            width: constraints.maxWidth,
            height: style.height ?? _defaultHeight,
            child: Row(
              children: <Widget>[
                for (int index = 0; index < widget.count; index++) ...<Widget>[
                  if (index > 0) SizedBox(width: gap),
                  Expanded(
                    child: _ProgressSegment(
                      driver: _driver,
                      index: index,
                      painted: _painted,
                      trackColor: style.trackColor ?? scheme.secondary,
                      fillColor: style.fillColor ?? scheme.primary,
                      radius: radius,
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  const _ProgressSegment({
    required this.driver,
    required this.index,
    required this.painted,
    required this.trackColor,
    required this.fillColor,
    required this.radius,
  });

  final OrionSpringDriver driver;
  final int index;
  final double Function(double current) painted;
  final Color trackColor;
  final Color fillColor;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: radius,
      child: Stack(
        fit: StackFit.expand,
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(color: trackColor, borderRadius: radius),
          ),
          AnimatedBuilder(
            animation: driver,
            builder: (BuildContext context, Widget? child) {
              final double amount = (painted(driver.value) - index).clamp(
                0.0,
                1.0,
              );
              return Transform.scale(
                alignment: AlignmentDirectional.centerStart,
                scaleX: amount,
                child: child,
              );
            },
            child: DecoratedBox(decoration: BoxDecoration(color: fillColor)),
          ),
        ],
      ),
    );
  }
}
