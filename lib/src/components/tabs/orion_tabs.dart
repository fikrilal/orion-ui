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
/// Features:
/// - Velocity-driven kinetic indicator stretch with single spring simulation (Zero Snap).
/// - Clean single-tree layout with zero duplicate text ghosting.
/// - Intrinsic width and equal width distributions.
/// - Horizontal scrolling with auto-centering on selection.
/// - Bidirectional `PageView` / `PageController` swipe synchronization.
/// - Full keyboard navigation (arrow keys respecting RTL) and focus ring support.
/// - Pure Flutter SDK (zero 3rd-party dependencies).
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
    this.style,
    this.focusNode,
    this.autofocus = false,
  });

  /// The list of tabs to display.
  final List<OrionTab<T>> tabs;

  /// The currently selected tab value.
  final T? value;

  /// Callback when a tab is selected.
  final ValueChanged<T>? onChanged;

  /// Optional programmatic controller.
  final OrionTabsController<T>? controller;

  /// Optional PageController for bidirectional swipe synchronization.
  final PageController? pageController;

  /// Visual treatment of the active indicator (underline, pill, segment).
  final OrionTabsVariant variant;

  /// Sizing and layout distribution (intrinsic scrollable vs. equal division).
  final OrionTabsDistribution distribution;

  /// Instance styling overrides.
  final OrionTabsStyle? style;

  /// Optional focus node for arrow-key keyboard selection.
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

  OrionTabsController<T>? _internalController;
  OrionTabsController<T> get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionTabsController<T>());

  FocusNode? _ownedFocusNode;
  FocusNode get _focusNode =>
      widget.focusNode ?? (_ownedFocusNode ??= FocusNode());

  bool _focused = false;
  T? _selectedValue;
  int? _lastPageIndex;
  List<Rect> _cachedTabRects = const <Rect>[];

  /// The spring behind the indicator, exposed so a test can assert continuity.
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
    _selectedValue =
        widget.value ??
        widget.controller?.value ??
        (widget.tabs.isNotEmpty ? widget.tabs.first.value : null);

    final double initialPos = _currentIndex.toDouble();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: initialPos,
      springSpec:
          widget.style?.springSpec ?? OrionTabsPresets.defaultSpringSpec,
    );
    _attachController();
    widget.pageController?.addListener(_handlePageScroll);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.reducedMotion = reduced;

    final OrionTabsStyle resolved = _resolveStyle(Theme.of(context));
    _driver.springSpec =
        resolved.springSpec ?? OrionTabsPresets.defaultSpringSpec;
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
      // The pager echoes the selection it just resolved: `_handlePageScroll` has already
      // moved the indicator and reported it. Animating to that echo would seize a swipe
      // that is still in the air, and the user could no longer drag back.
      final bool alreadySelected = newIdx == _currentIndex;
      _selectedValue = widget.value;
      if (newIdx >= 0 && !alreadySelected) {
        _animateToIndex(newIdx);
      }
    }

    // A shrunk list can strand the selection on a tab that no longer exists.
    if (widget.tabs.isNotEmpty && _indexOf(_selectedValue) < 0) {
      _animateToIndex(math.min(_currentIndex, widget.tabs.length - 1));
    }

    final OrionTabsStyle resolved = _resolveStyle(Theme.of(context));
    _driver.springSpec =
        resolved.springSpec ?? OrionTabsPresets.defaultSpringSpec;
  }

  @override
  void dispose() {
    widget.pageController?.removeListener(_handlePageScroll);
    _effectiveController.detach();
    _internalController?.dispose();
    _ownedFocusNode?.dispose();
    _scrollController.dispose();
    _driver.dispose();
    super.dispose();
  }

  void _attachController() {
    _effectiveController.attach(
      onAnimateTo: (val) {
        final int idx = _indexOf(val);
        if (idx >= 0) {
          _selectedValue = val;
          _animateToIndex(idx);
        }
      },
      onJumpTo: (val) {
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

    final double page = pager.page!;

    if (_driver.reducedMotion) {
      _driver.jumpTo(page.roundToDouble());
    } else {
      _driver.jumpTo(page);
    }

    // The public way to tell a finger from an animation: the position reports a user
    // scroll direction only while the user is the one moving it. A tap's animation and
    // the jump reduced motion uses both leave it idle.
    final bool userDriven =
        pager.position.userScrollDirection != ScrollDirection.idle;

    final int targetPage = page.round();
    if (targetPage != _lastPageIndex &&
        targetPage >= 0 &&
        targetPage < widget.tabs.length) {
      _lastPageIndex = targetPage;
      _syncControllerSelection(targetPage);
      // A page the user dragged to is an event; a page the component animated to was
      // already reported by `_select`.
      if (userDriven) {
        widget.onChanged?.call(widget.tabs[targetPage].value);
      }
      _autoCenterActiveTab(targetPage);
    }
  }

  void _animateToIndex(int targetIndex) {
    if (targetIndex < 0 || targetIndex >= widget.tabs.length) return;

    if (widget.pageController != null && widget.pageController!.hasClients) {
      if (_driver.reducedMotion) {
        widget.pageController!.jumpToPage(targetIndex);
      } else {
        widget.pageController!.animateToPage(
          targetIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
        );
      }
      _syncControllerSelection(targetIndex);
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

    if (widget.pageController != null && widget.pageController!.hasClients) {
      widget.pageController!.jumpToPage(targetIndex);
      _syncControllerSelection(targetIndex);
      return;
    }

    _driver.jumpTo(targetIndex.toDouble());
    _syncControllerSelection(targetIndex);
    _autoCenterActiveTab(targetIndex, immediate: true);
  }

  void _select(int index) {
    if (index < 0 || index >= widget.tabs.length) return;
    final OrionTab<T> tab = widget.tabs[index];
    if (tab.disabled) return;

    final theme = Theme.of(context);
    final style = _resolveStyle(theme);
    OrionHaptics.trigger(style.hapticType ?? OrionHapticType.selectionClick);

    _animateToIndex(index);
    widget.onChanged?.call(tab.value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      _ => 0,
    };
    if (delta == 0) return KeyEventResult.ignored;

    final int current = _currentIndex;
    int next = current + delta;
    while (next >= 0 &&
        next < widget.tabs.length &&
        widget.tabs[next].disabled) {
      next += delta;
    }
    if (current < 0 || next < 0 || next >= widget.tabs.length) {
      return KeyEventResult.handled;
    }
    _select(next);
    return KeyEventResult.handled;
  }

  void _autoCenterActiveTab(int index, {bool immediate = false}) {
    if (widget.distribution != OrionTabsDistribution.intrinsic) return;
    if (!_scrollController.hasClients) return;
    if (index < 0 || index >= _cachedTabRects.length) return;

    final Rect tabRect = _cachedTabRects[index];
    final double viewportWidth = _scrollController.position.viewportDimension;
    final double maxScroll = _scrollController.position.maxScrollExtent;
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

  Widget _buildTabItem({
    required OrionTab<T> tab,
    required int index,
    required OrionTabsStyle style,
    required ColorScheme scheme,
  }) {
    final bool isSelected = index == _currentIndex;
    final Color textColor = tab.disabled
        ? (style.disabledLabelColor ?? scheme.onSurface.withValues(alpha: 0.38))
        : (isSelected
              ? (style.activeLabelColor ?? scheme.onPrimary)
              : (style.inactiveLabelColor ?? scheme.onSurfaceVariant));

    final Widget labelWidget = Text(
      tab.label,
      maxLines: 1,
      style:
          (style.labelStyle ??
                  const TextStyle(fontSize: 14.0, fontWeight: FontWeight.w600))
              .copyWith(color: textColor),
    );

    final Widget? iconWidget = tab.icon != null
        ? IconTheme.merge(
            data: IconThemeData(color: textColor, size: style.iconSize ?? 18.0),
            child: tab.icon!,
          )
        : null;

    final Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (iconWidget != null) ...[
          iconWidget,
          const SizedBox(width: OrionSpacing.space8),
        ],
        labelWidget,
        if (tab.badge != null) ...[
          const SizedBox(width: OrionSpacing.space8),
          tab.badge!,
        ],
      ],
    );

    final EdgeInsetsGeometry effectivePadding =
        style.tabPadding ??
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space16,
          vertical: OrionSpacing.space12,
        );

    final Widget padded = Padding(padding: effectivePadding, child: content);

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      enabled: !tab.disabled,
      inMutuallyExclusiveGroup: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: OrionSizing.minHitTarget),
        child: OrionPressable(
          onTap: tab.disabled ? null : () => _select(index),
          pressedScale: style.pressedScale ?? 0.98,
          springSpec:
              style.pressSpring ??
              const OrionSpringSpec(stiffness: 420.0, dampingRatio: 0.85),
          releaseSpringSpec: style.releaseSpring,
          hapticType: OrionHapticType.none, // Managed in _select
          child: padded,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final style = _resolveStyle(theme);
    final TextDirection textDirection = Directionality.of(context);

    final List<Widget> tabWidgets = <Widget>[];
    for (int i = 0; i < widget.tabs.length; i++) {
      tabWidgets.add(
        _buildTabItem(
          tab: widget.tabs[i],
          index: i,
          style: style,
          scheme: scheme,
        ),
      );
    }

    final bool hasTrackBg =
        style.trackColor != null && style.trackColor != Colors.transparent;
    final Color focusRing =
        style.focusRingColor ?? scheme.primary.withValues(alpha: 0.5);

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      onFocusChange: (focused) {
        if (focused != _focused) setState(() => _focused = focused);
      },
      onKeyEvent: _onKey,
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
            onLayoutResolved: (rects) {
              _cachedTabRects = rects;
            },
            children: tabWidgets,
          );

          Widget result = SingleChildScrollView(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: tabsLayout,
          );

          result = DecoratedBox(
            decoration: BoxDecoration(
              color: hasTrackBg ? style.trackColor : null,
              borderRadius: style.trackBorderRadius,
              border: _focused
                  ? Border.all(color: focusRing, width: 2.0)
                  : null,
            ),
            child: result,
          );

          return result;
        },
      ),
    );
  }
}

/// Custom multi-child RenderObject that lays out tabs in a single pass on Frame 0
/// and paints the kinetic stretching indicator behind them with zero widget rebuilds
/// during spring flight.
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
      // With no tabs there is nothing to measure: an infinite inner width would be
      // handed back to the horizontal scroll view and fail layout.
      size = constraints.constrain(
        Size(0.0, constraints.hasBoundedHeight ? constraints.maxHeight : 0.0),
      );
      return;
    }

    final bool isRtl = textDirection == TextDirection.rtl;
    final List<Rect> rects = List<Rect>.filled(tabsCount, Rect.zero);
    double maxHeight = 0.0;

    RenderBox? child = firstChild;
    int i = 0;
    double maxNaturalWidth = 0.0;
    double totalNaturalWidth = trackPadding.horizontal;
    final List<double> naturalWidths = List<double>.filled(tabsCount, 0.0);

    while (child != null && i < tabsCount) {
      child.layout(const BoxConstraints(), parentUsesSize: true);
      naturalWidths[i] = child.size.width;
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
        // Fits equally without truncation!
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

    // Intrinsic or overflowing layout: preserve natural widths and never crush content!
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
    if (_tabRects.isEmpty) return Rect.zero;

    final double pos = driver.value.clamp(0.0, (tabsCount - 1).toDouble());
    final int baseIndex = pos.floor();
    final int nextIndex = math.min(tabsCount - 1, baseIndex + 1);
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
      case OrionTabsVariant.segment:
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

    // Draw subtle elevation shadow if segment variant
    if (variant == OrionTabsVariant.segment) {
      canvas.drawRRect(
        indRRect.shift(const Offset(0.0, 1.0)),
        Paint()
          ..color = Colors.black.withValues(alpha: 0.08)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2.0),
      );
    }

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
