import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:orion_ui/src/components/accordion/orion_accordion_presets.dart';
import 'package:orion_ui/src/components/accordion/orion_accordion_style.dart';
import 'package:orion_ui/src/components/accordion/orion_accordion_theme.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// The reveal sample both the panel extent and the chevron rotation read.
///
/// The floor is a geometric limit, not a shaping cap: [RenderPositionedBox]
/// asserts a non-negative `heightFactor`, and the collapse swing undershoots 0 by
/// ~3.9% of the travel. There is deliberately no ceiling. The gentle spring peaks
/// at 1.038, so the panel settles ~3.8% taller than its content for a frame or
/// two - the same soft pop the chip's check and the checkbox's mark have. A cap
/// there would stall the settle, which is the defect the chip's travel cap was
/// removed for.
double _reveal(double sample) => sample < 0 ? 0.0 : sample;

/// A controlled disclosure row: a header that toggles a panel of secondary
/// content.
///
/// The parent owns [expanded]. There is no group widget; compose a list and keep
/// at most one row open, the way the gallery does.
///
/// One [OrionSpringDriver] holds the 0 to 1 reveal fraction, and both consumers
/// read it through the same [_reveal] sample, so the panel's extent and the
/// chevron's rotation cannot disagree. The panel is a [ClipRect] around an
/// [Align] whose `heightFactor` is that sample: the content is laid out at its
/// natural height on every layout pass and only the clipped extent animates. The
/// content is the stable child of its [AnimatedBuilder], so no tick rebuilds it.
///
/// A bounded width is required. The header row is [Expanded] inside a stretched
/// [Column], so the header and the panel share one width.
///
/// The panel is always built - collapsed content keeps its state - and is removed
/// from the semantics tree and the focus order while [expanded] is false. Content
/// that measures itself late, such as an image or async text, simply makes the
/// panel taller when it resolves: the extent follows whatever the child reports
/// at that moment. Nested panels are not supported in v1; an inner row is clipped
/// and revealed with the outer one, and the outer header cannot reflect inner
/// state.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionAccordionPresets], the ambient [OrionAccordionTheme], and
/// the [style] passed here. Anything an override does not name falls through.
class OrionAccordion extends StatefulWidget {
  /// Creates a controlled accordion.
  const OrionAccordion({
    super.key,
    this.title,
    this.header,
    required this.child,
    required this.expanded,
    required this.onExpandedChanged,
    this.trailing,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
    this.style,
  }) : assert(
         (title != null) != (header != null),
         'Provide either title or header, not both.',
       );

  /// Plain text header rendered with semi-bold title typography.
  ///
  /// Mutually exclusive with [header]; use [header] for custom header layouts.
  final String? title;

  /// Custom header content. The whole header is the tap target and typography is
  /// host-owned, so a plain `Text` keeps the ambient style.
  ///
  /// Mutually exclusive with [title].
  final Widget? header;

  /// Panel content, revealed below the header. It is laid out at its natural
  /// height, so it must size itself vertically.
  final Widget child;

  /// Whether the panel is open. The parent owns the value.
  final bool expanded;

  /// Called with the opposite of [expanded]. Null disables the row.
  final ValueChanged<bool>? onExpandedChanged;

  /// Replaces the default chevron, which is a rotated [Icons.expand_more]
  /// inheriting the ambient [IconTheme].
  ///
  /// A supplied widget does not rotate: the rotation belongs to the chevron this
  /// component owns, so a caller who replaces it owns its motion too.
  final Widget? trailing;

  /// Spoken name in place of the header's own text.
  final String? semanticLabel;

  /// Optional focus node for keyboard activation.
  final FocusNode? focusNode;

  /// Whether the row requests focus on first build.
  final bool autofocus;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionAccordionTheme]. Only the fields set here change.
  final OrionAccordionStyle? style;

  @override
  State<OrionAccordion> createState() => _OrionAccordionState();
}

class _OrionAccordionState extends State<OrionAccordion>
    with SingleTickerProviderStateMixin {
  static const OrionSpringSpec _travel =
      OrionAccordionPresets.defaultExpandSpring;

  static const OrionSpringSpec _collapse =
      OrionAccordionPresets.defaultCollapseSpring;

  late final OrionSpringDriver _driver;
  bool _focused = false;
  bool _hovered = false;
  bool _pressed = false;

  @override
  void initState() {
    super.initState();
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: _travel,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncMotion();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_driver.reducedMotion;
    _driver.reducedMotion = reduce;
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
  void didUpdateWidget(OrionAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncMotion();
    if (widget.expanded != oldWidget.expanded) {
      _sync();
    }
  }

  @override
  void dispose() {
    _driver.dispose();
    super.dispose();
  }

  double get _target => widget.expanded ? 1 : 0;

  /// Sets the driver's spec from the resolved style, chosen by direction: the
  /// open and the close can be retuned independently.
  void _syncMotion() {
    final OrionAccordionStyle style = _resolve(Theme.of(context));
    _driver.springSpec = _target >= 1
        ? (style.expandSpring ?? _travel)
        : (style.collapseSpring ?? _collapse);
  }

  void _sync() {
    _syncMotion();
    _driver.retarget(_target);
  }

  OrionAccordionStyle _resolve(ThemeData theme) {
    final OrionAccordionTheme accordionTheme =
        theme.extension<OrionAccordionTheme>() ?? OrionAccordionTheme.fallback;
    return OrionAccordionPresets.resolve(
      scheme: theme.colorScheme,
    ).merge(accordionTheme.defaultStyle).merge(widget.style);
  }

  /// Reports the next value. The haptic belongs to [OrionPressable], so the
  /// keyboard path through [ActivateIntent] stays silent.
  void _toggle() {
    if (widget.onExpandedChanged == null) {
      return;
    }
    widget.onExpandedChanged!(!widget.expanded);
  }

  void _onPressedChanged(bool pressed) {
    if (!mounted || _pressed == pressed) {
      return;
    }
    if (SchedulerBinding.instance.schedulerPhase ==
        SchedulerPhase.persistentCallbacks) {
      SchedulerBinding.instance.addPostFrameCallback((Duration _) {
        _onPressedChanged(pressed);
      });
      return;
    }
    setState(() => _pressed = pressed);
  }

  void _setHovered(bool hovered) {
    if (!mounted || _hovered == hovered) {
      return;
    }
    setState(() => _hovered = hovered);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final OrionAccordionStyle style = _resolve(theme);
    final bool enabled = widget.onExpandedChanged != null;
    final double ringWidth = style.focusRingWidth ?? 2;
    final double disabledOpacity = style.disabledOpacity ?? 0.38;
    final EdgeInsetsGeometry headerPadding =
        style.headerPadding ??
        const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space16,
          vertical: OrionSpacing.space8,
        );
    final EdgeInsetsGeometry contentPadding =
        style.contentPadding ??
        const EdgeInsets.fromLTRB(
          OrionSpacing.space16,
          0,
          OrionSpacing.space16,
          OrionSpacing.space12,
        );
    final Color? headerWash = !enabled
        ? null
        : _pressed
        ? style.headerPressedColor
        : _hovered
        ? style.headerHoverColor
        : null;
    final Widget headerContent =
        widget.header ??
        Text(
          widget.title!,
          style: (theme.textTheme.titleSmall ?? const TextStyle()).copyWith(
            fontWeight: FontWeight.w600,
            color: scheme.onSurface,
          ),
        );

    final Widget headerFace = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        // The ring is drawn over the header, so showing focus never moves the
        // content the caller put there.
        border: _focused && enabled
            ? Border.all(
                color: style.focusRingColor ?? scheme.onSurface,
                width: ringWidth,
              )
            : null,
      ),
      child: ColoredBox(
        color: headerWash ?? Colors.transparent,
        child: Padding(
          padding: headerPadding,
          child: Row(
            children: <Widget>[
              Expanded(
                // An override replaces the header's own text as the spoken name,
                // the way the chip does with its label.
                child: widget.semanticLabel == null
                    ? headerContent
                    : ExcludeSemantics(child: headerContent),
              ),
              if (widget.trailing != null)
                widget.trailing!
              else
                Padding(
                  padding: const EdgeInsets.only(left: OrionSpacing.space8),
                  child: AnimatedBuilder(
                    animation: _driver,
                    // Built once per widget build, so a tick only rotates it.
                    child: Icon(Icons.expand_more, color: style.iconColor),
                    builder: (BuildContext context, Widget? child) {
                      return Transform.rotate(
                        angle: _reveal(_driver.value) * math.pi,
                        child: child,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    final Widget header = MergeSemantics(
      child: Semantics(
        container: true,
        button: true,
        expanded: widget.expanded,
        enabled: enabled,
        label: widget.semanticLabel,
        child: MouseRegion(
          onEnter: (_) => _setHovered(true),
          onExit: (_) => _setHovered(false),
          child: FocusableActionDetector(
            enabled: enabled,
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
                  _toggle();
                  return null;
                },
              ),
            },
            child: OrionPressable(
              onTap: enabled ? _toggle : null,
              pressedScale: style.pressedScale ?? 1.0,
              springSpec: orion.pressSpring,
              releaseSpringSpec: orion.releaseSpring,
              hapticType: orion.selectionHaptic,
              onPressedChanged: _onPressedChanged,
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  minWidth: OrionSizing.minHitTarget,
                  minHeight: OrionSizing.minHitTarget,
                ),
                child: Center(
                  widthFactor: 1,
                  heightFactor: 1,
                  // Dimming is owned here rather than by the caller: the row is
                  // the thing that is disabled, and the header slot takes
                  // arbitrary content that must not be recoloured.
                  child: Opacity(
                    opacity: enabled ? 1 : disabledOpacity,
                    child: headerFace,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );

    // Collapsed content keeps its state but leaves the semantics tree and the
    // focus order. Both are keyed on `expanded`, the parent's truth, so the panel
    // stops being announced or reachable as soon as it starts to close.
    final Widget panel = ExcludeFocus(
      excluding: !widget.expanded,
      child: ExcludeSemantics(
        excluding: !widget.expanded,
        child: ClipRect(
          child: AnimatedBuilder(
            animation: _driver,
            // The caller's content is wrapped with aligned contentPadding and held stable.
            child: Padding(padding: contentPadding, child: widget.child),
            builder: (BuildContext context, Widget? child) {
              final double factor = _reveal(_driver.value);
              return Align(
                alignment: Alignment.topLeft,
                heightFactor: factor,
                child: Opacity(
                  opacity: factor.clamp(0.0, 1.0),
                  child: child,
                ),
              );
            },
          ),
        ),
      ),
    );

    Widget body = Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[header, panel],
    );

    if (style.backgroundColor != null || style.borderColor != null) {
      final BorderRadius radius =
          style.borderRadius ?? BorderRadius.circular(OrionRadii.radius12);
      body = Container(
        decoration: BoxDecoration(
          color: style.backgroundColor,
          borderRadius: radius,
          border: Border.all(
            color:
                style.borderColor ??
                scheme.outlineVariant.withValues(alpha: 0.30),
            width: style.borderWidth ?? 1,
          ),
        ),
        child: ClipRRect(borderRadius: radius, child: body),
      );
    }

    return body;
  }
}
