import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/tabs/orion_tab.dart';
import 'package:orion_ui/src/components/tabs/orion_tabs_controller.dart';
import 'package:orion_ui/src/components/tabs/orion_tabs_presets.dart';
import 'package:orion_ui/src/components/tabs/orion_tabs_style.dart';
import 'package:orion_ui/src/components/tabs/orion_tabs_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Top-level view navigation tabs powered by continuous spring physics.
///
/// Use [OrionTabs] for view and content navigation (`underline` with baseline
/// hairline divider, or floating `pill` category strips) supporting variable
/// intrinsic tab widths, horizontal scrolling with automatic edge fades and
/// auto-centering, velocity-driven kinetic indicator stretching, and real-time
/// bidirectional `PageView` synchronization. For compact 2–4 option equal-width
/// mode switchers inside cards or toolbars, use `OrionSegmentedControl`.
class OrionTabs<T> extends StatefulWidget {
  const OrionTabs({
    super.key,
    required this.tabs,
    this.value,
    this.onChanged,
    this.controller,
    this.pageController,
    this.variant = OrionTabsVariant.underline,
    this.distribution = OrionTabsDistribution.intrinsic,
    this.showDivider,
    this.fadeEdges = true,
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The list of tabs to display.
  final List<OrionTab<T>> tabs;

  /// The currently selected tab value.
  final T? value;

  /// Callback when a tab is selected. Retapping the already-selected tab does
  /// not fire this callback.
  final ValueChanged<T>? onChanged;

  /// Optional programmatic controller.
  final OrionTabsController<T>? controller;

  /// Optional [PageController] for bidirectional swipe synchronization.
  final PageController? pageController;

  /// Visual treatment of the active indicator (`underline` or `pill`).
  final OrionTabsVariant variant;

  /// Sizing and layout distribution (intrinsic scrollable vs. equal division).
  final OrionTabsDistribution distribution;

  /// Whether to paint the baseline hairline divider beneath
  /// [OrionTabsVariant.underline]. Defaults to `true` for `underline` and
  /// `false` for `pill`.
  final bool? showDivider;

  /// Whether to smoothly fade overflowing scroll edges on long tab strips.
  /// Defaults to `true` and has zero overhead when all tabs fit.
  final bool fadeEdges;

  /// Instance styling overrides.
  final OrionTabsStyle? style;

  /// Optional focus node for keyboard selection (`ArrowLeft`, `ArrowRight`,
  /// `Home`, `End`).
  final FocusNode? focusNode;

  /// Whether the control requests focus on first build.
  final bool autofocus;

  @override
  State<OrionTabs<T>> createState() => OrionTabsState<T>();
}

class OrionTabsState<T> extends State<OrionTabs<T>>
    with SingleTickerProviderStateMixin {
  late final OrionSpringDriver _driver;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  final ValueNotifier<(bool, bool)> _edgeFadeNotifier =
      ValueNotifier<(bool, bool)>((false, false));

  OrionTabsController<T>? _internalController;
  OrionTabsController<T> get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionTabsController<T>());

  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  bool _focused = false;
  T? _selectedValue;
  int? _lastPageIndex;
  int _programmaticPageAnimCount = 0;
  bool _isProgrammaticJump = false;
  bool _didInitialAutoCenter = false;
  int? _pendingAutoCenterIndex;
  bool _pendingAutoCenterImmediate = false;
  List<Rect> _cachedTabRects = const <Rect>[];

  /// The spring behind the indicator, exposed so tests can assert continuity.
  @visibleForTesting
  late final OrionSpringDriver indicatorDriver = _driver;

  int _indexOf(T? val) {
    if (val == null) return -1;
    for (int i = 0; i < widget.tabs.length; i++) {
      if (widget.tabs[i].value == val) return i;
    }
    return -1;
  }

  int get _currentIndex {
    final int idx = _indexOf(_selectedValue);
    return idx >= 0 ? idx : 0;
  }

  @override
  void initState() {
    super.initState();
    T? initial = widget.value ?? widget.controller?.value;
    if (initial == null && widget.tabs.isNotEmpty) {
      final int initialIdx = widget.pageController != null
          ? widget.pageController!.initialPage.clamp(0, widget.tabs.length - 1)
          : 0;
      initial = widget.tabs[initialIdx].value;
    }
    _selectedValue = initial;
    _lastPageIndex = _currentIndex;

    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _currentIndex.toDouble(),
      springSpec:
          widget.style?.springSpec ?? OrionTabsPresets.defaultSpringSpec,
    );
    _attachController();
    widget.pageController?.addListener(_handlePageScroll);
    _scrollController.addListener(_updateEdgeFades);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.reducedMotion = reduced;

    final OrionTabsStyle resolved = _resolveStyle(Theme.of(context));
    _driver.springSpec =
        resolved.springSpec ?? OrionTabsPresets.defaultSpringSpec;
    _scheduleEdgeFadeCheck();
  }

  @override
  void didUpdateWidget(OrionTabs<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
    if (widget.pageController != oldWidget.pageController) {
      oldWidget.pageController?.removeListener(_handlePageScroll);
      widget.pageController?.addListener(_handlePageScroll);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode != null) {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
    }
    if (widget.value != oldWidget.value && widget.value != null) {
      final int newIdx = _indexOf(widget.value);
      final bool alreadySelected = newIdx == _currentIndex;
      _selectedValue = widget.value;
      if (newIdx >= 0 && !alreadySelected) {
        _animateToIndex(newIdx);
      }
    }

    // A shrunk list cannot strand the selection on a tab that no longer exists.
    if (widget.tabs.isNotEmpty && _indexOf(_selectedValue) < 0) {
      final int fallbackIndex = math.min(_currentIndex, widget.tabs.length - 1);
      _animateToIndex(fallbackIndex);
    }

    final OrionTabsStyle resolved = _resolveStyle(Theme.of(context));
    _driver.springSpec =
        resolved.springSpec ?? OrionTabsPresets.defaultSpringSpec;

    if (widget.fadeEdges != oldWidget.fadeEdges ||
        widget.tabs.length != oldWidget.tabs.length ||
        widget.distribution != oldWidget.distribution) {
      _scheduleEdgeFadeCheck();
    }
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_handlePageScroll);
    _scrollController.removeListener(_updateEdgeFades);
    _effectiveController.detach();
    _internalController?.dispose();
    _ownedFocusNode?.dispose();
    _scrollController.dispose();
    _edgeFadeNotifier.dispose();
    _driver.dispose();
    super.dispose();
  }

  void _scheduleEdgeFadeCheck() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _updateEdgeFades();
      }
    });
  }

  void _updateEdgeFades() {
    if (!mounted) return;
    if (!widget.fadeEdges || !_scrollController.hasClients) {
      if (_edgeFadeNotifier.value != (false, false)) {
        _edgeFadeNotifier.value = (false, false);
      }
      return;
    }
    final ScrollPosition pos = _scrollController.position;
    if (!pos.hasContentDimensions || pos.maxScrollExtent <= 1.0) {
      if (_edgeFadeNotifier.value != (false, false)) {
        _edgeFadeNotifier.value = (false, false);
      }
      return;
    }
    final bool canStart = pos.pixels > 1.0;
    final bool canEnd = pos.pixels < pos.maxScrollExtent - 1.0;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;
    final (bool, bool) next = isRtl ? (canEnd, canStart) : (canStart, canEnd);
    if (_edgeFadeNotifier.value != next) {
      _edgeFadeNotifier.value = next;
    }
  }

  void _attachController() {
    _effectiveController.attach(
      onAnimateTo: (T val) {
        final int idx = _indexOf(val);
        if (idx >= 0) {
          _selectedValue = val;
          _animateToIndex(idx);
        }
      },
      onJumpTo: (T val) {
        final int idx = _indexOf(val);
        if (idx >= 0) {
          _selectedValue = val;
          _jumpToIndex(idx);
        }
      },
    );
    _syncControllerSelection(_currentIndex);
  }

  void _syncControllerSelection(int index) {
    if (index >= 0 && index < widget.tabs.length) {
      _selectedValue = widget.tabs[index].value;
      _effectiveController.updateSelection(
        value: widget.tabs[index].value,
        index: index,
        length: widget.tabs.length,
      );
      if (mounted) setState(() {});
    }
  }

  void _handlePageScroll() {
    final PageController? pager = widget.pageController;
    if (pager == null || !pager.hasClients || pager.page == null) return;
    if (widget.tabs.isEmpty) return;

    final double clampedPage = pager.page!.clamp(
      0.0,
      (widget.tabs.length - 1).toDouble(),
    );

    if (_driver.reducedMotion) {
      _driver.jumpTo(clampedPage.roundToDouble());
    } else {
      _driver.jumpTo(clampedPage);
    }

    final bool isProgrammatic =
        _programmaticPageAnimCount > 0 || _isProgrammaticJump;
    final bool userDriven =
        !isProgrammatic ||
        pager.position.userScrollDirection != ScrollDirection.idle;

    final int targetPage = clampedPage.round();
    if (targetPage != _lastPageIndex &&
        targetPage >= 0 &&
        targetPage < widget.tabs.length) {
      _lastPageIndex = targetPage;
      _syncControllerSelection(targetPage);
      if (userDriven) {
        widget.onChanged?.call(widget.tabs[targetPage].value);
      }
      _autoCenterActiveTab(targetPage);
    }
  }

  void _animateToIndex(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= widget.tabs.length) return;
    _lastPageIndex = targetIndex;

    if (widget.pageController != null && widget.pageController!.hasClients) {
      _syncControllerSelection(targetIndex);
      _autoCenterActiveTab(targetIndex);
      if (_driver.reducedMotion) {
        _isProgrammaticJump = true;
        try {
          widget.pageController!.jumpToPage(targetIndex);
        } finally {
          _isProgrammaticJump = false;
        }
        _driver.jumpTo(targetIndex.toDouble());
      } else {
        _programmaticPageAnimCount++;
        widget.pageController!
            .animateToPage(
              targetIndex,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
            )
            .whenComplete(() {
              if (mounted) {
                _programmaticPageAnimCount = math.max(
                  0,
                  _programmaticPageAnimCount - 1,
                );
              }
            });
      }
      return;
    }

    final OrionTabsStyle resolved = _resolveStyle(Theme.of(context));
    _driver.springSpec =
        resolved.springSpec ?? OrionTabsPresets.defaultSpringSpec;

    if (_driver.reducedMotion) {
      _driver.jumpTo(targetIndex.toDouble());
    } else {
      _driver.retarget(targetIndex.toDouble());
    }

    _syncControllerSelection(targetIndex);
    _autoCenterActiveTab(targetIndex);
  }

  void _jumpToIndex(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= widget.tabs.length) return;
    _lastPageIndex = targetIndex;

    if (widget.pageController != null && widget.pageController!.hasClients) {
      _syncControllerSelection(targetIndex);
      _autoCenterActiveTab(targetIndex, immediate: true);
      _isProgrammaticJump = true;
      try {
        widget.pageController!.jumpToPage(targetIndex);
      } finally {
        _isProgrammaticJump = false;
      }
      _driver.jumpTo(targetIndex.toDouble());
      return;
    }

    _driver.jumpTo(targetIndex.toDouble());
    _syncControllerSelection(targetIndex);
    _autoCenterActiveTab(targetIndex, immediate: true);
  }

  void _select(int index, {required bool haptic}) {
    if (index < 0 || index >= widget.tabs.length) return;
    if (index == _currentIndex) return;
    final OrionTab<T> tab = widget.tabs[index];
    if (tab.disabled) return;

    if (haptic) {
      final OrionTabsStyle style = _resolveStyle(Theme.of(context));
      final OrionHapticType cue =
          style.hapticType ?? OrionHapticType.selectionClick;
      if (cue != OrionHapticType.none) {
        OrionHaptics.trigger(cue);
      }
    }

    _animateToIndex(index);
    widget.onChanged?.call(tab.value);
  }

  int? _findBoundaryEnabled({required bool fromStart}) {
    if (fromStart) {
      for (int i = 0; i < widget.tabs.length; i++) {
        if (!widget.tabs[i].disabled) return i;
      }
    } else {
      for (int i = widget.tabs.length - 1; i >= 0; i--) {
        if (!widget.tabs[i].disabled) return i;
      }
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (widget.tabs.isEmpty) return KeyEventResult.ignored;

    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey key = event.logicalKey;

    int? targetIndex;
    if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft) {
      final int delta = key == LogicalKeyboardKey.arrowRight
          ? (rtl ? -1 : 1)
          : (rtl ? 1 : -1);
      int next = _currentIndex + delta;
      while (next >= 0 &&
          next < widget.tabs.length &&
          widget.tabs[next].disabled) {
        next += delta;
      }
      if (next >= 0 && next < widget.tabs.length) {
        targetIndex = next;
      }
    } else if (key == LogicalKeyboardKey.home) {
      targetIndex = _findBoundaryEnabled(fromStart: true);
    } else if (key == LogicalKeyboardKey.end) {
      targetIndex = _findBoundaryEnabled(fromStart: false);
    } else {
      return KeyEventResult.ignored;
    }

    if (targetIndex != null) {
      _select(targetIndex, haptic: false);
    }
    return KeyEventResult.handled;
  }

  void _autoCenterActiveTab(int index, {bool immediate = false}) {
    if (index < 0 || index >= widget.tabs.length) return;
    if (!_scrollController.hasClients ||
        _cachedTabRects.length != widget.tabs.length ||
        index >= _cachedTabRects.length ||
        !_scrollController.position.hasContentDimensions) {
      _pendingAutoCenterIndex = index;
      _pendingAutoCenterImmediate = immediate;
      return;
    }
    _pendingAutoCenterIndex = null;
    final double maxScroll = _scrollController.position.maxScrollExtent;
    if (maxScroll <= 0.0) return;

    final Rect tabRect = _cachedTabRects[index];
    final double viewportWidth = _scrollController.position.viewportDimension;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    final double totalWidth = maxScroll + viewportWidth;
    final double startDistance = isRtl
        ? (totalWidth - tabRect.center.dx)
        : tabRect.center.dx;

    final double targetOffset = (startDistance - (viewportWidth / 2.0)).clamp(
      0.0,
      maxScroll,
    );

    if (immediate || _driver.reducedMotion) {
      _scrollController.jumpTo(targetOffset);
    } else {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
      );
    }
  }

  OrionTabsStyle _resolveStyle(ThemeData theme) {
    final OrionTabsTheme tabsTheme =
        theme.extension<OrionTabsTheme>() ?? OrionTabsTheme.fallback;
    final OrionTabsStyle defaults = OrionTabsPresets.resolve(
      scheme: theme.colorScheme,
      variant: widget.variant,
    );
    return defaults.merge(tabsTheme.defaultStyle).merge(widget.style);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionTabsStyle style = _resolveStyle(theme);
    final TextDirection textDirection = Directionality.of(context);
    final bool effectiveShowDivider =
        widget.showDivider ?? (widget.variant == OrionTabsVariant.underline);
    final double edgeFadeWidth = math.max(0.0, style.edgeFadeWidth ?? 28.0);
    final BorderRadius? trackRadius = style.trackBorderRadius;
    final bool hasTrackBg =
        style.trackColor != null && style.trackColor != Colors.transparent;
    final Color focusRing =
        style.focusRingColor ?? scheme.primary.withValues(alpha: 0.5);

    final List<Widget> tabWidgets = <Widget>[
      for (int i = 0; i < widget.tabs.length; i++)
        _OrionTabItem<T>(
          tab: widget.tabs[i],
          index: i,
          isSelected: i == _currentIndex,
          driver: _driver,
          variant: widget.variant,
          style: style,
          scheme: scheme,
          onTap: () => _select(i, haptic: true),
        ),
    ];

    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      onKeyEvent: _onKey,
      child: FocusableActionDetector(
        focusNode: _focusNode,
        autofocus: widget.autofocus,
        onShowFocusHighlight: (bool focused) {
          if (focused != _focused) {
            setState(() => _focused = focused);
          }
        },
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final double availableWidth = constraints.maxWidth;

            final Widget tabsLayout = _OrionTabsRenderWidget(
              driver: _driver,
              tabsCount: widget.tabs.length,
              distribution: widget.distribution,
              variant: widget.variant,
              style: style,
              scheme: scheme,
              textDirection: textDirection,
              availableWidth: availableWidth,
              tabSpacing: style.tabSpacing ?? OrionSpacing.space4,
              trackPadding: (style.trackPadding ?? EdgeInsets.zero).resolve(
                textDirection,
              ),
              onLayoutResolved: (List<Rect> rects) {
                _cachedTabRects = rects;
                if (!_didInitialAutoCenter && rects.isNotEmpty) {
                  _didInitialAutoCenter = true;
                  if (_currentIndex > 0) {
                    _pendingAutoCenterIndex ??= _currentIndex;
                    _pendingAutoCenterImmediate = true;
                  }
                }
                if (_pendingAutoCenterIndex != null &&
                    rects.length == widget.tabs.length) {
                  final int pendingIdx = _pendingAutoCenterIndex!;
                  final bool pendingImmediate = _pendingAutoCenterImmediate;
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted && _pendingAutoCenterIndex == pendingIdx) {
                      _autoCenterActiveTab(
                        pendingIdx,
                        immediate: pendingImmediate,
                      );
                    }
                  });
                }
                _scheduleEdgeFadeCheck();
              },
              children: tabWidgets,
            );

            Widget contentStrip = SingleChildScrollView(
              key: _scrollViewKey,
              controller: _scrollController,
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: tabsLayout,
            );

            if (widget.fadeEdges && edgeFadeWidth > 0.0) {
              contentStrip = AnimatedBuilder(
                animation: _edgeFadeNotifier,
                child: contentStrip,
                builder: (BuildContext context, Widget? child) {
                  final (bool fadeLeft, bool fadeRight) =
                      _edgeFadeNotifier.value;
                  if (!fadeLeft && !fadeRight) {
                    return child!;
                  }
                  return ShaderMask(
                    blendMode: BlendMode.dstIn,
                    shaderCallback: (Rect bounds) {
                      final double w = bounds.width > 0 ? bounds.width : 1.0;
                      final double stop = (edgeFadeWidth / w).clamp(0.0, 0.25);
                      return LinearGradient(
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                        colors: <Color>[
                          fadeLeft ? Colors.transparent : Colors.white,
                          Colors.white,
                          Colors.white,
                          fadeRight ? Colors.transparent : Colors.white,
                        ],
                        stops: <double>[0.0, stop, 1.0 - stop, 1.0],
                      ).createShader(bounds);
                    },
                    child: child,
                  );
                },
              );
            }

            final Color? dividerColor =
                effectiveShowDivider &&
                    widget.variant == OrionTabsVariant.underline
                ? (style.dividerColor ?? scheme.outlineVariant)
                : null;
            final double dividerThickness = style.dividerThickness ?? 1.0;

            if (dividerColor != null &&
                dividerColor != Colors.transparent &&
                dividerThickness > 0) {
              contentStrip = DecoratedBox(
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: dividerColor,
                      width: dividerThickness,
                    ),
                  ),
                ),
                child: contentStrip,
              );
            }

            if (trackRadius != null && trackRadius != BorderRadius.zero) {
              contentStrip = ClipRRect(
                borderRadius: trackRadius,
                child: contentStrip,
              );
            }

            return DecoratedBox(
              decoration: BoxDecoration(
                color: hasTrackBg ? style.trackColor : null,
                borderRadius: trackRadius,
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius:
                      trackRadius ?? BorderRadius.circular(OrionRadii.radius8),
                  border: _focused
                      ? Border.all(
                          color: focusRing,
                          width: 2.0,
                          strokeAlign: BorderSide.strokeAlignInside,
                        )
                      : null,
                ),
                child: contentStrip,
              ),
            );
          },
        ),
      ),
    );
  }
}

class _OrionTabItem<T> extends StatefulWidget {
  const _OrionTabItem({
    required this.tab,
    required this.index,
    required this.isSelected,
    required this.driver,
    required this.variant,
    required this.style,
    required this.scheme,
    required this.onTap,
  });

  final OrionTab<T> tab;
  final int index;
  final bool isSelected;
  final OrionSpringDriver driver;
  final OrionTabsVariant variant;
  final OrionTabsStyle style;
  final ColorScheme scheme;
  final VoidCallback onTap;

  @override
  State<_OrionTabItem<T>> createState() => _OrionTabItemState<T>();
}

class _OrionTabItemState<T> extends State<_OrionTabItem<T>> {
  bool _hovered = false;

  @override
  void didUpdateWidget(_OrionTabItem<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.tab.disabled && _hovered) {
      _hovered = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final OrionTab<T> tab = widget.tab;
    final OrionTabsStyle style = widget.style;
    final ColorScheme scheme = widget.scheme;
    final bool enabled = !tab.disabled;
    final bool showHover = _hovered && enabled && !widget.isSelected;

    final Color activeColor =
        style.activeLabelColor ??
        (widget.variant == OrionTabsVariant.pill
            ? scheme.onPrimary
            : scheme.primary);
    final Color inactiveColor =
        style.inactiveLabelColor ?? scheme.onSurfaceVariant;
    final Color hoverLabelColor =
        style.hoverLabelColor ??
        Color.lerp(inactiveColor, scheme.onSurface, 0.55)!;
    final Color disabledColor =
        style.disabledLabelColor ?? scheme.onSurface.withValues(alpha: 0.38);
    final Color hoverBg =
        style.hoverColor ??
        scheme.onSurface.withValues(
          alpha: scheme.brightness == Brightness.dark ? 0.06 : 0.04,
        );
    final TextStyle baseTextStyle =
        style.labelStyle ??
        const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600);
    final double iconSize = style.iconSize ?? 18.0;

    final EdgeInsetsGeometry effectivePadding =
        style.tabPadding ??
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space16,
          vertical: OrionSpacing.space12,
        );

    final BorderRadius hoverRadius = widget.variant == OrionTabsVariant.pill
        ? (style.indicatorRadius ??
              BorderRadius.circular(OrionRadii.radiusPill))
        : BorderRadius.circular(OrionRadii.radius8);

    // Build icon + label ink inside AnimatedBuilder so ink cross-fades cleanly
    // with the moving indicator / PageView drag, while keeping tab.badge
    // outside AnimatedBuilder so badge widgets never rebuild on spring ticks.
    final Widget inkContent = AnimatedBuilder(
      animation: widget.driver,
      child: tab.icon,
      builder: (BuildContext context, Widget? iconChild) {
        final Color liveColor;
        if (!enabled) {
          liveColor = disabledColor;
        } else {
          final double proximity =
              (1.0 - (widget.driver.value - widget.index).abs()).clamp(
                0.0,
                1.0,
              );
          final Color restColor = showHover ? hoverLabelColor : inactiveColor;
          liveColor = Color.lerp(restColor, activeColor, proximity)!;
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (iconChild != null) ...<Widget>[
              IconTheme.merge(
                data: IconThemeData(color: liveColor, size: iconSize),
                child: iconChild,
              ),
              const SizedBox(width: OrionSpacing.space8),
            ],
            Text(
              tab.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: baseTextStyle.copyWith(color: liveColor),
            ),
          ],
        );
      },
    );

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        inkContent,
        if (tab.badge != null) ...<Widget>[
          const SizedBox(width: OrionSpacing.space8),
          tab.badge!,
        ],
      ],
    );

    Widget result = Semantics(
      container: true,
      button: true,
      selected: widget.isSelected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      excludeSemantics: tab.semanticLabel != null,
      label: tab.semanticLabel,
      child: MouseRegion(
        cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
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
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minHeight: OrionSizing.minHitTarget,
          ),
          child: OrionPressable(
            onTap: enabled ? widget.onTap : null,
            pressedScale: style.pressedScale ?? 0.98,
            springSpec:
                style.pressSpring ??
                const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.85),
            releaseSpringSpec: style.releaseSpring,
            hapticType: OrionHapticType.none, // Managed in _select
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: showHover ? hoverBg : null,
                borderRadius: hoverRadius,
              ),
              child: Padding(padding: effectivePadding, child: content),
            ),
          ),
        ),
      ),
    );

    if (tab.tooltip != null && tab.tooltip!.isNotEmpty) {
      result = Tooltip(message: tab.tooltip!, child: result);
    }

    return result;
  }
}

/// Custom multi-child RenderObject that lays out tabs in a single pass on Frame 0
/// and paints the kinetic stretching indicator behind them with zero widget
/// rebuilds during spring flight.
class _OrionTabsRenderWidget extends MultiChildRenderObjectWidget {
  const _OrionTabsRenderWidget({
    required this.driver,
    required this.tabsCount,
    required this.distribution,
    required this.variant,
    required this.style,
    required this.scheme,
    required this.textDirection,
    required this.availableWidth,
    required this.tabSpacing,
    required this.trackPadding,
    required this.onLayoutResolved,
    required super.children,
  });

  final OrionSpringDriver driver;
  final int tabsCount;
  final OrionTabsDistribution distribution;
  final OrionTabsVariant variant;
  final OrionTabsStyle style;
  final ColorScheme scheme;
  final TextDirection textDirection;
  final double availableWidth;
  final double tabSpacing;
  final EdgeInsets trackPadding;
  final ValueChanged<List<Rect>> onLayoutResolved;

  @override
  _RenderOrionTabs createRenderObject(BuildContext context) {
    return _RenderOrionTabs(
      driver: driver,
      tabsCount: tabsCount,
      distribution: distribution,
      variant: variant,
      style: style,
      scheme: scheme,
      textDirection: textDirection,
      availableWidth: availableWidth,
      tabSpacing: tabSpacing,
      trackPadding: trackPadding,
      onLayoutResolved: onLayoutResolved,
    );
  }

  @override
  void updateRenderObject(BuildContext context, _RenderOrionTabs renderObject) {
    renderObject
      ..driver = driver
      ..tabsCount = tabsCount
      ..distribution = distribution
      ..variant = variant
      ..style = style
      ..scheme = scheme
      ..textDirection = textDirection
      ..availableWidth = availableWidth
      ..tabSpacing = tabSpacing
      ..trackPadding = trackPadding
      ..onLayoutResolved = onLayoutResolved;
  }
}

class _OrionTabsParentData extends ContainerBoxParentData<RenderBox> {}

class _RenderOrionTabs extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _OrionTabsParentData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _OrionTabsParentData> {
  _RenderOrionTabs({
    required OrionSpringDriver driver,
    required int tabsCount,
    required OrionTabsDistribution distribution,
    required OrionTabsVariant variant,
    required OrionTabsStyle style,
    required ColorScheme scheme,
    required TextDirection textDirection,
    required double availableWidth,
    required double tabSpacing,
    required EdgeInsets trackPadding,
    required ValueChanged<List<Rect>> onLayoutResolved,
  }) : _driver = driver,
       _tabsCount = tabsCount,
       _distribution = distribution,
       _variant = variant,
       _style = style,
       _scheme = scheme,
       _textDirection = textDirection,
       _availableWidth = availableWidth,
       _tabSpacing = tabSpacing,
       _trackPadding = trackPadding,
       _onLayoutResolved = onLayoutResolved {
    _driver.addListener(markNeedsPaint);
  }

  OrionSpringDriver _driver;
  OrionSpringDriver get driver => _driver;
  set driver(OrionSpringDriver value) {
    if (_driver == value) return;
    _driver.removeListener(markNeedsPaint);
    _driver = value;
    _driver.addListener(markNeedsPaint);
    markNeedsPaint();
  }

  int _tabsCount;
  int get tabsCount => _tabsCount;
  set tabsCount(int value) {
    if (_tabsCount == value) return;
    _tabsCount = value;
    markNeedsLayout();
  }

  OrionTabsDistribution _distribution;
  OrionTabsDistribution get distribution => _distribution;
  set distribution(OrionTabsDistribution value) {
    if (_distribution == value) return;
    _distribution = value;
    markNeedsLayout();
  }

  OrionTabsVariant _variant;
  OrionTabsVariant get variant => _variant;
  set variant(OrionTabsVariant value) {
    if (_variant == value) return;
    _variant = value;
    markNeedsPaint();
  }

  OrionTabsStyle _style;
  OrionTabsStyle get style => _style;
  set style(OrionTabsStyle value) {
    if (_style == value) return;
    _style = value;
    markNeedsPaint();
  }

  ColorScheme _scheme;
  ColorScheme get scheme => _scheme;
  set scheme(ColorScheme value) {
    if (_scheme == value) return;
    _scheme = value;
    markNeedsPaint();
  }

  TextDirection _textDirection;
  TextDirection get textDirection => _textDirection;
  set textDirection(TextDirection value) {
    if (_textDirection == value) return;
    _textDirection = value;
    markNeedsLayout();
  }

  double _availableWidth;
  double get availableWidth => _availableWidth;
  set availableWidth(double value) {
    if (_availableWidth == value) return;
    _availableWidth = value;
    markNeedsLayout();
  }

  double _tabSpacing;
  double get tabSpacing => _tabSpacing;
  set tabSpacing(double value) {
    if (_tabSpacing == value) return;
    _tabSpacing = value;
    markNeedsLayout();
  }

  EdgeInsets _trackPadding;
  EdgeInsets get trackPadding => _trackPadding;
  set trackPadding(EdgeInsets value) {
    if (_trackPadding == value) return;
    _trackPadding = value;
    markNeedsLayout();
  }

  ValueChanged<List<Rect>> _onLayoutResolved;
  ValueChanged<List<Rect>> get onLayoutResolved => _onLayoutResolved;
  set onLayoutResolved(ValueChanged<List<Rect>> value) {
    if (_onLayoutResolved == value) return;
    _onLayoutResolved = value;
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _OrionTabsParentData) {
      child.parentData = _OrionTabsParentData();
    }
  }

  @override
  void dispose() {
    _driver.removeListener(markNeedsPaint);
    super.dispose();
  }

  List<Rect> _tabRects = const <Rect>[];

  @override
  void performLayout() {
    if (childCount == 0 || tabsCount == 0) {
      size = constraints.constrain(
        Size(0.0, constraints.hasBoundedHeight ? constraints.maxHeight : 0.0),
      );
      _tabRects = const <Rect>[];
      onLayoutResolved(_tabRects);
      return;
    }

    final bool isRtl = textDirection == TextDirection.rtl;
    final List<Rect> rects = List<Rect>.filled(tabsCount, Rect.zero);
    double maxHeight = 0.0;

    RenderBox? child = firstChild;
    int i = 0;
    double maxNaturalWidth = 0.0;
    double totalNaturalWidth = trackPadding.horizontal;

    while (child != null && i < tabsCount) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      maxNaturalWidth = math.max(maxNaturalWidth, child.size.width);
      totalNaturalWidth += child.size.width;
      if (i < tabsCount - 1) totalNaturalWidth += tabSpacing;
      if (child.size.height > maxHeight) maxHeight = child.size.height;
      child = (child.parentData! as _OrionTabsParentData).nextSibling;
      i++;
    }

    final double effectiveHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : (maxHeight + trackPadding.vertical);
    final double topOffset = constraints.hasBoundedHeight
        ? math.max(trackPadding.top, (effectiveHeight - maxHeight) / 2.0)
        : trackPadding.top;

    final double boundedContainerWidth = availableWidth.isFinite
        ? availableWidth
        : (constraints.hasBoundedWidth
              ? constraints.maxWidth
              : double.infinity);

    if (distribution == OrionTabsDistribution.equal &&
        !boundedContainerWidth.isInfinite) {
      final double totalAvailableWidth = math.max(
        0.0,
        boundedContainerWidth -
            trackPadding.horizontal -
            (tabSpacing * (tabsCount - 1)),
      );
      final double equalSlotWidth = totalAvailableWidth / tabsCount;

      if (equalSlotWidth >= maxNaturalWidth) {
        double currentX = isRtl
            ? boundedContainerWidth - trackPadding.right - equalSlotWidth
            : trackPadding.left;

        child = firstChild;
        i = 0;
        while (child != null && i < tabsCount) {
          final _OrionTabsParentData bData =
              child.parentData! as _OrionTabsParentData;
          child.layout(
            BoxConstraints.tightFor(width: equalSlotWidth),
            parentUsesSize: true,
          );
          final Offset tabPos = Offset(currentX, topOffset);
          bData.offset = tabPos;
          rects[i] = Rect.fromLTWH(
            currentX,
            topOffset,
            equalSlotWidth,
            maxHeight,
          );
          currentX += isRtl
              ? -(equalSlotWidth + tabSpacing)
              : (equalSlotWidth + tabSpacing);
          child = bData.nextSibling;
          i++;
        }

        size = constraints.constrain(
          Size(boundedContainerWidth, effectiveHeight),
        );
        _tabRects = rects;
        onLayoutResolved(rects);
        return;
      }
    }

    // Intrinsic or overflowing layout: preserve natural widths and scroll cleanly.
    double currentX = isRtl
        ? totalNaturalWidth - trackPadding.right
        : trackPadding.left;

    child = firstChild;
    i = 0;
    while (child != null && i < tabsCount) {
      final _OrionTabsParentData bData =
          child.parentData! as _OrionTabsParentData;
      final double childWidth = child.size.width;
      final double tabLeft = isRtl ? currentX - childWidth : currentX;
      final Offset tabPos = Offset(tabLeft, topOffset);
      bData.offset = tabPos;
      rects[i] = Rect.fromLTWH(tabLeft, topOffset, childWidth, maxHeight);
      currentX += isRtl
          ? -(childWidth + tabSpacing)
          : (childWidth + tabSpacing);
      child = bData.nextSibling;
      i++;
    }

    final double totalWidth = math.max(
      constraints.hasBoundedWidth ? constraints.minWidth : 0.0,
      totalNaturalWidth,
    );
    size = constraints.constrain(Size(totalWidth, effectiveHeight));
    _tabRects = rects;
    onLayoutResolved(rects);
  }

  Rect _calculateIndicatorRect() {
    final int maxIdx = math.min(tabsCount, _tabRects.length) - 1;
    if (maxIdx < 0) return Rect.zero;

    final double pos = driver.value.clamp(0.0, maxIdx.toDouble());
    final int baseIndex = pos.floor();
    final int nextIndex = math.min(maxIdx, baseIndex + 1);
    final double t = pos - baseIndex;

    final Rect baseRect = _tabRects[baseIndex];
    final Rect nextRect = _tabRects[nextIndex];

    final double targetLeft = (1.0 - t) * baseRect.left + t * nextRect.left;
    final double targetWidth = (1.0 - t) * baseRect.width + t * nextRect.width;

    // Velocity-driven kinetic stretch
    final double vel = driver.velocity;
    final double stretch = math.min(24.0, vel.abs() * 3.2);
    final double stretchedWidth = targetWidth + stretch;

    final bool isRtl = textDirection == TextDirection.rtl;
    final double dir = isRtl ? -1.0 : 1.0;
    final double center =
        targetLeft + (targetWidth / 2.0) + (dir * vel.sign * (stretch / 2.0));
    final double left = center - (stretchedWidth / 2.0);

    final double top;
    final double height;

    switch (variant) {
      case OrionTabsVariant.underline:
        final double h = style.indicatorHeight ?? 2.5;
        top = size.height - h;
        height = h;
      case OrionTabsVariant.pill:
        top = baseRect.top;
        height = baseRect.height;
    }

    return Rect.fromLTWH(left, top, stretchedWidth, height);
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    if (_tabRects.isEmpty) return;

    final Canvas canvas = context.canvas;
    final Rect indicatorRect = _calculateIndicatorRect().shift(offset);

    // 1. Paint Indicator Layer
    final Color indColor = style.indicatorColor ?? scheme.primary;
    final BorderRadius indRadius =
        style.indicatorRadius ??
        (variant == OrionTabsVariant.underline
            ? const BorderRadius.vertical(
                top: Radius.circular(OrionRadii.radiusPill),
              )
            : BorderRadius.circular(OrionRadii.radiusPill));

    final Paint indPaint = Paint()..color = indColor;
    final RRect indRRect = indRadius.toRRect(indicatorRect);
    canvas.drawRRect(indRRect, indPaint);

    // 2. Paint All Tab Children directly on top of the indicator
    RenderBox? child = firstChild;
    int index = 0;
    while (child != null && index < tabsCount) {
      final _OrionTabsParentData childParentData =
          child.parentData! as _OrionTabsParentData;
      context.paintChild(child, childParentData.offset + offset);
      child = childParentData.nextSibling;
      index++;
    }
  }

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) {
    return defaultHitTestChildren(result, position: position);
  }
}
