import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';

/// One period of a slot's column, in rows.
const int _period = 10;

/// Rows in the column: `0..9` printed twice, so the window can sit anywhere in
/// `[0, 10)` rows while still covering the row below it.
const int _columnRows = _period * 2;

/// A rolling digit odometer over a non-negative integer.
///
/// The parent owns [value]. The counter is a readout: it takes no taps, and owns
/// no callback, no hit target, no cursor, and no keyboard path, the way
/// `OrionBadge` is a readout.
///
/// ### Motion
///
/// One [OrionSpringDriver] per digit slot, each seeded on its own digit and only
/// ever moved by `retarget`. A slot is a one-line window over a static column of
/// `0..9` printed twice, translated by `-(p mod 10)` lines, where `p` is that
/// slot's continuous position. Ten rows is exactly one period of the column, so a
/// slot crossing a multiple of ten moves the column by one whole period and the
/// pixels at the window are identical on both sides of the crossing: the wrap
/// needs no clamp and no special case.
///
/// Direction belongs to the change, not to the digit. A slot's new target is its
/// current target plus the signed number of rows it must travel, so a `9`
/// becoming `0` on a growing value travels one row forward rather than unwinding
/// nine rows backward. A slot whose digit did not change is never retargeted, so
/// it never ticks and never moves while its neighbours are in flight.
///
/// Every slot shares one pre-built column as its ticker's `child`, so a frame
/// moves a transform and rebuilds nothing.
///
/// ### Typography
///
/// The resolved style is the ambient `DefaultTextStyle` merged with [style]. Every
/// slot is pinned to the widest digit of that style and
/// [FontFeature.tabularFigures] is requested on top. Pinning is the guarantee: a
/// proportional font cannot make the row twitch as digits change. The feature is
/// the polish, and degrades to a no-op where the font has no `tnum`.
///
/// ### Accessibility
///
/// The row is one semantics node carrying the formatted value and, when given,
/// [semanticLabel]. The glyphs are excluded, so a reader announces `128` once
/// instead of reading twenty digit rows.
class OrionCounter extends StatefulWidget {
  /// Creates a counter for [value].
  const OrionCounter({
    super.key,
    required this.value,
    this.style,
    this.semanticLabel,
    this.animate = true,
  }) : assert(value >= 0, 'OrionCounter renders non-negative values');

  /// The number to render. Negative values are out of scope for v1.
  final int value;

  /// Overrides for the ambient text style. Unset attributes are inherited.
  final TextStyle? style;

  /// Spoken name, for example `Unread`. The value is exposed separately.
  final String? semanticLabel;

  /// Whether a value change rolls. False renders the new value without travel.
  final bool animate;

  @override
  State<OrionCounter> createState() => _OrionCounterState();
}

class _OrionCounterState extends State<OrionCounter>
    with TickerProviderStateMixin {
  /// Travel spring for one row of digits.
  ///
  /// [OrionSpringSpec.snappy] and [OrionThemeData.pressSpring] are sized for the
  /// 0.96 to 1.0 press release; over a full row their ~30% overshoot would need a
  /// cap, and a cap on a longer travel is what stalls the motion. Gentle peaks at
  /// ~3.8% of one row, inside the resolved style's own leading, so it is left
  /// uncapped. The checkbox and the chip recorded the same decision.
  static const OrionSpringSpec _travel = OrionSpringSpec.gentle;

  /// Slots indexed by their distance from the right, so index 0 is the ones.
  final List<_DigitSlot> _slots = <_DigitSlot>[];

  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    final List<int> digits = _digitsOf(widget.value);
    for (var index = 0; index < digits.length; index++) {
      _slots.add(_createSlot(index, digits[index]));
    }
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
        _settle();
      });
    }
  }

  @override
  void didUpdateWidget(OrionCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    _reconcile(oldWidget.value);
    if (oldWidget.animate && !widget.animate) {
      _settle();
    }
  }

  @override
  void dispose() {
    for (final _DigitSlot slot in _slots) {
      slot.driver.dispose();
    }
    super.dispose();
  }

  /// Digits of [value], least significant first.
  static List<int> _digitsOf(int value) {
    final List<int> digits = <int>[];
    var rest = value;
    do {
      digits.add(rest % 10);
      rest ~/= 10;
    } while (rest > 0);
    return digits;
  }

  /// The digit this slot is resting on or travelling toward.
  static int _digitOf(double position) => position.round() % _period;

  _DigitSlot _createSlot(int index, int digit) {
    return _DigitSlot(
      index: index,
      // A new leading slot rests on its digit. Growing from 4 to 5 slots
      // re-lays out the row; it does not animate a fifth width into being.
      driver: OrionSpringDriver(
        vsync: this,
        initialValue: digit.toDouble(),
        springSpec: _travel,
      ),
    );
  }

  void _reconcile(int oldValue) {
    final int direction = widget.value.compareTo(oldValue);
    final List<int> digits = _digitsOf(widget.value);

    while (_slots.length < digits.length) {
      _slots.add(_createSlot(_slots.length, digits[_slots.length]));
    }
    while (_slots.length > digits.length) {
      // The element for this slot unmounts later in this same frame. The driver
      // clears its listeners on dispose, so its AnimatedBuilder's later
      // removeListener is a no-op.
      _slots.removeLast().driver.dispose();
    }

    if (direction == 0) {
      return;
    }
    for (final _DigitSlot slot in _slots) {
      _aim(slot, digits[slot.index], direction);
    }
  }

  /// Sends [slot] to [digit], travelling in [direction].
  ///
  /// The target is read from the driver's *target*, not its current position, so
  /// a retarget that lands mid-flight still steps from the digit it was heading
  /// for. An unchanged digit yields a zero delta, which leaves the driver alone:
  /// no retarget, no ticker, no motion.
  void _aim(_DigitSlot slot, int digit, int direction) {
    final double current = slot.driver.target;
    final int rest = _digitOf(current);
    final int steps = direction > 0
        ? (digit - rest) % _period
        : (rest - digit) % _period;
    if (steps == 0) {
      return;
    }
    _move(slot, current + direction * steps);
  }

  void _move(_DigitSlot slot, double target) {
    if (_reduceMotion || !widget.animate) {
      slot.driver.jumpTo(target);
      return;
    }
    slot.driver.retarget(target);
  }

  /// Settles every slot on the target it already has.
  void _settle() {
    for (final _DigitSlot slot in _slots) {
      slot.driver.jumpTo(slot.driver.target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle merged = DefaultTextStyle.of(
      context,
    ).style.merge(widget.style);
    final TextStyle effective = merged.copyWith(
      fontFeatures: <FontFeature>[
        ...?merged.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final (double lineHeight, double slotWidth) = _measure(
      effective,
      textScaler,
    );

    // Built once per widget build and handed to every slot as the ticker's
    // stable child, so a tick moves a transform and rebuilds no text.
    final Widget column = _DigitColumn(
      style: effective,
      textScaler: textScaler,
      lineHeight: lineHeight,
      slotWidth: slotWidth,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: widget.semanticLabel,
      value: widget.value.toString(),
      child: Row(
        // Numerals read left to right in every locale, so the digit order must
        // not follow the ambient direction. Without this the slots lay out
        // right-to-left under RTL and 123 renders as 321.
        textDirection: TextDirection.ltr,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (final _DigitSlot slot in _slots.reversed)
            _DigitWindow(
              key: ValueKey<int>(slot.index),
              driver: slot.driver,
              lineHeight: lineHeight,
              slotWidth: slotWidth,
              column: column,
            ),
        ],
      ),
    );
  }
}

/// One line of [style], and the widest digit in it.
///
/// The widest digit sets the slot width, so a proportional figure cannot move a
/// neighbour. Old-style figures vary in height as well, so the tallest digit sets
/// the line height and nothing clips.
(double, double) _measure(TextStyle style, TextScaler textScaler) {
  var lineHeight = 0.0;
  var slotWidth = 0.0;
  for (var digit = 0; digit < 10; digit++) {
    final TextPainter painter = TextPainter(
      text: TextSpan(text: '$digit', style: style),
      textDirection: TextDirection.ltr,
      textScaler: textScaler,
    )..layout();
    lineHeight = math.max(lineHeight, painter.height);
    slotWidth = math.max(slotWidth, painter.width);
  }
  return (lineHeight, slotWidth);
}

/// One digit slot's driver, and its distance from the right.
class _DigitSlot {
  const _DigitSlot({required this.index, required this.driver});

  /// 0 is the ones digit, 1 the tens, and so on.
  final int index;

  final OrionSpringDriver driver;
}

/// The clipped one-line window a slot rolls behind.
class _DigitWindow extends StatelessWidget {
  const _DigitWindow({
    super.key,
    required this.driver,
    required this.lineHeight,
    required this.slotWidth,
    required this.column,
  });

  final OrionSpringDriver driver;
  final double lineHeight;
  final double slotWidth;
  final Widget column;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: lineHeight,
      child: ClipRect(
        // The column is taller than the window; the window clips it.
        child: OverflowBox(
          alignment: Alignment.topLeft,
          maxHeight: double.infinity,
          child: AnimatedBuilder(
            animation: driver,
            child: column,
            builder: (BuildContext context, Widget? child) {
              // Dart's `%` is already non-negative for a positive divisor.
              final double row = driver.value % _period;
              return Transform.translate(
                offset: Offset(0, -row * lineHeight),
                child: child,
              );
            },
          ),
        ),
      ),
    );
  }
}

/// The static `0..9` column the windows roll behind, printed twice.
class _DigitColumn extends StatelessWidget {
  const _DigitColumn({
    required this.style,
    required this.textScaler,
    required this.lineHeight,
    required this.slotWidth,
  });

  final TextStyle style;
  final TextScaler textScaler;
  final double lineHeight;
  final double slotWidth;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: lineHeight * _columnRows,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          for (var row = 0; row < _columnRows; row++)
            SizedBox(
              width: slotWidth,
              height: lineHeight,
              child: Text(
                '${row % _period}',
                style: style,
                textScaler: textScaler,
                textAlign: TextAlign.center,
                maxLines: 1,
                softWrap: false,
              ),
            ),
        ],
      ),
    );
  }
}
