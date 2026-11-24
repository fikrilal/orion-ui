import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/navigation/orion_navigation_bar_style.dart';
import 'package:orion_ui/src/components/navigation/orion_navigation_bar_theme.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One destination in an [OrionNavigationBar].
class OrionNavigationDestination {
  /// Creates a destination with an icon and a short label.
  const OrionNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.badge,
    this.badgeCount,
    this.maxBadgeCount = 99,
    this.badgeDot = false,
    this.enabled = true,
    this.tooltip,
    this.semanticLabel,
  }) : assert(
         badgeCount == null || badgeCount >= 0,
         'badgeCount must not be negative',
       ),
       assert(
         maxBadgeCount == null || maxBadgeCount > 0,
         'maxBadgeCount must be positive',
       );

  /// Icon shown when unselected (and when selected if [selectedIcon] is null).
  /// Inherits the destination colour and icon size.
  final Widget icon;

  /// Optional icon cross-faded in as this destination becomes selected (for
  /// example, swapping an outlined glyph for its filled counterpart).
  final Widget? selectedIcon;

  /// Short name of the destination.
  final String label;

  /// Optional custom badge content shown in a cut-out chip at the icon's
  /// top-right. Takes precedence over [badgeCount] and [badgeDot].
  final Widget? badge;

  /// Optional numeric unread counter shorthand. Values `<= 0` hide the badge;
  /// values above [maxBadgeCount] display as `"99+"` while keeping the true
  /// count for screen readers.
  final int? badgeCount;

  /// Optional cap for [badgeCount]. Defaults to `99`; pass `null` to show the
  /// exact number without capping.
  final int? maxBadgeCount;

  /// Whether to show a compact status dot at the icon's top-right when neither
  /// [badge] nor a positive [badgeCount] is supplied.
  final bool badgeDot;

  /// Whether this individual destination accepts taps, long presses, and
  /// keyboard selection. Defaults to `true`.
  final bool enabled;

  /// Optional tooltip message shown on pointer hover (and on long press when
  /// [OrionNavigationBar.onLongPress] is null). In
  /// [OrionNavigationLabelMode.none], defaults to [label]; pass `''` to
  /// suppress it.
  final String? tooltip;

  /// Optional screen-reader override for this destination (e.g.
  /// `"Chats, 12 unread"`). When null, the visible label (or [label] when
  /// hidden) is announced automatically.
  final String? semanticLabel;
}

/// How an [OrionNavigationBar] presents its destination labels.
enum OrionNavigationLabelMode {
  /// Every destination shows its icon above its label, and the bar fills
  /// the space it is given up to the style's maximum width.
  all,

  /// Destinations are icons only, and a floating capsule hugs them: a natural
  /// width and a shorter fallback height.
  none,

  /// Destinations rest as icons; the selected one expands into a pill that
  /// reveals its label, the label-on-select pattern. The capsule reserves one
  /// label's width, so it never resizes as the selection moves.
  selected,
}

/// Layout geometry of an [OrionNavigationBar].
enum OrionNavigationBarVariant {
  /// Floating pill capsule inset from screen edges with elevation shadows.
  floating,

  /// Full-width edge-to-edge bottom bar separated by a top hairline border,
  /// suited for direct placement in [Scaffold.bottomNavigationBar].
  docked,
}

/// The weight a selected label renders at: the style's own when it is already
/// bold, else bold.
FontWeight _activeWeight(TextStyle style) {
  final FontWeight base = style.fontWeight ?? FontWeight.w500;
  return base.value >= FontWeight.w700.value ? base : FontWeight.w700;
}

/// Computes a concentric corner radius for an inner selection pill relative to
/// the bar's outer [radius] and inner [padding].
BorderRadius _concentricPillRadius(
  BorderRadius outer,
  EdgeInsets padding, {
  required OrionNavigationBarVariant variant,
  required OrionNavigationLabelMode labelMode,
}) {
  if (variant == OrionNavigationBarVariant.docked &&
      outer == BorderRadius.zero) {
    return BorderRadius.circular(
      labelMode == OrionNavigationLabelMode.all
          ? OrionRadii.radius16
          : OrionRadii.radiusPill,
    );
  }
  Radius shrink(Radius r, double dx, double dy) {
    if (r.x >= OrionRadii.radiusPill / 2 && r.y >= OrionRadii.radiusPill / 2) {
      return r;
    }
    return Radius.elliptical(math.max(0, r.x - dx), math.max(0, r.y - dy));
  }

  return BorderRadius.only(
    topLeft: shrink(outer.topLeft, padding.left, padding.top),
    topRight: shrink(outer.topRight, padding.right, padding.top),
    bottomLeft: shrink(outer.bottomLeft, padding.left, padding.bottom),
    bottomRight: shrink(outer.bottomRight, padding.right, padding.bottom),
  );
}

/// A spring-driven bottom navigation bar in floating capsule or docked form.
///
/// The parent owns [selectedIndex]. The selection travels on the immediate
/// travel spec rather than the press spring, whose overshoot is a third of the
/// travel. While a pager is moving, [dragPosition] is the fractional page and
/// the pill follows it. A jump of more than one destination does not select
/// the tabs in between.
///
/// Safe to place either overlaid inside a [Stack] or directly in
/// [Scaffold.bottomNavigationBar]: the bar sizes to its intrinsic height and
/// optionally applies safe-area insets via [useSafeArea] (off by default for
/// [OrionNavigationBarVariant.floating], on by default for
/// [OrionNavigationBarVariant.docked]).
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionNavigationBarStyle.defaults], the ambient
/// [OrionNavigationTheme], and the [style] passed here. Anything an override
/// does not name falls through.
class OrionNavigationBar extends StatefulWidget {
  /// Creates a controlled navigation bar.
  const OrionNavigationBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onChanged,
    this.onLongPress,
    this.variant = OrionNavigationBarVariant.floating,
    this.useSafeArea,
    this.style,
    this.dragPosition,
    this.visible = true,
    this.focusNode,
    this.autofocus = false,
  });

  /// Destinations from the leading edge. At least two.
  final List<OrionNavigationDestination> destinations;

  /// Index of the selected destination.
  final int selectedIndex;

  /// Called with the tapped or keyed index, including a retap of the current
  /// destination. Null disables the entire bar.
  final ValueChanged<int>? onChanged;

  /// Called with the index when an enabled destination is long-pressed. Null
  /// disables the long press while a plain tap still selects. Silent, like the
  /// reference's tab bar; menus are the host's.
  final ValueChanged<int>? onLongPress;

  /// Whether the bar renders as a floating pill capsule or a full-width docked
  /// bar. Defaults to [OrionNavigationBarVariant.floating].
  final OrionNavigationBarVariant variant;

  /// Whether to apply bottom (and horizontal) safe-area padding.
  ///
  /// When null, defaults to `false` for [OrionNavigationBarVariant.floating]
  /// (so host stacks keep full control over outer insets) and `true` for
  /// [OrionNavigationBarVariant.docked] (so the bar's background extends
  /// seamlessly behind the system home indicator).
  final bool? useSafeArea;

  /// Instance-level overrides, merged over the defaults and the ambient
  /// [OrionNavigationTheme]. Only the fields set here change.
  final OrionNavigationBarStyle? style;

  /// Fractional page while a finger is dragging a pager. Null lets the pill
  /// spring to [selectedIndex]. Do not feed this from a programmatic page
  /// animation, or a multi-tab jump will select the tabs in between.
  final double? dragPosition;

  /// Whether the bar is shown. Hiding fades it, scales it to 0.98, and
  /// slides it down by 8 pt.
  final bool visible;

  /// Optional focus node for keyboard navigation (`ArrowLeft`, `ArrowRight`,
  /// `Home`, `End`).
  final FocusNode? focusNode;

  /// Whether the bar requests focus on first build.
  final bool autofocus;

  @override
  State<OrionNavigationBar> createState() => _OrionNavigationBarState();
}

class _OrionNavigationBarState extends State<OrionNavigationBar>
    with TickerProviderStateMixin {
  late final OrionSpringDriver _selection;
  late final OrionSpringDriver _visibility;

  /// Relaxes the displayed factors from the last pair flip to the new theory,
  /// so an interrupted jump hands over without a snap.
  late final AnimationController _relax;

  /// The factors the last hand-off started from, one per destination.
  late List<double> _blendFrom;
  late double _origin;
  bool _focused = false;
  bool _reduced = false;

  FocusNode? _ownedFocusNode;
  FocusNode get _effectiveFocusNode =>
      widget.focusNode ??
      (_ownedFocusNode ??= FocusNode(debugLabel: 'OrionNavigationBar'));

  // Cached expanding-mode label measurements so per-frame dragPosition ticks
  // never re-run TextPainter layouts.
  List<String>? _cachedLabels;
  TextStyle? _cachedActiveLabelStyle;
  TextDirection? _cachedTextDirection;
  TextScaler? _cachedTextScaler;
  double? _cachedIconLabelGap;
  List<double> _cachedLabelAdds = const <double>[];

  /// The capsule's minimum height; a label-less bar hugs its icons with the
  /// shorter one.
  static const double _defaultMinHeight = 64;
  static const double _iconOnlyMinHeight = 52;

  @override
  void initState() {
    super.initState();
    _origin = _selectionTarget;
    _selection = OrionSpringDriver(vsync: this, initialValue: _origin);
    _visibility = OrionSpringDriver(
      vsync: this,
      initialValue: widget.visible ? 1 : 0,
    );
    _relax = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
      value: 1,
    );
    _blendFrom = _settledFactors();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    _reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = _reduced && !_selection.reducedMotion;
    // Both travels are lateral or chrome; the drivers own reduced motion, so a
    // retarget settles in the same frame when the platform asked for none.
    _selection.reducedMotion = _reduced;
    _visibility.reducedMotion = _reduced;
    if (becameReduced) {
      _relax.value = 1;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_selection.reducedMotion) {
          return;
        }
        _origin = _selectionTarget;
        _selection.jumpTo(_origin);
        _visibility.jumpTo(widget.visible ? 1 : 0);
      });
    }
  }

  @override
  void didUpdateWidget(OrionNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode == null && widget.focusNode != null) {
      _ownedFocusNode?.dispose();
      _ownedFocusNode = null;
    }
    _syncMotion();
    final int count = widget.destinations.length;
    if (_blendFrom.length != count) {
      _blendFrom = _settledFactors();
      _relax.value = 1;
      if (count > 0 && _selection.value > count - 1) {
        _origin = _selectionTarget;
        _selection.jumpTo(_origin);
      }
    }
    _syncSelection();
    _syncVisibility();
    if (oldWidget.visible && !widget.visible && _focused) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && !widget.visible && _effectiveFocusNode.hasFocus) {
          _effectiveFocusNode.unfocus();
        }
      });
    }
  }

  @override
  void dispose() {
    _ownedFocusNode?.dispose();
    _relax.dispose();
    _selection.dispose();
    _visibility.dispose();
    super.dispose();
  }

  bool get _hasAnyEnabledDestination =>
      widget.onChanged != null &&
      widget.destinations.any(
        (OrionNavigationDestination destination) => destination.enabled,
      );

  double get _selectionTarget {
    if (widget.destinations.isEmpty) {
      return 0;
    }
    final double last = (widget.destinations.length - 1).toDouble();
    final double raw = widget.dragPosition ?? widget.selectedIndex.toDouble();
    return raw.clamp(0.0, math.max(0.0, last));
  }

  /// The relaxed progress the displayed factors blend by.
  double get _handoff => Curves.easeOutCubic.transform(_relax.value);

  List<double> _settledFactors() {
    final int count = widget.destinations.length;
    if (count == 0) {
      return const <double>[];
    }
    final List<double> factors = List<double>.filled(count, 0);
    final int index = widget.selectedIndex.clamp(0, count - 1);
    factors[index] = 1;
    return factors;
  }

  void _debugValidate() {
    assert(widget.destinations.length >= 2, 'at least two destinations');
    assert(
      widget.selectedIndex >= 0 &&
          widget.selectedIndex < widget.destinations.length,
      'selectedIndex must match a destination',
    );
  }

  OrionNavigationBarStyle _resolve(ThemeData theme) {
    final OrionNavigationTheme navigationTheme =
        theme.extension<OrionNavigationTheme>() ??
        OrionNavigationTheme.fallback;
    return OrionNavigationBarStyle.defaults(
      scheme: theme.colorScheme,
      labelStyle: theme.textTheme.labelSmall,
      variant: widget.variant,
    ).merge(navigationTheme.defaultStyle).merge(widget.style);
  }

  void _syncMotion() {
    final OrionNavigationBarStyle style = _resolve(Theme.of(context));
    _selection.springSpec = style.selectionSpring ?? OrionSpringSpec.immediate;
    _visibility.springSpec =
        style.hideSpring ??
        const OrionSpringSpec(stiffness: 380, dampingRatio: 1);
  }

  void _syncSelection() {
    final double target = _selectionTarget;
    if (widget.dragPosition != null || _selection.reducedMotion) {
      _relax.value = 1;
      _origin = target;
      _selection.jumpTo(target);
      return;
    }
    if (_selection.target == target) {
      return;
    }
    _captureHandoff();
    _origin = _selection.value;
    _selection.retarget(target);
  }

  /// Captures what is on screen and relaxes toward the new factor theory, so a
  /// pair flip - a retarget mid-jump, a new jump - cannot snap.
  void _captureHandoff() {
    final List<double> theory = <double>[
      for (var index = 0; index < widget.destinations.length; index++)
        _factor(index),
    ];
    final double handoff = _handoff;
    _blendFrom = <double>[
      for (var index = 0; index < theory.length; index++)
        _blendFrom[index] + (theory[index] - _blendFrom[index]) * handoff,
    ];
    if (_selection.reducedMotion) {
      _relax.value = 1;
    } else {
      _relax.forward(from: 0);
    }
  }

  void _syncVisibility() {
    final double target = widget.visible ? 1 : 0;
    if (_visibility.reducedMotion) {
      _visibility.jumpTo(target);
      return;
    }
    if (_visibility.target == target) {
      return;
    }
    _visibility.retarget(target);
  }

  void _select(int index, {required bool haptic}) {
    if (widget.onChanged == null) {
      return;
    }
    if (index < 0 ||
        index >= widget.destinations.length ||
        !widget.destinations[index].enabled) {
      return;
    }
    if (haptic) {
      OrionHaptics.trigger(OrionTheme.of(context).selectionHaptic);
    }
    widget.onChanged!(index);
  }

  int? _findEnabled({required int start, required int step}) {
    final int count = widget.destinations.length;
    for (int i = start; i >= 0 && i < count; i += step) {
      if (widget.destinations[i].enabled) {
        return i;
      }
    }
    return null;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (!widget.visible ||
        (event is! KeyDownEvent && event is! KeyRepeatEvent) ||
        !_hasAnyEnabledDestination) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final LogicalKeyboardKey key = event.logicalKey;

    int? next;
    if (key == LogicalKeyboardKey.home) {
      next = _findEnabled(start: 0, step: 1);
    } else if (key == LogicalKeyboardKey.end) {
      next = _findEnabled(start: widget.destinations.length - 1, step: -1);
    } else if (key == LogicalKeyboardKey.arrowRight ||
        key == LogicalKeyboardKey.arrowLeft) {
      final int delta = key == LogicalKeyboardKey.arrowRight
          ? (rtl ? -1 : 1)
          : (rtl ? 1 : -1);
      next = _findEnabled(start: widget.selectedIndex + delta, step: delta);
    } else {
      return KeyEventResult.ignored;
    }

    if (next == null || next == widget.selectedIndex) {
      return KeyEventResult.handled;
    }
    _select(next, haptic: false);
    return KeyEventResult.handled;
  }

  double _factor(int index) {
    if (widget.destinations.isEmpty) {
      return 0;
    }
    final int last = widget.destinations.length - 1;
    final int from = _origin.round().clamp(0, last);
    final int to = _selection.target.round().clamp(0, last);
    final bool longJump = widget.dragPosition == null && (from - to).abs() > 1;
    if (!longJump) {
      final double distance = (index - _selection.value).abs();
      if (distance >= 1) {
        return 0;
      }
      return 1 - distance;
    }

    final double span = (to - from).toDouble();
    final double t = ((_selection.value - from) / span).clamp(0.0, 1.0);
    if (index == from) {
      return 1 - t;
    }
    if (index == to) {
      return t;
    }
    return 0;
  }

  List<double> _labelAddsFor({
    required TextStyle activeLabelStyle,
    required TextDirection textDirection,
    required TextScaler textScaler,
    required double iconLabelGap,
  }) {
    final List<String> labels = <String>[
      for (final OrionNavigationDestination destination in widget.destinations)
        destination.label,
    ];
    if (_cachedLabels != null &&
        listEquals(_cachedLabels, labels) &&
        _cachedActiveLabelStyle == activeLabelStyle &&
        _cachedTextDirection == textDirection &&
        _cachedTextScaler == textScaler &&
        _cachedIconLabelGap == iconLabelGap) {
      return _cachedLabelAdds;
    }

    final List<double> measured = <double>[
      for (final String label in labels)
        iconLabelGap +
            _measureLabelWidth(
              label,
              activeLabelStyle,
              textDirection: textDirection,
              textScaler: textScaler,
            ) +
            1,
    ];
    _cachedLabels = labels;
    _cachedActiveLabelStyle = activeLabelStyle;
    _cachedTextDirection = textDirection;
    _cachedTextScaler = textScaler;
    _cachedIconLabelGap = iconLabelGap;
    _cachedLabelAdds = measured;
    return measured;
  }

  double _measureLabelWidth(
    String label,
    TextStyle style, {
    required TextDirection textDirection,
    required TextScaler textScaler,
  }) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: label, style: style),
      textDirection: textDirection,
      // The live layout applies the ambient text scale; the reserve must too,
      // or a scaled device overflows the measured room.
      textScaler: textScaler,
      maxLines: 1,
    )..layout();
    final double width = painter.width;
    painter.dispose();
    return width;
  }

  Widget _destinationButton(
    int index, {
    required double factor,
    required bool barEnabled,
    required TextStyle labelStyle,
    required double iconSize,
    required OrionNavigationBarStyle style,
    required ColorScheme scheme,
    required Color surfaceBase,
    required Color selectColor,
    required Color hoverColor,
    required EdgeInsets itemPadding,
    required double iconLabelGap,
    required OrionNavigationLabelMode labelMode,
    required double labelScale,
    required Color? pillColor,
    required BorderRadius pillRadius,
  }) {
    final OrionNavigationDestination destination = widget.destinations[index];
    final bool itemEnabled = barEnabled && destination.enabled && widget.visible;
    final bool itemVisuallyEnabled = barEnabled && destination.enabled;

    return _DestinationButton(
      destination: destination,
      factor: factor,
      selected: index == widget.selectedIndex,
      enabled: itemEnabled,
      visuallyEnabled: itemVisuallyEnabled,
      labelStyle: labelStyle,
      iconSize: iconSize,
      scheme: scheme,
      destinationColor: style.destinationColor,
      badgeStyle:
          style.badge ?? OrionNavigationBadgeStyle.defaults(scheme: scheme),
      surfaceBase: surfaceBase,
      selectColor: selectColor,
      hoverColor: hoverColor,
      itemPadding: itemPadding,
      iconLabelGap: iconLabelGap,
      labelMode: labelMode,
      labelScale: labelScale,
      pillColor: pillColor,
      pillRadius: pillRadius,
      reduced: _reduced,
      onTap: itemEnabled ? () => _select(index, haptic: true) : null,
      onLongPress: itemEnabled && widget.onLongPress != null
          ? () => widget.onLongPress!(index)
          : null,
    );
  }

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    if (widget.destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;
    final TextDirection textDirection = Directionality.of(context);
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final OrionNavigationBarStyle style = _resolve(theme);

    final bool docked = widget.variant == OrionNavigationBarVariant.docked;
    final bool effectiveSafeArea = widget.useSafeArea ?? docked;
    final bool barEnabled = widget.onChanged != null;
    final bool canFocus = _hasAnyEnabledDestination && widget.visible;

    final BorderRadius radius =
        style.radius ??
        (docked
            ? BorderRadius.zero
            : BorderRadius.circular(OrionRadii.radiusPill));
    final TextStyle labelStyle =
        style.labelStyle ?? theme.textTheme.labelSmall ?? const TextStyle();
    final double iconSize = style.iconSize ?? 20;
    final OrionNavigationLabelMode labelMode =
        style.labelMode ?? OrionNavigationLabelMode.all;
    final Color background = style.background ?? scheme.surfaceContainer;
    final Color hairline = style.borderColor ?? scheme.outlineVariant;
    final double borderWidth = style.borderWidth ?? 1;
    final bool frosted = style.frosted ?? false;
    final List<BoxShadow> shadows = style.shadows ?? const <BoxShadow>[];
    final Color focusRing = style.focusRingColor ?? scheme.onSurface;
    final Color hoverColor =
        style.hoverColor ?? scheme.onSurface.withValues(alpha: 0.05);
    final double hideSlide = style.hideSlide ?? 8;
    final double hideScale = style.hideScale ?? 0.98;
    final EdgeInsets padding =
        (style.padding ?? const EdgeInsets.all(OrionSpacing.space4)).resolve(
          textDirection,
        );
    final Color selectColor =
        style.selectionColor?.resolve(<WidgetState>{
          if (!barEnabled) WidgetState.disabled,
        }) ??
        scheme.onSurface.withValues(alpha: barEnabled ? 0.08 : 0.04);

    final BorderRadius pillRadius = _concentricPillRadius(
      radius,
      padding,
      variant: widget.variant,
      labelMode: labelMode,
    );

    final EdgeInsets dockedSafeInsets = docked && effectiveSafeArea
        ? MediaQuery.paddingOf(context).copyWith(top: 0)
        : EdgeInsets.zero;

    final Widget bar = Focus(
      focusNode: _effectiveFocusNode,
      autofocus: widget.autofocus,
      canRequestFocus: canFocus,
      onFocusChange: (bool focused) {
        if (focused != _focused) {
          setState(() => _focused = focused);
        }
      },
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final int count = widget.destinations.length;
          final bool labelled = labelMode == OrionNavigationLabelMode.all;
          final bool expands = labelMode == OrionNavigationLabelMode.selected;
          final double iconLabelGap =
              style.iconLabelGap ??
              (expands ? OrionSpacing.space8 : OrionSpacing.space4);

          final EdgeInsets baseItemPadding =
              style.itemPadding?.resolve(textDirection) ??
              (labelled
                  ? const EdgeInsets.all(OrionSpacing.space8)
                  : const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space20,
                      vertical: OrionSpacing.space12,
                    ));

          final double defaultMaxWidth = docked ? double.infinity : 360;
          final double maxWidth = style.maxWidth ?? defaultMaxWidth;
          final double available = constraints.hasBoundedWidth
              ? constraints.maxWidth
              : (maxWidth.isFinite ? maxWidth : 360);

          final TextStyle activeLabelStyle = labelStyle.copyWith(
            fontWeight: _activeWeight(labelStyle),
          );
          final List<double> labelAdds = expands
              ? _labelAddsFor(
                  activeLabelStyle: activeLabelStyle,
                  textDirection: textDirection,
                  textScaler: textScaler,
                  iconLabelGap: iconLabelGap,
                )
              : const <double>[];
          final double widest = labelAdds.isEmpty
              ? 0
              : labelAdds.reduce(math.max);

          final double baseIconSlot = iconSize + baseItemPadding.horizontal;
          final double outerHorizontalPadding =
              padding.horizontal + dockedSafeInsets.horizontal;

          // Docked bars fill available width; floating labelled bars fill up to
          // maxWidth; icon-only and expanding floating capsules hug naturally.
          final double naturalWidth = labelled || docked
              ? maxWidth
              : outerHorizontalPadding + count * baseIconSlot + widest;
          final double barWidth = docked
              ? math.min(available, maxWidth)
              : (labelled
                    ? math.min(available, maxWidth)
                    : math.min(available, math.min(maxWidth, naturalWidth)));

          final double innerWidth = math.max(
            0.0,
            barWidth - outerHorizontalPadding,
          );

          // Adapt horizontal item padding gracefully when tight (e.g. 5-6 tabs
          // or narrow screens) so slots never overflow the Row.
          EdgeInsets effectiveItemPadding = baseItemPadding;
          double iconSlot = baseIconSlot;
          if (expands) {
            final double basePadH = baseItemPadding.horizontal / 2;
            final double hardMaxPadH = math.max(
              0.0,
              (innerWidth - count * iconSize) / (2 * count),
            );
            final double minComfortPadH = math.min(
              basePadH,
              OrionSpacing.space8,
            );
            final double desiredPadH =
                (innerWidth - widest - count * iconSize) / (2 * count);
            final double padH = desiredPadH.clamp(
              math.min(minComfortPadH, hardMaxPadH),
              math.min(basePadH, hardMaxPadH),
            );
            effectiveItemPadding = EdgeInsets.fromLTRB(
              padH,
              baseItemPadding.top,
              padH,
              baseItemPadding.bottom,
            );
            iconSlot = math.min(
              iconSize + effectiveItemPadding.horizontal,
              innerWidth / count,
            );
          } else if (!labelled) {
            final double slotW = innerWidth / count;
            if (slotW < baseIconSlot) {
              final double padH = math.max(0.0, (slotW - iconSize) / 2);
              effectiveItemPadding = EdgeInsets.fromLTRB(
                padH,
                baseItemPadding.top,
                padH,
                baseItemPadding.bottom,
              );
            }
          }

          final double labelRoom = math.max(0.0, innerWidth - count * iconSlot);
          final double labelScale = !expands || widest <= 0
              ? 1
              : (labelRoom / widest).clamp(0.0, 1.0);

          final double slotWidth = innerWidth / count;
          final double direction = textDirection == TextDirection.rtl ? -1 : 1;

          final Color surfaceColor = frosted
              ? background.withValues(alpha: isDark ? 0.72 : 0.78)
              : background;

          Widget button(int index, double factor) => _destinationButton(
            index,
            factor: factor,
            barEnabled: barEnabled,
            labelStyle: labelStyle,
            iconSize: iconSize,
            style: style,
            scheme: scheme,
            surfaceBase: background,
            selectColor: selectColor,
            hoverColor: hoverColor,
            itemPadding: effectiveItemPadding,
            iconLabelGap: iconLabelGap,
            labelMode: labelMode,
            labelScale: expands ? labelScale : 1,
            pillColor: expands ? selectColor : null,
            pillRadius: pillRadius,
          );

          final Border? chromeBorder;
          if (_focused && canFocus) {
            chromeBorder = Border.all(color: focusRing, width: 2);
          } else if (borderWidth <= 0) {
            chromeBorder = null;
          } else if (docked) {
            chromeBorder = Border(
              top: BorderSide(color: hairline, width: borderWidth),
            );
          } else {
            chromeBorder = Border.all(color: hairline, width: borderWidth);
          }

          final double effectiveMinHeight =
              style.minHeight ??
              (labelled ? _defaultMinHeight : _iconOnlyMinHeight);
          final double innerMinHeight = math.max(
            0.0,
            effectiveMinHeight - padding.vertical,
          );

          final Widget interactiveBody = Padding(
            padding: dockedSafeInsets,
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: effectiveMinHeight),
              child: Padding(
                padding: padding,
                child: AnimatedBuilder(
                  animation: Listenable.merge(<Listenable>[_selection, _relax]),
                  builder: (BuildContext context, Widget? child) {
                    final double handoff = _handoff;
                    final List<double> factors = <double>[
                      for (var index = 0; index < count; index++)
                        _blendFrom[index] +
                            (_factor(index) - _blendFrom[index]) * handoff,
                    ];
                    final double clampedPillIndex = _selection.value.clamp(
                      0.0,
                      (count - 1).toDouble(),
                    );
                    return Stack(
                      children: <Widget>[
                        // The expanding mode gives each slot its own pill; the
                        // other modes share one sliding pill.
                        if (!expands)
                          PositionedDirectional(
                            start: 0,
                            top: 0,
                            bottom: 0,
                            width: slotWidth,
                            child: Transform.translate(
                              offset: Offset(
                                direction * clampedPillIndex * slotWidth,
                                0,
                              ),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: selectColor,
                                  borderRadius: pillRadius,
                                ),
                              ),
                            ),
                          ),
                        Row(
                          // Pin the leading and trailing slots flush to the
                          // capsule's inner padding so top, bottom, left, and
                          // right edge gaps stay uniform and concentric while
                          // reserved label slack distributes between slots.
                          mainAxisAlignment: expands
                              ? MainAxisAlignment.spaceBetween
                              : MainAxisAlignment.center,
                          children: <Widget>[
                            for (var index = 0; index < count; index++)
                              if (expands)
                                ConstrainedBox(
                                  constraints: BoxConstraints(
                                    minWidth:
                                        iconSlot +
                                        labelAdds[index] *
                                            factors[index] *
                                            labelScale,
                                    maxWidth:
                                        iconSlot +
                                        labelAdds[index] *
                                            factors[index] *
                                            labelScale,
                                    minHeight: innerMinHeight,
                                  ),
                                  child: button(index, factors[index]),
                                )
                              else
                                Expanded(child: button(index, factors[index])),
                          ],
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );

          final Widget surface = frosted
              ? BackdropFilter(
                  filter: ImageFilter.blur(
                    sigmaX: orion.blurSigma,
                    sigmaY: orion.blurSigma,
                  ),
                  child: ColoredBox(color: surfaceColor, child: interactiveBody),
                )
              : ColoredBox(color: surfaceColor, child: interactiveBody);

          final Widget chrome = DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              boxShadow: shadows.isEmpty ? null : shadows,
            ),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: radius,
                border: chromeBorder,
              ),
              child: ClipRRect(borderRadius: radius, child: surface),
            ),
          );

          return Align(
            alignment: Alignment.bottomCenter,
            heightFactor: 1,
            child: SizedBox(
              width: barWidth,
              child: AnimatedBuilder(
                animation: _visibility,
                builder: (BuildContext context, Widget? child) {
                  final double shown = _visibility.value.clamp(0.0, 1.0);
                  return IgnorePointer(
                    ignoring: !widget.visible,
                    child: ExcludeSemantics(
                      excluding: !widget.visible,
                      child: Opacity(
                        opacity: shown,
                        child: Transform.translate(
                          offset: Offset(0, (1 - shown) * hideSlide),
                          child: Transform.scale(
                            scale: hideScale + (1 - hideScale) * shown,
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  );
                },
                // The chrome is static: it must not rebuild on selection
                // ticks. Only the stack inside interactiveBody follows drivers.
                child: chrome,
              ),
            ),
          );
        },
      ),
    );

    if (!docked && effectiveSafeArea) {
      return SafeArea(top: false, child: bar);
    }
    return bar;
  }
}

class _DestinationButton extends StatefulWidget {
  const _DestinationButton({
    required this.destination,
    required this.factor,
    required this.selected,
    required this.enabled,
    required this.visuallyEnabled,
    required this.labelStyle,
    required this.iconSize,
    required this.scheme,
    required this.destinationColor,
    required this.badgeStyle,
    required this.surfaceBase,
    required this.selectColor,
    required this.hoverColor,
    required this.itemPadding,
    required this.iconLabelGap,
    required this.labelMode,
    required this.labelScale,
    required this.pillColor,
    required this.pillRadius,
    required this.reduced,
    required this.onTap,
    required this.onLongPress,
  });

  final OrionNavigationDestination destination;
  final double factor;
  final bool selected;
  final bool enabled;
  final bool visuallyEnabled;
  final TextStyle labelStyle;
  final double iconSize;
  final ColorScheme scheme;
  final WidgetStateProperty<Color?>? destinationColor;
  final OrionNavigationBadgeStyle badgeStyle;
  final Color surfaceBase;
  final Color selectColor;
  final Color hoverColor;
  final EdgeInsets itemPadding;
  final double iconLabelGap;
  final OrionNavigationLabelMode labelMode;
  final double labelScale;
  final Color? pillColor;
  final BorderRadius pillRadius;
  final bool reduced;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<_DestinationButton> createState() => _DestinationButtonState();
}

class _DestinationButtonState extends State<_DestinationButton> {
  bool _hovered = false;
  bool _lastBadgeWasDot = false;

  void _setHovered(bool value) {
    if (_hovered == value) {
      return;
    }
    setState(() => _hovered = value);
  }

  Widget _buildIcon(Color foreground) {
    final OrionNavigationDestination destination = widget.destination;
    final double shown = widget.factor.clamp(0.0, 1.0);
    final Widget iconWidget;
    if (destination.selectedIcon == null || shown <= 0.001) {
      iconWidget = destination.icon;
    } else if (shown >= 0.999) {
      iconWidget = destination.selectedIcon!;
    } else {
      iconWidget = Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Opacity(
            opacity: 1 - shown,
            child: ExcludeSemantics(
              excluding: shown >= 0.5,
              child: destination.icon,
            ),
          ),
          Opacity(
            opacity: shown,
            child: ExcludeSemantics(
              excluding: shown < 0.5,
              child: destination.selectedIcon!,
            ),
          ),
        ],
      );
    }

    return IconTheme.merge(
      data: IconThemeData(color: foreground, size: widget.iconSize),
      child: iconWidget,
    );
  }

  (Widget?, bool) _resolveBadgeContent() {
    final OrionNavigationDestination destination = widget.destination;
    if (destination.badge != null) {
      return (destination.badge, false);
    }
    final int? count = destination.badgeCount;
    if (count != null && count > 0) {
      final int? maxCount = destination.maxBadgeCount;
      final String display = (maxCount != null && count > maxCount)
          ? '$maxCount+'
          : '$count';
      return (
        Text(
          display,
          semanticsLabel: '$count',
          style: const TextStyle(
            fontFeatures: <FontFeature>[FontFeature.tabularFigures()],
          ),
        ),
        false,
      );
    }
    if (destination.badgeDot) {
      return (const SizedBox.shrink(), true);
    }
    return (null, false);
  }

  @override
  Widget build(BuildContext context) {
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionNavigationDestination destination = widget.destination;
    final bool hovered = _hovered && widget.enabled;

    // The layout follows the selection factor whatever the interactivity: a
    // disabled bar mutes through the resolved colours, it does not drop its
    // labels, its pill, or its slot widths.
    final double shown = widget.factor.clamp(0.0, 1.0);

    final Set<WidgetState> statesOff = <WidgetState>{
      if (!widget.visuallyEnabled) WidgetState.disabled,
      if (hovered) WidgetState.hovered,
    };
    final Set<WidgetState> statesOn = <WidgetState>{
      WidgetState.selected,
      if (!widget.visuallyEnabled) WidgetState.disabled,
      if (hovered) WidgetState.hovered,
    };
    final Color colorOff =
        widget.destinationColor?.resolve(statesOff) ??
        widget.scheme.onSurfaceVariant;
    final Color colorOn =
        widget.destinationColor?.resolve(statesOn) ?? widget.scheme.primary;

    final Color foreground = Color.lerp(colorOff, colorOn, shown) ?? colorOff;
    final FontWeight baseWeight = widget.labelStyle.fontWeight ?? FontWeight.w500;
    final FontWeight weight =
        FontWeight.lerp(baseWeight, _activeWeight(widget.labelStyle), shown) ??
        baseWeight;

    final Set<WidgetState> badgeStates = <WidgetState>{
      if (!widget.visuallyEnabled) WidgetState.disabled,
      if (widget.selected) WidgetState.selected,
      if (hovered) WidgetState.hovered,
    };

    final bool alwaysLabels = widget.labelMode == OrionNavigationLabelMode.all;
    final bool expands = widget.labelMode == OrionNavigationLabelMode.selected;
    final bool labelVisible = alwaysLabels || (expands && shown > 0);
    final bool hasCustomSemantics = destination.semanticLabel != null;

    final (Widget? badgeContent, bool badgeIsDot) = _resolveBadgeContent();
    if (badgeContent != null) {
      _lastBadgeWasDot = badgeIsDot;
    }
    final bool anchorDot = badgeContent != null ? badgeIsDot : _lastBadgeWasDot;

    // Match the cut-out ring to the live surface behind this destination so it
    // stays seamless over both the bar surface and the active selection pill.
    final Color activeSlotSurface = Color.alphaBlend(
      Color.lerp(Colors.transparent, widget.selectColor, shown) ??
          Colors.transparent,
      widget.surfaceBase,
    );
    final Color badgeRing = widget.badgeStyle.ringColor ?? activeSlotSurface;

    final Widget iconStack = ExcludeSemantics(
      excluding: hasCustomSemantics,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          _buildIcon(foreground),
          PositionedDirectional(
            top: anchorDot ? -2 : -6,
            end: anchorDot ? -3 : -7,
            child: IgnorePointer(
              child: _NavigationBadge(
                badge: badgeContent,
                isDot: badgeIsDot,
                reduced: widget.reduced,
                fill:
                    widget.badgeStyle.fill?.resolve(badgeStates) ??
                    widget.scheme.primary,
                ink:
                    widget.badgeStyle.ink?.resolve(badgeStates) ??
                    widget.scheme.onPrimary,
                textStyle: widget.badgeStyle.textStyle ?? widget.labelStyle,
                height: widget.badgeStyle.height ?? 16,
                minWidth: widget.badgeStyle.minWidth ?? 16,
                dotSize: widget.badgeStyle.dotSize ?? 8,
                padding:
                    widget.badgeStyle.padding ??
                    const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
                ring: badgeRing,
                ringWidth: widget.badgeStyle.ringWidth ?? 1.33,
              ),
            ),
          ),
        ],
      ),
    );

    final Widget label = ExcludeSemantics(
      excluding: hasCustomSemantics,
      child: Text(
        destination.label,
        maxLines: 1,
        softWrap: false,
        overflow: TextOverflow.fade,
        textAlign: TextAlign.center,
        style: widget.labelStyle.copyWith(color: foreground, fontWeight: weight),
      ),
    );

    final Widget content;
    if (alwaysLabels) {
      content = Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconStack,
          SizedBox(height: widget.iconLabelGap),
          label,
        ],
      );
    } else if (expands) {
      content = Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          iconStack,
          // The label's room follows the selection factor, so the slot grows
          // into the label and the text arrives with it.
          if (shown > 0)
            ClipRect(
              child: Align(
                alignment: AlignmentDirectional.centerStart,
                widthFactor: shown * widget.labelScale,
                // Without it the align expands to the incoming max height and
                // the whole capsule stretches with it.
                heightFactor: 1,
                child: Opacity(
                  opacity: shown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      SizedBox(width: widget.iconLabelGap),
                      label,
                    ],
                  ),
                ),
              ),
            ),
        ],
      );
    } else {
      content = iconStack;
    }

    final Widget body = Padding(
      padding: widget.itemPadding,
      child: Transform.scale(scale: 0.98 + (0.02 * shown), child: content),
    );

    final Color? slotBackground;
    if (widget.pillColor != null) {
      final Color pillFill =
          Color.lerp(Colors.transparent, widget.pillColor, shown) ??
          Colors.transparent;
      slotBackground = hovered && shown < 0.5
          ? Color.alphaBlend(widget.hoverColor, pillFill)
          : pillFill;
    } else {
      slotBackground = hovered && !widget.selected ? widget.hoverColor : null;
    }

    // The expanding mode gives each slot its own pill, fading with the
    // selection factor; the other modes leave the pill to the bar and only
    // paint a subtle hover tint on unselected hovered slots.
    final Widget slot = slotBackground == null
        ? body
        : DecoratedBox(
            decoration: BoxDecoration(
              color: slotBackground,
              borderRadius: widget.pillRadius,
            ),
            child: body,
          );

    final String? effectiveTooltip =
        destination.tooltip ??
        (widget.labelMode == OrionNavigationLabelMode.none
            ? destination.label
            : null);

    Widget interactive = MouseRegion(
      onEnter: (_) => _setHovered(true),
      onExit: (_) => _setHovered(false),
      child: OrionPressable(
        onTap: widget.onTap,
        onLongPress: widget.onLongPress,
        pressedScale: orion.pressScale,
        springSpec: orion.pressSpring,
        releaseSpringSpec: orion.releaseSpring,
        hapticType: OrionHapticType.none,
        // The reference's tab bar fires no haptic on a long press, so the
        // pressable's impact default is silenced too.
        impactHapticType: OrionHapticType.none,
        child: slot,
      ),
    );

    if (effectiveTooltip != null && effectiveTooltip.isNotEmpty) {
      interactive = Tooltip(
        message: effectiveTooltip,
        excludeFromSemantics: true,
        triggerMode: widget.onLongPress != null
            ? TooltipTriggerMode.manual
            : TooltipTriggerMode.longPress,
        child: interactive,
      );
    }

    return Semantics(
      container: true,
      button: true,
      selected: widget.selected,
      enabled: widget.enabled,
      inMutuallyExclusiveGroup: true,
      // A destination with an explicit semanticLabel owns its spoken name;
      // otherwise a hidden label keeps its spoken name while a shown label
      // speaks directly through its Text child to avoid double announcements.
      label: hasCustomSemantics
          ? destination.semanticLabel
          : (labelVisible ? null : destination.label),
      child: interactive,
    );
  }
}

/// The destination badge: a chip or compact dot at the icon's top-right, ringed
/// in the live slot surface so it reads as cut out of the icon beneath it. It
/// scales in when it appears, keeps its shape mounted while it scales out, and
/// lands instantly under reduced motion.
class _NavigationBadge extends StatefulWidget {
  const _NavigationBadge({
    required this.badge,
    required this.isDot,
    required this.reduced,
    required this.fill,
    required this.ink,
    required this.textStyle,
    required this.height,
    required this.minWidth,
    required this.dotSize,
    required this.padding,
    required this.ring,
    required this.ringWidth,
  });

  final Widget? badge;
  final bool isDot;
  final bool reduced;
  final Color fill;
  final Color ink;
  final TextStyle textStyle;
  final double height;
  final double minWidth;
  final double dotSize;
  final EdgeInsetsGeometry padding;
  final Color ring;
  final double ringWidth;

  @override
  State<_NavigationBadge> createState() => _NavigationBadgeState();
}

class _NavigationBadgeState extends State<_NavigationBadge> {
  /// The last presented badge content, kept mounted while the chip scales out
  /// so a dismissal animates instead of vanishing.
  Widget? _last;
  bool _lastIsDot = false;

  @override
  void initState() {
    super.initState();
    _last = widget.badge;
    _lastIsDot = widget.isDot;
  }

  @override
  void didUpdateWidget(_NavigationBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.badge != null) {
      _last = widget.badge;
      _lastIsDot = widget.isDot;
    }
  }

  Widget _chip(Widget content, {required bool isDot}) {
    final Border? ringBorder = widget.ringWidth > 0
        ? Border.all(color: widget.ring, width: widget.ringWidth)
        : null;
    if (isDot) {
      return Container(
        width: widget.dotSize,
        height: widget.dotSize,
        decoration: BoxDecoration(
          color: widget.fill,
          shape: BoxShape.circle,
          border: ringBorder,
        ),
      );
    }
    return Container(
      constraints: BoxConstraints(
        minWidth: widget.minWidth,
        minHeight: widget.height,
      ),
      padding: widget.padding,
      decoration: BoxDecoration(
        color: widget.fill,
        borderRadius: BorderRadius.circular(OrionRadii.radiusPill),
        border: ringBorder,
      ),
      child: Center(
        widthFactor: 1,
        heightFactor: 1,
        child: DefaultTextStyle(
          style: widget.textStyle.copyWith(color: widget.ink),
          child: content,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool present = widget.badge != null;
    final Widget? content = widget.badge ?? _last;
    final bool isDot = present ? widget.isDot : _lastIsDot;

    if (widget.reduced) {
      return present && content != null
          ? _chip(content, isDot: isDot)
          : const SizedBox.shrink();
    }
    final Widget chip = content == null
        ? const SizedBox.shrink()
        : _chip(content, isDot: isDot);
    // An implicit scale cannot animate a badge that is not there, so the
    // wrapper stays mounted and the chip rides the scale in and out. Exclude
    // departing badges from semantics immediately so screen readers never
    // announce a cleared badge mid-exit.
    return ExcludeSemantics(
      excluding: !present,
      child: AnimatedScale(
        scale: present ? 1 : 0,
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        onEnd: () {
          if (!present && _last != null) {
            setState(() {
              _last = null;
              _lastIsDot = false;
            });
          }
        },
        child: chip,
      ),
    );
  }
}
