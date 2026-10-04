import 'package:flutter/material.dart';

import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// A single-line field. The parent owns the string.
///
/// Focus paints a hairline ring on [OrionThemeData.pressSpring]. Losing focus
/// settles on a critically damped spring so the ring does not flash back on.
/// The caret stays the platform caret. A non-empty [error] replaces [helper]
/// and paints the border with [ColorScheme.error].
class OrionTextField extends StatefulWidget {
  /// Creates a single-line field.
  const OrionTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.enabled = true,
    this.label,
    this.hint,
    this.error,
    this.helper,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.onSubmitted,
    this.autofocus = false,
  });

  /// Optional controller. When omitted, the field owns one.
  final TextEditingController? controller;

  /// Optional focus node. When omitted, the field owns one.
  final FocusNode? focusNode;

  /// Called with the field text after each edit.
  final ValueChanged<String>? onChanged;

  /// False mutes the field and ignores edits.
  final bool enabled;

  /// Text shown above the face.
  final String? label;

  /// Placeholder shown while the field is empty.
  final String? hint;

  /// Non-empty paints an error border and replaces [helper].
  final String? error;

  /// Quiet note under the face. Hidden while [error] is non-empty.
  final String? helper;

  /// Hides the characters, for a password.
  final bool obscureText;

  /// Keyboard layout for the field.
  final TextInputType? keyboardType;

  /// Action button on the keyboard.
  final TextInputAction? textInputAction;

  /// Called when the user submits the field.
  final ValueChanged<String>? onSubmitted;

  /// Whether the field requests focus on first build.
  final bool autofocus;

  @override
  State<OrionTextField> createState() => _OrionTextFieldState();
}

class _OrionTextFieldState extends State<OrionTextField>
    with SingleTickerProviderStateMixin {
  static const double _restingStrength = 0.16;
  static const double _strengthCap = 0.24;
  static const OrionSpringSpec _releaseSpec = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
  );

  late final OrionSpringDriver _driver;
  late TextEditingController _controller;
  late FocusNode _focusNode;
  bool _ownsController = false;
  bool _ownsFocus = false;
  bool _focusBound = false;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _bindController(widget.controller);
    _bindFocus(widget.focusNode);
    _driver = OrionSpringDriver(
      vsync: this,
      initialValue: _target,
      springSpec: OrionSpringSpec.snappy,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _driver.springSpec = _specFor(_target);
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
  void didUpdateWidget(OrionTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      _bindController(widget.controller);
    }
    var retarget = false;
    if (widget.focusNode != oldWidget.focusNode) {
      _bindFocus(widget.focusNode);
      retarget = true;
    }
    if (widget.enabled != oldWidget.enabled) {
      retarget = true;
    }
    if (retarget) {
      _sync();
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocus);
    if (_ownsFocus) {
      _focusNode.dispose();
    }
    if (_ownsController) {
      _controller.dispose();
    }
    _driver.dispose();
    super.dispose();
  }

  double get _target => widget.enabled && _focusNode.hasFocus ? 1 : 0;

  OrionSpringSpec _specFor(double target) {
    if (target == 0) {
      return _releaseSpec;
    }
    return OrionTheme.of(context).pressSpring;
  }

  void _bindController(TextEditingController? incoming) {
    if (_ownsController) {
      _controller.dispose();
    }
    _ownsController = incoming == null;
    _controller = incoming ?? TextEditingController();
  }

  void _bindFocus(FocusNode? incoming) {
    if (_focusBound) {
      _focusNode.removeListener(_onFocus);
      if (_ownsFocus) {
        _focusNode.dispose();
      }
    }
    _ownsFocus = incoming == null;
    _focusNode = incoming ?? FocusNode();
    _focusNode.addListener(_onFocus);
    _focusBound = true;
  }

  void _onFocus() {
    _sync();
  }

  void _sync() {
    if (_reduceMotion) {
      _driver.jumpTo(_target);
      return;
    }
    _driver.springSpec = _specFor(_target);
    _driver.retarget(_target);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = widget.enabled;
    final bool hasError = widget.error != null && widget.error!.isNotEmpty;
    final String? caption = hasError ? widget.error : widget.helper;
    final TextStyle body = theme.textTheme.bodyLarge ?? const TextStyle();
    final Color textColor = enabled
        ? scheme.onSurface
        : scheme.onSurface.withValues(alpha: 0.38);
    final Color hintColor = enabled
        ? scheme.onSurfaceVariant
        : scheme.onSurface.withValues(alpha: 0.38);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (widget.label != null) ...<Widget>[
          ExcludeSemantics(
            child: Text(
              widget.label!,
              style: theme.textTheme.labelMedium?.copyWith(color: textColor),
            ),
          ),
          const SizedBox(height: OrionSpacing.space8),
        ],
        AnimatedBuilder(
          animation: _driver,
          builder: (BuildContext context, Widget? child) {
            final double sample = _driver.value;
            final double clamped = sample.clamp(0.0, 1.0);
            final double strength = (sample * _restingStrength).clamp(
              0.0,
              _strengthCap,
            );
            final bool showRing = enabled && !hasError && strength > 0;
            final Color borderColor = !enabled
                ? scheme.onSurface.withValues(alpha: 0.12)
                : hasError
                ? scheme.error
                : Color.lerp(scheme.outline, scheme.onSurface, clamped)!;
            return MouseRegion(
              cursor: enabled ? SystemMouseCursors.text : MouseCursor.defer,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                excludeFromSemantics: true,
                onTap: enabled ? () => _focusNode.requestFocus() : null,
                child: SizedBox(
                  height: OrionSizing.controlHeightLarge,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: scheme.surface,
                      borderRadius: BorderRadius.circular(OrionRadii.radius8),
                      border: Border.all(color: borderColor),
                      boxShadow: showRing
                          ? <BoxShadow>[
                              BoxShadow(
                                color: scheme.onSurface.withValues(
                                  alpha: strength,
                                ),
                                spreadRadius: 1,
                              ),
                            ]
                          : null,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: OrionSpacing.space12,
                      ),
                      child: Center(child: child),
                    ),
                  ),
                ),
              ),
            );
          },
          child: Semantics(
            label: widget.label,
            child: TextField(
              controller: _controller,
              focusNode: _focusNode,
              enabled: enabled,
              onChanged: enabled ? widget.onChanged : null,
              obscureText: widget.obscureText,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              onSubmitted: widget.onSubmitted,
              autofocus: widget.autofocus,
              style: body.copyWith(color: textColor),
              cursorColor: scheme.onSurface,
              decoration: InputDecoration(
                hintText: widget.hint,
                hintStyle: body.copyWith(color: hintColor),
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                disabledBorder: InputBorder.none,
                errorBorder: InputBorder.none,
                focusedErrorBorder: InputBorder.none,
              ),
            ),
          ),
        ),
        if (caption != null) ...<Widget>[
          const SizedBox(height: OrionSpacing.space8),
          Text(
            caption,
            style: theme.textTheme.bodySmall?.copyWith(
              color: hasError ? scheme.error : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}
