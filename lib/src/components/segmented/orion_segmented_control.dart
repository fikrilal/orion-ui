import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
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
  const OrionSegment({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
    this.enabled = true,
    this.semanticLabel,
    this.tooltip,
  });

  /// Value reported when this segment becomes selected.
  final T value;

  /// Visible content. Text uses `labelMedium`; icons inherit the label color.
  final Widget label;

  /// Optional leading icon rendered before [label], inheriting the segment's
  /// live colour and `iconSize`.
  final Widget? icon;

  /// Optional short content - a count, typically - shown in a counter chip
  /// after the label. The chip is themed by the control, muted when the
  /// segment or control is disabled, and collapses in place when it disappears;
  /// the segment's slot keeps its width.
  final Widget? badge;

  /// Whether this individual segment can be selected. Disabled segments are
  /// muted and skipped by taps, keyboard navigation, and pill scrubbing.
  final bool enabled;

  /// Optional spoken label for screen readers (recommended for icon-only
  /// segments).
  final String? semanticLabel;

  /// Optional tooltip displayed on long-press or pointer hover.
  final String? tooltip;
}

/// Single-select pill track. The parent owns [value].
///
/// Segments share equal slot widths—filling the available bounded width when
/// [expand] is `true` (the default), or sizing intrinsically to the widest
/// segment when [expand] is `false`.
///
/// The active pill slides on [OrionSegmentedControlStyle.travelSpring]
/// (defaulting to [OrionSpringSpec.immediate] for crisp lateral motion without
/// overshoot), derives a concentric inner corner radius from the track's outer
/// radius, supports interactive horizontal drag-to-scrub with detent haptics,
/// and smoothly synchronizes label/icon ink transitions as the pill glides.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionSegmentedControlStyle.defaults] for [size], the ambient
/// [OrionSegmentedControlTheme], and the [style] passed here. Anything an
/// override does not name falls through.
class OrionSegmentedControl<T> extends StatefulWidget {
  /// Creates a controlled segmented control.
  const OrionSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.size = OrionSegmentedControlSize.medium,
    this.expand = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// Options, in reading order. Must be non-empty, with unique values.
  final List<OrionSegment<T>> segments;

  /// Currently selected value. Must equal one segment's value.
  final T value;

  /// Called with the newly selected value. Null disables the control.
  ///
  /// Tapping the already selected segment does not call this.
  final ValueChanged<T>? onChanged;

  /// Visual size step controlling track height, inset, icon size, and badge
  /// scale. Defaults to [OrionSegmentedControlSize.medium].
  final OrionSegmentedControlSize size;

  /// Whether the control stretches to fill incoming bounded width (`true`, the
  /// default) or sizes intrinsically to the widest equal slot (`false`) so it
  /// can be placed inside an unbounded [Row], [Wrap], or [AppBar].
  final bool expand;

  /// Instance-level overrides, merged over the built-in defaults and the
  /// ambient [OrionSegmentedControlTheme]. Only the fields set here change.
  final OrionSegmentedControlStyle? style;

  /// Optional focus node for keyboard navigation.
  final FocusNode? focusNode;

  /// Whether the control requests focus on first build.
  final bool autofocus;

  @override
  State<OrionSegmentedControl<T>> createState() =>
      _OrionSegmentedControlState<T>();
}

class _OrionSegmentedControlState<T> extends State<OrionSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  final GlobalKey _trackKey = GlobalKey();
  late final OrionSpringDriver _driver;
  FocusNode? _ownedFocusNode;
  bool _focused = false;
  bool _dragging = false;
  double _dragStartOffset = 0.0;
  int _dragLastIndex = -1;

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
      springSpec: OrionSpringSpec.immediate,
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
    _syncMotion();
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null) {
        _ownedFocusNode ??= FocusNode();
      } else {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
    }
    if (widget.onChanged == null) {
      _dragging = false;
      _focused = false;
    } else if (widget.segments.length != oldWidget.segments.length) {
      _dragging = false;
    }
    if (!_dragging) {
      _syncPill();
    }
  }

  @override
  void dispose() {
    _driver.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  OrionSegmentedControlStyle _resolveStyle(ThemeData theme) {
    final TextStyle baseLabelStyle =
        (widget.size == OrionSegmentedControlSize.small
            ? theme.textTheme.labelSmall
            : theme.textTheme.labelMedium) ??
        const TextStyle();
    final OrionSegmentedControlTheme controlTheme =
        theme.extension<OrionSegmentedControlTheme>() ??
        OrionSegmentedControlTheme.fallback;
    return OrionSegmentedControlStyle.defaults(
      scheme: theme.colorScheme,
      labelStyle: baseLabelStyle,
      size: widget.size,
    ).merge(controlTheme.defaultStyle).merge(widget.style);
  }

  void _syncMotion() {
    final OrionSegmentedControlStyle style = _resolveStyle(Theme.of(context));
    _driver.springSpec = style.travelSpring ?? OrionSpringSpec.immediate;
  }

  int _indexOf(T value) {
    return widget.segments.indexWhere((segment) => segment.value == value);
  }

  bool _isSegmentEnabled(int index) {
    if (widget.onChanged == null ||
        index < 0 ||
        index >= widget.segments.length) {
      return false;
    }
    return widget.segments[index].enabled;
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
    if (_driver.target == target && (_driver.value - target).abs() < 0.0001) {
      return;
    }
    if (_driver.target == target && !_dragging) {
      return;
    }
    _driver.retarget(target);
  }

  void _select(T value) {
    if (widget.onChanged == null || value == widget.value) {
      return;
    }
    final int idx = _indexOf(value);
    if (idx < 0 || !widget.segments[idx].enabled) {
      return;
    }
    widget.onChanged!(value);
  }

  int? _findNextEnabled(int fromIndex, int delta) {
    int candidate = fromIndex + delta;
    while (candidate >= 0 && candidate < widget.segments.length) {
      if (widget.segments[candidate].enabled) {
        return candidate;
      }
      candidate += delta;
    }
    return null;
  }

  int? _findBoundaryEnabled({required bool fromStart}) {
    if (fromStart) {
      for (int i = 0; i < widget.segments.length; i++) {
        if (widget.segments[i].enabled) {
          return i;
        }
      }
    } else {
      for (int i = widget.segments.length - 1; i >= 0; i--) {
        if (widget.segments[i].enabled) {
          return i;
        }
      }
    }
    return null;
  }

  int? _nearestEnabledIndex(int target) {
    final int count = widget.segments.length;
    if (count == 0) {
      return null;
    }
    final int clamped = target.clamp(0, count - 1);
    if (widget.segments[clamped].enabled) {
      return clamped;
    }
    for (int offset = 1; offset < count; offset++) {
      final int right = clamped + offset;
      if (right < count && widget.segments[right].enabled) {
        return right;
      }
      final int left = clamped - offset;
      if (left >= 0 && widget.segments[left].enabled) {
        return left;
      }
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if ((event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        widget.onChanged == null ||
        widget.segments.isEmpty) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey key = event.logicalKey;

    int? targetIndex;
    if (key == LogicalKeyboardKey.arrowRight) {
      final int current = _indexOf(widget.value);
      if (current >= 0) {
        targetIndex = _findNextEnabled(current, rtl ? -1 : 1);
      }
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      final int current = _indexOf(widget.value);
      if (current >= 0) {
        targetIndex = _findNextEnabled(current, rtl ? 1 : -1);
      }
    } else if (key == LogicalKeyboardKey.home) {
      targetIndex = _findBoundaryEnabled(fromStart: true);
    } else if (key == LogicalKeyboardKey.end) {
      targetIndex = _findBoundaryEnabled(fromStart: false);
    } else {
      return KeyEventResult.ignored;
    }

    if (targetIndex != null) {
      _select(widget.segments[targetIndex].value);
    }
    return KeyEventResult.handled;
  }

  _RenderEqualSlotTrack? get _trackRenderBox {
    final RenderObject? ro = _trackKey.currentContext?.findRenderObject();
    return ro is _RenderEqualSlotTrack ? ro : null;
  }

  double _localReadingX(Offset localPosition, _RenderEqualSlotTrack box) {
    final double inset = box.inset;
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    return rtl
        ? (box.size.width - inset - localPosition.dx)
        : (localPosition.dx - inset);
  }

  void _handleDragStart(DragStartDetails details) {
    final _RenderEqualSlotTrack? box = _trackRenderBox;
    if (box == null || box.slotWidth <= 0 || widget.segments.length <= 1) {
      return;
    }
    final int selectedIndex = _indexOf(widget.value);
    if (selectedIndex < 0) {
      return;
    }
    final double localX = _localReadingX(details.localPosition, box);
    final double pillStart = _driver.value * box.slotWidth;
    final double pillEnd = pillStart + box.slotWidth;
    final bool startedOnPill = localX >= pillStart && localX <= pillEnd;

    _dragging = true;
    _dragLastIndex = selectedIndex;
    _dragStartOffset = startedOnPill
        ? (localX - pillStart)
        : (box.slotWidth * 0.5);
  }

  void _handleDragUpdate(DragUpdateDetails details, OrionHapticType haptic) {
    if (!_dragging) {
      return;
    }
    final _RenderEqualSlotTrack? box = _trackRenderBox;
    if (box == null || box.slotWidth <= 0 || widget.segments.length <= 1) {
      return;
    }
    final double maxIndex = (widget.segments.length - 1).toDouble();
    final double localX = _localReadingX(details.localPosition, box);
    final double raw = (localX - _dragStartOffset) / box.slotWidth;

    double position;
    if (raw < 0.0) {
      position = math.max(-0.18, raw * 0.25);
    } else if (raw > maxIndex) {
      position = maxIndex + math.min(0.18, (raw - maxIndex) * 0.25);
    } else {
      position = raw;
    }

    _driver.jumpTo(position);

    final int? nearest = _nearestEnabledIndex(position.round());
    if (nearest != null && nearest != _dragLastIndex) {
      _dragLastIndex = nearest;
      if (haptic != OrionHapticType.none) {
        OrionHaptics.trigger(haptic);
      }
    }
  }

  void _handleDragEnd() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    final int currentIndex = _indexOf(widget.value);
    final int? targetIndex =
        _nearestEnabledIndex(_driver.value.round()) ??
        (currentIndex >= 0 ? currentIndex : null);

    if (targetIndex == null) {
      return;
    }
    if (targetIndex != currentIndex) {
      _select(widget.segments[targetIndex].value);
    }
    _driver.retarget(targetIndex.toDouble());
  }

  static BorderRadius _innerRadius(BorderRadius outer, double inset) {
    Radius shrink(Radius r) {
      if (r.x >= 500 && r.y >= 500) {
        return r;
      }
      return Radius.elliptical(
        math.max(0.0, r.x - inset),
        math.max(0.0, r.y - inset),
      );
    }

    return BorderRadius.only(
      topLeft: shrink(outer.topLeft),
      topRight: shrink(outer.topRight),
      bottomLeft: shrink(outer.bottomLeft),
      bottomRight: shrink(outer.bottomRight),
    );
  }

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionSegmentedControlStyle style = _resolveStyle(theme);

    final bool controlEnabled = widget.onChanged != null;
    final double height = math.max(
      0.0,
      style.height ?? OrionSizing.minHitTarget,
    );
    if (widget.segments.isEmpty) {
      return SizedBox(height: height);
    }

    final int selectedIndex = _indexOf(widget.value);
    final double inset = math.max(0.0, style.inset ?? OrionSpacing.space4);
    final BorderRadius outerRadius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final BorderRadius pillRadius = _innerRadius(outerRadius, inset);
    final TextStyle labelStyle =
        style.labelStyle ??
        (widget.size == OrionSegmentedControlSize.small
            ? theme.textTheme.labelSmall
            : theme.textTheme.labelMedium) ??
        const TextStyle();
    final TextStyle badgeTextStyle =
        style.badge?.textStyle ?? theme.textTheme.labelSmall ?? labelStyle;
    final double iconSize = style.iconSize ?? OrionSizing.iconSmall;
    final EdgeInsetsGeometry segmentPadding =
        style.segmentPadding ??
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space8);
    final Color focusRingColor = style.focusRingColor ?? scheme.onSurface;
    final Color hoverColor =
        style.hoverColor ??
        scheme.onSurface.withValues(
          alpha: theme.brightness == Brightness.dark ? 0.06 : 0.04,
        );
    final double pressedScale = style.pressedScale ?? orion.pressScale;
    final OrionSpringSpec pressSpring = style.pressSpring ?? orion.pressSpring;
    final OrionSpringSpec releaseSpring =
        style.releaseSpring ?? orion.releaseSpring;
    final OrionHapticType haptic = style.hapticType ?? orion.selectionHaptic;

    final Color trackColor =
        style.trackColor?.resolve(<WidgetState>{
          if (!controlEnabled) WidgetState.disabled,
        }) ??
        scheme.secondary;
    final BorderSide trackBorder = style.trackBorder ?? BorderSide.none;
    final Color pillColor =
        style.pillColor?.resolve(<WidgetState>{
          WidgetState.selected,
          if (!controlEnabled) WidgetState.disabled,
        }) ??
        scheme.surface;
    final BorderSide pillBorder = controlEnabled
        ? (style.pillBorder ?? BorderSide.none)
        : BorderSide.none;
    final List<BoxShadow>? pillShadow =
        controlEnabled && (style.pillShadow?.isNotEmpty ?? false)
        ? style.pillShadow
        : null;

    final TextDirection textDirection = Directionality.of(context);
    final double direction = textDirection == TextDirection.rtl ? -1.0 : 1.0;

    final Widget pillChild = selectedIndex >= 0
        ? LayoutBuilder(
            builder: (BuildContext context, BoxConstraints pillConstraints) {
              final double slotWidth = pillConstraints.maxWidth;
              return AnimatedBuilder(
                animation: _driver,
                builder: (BuildContext context, Widget? child) {
                  return Transform.translate(
                    offset: Offset(direction * _driver.value * slotWidth, 0),
                    child: child,
                  );
                },
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: pillColor,
                    borderRadius: pillRadius,
                    border: pillBorder == BorderSide.none
                        ? null
                        : Border.fromBorderSide(pillBorder),
                    boxShadow: pillShadow,
                  ),
                ),
              );
            },
          )
        : const SizedBox.shrink();

    final bool canScrub = controlEnabled && widget.segments.length > 1;

    final Widget track = DecoratedBox(
      decoration: BoxDecoration(
        color: trackColor,
        borderRadius: outerRadius,
        border: trackBorder == BorderSide.none
            ? null
            : Border.fromBorderSide(trackBorder),
      ),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: outerRadius,
          border: _focused && controlEnabled
              ? Border.all(
                  color: focusRingColor,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                )
              : null,
        ),
        child: ClipRRect(
          borderRadius: outerRadius,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onHorizontalDragStart: canScrub ? _handleDragStart : null,
            onHorizontalDragUpdate: canScrub
                ? (DragUpdateDetails details) =>
                      _handleDragUpdate(details, haptic)
                : null,
            onHorizontalDragEnd: canScrub
                ? (DragEndDetails _) => _handleDragEnd()
                : null,
            onHorizontalDragCancel: canScrub ? _handleDragEnd : null,
            child: _EqualSlotTrack(
              key: _trackKey,
              height: height,
              inset: inset,
              expand: widget.expand,
              textDirection: textDirection,
              hasPill: selectedIndex >= 0,
              children: <Widget>[
                pillChild,
                for (int i = 0; i < widget.segments.length; i++)
                  _SegmentButton(
                    index: i,
                    driver: _driver,
                    label: widget.segments[i].label,
                    icon: widget.segments[i].icon,
                    badge: widget.segments[i].badge,
                    semanticLabel: widget.segments[i].semanticLabel,
                    tooltip: widget.segments[i].tooltip,
                    badgeStyle: style.badge,
                    badgeTextStyle: badgeTextStyle,
                    labelColorProperty: style.labelColor,
                    defaultRestColor: scheme.onSurfaceVariant,
                    defaultSelectedColor: scheme.onSurface,
                    defaultBadgeFill: scheme.primary,
                    defaultBadgeInk: scheme.onPrimary,
                    selected: widget.segments[i].value == widget.value,
                    enabled: _isSegmentEnabled(i),
                    textStyle: labelStyle,
                    iconSize: iconSize,
                    inset: inset,
                    padding: segmentPadding,
                    hoverColor: hoverColor,
                    hoverRadius: pillRadius,
                    pressedScale: pressedScale,
                    pressSpring: pressSpring,
                    releaseSpring: releaseSpring,
                    haptic: haptic,
                    onTap: _isSegmentEnabled(i)
                        ? () => _select(widget.segments[i].value)
                        : null,
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: FocusableActionDetector(
        enabled: controlEnabled,
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (bool focused) {
          if (focused != _focused) {
            setState(() => _focused = focused);
          }
        },
        child: track,
      ),
    );
  }
}

class _SegmentButton extends StatefulWidget {
  const _SegmentButton({
    required this.index,
    required this.driver,
    required this.label,
    required this.icon,
    required this.badge,
    required this.semanticLabel,
    required this.tooltip,
    required this.badgeStyle,
    required this.badgeTextStyle,
    required this.labelColorProperty,
    required this.defaultRestColor,
    required this.defaultSelectedColor,
    required this.defaultBadgeFill,
    required this.defaultBadgeInk,
    required this.selected,
    required this.enabled,
    required this.textStyle,
    required this.iconSize,
    required this.inset,
    required this.padding,
    required this.hoverColor,
    required this.hoverRadius,
    required this.pressedScale,
    required this.pressSpring,
    required this.releaseSpring,
    required this.haptic,
    required this.onTap,
  });

  final int index;
  final OrionSpringDriver driver;
  final Widget label;
  final Widget? icon;
  final Widget? badge;
  final String? semanticLabel;
  final String? tooltip;
  final OrionSegmentBadgeStyle? badgeStyle;
  final TextStyle badgeTextStyle;
  final WidgetStateProperty<Color?>? labelColorProperty;
  final Color defaultRestColor;
  final Color defaultSelectedColor;
  final Color defaultBadgeFill;
  final Color defaultBadgeInk;
  final bool selected;
  final bool enabled;
  final TextStyle textStyle;
  final double iconSize;
  final double inset;
  final EdgeInsetsGeometry padding;
  final Color hoverColor;
  final BorderRadius hoverRadius;
  final double pressedScale;
  final OrionSpringSpec pressSpring;
  final OrionSpringSpec releaseSpring;
  final OrionHapticType haptic;
  final VoidCallback? onTap;

  @override
  State<_SegmentButton> createState() => _SegmentButtonState();
}

class _SegmentButtonState extends State<_SegmentButton> {
  bool _hovered = false;

  @override
  void didUpdateWidget(_SegmentButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _hovered) {
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool showHover = _hovered && widget.enabled && !widget.selected;

    final Set<WidgetState> restStates = <WidgetState>{
      if (!widget.enabled) WidgetState.disabled,
      if (showHover) WidgetState.hovered,
    };
    final Set<WidgetState> selectedStates = <WidgetState>{
      WidgetState.selected,
      if (!widget.enabled) WidgetState.disabled,
    };
    final Set<WidgetState> liveStates = widget.selected
        ? selectedStates
        : restStates;

    final Color restColor =
        widget.labelColorProperty?.resolve(restStates) ??
        widget.defaultRestColor;
    final Color selectedColor =
        widget.labelColorProperty?.resolve(selectedStates) ??
        widget.defaultSelectedColor;
    final Color badgeFill =
        widget.badgeStyle?.fill?.resolve(liveStates) ?? widget.defaultBadgeFill;
    final Color badgeInk =
        widget.badgeStyle?.ink?.resolve(liveStates) ?? widget.defaultBadgeInk;

    final double badgeHeight = widget.badgeStyle?.height ?? 18;
    final double badgeMinWidth = widget.badgeStyle?.minWidth ?? 18;
    final EdgeInsetsGeometry badgePadding =
        widget.badgeStyle?.padding ??
        const EdgeInsets.symmetric(horizontal: OrionSpacing.space4);
    final double badgeGap = widget.badgeStyle?.gap ?? OrionSpacing.space4;

    final Widget badgeChild = widget.badge == null
        ? const SizedBox.shrink()
        : Padding(
            padding: EdgeInsetsDirectional.only(start: badgeGap),
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
                  style: widget.badgeTextStyle.copyWith(color: badgeInk),
                  child: widget.badge!,
                ),
              ),
            ),
          );

    final Widget contentRow = Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        if (widget.icon != null) ...<Widget>[
          widget.icon!,
          const SizedBox(width: OrionSpacing.space4),
        ],
        Flexible(child: widget.label),
        // An animated size cannot run at zero duration (it would re-dirty
        // itself mid-layout), so reduced motion swaps the wrapper out entirely
        // and the change lands in one frame.
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
    );

    Widget button = Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      inMutuallyExclusiveGroup: true,
      label: widget.semanticLabel,
      child: MouseRegion(
        onEnter: (_) {
          if (mounted && widget.enabled && !_hovered) {
            setState(() => _hovered = true);
          }
        },
        onExit: (_) {
          if (mounted && _hovered) {
            setState(() => _hovered = false);
          }
        },
        child: OrionPressable(
          onTap: widget.selected ? null : widget.onTap,
          pressedScale: widget.pressedScale,
          springSpec: widget.pressSpring,
          releaseSpringSpec: widget.releaseSpring,
          hapticType: widget.haptic,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              if (showHover)
                Positioned.fill(
                  top: widget.inset,
                  bottom: widget.inset,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: widget.hoverColor,
                        borderRadius: widget.hoverRadius,
                      ),
                    ),
                  ),
                ),
              Padding(
                padding: widget.padding,
                child: Center(
                  widthFactor: 1,
                  child: AnimatedBuilder(
                    animation: widget.driver,
                    child: contentRow,
                    builder: (BuildContext context, Widget? child) {
                      final double proximity =
                          (1.0 - (widget.driver.value - widget.index).abs())
                              .clamp(0.0, 1.0);
                      final Color liveColor = Color.lerp(
                        restColor,
                        selectedColor,
                        proximity,
                      )!;
                      return IconTheme.merge(
                        data: IconThemeData(
                          color: liveColor,
                          size: widget.iconSize,
                        ),
                        child: DefaultTextStyle(
                          style: widget.textStyle.copyWith(color: liveColor),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          child: child!,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      button = Tooltip(message: widget.tooltip!, child: button);
    }

    return button;
  }
}

class _EqualSlotTrack extends MultiChildRenderObjectWidget {
  const _EqualSlotTrack({
    super.key,
    required this.height,
    required this.inset,
    required this.expand,
    required this.textDirection,
    required this.hasPill,
    required super.children,
  });

  final double height;
  final double inset;
  final bool expand;
  final TextDirection textDirection;
  final bool hasPill;

  @override
  _RenderEqualSlotTrack createRenderObject(BuildContext context) {
    return _RenderEqualSlotTrack(
      height: height,
      inset: inset,
      expand: expand,
      textDirection: textDirection,
      hasPill: hasPill,
    );
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEqualSlotTrack renderObject,
  ) {
    renderObject
      ..height = height
      ..inset = inset
      ..expand = expand
      ..textDirection = textDirection
      ..hasPill = hasPill;
  }
}

class _EqualSlotParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderEqualSlotTrack extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _EqualSlotParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _EqualSlotParentData> {
  _RenderEqualSlotTrack({
    required double height,
    required double inset,
    required bool expand,
    required TextDirection textDirection,
    required bool hasPill,
  }) : _height = height,
       _inset = inset,
       _expand = expand,
       _textDirection = textDirection,
       _hasPill = hasPill;

  double _height;
  double get height => _height;
  set height(double value) {
    if (_height != value) {
      _height = value;
      markNeedsLayout();
    }
  }

  double _inset;
  double get inset => _inset;
  set inset(double value) {
    if (_inset != value) {
      _inset = value;
      markNeedsLayout();
    }
  }

  bool _expand;
  bool get expand => _expand;
  set expand(bool value) {
    if (_expand != value) {
      _expand = value;
      markNeedsLayout();
    }
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection != value) {
      _textDirection = value;
      markNeedsLayout();
    }
  }

  bool _hasPill;
  bool get hasPill => _hasPill;
  set hasPill(bool value) {
    if (_hasPill != value) {
      _hasPill = value;
      markNeedsPaint();
    }
  }

  double _slotWidth = 0.0;
  double get slotWidth => _slotWidth;

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _EqualSlotParentData) {
      child.parentData = _EqualSlotParentData();
    }
  }

  @override
  double computeMinIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(height, max: false);
  }

  @override
  double computeMaxIntrinsicWidth(double height) {
    return _computeIntrinsicWidth(height, max: true);
  }

  double _computeIntrinsicWidth(double height, {required bool max}) {
    final int segmentCount = childCount - 1;
    if (segmentCount <= 0) {
      return 0.0;
    }
    double maxChild = _height;
    RenderBox? child = firstChild;
    if (child != null) {
      child = childAfter(child); // skip pill child
    }
    while (child != null) {
      final double w = max
          ? child.getMaxIntrinsicWidth(_height)
          : child.getMinIntrinsicWidth(_height);
      if (w > maxChild) {
        maxChild = w;
      }
      child = childAfter(child);
    }
    return maxChild * segmentCount + _inset * 2;
  }

  @override
  double computeMinIntrinsicHeight(double width) => _height;

  @override
  double computeMaxIntrinsicHeight(double width) => _height;

  @override
  void performLayout() {
    final RenderBox? pillChild = firstChild;
    final int segmentCount = childCount - 1;
    if (pillChild == null || segmentCount <= 0) {
      _slotWidth = 0.0;
      size = constraints.constrain(Size(0.0, _height));
      return;
    }

    assert(
      !_expand || constraints.hasBoundedWidth,
      'OrionSegmentedControl requires a bounded width.',
    );

    final double effectiveInset = math.max(0.0, _inset);
    final double innerHeight = math.max(0.0, _height - effectiveInset * 2);

    double totalWidth;
    if (_expand) {
      totalWidth = constraints.maxWidth;
      _slotWidth = math.max(
        0.0,
        (totalWidth - effectiveInset * 2) / segmentCount,
      );
    } else {
      final double maxAvailableSlot = constraints.hasBoundedWidth
          ? math.max(
              0.0,
              (constraints.maxWidth - effectiveInset * 2) / segmentCount,
            )
          : double.infinity;

      double widest = _height;
      RenderBox? child = childAfter(pillChild);
      while (child != null) {
        final double intrinsic = child.getMaxIntrinsicWidth(_height);
        if (intrinsic > widest) {
          widest = intrinsic;
        }
        child = childAfter(child);
      }

      final double naturalSlot = math.min(maxAvailableSlot, widest);
      totalWidth = constraints.constrainWidth(
        naturalSlot * segmentCount + effectiveInset * 2,
      );
      _slotWidth = math.max(
        0.0,
        (totalWidth - effectiveInset * 2) / segmentCount,
      );
    }

    final BoxConstraints slotConstraints = BoxConstraints.tightFor(
      width: _slotWidth,
      height: _height,
    );

    int segmentIndex = 0;
    RenderBox? child = childAfter(pillChild);
    while (child != null) {
      child.layout(slotConstraints, parentUsesSize: true);
      final int visualIndex = _textDirection == TextDirection.rtl
          ? (segmentCount - 1 - segmentIndex)
          : segmentIndex;
      final _EqualSlotParentData pd = child.parentData! as _EqualSlotParentData;
      pd.offset = Offset(effectiveInset + visualIndex * _slotWidth, 0.0);
      segmentIndex++;
      child = childAfter(child);
    }

    pillChild.layout(
      BoxConstraints.tightFor(width: _slotWidth, height: innerHeight),
      parentUsesSize: true,
    );
    final _EqualSlotParentData pillPd =
        pillChild.parentData! as _EqualSlotParentData;
    final double pillStartX = _textDirection == TextDirection.rtl
        ? effectiveInset + (segmentCount - 1) * _slotWidth
        : effectiveInset;
    pillPd.offset = Offset(pillStartX, effectiveInset);

    size = constraints.constrain(Size(totalWidth, _height));
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? pillChild = firstChild;
    if (pillChild == null) {
      return;
    }
    if (_hasPill) {
      final _EqualSlotParentData pillPd =
          pillChild.parentData! as _EqualSlotParentData;
      context.paintChild(pillChild, pillPd.offset + offset);
    }
    RenderBox? child = childAfter(pillChild);
    while (child != null) {
      final _EqualSlotParentData pd = child.parentData! as _EqualSlotParentData;
      context.paintChild(child, pd.offset + offset);
      child = childAfter(child);
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    final RenderBox? pillChild = firstChild;
    if (pillChild == null) {
      return false;
    }
    RenderBox? child = lastChild;
    while (child != null && !identical(child, pillChild)) {
      final _EqualSlotParentData pd = child.parentData! as _EqualSlotParentData;
      final bool isHit = result.addWithPaintOffset(
        offset: pd.offset,
        position: position,
        hitTest: (BoxHitTestResult result, Offset transformed) {
          return child!.hitTest(result, position: transformed);
        },
      );
      if (isHit) {
        return true;
      }
      child = childBefore(child);
    }
    return false;
  }
}
