import 'dart:math' as math;
import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button.dart';
import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/components/toast/orion_toast_data.dart';
import 'package:orion_ui/src/components/toast/orion_toast_presets.dart';
import 'package:orion_ui/src/components/toast/orion_toast_style.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Key for the painted surface face inside [OrionToastCard].
const Key orionToastCardFaceKey = Key('orion_toast_card_face');

/// Key for the close button inside [OrionToastCard].
const Key orionToastCloseButtonKey = Key('orion_toast_close_button');

/// Key for the optional countdown progress bar inside [OrionToastCard].
const Key orionToastProgressBarKey = Key('orion_toast_progress_bar');

enum _ExitMode { none, horizontal, vertical, calm }

/// Signature for dismissing a toast card with the reason it left.
typedef OrionToastDismissCallback =
    void Function(String id, OrionToastDismissReason reason);

/// Interactive toast notification card with dual-axis swipe physics,
/// smooth status morphing, and calm anchor-edge exit animations.
class OrionToastCard extends StatefulWidget {
  const OrionToastCard({
    super.key,
    required this.data,
    required this.onDismiss,
    this.isTop = false,
    this.showCloseButton = true,
    this.showProgressBar = false,
    this.richColors = false,
    this.paused = false,
    this.departing = false,
    this.onExited,
    this.onCardTap,
    this.onRequestExpand,
    this.style,
  });

  /// The toast payload.
  final OrionToastData data;

  /// Invoked when the user dismisses the toast via swipe, close button, or
  /// action button once the exit motion completes.
  final OrionToastDismissCallback onDismiss;

  /// Whether the enclosing stack anchors to the top edge (`true`) or bottom
  /// edge (`false`). Controls vertical swipe-to-dismiss and calm exit direction.
  final bool isTop;

  /// Default close button visibility when [OrionToastData.showCloseButton] is
  /// null. Always hidden when [OrionToastData.dismissible] is false.
  final bool showCloseButton;

  /// Default countdown bar visibility when [OrionToastData.showProgressBar] is
  /// null.
  final bool showProgressBar;

  /// Default semantic tinting when [OrionToastStyle.richColors] is null.
  final bool richColors;

  /// Whether auto-dismiss timers are currently paused (pauses the progress bar).
  final bool paused;

  /// Whether the host has already removed this toast from its queue and is
  /// waiting for the exit motion to complete.
  final bool departing;

  /// Invoked once a [departing] card finishes leaving the screen.
  final VoidCallback? onExited;

  /// Optional tap handler invoked when tapping the card body without dragging.
  final VoidCallback? onCardTap;

  /// Optional callback invoked when the user pulls away from the anchor edge
  /// on a collapsed multi-toast stack to expand it.
  final VoidCallback? onRequestExpand;

  /// Host-level style overrides (merged below [OrionToastData.style]).
  final OrionToastStyle? style;

  @override
  State<OrionToastCard> createState() => _OrionToastCardState();
}

class _OrionToastCardState extends State<OrionToastCard>
    with TickerProviderStateMixin {
  static const double _horizontalDismissDistance = 72.0;
  static const double _horizontalDismissVelocity = 450.0;
  static const double _horizontalFadeDistance = 280.0;

  static const double _verticalDismissDistance = 36.0;
  static const double _verticalDismissVelocity = 350.0;
  static const double _verticalFadeDistance = 120.0;
  static const double _pullExpandThreshold = 22.0;
  static const double _calmExitTravel = 20.0;

  late final OrionSpringDriver _xDriver;
  late final OrionSpringDriver _yDriver;
  late final OrionSpringDriver _exitDriver;
  AnimationController? _progressController;

  OrionHapticType _impactHaptic = OrionHapticType.lightImpact;
  _ExitMode _exitMode = _ExitMode.none;
  OrionToastDismissReason _pendingReason = OrionToastDismissReason.programmatic;
  bool _delivered = false;
  bool _draggingHorizontal = false;
  bool _draggingVertical = false;
  double _dragOriginX = 0.0;
  double _dragOriginY = 0.0;
  double _accumDx = 0.0;
  double _accumDy = 0.0;
  Duration? _dragStartTime;
  Duration? _lastDragTime;
  double _screenWidth = 400.0;
  double _cardWidth = 340.0;
  double _cardHeight = 64.0;

  bool get _exiting => _exitMode != _ExitMode.none;

  bool get _effectiveShowProgressBar {
    final bool wanted = widget.data.showProgressBar ?? widget.showProgressBar;
    final Duration? d = widget.data.duration;
    return wanted && d != null && d > Duration.zero;
  }

  @override
  void initState() {
    super.initState();
    _xDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionToastPresets.defaultSwipeSpring,
    )..addStatusListener(_onHorizontalStatus);
    _yDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionToastPresets.defaultSwipeSpring,
    )..addStatusListener(_onVerticalStatus);
    _exitDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionToastPresets.defaultMountSpring,
    )..addStatusListener(_onCalmExitStatus);

    _syncProgressController(reset: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData theme = Theme.of(context);
    final OrionToastStyle style = _resolveStyle(theme);
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    _xDriver
      ..reducedMotion = reduced
      ..springSpec = style.swipeSpring ?? OrionToastPresets.defaultSwipeSpring;
    _yDriver
      ..reducedMotion = reduced
      ..springSpec = style.swipeSpring ?? OrionToastPresets.defaultSwipeSpring;
    _exitDriver
      ..reducedMotion = reduced
      ..springSpec = style.mountSpring ?? OrionToastPresets.defaultMountSpring;

    _impactHaptic = OrionTheme.of(context).impactHaptic;
    _screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 400.0;
  }

  @override
  void didUpdateWidget(OrionToastCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final bool payloadReset =
        widget.data.duration != oldWidget.data.duration ||
        widget.data.status != oldWidget.data.status ||
        widget.data.title != oldWidget.data.title ||
        widget.showProgressBar != oldWidget.showProgressBar ||
        widget.data.showProgressBar != oldWidget.data.showProgressBar;
    if (payloadReset || widget.paused != oldWidget.paused) {
      _syncProgressController(reset: payloadReset);
    }

    if (widget.departing == oldWidget.departing) {
      return;
    }
    if (!widget.departing) {
      if (_exiting) {
        _exitMode = _ExitMode.none;
        _xDriver.retarget(0.0, velocity: _xDriver.velocity);
        _yDriver.retarget(0.0, velocity: _yDriver.velocity);
        _exitDriver.retarget(0.0);
      }
      return;
    }
    if (_exiting) {
      return;
    }
    if (_delivered) {
      _reportExited();
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.departing && !_exiting) {
        _exitCalm(OrionToastDismissReason.timeout);
      }
    });
  }

  @override
  void dispose() {
    _progressController?.dispose();
    _xDriver
      ..removeStatusListener(_onHorizontalStatus)
      ..dispose();
    _yDriver
      ..removeStatusListener(_onVerticalStatus)
      ..dispose();
    _exitDriver
      ..removeStatusListener(_onCalmExitStatus)
      ..dispose();
    super.dispose();
  }

  void _syncProgressController({required bool reset}) {
    if (!_effectiveShowProgressBar || widget.departing) {
      _progressController?.stop();
      if (!_effectiveShowProgressBar) {
        _progressController?.dispose();
        _progressController = null;
      }
      return;
    }
    final Duration duration = widget.data.duration!;
    final AnimationController controller = _progressController ??=
        AnimationController(vsync: this, value: 1.0, duration: duration);
    if (reset) {
      controller
        ..duration = duration
        ..value = 1.0;
    }
    if (widget.paused) {
      controller.stop();
    } else if (!controller.isAnimating && controller.value > 0.0) {
      controller.reverse(from: controller.value);
    }
  }

  void _onHorizontalStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _exitMode == _ExitMode.horizontal) {
      _finishExit();
    }
  }

  void _onVerticalStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _exitMode == _ExitMode.vertical) {
      _finishExit();
    }
  }

  void _onCalmExitStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && _exitMode == _ExitMode.calm) {
      _finishExit();
    }
  }

  void _finishExit() {
    _exitMode = _ExitMode.none;
    if (widget.departing) {
      _reportExited();
      return;
    }
    _delivered = true;
    widget.onDismiss(widget.data.id, _pendingReason);
  }

  void _reportExited() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onExited?.call();
      }
    });
  }

  OrionToastStyle _resolveStyle(ThemeData theme) {
    return OrionToastPresets.resolveFor(
      theme,
      status: widget.data.status,
      richColors: widget.richColors,
      stackStyle: widget.style,
      instanceStyle: widget.data.style,
    );
  }

  void _handleDragDown(DragDownDetails details) {
    if (_exiting || widget.departing) return;
    // Catch an in-flight snap-back smoothly without jumping its position.
    if (_xDriver.isAnimating || _yDriver.isAnimating) {
      _xDriver.stop();
      _yDriver.stop();
    }
  }

  void _handleHorizontalStart(DragStartDetails details) {
    if (_exiting || widget.departing) return;
    _draggingHorizontal = true;
    _dragOriginX = _xDriver.value;
    _accumDx = 0.0;
    _dragStartTime = details.sourceTimeStamp;
    _lastDragTime = details.sourceTimeStamp;
    _xDriver.stop();
  }

  void _handleHorizontalUpdate(DragUpdateDetails details) {
    if (!mounted || !_draggingHorizontal || _exiting) return;
    _accumDx += details.primaryDelta ?? details.delta.dx;
    if (details.sourceTimeStamp != null) {
      _dragStartTime ??= details.sourceTimeStamp;
      _lastDragTime = details.sourceTimeStamp;
    }
    if (!widget.data.dismissible) {
      _xDriver.jumpTo((_dragOriginX + _accumDx) * 0.16);
    } else {
      _xDriver.jumpTo(_dragOriginX + _accumDx);
    }
  }

  double _resolveFallbackVelocity(double reported, double accumulated) {
    if (reported != 0.0 || accumulated.abs() < 16.0) {
      return reported;
    }
    if (_dragStartTime != null && _lastDragTime != null) {
      final int us = (_lastDragTime! - _dragStartTime!).inMicroseconds;
      if (us > 0 && us < 250000) {
        return accumulated * 1e6 / us;
      }
    }
    return reported;
  }

  void _handleHorizontalEnd(DragEndDetails details) {
    if (!mounted || !_draggingHorizontal || _exiting) return;
    _draggingHorizontal = false;
    final double vx = _resolveFallbackVelocity(
      details.primaryVelocity ?? details.velocity.pixelsPerSecond.dx,
      _accumDx,
    );
    final double x = _xDriver.value;
    final bool flicked = vx.abs() >= _horizontalDismissVelocity;
    if (widget.data.dismissible &&
        (x.abs() >= _horizontalDismissDistance || flicked)) {
      final double direction = flicked
          ? (vx >= 0.0 ? 1.0 : -1.0)
          : (x >= 0.0 ? 1.0 : -1.0);
      _exitHorizontal(
        direction,
        velocity: vx.isNegative == direction.isNegative ? vx : 0.0,
        reason: OrionToastDismissReason.swiped,
      );
      OrionHaptics.trigger(_impactHaptic);
      return;
    }
    _xDriver.retarget(0.0, velocity: vx);
  }

  void _handleHorizontalCancel() {
    _draggingHorizontal = false;
    _recoverIfDisplaced();
  }

  void _handleVerticalStart(DragStartDetails details) {
    if (_exiting || widget.departing) return;
    _draggingVertical = true;
    _dragOriginY = _yDriver.value;
    _accumDy = 0.0;
    _dragStartTime = details.sourceTimeStamp;
    _lastDragTime = details.sourceTimeStamp;
    _yDriver.stop();
  }

  void _handleVerticalUpdate(DragUpdateDetails details) {
    if (!mounted || !_draggingVertical || _exiting) return;
    _accumDy += details.primaryDelta ?? details.delta.dy;
    if (details.sourceTimeStamp != null) {
      _dragStartTime ??= details.sourceTimeStamp;
      _lastDragTime = details.sourceTimeStamp;
    }
    final double dismissSign = widget.isTop ? -1.0 : 1.0;
    final double rawY = _dragOriginY + _accumDy;
    final bool towardEdge = rawY * dismissSign > 0.0;
    if (towardEdge && widget.data.dismissible) {
      _yDriver.jumpTo(rawY);
    } else {
      _yDriver.jumpTo(rawY * 0.22);
    }
  }

  void _handleVerticalEnd(DragEndDetails details) {
    if (!mounted || !_draggingVertical || _exiting) return;
    _draggingVertical = false;
    final double dismissSign = widget.isTop ? -1.0 : 1.0;
    final double vy = _resolveFallbackVelocity(
      details.primaryVelocity ?? details.velocity.pixelsPerSecond.dy,
      _accumDy,
    );
    final double y = _yDriver.value;
    final double towardDist = y * dismissSign;
    final double towardVel = vy * dismissSign;
    if (widget.data.dismissible &&
        (towardDist >= _verticalDismissDistance ||
            towardVel >= _verticalDismissVelocity)) {
      _exitVertical(
        dismissSign,
        velocity: towardVel > 0.0 ? vy : 0.0,
        reason: OrionToastDismissReason.swiped,
      );
      OrionHaptics.trigger(_impactHaptic);
      return;
    }

    final double rawPullAway = -(_dragOriginY + _accumDy) * dismissSign;
    if (rawPullAway >= _pullExpandThreshold) {
      widget.onRequestExpand?.call();
    }
    _yDriver.retarget(0.0, velocity: vy);
  }

  void _handleVerticalCancel() {
    _draggingVertical = false;
    _recoverIfDisplaced();
  }

  void _recoverIfDisplaced() {
    if (_exiting || widget.departing) return;
    if (_xDriver.value != 0.0 || _xDriver.target != 0.0) {
      _xDriver.retarget(0.0);
    }
    if (_yDriver.value != 0.0 || _yDriver.target != 0.0) {
      _yDriver.retarget(0.0);
    }
  }

  void _exitHorizontal(
    double direction, {
    double velocity = 0.0,
    required OrionToastDismissReason reason,
  }) {
    _exitMode = _ExitMode.horizontal;
    _pendingReason = reason;
    _xDriver.retarget(
      direction * (_screenWidth + _cardWidth) / 2.0,
      velocity: velocity,
    );
  }

  void _exitVertical(
    double direction, {
    double velocity = 0.0,
    required OrionToastDismissReason reason,
  }) {
    _exitMode = _ExitMode.vertical;
    _pendingReason = reason;
    _yDriver.retarget(
      direction * math.max(_cardHeight + 48.0, 120.0),
      velocity: velocity,
    );
  }

  void _exitCalm(OrionToastDismissReason reason) {
    if (_exiting) return;
    _exitMode = _ExitMode.calm;
    _pendingReason = reason;
    _exitDriver.retarget(1.0);
  }

  Widget? _buildLeadingIcon(OrionToastStyle style, bool reducedMotion) {
    final Color color = style.iconColor ?? Colors.grey;
    final Color badgeBg = style.iconBackgroundColor ?? Colors.transparent;

    Widget? glyph;
    if (widget.data.icon != null) {
      glyph = IconTheme.merge(
        data: IconThemeData(color: color, size: 18.0),
        child: widget.data.icon!,
      );
    } else {
      glyph = switch (widget.data.status) {
        OrionToastStatus.neutral => null,
        OrionToastStatus.loading => SizedBox(
          width: 15.0,
          height: 15.0,
          child: CircularProgressIndicator(
            strokeWidth: 2.0,
            strokeCap: StrokeCap.round,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
        OrionToastStatus.success => Icon(
          Icons.check_circle_rounded,
          color: color,
          size: 18.0,
        ),
        OrionToastStatus.error => Icon(
          Icons.error_rounded,
          color: color,
          size: 18.0,
        ),
        OrionToastStatus.warning => Icon(
          Icons.warning_rounded,
          color: color,
          size: 18.0,
        ),
        OrionToastStatus.info => Icon(
          Icons.info_rounded,
          color: color,
          size: 18.0,
        ),
      };
    }

    if (glyph == null) {
      return null;
    }

    final Widget wrapped = widget.data.icon != null || badgeBg.a <= 0
        ? glyph
        : Container(
            width: 28.0,
            height: 28.0,
            decoration: BoxDecoration(color: badgeBg, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: glyph,
          );

    if (reducedMotion) {
      return wrapped;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (Widget child, Animation<double> anim) {
        return FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.78, end: 1.0).animate(anim),
            child: child,
          ),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<Object>(widget.data.icon ?? widget.data.status),
        child: wrapped,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final Size? measured = context.size;
      if (measured != null) {
        _cardWidth = measured.width;
        _cardHeight = measured.height;
      }
    });

    final ThemeData theme = Theme.of(context);
    final OrionToastStyle style = _resolveStyle(theme);
    final OrionThemeData orion = OrionTheme.of(context);
    final bool reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;

    final BorderRadius radius =
        style.borderRadius ?? BorderRadius.circular(OrionRadii.radius16);
    final bool frosted = style.frosted ?? false;
    final Color bg = style.backgroundColor ?? theme.colorScheme.surface;
    final double borderWidth = math.max(0.0, style.borderWidth ?? 1.0);
    final double maxWidth = math.max(160.0, style.maxWidth ?? 380.0);
    final EdgeInsets resolvedPadding =
        (style.padding ??
                const EdgeInsets.symmetric(
                  horizontal: OrionSpacing.space16,
                  vertical: OrionSpacing.space12,
                ))
            .resolve(Directionality.of(context));

    final bool showClose =
        widget.data.dismissible &&
        (widget.data.showCloseButton ?? widget.showCloseButton);
    final double rightPad = showClose && widget.data.action == null
        ? math.max(OrionSpacing.space8, resolvedPadding.right - 6.0)
        : resolvedPadding.right;

    final Widget? leadingIcon = _buildLeadingIcon(style, reducedMotion);

    final Widget content = Padding(
      padding: EdgeInsets.only(
        left: resolvedPadding.left,
        right: rightPad,
        top: resolvedPadding.top,
        bottom: resolvedPadding.bottom,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: <Widget>[
          if (leadingIcon != null) ...<Widget>[
            leadingIcon,
            const SizedBox(width: OrionSpacing.space12),
          ],
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  widget.data.title,
                  style: style.titleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.data.description != null &&
                    widget.data.description!.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 2.0),
                  Text(
                    widget.data.description!,
                    style: style.descriptionStyle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          if (widget.data.action != null) ...<Widget>[
            const SizedBox(width: OrionSpacing.space12),
            OrionButton(
              size: OrionButtonSize.small,
              variant: OrionButtonVariant.bordered,
              style:
                  style.actionStyle ??
                  OrionButtonStyle.from(
                    borderRadius: BorderRadius.circular(OrionRadii.radius8),
                  ),
              onPressed: () {
                final OrionToastAction action = widget.data.action!;
                action.onPressed();
                if (action.dismissOnPress) {
                  _exitCalm(OrionToastDismissReason.action);
                }
              },
              child: Text(widget.data.action!.label),
            ),
          ],
          if (showClose) ...<Widget>[
            const SizedBox(width: OrionSpacing.space4),
            _ToastCloseButton(
              color:
                  style.closeButtonColor ?? theme.colorScheme.onSurfaceVariant,
              onPressed: () => _exitCalm(OrionToastDismissReason.closeButton),
            ),
          ],
        ],
      ),
    );

    final Widget backdrop = frosted
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: orion.blurSigma,
              sigmaY: orion.blurSigma,
            ),
            child: ColoredBox(color: bg.withValues(alpha: 0.82)),
          )
        : ColoredBox(color: bg);

    final Color progressColor =
        style.progressBarColor ?? style.iconColor ?? theme.colorScheme.primary;

    final Widget cardSurface = Material(
      type: MaterialType.transparency,
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: 48.0, maxWidth: maxWidth),
        child: SizedBox(
          width: double.infinity,
          child: DecoratedBox(
            key: orionToastCardFaceKey,
            decoration: BoxDecoration(
              borderRadius: radius,
              border: borderWidth > 0
                  ? Border.all(
                      color:
                          style.borderColor ?? theme.colorScheme.outlineVariant,
                      width: borderWidth,
                    )
                  : null,
              boxShadow: style.shadow ?? OrionToastPresets.lightShadow,
            ),
            child: ClipRRect(
              borderRadius: radius,
              child: Stack(
                children: <Widget>[
                  Positioned.fill(child: backdrop),
                  content,
                  if (_effectiveShowProgressBar && _progressController != null)
                    Positioned(
                      left: 0.0,
                      right: 0.0,
                      bottom: 0.0,
                      height: 2.5,
                      child: AnimatedBuilder(
                        animation: _progressController!,
                        builder: (BuildContext context, Widget? child) {
                          return FractionallySizedBox(
                            alignment: AlignmentDirectional.centerStart,
                            widthFactor: _progressController!.value.clamp(
                              0.0,
                              1.0,
                            ),
                            child: ColoredBox(
                              key: orionToastProgressBarKey,
                              color: progressColor.withValues(alpha: 0.75),
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
    );

    final bool tappableBody =
        widget.onCardTap != null || widget.data.onTap != null;

    return IgnorePointer(
      ignoring: widget.departing,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        dragStartBehavior: DragStartBehavior.down,
        onTap: tappableBody
            ? () {
                _recoverIfDisplaced();
                if (widget.onCardTap != null) {
                  widget.onCardTap!();
                } else {
                  widget.data.onTap?.call();
                }
              }
            : _recoverIfDisplaced,
        onHorizontalDragDown: _handleDragDown,
        onHorizontalDragStart: _handleHorizontalStart,
        onHorizontalDragUpdate: _handleHorizontalUpdate,
        onHorizontalDragEnd: _handleHorizontalEnd,
        onHorizontalDragCancel: _handleHorizontalCancel,
        onVerticalDragDown: _handleDragDown,
        onVerticalDragStart: _handleVerticalStart,
        onVerticalDragUpdate: _handleVerticalUpdate,
        onVerticalDragEnd: _handleVerticalEnd,
        onVerticalDragCancel: _handleVerticalCancel,
        child: AnimatedBuilder(
          animation: Listenable.merge(<Listenable>[
            _xDriver,
            _yDriver,
            _exitDriver,
          ]),
          child: cardSurface,
          builder: (BuildContext context, Widget? child) {
            final double x = _xDriver.value;
            final double ySwipe = _yDriver.value;
            final double exitT = _exitDriver.value.clamp(0.0, 1.0);
            final double calmOffsetY =
                (widget.isTop ? -_calmExitTravel : _calmExitTravel) * exitT;

            final double xOpacity = (1.0 - (x.abs() / _horizontalFadeDistance))
                .clamp(0.0, 1.0);
            final double yOpacity =
                (1.0 - (ySwipe.abs() / _verticalFadeDistance)).clamp(0.0, 1.0);
            final double calmOpacity = (1.0 - exitT).clamp(0.0, 1.0);
            final double combinedOpacity = (xOpacity * yOpacity * calmOpacity)
                .clamp(0.0, 1.0);
            final double calmScale = 1.0 - (0.06 * exitT);

            return Transform.translate(
              offset: Offset(x, ySwipe + calmOffsetY),
              child: Transform.scale(
                scale: calmScale,
                alignment: widget.isTop
                    ? Alignment.topCenter
                    : Alignment.bottomCenter,
                child: Opacity(opacity: combinedOpacity, child: child),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ToastCloseButton extends StatefulWidget {
  const _ToastCloseButton({required this.color, required this.onPressed});

  final Color color;
  final VoidCallback onPressed;

  @override
  State<_ToastCloseButton> createState() => _ToastCloseButtonState();
}

class _ToastCloseButtonState extends State<_ToastCloseButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final String label = MaterialLocalizations.of(context).closeButtonTooltip;
    final Color hoverBg = scheme.onSurface.withValues(
      alpha: scheme.brightness == Brightness.dark ? 0.12 : 0.06,
    );

    return Semantics(
      button: true,
      label: label,
      child: Tooltip(
        message: label,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) {
            if (mounted && !_hovered) setState(() => _hovered = true);
          },
          onExit: (_) {
            if (mounted && _hovered) setState(() => _hovered = false);
          },
          child: OrionPressable(
            key: orionToastCloseButtonKey,
            onTap: widget.onPressed,
            pressedScale: 0.90,
            hapticType: OrionHapticType.selectionClick,
            child: SizedBox(
              width: 32.0,
              height: 32.0,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: _hovered ? hoverBg : null,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: OrionSizing.iconSmall,
                  color: widget.color,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
