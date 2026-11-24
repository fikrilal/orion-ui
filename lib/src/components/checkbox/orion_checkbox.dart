import 'dart:ui' show PathMetric;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/checkbox/orion_checkbox_presets.dart';
import 'package:orion_ui/src/components/checkbox/orion_checkbox_style.dart';
import 'package:orion_ui/src/components/checkbox/orion_checkbox_theme.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The box's size step.
enum OrionCheckboxSize { small, medium, large }

/// Key for the custom-drawn checkmark inside [OrionCheckbox].
const Key orionCheckboxCheckMarkKey = Key('orion_checkbox_check_mark');

/// A box that confirms a boolean and can show an indeterminate middle state.
///
/// The parent owns [value]; null is indeterminate. Pass optional [label] and
/// [subtitle] to render a clickable label row where tapping anywhere along the
/// label toggles the checkbox.
///
/// One [OrionSpringDriver] drives the fill, border, and stroke-drawn check
/// mark on a crisp spring (`k = 520, zeta = 0.80`). Checked and indeterminate
/// share the travel's filled end, so that swap cross-fades cleanly in 160 ms
/// (or instantly under reduced motion). A tap emits
/// [OrionThemeData.selectionHaptic] once the tap wins the gesture arena; Enter
/// and Space flip the box silently. Focus paints a translucent overlay under
/// the box, not a second border.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionCheckboxPresets] for the [size], the ambient
/// [OrionCheckboxTheme], and the [style] passed here.
class OrionCheckbox extends StatefulWidget {
  /// Creates a controlled checkbox.
  const OrionCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.subtitle,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
    this.size = OrionCheckboxSize.medium,
    this.error = false,
    this.style,
  });

  /// Whether the box is checked. Null is indeterminate.
  final bool? value;

  /// Called with the opposite of [value]. An indeterminate box reports `true`.
  /// Null disables the box.
  final ValueChanged<bool?>? onChanged;

  /// Optional clickable text label displayed beside the checkbox.
  final String? label;

  /// Optional supporting description displayed beneath [label].
  final String? subtitle;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the box requests focus on first build.
  final bool autofocus;

  /// Spoken name. Defaults to [label] when provided; the checked state is
  /// exposed separately.
  final String? semanticLabel;

  /// The size step. Defaults to [OrionCheckboxSize.medium].
  final OrionCheckboxSize size;

  /// Paints the error role: an unchecked box borders in the scheme's error
  /// colour, a checked one fills with it. The box does not validate anything.
  final bool error;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionCheckboxTheme]. Only the fields set here change.
  final OrionCheckboxStyle? style;

  @override
  State<OrionCheckbox> createState() => _OrionCheckboxState();
}

class _OrionCheckboxState extends State<OrionCheckbox>
    with SingleTickerProviderStateMixin {
  static const OrionSpringSpec _travel = OrionCheckboxPresets.defaultSpring;

  /// Guard ceiling for mark scale overshoot.
  static const double _markCeiling = 1.4;

  late final OrionSpringDriver _driver;
  bool _focused = false;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: _travel,
    );
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
        _driver.jumpTo(_target);
      });
    }
  }

  @override
  void didUpdateWidget(OrionCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (widget.value != oldWidget.value) {
      _sync();
    }
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  /// The filled end of the travel. Checked and indeterminate are both filled.
  double get _target => widget.value == false ? 0 : 1;

  void _sync() {
    if (_driver.reducedMotion) {
      _driver.jumpTo(_target);
    } else {
      _driver.retarget(_target);
    }
  }

  void _syncMotion() {
    final OrionCheckboxStyle style = _resolve(Theme.of(context));
    _driver.springSpec = style.spring ?? _travel;
  }

  OrionCheckboxStyle _resolve(ThemeData theme) {
    final OrionCheckboxTheme boxTheme =
        theme.extension<OrionCheckboxTheme>() ?? OrionCheckboxTheme.fallback;
    return OrionCheckboxPresets.resolve(
      size: widget.size,
      scheme: theme.colorScheme,
    ).merge(boxTheme.defaultStyle).merge(widget.style);
  }

  void _flip() {
    if (widget.onChanged == null) {
      return;
    }
    widget.onChanged!(!(widget.value ?? false));
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionCheckboxStyle style = _resolve(theme);
    final bool enabled = widget.onChanged != null;
    final bool indeterminate = widget.value == null;
    final bool hasLabel = widget.label != null || widget.subtitle != null;

    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (widget.error) WidgetState.error,
    };
    final Set<WidgetState> filledStates = <WidgetState>{
      WidgetState.selected,
      ...restingStates,
    };

    final Color fill = style.fillColor?.resolve(filledStates) ?? scheme.primary;
    final Color fillRest =
        style.fillColor?.resolve(restingStates) ?? Colors.transparent;
    final Color borderRest =
        style.borderColor?.resolve(restingStates) ?? scheme.outline;
    final Color borderOn =
        style.borderColor?.resolve(filledStates) ?? scheme.primary;
    final Color markColor =
        style.markColor?.resolve(filledStates) ?? scheme.onPrimary;
    final double boxSize = style.size ?? OrionSizing.iconMedium;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radius6);
    final double borderWidth = style.borderWidth ?? 1.75;
    final double markSize = style.markSize ?? OrionSizing.iconSmall;
    final double barWidth = style.barWidth ?? OrionSpacing.space12;
    final double barHeight = style.barHeight ?? 2;
    final double pressedScale = style.pressedScale ?? 0.90;
    final Color overlay =
        style.focusOverlayColor ?? scheme.onSurface.withValues(alpha: 0.12);

    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final Widget indeterminateMark = SizedBox(
      width: barWidth,
      height: barHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: markColor,
          borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
        ),
      ),
    );

    final Widget checkMark = SizedBox.square(
      key: orionCheckboxCheckMarkKey,
      dimension: markSize,
      child: CustomPaint(
        painter: _CheckMarkPainter(
          progress: _driver,
          color: markColor,
          strokeWidth: (markSize * 0.145).clamp(1.75, 2.5),
        ),
      ),
    );

    final Widget swappedMark = AnimatedSwitcher(
      duration: reduce ? Duration.zero : const Duration(milliseconds: 160),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeOut,
      transitionBuilder: (Widget child, Animation<double> animation) =>
          FadeTransition(
            opacity: animation,
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.5, end: 1).animate(animation),
              child: child,
            ),
          ),
      child: KeyedSubtree(
        key: ValueKey<bool>(indeterminate),
        child: indeterminate ? indeterminateMark : checkMark,
      ),
    );

    final Widget boxTarget = SizedBox(
      width: OrionSizing.minHitTarget,
      height: OrionSizing.minHitTarget,
      child: Center(
        child: AnimatedBuilder(
          animation: _driver,
          child: swappedMark,
          builder: (BuildContext context, Widget? child) {
            final double shown = _driver.value.clamp(0.0, 1.0);
            return Stack(
              alignment: Alignment.center,
              children: <Widget>[
                if ((_focused || _hovered) && enabled)
                  SizedBox.square(
                    dimension: boxSize + OrionSpacing.space16,
                    child: ClipOval(
                      child: ColoredBox(
                        color: _focused
                            ? overlay
                            : scheme.onSurface.withValues(alpha: 0.05),
                      ),
                    ),
                  ),
                SizedBox.square(
                  dimension: boxSize,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Color.lerp(fillRest, fill, shown),
                      borderRadius: radius,
                      border: Border.all(
                        color: Color.lerp(borderRest, borderOn, shown)!,
                        width: borderWidth,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: radius,
                      child: Center(
                        child: Transform.scale(
                          scale: _driver.value.clamp(0.0, _markCeiling),
                          child: child,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );

    final Widget pressableBox = OrionPressable(
      behavior: HitTestBehavior.opaque,
      pressedScale: pressedScale,
      hapticType: OrionTheme.of(context).selectionHaptic,
      onTap: enabled ? _flip : null,
      child: boxTarget,
    );

    Widget interactiveChild;
    if (!hasLabel) {
      interactiveChild = pressableBox;
    } else {
      final Color labelColor = !enabled
          ? scheme.onSurface.withValues(alpha: 0.38)
          : widget.error
          ? scheme.error
          : scheme.onSurface;
      final Color subtitleColor = !enabled
          ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
          : scheme.onSurfaceVariant;

      // Wrap the whole row in a subtle tap target so clicking the text toggles
      // the box, while keeping the box's 0.90 tactile compression isolated to
      // the checkbox itself.
      interactiveChild = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? _flip : null,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: widget.subtitle != null
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.center,
          children: <Widget>[
            pressableBox,
            const SizedBox(width: OrionSpacing.space4),
            Flexible(
              child: Padding(
                padding: widget.subtitle != null
                    ? const EdgeInsets.only(top: 10.0)
                    : EdgeInsets.zero,
                child: ExcludeSemantics(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      if (widget.label != null)
                        Text(
                          widget.label!,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: labelColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      if (widget.subtitle != null) ...<Widget>[
                        const SizedBox(height: 2.0),
                        Text(
                          widget.subtitle!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: subtitleColor,
                            height: 1.35,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Semantics(
      container: true,
      checked: widget.value ?? false,
      mixed: indeterminate,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
      child: MouseRegion(
        onEnter: (_) {
          if (mounted && !_hovered) setState(() => _hovered = true);
        },
        onExit: (_) {
          if (mounted && _hovered) setState(() => _hovered = false);
        },
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          focusNode: widget.focusNode,
          autofocus: widget.autofocus,
          onShowFocusHighlight: (bool focused) {
            if (focused != _focused) {
              setState(() => _focused = focused);
            }
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                _flip();
                return null;
              },
            ),
          },
          child: interactiveChild,
        ),
      ),
    );
  }
}

/// Draws a crisp rounded-cap checkmark stroke progressively along its path as
/// [progress] travels from 0 to 1.
class _CheckMarkPainter extends CustomPainter {
  _CheckMarkPainter({
    required this.progress,
    required this.color,
    required this.strokeWidth,
  }) : super(repaint: progress);

  final Animation<double> progress;
  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final double t = progress.value.clamp(0.0, 1.0);
    if (t <= 0.01) return;

    final Paint paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final Path fullPath = Path()
      ..moveTo(size.width * 0.18, size.height * 0.52)
      ..lineTo(size.width * 0.41, size.height * 0.75)
      ..lineTo(size.width * 0.84, size.height * 0.27);

    // Draw stroke smoothly along the checkmark path.
    final double drawT = ((t - 0.12) / 0.88).clamp(0.0, 1.0);
    if (drawT <= 0.0) return;

    for (final PathMetric metric in fullPath.computeMetrics()) {
      final Path partial = metric.extractPath(0.0, metric.length * drawT);
      canvas.drawPath(partial, paint);
    }
  }

  @override
  bool shouldRepaint(_CheckMarkPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progress != progress;
  }
}
