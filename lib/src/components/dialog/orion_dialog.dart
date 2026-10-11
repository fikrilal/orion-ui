import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/button/orion_button.dart';
import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/components/dialog/orion_dialog_action.dart';
import 'package:orion_ui/src/components/dialog/orion_dialog_presets.dart';
import 'package:orion_ui/src/components/dialog/orion_dialog_style.dart';
import 'package:orion_ui/src/components/dialog/orion_dialog_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Layout mode for action buttons inside an [OrionDialog].
enum OrionDialogActionLayout {
  /// Automatically balances horizontal side-by-side for 1-2 actions, and
  /// vertical stacked column for 3+ actions.
  auto,

  /// Forces side-by-side horizontal row layout.
  horizontal,

  /// Forces stacked vertical column layout.
  vertical,
}

/// A physics-driven, centered modal dialog surface.
///
/// Unlike anchored floating surfaces (popovers and menus) which emerge from
/// trigger coordinates, [OrionDialog] adheres to Emil Kowalski's Centered Modal
/// Law: it blossoms directly out of screen center with authoritative micro-scale
/// kinematics ($0.94 \to 1.0$) and subtle directional glide ($y = 6 \to 0$).
///
/// Features:
/// - Single continuous [OrionSpringDriver] simulation with Zero Snap continuity.
/// - Surface frosted glass option (`frosted: true`) with static blur isolation.
/// - Adaptive action button layout ([OrionDialogActionLayout]).
/// - Zero per-frame rebuilds of child content during animation ticks.
/// - Reduced motion support (immediate settlement on frame 0).
class OrionDialog extends StatelessWidget {
  const OrionDialog({
    super.key,
    this.icon,
    this.title,
    this.description,
    this.content,
    this.actions = const <OrionDialogAction>[],
    this.actionLayout = OrionDialogActionLayout.auto,
    this.style,
  });

  /// Optional leading icon or illustration widget displayed above the title.
  final Widget? icon;

  /// Primary dialog title text.
  final String? title;

  /// Secondary descriptive text explaining the purpose of the dialog.
  final String? description;

  /// Custom body content widget subtree inserted below the description.
  final Widget? content;

  /// List of action buttons displayed in the dialog footer.
  final List<OrionDialogAction> actions;

  /// Layout arrangement for the action buttons.
  final OrionDialogActionLayout actionLayout;

  /// Instance style overrides.
  final OrionDialogStyle? style;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final orionTheme = OrionTheme.of(context);

    final OrionDialogTheme dialogTheme =
        theme.extension<OrionDialogTheme>() ?? OrionDialogTheme.fallback;
    final OrionDialogStyle resolvedStyle = OrionDialogPresets.resolve(
      scheme: scheme,
    ).merge(dialogTheme.defaultStyle).merge(style);

    final BorderRadius radius =
        resolvedStyle.borderRadius ??
        BorderRadius.circular(OrionRadii.radius24);
    final Color bg = resolvedStyle.backgroundColor ?? scheme.surface;
    final bool frosted = resolvedStyle.frosted ?? false;
    final double contentSpacing = resolvedStyle.contentSpacing ?? 16.0;

    final Widget surfaceBackdrop = frosted
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: orionTheme.blurSigma,
              sigmaY: orionTheme.blurSigma,
            ),
            child: ColoredBox(color: bg.withValues(alpha: 0.70)),
          )
        : ColoredBox(color: bg);

    final List<Widget> bodyItems = <Widget>[];

    // Icon slot
    if (icon != null) {
      bodyItems.add(
        Padding(
          padding: EdgeInsets.only(bottom: contentSpacing * 0.75),
          child: Center(child: icon),
        ),
      );
    }

    // Title slot
    if (title != null) {
      bodyItems.add(
        Text(
          title!,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 18.0,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.2,
            color: scheme.onSurface,
          ),
        ),
      );
    }

    // Description slot
    if (description != null) {
      bodyItems.add(
        Padding(
          padding: EdgeInsets.only(top: title != null ? 8.0 : 0.0),
          child: Text(
            description!,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.45,
              color: scheme.onSurfaceVariant,
            ),
          ),
        ),
      );
    }

    // Custom content slot
    if (content != null) {
      bodyItems.add(
        Padding(
          padding: EdgeInsets.only(
            top: (title != null || description != null) ? contentSpacing : 0.0,
          ),
          child: content!,
        ),
      );
    }

    // Actions slot
    if (actions.isNotEmpty) {
      bodyItems.add(
        Padding(
          padding: EdgeInsets.only(top: contentSpacing * 1.25),
          child: _buildActionsLayout(context, scheme, resolvedStyle),
        ),
      );
    }

    return Semantics(
      scopesRoute: true,
      namesRoute: true,
      explicitChildNodes: true,
      label: title,
      container: true,
      child: Container(
        constraints: BoxConstraints(maxWidth: resolvedStyle.maxWidth ?? 340.0),
        decoration: BoxDecoration(
          borderRadius: radius,
          border: Border.all(
            color:
                resolvedStyle.borderColor ??
                scheme.outlineVariant.withValues(alpha: 0.35),
            width: resolvedStyle.borderWidth ?? 1.0,
          ),
          boxShadow: resolvedStyle.shadow ?? OrionThemeData.defaultShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: [
                Positioned.fill(child: surfaceBackdrop),
                Padding(
                  padding:
                      resolvedStyle.padding ??
                      const EdgeInsets.all(OrionSpacing.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: bodyItems,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionsLayout(
    BuildContext context,
    ColorScheme scheme,
    OrionDialogStyle resolvedStyle,
  ) {
    final double spacing = resolvedStyle.actionSpacing ?? 10.0;
    final bool useVertical = switch (actionLayout) {
      OrionDialogActionLayout.vertical => true,
      OrionDialogActionLayout.horizontal => false,
      OrionDialogActionLayout.auto =>
        actions.length > 2 || actions.any((a) => a.label.length > 10),
    };

    if (useVertical) {
      final List<Widget> actionWidgets = <Widget>[];
      for (int i = 0; i < actions.length; i++) {
        if (i > 0) {
          actionWidgets.add(SizedBox(height: spacing));
        }
        actionWidgets.add(
          _buildActionButton(actions[i], scheme, isExpanded: true),
        );
      }
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: actionWidgets,
      );
    }

    // Horizontal arrangement
    final List<Widget> actionWidgets = <Widget>[];
    for (int i = 0; i < actions.length; i++) {
      if (i > 0) {
        actionWidgets.add(SizedBox(width: spacing));
      }
      actionWidgets.add(
        Expanded(
          child: _buildActionButton(actions[i], scheme, isExpanded: true),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.max, children: actionWidgets);
  }

  Widget _buildActionButton(
    OrionDialogAction action,
    ColorScheme scheme, {
    required bool isExpanded,
  }) {
    final OrionButtonVariant variant = switch (action.variant) {
      OrionDialogActionVariant.primary => OrionButtonVariant.solid,
      OrionDialogActionVariant.secondary => OrionButtonVariant.bordered,
      OrionDialogActionVariant.destructive => OrionButtonVariant.solid,
      OrionDialogActionVariant.cancel => OrionButtonVariant.flat,
    };

    OrionButtonStyle? customStyle;
    if (action.variant == OrionDialogActionVariant.destructive) {
      customStyle = OrionButtonStyle.from(
        backgroundColor: scheme.error,
        foregroundColor: scheme.onError,
      );
    }

    return OrionButton(
      variant: variant,
      size: OrionButtonSize.medium,
      style: customStyle,
      isExpanded: isExpanded,
      leading: action.leading,
      isLoading: action.isLoading,
      onPressed: action.enabled ? action.onPressed : null,
      child: Flexible(
        child: Text(action.label, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}

/// Presents an [OrionDialog] imperatively as a modal route.
///
/// Returns a [Future] resolving to the value passed when the dialog is dismissed.
Future<T?> showOrionDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  OrionDialogStyle? style,
  bool barrierDismissible = true,
  RouteSettings? routeSettings,
}) {
  return Navigator.of(context, rootNavigator: true).push<T>(
    _OrionDialogRoute<T>(
      pageBuilder: (buildContext, animation, secondaryAnimation) =>
          builder(buildContext),
      style: style,
      isBarrierDismissible: barrierDismissible,
      settings: routeSettings,
    ),
  );
}

/// Presents a high-level confirmation dialog with confirm and cancel buttons.
///
/// Returns `true` if the confirm button was pressed, or `false` if cancelled
/// or dismissed via barrier/back button.
Future<bool> showOrionConfirmDialog({
  required BuildContext context,
  required String title,
  required String message,
  String confirmLabel = 'Confirm',
  String cancelLabel = 'Cancel',
  bool isDestructive = false,
  Widget? icon,
  OrionDialogStyle? style,
  bool barrierDismissible = true,
}) async {
  final bool? result = await showOrionDialog<bool>(
    context: context,
    style: style,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return OrionDialog(
        icon: icon,
        title: title,
        description: message,
        style: style,
        actions: [
          OrionDialogAction.cancel(
            label: cancelLabel,
            onPressed: () => Navigator.of(dialogContext).maybePop(false),
          ),
          if (isDestructive)
            OrionDialogAction.destructive(
              label: confirmLabel,
              onPressed: () => Navigator.of(dialogContext).maybePop(true),
            )
          else
            OrionDialogAction.primary(
              label: confirmLabel,
              onPressed: () => Navigator.of(dialogContext).maybePop(true),
            ),
        ],
      );
    },
  );

  return result ?? false;
}

/// Presents a high-level informational alert dialog with a single acknowledgment button.
Future<void> showOrionAlertDialog({
  required BuildContext context,
  required String title,
  required String message,
  String actionLabel = 'OK',
  Widget? icon,
  OrionDialogStyle? style,
  bool barrierDismissible = true,
}) {
  return showOrionDialog<void>(
    context: context,
    style: style,
    barrierDismissible: barrierDismissible,
    builder: (dialogContext) {
      return OrionDialog(
        icon: icon,
        title: title,
        description: message,
        style: style,
        actions: [
          OrionDialogAction.primary(
            label: actionLabel,
            onPressed: () => Navigator.of(dialogContext).maybePop(),
          ),
        ],
      );
    },
  );
}

class _OrionDialogRoute<T> extends PopupRoute<T> {
  _OrionDialogRoute({
    required this.pageBuilder,
    required this.style,
    required this.isBarrierDismissible,
    super.settings,
  });

  final RoutePageBuilder pageBuilder;
  final OrionDialogStyle? style;
  final bool isBarrierDismissible;

  @override
  Duration get transitionDuration => Duration.zero;

  @override
  bool get barrierDismissible => false; // Managed by overlay for continuous spring dismissal

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss dialog';

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return child;
  }

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return _OrionDialogOverlay<T>(
      route: this,
      style: style,
      barrierDismissible: isBarrierDismissible,
      child: pageBuilder(context, animation, secondaryAnimation),
    );
  }
}

class _OrionDialogOverlay<T> extends StatefulWidget {
  const _OrionDialogOverlay({
    required this.route,
    required this.style,
    required this.barrierDismissible,
    required this.child,
  });

  final _OrionDialogRoute<T> route;
  final OrionDialogStyle? style;
  final bool barrierDismissible;
  final Widget child;

  @override
  State<_OrionDialogOverlay<T>> createState() => _OrionDialogOverlayState<T>();
}

class _OrionDialogOverlayState<T> extends State<_OrionDialogOverlay<T>>
    with SingleTickerProviderStateMixin {
  late final OrionSpringDriver _driver;
  bool _isClosing = false;
  T? _dismissResult;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec:
          widget.style?.springSpec ??
          const OrionSpringSpec(stiffness: 380.0, dampingRatio: 0.85),
    );
    _driver.addStatusListener(_onDriverStatus);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_driver.reducedMotion) {
          _driver.jumpTo(1.0);
        } else {
          _driver.retarget(1.0);
          OrionHaptics.trigger(OrionHapticType.selectionClick);
        }
      }
    });
  }

  OrionDialogStyle _resolveStyle(BuildContext context) {
    final theme = Theme.of(context);
    final dialogTheme =
        theme.extension<OrionDialogTheme>() ?? OrionDialogTheme.fallback;
    return OrionDialogPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(dialogTheme.defaultStyle).merge(widget.style);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.reducedMotion = reduced;

    final resolvedStyle = _resolveStyle(context);
    if (!_isClosing && resolvedStyle.springSpec != null) {
      _driver.springSpec = resolvedStyle.springSpec!;
    }
  }

  @override
  void dispose() {
    _driver.removeStatusListener(_onDriverStatus);
    _driver.dispose();
    super.dispose();
  }

  void _onDriverStatus(AnimationStatus status) {
    if (!mounted) return;
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _driver.value <= 0.01) {
      if (widget.route.isCurrent) {
        Navigator.of(context).pop(_dismissResult);
      }
    }
  }

  void _dismiss([T? result]) {
    if (_isClosing) return;
    _isClosing = true;
    _dismissResult = result;

    if (_driver.reducedMotion) {
      _driver.jumpTo(0.0);
      if (widget.route.isCurrent) {
        Navigator.of(context).pop(_dismissResult);
      }
      return;
    }

    final resolvedStyle = _resolveStyle(context);
    _driver.springSpec =
        resolvedStyle.dismissSpringSpec ??
        const OrionSpringSpec(
          stiffness: 340.0,
          dampingRatio: 1.0,
          clampOvershoot: true,
        );
    _driver.retarget(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    final OrionDialogTheme dialogTheme =
        theme.extension<OrionDialogTheme>() ?? OrionDialogTheme.fallback;
    final OrionDialogStyle resolvedStyle = OrionDialogPresets.resolve(
      scheme: scheme,
    ).merge(dialogTheme.defaultStyle).merge(widget.style);

    final Color barrierColor =
        resolvedStyle.barrierColor ?? const Color(0x73000000);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _dismiss(result as T?);
      },
      child: FocusScope(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              widget.barrierDismissible) {
            _dismiss();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: AnimatedBuilder(
          animation: _driver,
          child: widget.child,
          builder: (context, child) {
            final double progress = _driver.value;
            final double scrimOpacity = progress.clamp(0.0, 1.0);
            final double scale = 0.94 + (0.06 * progress);
            final double opacity = (progress * 2.0).clamp(0.0, 1.0);
            final double translateY = (1.0 - progress.clamp(0.0, 1.0)) * 6.0;

            return Stack(
              children: [
                // Backdrop Scrim
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.barrierDismissible ? () => _dismiss() : null,
                    child: ColoredBox(
                      color: barrierColor.withValues(
                        alpha: barrierColor.a * scrimOpacity,
                      ),
                    ),
                  ),
                ),

                // Centered Dialog Surface
                Positioned.fill(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      child: IgnorePointer(
                        ignoring: _isClosing,
                        child: Transform.translate(
                          offset: Offset(0, translateY),
                          child: Transform.scale(
                            scale: scale,
                            alignment: Alignment.center,
                            child: Opacity(opacity: opacity, child: child),
                          ),
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
  }
}
