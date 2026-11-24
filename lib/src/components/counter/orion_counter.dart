import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'package:orion_ui/src/components/counter/orion_counter_presets.dart';
import 'package:orion_ui/src/components/counter/orion_counter_style.dart';
import 'package:orion_ui/src/components/counter/orion_counter_theme.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';

/// One period of a slot's column, in rows.
const int _period = 10;

/// Rows in the column: `0..9` printed twice, so the window can sit anywhere in
/// `[0, 10)` rows while still covering the row below it.
const int _columnRows = _period * 2;

/// Duration for smooth width and sign transitions when slot count or sign
/// changes.
const Duration _layoutTransitionDuration = Duration(milliseconds: 220);

/// A rolling digit odometer for integers and decimals.
///
/// The parent owns [value]. The counter is a readout: it takes no taps, and owns
/// no callback, no hit target, no cursor, and no keyboard path, the way
/// `OrionBadge` is a readout.
///
/// Supports negative values, fixed-precision decimals ([fractionDigits]),
/// zero-padded minimum integer digits ([minDigits]), thousands grouping
/// ([thousandSeparator]), and optional [prefix] / [suffix] text without external
/// formatting dependencies.
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
/// Direction belongs to the change in magnitude, so both positive (`9 -> 10`)
/// and negative (`-9 -> -10`) carries travel one row forward rather than
/// unwinding nine rows backward. A slot whose digit did not change is never
/// retargeted, so it never ticks and never moves while its neighbours are in
/// flight.
///
/// Every slot shares one pre-built column as its ticker's `child`, so a frame
/// moves a transform and rebuilds nothing.
///
/// ### Typography
///
/// The resolved style is the ambient `DefaultTextStyle` merged with the
/// effective `textStyle`. Every slot is pinned to the widest digit of that
/// style and [FontFeature.tabularFigures] is requested on top. Pinning is the
/// guarantee: a proportional font cannot make the row twitch as digits change.
/// Measured metrics are cached by `(TextStyle, TextScaler)` and the underlying
/// [TextPainter] is disposed immediately after measurement.
///
/// Look and feel resolve in three layers, each overriding the last: the
/// built-in [OrionCounterPresets], the ambient [OrionCounterTheme], and the
/// [style] / [textStyle] passed here.
///
/// ### Accessibility
///
/// The row is one semantics node carrying the formatted value (including sign,
/// separators, prefix, and suffix) and, when given, [semanticLabel]. The digit
/// glyphs are excluded, so a screen reader announces the readout once instead of
/// reading twenty digit rows.
class OrionCounter extends StatefulWidget {
  /// Creates a counter for [value].
  const OrionCounter({
    super.key,
    required this.value,
    this.fractionDigits = 0,
    this.minDigits = 1,
    this.thousandSeparator,
    this.decimalSeparator = '.',
    this.prefix,
    this.suffix,
    this.showPositiveSign = false,
    this.textStyle,
    this.style,
    this.semanticLabel,
    this.animate = true,
    this.fadeEdges,
  }) : assert(
         value == value &&
             value != double.infinity &&
             value != double.negativeInfinity,
         'OrionCounter value must be finite',
       ),
       assert(fractionDigits >= 0, 'fractionDigits must be >= 0'),
       assert(minDigits >= 1, 'minDigits must be >= 1');

  /// The number to render. Supports integers, decimals, and negative values.
  final num value;

  /// Number of digits rendered after [decimalSeparator]. Defaults to `0`.
  final int fractionDigits;

  /// Minimum number of integer digits rendered (zero-padded on the left).
  /// Useful for timers and countdowns (for example `minDigits: 2` renders `09`).
  final int minDigits;

  /// Optional grouping separator inserted every three integer digits (for
  /// example `','` renders `1,000,000`).
  final String? thousandSeparator;

  /// Separator rendered between integer and fractional digits when
  /// [fractionDigits] is greater than zero. Defaults to `'.'`.
  final String decimalSeparator;

  /// Optional static text rendered between the sign and the leading digit (for
  /// example `'\$'` renders `-\$12.50`).
  final String? prefix;

  /// Optional static text rendered after the trailing digit (for example `'%'`
  /// or `' pts'`).
  final String? suffix;

  /// Whether to render a leading `'+'` sign for strictly positive values.
  /// Zero never displays a sign.
  final bool showPositiveSign;

  /// Direct text style shorthand, merged on top of the ambient
  /// `DefaultTextStyle` and [OrionCounterTheme].
  final TextStyle? textStyle;

  /// Instance-level overrides, merged over the presets and the ambient
  /// [OrionCounterTheme]. Only the fields set here change.
  final OrionCounterStyle? style;

  /// Spoken name, for example `Unread`. The formatted value is exposed
  /// separately.
  final String? semanticLabel;

  /// Whether a value change rolls. False renders the new value without travel.
  final bool animate;

  /// Whether rolling digits softly fade near the top and bottom clip edges
  /// while in motion. When null, resolves from [style] / [OrionCounterTheme] /
  /// [OrionCounterPresets] (defaults to `true`).
  final bool? fadeEdges;

  @override
  State<OrionCounter> createState() => _OrionCounterState();
}

class _OrionCounterState extends State<OrionCounter>
    with TickerProviderStateMixin {
  /// Slots indexed by their distance from the right, so index 0 is the
  /// rightmost digit.
  final List<_DigitSlot> _slots = <_DigitSlot>[];

  /// The resolved style, refreshed on dependency and widget changes.
  late OrionCounterStyle _style;

  /// The current parsed representation of [OrionCounter.value].
  late _ParsedCounterValue _parsed;

  /// Mirrors the platform's reduced-motion setting for every slot's driver.
  bool _reduceMotion = false;

  /// Cached glyph metrics for `(effectiveStyle, textScaler)`.
  TextStyle? _measuredStyle;
  TextScaler? _measuredScaler;
  double _cachedLineHeight = 0;
  double _cachedSlotWidth = 0;

  @override
  void initState() {
    super.initState();
    _style = OrionCounterPresets.resolve();
    _parsed = _ParsedCounterValue.parse(
      value: widget.value,
      fractionDigits: widget.fractionDigits,
      minDigits: widget.minDigits,
    );
    for (var index = 0; index < _parsed.digits.length; index++) {
      _slots.add(_createSlot(index, _parsed.digits[index]));
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncStyle();
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
    _syncStyle();
    final _ParsedCounterValue previous = _parsed;
    final _ParsedCounterValue next = _ParsedCounterValue.parse(
      value: widget.value,
      fractionDigits: widget.fractionDigits,
      minDigits: widget.minDigits,
    );
    _parsed = next;
    _reconcile(
      previous: previous,
      next: next,
      fractionChanged: oldWidget.fractionDigits != widget.fractionDigits,
    );
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

  void _syncStyle() {
    final ThemeData theme = Theme.of(context);
    final OrionCounterTheme counterTheme =
        theme.extension<OrionCounterTheme>() ?? OrionCounterTheme.fallback;
    _style = OrionCounterPresets.resolve()
        .merge(counterTheme.defaultStyle)
        .merge(
          widget.textStyle == null
              ? null
              : OrionCounterStyle(textStyle: widget.textStyle),
        )
        .merge(widget.style)
        .merge(
          widget.fadeEdges == null
              ? null
              : OrionCounterStyle(fadeEdges: widget.fadeEdges),
        );
    for (final _DigitSlot slot in _slots) {
      slot.driver.springSpec = _style.spring ?? OrionCounterPresets.defaultSpring;
    }
  }

  /// The digit this slot is resting on or travelling toward.
  static int _digitOf(double position) => position.round() % _period;

  _DigitSlot _createSlot(int index, int digit) {
    return _DigitSlot(
      index: index,
      // A new leading slot rests on its digit while AnimatedSize smoothly
      // expands the row width from the trailing anchor.
      driver: OrionSpringDriver(
        vsync: this,
        initialValue: digit.toDouble(),
        springSpec: _style.spring ?? OrionCounterPresets.defaultSpring,
      ),
    );
  }

  void _reconcile({
    required _ParsedCounterValue previous,
    required _ParsedCounterValue next,
    required bool fractionChanged,
  }) {
    final List<int> digits = next.digits;

    if (fractionChanged) {
      for (final _DigitSlot slot in _slots) {
        slot.driver.dispose();
      }
      _slots.clear();
      for (var index = 0; index < digits.length; index++) {
        _slots.add(_createSlot(index, digits[index]));
      }
      return;
    }

    final int direction = next.compareMagnitude(previous);

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

  (double, double) _measureCached(TextStyle style, TextScaler textScaler) {
    if (_measuredStyle == style && _measuredScaler == textScaler) {
      return (_cachedLineHeight, _cachedSlotWidth);
    }
    final (double lineHeight, double slotWidth) = _measure(style, textScaler);
    _measuredStyle = style;
    _measuredScaler = textScaler;
    _cachedLineHeight = lineHeight;
    _cachedSlotWidth = slotWidth;
    return (lineHeight, slotWidth);
  }

  Widget _staticToken(
    String text, {
    required TextStyle style,
    required TextScaler textScaler,
    required double lineHeight,
    Key? key,
  }) {
    return SizedBox(
      key: key,
      height: lineHeight,
      child: Align(
        alignment: Alignment.center,
        widthFactor: 1,
        child: Text(
          text,
          style: style,
          textScaler: textScaler,
          maxLines: 1,
          softWrap: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final TextStyle merged = DefaultTextStyle.of(
      context,
    ).style.merge(_style.textStyle);
    final TextStyle effective = merged.copyWith(
      fontFeatures: <FontFeature>[
        ...?merged.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
    final TextScaler textScaler = MediaQuery.textScalerOf(context);
    final (double lineHeight, double slotWidth) = _measureCached(
      effective,
      textScaler,
    );

    final bool shouldAnimate = widget.animate && !_reduceMotion;
    final Duration layoutDuration = shouldAnimate
        ? _layoutTransitionDuration
        : Duration.zero;
    final double stretchX = _style.rollStretchX ?? 0.06;
    final double squashY = _style.rollSquashY ?? 0.10;
    final bool fadeEdges = _style.fadeEdges ?? true;

    // Built once per widget build and handed to every slot as the ticker's
    // stable child, so a tick moves a transform and rebuilds no text.
    final Widget column = _DigitColumn(
      style: effective,
      textScaler: textScaler,
      lineHeight: lineHeight,
      slotWidth: slotWidth,
    );

    final String signText = _parsed.sign < 0
        ? '-'
        : (widget.showPositiveSign && _parsed.sign > 0 ? '+' : '');
    final String? separator = widget.thousandSeparator;
    final bool hasSeparator = separator != null && separator.isNotEmpty;
    final int fractionDigits = widget.fractionDigits;

    final List<Widget> children = <Widget>[
      AnimatedSwitcher(
        duration: layoutDuration,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeOutCubic,
        transitionBuilder: (Widget child, Animation<double> animation) =>
            FadeTransition(opacity: animation, child: child),
        child: signText.isEmpty
            ? const SizedBox.shrink(key: ValueKey<String>('sign:none'))
            : _staticToken(
                signText,
                key: ValueKey<String>('sign:$signText'),
                style: effective,
                textScaler: textScaler,
                lineHeight: lineHeight,
              ),
      ),
      if (widget.prefix != null && widget.prefix!.isNotEmpty)
        _staticToken(
          widget.prefix!,
          style: effective,
          textScaler: textScaler,
          lineHeight: lineHeight,
        ),
    ];

    // Integer slots, most-significant first, with optional thousands grouping.
    for (int i = _slots.length - 1; i >= fractionDigits; i--) {
      if (hasSeparator &&
          i < _slots.length - 1 &&
          (i - fractionDigits + 1) % 3 == 0) {
        children.add(
          _staticToken(
            separator,
            style: effective,
            textScaler: textScaler,
            lineHeight: lineHeight,
          ),
        );
      }
      final _DigitSlot slot = _slots[i];
      children.add(
        _DigitWindow(
          key: ValueKey<int>(slot.index),
          driver: slot.driver,
          lineHeight: lineHeight,
          slotWidth: slotWidth,
          stretchX: stretchX,
          squashY: squashY,
          fadeEdges: fadeEdges,
          column: column,
        ),
      );
    }

    // Decimal separator and fractional slots, most-significant first.
    if (fractionDigits > 0) {
      children.add(
        _staticToken(
          widget.decimalSeparator,
          style: effective,
          textScaler: textScaler,
          lineHeight: lineHeight,
        ),
      );
      for (int i = fractionDigits - 1; i >= 0; i--) {
        final _DigitSlot slot = _slots[i];
        children.add(
          _DigitWindow(
            key: ValueKey<int>(slot.index),
            driver: slot.driver,
            lineHeight: lineHeight,
            slotWidth: slotWidth,
            stretchX: stretchX,
            squashY: squashY,
            fadeEdges: fadeEdges,
            column: column,
          ),
        );
      }
    }

    if (widget.suffix != null && widget.suffix!.isNotEmpty) {
      children.add(
        _staticToken(
          widget.suffix!,
          style: effective,
          textScaler: textScaler,
          lineHeight: lineHeight,
        ),
      );
    }

    final String formatted = _parsed.format(
      thousandSeparator: widget.thousandSeparator,
      decimalSeparator: widget.decimalSeparator,
      prefix: widget.prefix,
      suffix: widget.suffix,
      showPositiveSign: widget.showPositiveSign,
    );

    return Semantics(
      container: true,
      excludeSemantics: true,
      label: widget.semanticLabel,
      value: formatted,
      child: AnimatedSize(
        duration: layoutDuration,
        curve: Curves.easeOutCubic,
        alignment: Alignment.centerRight,
        child: Row(
          // Numerals read left to right in every locale, so the digit order
          // must not follow the ambient direction. Without this the slots lay
          // out right-to-left under RTL and 123 renders as 321.
          textDirection: TextDirection.ltr,
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }
}

/// Normalized decimal digits and sign for an [OrionCounter] value.
class _ParsedCounterValue {
  const _ParsedCounterValue({
    required this.sign,
    required this.intPart,
    required this.paddedInt,
    required this.fracPart,
    required this.digits,
  });

  /// `-1` for negative, `0` for zero (including `-0.0`), `1` for positive.
  final int sign;

  /// Unpadded integer digits string without sign (for example `'0'`, `'128'`).
  final String intPart;

  /// Integer digits zero-padded on the left to at least `minDigits`.
  final String paddedInt;

  /// Fractional digits string (empty when `fractionDigits == 0`).
  final String fracPart;

  /// All rendered digits least-significant first (index 0 = rightmost digit).
  final List<int> digits;

  factory _ParsedCounterValue.parse({
    required num value,
    required int fractionDigits,
    required int minDigits,
  }) {
    final String raw = fractionDigits == 0 && value is int
        ? value.toString()
        : value.toStringAsFixed(fractionDigits);
    final bool negativeRaw = raw.startsWith('-');
    final String unsigned = negativeRaw ? raw.substring(1) : raw;
    final int dot = unsigned.indexOf('.');
    final String intPart = dot == -1 ? unsigned : unsigned.substring(0, dot);
    final String fracPart = dot == -1 ? '' : unsigned.substring(dot + 1);

    final bool allZero = _isAllZeros(intPart) && _isAllZeros(fracPart);
    final int sign = allZero ? 0 : (negativeRaw ? -1 : 1);
    final String paddedInt = intPart.padLeft(minDigits, '0');

    final List<int> digits = <int>[];
    for (int i = fracPart.length - 1; i >= 0; i--) {
      digits.add(fracPart.codeUnitAt(i) - 48);
    }
    for (int i = paddedInt.length - 1; i >= 0; i--) {
      digits.add(paddedInt.codeUnitAt(i) - 48);
    }

    return _ParsedCounterValue(
      sign: sign,
      intPart: intPart,
      paddedInt: paddedInt,
      fracPart: fracPart,
      digits: digits,
    );
  }

  static bool _isAllZeros(String s) {
    for (int i = 0; i < s.length; i++) {
      if (s.codeUnitAt(i) != 48) {
        return false;
      }
    }
    return true;
  }

  /// Compares non-negative magnitudes without floating-point drift.
  int compareMagnitude(_ParsedCounterValue other) {
    if (intPart.length != other.intPart.length) {
      return intPart.length.compareTo(other.intPart.length);
    }
    final int intCmp = intPart.compareTo(other.intPart);
    if (intCmp != 0) {
      return intCmp;
    }
    return fracPart.compareTo(other.fracPart);
  }

  /// Formats the full readout string for semantics.
  String format({
    required String? thousandSeparator,
    required String decimalSeparator,
    required String? prefix,
    required String? suffix,
    required bool showPositiveSign,
  }) {
    final StringBuffer buffer = StringBuffer();
    if (sign < 0) {
      buffer.write('-');
    } else if (showPositiveSign && sign > 0) {
      buffer.write('+');
    }
    if (prefix != null && prefix.isNotEmpty) {
      buffer.write(prefix);
    }
    final bool hasSeparator =
        thousandSeparator != null && thousandSeparator.isNotEmpty;
    for (int i = 0; i < paddedInt.length; i++) {
      final int remaining = paddedInt.length - i;
      if (hasSeparator && i > 0 && remaining % 3 == 0) {
        buffer.write(thousandSeparator);
      }
      buffer.write(paddedInt[i]);
    }
    if (fracPart.isNotEmpty) {
      buffer.write(decimalSeparator);
      buffer.write(fracPart);
    }
    if (suffix != null && suffix.isNotEmpty) {
      buffer.write(suffix);
    }
    return buffer.toString();
  }
}

/// One line of [style], and the widest digit in it.
///
/// Reuses one [TextPainter] across digits 0..9 and disposes it before returning
/// so no native paragraph resources leak.
(double, double) _measure(TextStyle style, TextScaler textScaler) {
  var lineHeight = 0.0;
  var slotWidth = 0.0;
  final TextPainter painter = TextPainter(
    textDirection: TextDirection.ltr,
    textScaler: textScaler,
  );
  try {
    for (var digit = 0; digit < 10; digit++) {
      painter
        ..text = TextSpan(text: '$digit', style: style)
        ..layout();
      lineHeight = math.max(lineHeight, painter.height);
      slotWidth = math.max(slotWidth, painter.width);
    }
  } finally {
    painter.dispose();
  }
  return (lineHeight, slotWidth);
}

/// One digit slot's driver, and its distance from the right.
class _DigitSlot {
  const _DigitSlot({required this.index, required this.driver});

  /// 0 is the rightmost digit, 1 is the next left, and so on.
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
    required this.stretchX,
    required this.squashY,
    required this.fadeEdges,
    required this.column,
  });

  final OrionSpringDriver driver;
  final double lineHeight;
  final double slotWidth;
  final double stretchX;
  final double squashY;
  final bool fadeEdges;
  final Widget column;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: slotWidth,
      height: lineHeight,
      child: ClipRect(
        child: AnimatedBuilder(
          animation: driver,
          child: column,
          builder: (BuildContext context, Widget? child) {
            // Dart's `%` is already non-negative for a positive divisor.
            final double row = driver.value % _period;
            // How far this digit is from resting on a row: zero at rest, at
            // most a half mid-roll. A rolling digit squashes and recovers so
            // travel reads as weight rather than a flat slide.
            final double motion =
                (driver.value - driver.value.roundToDouble()).abs();
            final double squash = (motion * 2).clamp(0.0, 1.0);
            return _EdgeFadeMask(
              intensity: fadeEdges ? squash : 0.0,
              child: OverflowBox(
                alignment: Alignment.topLeft,
                maxHeight: double.infinity,
                child: Transform(
                  // Pivot on the row the window is showing. Aligning to the
                  // column's centre would pivot ten rows below a twenty row
                  // column, dragging the visible digit out of its window.
                  origin: Offset(slotWidth / 2, (row + 0.5) * lineHeight),
                  transform: Matrix4.diagonal3Values(
                    1 + stretchX * squash,
                    1 - squashY * squash,
                    1,
                  )..setTranslationRaw(0, -row * lineHeight, 0),
                  child: child,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Motion-aware vertical edge fade mask.
///
/// At rest (`intensity <= 0.001`), paints its child directly with zero
/// offscreen `saveLayer` overhead and full glyph crispness. While rolling,
/// fades the top and bottom 16% of the slot proportionally to [intensity].
class _EdgeFadeMask extends SingleChildRenderObjectWidget {
  const _EdgeFadeMask({required this.intensity, required super.child});

  final double intensity;

  @override
  _RenderEdgeFadeMask createRenderObject(BuildContext context) {
    return _RenderEdgeFadeMask(intensity: intensity);
  }

  @override
  void updateRenderObject(
    BuildContext context,
    _RenderEdgeFadeMask renderObject,
  ) {
    renderObject.intensity = intensity;
  }
}

class _RenderEdgeFadeMask extends RenderProxyBox {
  _RenderEdgeFadeMask({required double intensity}) : _intensity = intensity;

  double _intensity;
  double get intensity => _intensity;
  set intensity(double value) {
    if (_intensity == value) {
      return;
    }
    _intensity = value;
    markNeedsPaint();
  }

  @override
  void paint(PaintingContext context, Offset offset) {
    final RenderBox? child = this.child;
    if (child == null) {
      return;
    }
    if (_intensity <= 0.001 || size.isEmpty) {
      context.paintChild(child, offset);
      return;
    }
    final Rect bounds = offset & size;
    final double edgeAlpha = (1.0 - _intensity).clamp(0.0, 1.0);
    context.canvas.saveLayer(bounds, Paint());
    context.paintChild(child, offset);
    final Paint maskPaint = Paint()
      ..blendMode = BlendMode.dstIn
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: <Color>[
          Color.fromRGBO(255, 255, 255, edgeAlpha),
          Colors.white,
          Colors.white,
          Color.fromRGBO(255, 255, 255, edgeAlpha),
        ],
        stops: const <double>[0.0, 0.16, 0.84, 1.0],
      ).createShader(bounds);
    context.canvas.drawRect(bounds, maskPaint);
    context.canvas.restore();
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
