import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/radio/orion_radio.dart';
import 'package:orion_ui/src/components/radio/orion_radio_style.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Visual presentation of each option inside [OrionRadioGroup].
enum OrionRadioGroupVariant {
  /// Plain clickable radio rows with label and optional subtitle. The default.
  plain,

  /// Rounded selectable cards with animated border/surface highlight and
  /// full-card tactile press feedback.
  card,
}

/// One typed choice rendered by [OrionRadioGroup].
@immutable
class OrionRadioOption<T> {
  const OrionRadioOption({
    required this.value,
    required this.label,
    this.subtitle,
    this.trailing,
    this.enabled = true,
    this.semanticLabel,
  });

  /// Logical value represented by this option.
  final T value;

  /// Primary visible label text.
  final String label;

  /// Optional supporting description beneath [label].
  final String? subtitle;

  /// Optional trailing widget (for example a price, badge, or icon).
  final Widget? trailing;

  /// Whether this individual option can be selected.
  final bool enabled;

  /// Optional spoken override for screen readers. Defaults to [label].
  final String? semanticLabel;
}

/// A managed, typed group of mutually exclusive [OrionRadio] choices.
///
/// Features:
/// - **Typed single-choice API**: pass [options], [value], and [onChanged]
///   instead of hand-wiring individual radio booleans.
/// - **WAI-ARIA keyboard navigation**: roving `Tab` entry onto the selected
///   (or first enabled) option, with `ArrowUp`/`ArrowDown`/`ArrowLeft`/
///   `ArrowRight` (RTL-aware, wrapping, skipping disabled options) plus
///   `Home`/`End` moving focus and selection together.
/// - **Plain and card layouts**: render compact label rows or bordered
///   selectable tiles in vertical lists or wrapping horizontal strips.
/// - **Form integration**: optional [label], [helper], [error], [hasError],
///   [validator], and [autovalidateMode] matching `OrionTextField` and
///   `OrionDropdown`.
class OrionRadioGroup<T> extends StatefulWidget {
  const OrionRadioGroup({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.label,
    this.helper,
    this.error,
    this.hasError = false,
    this.validator,
    this.autovalidateMode,
    this.enabled = true,
    this.direction = Axis.vertical,
    this.variant = OrionRadioGroupVariant.plain,
    this.size = OrionRadioSize.medium,
    this.spacing,
    this.runSpacing = OrionSpacing.space8,
    this.radioStyle,
    this.semanticLabel,
  }) : assert(
         spacing == null || spacing >= 0,
         'spacing must be greater than or equal to zero.',
       ),
       assert(
         runSpacing >= 0,
         'runSpacing must be greater than or equal to zero.',
       );

  /// The choices to render in order.
  final List<OrionRadioOption<T>> options;

  /// Currently selected value, or `null` when nothing is selected yet.
  final T? value;

  /// Called with the newly chosen option's value. Null disables the group.
  final ValueChanged<T>? onChanged;

  /// Optional group heading displayed above the options.
  final String? label;

  /// Optional supporting text displayed beneath the options when no error
  /// message is active.
  final String? helper;

  /// Optional validation error message. A non-empty string replaces [helper]
  /// and tints every option with the error role.
  final String? error;

  /// Forces the error visual state even when [error] is null or empty.
  final bool hasError;

  /// Optional [FormField] validator evaluated against [value].
  final FormFieldValidator<T>? validator;

  /// Controls when [validator] runs automatically.
  final AutovalidateMode? autovalidateMode;

  /// Master enabled flag for all options in the group.
  final bool enabled;

  /// Lays options out vertically in a column or horizontally in a wrapping row.
  final Axis direction;

  /// Plain clickable rows or bordered selectable cards.
  final OrionRadioGroupVariant variant;

  /// Size step forwarded to every [OrionRadio] indicator in the group.
  final OrionRadioSize size;

  /// Space between adjacent options along [direction]. Defaults to `4` for
  /// vertical plain rows, `16` for horizontal plain rows, and `8` for cards.
  final double? spacing;

  /// Cross-axis spacing between wrapped lines when [direction] is
  /// [Axis.horizontal].
  final double runSpacing;

  /// Optional style override forwarded to every [OrionRadio] indicator.
  final OrionRadioStyle? radioStyle;

  /// Optional spoken group label for screen readers. Defaults to [label].
  final String? semanticLabel;

  @override
  State<OrionRadioGroup<T>> createState() => _OrionRadioGroupState<T>();
}

class _OrionRadioGroupState<T> extends State<OrionRadioGroup<T>> {
  final GlobalKey<FormFieldState<T>> _fieldKey = GlobalKey<FormFieldState<T>>();
  final List<FocusNode> _focusNodes = <FocusNode>[];

  bool get _groupEnabled => widget.enabled && widget.onChanged != null;

  bool _isOptionEnabled(int index) =>
      _groupEnabled && widget.options[index].enabled;

  @override
  void initState() {
    super.initState();
    _syncFocusNodes();
  }

  @override
  void didUpdateWidget(OrionRadioGroup<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncFocusNodes();
    if (widget.value != oldWidget.value) {
      final FormFieldState<T>? field = _fieldKey.currentState;
      if (field != null && field.value != widget.value) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) {
            return;
          }
          final FormFieldState<T>? currentField = _fieldKey.currentState;
          if (currentField != null && currentField.value != widget.value) {
            currentField.didChange(widget.value);
          }
        });
      }
    }
  }

  @override
  void dispose() {
    for (final FocusNode node in _focusNodes) {
      node.dispose();
    }
    _focusNodes.clear();
    super.dispose();
  }

  void _syncFocusNodes() {
    final int count = widget.options.length;
    while (_focusNodes.length < count) {
      _focusNodes.add(
        FocusNode(debugLabel: 'OrionRadioGroup option ${_focusNodes.length}'),
      );
    }
    while (_focusNodes.length > count) {
      _focusNodes.removeLast().dispose();
    }

    int entryIndex = -1;
    for (int i = 0; i < count; i++) {
      if (_isOptionEnabled(i) && widget.options[i].value == widget.value) {
        entryIndex = i;
        break;
      }
    }
    if (entryIndex == -1) {
      for (int i = 0; i < count; i++) {
        if (_isOptionEnabled(i)) {
          entryIndex = i;
          break;
        }
      }
    }

    for (int i = 0; i < count; i++) {
      final bool enabled = _isOptionEnabled(i);
      final FocusNode node = _focusNodes[i];
      node.skipTraversal = !enabled || i != entryIndex;
    }
  }

  void _selectOption(T nextValue, FormFieldState<T> field) {
    if (!_groupEnabled) {
      return;
    }
    field.didChange(nextValue);
    widget.onChanged?.call(nextValue);
  }

  KeyEventResult _handleKeyEvent(
    BuildContext context,
    KeyEvent event,
    FormFieldState<T> field,
  ) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    if (!_groupEnabled || widget.options.isEmpty) {
      return KeyEventResult.ignored;
    }

    final int focusedIndex = _focusNodes.indexWhere(
      (FocusNode node) => node.hasFocus,
    );
    if (focusedIndex == -1) {
      return KeyEventResult.ignored;
    }

    final LogicalKeyboardKey key = event.logicalKey;
    final bool isRtl = Directionality.of(context) == TextDirection.rtl;

    int? targetIndex;
    if (key == LogicalKeyboardKey.arrowDown) {
      targetIndex = _findAdjacentEnabled(focusedIndex, 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      targetIndex = _findAdjacentEnabled(focusedIndex, -1);
    } else if (key == LogicalKeyboardKey.arrowRight) {
      targetIndex = _findAdjacentEnabled(focusedIndex, isRtl ? -1 : 1);
    } else if (key == LogicalKeyboardKey.arrowLeft) {
      targetIndex = _findAdjacentEnabled(focusedIndex, isRtl ? 1 : -1);
    } else if (key == LogicalKeyboardKey.home) {
      targetIndex = _findBoundaryEnabled(fromStart: true);
    } else if (key == LogicalKeyboardKey.end) {
      targetIndex = _findBoundaryEnabled(fromStart: false);
    } else {
      return KeyEventResult.ignored;
    }

    if (targetIndex != null) {
      _focusNodes[targetIndex].requestFocus();
      final T nextValue = widget.options[targetIndex].value;
      if (targetIndex != focusedIndex || widget.value != nextValue) {
        _selectOption(nextValue, field);
      }
    }
    return KeyEventResult.handled;
  }

  int? _findAdjacentEnabled(int fromIndex, int delta) {
    final int count = widget.options.length;
    for (int step = 1; step <= count; step++) {
      final int candidate = (fromIndex + step * delta) % count;
      final int normalized = candidate < 0 ? candidate + count : candidate;
      if (_isOptionEnabled(normalized)) {
        return normalized;
      }
    }
    return null;
  }

  int? _findBoundaryEnabled({required bool fromStart}) {
    final int count = widget.options.length;
    if (fromStart) {
      for (int i = 0; i < count; i++) {
        if (_isOptionEnabled(i)) {
          return i;
        }
      }
    } else {
      for (int i = count - 1; i >= 0; i--) {
        if (_isOptionEnabled(i)) {
          return i;
        }
      }
    }
    return null;
  }

  double get _effectiveSpacing {
    if (widget.spacing != null) {
      return widget.spacing!;
    }
    if (widget.variant == OrionRadioGroupVariant.card) {
      return OrionSpacing.space8;
    }
    return widget.direction == Axis.vertical
        ? OrionSpacing.space4
        : OrionSpacing.space16;
  }

  Widget _buildOption(
    BuildContext context,
    int index,
    bool effectiveError,
    FormFieldState<T> field,
  ) {
    final OrionRadioOption<T> option = widget.options[index];
    final bool itemEnabled = _isOptionEnabled(index);
    final bool selected = widget.value == option.value;
    final FocusNode focusNode = _focusNodes[index];

    if (widget.variant == OrionRadioGroupVariant.card) {
      return _OrionRadioOptionCard<T>(
        option: option,
        selected: selected,
        enabled: itemEnabled,
        error: effectiveError,
        size: widget.size,
        radioStyle: widget.radioStyle,
        focusNode: focusNode,
        expandWidth: widget.direction == Axis.vertical,
        onSelect: () => _selectOption(option.value, field),
      );
    }

    final Widget radio = OrionRadio(
      value: selected,
      label: option.label,
      subtitle: option.subtitle,
      semanticLabel: option.semanticLabel,
      focusNode: focusNode,
      size: widget.size,
      error: effectiveError,
      style: widget.radioStyle,
      onChanged: itemEnabled ? (_) => _selectOption(option.value, field) : null,
    );

    if (option.trailing == null) {
      return radio;
    }

    return MouseRegion(
      cursor: itemEnabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: itemEnabled
            ? () {
                if (!selected) {
                  final OrionHapticType haptic = OrionTheme.of(
                    context,
                  ).selectionHaptic;
                  if (haptic != OrionHapticType.none) {
                    OrionHaptics.trigger(haptic);
                  }
                }
                _selectOption(option.value, field);
              }
            : null,
        child: Row(
          mainAxisSize: widget.direction == Axis.vertical
              ? MainAxisSize.max
              : MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            if (widget.direction == Axis.vertical)
              Expanded(child: radio)
            else
              Flexible(child: radio),
            const SizedBox(width: OrionSpacing.space12),
            option.trailing!,
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T>(
      key: _fieldKey,
      initialValue: widget.value,
      enabled: _groupEnabled,
      validator: widget.validator == null
          ? null
          : (T? _) => widget.validator!(widget.value),
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      builder: (FormFieldState<T> field) => _buildContent(context, field),
    );
  }

  Widget _buildContent(BuildContext context, FormFieldState<T> field) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final String? errorText = widget.error != null && widget.error!.isNotEmpty
        ? widget.error
        : field.errorText;
    final bool hasErrorText = errorText != null && errorText.isNotEmpty;
    final bool effectiveError = widget.hasError || hasErrorText;
    final String? caption = hasErrorText ? errorText : widget.helper;

    final Color labelColor = !_groupEnabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : scheme.onSurface;
    final TextStyle labelStyle =
        theme.textTheme.labelMedium ?? const TextStyle();
    final TextStyle captionStyle =
        theme.textTheme.bodySmall ?? const TextStyle();

    final double spacing = _effectiveSpacing;
    final List<Widget> optionWidgets = <Widget>[
      for (int i = 0; i < widget.options.length; i++)
        _buildOption(context, i, effectiveError, field),
    ];

    final Widget optionsLayout;
    if (widget.direction == Axis.vertical) {
      optionsLayout = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: widget.variant == OrionRadioGroupVariant.card
            ? CrossAxisAlignment.stretch
            : CrossAxisAlignment.start,
        children: <Widget>[
          for (int i = 0; i < optionWidgets.length; i++) ...<Widget>[
            optionWidgets[i],
            if (i != optionWidgets.length - 1 && spacing > 0)
              SizedBox(height: spacing),
          ],
        ],
      );
    } else {
      optionsLayout = Wrap(
        spacing: spacing,
        runSpacing: widget.runSpacing,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: optionWidgets,
      );
    }

    return Semantics(
      container: true,
      label: widget.semanticLabel ?? widget.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (widget.label != null) ...<Widget>[
            ExcludeSemantics(
              child: Text(
                widget.label!,
                style: labelStyle.copyWith(color: labelColor),
              ),
            ),
            const SizedBox(height: OrionSpacing.space8),
          ],
          Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (FocusNode node, KeyEvent event) =>
                _handleKeyEvent(context, event, field),
            child: optionsLayout,
          ),
          if (caption != null && caption.isNotEmpty) ...<Widget>[
            const SizedBox(height: OrionSpacing.space8),
            Text(
              caption,
              style: captionStyle.copyWith(
                color: hasErrorText ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _OrionRadioOptionCard<T> extends StatefulWidget {
  const _OrionRadioOptionCard({
    required this.option,
    required this.selected,
    required this.enabled,
    required this.error,
    required this.size,
    required this.radioStyle,
    required this.focusNode,
    required this.expandWidth,
    required this.onSelect,
  });

  final OrionRadioOption<T> option;
  final bool selected;
  final bool enabled;
  final bool error;
  final OrionRadioSize size;
  final OrionRadioStyle? radioStyle;
  final FocusNode focusNode;
  final bool expandWidth;
  final VoidCallback onSelect;

  @override
  State<_OrionRadioOptionCard<T>> createState() =>
      _OrionRadioOptionCardState<T>();
}

class _OrionRadioOptionCardState<T> extends State<_OrionRadioOptionCard<T>> {
  bool _hovered = false;
  bool _focused = false;

  @override
  void didUpdateWidget(_OrionRadioOptionCard<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && (_hovered || _focused)) {
      _hovered = false;
      _focused = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool isDark = theme.brightness == Brightness.dark;
    final bool reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final bool enabled = widget.enabled;
    final bool selected = widget.selected;
    final bool error = widget.error;

    final Color baseSurface = scheme.surfaceContainer;
    final Color backgroundColor;
    if (!enabled) {
      backgroundColor = baseSurface;
    } else if (selected) {
      final Color tint = error
          ? scheme.error.withValues(alpha: isDark ? 0.12 : 0.05)
          : scheme.primary.withValues(alpha: isDark ? 0.08 : 0.04);
      backgroundColor = Color.alphaBlend(tint, baseSurface);
    } else if (_hovered) {
      final Color hoverTint = scheme.onSurface.withValues(
        alpha: isDark ? 0.05 : 0.03,
      );
      backgroundColor = Color.alphaBlend(hoverTint, baseSurface);
    } else {
      backgroundColor = baseSurface;
    }

    final Color borderColor;
    final double borderWidth;
    if (!enabled) {
      borderColor = scheme.outlineVariant.withValues(alpha: 0.5);
      borderWidth = 1.0;
    } else if (error) {
      borderColor = selected
          ? scheme.error
          : scheme.error.withValues(alpha: 0.65);
      borderWidth = selected ? 1.5 : 1.0;
    } else if (selected) {
      borderColor = scheme.primary;
      borderWidth = 1.5;
    } else if (_hovered) {
      borderColor = Color.lerp(scheme.outlineVariant, scheme.onSurface, 0.2)!;
      borderWidth = 1.0;
    } else {
      borderColor = scheme.outlineVariant;
      borderWidth = 1.0;
    }

    final Color labelColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : error && selected
        ? scheme.error
        : scheme.onSurface;
    final Color subtitleColor = !enabled
        ? scheme.onSurfaceVariant.withValues(alpha: 0.38)
        : scheme.onSurfaceVariant;

    final Widget textColumn = ExcludeSemantics(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.option.label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (widget.option.subtitle != null) ...<Widget>[
            const SizedBox(height: 2.0),
            Text(
              widget.option.subtitle!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: subtitleColor,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );

    final Widget indicator = IgnorePointer(
      child: ExcludeSemantics(
        child: ExcludeFocus(
          child: OrionRadio(
            value: selected,
            onChanged: enabled ? (_) {} : null,
            size: widget.size,
            error: error,
            style: widget.radioStyle,
          ),
        ),
      ),
    );

    final Color focusRingColor = error
        ? scheme.error.withValues(alpha: 0.20)
        : scheme.onSurface.withValues(alpha: 0.12);

    return Semantics(
      container: true,
      checked: selected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      label: widget.option.semanticLabel ?? widget.option.label,
      child: MouseRegion(
        onEnter: (_) {
          if (mounted && enabled && !_hovered) {
            setState(() => _hovered = true);
          }
        },
        onExit: (_) {
          if (mounted && _hovered) {
            setState(() => _hovered = false);
          }
        },
        child: FocusableActionDetector(
          enabled: enabled,
          mouseCursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          focusNode: widget.focusNode,
          onShowFocusHighlight: (bool focused) {
            if (focused != _focused) {
              setState(() => _focused = focused);
            }
          },
          actions: <Type, Action<Intent>>{
            ActivateIntent: CallbackAction<ActivateIntent>(
              onInvoke: (ActivateIntent intent) {
                widget.onSelect();
                return null;
              },
            ),
          },
          child: OrionPressable(
            behavior: HitTestBehavior.opaque,
            pressedScale: 0.985,
            hapticType: selected
                ? OrionHapticType.none
                : OrionTheme.of(context).selectionHaptic,
            onTap: enabled ? widget.onSelect : null,
            child: AnimatedContainer(
              duration: reduce
                  ? Duration.zero
                  : const Duration(milliseconds: 160),
              curve: Curves.easeOut,
              padding: const EdgeInsetsDirectional.fromSTEB(
                OrionSpacing.space4,
                OrionSpacing.space8,
                OrionSpacing.space16,
                OrionSpacing.space8,
              ),
              decoration: BoxDecoration(
                color: backgroundColor,
                borderRadius: BorderRadius.circular(OrionRadii.radius12),
                border: Border.all(
                  color: borderColor,
                  width: borderWidth,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
                boxShadow: _focused && enabled
                    ? <BoxShadow>[
                        BoxShadow(
                          color: focusRingColor,
                          spreadRadius: 2.5,
                          blurRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: widget.expandWidth
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  indicator,
                  const SizedBox(width: OrionSpacing.space4),
                  if (widget.expandWidth)
                    Expanded(child: textColumn)
                  else
                    Flexible(child: textColumn),
                  if (widget.option.trailing != null) ...<Widget>[
                    const SizedBox(width: OrionSpacing.space12),
                    Opacity(
                      opacity: enabled ? 1.0 : 0.38,
                      child: widget.option.trailing!,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
