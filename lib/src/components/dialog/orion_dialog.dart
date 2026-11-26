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
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Key assigned to the optional top-right close button when
/// [OrionDialog.showCloseButton] is true.
const Key orionDialogCloseButtonKey = Key('orion_dialog_close_button');

/// Layout mode for action buttons inside an [OrionDialog].
enum OrionDialogActionLayout {
  /// Automatically balances horizontal side-by-side for 1-2 short actions, and
  /// vertical stacked column for 3+ actions or long labels.
  auto,

  /// Forces side-by-side horizontal row layout.
  horizontal,

  /// Forces stacked vertical column layout.
  vertical,
}

/// A physics-driven, centered modal dialog surface.
///
/// Unlike anchored floating surfaces (popovers and menus) which emerge from
/// trigger coordinates, [OrionDialog] blossoms directly out of screen center
/// with authoritative micro-scale kinematics (`0.94 -> 1.0`) and subtle upward
/// glide (`y = 6 -> 0`).
///
/// Features:
/// - Single continuous [OrionSpringDriver] simulation with mid-flight reversal.
/// - Programmatic animated dismissal via [OrionDialog.dismissOf], even when
///   `barrierDismissible` is false.
/// - Automatic keyboard inset lift (`viewInsets`), `SafeArea`, and internal
///   body scrolling while keeping footer actions pinned and reachable.
/// - Surface frosted glass option (`frosted: true`) with static blur isolation.
/// - Adaptive action layout ([OrionDialogActionLayout]) that keeps primary
///   actions above cancel when stacked vertically.
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
    this.centerContent = true,
    this.showCloseButton = false,
    this.onClose,
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

  /// Whether [icon], [title], and [description] are centered (`true`) or
  /// start-aligned (`false`). Defaults to `true`.
  final bool centerContent;

  /// Whether to show a top-right close button (`×`) inside the dialog header.
  final bool showCloseButton;

  /// Custom handler for the top-right close button when [showCloseButton] is
  /// true. Defaults to dismissing the dialog via [OrionDialog.dismissOf].
  final VoidCallback? onClose;

  /// Instance style overrides.
  final OrionDialogStyle? style;

  /// Smoothly dismisses the enclosing [OrionDialog] presented via
  /// [showOrionDialog], optionally returning [result] to the caller's Future.
  ///
  /// Always plays the dialog's spring exit animation, even when
  /// `barrierDismissible` is `false`. Falls back to `Navigator.maybePop` if
  /// the dialog is not hosted inside [showOrionDialog].
  static void dismissOf<T>(BuildContext context, [T? result]) {
    final _OrionDialogScope? scope = context
        .getInheritedWidgetOfExactType<_OrionDialogScope>();
    if (scope != null) {
      scope.dismiss(result);
      return;
    }
    Navigator.maybeOf(context)?.maybePop(result);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orionTheme = OrionTheme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    final OrionDialogTheme dialogTheme =
        theme.extension<OrionDialogTheme>() ?? OrionDialogTheme.fallback;
    final _OrionDialogScope? scope = _OrionDialogScope.maybeOf(context);
    final OrionDialogStyle resolvedStyle = OrionDialogPresets.resolve(
      scheme: scheme,
    ).merge(dialogTheme.defaultStyle).merge(scope?.routeStyle).merge(style);

    final BorderRadius radius =
        resolvedStyle.borderRadius ??
        BorderRadius.circular(OrionRadii.radius24);
    final Color bg = resolvedStyle.backgroundColor ?? scheme.surfaceContainer;
    final double borderWidth = resolvedStyle.borderWidth ?? 1.0;
    final bool frosted = resolvedStyle.frosted ?? false;
    final double contentSpacing = resolvedStyle.contentSpacing ?? 16.0;
    final TextAlign textAlign = centerContent
        ? TextAlign.center
        : TextAlign.start;

    final Widget surfaceBackdrop = frosted
        ? BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: orionTheme.blurSigma,
              sigmaY: orionTheme.blurSigma,
            ),
            child: ColoredBox(
              color: bg.withValues(alpha: isDark ? 0.72 : 0.78),
            ),
          )
        : ColoredBox(color: bg);

    final TextStyle resolvedTitleStyle =
        (theme.textTheme.titleMedium ?? const TextStyle())
            .copyWith(
              fontSize: 18.0,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
              color: scheme.onSurface,
            )
            .merge(resolvedStyle.titleStyle);

    final TextStyle resolvedDescriptionStyle =
        (theme.textTheme.bodyMedium ?? const TextStyle())
            .copyWith(height: 1.45, color: scheme.onSurfaceVariant)
            .merge(resolvedStyle.descriptionStyle);

    final List<Widget> scrollableItems = <Widget>[];

    // Icon slot
    if (icon != null) {
      scrollableItems.add(
        Padding(
          padding: EdgeInsets.only(bottom: contentSpacing * 0.75),
          child: Align(
            alignment: centerContent
                ? Alignment.center
                : AlignmentDirectional.centerStart,
            child: icon,
          ),
        ),
      );
    }

    // Title slot
    if (title != null) {
      EdgeInsetsGeometry titlePadding = EdgeInsets.zero;
      if (showCloseButton && icon == null) {
        titlePadding = centerContent
            ? const EdgeInsets.symmetric(horizontal: 28.0)
            : const EdgeInsetsDirectional.only(end: 32.0);
      }
      scrollableItems.add(
        Padding(
          padding: titlePadding,
          child: Text(title!, textAlign: textAlign, style: resolvedTitleStyle),
        ),
      );
    }

    // Description slot
    if (description != null) {
      scrollableItems.add(
        Padding(
          padding: EdgeInsets.only(top: title != null ? 8.0 : 0.0),
          child: Text(
            description!,
            textAlign: textAlign,
            style: resolvedDescriptionStyle,
          ),
        ),
      );
    }

    // Custom content slot
    if (content != null) {
      scrollableItems.add(
        Padding(
          padding: EdgeInsets.only(
            top: (title != null || description != null) ? contentSpacing : 0.0,
          ),
          child: content!,
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
          border: borderWidth <= 0
              ? null
              : Border.all(
                  color: resolvedStyle.borderColor ?? scheme.outlineVariant,
                  width: borderWidth,
                ),
          boxShadow: resolvedStyle.shadow ?? OrionThemeData.defaultShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(
            type: MaterialType.transparency,
            child: Stack(
              children: <Widget>[
                Positioned.fill(child: surfaceBackdrop),
                Padding(
                  padding:
                      resolvedStyle.padding ??
                      const EdgeInsets.all(OrionSpacing.space24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      if (scrollableItems.isNotEmpty)
                        Flexible(
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: scrollableItems,
                            ),
                          ),
                        ),
                      if (actions.isNotEmpty)
                        Padding(
                          padding: EdgeInsets.only(
                            top: scrollableItems.isNotEmpty
                                ? contentSpacing * 1.25
                                : 0.0,
                          ),
                          child: _buildActionsLayout(
                            context,
                            scheme,
                            resolvedStyle,
                          ),
                        ),
                    ],
                  ),
                ),
                if (showCloseButton)
                  PositionedDirectional(
                    top: 10.0,
                    end: 10.0,
                    child: _DialogCloseButton(
                      onPressed:
                          onClose ??
                          () => OrionDialog.dismissOf<Object?>(context),
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
        actions.length > 2 ||
            actions.any(
              (OrionDialogAction a) =>
                  a.label.length > 13 ||
                  (a.leading != null && a.label.length > 10),
            ),
    };

    if (useVertical) {
      // In vertical stacked layouts, place the primary/destructive CTA above a
      // leading cancel action when given a standard 2-button [cancel, confirm]
      // pair.
      final List<OrionDialogAction> ordered =
          actions.length == 2 &&
              actions.first.variant == OrionDialogActionVariant.cancel &&
              actions.last.variant != OrionDialogActionVariant.cancel
          ? <OrionDialogAction>[actions.last, actions.first]
          : actions;

      final List<Widget> actionWidgets = <Widget>[];
      for (int i = 0; i < ordered.length; i++) {
        if (i > 0) {
          actionWidgets.add(SizedBox(height: spacing));
        }
        actionWidgets.add(
          _buildActionButton(
            context,
            ordered[i],
            scheme,
            isExpanded: true,
            isVertical: true,
          ),
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
          child: _buildActionButton(
            context,
            actions[i],
            scheme,
            isExpanded: true,
            isVertical: false,
          ),
        ),
      );
    }
    return Row(mainAxisSize: MainAxisSize.max, children: actionWidgets);
  }

  Widget _buildActionButton(
    BuildContext context,
    OrionDialogAction action,
    ColorScheme scheme, {
    required bool isExpanded,
    required bool isVertical,
  }) {
    final OrionButtonVariant variant = switch (action.variant) {
      OrionDialogActionVariant.primary => OrionButtonVariant.solid,
      OrionDialogActionVariant.secondary => OrionButtonVariant.bordered,
      OrionDialogActionVariant.destructive => OrionButtonVariant.solid,
      OrionDialogActionVariant.cancel =>
        isVertical ? OrionButtonVariant.flat : OrionButtonVariant.bordered,
    };

    OrionButtonStyle? customStyle;
    if (action.variant == OrionDialogActionVariant.destructive) {
      final Color disabledBg = scheme.onSurface.withValues(alpha: 0.12);
      final Color disabledFg = scheme.onSurface.withValues(alpha: 0.38);
      final Color pressedBg = Color.alphaBlend(
        scheme.onError.withValues(alpha: 0.14),
        scheme.error,
      );
      customStyle = OrionButtonStyle(
        background: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.disabled)) {
            return disabledBg;
          }
          if (states.contains(WidgetState.pressed)) {
            return pressedBg;
          }
          return scheme.error;
        }),
        foreground: WidgetStateProperty.resolveWith<Color?>(
          (Set<WidgetState> states) => states.contains(WidgetState.disabled)
              ? disabledFg
              : scheme.onError,
        ),
      );
    }

    VoidCallback? effectiveOnPressed;
    if (action.enabled) {
      if (action.onPressed != null) {
        effectiveOnPressed = action.onPressed;
      } else if (action.variant == OrionDialogActionVariant.cancel) {
        effectiveOnPressed = () => OrionDialog.dismissOf<Object?>(context);
      }
    }

    return OrionButton(
      variant: variant,
      size: OrionButtonSize.medium,
      style: customStyle,
      isExpanded: isExpanded,
      leading: action.leading,
      isLoading: action.isLoading,
      label: action.label,
      loadingLabel: action.loadingLabel,
      onPressed: effectiveOnPressed,
    );
  }
}

class _DialogCloseButton extends StatelessWidget {
  const _DialogCloseButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);

    return Semantics(
      button: true,
      label: 'Close',
      child: Tooltip(
        message: 'Close',
        child: OrionPressable(
          key: orionDialogCloseButtonKey,
          onTap: onPressed,
          pressedScale: 0.92,
          springSpec: orion.pressSpring,
          releaseSpringSpec: orion.releaseSpring,
          hapticType: orion.selectionHaptic,
          child: SizedBox(
            width: OrionSizing.minHitTarget,
            height: OrionSizing.minHitTarget,
            child: Center(
              child: Container(
                width: 30.0,
                height: 30.0,
                decoration: BoxDecoration(
                  color: scheme.onSurface.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.close_rounded,
                  size: 16.0,
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Presents an [OrionDialog] imperatively as a modal route.
///
/// Any [style] passed here configures both the route (barrier color, open and
/// dismiss springs) and automatically propagates as defaults to the descendant
/// [OrionDialog] without needing to pass `style` twice.
///
/// Returns a [Future] resolving to the value passed when the dialog is dismissed.
Future<T?> showOrionDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  OrionDialogStyle? style,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
  RouteSettings? routeSettings,
}) {
  final NavigatorState navigator = Navigator.of(
    context,
    rootNavigator: useRootNavigator,
  );
  final CapturedThemes capturedThemes = InheritedTheme.capture(
    from: context,
    to: navigator.context,
  );
  return navigator.push<T>(
    _OrionDialogRoute<T>(
      capturedThemes: capturedThemes,
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
  bool centerContent = true,
  bool showCloseButton = false,
  OrionDialogActionLayout actionLayout = OrionDialogActionLayout.auto,
  OrionDialogStyle? style,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) async {
  final bool? result = await showOrionDialog<bool>(
    context: context,
    style: style,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext dialogContext) {
      return OrionDialog(
        icon: icon,
        title: title,
        description: message,
        centerContent: centerContent,
        showCloseButton: showCloseButton,
        onClose: () => OrionDialog.dismissOf<bool>(dialogContext, false),
        actionLayout: actionLayout,
        actions: <OrionDialogAction>[
          OrionDialogAction.cancel(
            label: cancelLabel,
            onPressed: () => OrionDialog.dismissOf<bool>(dialogContext, false),
          ),
          if (isDestructive)
            OrionDialogAction.destructive(
              label: confirmLabel,
              onPressed: () => OrionDialog.dismissOf<bool>(dialogContext, true),
            )
          else
            OrionDialogAction.primary(
              label: confirmLabel,
              onPressed: () => OrionDialog.dismissOf<bool>(dialogContext, true),
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
  bool centerContent = true,
  bool showCloseButton = false,
  OrionDialogStyle? style,
  bool barrierDismissible = true,
  bool useRootNavigator = true,
}) {
  return showOrionDialog<void>(
    context: context,
    style: style,
    barrierDismissible: barrierDismissible,
    useRootNavigator: useRootNavigator,
    builder: (BuildContext dialogContext) {
      return OrionDialog(
        icon: icon,
        title: title,
        description: message,
        centerContent: centerContent,
        showCloseButton: showCloseButton,
        onClose: () => OrionDialog.dismissOf<void>(dialogContext),
        actions: <OrionDialogAction>[
          OrionDialogAction.primary(
            label: actionLabel,
            onPressed: () => OrionDialog.dismissOf<void>(dialogContext),
          ),
        ],
      );
    },
  );
}

class _OrionDialogScope extends InheritedWidget {
  const _OrionDialogScope({
    required this.dismiss,
    required this.routeStyle,
    required super.child,
  });

  final void Function(Object? result) dismiss;
  final OrionDialogStyle? routeStyle;

  static _OrionDialogScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_OrionDialogScope>();
  }

  @override
  bool updateShouldNotify(_OrionDialogScope oldWidget) =>
      routeStyle != oldWidget.routeStyle;
}

class _OrionDialogRoute<T> extends PopupRoute<T> {
  _OrionDialogRoute({
    required this.capturedThemes,
    required this.pageBuilder,
    required this.style,
    required this.isBarrierDismissible,
    super.settings,
  });

  final CapturedThemes capturedThemes;
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
    return capturedThemes.wrap(
      _OrionDialogOverlay<T>(
        route: this,
        style: style,
        barrierDismissible: isBarrierDismissible,
        builder: (BuildContext dialogContext) =>
            pageBuilder(dialogContext, animation, secondaryAnimation),
      ),
    );
  }
}

class _OrionDialogOverlay<T> extends StatefulWidget {
  const _OrionDialogOverlay({
    required this.route,
    required this.style,
    required this.barrierDismissible,
    required this.builder,
  });

  final _OrionDialogRoute<T> route;
  final OrionDialogStyle? style;
  final bool barrierDismissible;
  final WidgetBuilder builder;

  @override
  State<_OrionDialogOverlay<T>> createState() => _OrionDialogOverlayState<T>();
}

class _OrionDialogOverlayState<T> extends State<_OrionDialogOverlay<T>>
    with SingleTickerProviderStateMixin {
  late final OrionSpringDriver _driver;
  late final Widget _scopedChild;
  bool _isClosing = false;
  T? _dismissResult;
  OrionHapticType _openHaptic = OrionHapticType.selectionClick;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec:
          widget.style?.springSpec ?? OrionDialogPresets.defaultOpenSpring,
    );
    _driver.addStatusListener(_onDriverStatus);
    _scopedChild = _OrionDialogScope(
      dismiss: _dismissFromScope,
      routeStyle: widget.style,
      child: Builder(builder: widget.builder),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        if (_driver.reducedMotion) {
          _driver.jumpTo(1.0);
        } else {
          _driver.retarget(1.0);
          OrionHaptics.trigger(_openHaptic);
        }
      }
    });
  }

  OrionDialogStyle _resolveStyle(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OrionDialogTheme dialogTheme =
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
    _openHaptic = OrionTheme.of(context).selectionHaptic;

    final OrionDialogStyle resolvedStyle = _resolveStyle(context);
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

  void _dismissFromScope(Object? result) {
    if (result == null) {
      _dismiss();
    } else {
      _dismiss(result as T);
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

    final OrionDialogStyle resolvedStyle = _resolveStyle(context);
    _driver.springSpec =
        resolvedStyle.dismissSpringSpec ??
        OrionDialogPresets.defaultDismissSpring;
    _driver.retarget(0.0);
  }

  @override
  Widget build(BuildContext context) {
    final OrionDialogStyle resolvedStyle = _resolveStyle(context);
    final Color barrierColor =
        resolvedStyle.barrierColor ?? const Color(0x73000000);
    final EdgeInsets viewInsets = MediaQuery.viewInsetsOf(context);
    final bool reducedMotion = _driver.reducedMotion;

    return PopScope<T>(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, T? result) {
        if (didPop) return;
        // Block system back dismissal (result == null) when non-dismissible.
        if (!widget.barrierDismissible && result == null) {
          return;
        }
        _dismiss(result);
      },
      child: FocusScope(
        autofocus: true,
        onKeyEvent: (FocusNode node, KeyEvent event) {
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
          child: _scopedChild,
          builder: (BuildContext context, Widget? child) {
            final double progress = _driver.value;
            final double clamped = progress.clamp(0.0, 1.0);
            final double scale = 0.94 + (0.06 * progress);
            final double opacity = _isClosing
                ? clamped
                : (progress * 2.0).clamp(0.0, 1.0);
            final double translateY = (1.0 - clamped) * 6.0;

            return Stack(
              children: <Widget>[
                // Backdrop Scrim
                Positioned.fill(
                  child: Semantics(
                    label: widget.route.barrierLabel,
                    button: widget.barrierDismissible,
                    excludeSemantics: !widget.barrierDismissible,
                    onTap: widget.barrierDismissible ? () => _dismiss() : null,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: widget.barrierDismissible
                          ? () => _dismiss()
                          : null,
                      child: ColoredBox(
                        color: barrierColor.withValues(
                          alpha: barrierColor.a * clamped,
                        ),
                      ),
                    ),
                  ),
                ),

                // Centered Dialog Surface with keyboard inset lift & safe area
                Positioned.fill(
                  child: AnimatedPadding(
                    padding: viewInsets,
                    duration: reducedMotion
                        ? Duration.zero
                        : const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    child: SafeArea(
                      minimum: const EdgeInsets.symmetric(
                        horizontal: 24.0,
                        vertical: 24.0,
                      ),
                      child: Center(
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
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
