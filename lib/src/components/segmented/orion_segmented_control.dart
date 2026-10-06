import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One option in an [OrionSegmentedControl].
@immutable
class OrionSegment<T> {
  /// Creates a segment whose [label] is shown in the track.
  const OrionSegment({required this.value, required this.label});

  /// Value reported when this segment becomes selected.
  final T value;

  /// Visible content. Text uses `labelMedium`; icons inherit the label color.
  final Widget label;
}

/// Single-select pill track. The parent owns [value].
///
/// Segments share the width equally. The selected pill slides on
/// [OrionThemeData.pressSpring]. A bounded width is required.
class OrionSegmentedControl<T> extends StatefulWidget {
  /// Creates a controlled segmented control.
  const OrionSegmentedControl({
    super.key,
    required this.segments,
    required this.value,
    required this.onChanged,
    this.focusNode,
    this.autofocus = false,
  });

  /// Options, left to right. Must be non-empty, with unique values.
  final List<OrionSegment<T>> segments;

  /// Currently selected value. Must equal one segment's value.
  final T value;

  /// Called with the newly selected value. Null disables the control.
  ///
  /// Tapping the already selected segment does not call this.
  final ValueChanged<T>? onChanged;

  /// Optional focus node for arrow-key selection.
  final FocusNode? focusNode;

  /// Whether the control requests focus on first build.
  final bool autofocus;

  @override
  State<OrionSegmentedControl<T>> createState() =>
      _OrionSegmentedControlState<T>();
}

class _OrionSegmentedControlState<T> extends State<OrionSegmentedControl<T>>
    with SingleTickerProviderStateMixin {
  late final OrionSpringDriver _driver;
  FocusNode? _ownedFocusNode;
  bool _focused = false;
  bool _reduceMotion = false;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  @override
  void initState() {
    super.initState();
    _debugValidate();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    final int index = _indexOf(widget.value);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: index < 0 ? 0 : index.toDouble(),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _driver.springSpec = OrionTheme.of(context).pressSpring;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reduceMotion) {
          return;
        }
        final int index = _indexOf(widget.value);
        if (index >= 0) {
          _driver.jumpTo(index.toDouble());
        }
      });
    }
  }

  @override
  void didUpdateWidget(OrionSegmentedControl<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _debugValidate();
    if (widget.focusNode != oldWidget.focusNode) {
      if (widget.focusNode == null) {
        _ownedFocusNode ??= FocusNode();
      } else {
        _ownedFocusNode?.dispose();
        _ownedFocusNode = null;
      }
    }
    _syncPill();
  }

  @override
  void dispose() {
    _driver.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  int _indexOf(T value) {
    return widget.segments.indexWhere((segment) => segment.value == value);
  }

  void _debugValidate() {
    assert(widget.segments.isNotEmpty, 'segments must not be empty');
    assert(_valuesAreUnique(widget.segments), 'segment values must be unique');
    assert(_indexOf(widget.value) >= 0, 'value must match a segment');
  }

  bool _valuesAreUnique(List<OrionSegment<T>> segments) {
    final Set<T> seen = <T>{};
    for (final OrionSegment<T> segment in segments) {
      if (!seen.add(segment.value)) {
        return false;
      }
    }
    return true;
  }

  void _syncPill() {
    final int index = _indexOf(widget.value);
    if (index < 0) {
      return;
    }
    final double target = index.toDouble();
    if (_driver.target == target) {
      return;
    }
    if (_reduceMotion) {
      _driver.jumpTo(target);
    } else {
      _driver.retarget(target);
    }
  }

  void _select(T value) {
    if (widget.onChanged == null || value == widget.value) {
      return;
    }
    widget.onChanged!(value);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || widget.onChanged == null) {
      return KeyEventResult.ignored;
    }
    final bool rtl = Directionality.of(context) == TextDirection.rtl;
    final int delta = switch (event.logicalKey) {
      LogicalKeyboardKey.arrowRight => rtl ? -1 : 1,
      LogicalKeyboardKey.arrowLeft => rtl ? 1 : -1,
      _ => 0,
    };
    if (delta == 0) {
      return KeyEventResult.ignored;
    }
    final int current = _indexOf(widget.value);
    final int next = current + delta;
    if (current < 0 || next < 0 || next >= widget.segments.length) {
      return KeyEventResult.handled;
    }
    _select(widget.segments[next].value);
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionThemeData orion = OrionTheme.of(context);
    final TextStyle textStyle =
        theme.textTheme.labelMedium ?? const TextStyle();
    final bool enabled = widget.onChanged != null;
    final int selectedIndex = _indexOf(widget.value);
    final BorderRadius radius = BorderRadius.circular(OrionRadii.radiusPill);
    final Color disabledForeground = scheme.onSurface.withValues(alpha: 0.38);
    final Color trackColor = enabled
        ? scheme.secondary
        : scheme.onSurface.withValues(alpha: 0.12);

    final Widget segments = Padding(
      padding: const EdgeInsets.symmetric(horizontal: OrionSpacing.space4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          for (final OrionSegment<T> segment in widget.segments)
            Expanded(
              child: _SegmentButton(
                label: segment.label,
                selected: segment.value == widget.value,
                enabled: enabled,
                textStyle: textStyle,
                selectedColor: enabled ? scheme.onSurface : disabledForeground,
                idleColor: enabled
                    ? scheme.onSurfaceVariant
                    : disabledForeground,
                pressedScale: orion.pressScale,
                pressSpring: orion.pressSpring,
                releaseSpring: orion.releaseSpring,
                haptic: orion.selectionHaptic,
                onTap: enabled ? () => _select(segment.value) : null,
              ),
            ),
        ],
      ),
    );

    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      canRequestFocus: enabled,
      onFocusChange: (bool focused) {
        if (focused != _focused) {
          setState(() => _focused = focused);
        }
      },
      onKeyEvent: _onKey,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          assert(
            constraints.hasBoundedWidth,
            'OrionSegmentedControl requires a bounded width.',
          );
          final double slotWidth =
              (constraints.maxWidth - OrionSpacing.space4 * 2) /
              widget.segments.length;
          return SizedBox(
            width: constraints.maxWidth,
            height: OrionSizing.minHitTarget,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: trackColor,
                borderRadius: radius,
              ),
              child: DecoratedBox(
                position: DecorationPosition.foreground,
                decoration: BoxDecoration(
                  borderRadius: radius,
                  border: _focused && enabled
                      ? Border.all(color: scheme.onSurface, width: 2)
                      : null,
                ),
                child: ClipRRect(
                  borderRadius: radius,
                  child: Stack(
                    children: <Widget>[
                      if (selectedIndex >= 0)
                        PositionedDirectional(
                          start: OrionSpacing.space4,
                          top: OrionSpacing.space4,
                          bottom: OrionSpacing.space4,
                          width: slotWidth,
                          child: AnimatedBuilder(
                            animation: _driver,
                            builder: (BuildContext context, Widget? child) {
                              final double direction =
                                  Directionality.of(context) ==
                                      TextDirection.rtl
                                  ? -1
                                  : 1;
                              return Transform.translate(
                                offset: Offset(
                                  direction * _driver.value * slotWidth,
                                  0,
                                ),
                                child: child,
                              );
                            },
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: scheme.surface,
                                borderRadius: radius,
                              ),
                            ),
                          ),
                        ),
                      segments,
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.selected,
    required this.enabled,
    required this.textStyle,
    required this.selectedColor,
    required this.idleColor,
    required this.pressedScale,
    required this.pressSpring,
    required this.releaseSpring,
    required this.haptic,
    required this.onTap,
  });

  final Widget label;
  final bool selected;
  final bool enabled;
  final TextStyle textStyle;
  final Color selectedColor;
  final Color idleColor;
  final double pressedScale;
  final OrionSpringSpec pressSpring;
  final OrionSpringSpec releaseSpring;
  final OrionHapticType haptic;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = selected ? selectedColor : idleColor;
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: OrionPressable(
        onTap: selected ? null : onTap,
        pressedScale: pressedScale,
        springSpec: pressSpring,
        releaseSpringSpec: releaseSpring,
        hapticType: haptic,
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(color: color, size: OrionSizing.iconSmall),
            child: DefaultTextStyle(
              style: textStyle.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              child: label,
            ),
          ),
        ),
      ),
    );
  }
}
