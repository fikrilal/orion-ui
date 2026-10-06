import 'dart:math' as math;

import 'package:flutter/material.dart';

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
class OrionAccordion extends StatefulWidget {
  /// Creates a controlled accordion.
  const OrionAccordion({
    super.key,
    required this.header,
    required this.child,
    required this.expanded,
    required this.onExpandedChanged,
    this.trailing,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Header content. The whole header is the tap target and typography is
  /// host-owned, so a plain `Text` keeps the ambient style.
  final Widget header;

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

  @override
  State<OrionAccordion> createState() => _OrionAccordionState();
}

class _OrionAccordionState extends State<OrionAccordion>
    with SingleTickerProviderStateMixin {
  /// Travel spring for the whole 0 to 1 reveal.
  ///
  /// [OrionSpringSpec.snappy] is sized for the documented 0.96 to 1.0 press
  /// release. Over a full travel its ~30% overshoot peaks at 1.297, which would
  /// stand the panel a third taller than its content, and any cap added to
  /// contain that would freeze the reveal mid-flight. [OrionSpringSpec.gentle]
  /// peaks at 1.038. The checkbox mark, the chip check, and the switch thumb ride
  /// the same spec for the same reason.
  static const OrionSpringSpec _travel = OrionSpringSpec.gentle;

  /// How far a disabled row's header is dimmed.
  static const double _disabledOpacity = 0.38;

  late final OrionSpringDriver _driver;
  bool _reduceMotion = false;
  bool _focused = false;

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
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
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
  void didUpdateWidget(OrionAccordion oldWidget) {
    super.didUpdateWidget(oldWidget);
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

  void _sync() {
    if (_reduceMotion) {
      _driver.jumpTo(_target);
    } else {
      _driver.retarget(_target);
    }
  }

  /// Reports the next value. The haptic belongs to [OrionPressable], so the
  /// keyboard path through [ActivateIntent] stays silent.
  void _toggle() {
    if (widget.onExpandedChanged == null) {
      return;
    }
    widget.onExpandedChanged!(!widget.expanded);
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final bool enabled = widget.onExpandedChanged != null;

    final Widget headerFace = DecoratedBox(
      position: DecorationPosition.foreground,
      decoration: BoxDecoration(
        // The ring is drawn over the header, so showing focus never moves the
        // content the caller put there.
        border: _focused && enabled
            ? Border.all(color: scheme.onSurface, width: 2)
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space16,
          vertical: OrionSpacing.space8,
        ),
        child: Row(
          children: <Widget>[
            Expanded(
              // An override replaces the header's own text as the spoken name,
              // the way the chip does with its label.
              child: widget.semanticLabel == null
                  ? widget.header
                  : ExcludeSemantics(child: widget.header),
            ),
            if (widget.trailing != null)
              widget.trailing!
            else
              Padding(
                padding: const EdgeInsets.only(left: OrionSpacing.space8),
                child: AnimatedBuilder(
                  animation: _driver,
                  // Built once per widget build, so a tick only rotates it.
                  child: const Icon(Icons.expand_more),
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
    );

    final Widget header = MergeSemantics(
      child: Semantics(
        container: true,
        button: true,
        expanded: widget.expanded,
        enabled: enabled,
        label: widget.semanticLabel,
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
            pressedScale: orion.pressScale,
            springSpec: orion.pressSpring,
            releaseSpringSpec: orion.releaseSpring,
            hapticType: orion.tapHaptic,
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
                  opacity: enabled ? 1 : _disabledOpacity,
                  child: headerFace,
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
            // The caller's content is built once and only ever clipped.
            child: widget.child,
            builder: (BuildContext context, Widget? child) {
              return Align(
                alignment: Alignment.topCenter,
                heightFactor: _reveal(_driver.value),
                child: child,
              );
            },
          ),
        ),
      ),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[header, panel],
    );
  }
}
