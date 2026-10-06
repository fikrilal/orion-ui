import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// One option in an [OrionWheelPicker].
@immutable
class OrionWheelItem<T> {
  /// Creates a wheel option.
  const OrionWheelItem({
    required this.value,
    required this.label,
    this.semanticLabel,
  });

  /// Value reported when this item is centred.
  final T value;

  /// Visible content. A plain `Text` inherits the ambient `bodyLarge` style.
  final Widget label;

  /// Spoken name of this item.
  ///
  /// [label] is a widget, so the picker cannot read its text. Pass this when the
  /// label is not a plain [Text]; otherwise the spoken value falls back to the
  /// `Text` data, then to the item's position ("3 of 12").
  final String? semanticLabel;
}

/// A vertical wheel of items on one retargeted spring.
///
/// The offset is a single scalar in item units: an integer value means that item
/// is centred. A drag moves the offset directly, so the wheel tracks the finger
/// exactly; the release projects the finger's velocity into a landing detent, so
/// a flick carries two or three items and a slow release lands on the nearer
/// one. Only the settle is animated, on one [OrionSpringDriver], and its
/// [SpringSimulation] finishes exactly on the detent, never between two.
///
/// The drag moves the wheel directly rather than retargeting the spring on every
/// pointer event: a spring chasing a target that moves each frame always trails the
/// finger, and the gesture's velocity is the release's business, not the drag's. That
/// is this component's choice, not a limit of [OrionSpringDriver], which re-anchors its
/// simulation on retarget without restarting its clock.
///
/// The wheel claims every vertical drag that starts on it, so it must not sit inside a
/// vertically scrolling parent: give it a bounded, non-scrolling surface, and a bounded
/// width. Crossing a detent emits a single selection click while rolling, and keyboard
/// and tap moves stay silent. Arrow keys move one item, and Home and End jump to the
/// bounds.
///
/// See also [OrionSegmentedControl], which is the same one-of-many choice at a fixed
/// size rather than a rolling column.
class OrionWheelPicker<T> extends StatefulWidget {
  /// Creates a controlled wheel picker.
  const OrionWheelPicker({
    super.key,
    required this.items,
    required this.value,
    required this.onChanged,
    this.visibleItemCount = 5,
    this.semanticLabel,
    this.focusNode,
    this.autofocus = false,
  });

  /// Options, in wheel order. Must be non-empty, with unique values.
  final List<OrionWheelItem<T>> items;

  /// Currently centred value. Must equal one item's value.
  final T value;

  /// Called with the newly centred value once the wheel comes to rest on it.
  /// Null disables the wheel.
  final ValueChanged<T>? onChanged;

  /// How many item slots the wheel spans. Must be odd and at least 3, so one
  /// slot is the centre.
  final int visibleItemCount;

  /// Spoken name for the wheel, such as "Month". The centred item is announced
  /// separately as its value.
  final String? semanticLabel;

  /// Optional focus node for arrow-key movement.
  final FocusNode? focusNode;

  /// Whether the wheel requests focus on first build.
  final bool autofocus;

  @override
  State<OrionWheelPicker<T>> createState() => _OrionWheelPickerState<T>();
}

class _OrionWheelPickerState<T> extends State<OrionWheelPicker<T>>
    with SingleTickerProviderStateMixin {
  /// Row extent. Every row is its own 44 pt tap target, so the wheel is
  /// `visibleItemCount * _itemExtent` tall with no per-item measurement, and the
  /// rows cannot jitter as label widths differ.
  static const double _itemExtent = OrionSizing.minHitTarget;

  /// Scale of a row at the edge of the band.
  static const double _edgeScale = 0.7;

  /// How much of the release velocity projects into the landing distance, in
  /// seconds. A 1500 px/s flick is about 34 items per second, which projects
  /// roughly 2.7 items.
  static const double _projectionSeconds = 0.08;

  /// How much of an out-of-range drag reaches the wheel, as a fraction.
  static const double _endResistance = 0.35;

  /// Settles onto the landing detent. Critically damped, like
  /// [OrionSegmentedProgress] and the text field's release, because an
  /// underdamped settle overshoots far enough to cross the next boundary - the
  /// wheel would ring past the detent it aimed at and tick again.
  static const OrionSpringSpec _settleSpec = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  late final OrionSpringDriver _driver;
  FocusNode? _ownedFocusNode;
  OrionHapticType _haptic = OrionHapticType.selectionClick;
  bool _reduceMotion = false;
  bool _dragging = false;
  bool _focused = false;

  /// True while the movement comes from a discrete command (arrow, Home/End,
  /// tap) rather than from the wheel rolling under the finger. Discrete moves
  /// are silent, like the kit's other keyboard paths.
  bool _silent = false;

  /// The accumulated finger position in item units, including any out-of-range
  /// travel. The spring chases it; it is never assigned to the spring.
  double _rawOffset = 0;

  /// The rounded sample: what the window and the row highlight follow.
  late int _detent;

  /// The last detent reported to [OrionWheelPicker.onChanged].
  late int _committed;

  FocusNode get _focusNode => widget.focusNode ?? _ownedFocusNode!;

  bool get _enabled => widget.onChanged != null;

  int get _lastIndex => widget.items.length - 1;

  int get _sampleDetent => _driver.value.round().clamp(0, _lastIndex);

  @override
  void initState() {
    super.initState();
    _debugValidate();
    if (widget.focusNode == null) {
      _ownedFocusNode = FocusNode();
    }
    final int index = _indexOf(widget.value);
    _detent = math.max(index, 0);
    _committed = _detent;
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _detent.toDouble(),
      springSpec: _settleSpec,
    );
    _driver.addListener(_onTick);
    _driver.addStatusListener(_onStatus);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _haptic = OrionTheme.of(context).selectionHaptic;
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool becameReduced = reduce && !_reduceMotion;
    _reduceMotion = reduce;
    if (becameReduced) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !_reduceMotion) {
          return;
        }
        // A jump settles without a ticker, so its status never reaches
        // `completed`; the commit is explicit here.
        _driver.jumpTo(_driver.target);
        _commit();
      });
    }
  }

  @override
  void didUpdateWidget(OrionWheelPicker<T> oldWidget) {
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
    if (widget.items.length != oldWidget.items.length) {
      // A shorter list can strand an in-flight target past the last item.
      final int clamped = _driver.target.round().clamp(0, _lastIndex);
      _committed = clamped;
      _settleOn(clamped, silent: true);
    }
    if (oldWidget.onChanged != null && !_enabled && _dragging) {
      _dragging = false;
      _settleOn(_sampleDetent, silent: true);
    }
    if (widget.value != oldWidget.value && !_dragging) {
      final int index = _indexOf(widget.value);
      if (index >= 0 && index != _driver.target.round()) {
        _committed = index;
        _settleOn(index, silent: true);
      }
    }
  }

  @override
  void dispose() {
    _driver.removeListener(_onTick);
    _driver.removeStatusListener(_onStatus);
    _driver.dispose();
    _ownedFocusNode?.dispose();
    super.dispose();
  }

  int _indexOf(T value) =>
      widget.items.indexWhere((OrionWheelItem<T> item) => item.value == value);

  void _debugValidate() {
    assert(widget.items.isNotEmpty, 'items must not be empty');
    assert(_valuesAreUnique(widget.items), 'item values must be unique');
    assert(_indexOf(widget.value) >= 0, 'value must match an item');
    assert(
      widget.visibleItemCount >= 3 && widget.visibleItemCount.isOdd,
      'visibleItemCount must be odd and at least 3',
    );
  }

  bool _valuesAreUnique(List<OrionWheelItem<T>> items) {
    final Set<T> seen = <T>{};
    for (final OrionWheelItem<T> item in items) {
      if (!seen.add(item.value)) {
        return false;
      }
    }
    return true;
  }

  /// Emits the crossing haptic and follows the sample with the window.
  void _onTick() {
    final int detent = _sampleDetent;
    if (detent == _detent) {
      return;
    }
    _detent = detent;
    if (!_silent) {
      OrionHaptics.trigger(_haptic);
    }
    setState(() {});
  }

  /// Reports the detent the wheel has come to rest on, once.
  void _onStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed) {
      _commit();
    }
  }

  void _commit() {
    if (!mounted) {
      return;
    }
    final ValueChanged<T>? onChanged = widget.onChanged;
    if (onChanged == null) {
      return;
    }
    final int detent = _sampleDetent;
    if (detent == _committed) {
      return;
    }
    _committed = detent;
    onChanged(widget.items[detent].value);
  }

  /// Drags the wheel toward [raw], with resistance past either end.
  double _resisted(double raw) {
    if (raw < 0) {
      return raw * _endResistance;
    }
    if (raw > _lastIndex) {
      return _lastIndex + (raw - _lastIndex) * _endResistance;
    }
    return raw;
  }

  void _onDragStart(DragStartDetails details) {
    if (!_enabled) {
      return;
    }
    _dragging = true;
    _silent = false;
    _rawOffset = _driver.value;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    if (!_enabled || !_dragging) {
      return;
    }
    // Dragging up rolls toward later items, like dragging a list. The offset
    // follows the finger; nothing is reported until the wheel settles.
    _rawOffset += -details.delta.dy / _itemExtent;
    _driver.jumpTo(_resisted(_rawOffset));
  }

  void _onDragEnd(DragEndDetails details) {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _settleOn(_landingDetent(details.velocity));
  }

  void _onDragCancel() {
    if (!_dragging) {
      return;
    }
    _dragging = false;
    _settleOn(_sampleDetent);
  }

  /// The detent a release lands on: the finger's velocity, projected forward.
  ///
  /// A slow release has almost no velocity, so this is the nearest detent; a
  /// flick projects two or three items further on. This is where the drag
  /// velocity reaches the spring: it chooses how far the settle has to travel.
  int _landingDetent(Velocity velocity) {
    final double itemsPerSecond = -velocity.pixelsPerSecond.dy / _itemExtent;
    final double projected =
        _driver.value + itemsPerSecond * _projectionSeconds;
    return projected.round().clamp(0, _lastIndex);
  }

  /// Retargets the spring onto [detent].
  ///
  /// A discrete command (keyboard or tap) passes `silent: true` so its crossings
  /// do not tick; the glide that follows a drag keeps ticking.
  void _settleOn(int detent, {bool silent = false}) {
    _silent = silent;
    if (_reduceMotion) {
      _driver.jumpTo(detent.toDouble());
      _commit();
      return;
    }
    _driver.springSpec = _settleSpec;
    _driver.retarget(detent.toDouble());
  }

  /// Moves one detent from the last commanded one, for keys and screen readers.
  void _step(int delta, {required bool silent}) {
    if (!_enabled) {
      return;
    }
    final int next = (_driver.target.round() + delta).clamp(0, _lastIndex);
    _settleOn(next, silent: silent);
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || !_enabled) {
      return KeyEventResult.ignored;
    }
    switch (event.logicalKey) {
      case LogicalKeyboardKey.arrowUp:
        _step(-1, silent: true);
      case LogicalKeyboardKey.arrowDown:
        _step(1, silent: true);
      case LogicalKeyboardKey.home:
        _settleOn(0, silent: true);
      case LogicalKeyboardKey.end:
        _settleOn(_lastIndex, silent: true);
      default:
        return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  String _spokenValue(int index) {
    final OrionWheelItem<T> item = widget.items[index];
    final String? label = item.semanticLabel;
    if (label != null) {
      return label;
    }
    final Widget content = item.label;
    if (content is Text && content.data != null) {
      return content.data!;
    }
    return '${index + 1} of ${widget.items.length}';
  }

  @override
  Widget build(BuildContext context) {
    _debugValidate();
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = _enabled;
    final Color selectedColor = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);
    final Color idleColor = enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurface.withValues(alpha: 0.38);
    final TextStyle textStyle = theme.textTheme.bodyLarge ?? const TextStyle();
    final BorderRadius radius = BorderRadius.circular(OrionRadii.radius12);

    // The band reaches from the centre to `halo` items away, where the falloff
    // is zero; the window is built from the rounded detent so it only changes
    // when the wheel crosses a boundary, never on a ticker frame.
    final int halo = (widget.visibleItemCount + 1) ~/ 2;
    final int first = math.max(0, _detent - halo);
    final int last = math.min(_lastIndex, _detent + halo);
    final List<Widget> rows = <Widget>[
      for (int index = first; index <= last; index++)
        _WheelRow(
          key: ValueKey<int>(index),
          label: widget.items[index].label,
          textStyle: textStyle,
          color: index == _detent ? selectedColor : idleColor,
          enabled: enabled,
          onTap: enabled ? () => _settleOn(index, silent: true) : null,
        ),
    ];

    return Semantics(
      container: true,
      enabled: enabled,
      label: widget.semanticLabel,
      value: _spokenValue(_detent),
      increasedValue: _detent < _lastIndex ? _spokenValue(_detent + 1) : null,
      decreasedValue: _detent > 0 ? _spokenValue(_detent - 1) : null,
      // An end has no neighbour to step to, so it offers no such action.
      onIncrease: enabled && _detent < _lastIndex
          ? () => _step(1, silent: true)
          : null,
      onDecrease: enabled && _detent > 0 ? () => _step(-1, silent: true) : null,
      child: ExcludeSemantics(
        child: Focus(
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
                'OrionWheelPicker requires a bounded width.',
              );
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onVerticalDragStart: enabled ? _onDragStart : null,
                onVerticalDragUpdate: enabled ? _onDragUpdate : null,
                onVerticalDragEnd: enabled ? _onDragEnd : null,
                onVerticalDragCancel: enabled ? _onDragCancel : null,
                child: SizedBox(
                  width: constraints.maxWidth,
                  height: _itemExtent * widget.visibleItemCount,
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
                      child: AnimatedBuilder(
                        animation: _driver,
                        // The rows are built once per detent crossing and only
                        // wrapped here, so a ticker frame never rebuilds a label.
                        builder: (BuildContext context, Widget? child) {
                          final double sample = _driver.value;
                          return Stack(
                            children: <Widget>[
                              for (int i = 0; i < rows.length; i++)
                                _slot(
                                  row: rows[i],
                                  index: first + i,
                                  sample: sample,
                                  halo: halo,
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Places one row for the current spring sample.
  ///
  /// Position, scale, and fade all come from the same sample, so nothing can
  /// move out of step. The clamps are geometric bounds, not motion shaping: the
  /// falloff is zero at [halo] items out and one at the centre.
  Widget _slot({
    required Widget row,
    required int index,
    required double sample,
    required int halo,
  }) {
    final double distance = (index - sample).abs();
    final double falloff = (distance / halo).clamp(0.0, 1.0);
    final double top =
        (index - sample + (widget.visibleItemCount - 1) / 2) * _itemExtent;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      height: _itemExtent,
      child: Opacity(
        opacity: 1 - falloff,
        child: Transform.scale(
          scale: 1 - (1 - _edgeScale) * falloff,
          child: row,
        ),
      ),
    );
  }
}

/// One row of the wheel: a 44 pt tap target that centres its label.
class _WheelRow extends StatelessWidget {
  const _WheelRow({
    super.key,
    required this.label,
    required this.textStyle,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  final Widget label;
  final TextStyle textStyle;
  final Color color;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: IconTheme.merge(
            data: IconThemeData(color: color, size: OrionSizing.iconMedium),
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
