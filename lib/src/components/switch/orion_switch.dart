import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/switch/orion_switch_style.dart';
import 'package:orion_ui/src/components/switch/orion_switch_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// A thumb that slides between the two ends of a pill track.
///
/// The parent owns [value]. The switch does not drag.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionSwitchStyle.defaults], the ambient [OrionSwitchTheme], and
/// the [style] passed here. Anything an override does not name falls through.
class OrionSwitch extends StatefulWidget {
  /// Creates a controlled switch.
  const OrionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.style,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Whether the thumb rests at the end of the track.
  final bool value;

  /// Called with the opposite of [value]. Null disables the switch.
  final ValueChanged<bool>? onChanged;

  /// Instance-level overrides, merged over the defaults and the ambient
  /// [OrionSwitchTheme]. Only the fields set here change.
  final OrionSwitchStyle? style;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the switch requests focus on first build.
  final bool autofocus;

  /// Spoken name. The toggled state is exposed separately.
  final String? semanticLabel;

  @override
  State<OrionSwitch> createState() => _OrionSwitchState();
}

class _OrionSwitchState extends State<OrionSwitch>
    with TickerProviderStateMixin {
  late final OrionSpringDriver _driver;

  /// Drives the thumb's deformation while it is held, on the press spring.
  late final OrionSpringDriver _press;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: OrionSpringSpec.gentle,
    );
    _press = OrionSpringDriver(
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
    // The deformation is motion too. Without this the thumb animates up to
    // 1.18 on a device that asked for no animation at all.
    _driver.reducedMotion = reduce;
    _press.reducedMotion = reduce;
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
  void didUpdateWidget(OrionSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (widget.value != oldWidget.value) {
      _sync();
    }
  }

  @override
  void dispose() {
    _driver.dispose();
    _press.dispose();
    super.dispose();
  }

  double get _target => widget.value ? 1 : 0;

  void _syncMotion() {
    final OrionSwitchStyle style = _resolve(Theme.of(context));
    _driver.springSpec = style.slideSpring ?? OrionSpringSpec.gentle;
    _press.springSpec = style.pressSpring ?? OrionSpringSpec.snappy;
  }

  /// The drivers own reduced motion: a retarget settles in the same frame when
  /// the platform asked for no animation.
  void _sync() {
    _driver.retarget(_target);
  }

  /// Compresses or releases the thumb.
  void _pressTo(double value) {
    _press.retarget(value);
  }

  OrionSwitchStyle _resolve(ThemeData theme) {
    final OrionSwitchTheme switchTheme =
        theme.extension<OrionSwitchTheme>() ?? OrionSwitchTheme.fallback;
    return OrionSwitchStyle.defaults(
      scheme: theme.colorScheme,
    ).merge(switchTheme.defaultStyle).merge(widget.style);
  }

  void _flip({required bool haptic}) {
    if (widget.onChanged == null) {
      return;
    }
    if (haptic) {
      // A deliberate divergence: the three reference switches fire no haptic at all,
      // and iOS's own switch is silent. We tick because this kit treats the flip as the
      // canonical selection cue - the theme documents selectionHaptic as "a switch
      // flipping" - and a silent toggle in a tactile kit reads as an oversight. The
      // keyboard path stays silent, since a key press is already felt.
      final OrionHapticType type =
          _resolve(Theme.of(context)).hapticType ??
          OrionTheme.of(context).selectionHaptic;
      if (type != OrionHapticType.none) {
        OrionHaptics.trigger(type);
      }
    }
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionSwitchStyle style = _resolve(theme);
    final bool enabled = widget.onChanged != null;
    final double trackWidth = style.trackWidth ?? 52;
    final double trackHeight =
        style.trackHeight ?? OrionSizing.controlHeightSmall;
    final double inset = style.inset ?? OrionSpacing.space4;
    final double thumbSize = trackHeight - inset * 2;
    final double travel = trackWidth - thumbSize - inset * 2;
    final BorderRadius radius =
        style.radius ?? BorderRadius.circular(OrionRadii.radiusPill);
    final double direction = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    final Set<WidgetState> statesOff = <WidgetState>{
      if (!enabled) WidgetState.disabled,
    };
    final Set<WidgetState> statesOn = <WidgetState>{
      WidgetState.selected,
      if (!enabled) WidgetState.disabled,
    };
    final Color trackOff =
        style.trackColor?.resolve(statesOff) ?? scheme.outline;
    final Color trackOn = style.trackColor?.resolve(statesOn) ?? scheme.primary;
    final Color thumbOff =
        style.thumbColor?.resolve(statesOff) ?? scheme.onSurface;
    final Color thumbOn =
        style.thumbColor?.resolve(statesOn) ?? scheme.onPrimary;
    final Color focusRing = style.focusRingColor ?? scheme.onSurface;

    /// Compression of a held thumb. The defaults come from the reference
    /// switches: the thumb widens and squashes under a finger, which is what
    /// the platform does and what ours did not do at all.
    final double stretch = style.pressStretch ?? 0.18;
    final double squish = style.pressSquish ?? 0.12;

    return Semantics(
      container: true,
      toggled: widget.value,
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
              _flip(haptic: false);
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: enabled ? () => _flip(haptic: true) : null,
          onTapDown: enabled ? (TapDownDetails _) => _pressTo(1) : null,
          onTapUp: enabled ? (TapUpDetails _) => _pressTo(0) : null,
          onTapCancel: enabled ? () => _pressTo(0) : null,
          child: SizedBox(
            width: trackWidth,
            height: math.max(OrionSizing.minHitTarget, trackHeight),
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
                        return DecoratedBox(
                          decoration: BoxDecoration(
                            color: Color.lerp(
                              trackOff,
                              trackOn,
                              _driver.value.clamp(0.0, 1.0),
                            ),
                            borderRadius: radius,
                          ),
                        );
                      },
                    ),
                    if (_focused && enabled)
                      DecoratedBox(
                        position: DecorationPosition.foreground,
                        decoration: BoxDecoration(
                          borderRadius: radius,
                          border: Border.all(color: focusRing, width: 2),
                        ),
                      ),
                    PositionedDirectional(
                      start: inset,
                      top: inset,
                      width: thumbSize,
                      height: thumbSize,
                      child: AnimatedBuilder(
                        animation: Listenable.merge(<Listenable>[
                          _driver,
                          _press,
                        ]),
                        builder: (BuildContext context, Widget? child) {
                          final double progress = _driver.value.clamp(0.0, 1.0);
                          final double press = _press.value.clamp(0.0, 1.0);
                          final double scaleX = 1 + stretch * press;
                          final double scaleY = 1 - squish * press;
                          // A thumb that only scaled would look like it drifted toward
                          // the middle: widen it and shift it back by half the growth,
                          // towards whichever edge it is resting on.
                          final double overflow =
                              (thumbSize * (scaleX - 1)) / 2;
                          final double anchor = 1 - 2 * progress;
                          // One matrix, composed around the thumb's centre: translate
                          // to the travel position, then deform in place.
                          final Matrix4 matrix =
                              Matrix4.diagonal3Values(scaleX, scaleY, 1)
                                ..setTranslationRaw(
                                  direction *
                                      (progress * travel + anchor * overflow),
                                  0,
                                  0,
                                );
                          return Transform(
                            transform: matrix,
                            alignment: Alignment.center,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color.lerp(thumbOff, thumbOn, progress),
                                shape: BoxShape.circle,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
