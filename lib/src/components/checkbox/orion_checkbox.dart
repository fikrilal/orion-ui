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

/// A box that confirms a boolean and can show an indeterminate middle state.
///
/// The parent owns [value]; null is indeterminate. The box is tap-only: it
/// does not drag, and it does not own a label row.
///
/// One [OrionSpringDriver] drives the fill, the border, and the mark's scale
/// on the travel spring, which is tuned for the full 0 to 1 state change
/// rather than for a press release. Checked and indeterminate share the
/// travel's filled end, so that step moves nothing - it gets its own 160 ms
/// cross-fade instead, and reduced motion swaps the glyph at once. The mark is
/// clipped by the box, so the overshoot cannot paint outside it. A tap emits
/// [OrionThemeData.selectionHaptic] once the tap wins the gesture arena; Enter
/// and Space flip the box silently. Focus paints a translucent overlay under
/// the box, not a second border.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionCheckboxPresets] for the [size], the ambient
/// [OrionCheckboxTheme], and the [style] passed here. Anything an override
/// does not name falls through. [error] rides the same machinery: it only
/// changes colours, and validation stays the host's.
class OrionCheckbox extends StatefulWidget {
  /// Creates a controlled checkbox.
  const OrionCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
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

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the box requests focus on first build.
  final bool autofocus;

  /// Spoken name. The checked state is exposed separately.
  final String? semanticLabel;

  /// The size step. Defaults to [OrionCheckboxSize.medium], the shipped box.
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
  /// Travel spring for the whole 0 to 1 state change.
  ///
  /// [OrionSpringSpec.snappy] is sized for the documented 0.96 to 1.0 press
  /// release, where its ~30% overshoot is 1.2% of scale. Driven over a full
  /// travel that same overshoot peaks at 1.297, so any sane cap holds the mark
  /// still for several frames and the fill dips to 0.91 on the way back.
  /// [OrionSpringSpec.gentle] peaks at 1.038 and dips to 0.9985: one visible
  /// pop, and a fill that never fades below full strength. The switch rides the
  /// same spring for its thumb travel.
  static const OrionSpringSpec _travel = OrionSpringSpec.gentle;

  /// The mark is 16 pt inside a 24 pt box, so it clears the edge until 1.5.
  /// The travel spring peaks near 1.04; this is a guard, not a shaping cap.
  static const double _markCeiling = 1.4;

  late final OrionSpringDriver _driver;
  bool _focused = false;

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
    final bool selected = widget.value != false;

    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (widget.error) WidgetState.error,
    };
    final Set<WidgetState> selectedStates = <WidgetState>{
      ...restingStates,
      if (selected) WidgetState.selected,
    };

    final Color fill =
        style.fillColor?.resolve(selectedStates) ?? scheme.primary;
    final Color fillRest =
        style.fillColor?.resolve(restingStates) ?? Colors.transparent;
    final Color borderRest =
        style.borderColor?.resolve(restingStates) ?? scheme.outline;
    final Color borderOn =
        style.borderColor?.resolve(selectedStates) ?? scheme.primary;
    final Color markColor =
        style.markColor?.resolve(selectedStates) ?? scheme.onPrimary;
    final double boxSize = style.size ?? OrionSizing.iconMedium;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radius4);
    final double borderWidth = style.borderWidth ?? 2;
    final double markSize = style.markSize ?? OrionSizing.iconSmall;
    final double barWidth = style.barWidth ?? OrionSpacing.space12;
    final double barHeight = style.barHeight ?? 2;
    final Color overlay =
        style.focusOverlayColor ?? scheme.onSurface.withValues(alpha: 0.12);

    final Widget mark = indeterminate
        ? SizedBox(
            width: barWidth,
            height: barHeight,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: markColor,
                borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
              ),
            ),
          )
        : Icon(Icons.check, size: markSize, color: markColor);

    // Checked and indeterminate are the same filled end, so the travel has no
    // distance to cover between them; the glyph swap carries its own
    // transition, and reduced motion swaps at once.
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
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
      child: KeyedSubtree(key: ValueKey<bool>(indeterminate), child: mark),
    );

    return Semantics(
      container: true,
      checked: widget.value ?? false,
      mixed: indeterminate,
      enabled: enabled,
      label: widget.semanticLabel,
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
        // Every other control in the kit gets its press feedback and its cue from
        // [OrionPressable]; these two hand-rolled a bare tap and a direct haptic.
        child: OrionPressable(
          behavior: HitTestBehavior.opaque,
          hapticType: OrionTheme.of(context).selectionHaptic,
          onTap: enabled ? _flip : null,
          child: SizedBox(
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
                      // The overlay sits under the box, so the border and fill
                      // stay legible and focus never draws a second border.
                      if (_focused && enabled)
                        SizedBox.square(
                          dimension: boxSize + OrionSpacing.space16,
                          child: ClipOval(child: ColoredBox(color: overlay)),
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
          ),
        ),
      ),
    );
  }
}
