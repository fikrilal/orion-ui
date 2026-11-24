import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/switch/orion_switch_presets.dart';
import 'package:orion_ui/src/components/switch/orion_switch_style.dart';
import 'package:orion_ui/src/components/switch/orion_switch_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Key for the painted pill track inside [OrionSwitch].
const Key orionSwitchTrackKey = Key('orion_switch_track');

/// Key for the painted thumb capsule inside [OrionSwitch].
const Key orionSwitchThumbKey = Key('orion_switch_thumb');

/// A tactile pill switch driven by asymmetric springs and direct manipulation.
///
/// The parent owns [value]. Users can tap the switch (or its optional [label] /
/// [subtitle] row), drag or flick the thumb horizontally across the track
/// (RTL-aware, with midpoint detent haptics and velocity handoff), or activate
/// it silently via keyboard (`Enter` or `Space`).
///
/// While held or dragged, the thumb elongates into a true stadium capsule
/// pinned to its active edge so round end-caps and optional [activeIcon] /
/// [inactiveIcon] glyphs stay crisp without oval distortion.
///
/// Look and feel resolve in three layers, each overriding the last:
/// [OrionSwitchPresets] for [size], the ambient [OrionSwitchTheme], and the
/// instance [style] passed here.
class OrionSwitch extends StatefulWidget {
  /// Creates a controlled switch.
  const OrionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.size = OrionSwitchSize.medium,
    this.label,
    this.subtitle,
    this.controlAffinity = OrionSwitchControlAffinity.trailing,
    this.activeIcon,
    this.inactiveIcon,
    this.tooltip,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Whether the switch is toggled on.
  final bool value;

  /// Called with the toggled value on tap, drag commit, or keyboard activation.
  /// Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Size step controlling track, thumb, inset, and thumb icon dimensions.
  final OrionSwitchSize size;

  /// Optional clickable label displayed alongside the switch.
  final String? label;

  /// Optional supporting description displayed beneath [label].
  final String? subtitle;

  /// Placement of the switch relative to [label] and [subtitle].
  /// Defaults to [OrionSwitchControlAffinity.trailing].
  final OrionSwitchControlAffinity controlAffinity;

  /// Optional widget (typically an [Icon]) displayed inside the thumb when on.
  final Widget? activeIcon;

  /// Optional widget (typically an [Icon]) displayed inside the thumb when off.
  final Widget? inactiveIcon;

  /// Optional tooltip shown on long-press or desktop hover.
  final String? tooltip;

  /// Instance-level overrides, merged over [OrionSwitchPresets] and the ambient
  /// [OrionSwitchTheme]. Only the fields set here change.
  final OrionSwitchStyle? style;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the switch requests focus on first build.
  final bool autofocus;

  /// Spoken name. Defaults to [label] when provided; the toggled state is
  /// exposed separately.
  final String? semanticLabel;

  @override
  State<OrionSwitch> createState() => _OrionSwitchState();
}

class _OrionSwitchState extends State<OrionSwitch>
    with TickerProviderStateMixin {
  static const double _flickVelocityThreshold = 180.0;

  late final OrionSpringDriver _driver;
  late final OrionSpringDriver _press;

  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;
  bool _isDragging = false;
  double _dragValue = 0.0;
  bool _crossedMidpointDuringDrag = false;
  bool? _hapticTargetDuringDrag;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: OrionSwitchPresets.defaultSlideSpring,
    );
    _press = OrionSpringDriver(
      vsync: this,
      springSpec: OrionSwitchPresets.defaultPressSpring,
      initialValue: 0.0,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
    _press.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_driver.reducedMotion) {
          return;
        }
        _driver.jumpTo(_target);
        _press.jumpTo(_pressed ? 1.0 : 0.0);
      });
    }
  }

  @override
  void didUpdateWidget(OrionSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();

    if (widget.onChanged == null) {
      _isDragging = false;
      _hapticTargetDuringDrag = null;
      if (_pressed || _hovered || _focused) {
        _pressed = false;
        _hovered = false;
        _focused = false;
      }
      if (_press.value != 0.0 || _press.target != 0.0) {
        _press.retarget(0.0);
      }
      if (_driver.value != _target || _driver.target != _target) {
        _sync();
      }
      return;
    }

    if (widget.value != oldWidget.value && !_isDragging) {
      if (_driver.target != _target) {
        _sync();
      }
    }
  }

  @override
  void dispose() {
    _driver.dispose();
    _press.dispose();
    super.dispose();
  }

  double get _target => widget.value ? 1.0 : 0.0;

  void _syncMotion() {
    final OrionSwitchStyle style = _resolve(Theme.of(context));
    _driver.springSpec =
        style.slideSpring ?? OrionSwitchPresets.defaultSlideSpring;
    _press.springSpec =
        style.pressSpring ?? OrionSwitchPresets.defaultPressSpring;
  }

  void _sync() {
    _driver.retarget(_target);
  }

  void _setPressed(bool pressed) {
    if (_pressed != pressed) {
      setState(() => _pressed = pressed);
    }
    _press.retarget(pressed ? 1.0 : 0.0);
  }

  OrionSwitchStyle _resolve(ThemeData theme) {
    final OrionSwitchTheme switchTheme =
        theme.extension<OrionSwitchTheme>() ?? OrionSwitchTheme.fallback;
    return OrionSwitchPresets.resolve(
      size: widget.size,
      scheme: theme.colorScheme,
    ).merge(switchTheme.defaultStyle).merge(widget.style);
  }

  void _triggerHaptic() {
    final OrionHapticType type =
        _resolve(Theme.of(context)).hapticType ??
        OrionTheme.of(context).selectionHaptic;
    if (type != OrionHapticType.none) {
      OrionHaptics.trigger(type);
    }
  }

  void _flip({required bool haptic}) {
    if (widget.onChanged == null) {
      return;
    }
    if (haptic) {
      _triggerHaptic();
    }
    widget.onChanged!(!widget.value);
  }

  void _handleDragStart(DragStartDetails details) {
    if (widget.onChanged == null) return;
    _isDragging = true;
    _dragValue = _driver.value.clamp(0.0, 1.0);
    _crossedMidpointDuringDrag = _dragValue >= 0.5;
    _hapticTargetDuringDrag = null;
    _setPressed(true);
  }

  void _handleDragUpdate(
    DragUpdateDetails details, {
    required double travel,
    required double direction,
  }) {
    if (!_isDragging || widget.onChanged == null) return;
    final double effectiveTravel = math.max(1.0, travel);
    final double delta =
        (details.primaryDelta ?? 0.0) * direction / effectiveTravel;
    _dragValue = (_dragValue + delta).clamp(0.0, 1.0);
    _driver.jumpTo(_dragValue);

    final bool pastMidpoint = _dragValue >= 0.5;
    if (pastMidpoint != _crossedMidpointDuringDrag) {
      _crossedMidpointDuringDrag = pastMidpoint;
      _hapticTargetDuringDrag = pastMidpoint;
      _triggerHaptic();
    }
  }

  void _handleDragEnd(
    DragEndDetails details, {
    required double travel,
    required double direction,
  }) {
    if (!_isDragging) return;
    _isDragging = false;
    _setPressed(false);

    if (widget.onChanged == null) {
      _driver.retarget(_target);
      return;
    }

    final double effectiveTravel = math.max(1.0, travel);
    final double primaryVelocity = (details.primaryVelocity ?? 0.0) * direction;
    final bool targetBool = primaryVelocity.abs() >= _flickVelocityThreshold
        ? primaryVelocity > 0
        : _dragValue >= 0.5;
    final double normalizedVelocity = (primaryVelocity / effectiveTravel).clamp(
      -20.0,
      20.0,
    );

    _driver.retarget(targetBool ? 1.0 : 0.0, velocity: normalizedVelocity);

    if (targetBool != widget.value) {
      if (_hapticTargetDuringDrag != targetBool) {
        _triggerHaptic();
      }
      widget.onChanged!(targetBool);
      // If the host rejects or defers the change, spring cleanly back to the
      // authoritative widget.value rather than stranding the thumb.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !_isDragging && _driver.target != _target) {
          _driver.retarget(_target);
        }
      });
    }
    _hapticTargetDuringDrag = null;
  }

  void _handleDragCancel() {
    if (!_isDragging) return;
    _isDragging = false;
    _hapticTargetDuringDrag = null;
    _setPressed(false);
    _driver.retarget(_target);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionSwitchStyle style = _resolve(theme);
    final bool enabled = widget.onChanged != null;
    final bool isDark = scheme.brightness == Brightness.dark;

    final double trackWidth = math.max(1.0, style.trackWidth ?? 52.0);
    final double trackHeight = math.max(
      1.0,
      style.trackHeight ?? OrionSizing.controlHeightSmall,
    );
    final double maxInset = math.max(
      0.0,
      (math.min(trackWidth, trackHeight) - 1.0) / 2.0,
    );
    final double inset = (style.inset ?? OrionSpacing.space4).clamp(
      0.0,
      maxInset,
    );
    final double thumbSize = math.max(1.0, trackHeight - inset * 2.0);
    final double travel = math.max(0.0, trackWidth - thumbSize - inset * 2.0);
    final double hitWidth = math.max(OrionSizing.minHitTarget, trackWidth);
    final double hitHeight = math.max(OrionSizing.minHitTarget, trackHeight);

    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final double direction = Directionality.of(context) == TextDirection.rtl
        ? -1.0
        : 1.0;

    final Set<WidgetState> statesOff = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (_hovered && enabled) WidgetState.hovered,
      if (_focused && enabled) WidgetState.focused,
      if (_pressed && enabled) WidgetState.pressed,
    };
    final Set<WidgetState> statesOn = <WidgetState>{
      WidgetState.selected,
      if (!enabled) WidgetState.disabled,
      if (_hovered && enabled) WidgetState.hovered,
      if (_focused && enabled) WidgetState.focused,
      if (_pressed && enabled) WidgetState.pressed,
    };

    final Color trackOff =
        style.trackColor?.resolve(statesOff) ?? scheme.outline;
    final Color trackOn = style.trackColor?.resolve(statesOn) ?? scheme.primary;
    final Color thumbOff =
        style.thumbColor?.resolve(statesOff) ??
        (isDark ? scheme.onSurface : scheme.surface);
    final Color thumbOn =
        style.thumbColor?.resolve(statesOn) ?? scheme.onPrimary;
    final Color trackBorderOff =
        style.trackBorderColor?.resolve(statesOff) ?? Colors.transparent;
    final Color trackBorderOn =
        style.trackBorderColor?.resolve(statesOn) ?? Colors.transparent;
    final double trackBorderWidth = math.max(0.0, style.trackBorderWidth ?? 0);
    final List<BoxShadow>? thumbShadow = enabled
        ? (style.thumbShadow ?? OrionSwitchPresets.defaultThumbShadow)
        : null;
    final Color focusRing =
        style.focusRingColor ?? scheme.primary.withValues(alpha: 0.45);

    final double stretch = math.max(0.0, style.pressStretch ?? 0.18);
    final double squish = (style.pressSquish ?? 0.12).clamp(0.0, 0.5);
    final double iconSize = math.max(1.0, style.iconSize ?? 14.0);
    final Color activeIconColor = enabled
        ? (style.activeIconColor ?? scheme.primary)
        : scheme.onSurface.withValues(alpha: 0.38);
    final Color inactiveIconColor = enabled
        ? (style.inactiveIconColor ??
              (isDark ? scheme.surface : scheme.onSurfaceVariant))
        : scheme.onSurface.withValues(alpha: 0.38);
    final bool hasThumbIcons =
        widget.activeIcon != null || widget.inactiveIcon != null;

    final Widget switchControl = Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: enabled
          ? (PointerDownEvent event) {
              if (event.kind != PointerDeviceKind.mouse ||
                  event.buttons == kPrimaryButton) {
                _setPressed(true);
              }
            }
          : null,
      onPointerUp: enabled
          ? (PointerUpEvent _) {
              if (!_isDragging) _setPressed(false);
            }
          : null,
      onPointerCancel: enabled
          ? (PointerCancelEvent _) {
              if (!_isDragging) _setPressed(false);
            }
          : null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _flip(haptic: true) : null,
        onTapCancel: enabled
            ? () {
                if (!_isDragging) _setPressed(false);
              }
            : null,
        onHorizontalDragStart: enabled ? _handleDragStart : null,
        onHorizontalDragUpdate: enabled
            ? (DragUpdateDetails details) => _handleDragUpdate(
                details,
                travel: travel,
                direction: direction,
              )
            : null,
        onHorizontalDragEnd: enabled
            ? (DragEndDetails details) =>
                  _handleDragEnd(details, travel: travel, direction: direction)
            : null,
        onHorizontalDragCancel: enabled ? _handleDragCancel : null,
        child: SizedBox(
          width: hitWidth,
          height: hitHeight,
          child: Center(
            child: SizedBox(
              width: trackWidth,
              height: trackHeight,
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: <Widget>[
                  AnimatedBuilder(
                    animation: _driver,
                    builder: (BuildContext context, Widget? child) {
                      final double progress = _driver.value.clamp(0.0, 1.0);
                      final Color? liveBorder = Color.lerp(
                        trackBorderOff,
                        trackBorderOn,
                        progress,
                      );
                      final bool showBorder =
                          trackBorderWidth > 0 &&
                          liveBorder != null &&
                          liveBorder.a > 0;
                      return DecoratedBox(
                        key: orionSwitchTrackKey,
                        decoration: BoxDecoration(
                          color: Color.lerp(trackOff, trackOn, progress),
                          borderRadius: radius,
                          border: showBorder
                              ? Border.all(
                                  color: liveBorder,
                                  width: trackBorderWidth,
                                )
                              : null,
                        ),
                      );
                    },
                  ),
                  if (_focused && enabled)
                    IgnorePointer(
                      child: DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(
                            color: focusRing,
                            width: 2.5,
                            strokeAlign: BorderSide.strokeAlignOutside,
                          ),
                        ),
                      ),
                    ),
                  AnimatedBuilder(
                    animation: Listenable.merge(<Listenable>[_driver, _press]),
                    builder: (BuildContext context, Widget? child) {
                      final double progress = _driver.value.clamp(0.0, 1.0);
                      final double press = _press.value.clamp(0.0, 1.0);
                      final double rawExtraWidth = thumbSize * stretch * press;
                      final double extraWidth = math.min(rawExtraWidth, travel);
                      final double currentWidth = thumbSize + extraWidth;
                      final double currentHeight = math.max(
                        1.0,
                        thumbSize * (1.0 - squish * press),
                      );
                      // Pin the elongating capsule to whichever edge it rests on
                      // (inset when off, trackWidth - inset when on) and centre it
                      // cleanly across mid-track drag positions.
                      final double logicalStart =
                          inset + progress * (travel - extraWidth);
                      final double topOffset =
                          (trackHeight - currentHeight) / 2.0;

                      Widget? thumbChild;
                      if (hasThumbIcons) {
                        final double activeOpacity = progress;
                        final double inactiveOpacity = 1.0 - progress;
                        thumbChild = Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: <Widget>[
                              if (widget.inactiveIcon != null &&
                                  inactiveOpacity > 0.001)
                                Opacity(
                                  opacity: inactiveOpacity,
                                  child: IconTheme.merge(
                                    data: IconThemeData(
                                      color: inactiveIconColor,
                                      size: iconSize,
                                    ),
                                    child: widget.inactiveIcon!,
                                  ),
                                ),
                              if (widget.activeIcon != null &&
                                  activeOpacity > 0.001)
                                Opacity(
                                  opacity: activeOpacity,
                                  child: IconTheme.merge(
                                    data: IconThemeData(
                                      color: activeIconColor,
                                      size: iconSize,
                                    ),
                                    child: widget.activeIcon!,
                                  ),
                                ),
                            ],
                          ),
                        );
                      }

                      return Stack(
                        clipBehavior: Clip.none,
                        children: <Widget>[
                          PositionedDirectional(
                            start: logicalStart,
                            top: topOffset,
                            width: currentWidth,
                            height: currentHeight,
                            child: DecoratedBox(
                              key: orionSwitchThumbKey,
                              decoration: BoxDecoration(
                                color: Color.lerp(thumbOff, thumbOn, progress),
                                borderRadius: BorderRadius.circular(
                                  currentHeight / 2.0,
                                ),
                                boxShadow:
                                    thumbShadow != null &&
                                        thumbShadow.isNotEmpty
                                    ? thumbShadow
                                    : null,
                              ),
                              child: thumbChild,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    final bool hasLabel = widget.label != null || widget.subtitle != null;
    Widget interactiveChild;
    if (!hasLabel) {
      interactiveChild = switchControl;
    } else {
      final Color labelColor = !enabled
          ? scheme.onSurface.withValues(alpha: 0.38)
          : scheme.onSurface;
      final Color subtitleColor = !enabled
          ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
          : scheme.onSurfaceVariant;
      final double labelTopPadding = math.max(0.0, (hitHeight - 24.0) / 2.0);

      final Widget paddedLabelColumn = Padding(
        padding: widget.subtitle != null
            ? EdgeInsets.only(top: labelTopPadding)
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
      );

      final Widget interactiveLabelColumn = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _flip(haptic: true) : null,
        onTapDown: enabled ? (TapDownDetails _) => _setPressed(true) : null,
        onTapUp: enabled ? (TapUpDetails _) => _setPressed(false) : null,
        onTapCancel: enabled ? () => _setPressed(false) : null,
        child: paddedLabelColumn,
      );

      final Widget row =
          widget.controlAffinity == OrionSwitchControlAffinity.leading
          ? Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: widget.subtitle != null
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: <Widget>[
                switchControl,
                const SizedBox(width: OrionSpacing.space12),
                Flexible(child: interactiveLabelColumn),
              ],
            )
          : LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                final bool stretchRow = constraints.hasBoundedWidth;
                return Row(
                  mainAxisSize: stretchRow
                      ? MainAxisSize.max
                      : MainAxisSize.min,
                  mainAxisAlignment: stretchRow
                      ? MainAxisAlignment.spaceBetween
                      : MainAxisAlignment.start,
                  crossAxisAlignment: widget.subtitle != null
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: <Widget>[
                    if (stretchRow)
                      Expanded(child: interactiveLabelColumn)
                    else
                      Flexible(child: interactiveLabelColumn),
                    const SizedBox(width: OrionSpacing.space12),
                    switchControl,
                  ],
                );
              },
            );

      interactiveChild = GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => _flip(haptic: true) : null,
        child: row,
      );
    }

    if (widget.tooltip != null && widget.tooltip!.isNotEmpty) {
      interactiveChild = Tooltip(
        message: widget.tooltip!,
        child: interactiveChild,
      );
    }

    return Semantics(
      container: true,
      toggled: widget.value,
      enabled: enabled,
      label: widget.semanticLabel ?? widget.label,
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
                _flip(haptic: false);
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
