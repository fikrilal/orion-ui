import 'dart:ui' show ImageFilter;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button.dart';
import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/components/toast/orion_toast_data.dart';
import 'package:orion_ui/src/components/toast/orion_toast_presets.dart';
import 'package:orion_ui/src/components/toast/orion_toast_style.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Interactive toast notification card with swipe-to-dismiss physics.
///
/// The card owns a single horizontal [OrionSpringDriver]. A drag drives its
/// position one to one, a release either retargets it home or glides it off the
/// nearest edge, and a dismissal is reported when that glide lands - never from
/// the gesture itself, so a swipe always ends in motion instead of a cut.
///
/// The driver is the only source of the card's horizontal position: taking hold
/// of a card that is already moving continues from where it is, in position and
/// in velocity, and no pointer event jumps it. An exit is the one exception: a
/// card that is already leaving is committed and cannot be caught back.
///
/// A card whose host has dropped it ([departing]) is out of the interaction
/// business - it neither takes pointers nor reports a dismissal - and only tells
/// the host through [onExited] that its exit has landed.
class OrionToastCard extends StatefulWidget {
  const OrionToastCard({
    super.key,
    required this.data,
    required this.onDismiss,
    this.departing = false,
    this.onExited,
    this.style,
  });

  /// The toast payload.
  final OrionToastData data;

  /// Invoked when the toast is swiped away or its close button tapped.
  final ValueChanged<String> onDismiss;

  /// Whether the host has already dropped this toast and is only keeping the
  /// card on screen until it has finished leaving.
  final bool departing;

  /// Invoked when a [departing] card has finished its exit glide.
  final VoidCallback? onExited;

  /// Per-instance style overrides.
  final OrionToastStyle? style;

  @override
  State<OrionToastCard> createState() => _OrionToastCardState();
}

class _OrionToastCardState extends State<OrionToastCard>
    with SingleTickerProviderStateMixin {
  /// Travel that turns a release into a dismissal.
  static const double _dismissDistance = 72.0;

  /// Speed that turns a flick into a dismissal, however short the drag.
  static const double _dismissVelocity = 500.0;

  /// Travel over which a swipe fades the card out.
  static const double _fadeDistance = 300.0;

  late final OrionSpringDriver _swipeDriver;
  VelocityTracker _velocityTracker = VelocityTracker.withKind(
    PointerDeviceKind.touch,
  );
  OrionHapticType _impactHaptic = OrionHapticType.lightImpact;
  bool _dragging = false;
  bool _exiting = false;
  bool _delivered = false;
  double _dragStartX = 0;
  double _dragOrigin = 0;
  double _currentX = 0;
  double _screenWidth = 0;
  double _cardWidth = 0;

  @override
  void initState() {
    super.initState();
    _swipeDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionSpringSpec.gentle,
    )..addStatusListener(_onSwipeStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final ThemeData theme = Theme.of(context);
    _swipeDriver.reducedMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _swipeDriver.springSpec =
        _resolveStyle(theme).swipeSpring ?? OrionSpringSpec.gentle;
    _impactHaptic = OrionTheme.of(context).impactHaptic;
    // Read here, where an ancestor lookup is allowed: an exit can be asked for
    // after the element has left the tree, and it cannot look anything up then.
    _screenWidth = MediaQuery.maybeSizeOf(context)?.width ?? 0;
  }

  @override
  void didUpdateWidget(OrionToastCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.departing == oldWidget.departing) {
      return;
    }
    if (!widget.departing) {
      // Shown again: a card held in the exit comes back to its place rather than
      // finishing a departure nobody is waiting for any more.
      if (_exiting) {
        _exiting = false;
        _swipeDriver.retarget(0.0, velocity: _swipeDriver.velocity);
      }
      return;
    }
    if (_exiting) {
      return; // already leaving: the status report hands it over
    }
    if (_delivered) {
      _reportExited(); // already gone; nothing left to animate
      return;
    }
    // Deferred: this runs inside a build, and an exit moves the driver.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.departing && !_exiting) {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _swipeDriver
      ..removeStatusListener(_onSwipeStatus)
      ..dispose();
    super.dispose();
  }

  /// Reports the exit once the glide has landed.
  ///
  /// Which report that is depends on what the host needs *now*, not on what
  /// started the exit: a host that dropped the toast while the card was still
  /// travelling is waiting to be told the card is gone, and telling it about a
  /// dismissal instead would leave the card on screen for good.
  void _onSwipeStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed || !_exiting) {
      return;
    }
    _exiting = false;
    if (widget.departing) {
      _reportExited();
      return;
    }
    _delivered = true;
    widget.onDismiss(widget.data.id);
  }

  /// Hands a dropped card back to the host that is holding it on screen.
  ///
  /// Deferred to the end of the frame: reduced motion lands the exit inside the
  /// retarget, which can be a build phase, and the host reacts by rebuilding.
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
      stackStyle: widget.style,
      instanceStyle: widget.data.style,
    );
  }

  void _onPointerDown(PointerDownEvent event) {
    if (!widget.data.dismissible || _exiting || widget.departing) {
      return;
    }
    _dragging = true;
    _velocityTracker = VelocityTracker.withKind(event.kind);
    _velocityTracker.addPosition(event.timeStamp, event.position);
    _dragStartX = event.position.dx;
    // The finger takes the card where it is: a moving card is caught without a
    // position jump and without truncating the velocity it already carries.
    _dragOrigin = _swipeDriver.value;
    _currentX = _dragOrigin;
    _swipeDriver.stop();
  }

  /// A gesture outlives the card it started on - a pointer that is still down
  /// when the host drops the toast is released afterwards - so every release
  /// path checks that there is still an element to act on.
  void _onPointerMove(PointerMoveEvent event) {
    if (!mounted || !_dragging || _exiting) {
      return;
    }
    _velocityTracker.addPosition(event.timeStamp, event.position);
    _currentX = _dragOrigin + (event.position.dx - _dragStartX);
    _swipeDriver.jumpTo(_currentX);
  }

  void _onPointerUp(PointerUpEvent event) {
    if (!mounted || !_dragging || _exiting) {
      return;
    }
    _dragging = false;
    _velocityTracker.addPosition(event.timeStamp, event.position);
    final double vx = _velocityTracker.getVelocity().pixelsPerSecond.dx;
    final bool flicked = vx.abs() > _dismissVelocity;

    if (widget.data.dismissible &&
        (_currentX.abs() > _dismissDistance || flicked)) {
      final double direction = flicked
          ? (vx > 0 ? 1.0 : -1.0)
          : (_currentX >= 0 ? 1.0 : -1.0);
      // Hand the gesture over only when it already points the way the card is
      // leaving; a backwards velocity would first send it the long way round.
      _exit(
        direction,
        velocity: vx.isNegative == direction.isNegative ? vx : 0.0,
      );
      // The buzz belongs to the gesture, not to the card: a toast that simply
      // times out leaves in silence.
      OrionHaptics.trigger(_impactHaptic);
      return;
    }
    // Snap back cleanly to center, keeping the release velocity.
    _swipeDriver.retarget(0.0, velocity: vx);
  }

  void _onPointerCancel(PointerCancelEvent event) {
    if (!mounted || !_dragging || _exiting) {
      return;
    }
    _dragging = false;
    _swipeDriver.retarget(0.0);
  }

  /// Glides the card off the [direction] edge, then reports the exit.
  ///
  /// The travel comes from the width on offer rather than a fixed number: a
  /// constant that clears a phone leaves the card on screen when the item is
  /// removed on a tablet. Both widths are read from cache - an exit can be asked
  /// for from a post-frame callback, or after the element has left the tree
  /// entirely, and neither may size a render object up.
  void _exit(double direction, {double velocity = 0.0}) {
    _exiting = true;
    _swipeDriver.retarget(
      direction * (_screenWidth + _cardWidth) / 2,
      velocity: velocity,
    );
  }

  /// Dismisses without a gesture, leaving by the nearer edge.
  void _dismiss() {
    if (_exiting) {
      return;
    }
    _exit(_swipeDriver.value >= 0 ? 1.0 : -1.0);
  }

  Widget _buildStatusIcon(OrionToastStyle style) {
    if (widget.data.icon != null) {
      return widget.data.icon!;
    }

    final Color color = style.iconColor ?? Colors.grey;
    return switch (widget.data.status) {
      OrionToastStatus.loading => SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
      OrionToastStatus.success => Icon(
        Icons.check_circle_rounded,
        color: color,
        size: 20,
      ),
      OrionToastStatus.error => Icon(
        Icons.error_rounded,
        color: color,
        size: 20,
      ),
      OrionToastStatus.warning => Icon(
        Icons.warning_amber_rounded,
        color: color,
        size: 20,
      ),
      OrionToastStatus.info => Icon(
        Icons.info_outline_rounded,
        color: color,
        size: 20,
      ),
      OrionToastStatus.neutral => Icon(
        Icons.notifications_active_rounded,
        color: color,
        size: 20,
      ),
    };
  }

  Widget _buildCloseButton(BuildContext context, OrionToastStyle style) {
    return MergeSemantics(
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: _dismiss,
          child: SizedBox(
            width: OrionSizing.minHitTarget,
            height: OrionSizing.minHitTarget,
            child: Icon(
              Icons.close_rounded,
              size: OrionSizing.iconSmall,
              color: style.closeButtonColor,
              semanticLabel: MaterialLocalizations.of(
                context,
              ).closeButtonTooltip,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Sizing is read here, after the frame, and kept for the exit: an exit can be
    // asked for from a build phase or after the element has gone, and neither
    // place may ask a render object how big it is.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      final double? width = context.size?.width;
      if (width != null) {
        _cardWidth = width;
      }
    });

    final ThemeData theme = Theme.of(context);
    final OrionToastStyle style = _resolveStyle(theme);
    final OrionThemeData orion = OrionTheme.of(context);

    final BorderRadius radius =
        style.borderRadius ?? BorderRadius.circular(OrionRadii.radius16);
    final bool frosted = style.frosted ?? false;
    final Color bg = style.backgroundColor ?? theme.colorScheme.surface;

    final Widget content = Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: OrionSpacing.space16,
        vertical: OrionSpacing.space12,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildStatusIcon(style),
          const SizedBox(width: OrionSpacing.space12),
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.data.title,
                  style: style.titleStyle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (widget.data.description != null) ...[
                  const SizedBox(height: 2),
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
          if (widget.data.action != null) ...[
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
                widget.data.action!.onPressed();
                _dismiss();
              },
              child: Text(widget.data.action!.label),
            ),
          ],
          if (widget.data.dismissible) ...[
            const SizedBox(width: OrionSpacing.space8),
            _buildCloseButton(context, style),
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
            child: ColoredBox(color: bg.withValues(alpha: 0.85)),
          )
        : ColoredBox(color: bg);

    final Widget cardSurface = Container(
      constraints: const BoxConstraints(minHeight: 48, maxWidth: 380),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(
          color: style.borderColor ?? theme.colorScheme.outlineVariant,
          width: style.borderWidth ?? 1.0,
        ),
        boxShadow: style.shadow ?? OrionThemeData.defaultShadow,
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Stack(
          children: [
            Positioned.fill(child: backdrop),
            content,
          ],
        ),
      ),
    );

    return IgnorePointer(
      // A dropped card is a picture of one: it must not take a tap meant for
      // whatever the app has underneath, nor one meant for a live toast.
      ignoring: widget.departing,
      child: Listener(
        behavior: HitTestBehavior.translucent,
        onPointerDown: _onPointerDown,
        onPointerMove: _onPointerMove,
        onPointerUp: _onPointerUp,
        onPointerCancel: _onPointerCancel,
        child: AnimatedBuilder(
          animation: _swipeDriver,
          child: cardSurface,
          builder: (BuildContext context, Widget? child) {
            final double x = _swipeDriver.value;
            final double opacity = (1.0 - (x.abs() / _fadeDistance)).clamp(
              0.0,
              1.0,
            );
            return Transform.translate(
              offset: Offset(x, 0),
              child: Opacity(opacity: opacity, child: child),
            );
          },
        ),
      ),
    );
  }
}
