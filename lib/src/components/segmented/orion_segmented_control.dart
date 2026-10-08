import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/segmented/orion_segmented_control_style.dart';
import 'package:orion_ui/src/components/segmented/orion_segmented_control_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One option in an [OrionSegmentedControl].
@immutable
class OrionSegment<T> {
  /// Creates a segment whose [label] is shown in the track.
  const OrionSegment({required this.value, required this.label, this.badge});

  /// Value reported when this segment becomes selected.
  final T value;

  /// Visible content. Text uses `labelMedium`; icons inherit the label color.
  final Widget label;

  /// Optional short content - a count, typically - shown in a counter chip
  /// after the label. The chip is themed by the control, muted when the
  /// control is disabled, and collapses in place when it disappears; the
  /// segment's slot keeps its width.
  final Widget? badge;
}

/// Single-select pill track. The parent owns [value].
///
/// Segments share the width equally. The selected pill slides on the immediate
/// travel spec, not the press spring. A bounded width is required.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionSegmentedControlStyle.defaults], the ambient
/// [OrionSegmentedControlTheme], and the [style] passed here. Anything an
/// override does not name falls through.
class OrionSegmentedControl<T> extends StatefulWidget {
  /// Creates a controlled segmented control.
  const OrionSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Options, left to right. Must be non-empty, with unique values.
  final List<OrionSegment<T>> segments;

  /// Currently selected value. Must equal one segment's value.
  final T value;

  /// Called with the newly selected value. Null disables the control.
  ///
  /// Tapping the already selected segment does not call this.
  final ValueChanged<T>? onChanged;

  /// Instance-level overrides, merged over the built-in defaults and the
  /// ambient [OrionSegmentedControlTheme]. Only the fields set here change.
  final OrionSegmentedControlStyle? style;

  /// Optional focus node for arrow-key selection.
  final FocusNode? focusNode;

  /// Whether the control requests focus on first build.
  final bool autofocus;

  @override
  State<OrionSegmentedControl<T>> createState() =>
      _OrionSegmentedControlState<T>();
}

class _OrionSegmentedControlState<T> extends State<OrionSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  late final OrionSpringDriver _driver;
  FocusNode? _ownedFocusNode;
  bool _focused = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    _debugValidate();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    final int index = _indexOf(widget.value);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: index < 0 ? 0 : index.toDouble(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    // The indicator travels between segments; it is not a press. The theme's press
    // spring is zeta 0.36, and its 30 % overshoot on a lateral move reads as a wobble
    // past the segment, so the indicator runs on the immediate travel spec instead.
    _driver.springSpec = OrionSpringSpec.immediate;
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion) {
          return;
        }
        final int index = _indexOf(widget.value);
        if (index >= 0) {
          _driver.jumpTo(index.toDouble());
        }
      });
    }
  }

  @override
  void didUpdateWidget(OrionSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _debugValidate();
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null) {
        _ownedFocusNode ??= FocusNode();
      } else {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
    }
    _syncPill();
  }

  @override
  void dispose() {
    _driver.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  int _indexOf(T value) {
    return widget.segments.indexWhere((segment) => segment.value == value);
  }

  void _debugValidate() {
    assert(widget.segments.isNotEmpty, 'segments must not be empty');
    assert(_valuesAreUnique(widget.segments), 'segment values must be unique');
    assert(_indexOf(widget.value) >= 0, 'value must match a segment');
  }

  bool _valuesAreUnique(List<OrionSegment<T>> segments) {
    final Set<T> seen = <T>{};
    for (final OrionSegment<T> segment in segments) {
      if (!seen.add(segment.value)) {
        return false;
      }
    }
    return true;
  }

  void _syncPill() {
    final int index = _indexOf(widget.value);
    if (index < 0) {
      return;
    }
    final double target = index.toDouble();
    if (_driver.target == target) {
      return;
    }
    _driver.retarget(target);
  }

  void _select(T value) {
    if (widget.onChanged == null || value == widget.value) {
      return;
    }
    widget.onChanged!(value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      _ => 0,
    };
    if (delta == 0) {
      return KeyEventResult.ignored;
    }
    final int current = _indexOf(widget.value);
    final int next = current + delta;
    if (current < 0 || next < 0 || next >= widget.segments.length) {
      return KeyEventResult.handled;
    }
    _select(widget.segments[next].value);
    return KeyEventResult.handled;
  }

  Widget _buildSegment(
    OrionSegment<T> segment, {
    required OrionSegmentedControlStyle style,
    required bool enabled,
    required TextStyle labelStyle,
    required TextStyle badgeTextStyle,
    required double iconSize,
    required double pressedScale,
    required OrionSpringSpec pressSpring,
    required OrionSpringSpec releaseSpring,
    required OrionHapticType haptic,
  }) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool selected = segment.value == widget.value;
    final Set<WidgetState> states = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (selected) WidgetState.selected,
    };
    return _SegmentButton(
      label: segment.label,
      badge: segment.badge,
      badgeStyle: style.badge,
      badgeTextStyle: badgeTextStyle,
      badgeFill: style.badge?.fill?.resolve(states) ?? scheme.primary,
      badgeInk: style.badge?.ink?.resolve(states) ?? scheme.onPrimary,
      selected: selected,
      enabled: enabled,
      textStyle: labelStyle,
      color: style.labelColor?.resolve(states) ?? scheme.onSurface,
      iconSize: iconSize,
      pressedScale: pressedScale,
      pressSpring: pressSpring,
      releaseSpring: releaseSpring,
      haptic: haptic,
      onTap: enabled ? () => _select(segment.value) : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final TextStyle baseLabelStyle =
        theme.textTheme.labelMedium ?? const TextStyle();
    final OrionSegmentedControlTheme controlTheme =
        theme.extension<OrionSegmentedControlTheme>() ??
        OrionSegmentedControlTheme.fallback;

    final OrionSegmentedControlStyle style =
        OrionSegmentedControlStyle.defaults(
          scheme: scheme,
          labelStyle: baseLabelStyle,
        ).merge(controlTheme.defaultStyle).merge(widget.style);

    final bool enabled = widget.onChanged != null;
    final int selectedIndex = _indexOf(widget.value);
    final double height = style.height ?? OrionSizing.minHitTarget;
    final double inset = style.inset ?? OrionSpacing.space4;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final TextStyle labelStyle = style.labelStyle ?? baseLabelStyle;
    final TextStyle badgeTextStyle =
        style.badge?.textStyle ?? theme.textTheme.labelSmall ?? labelStyle;
    final double iconSize = style.iconSize ?? OrionSizing.iconSmall;
    final Color focusRingColor = style.focusRingColor ?? scheme.onSurface;
    final double pressedScale = style.pressedScale ?? orion.pressScale;
    final OrionSpringSpec pressSpring = style.pressSpring ?? orion.pressSpring;
    final OrionSpringSpec releaseSpring =
        style.releaseSpring ?? orion.releaseSpring;
    final OrionHapticType haptic = style.hapticType ?? orion.selectionHaptic;
    final Color trackColor =
        style.trackColor?.resolve(<WidgetState>{
          if (!enabled) WidgetState.disabled,
        }) ??
        scheme.secondary;
    final Color pillColor =
        style.pillColor?.resolve(<WidgetState>{
          WidgetState.selected,
          if (!enabled) WidgetState.disabled,
        }) ??
        scheme.surface;

    final Widget segments = Padding(
      padding: EdgeInsets.symmetric(horizontal: inset),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final OrionSegment<T> segment in widget.segments)
            Expanded(
              child: _buildSegment(
                segment,
                style: style,
                enabled: enabled,
                labelStyle: labelStyle,
                badgeTextStyle: badgeTextStyle,
                iconSize: iconSize,
                pressedScale: pressedScale,
                pressSpring: pressSpring,
                releaseSpring: releaseSpring,
                haptic: haptic,
              ),
            ),
        ],
      ),
    );

    return Focus(
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
            'OrionSegmentedControl requires a bounded width.',
          );
          final double slotWidth =
              (constraints.maxWidth - inset * 2) / widget.segments.length;
          return SizedBox(
            width: constraints.maxWidth,
            height: height,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: radius,
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: _focused && enabled
                      ? Border.all(color: focusRingColor, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: <Widget>[
                      if (selectedIndex >= 0)
                        PositionedDirectional(
                          start: inset,
                          top: inset,
                          bottom: inset,
                          width: slotWidth,
                          child: AnimatedBuilder(
                            animation: _driver,
                            builder: (BuildContext context, Widget? child) {
                              final double direction =
                                  Directionality.of(context) ==
                                      TextDirection.rtl
                                  ? -1
                                  : 1;
                              return Transform.translate(
                                offset: Offset(
                                  direction * _driver.value * slotWidth,
                                  0,
                                ),
                                child: child,
                              );
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: pillColor,
                                borderRadius: radius,
                              ),
                            ),
                          ),
                        ),
                      segments,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.badge,
    required this.badgeStyle,
    required this.badgeTextStyle,
    required this.badgeFill,
    required this.badgeInk,
    required this.selected,
    required this.enabled,
    required this.textStyle,
    required this.color,
    required this.iconSize,
    required this.pressedScale,
    required this.pressSpring,
    required this.releaseSpring,
    required this.haptic,
    required this.onTap,
  });

  final Widget label;

  /// Optional short content - a count, typically - shown in a counter chip.
  final Widget? badge;

  /// The chip's metrics; colours arrive pre-resolved for this segment.
  final OrionSegmentBadgeStyle? badgeStyle;
  final TextStyle badgeTextStyle;
  final Color badgeFill;
  final Color badgeInk;

  final bool selected;
  final bool enabled;
  final TextStyle textStyle;
  final Color color;
  final double iconSize;
  final double pressedScale;
  final OrionSpringSpec pressSpring;
  final OrionSpringSpec releaseSpring;
  final OrionHapticType haptic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // The badge's presence is content, not travel: it collapses in place while
    // the pill keeps the springs. Reduced motion lands it in the same frame.
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final double badgeHeight = badgeStyle?.height ?? 18;
    final double badgeMinWidth = badgeStyle?.minWidth ?? 18;
    final EdgeInsetsGeometry badgePadding =
        badgeStyle?.padding ??
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space4);
    final double badgeGap = badgeStyle?.gap ?? OrionSpacing.space4;
    final Widget badgeChild = badge == null
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsets.only(left: badgeGap),
            child: Container(
              constraints: BoxConstraints(
                minWidth: badgeMinWidth,
                minHeight: badgeHeight,
              ),
              padding: badgePadding,
              decoration: BoxDecoration(
                color: badgeFill,
                borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
              ),
              child: Center(
                widthFactor: 1,
                heightFactor: 1,
                child: DefaultTextStyle(
                  style: badgeTextStyle.copyWith(color: badgeInk),
                  child: badge!,
                ),
              ),
            ),
          );

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: OrionPressable(
        onTap: selected ? null : onTap,
        pressedScale: pressedScale,
        springSpec: pressSpring,
        releaseSpringSpec: releaseSpring,
        hapticType: haptic,
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(color: color, size: iconSize),
            child: DefaultTextStyle(
              style: textStyle.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Flexible(child: label),
                  // An animated size cannot run at zero duration (it would
                  // re-dirty itself mid-layout), so reduced motion swaps the
                  // wrapper out entirely and the change lands in one frame.
                  if (reduced)
                    badgeChild
                  else
                    AnimatedSize(
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment.center,
                      child: badgeChild,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
