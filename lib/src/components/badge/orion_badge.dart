import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/badge/orion_badge_presets.dart';
import 'package:orion_ui/src/components/badge/orion_badge_style.dart';
import 'package:orion_ui/src/components/badge/orion_badge_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Pill size. [medium] is the default and matches the original badge metrics.
enum OrionBadgeSize { small, medium, large }

/// Colour role of an [OrionBadge]. Each maps to a [ColorScheme] pair, with
/// [outline] drawing the scheme's outline as a border.
enum OrionBadgeVariant { neutral, primary, secondary, error, outline }

/// Small pill-shaped label, status indicator or counter.
///
/// Three forms: a host-owned [child] label, a decorative [OrionBadge.dot], and
/// a numeric [OrionBadge.count] whose figures are tabular and whose change
/// pops the pill and morphs its width on the kit's springs - instant under
/// reduced motion.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionBadgePresets], the ambient [OrionBadgeTheme], and the
/// [style] passed here. Anything an override does not name falls through.
class OrionBadge extends StatefulWidget {
  /// Creates a badge whose [label] or [child] is shown in the pill.
  const OrionBadge({
    super.key,
    this.label,
    this.child,
    this.variant = OrionBadgeVariant.neutral,
    this.size = OrionBadgeSize.medium,
    this.style,
  }) : value = null,
       maxCount = null,
       assert(
         (label != null) != (child != null),
         'Provide either label or child, not both.',
       );

  /// Creates a bare status dot: a circle of the variant's background colour,
  /// `dotSize` across, with no content and no semantics.
  const OrionBadge.dot({
    super.key,
    this.variant = OrionBadgeVariant.neutral,
    this.size = OrionBadgeSize.medium,
    this.style,
  }) : label = null,
       child = null,
       value = null,
       maxCount = null;

  /// Creates a numeric counter. Figures are tabular; when [maxCount] is set
  /// the display caps at `"99+"` while the semantics name the true value.
  const OrionBadge.count({
    super.key,
    required int this.value,
    this.maxCount,
    this.variant = OrionBadgeVariant.neutral,
    this.size = OrionBadgeSize.medium,
    this.style,
  }) : label = null,
       child = null,
       assert(value >= 0, 'value must not be negative'),
       assert(maxCount == null || maxCount > 0, 'maxCount must be positive');

  /// Plain text label shorthand; mutually exclusive with [child].
  final String? label;

  /// Badge content; null for [OrionBadge.dot], [OrionBadge.count], and when
  /// [label] is provided.
  final Widget? child;

  /// Counter value; null for label and dot badges.
  final int? value;

  /// Optional cap for [value]. Null shows the value in full.
  final int? maxCount;

  /// Colour role. Defaults to [OrionBadgeVariant.neutral].
  final OrionBadgeVariant variant;

  /// Padding and text style step. Defaults to [OrionBadgeSize.medium].
  final OrionBadgeSize size;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionBadgeTheme]. Only the fields set here change.
  final OrionBadgeStyle? style;

  @override
  State<OrionBadge> createState() => _OrionBadgeState();
}

class _OrionBadgeState extends State<OrionBadge>
    with SingleTickerProviderStateMixin {
  late final OrionSpringDriver _pop;
  double _popScale = 1.1;

  @override
  void initState() {
    super.initState();
    _pop = OrionSpringDriver(vsync: this, initialValue: 1);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _configure();
  }

  @override
  void didUpdateWidget(OrionBadge oldWidget) {
    super.didUpdateWidget(oldWidget);
    _configure();
    if (widget.value != null &&
        oldWidget.value != null &&
        widget.value != oldWidget.value) {
      _play();
    }
  }

  @override
  void dispose() {
    _pop.dispose();
    super.dispose();
  }

  void _configure() {
    final ThemeData theme = Theme.of(context);
    final OrionThemeData orion = OrionTheme.of(context);
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final OrionBadgeStyle style = _resolveStyle(theme);
    _popScale = style.popScale ?? 1.1;
    _pop.springSpec = style.popSpring ?? orion.pressSpring;
    _pop.reducedMotion = reduced;
    if (reduced && _pop.value != 1) {
      _pop.jumpTo(1);
    }
  }

  void _play() {
    if (_pop.reducedMotion) {
      return;
    }
    _pop.jumpTo(_popScale);
    _pop.retarget(1);
  }

  OrionBadgeStyle _resolveStyle(ThemeData theme) {
    final OrionBadgeTheme badgeTheme =
        theme.extension<OrionBadgeTheme>() ?? OrionBadgeTheme.fallback;
    return OrionBadgePresets.resolve(
          variant: widget.variant,
          size: widget.size,
          scheme: theme.colorScheme,
          textTheme: theme.textTheme,
        )
        .merge(badgeTheme.defaultStyle)
        .merge(badgeTheme.variantStyles?[widget.variant])
        .merge(widget.style);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final OrionBadgeStyle style = _resolveStyle(theme);
    final Color background = style.background ?? scheme.surfaceContainerHighest;
    final Color foreground = style.foreground ?? scheme.onSurfaceVariant;
    final BorderSide? border = style.border;
    final BoxBorder? resolvedBorder = border == null || border.width == 0
        ? null
        : Border.fromBorderSide(border);
    final bool isDot =
        widget.label == null && widget.child == null && widget.value == null;

    if (isDot) {
      return ExcludeSemantics(
        child: SizedBox.square(
          dimension: style.dotSize ?? 8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: resolvedBorder,
            ),
          ),
        ),
      );
    }

    final Widget content;
    if (widget.label != null || widget.child != null) {
      final Widget body =
          widget.child ??
          Text(widget.label!, maxLines: 1, overflow: TextOverflow.ellipsis);
      content = IconTheme.merge(
        data: IconThemeData(color: foreground, size: OrionSizing.iconSmall),
        child: DefaultTextStyle(
          style: (style.textStyle ?? const TextStyle()).copyWith(
            color: foreground,
          ),
          child: body,
        ),
      );
    } else {
      final int count = widget.value!;
      final String display = widget.maxCount != null && count > widget.maxCount!
          ? '${widget.maxCount}+'
          : '$count';
      content = DefaultTextStyle(
        style: (style.textStyle ?? const TextStyle()).copyWith(
          color: foreground,
          // Tabular figures keep a changing count from jittering.
          fontFeatures: const <FontFeature>[FontFeature.tabularFigures()],
        ),
        child: Text(display),
      );
    }

    final Widget pill = DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius:
            style.radius ?? BorderRadius.circular(OrionRadii.radiusPill),
        border: resolvedBorder,
      ),
      child: Padding(padding: style.padding ?? EdgeInsets.zero, child: content),
    );

    Widget result = AnimatedBuilder(
      animation: _pop,
      builder: (BuildContext context, Widget? child) =>
          Transform.scale(scale: _pop.value, child: child),
      child: pill,
    );
    // An animated size cannot run at zero duration (it would re-dirty itself
    // mid-layout), so reduced motion swaps the wrapper out entirely and a
    // resize lands in one frame.
    if (!reduced) {
      result = AnimatedSize(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        alignment: Alignment.center,
        child: result,
      );
    }
    if (widget.value != null) {
      // The capped display must not hide the real value from a screen reader.
      return Semantics(
        label: '${widget.value}',
        excludeSemantics: true,
        child: result,
      );
    }
    return result;
  }
}
