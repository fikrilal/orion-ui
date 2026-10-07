import 'package:flutter/material.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// A thumb that slides between the two ends of a pill track.
///
/// The parent owns [value]. The switch does not drag.
class OrionSwitch extends StatefulWidget {
  /// Creates a controlled switch.
  const OrionSwitch({
    super.key,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.semanticLabel,
  });

  /// Whether the thumb rests at the end of the track.
  final bool value;

  /// Called with the opposite of [value]. Null disables the switch.
  final ValueChanged<bool>? onChanged;

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
  static const double _trackWidth = 52;
  static const double _trackHeight = OrionSizing.controlHeightSmall;
  static const double _inset = OrionSpacing.space4;
  static const double _thumbSize = _trackHeight - _inset * 2;
  static const double _travel = _trackWidth - _thumbSize - _inset * 2;

  late final OrionSpringDriver _driver;

  /// Compression of a held thumb. The values come from the reference switches: the
  /// thumb widens and squashes under a finger, which is what the platform does and
  /// what ours did not do at all.
  static const double _pressStretch = 0.18;
  static const double _pressSquish = 0.12;

  /// Drives the thumb's deformation while it is held, on the press spring.
  late final OrionSpringDriver _press;
  bool _reduceMotion = false;
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
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
    // The deformation is motion too. Without this the thumb animates up to 1.18 on a
    // device that asked for no animation at all.
    _press.reducedMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reduceMotion) {
          return;
        }
        _driver.jumpTo(_target);
      });
    }
  }

  @override
  void didUpdateWidget(OrionSwitch oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  /// Compresses or releases the thumb. Reduced motion lands it in the same frame.
  void _pressTo(double value) {
    if (_press.reducedMotion) {
      _press.jumpTo(value);
    } else {
      _press.retarget(value);
    }
  }

  void _sync() {
    if (_reduceMotion) {
      _driver.jumpTo(_target);
    } else {
      _driver.retarget(_target);
    }
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
      OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
    }
    widget.onChanged!(!widget.value);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool enabled = widget.onChanged != null;
    final BorderRadius radius = BorderRadius.circular(OrionRadii.radiusPill);
    final double direction = Directionality.of(context) == TextDirection.rtl
        ? -1
        : 1;
    final Color trackOff = enabled
        ? scheme.outline
        : scheme.onSurface.withValues(alpha: 0.12);
    final Color trackOn = enabled
        ? scheme.primary
        : scheme.primary.withValues(alpha: 0.38);
    final Color thumbOff = scheme.onSurface.withValues(
      alpha: enabled ? 1 : 0.38,
    );
    final Color thumbOn = enabled
        ? scheme.onPrimary
        : scheme.onSurface.withValues(alpha: 0.38);

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
            width: _trackWidth,
            height: OrionSizing.minHitTarget,
            child: Center(
              child: SizedBox(
                width: _trackWidth,
                height: _trackHeight,
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
                          border: Border.all(color: scheme.onSurface, width: 2),
                        ),
                      ),
                    PositionedDirectional(
                      start: _inset,
                      top: _inset,
                      width: _thumbSize,
                      height: _thumbSize,
                      child: AnimatedBuilder(
                        animation: Listenable.merge(<Listenable>[
                          _driver,
                          _press,
                        ]),
                        builder: (BuildContext context, Widget? child) {
                          final double progress = _driver.value.clamp(0.0, 1.0);
                          final double press = _press.value.clamp(0.0, 1.0);
                          final double scaleX = 1 + _pressStretch * press;
                          final double scaleY = 1 - _pressSquish * press;
                          // A thumb that only scaled would look like it drifted toward
                          // the middle: widen it and shift it back by half the growth,
                          // towards whichever edge it is resting on.
                          final double overflow =
                              (_thumbSize * (scaleX - 1)) / 2;
                          final double anchor = 1 - 2 * progress;
                          // One matrix, composed around the thumb's centre: translate
                          // to the travel position, then deform in place.
                          final Matrix4 matrix =
                              Matrix4.diagonal3Values(scaleX, scaleY, 1)
                                ..setTranslationRaw(
                                  direction *
                                      (progress * _travel + anchor * overflow),
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
