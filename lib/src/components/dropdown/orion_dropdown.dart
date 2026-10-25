import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/dropdown/orion_dropdown_option.dart';
import 'package:orion_ui/src/components/dropdown/orion_dropdown_presets.dart';
import 'package:orion_ui/src/components/dropdown/orion_dropdown_style.dart';
import 'package:orion_ui/src/components/dropdown/orion_dropdown_theme.dart';
import 'package:orion_ui/src/components/popover/orion_popover.dart';
import 'package:orion_ui/src/components/popover/orion_popover_controller.dart';
import 'package:orion_ui/src/components/popover/orion_popover_geometry.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';

/// A physics-driven single-select dropdown form control.
///
/// The closed control is a clean form field face with full rounded borders,
/// showing the selected label (or placeholder) and an organic rotating chevron.
/// Opening it blossoms an anchored option panel directly from the trigger
/// anchor using Emil Kowalski's transform-origin law (normalized micro-scaling
/// $0.94 \to 1.0$, fast opacity ramp, and 6 pt directional glide).
/// On dismissal, a critically damped spring ($k = 380, \zeta = 1.0$, clamped)
/// returns smoothly to rest with zero rebound overshoot.
///
/// Selection is parent-owned ([value] / [onChanged]); the panel carries the
/// full keyboard model (wrapping arrows that skip disabled options, Home/End,
/// Enter/Space, Escape with focus restore, Tab with form advance), one
/// semantic node per control, and the kit's three-layer styling contract.
class OrionDropdown<T> extends StatefulWidget {
  const OrionDropdown({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.prefix,
    this.validator,
    this.autovalidateMode,
    this.reserveCaption = false,
    this.enabled = true,
    this.variant = OrionDropdownVariant.outline,
    this.size = OrionDropdownSize.medium,
    this.placement = OrionPopoverPlacement.bottomStart,
    this.autoFlip = true,
    this.dismissOnScroll = true,
    this.controller,
    this.focusNode,
    this.style,
  });

  /// The ordered options. A non-null [value] must be present among them.
  final List<OrionDropdownOption<T>> options;

  /// The selected value, owned by the host.
  final T? value;

  /// Called once per commit whose value differs from [value].
  final ValueChanged<T>? onChanged;

  /// The field label shown above the face.
  final String? label;

  /// Shown in the face while [value] is null.
  final String? placeholder;

  /// Caption below the face, replaced by the error text when one exists.
  final String? helper;

  /// Explicit error text; the field's validator result wins when present.
  final String? error;

  /// Optional fixed leading widget shown before the text / selected option leading.
  final Widget? prefix;

  /// Form validation over the nullable value.
  final FormFieldValidator<T?>? validator;

  /// When validation runs.
  final AutovalidateMode? autovalidateMode;

  /// Keeps the caption row present so validation cannot reflow the form.
  final bool reserveCaption;

  /// False mutes the control and takes no input.
  final bool enabled;

  /// The face of the trigger.
  final OrionDropdownVariant variant;

  /// The size step of the trigger face.
  final OrionDropdownSize size;

  /// Preferred placement of the panel relative to the field.
  final OrionPopoverPlacement placement;

  /// Whether the panel flips to the opposite side when space runs out.
  final bool autoFlip;

  /// Whether scrolling an ancestor dismisses the panel.
  final bool dismissOnScroll;

  /// Optional programmatic open-state control.
  final OrionPopoverController? controller;

  /// Optional focus node for the trigger.
  final FocusNode? focusNode;

  /// Instance styling overrides.
  final OrionDropdownStyle? style;

  @override
  State<OrionDropdown<T>> createState() => OrionDropdownState<T>();
}

class OrionDropdownState<T> extends State<OrionDropdown<T>>
    with TickerProviderStateMixin {
  /// Focus is not a press: the line arrives, it does not bounce. Matches the
  /// text field's focus spring.
  static const OrionSpringSpec _faceFocus = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
    clampOvershoot: true,
  );

  final GlobalKey _triggerKey = GlobalKey();
  final GlobalKey<_OrionDropdownPanelState<T>> _panelStateKey =
      GlobalKey<_OrionDropdownPanelState<T>>();
  final OverlayPortalController _portalController = OverlayPortalController();
  final ScrollController _panelScrollController = ScrollController();
  final FocusNode _panelFocusNode = FocusNode(debugLabel: 'OrionDropdownPanel');

  late final OrionSpringDriver _openDriver;
  late final OrionSpringDriver _faceFocusDriver;
  late final OrionSpringDriver _highlightDriver;

  OrionPopoverController? _internalController;
  OrionPopoverController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionPopoverController());

  late FocusNode _focusNode;
  bool _ownsFocus = false;
  bool _focusBound = false;

  bool _isOpen = false;
  bool _isClosing = false;
  int? _activeIndex;
  OrionPopoverResolvedLayout? _resolvedLayout;
  Rect? _lastTriggerRect;
  FormFieldState<T?>? _field;
  ScrollNotificationObserverState? _scrollObserver;

  OrionDropdownStyle _resolvedStyle = const OrionDropdownStyle();

  /// The spring powering the open and close kinematics.
  @visibleForTesting
  OrionSpringDriver get openDriver => _openDriver;

  /// Compatibility alias for [openDriver].
  @visibleForTesting
  OrionSpringDriver get unfoldDriver => _openDriver;

  /// Compatibility alias for [openDriver].
  @visibleForTesting
  OrionSpringDriver get separationDriver => _openDriver;

  /// The spring behind the gliding highlight.
  @visibleForTesting
  OrionSpringDriver get highlightDriver => _highlightDriver;

  /// The index the keyboard and hover cursor points at.
  @visibleForTesting
  int? get activeIndex => _activeIndex;

  /// The trigger's focus node.
  @visibleForTesting
  FocusNode get triggerFocusNode => _focusNode;

  /// Whether the panel is open (including while it is closing).
  @visibleForTesting
  bool get isOpen => _isOpen;

  /// The panel's global rect, or null while it is not on screen.
  @visibleForTesting
  Rect? get panelRect {
    final RenderObject? renderObject = _panelStateKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  @override
  void initState() {
    super.initState();
    _openDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionDropdownPresets.unfoldSpring,
    );
    _faceFocusDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: _faceFocus,
    );
    _highlightDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionDropdownPresets.highlightSpring,
    );
    _openDriver.addListener(_onOpenTick);
    _openDriver.addStatusListener(_onOpenStatus);
    _bindFocus(widget.focusNode);
    _attachController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _openDriver.reducedMotion = reduced;
    _faceFocusDriver.reducedMotion = reduced;
    _highlightDriver.reducedMotion = reduced;
    _resolvedStyle = _resolveStyle(Theme.of(context));
    _syncMotionSpecs();
    _syncFaceFocus();

    _scrollObserver?.removeListener(_handleScrollNotification);
    _scrollObserver = ScrollNotificationObserver.maybeOf(context);
    _scrollObserver?.addListener(_handleScrollNotification);
  }

  @override
  void didUpdateWidget(OrionDropdown<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller?.detach();
      _attachController();
    }
    if (widget.focusNode != oldWidget.focusNode) {
      _bindFocus(widget.focusNode);
    }
    if (!identical(widget.options, oldWidget.options)) {
      final int? current = _activeIndex;
      if (_isOpen &&
          current != null &&
          (current >= widget.options.length ||
              !widget.options[current].enabled)) {
        _setActive(_resolveFallbackActive(), glide: false);
      }
    }
    if (!widget.enabled && _isOpen) {
      hide();
    }
    _resolvedStyle = _resolveStyle(Theme.of(context));
    _syncMotionSpecs();
    _syncFaceFocus();
  }

  @override
  void dispose() {
    _scrollObserver?.removeListener(_handleScrollNotification);
    _openDriver.removeListener(_onOpenTick);
    _openDriver.removeStatusListener(_onOpenStatus);
    _effectiveController.detach();
    _internalController?.dispose();
    _focusNode.removeListener(_syncFaceFocus);
    if (_ownsFocus) {
      _focusNode.dispose();
    }
    _panelFocusNode.dispose();
    _panelScrollController.dispose();
    _openDriver.dispose();
    _faceFocusDriver.dispose();
    _highlightDriver.dispose();
    super.dispose();
  }

  void _attachController() {
    _effectiveController.attach(onShow: show, onHide: () => hide());
  }

  void _bindFocus(FocusNode? incoming) {
    if (_focusBound) {
      _focusNode.removeListener(_syncFaceFocus);
      if (_ownsFocus) {
        _focusNode.dispose();
      }
    }
    _ownsFocus = incoming == null;
    _focusNode = incoming ?? FocusNode();
    _focusNode.addListener(_syncFaceFocus);
    _focusBound = true;
  }

  OrionDropdownStyle _resolveStyle(ThemeData theme) {
    final OrionDropdownTheme dropdownTheme =
        theme.extension<OrionDropdownTheme>() ?? OrionDropdownTheme.fallback;
    return OrionDropdownPresets.resolve(
      variant: widget.variant,
      size: widget.size,
      scheme: theme.colorScheme,
      textTheme: theme.textTheme,
    ).merge(dropdownTheme.defaultStyle).merge(widget.style);
  }

  void _syncMotionSpecs() {
    _openDriver.springSpec =
        _resolvedStyle.springSpec ?? OrionDropdownPresets.unfoldSpring;
    _highlightDriver.springSpec =
        _resolvedStyle.highlightSpringSpec ??
        OrionDropdownPresets.highlightSpring;
  }

  void _syncFaceFocus() {
    final double target = (widget.enabled && (_focusNode.hasFocus || _isOpen))
        ? 1.0
        : 0.0;
    if (_faceFocusDriver.reducedMotion) {
      _faceFocusDriver.jumpTo(target);
      return;
    }
    if (_faceFocusDriver.target != target) {
      _faceFocusDriver.retarget(target);
    }
  }

  bool get _panelIsAbove {
    final OrionPopoverResolvedLayout? layout = _resolvedLayout;
    if (layout != null) {
      return layout.placement == OrionPopoverPlacement.topStart ||
          layout.placement == OrionPopoverPlacement.topCenter ||
          layout.placement == OrionPopoverPlacement.topEnd;
    }
    return widget.placement == OrionPopoverPlacement.topStart ||
        widget.placement == OrionPopoverPlacement.topCenter ||
        widget.placement == OrionPopoverPlacement.topEnd;
  }

  int _indexOf(T? value) {
    if (value == null) return -1;
    for (int i = 0; i < widget.options.length; i++) {
      if (widget.options[i].value == value) return i;
    }
    return -1;
  }

  int? _resolveFallbackActive() {
    final int selected = _indexOf(widget.value);
    if (selected >= 0 && widget.options[selected].enabled) return selected;
    for (int i = 0; i < widget.options.length; i++) {
      if (widget.options[i].enabled) return i;
    }
    return null;
  }

  List<int> _enabledIndices() {
    final List<int> indices = <int>[];
    for (int i = 0; i < widget.options.length; i++) {
      if (widget.options[i].enabled) indices.add(i);
    }
    return indices;
  }

  void _setActive(int? index, {bool glide = true}) {
    if (index == null || index == _activeIndex) return;
    _activeIndex = index;
    if (glide && !_highlightDriver.reducedMotion) {
      _highlightDriver.retarget(index.toDouble());
    } else {
      _highlightDriver.jumpTo(index.toDouble());
    }
  }

  Rect? _measureTriggerRect() {
    final RenderBox? box =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final Offset globalOffset = box.localToGlobal(Offset.zero);
    return globalOffset & box.size;
  }

  /// Opens the panel with organic transform-origin scale and glide.
  void show() {
    if ((_isOpen && !_isClosing) || !widget.enabled) return;
    final Rect? rect = _measureTriggerRect();
    if (rect == null) return;
    _lastTriggerRect = rect;
    _isClosing = false;
    _isOpen = true;
    _activeIndex = _resolveFallbackActive();
    _effectiveController.updateOpenState(true);
    _syncMotionSpecs();

    final Size viewportSize = MediaQuery.sizeOf(context);
    final double panelMaxWidth = _resolvedStyle.panelMaxWidth ?? 320.0;
    final double panelWidth = rect.width.clamp(140.0, panelMaxWidth);
    final double estimatedHeight = math.min(
      _resolvedStyle.panelMaxHeight ?? 320.0,
      widget.options.length * (_resolvedStyle.rowMinHeight ?? 44.0) +
          ((_resolvedStyle.panelPadding ?? const EdgeInsets.all(8.0))
              .resolve(Directionality.of(context))
              .vertical),
    );
    _resolvedLayout = OrionPopoverGeometry.resolve(
      triggerRect: rect,
      popoverSize: Size(panelWidth, estimatedHeight),
      viewportSize: viewportSize,
      viewportPadding: const EdgeInsets.all(12.0),
      preferredPlacement: _effectivePlacement(context),
      gap: _resolvedStyle.panelGap ?? 8.0,
      autoFlip: widget.autoFlip,
      showArrow: false,
      arrowSize: Size.zero,
    );

    _portalController.show();
    if (_activeIndex != null) {
      _highlightDriver.jumpTo(_activeIndex!.toDouble());
    }
    if (_openDriver.reducedMotion) {
      _openDriver.jumpTo(1.0);
    } else {
      _openDriver.springSpec =
          _resolvedStyle.springSpec ?? OrionDropdownPresets.unfoldSpring;
      _openDriver.retarget(1.0);
    }
    OrionHaptics.trigger(
      _resolvedStyle.hapticType ?? OrionHapticType.selectionClick,
    );
    _syncFaceFocus();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOpen) return;
      _panelFocusNode.requestFocus();
      _panelStateKey.currentState?.ensureRowVisible(_activeIndex);
    });
  }

  /// Closes the panel with critically damped kinematics and zero rebound.
  void hide({bool restoreFocus = false}) {
    if (!_isOpen || _isClosing) return;
    _isClosing = true;
    setState(() {});
    if (restoreFocus) {
      _focusNode.requestFocus();
    }
    if (_openDriver.reducedMotion) {
      _openDriver.jumpTo(0.0);
      _finishClose();
      return;
    }
    _openDriver.springSpec =
        _resolvedStyle.dismissSpringSpec ?? OrionDropdownPresets.dismissSpring;
    _openDriver.retarget(0.0);
    _syncFaceFocus();
  }

  /// Toggles the panel between open and closed.
  void toggle() {
    if (_isOpen && !_isClosing) {
      hide();
    } else {
      show();
    }
  }

  void _onOpenTick() {
    if (_isClosing && _openDriver.value <= 0.005) {
      _finishClose();
    }
  }

  void _onOpenStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _isClosing &&
        _openDriver.value <= 0.01) {
      _finishClose();
    }
  }

  void _finishClose() {
    if (!_isOpen && !_isClosing) return;
    _isClosing = false;
    _isOpen = false;
    _portalController.hide();
    _effectiveController.updateOpenState(false);
    _syncFaceFocus();
    setState(() {});
  }

  void _commit(int index) {
    if (index < 0 || index >= widget.options.length) return;
    final OrionDropdownOption<T> option = widget.options[index];
    if (!option.enabled) return;
    final T next = option.value;
    final bool changed = next != widget.value;
    hide(restoreFocus: true);
    if (!changed) return;
    OrionHaptics.trigger(
      _resolvedStyle.hapticType ?? OrionHapticType.selectionClick,
    );
    _field?.didChange(next);
    widget.onChanged?.call(next);
  }

  void _step(int delta) {
    final List<int> enabled = _enabledIndices();
    if (enabled.isEmpty) return;
    final int at = enabled.indexOf(_activeIndex ?? -1);
    final int next = at < 0
        ? (delta > 0 ? 0 : enabled.length - 1)
        : (at + delta + enabled.length) % enabled.length;
    _setActive(enabled[next]);
    _panelStateKey.currentState?.ensureRowVisible(_activeIndex);
  }

  void _setActiveAndReveal(int? index) {
    _setActive(index);
    _panelStateKey.currentState?.ensureRowVisible(_activeIndex);
  }

  KeyEventResult _onTriggerKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent || _isOpen) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    final bool activates =
        key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp;
    if (!activates) return KeyEventResult.ignored;
    show();
    return KeyEventResult.handled;
  }

  KeyEventResult _onPanelKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown) {
      _step(1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      _step(-1);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home) {
      final List<int> enabled = _enabledIndices();
      _setActiveAndReveal(enabled.isEmpty ? null : enabled.first);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.end) {
      final List<int> enabled = _enabledIndices();
      _setActiveAndReveal(enabled.isEmpty ? null : enabled.last);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.space) {
      final int? active = _activeIndex;
      if (active != null) {
        _commit(active);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      hide(restoreFocus: true);
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.tab) {
      hide();
      final bool isShift = HardwareKeyboard.instance.isShiftPressed;
      if (isShift) {
        _focusNode.previousFocus();
      } else {
        _focusNode.nextFocus();
      }
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _handleScrollNotification(ScrollNotification notification) {
    if (!widget.dismissOnScroll) return;
    if (!_isOpen || _isClosing) return;
    final BuildContext? notifContext = notification.context;
    if (notifContext != null && _isInsidePanel(notifContext)) {
      return;
    }
    if (notification is ScrollUpdateNotification &&
        notification.scrollDelta != null &&
        notification.scrollDelta != 0.0) {
      hide();
    } else if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      hide();
    }
  }

  bool _isInsidePanel(BuildContext notifContext) {
    if (!notifContext.mounted) return false;
    final BuildContext? panelContext = _panelStateKey.currentContext;
    if (panelContext == null || !panelContext.mounted) return false;
    final RenderObject? panelRenderObject = panelContext.findRenderObject();
    if (panelRenderObject == null) return false;
    final RenderObject? notifRenderObject = notifContext.findRenderObject();
    if (notifRenderObject == null) return false;
    RenderObject? current = notifRenderObject;
    while (current != null) {
      if (current == panelRenderObject) return true;
      current = current.parent;
    }
    return false;
  }

  /// Maps start/end placement through the text direction. The popover geometry
  /// resolver works in physical left/right; the dropdown owns this mapping at
  /// its call site.
  OrionPopoverPlacement _effectivePlacement(BuildContext context) {
    if (Directionality.of(context) != TextDirection.rtl) {
      return widget.placement;
    }
    return switch (widget.placement) {
      OrionPopoverPlacement.bottomStart => OrionPopoverPlacement.bottomEnd,
      OrionPopoverPlacement.bottomEnd => OrionPopoverPlacement.bottomStart,
      OrionPopoverPlacement.topStart => OrionPopoverPlacement.topEnd,
      OrionPopoverPlacement.topEnd => OrionPopoverPlacement.topStart,
      OrionPopoverPlacement.bottomCenter => OrionPopoverPlacement.bottomCenter,
      OrionPopoverPlacement.topCenter => OrionPopoverPlacement.topCenter,
    };
  }

  @override
  Widget build(BuildContext context) {
    return FormField<T?>(
      initialValue: widget.value,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      builder: (FormFieldState<T?> field) {
        _field = field;
        return _build(context, field);
      },
    );
  }

  Widget _build(BuildContext context, FormFieldState<T?> field) {
    assert(
      widget.value == null || _indexOf(widget.value) >= 0,
      'OrionDropdown: value must be present among options.',
    );

    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionDropdownStyle style = _resolveStyle(theme);
    final bool enabled = widget.enabled;
    final String? errorText = widget.error != null && widget.error!.isNotEmpty
        ? widget.error
        : field.errorText;
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final String? caption = hasError ? errorText : widget.helper;

    final int selectedIndex = _indexOf(widget.value);
    final OrionDropdownOption<T>? selectedOption = selectedIndex >= 0
        ? widget.options[selectedIndex]
        : null;
    final String? selectedLabel = selectedOption?.label;
    final Widget? selectedLeading = selectedOption?.leading;

    final Widget trigger = Semantics(
      container: true,
      button: true,
      enabled: enabled,
      expanded: _isOpen,
      label: widget.label ?? widget.placeholder,
      value: selectedLabel,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: enabled ? toggle : null,
            child: Focus(
              focusNode: _focusNode,
              onKeyEvent: _onTriggerKey,
              child: _buildFace(
                context,
                style,
                scheme,
                enabled: enabled,
                hasError: hasError,
                display: selectedLabel ?? widget.placeholder ?? '',
                hasValue: selectedLabel != null,
                selectedLeading: selectedLeading,
              ),
            ),
          ),
        ),
      ),
    );

    final TextStyle labelStyle =
        style.labelStyle ?? theme.textTheme.labelMedium ?? const TextStyle();
    final TextStyle captionStyle =
        style.captionStyle ?? theme.textTheme.bodySmall ?? const TextStyle();
    final Color labelColor =
        style.textColor?.resolve(<WidgetState>{
          if (!enabled) WidgetState.disabled,
        }) ??
        scheme.onSurface;

    return OverlayPortal(
      controller: _portalController,
      overlayChildBuilder: _buildOverlay,
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
            SizedBox(height: style.labelGap ?? 8.0),
          ],
          KeyedSubtree(key: _triggerKey, child: trigger),
          if (caption != null || widget.reserveCaption) ...<Widget>[
            SizedBox(height: style.captionGap ?? 8.0),
            Text(
              caption ?? '',
              style: captionStyle.copyWith(
                color: hasError ? scheme.error : scheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFace(
    BuildContext context,
    OrionDropdownStyle style,
    ColorScheme scheme, {
    required bool enabled,
    required bool hasError,
    required String display,
    required bool hasValue,
    Widget? selectedLeading,
  }) {
    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (hasError) WidgetState.error,
    };
    final Set<WidgetState> focusedStates = <WidgetState>{
      WidgetState.focused,
      ...restingStates,
    };
    final Color fill =
        style.fillColor?.resolve(restingStates) ?? scheme.surface;
    final Color borderRest =
        style.borderColor?.resolve(restingStates) ?? scheme.outline;
    final Color borderFocused =
        style.borderColor?.resolve(focusedStates) ?? scheme.primary;
    final double borderWidth = style.borderWidth ?? 1;
    final Color textColor =
        style.textColor?.resolve(restingStates) ?? scheme.onSurface;
    final Color hintColor =
        style.hintColor?.resolve(restingStates) ?? scheme.onSurfaceVariant;
    final TextStyle textStyle = style.textStyle ?? const TextStyle();
    final EdgeInsets padding =
        (style.padding ?? const EdgeInsets.symmetric(horizontal: 12.0)).resolve(
          Directionality.of(context),
        );
    final bool underline = widget.variant == OrionDropdownVariant.underline;
    final Widget? effectiveLeading =
        widget.prefix ?? (hasValue ? selectedLeading : null);

    final Widget content = Padding(
      padding: padding,
      child: Row(
        children: <Widget>[
          if (effectiveLeading != null) ...<Widget>[
            IconTheme.merge(
              data: IconThemeData(
                color: hasValue ? textColor : hintColor,
                size: style.iconSize ?? 18.0,
              ),
              child: effectiveLeading,
            ),
            const SizedBox(width: 8.0),
          ],
          Expanded(
            child: Text(
              display,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: textStyle.copyWith(
                color: hasValue ? textColor : hintColor,
              ),
            ),
          ),
          const SizedBox(width: 8.0),
          AnimatedBuilder(
            animation: _openDriver,
            child: Icon(
              Icons.keyboard_arrow_down_rounded,
              size: style.iconSize ?? 18.0,
              color: style.chevronColor ?? scheme.onSurfaceVariant,
            ),
            builder: (BuildContext context, Widget? child) => Transform.rotate(
              angle: math.pi * _openDriver.value.clamp(0.0, 1.0),
              child: child,
            ),
          ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: style.height ?? 48.0),
      child: AnimatedBuilder(
        animation: _faceFocusDriver,
        child: content,
        builder: (BuildContext context, Widget? child) {
          final double progress = _faceFocusDriver.value.clamp(0.0, 1.0);
          final Color borderColor = Color.lerp(
            borderRest,
            borderFocused,
            progress,
          )!;
          final double width = borderWidth + 0.5 * progress;
          final BorderRadius radius =
              style.radius ?? BorderRadius.circular(12.0);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: underline
                  ? Border(
                      bottom: BorderSide(color: borderColor, width: width),
                    )
                  : Border.all(color: borderColor, width: width),
            ),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OrionDropdownStyle style = _resolveStyle(theme);
    final Rect triggerRect =
        _measureTriggerRect() ?? _lastTriggerRect ?? Rect.zero;
    final double panelMaxWidth = style.panelMaxWidth ?? 320.0;
    final double panelWidth = triggerRect.width.clamp(140.0, panelMaxWidth);

    final Widget panel = SizedBox(
      width: panelWidth,
      child: _buildPanelSurface(
        context,
        style,
        _OrionDropdownPanel<T>(
          key: _panelStateKey,
          options: widget.options,
          style: style,
          selectedValue: widget.value,
          highlightDriver: _highlightDriver,
          scrollController: _panelScrollController,
          onSelect: _commit,
          onHover: _setActive,
        ),
      ),
    );

    return Focus(
      focusNode: _panelFocusNode,
      onKeyEvent: _onPanelKey,
      child: PopScope(
        canPop: false,
        onPopInvokedWithResult: (bool didPop, Object? result) {
          if (!didPop) hide();
        },
        child: Stack(
          children: <Widget>[
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.translucent,
                excludeFromSemantics: true,
                onTap: () => hide(),
                onPanStart: widget.dismissOnScroll
                    ? (DragStartDetails _) => hide()
                    : null,
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isClosing,
                child: CustomSingleChildLayout(
                  delegate: OrionPopoverLayoutDelegate(
                    triggerRect: triggerRect,
                    viewportPadding: const EdgeInsets.all(12.0),
                    preferredPlacement: _effectivePlacement(context),
                    gap: style.panelGap ?? 8.0,
                    autoFlip: widget.autoFlip,
                    showArrow: false,
                    arrowSize: Size.zero,
                    onLayoutResolved: (OrionPopoverResolvedLayout layout) {
                      _resolvedLayout = layout;
                    },
                  ),
                  child: AnimatedBuilder(
                    animation: _openDriver,
                    child: panel,
                    builder: (BuildContext context, Widget? child) {
                      final double progress = _openDriver.value.clamp(0.0, 1.0);
                      final double scale = 0.94 + (0.06 * progress);
                      final double opacity = (progress * 2.0).clamp(0.0, 1.0);
                      final Alignment origin =
                          _resolvedLayout?.transformOrigin ??
                          (_panelIsAbove
                              ? Alignment.bottomCenter
                              : Alignment.topCenter);
                      final double translateY =
                          (1.0 - progress) * (_panelIsAbove ? 6.0 : -6.0);

                      final Widget contentWidget = opacity < 1.0
                          ? Opacity(opacity: opacity, child: child)
                          : child!;

                      return Transform.translate(
                        offset: Offset(0, translateY),
                        child: Transform.scale(
                          scale: scale,
                          alignment: origin,
                          child: contentWidget,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanelSurface(
    BuildContext context,
    OrionDropdownStyle style,
    Widget content,
  ) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final BorderRadius radius =
        style.panelBorderRadius ?? BorderRadius.circular(12.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: style.panelColor ?? scheme.surface,
          borderRadius: radius,
          border: Border.all(
            color:
                style.panelBorderColor ??
                scheme.outlineVariant.withValues(alpha: 0.35),
            width: style.panelBorderWidth ?? 1.0,
          ),
          boxShadow: style.panelShadow ?? OrionThemeData.defaultShadow,
        ),
        child: ClipRRect(borderRadius: radius, child: content),
      ),
    );
  }
}

class _OrionDropdownPanel<T> extends StatefulWidget {
  const _OrionDropdownPanel({
    super.key,
    required this.options,
    required this.style,
    required this.selectedValue,
    required this.highlightDriver,
    required this.scrollController,
    required this.onSelect,
    required this.onHover,
  });

  final List<OrionDropdownOption<T>> options;
  final OrionDropdownStyle style;
  final T? selectedValue;
  final OrionSpringDriver highlightDriver;
  final ScrollController scrollController;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onHover;

  @override
  State<_OrionDropdownPanel<T>> createState() => _OrionDropdownPanelState<T>();
}

class _OrionDropdownPanelState<T> extends State<_OrionDropdownPanel<T>> {
  final List<GlobalKey> _rowKeys = <GlobalKey>[];
  final GlobalKey _gliderHostKey = GlobalKey();
  List<Rect> _rowRects = const <Rect>[];
  bool _measureScheduled = false;

  /// Jumps the smallest scroll that brings [index] fully into view.
  ///
  /// Keyboard navigation is a keyboard-initiated action; it never animates.
  void ensureRowVisible(int? index) {
    if (index == null ||
        !widget.scrollController.hasClients ||
        index < 0 ||
        index >= _rowRects.length) {
      return;
    }
    final ScrollPosition position = widget.scrollController.position;
    final Rect rect = _rowRects[index];
    final double viewportTop = position.pixels;
    final double viewportBottom = viewportTop + position.viewportDimension;
    double target = position.pixels;
    if (rect.top < viewportTop) {
      target = rect.top;
    } else if (rect.bottom > viewportBottom) {
      target = rect.bottom - position.viewportDimension;
    }
    final double clamped = target.clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (clamped != position.pixels) {
      position.jumpTo(clamped);
    }
  }

  bool _sameRects(List<Rect> a, List<Rect> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  void _scheduleMeasure() {
    if (_measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final RenderBox? host =
          _gliderHostKey.currentContext?.findRenderObject() as RenderBox?;
      if (host == null) return;
      final List<Rect> rects = <Rect>[];
      final int count = widget.options.length;
      for (int i = 0; i < count && i < _rowKeys.length; i++) {
        final GlobalKey key = _rowKeys[i];
        final RenderBox? box =
            key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) return;
        rects.add(box.localToGlobal(Offset.zero, ancestor: host) & box.size);
      }
      final bool wasEmpty = _rowRects.isEmpty;
      if (rects.isEmpty || _sameRects(rects, _rowRects)) return;
      setState(() => _rowRects = rects);
      if (wasEmpty) {
        ensureRowVisible(widget.highlightDriver.target.round());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final int count = widget.options.length;
    while (_rowKeys.length < count) {
      _rowKeys.add(GlobalKey());
    }
    while (_rowKeys.length > count) {
      _rowKeys.removeLast();
    }

    final List<Widget> rows = <Widget>[
      for (int i = 0; i < count; i++)
        _OrionDropdownRow<T>(
          key: _rowKeys[i],
          option: widget.options[i],
          style: widget.style,
          isSelected:
              widget.selectedValue != null &&
              widget.options[i].value == widget.selectedValue,
          onSelect: () => widget.onSelect(i),
          onHover: () => widget.onHover(i),
        ),
    ];

    _scheduleMeasure();

    final EdgeInsets panelPadding =
        (widget.style.panelPadding ?? const EdgeInsets.all(8.0)).resolve(
          Directionality.of(context),
        );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: widget.style.panelMaxHeight ?? 320.0,
        ),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          child: CustomPaint(
            key: _gliderHostKey,
            painter: _OrionDropdownGliderPainter(
              driver: widget.highlightDriver,
              rects: _rowRects,
              color: widget.style.activeRowColor ?? Colors.transparent,
              radius:
                  widget.style.activeRowRadius ?? BorderRadius.circular(8.0),
            ),
            child: Padding(
              padding: panelPadding,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: rows,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _OrionDropdownRow<T> extends StatelessWidget {
  const _OrionDropdownRow({
    super.key,
    required this.option,
    required this.style,
    required this.isSelected,
    required this.onSelect,
    required this.onHover,
  });

  final OrionDropdownOption<T> option;
  final OrionDropdownStyle style;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onHover;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final bool enabled = option.enabled;
    final double iconSize = style.iconSize ?? 18.0;

    final Color titleColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (isSelected
              ? (style.selectedLabelColor ?? scheme.onSurface)
              : (style.labelColor ?? scheme.onSurfaceVariant));
    final Color descriptionColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (style.descriptionColor ?? scheme.onSurfaceVariant);

    final Widget content = Container(
      constraints: BoxConstraints(minHeight: style.rowMinHeight ?? 44.0),
      alignment: AlignmentDirectional.centerStart,
      child: Padding(
        padding:
            (style.rowPadding ??
                    const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0))
                .resolve(Directionality.of(context)),
        child: Row(
          children: <Widget>[
            if (option.leading != null) ...<Widget>[
              IconTheme.merge(
                data: IconThemeData(color: titleColor, size: iconSize),
                child: option.leading!,
              ),
              const SizedBox(width: 12.0),
            ],
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    option.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: (style.rowTitleStyle ?? const TextStyle()).copyWith(
                      color: titleColor,
                    ),
                  ),
                  if (option.description != null) ...<Widget>[
                    const SizedBox(height: 2.0),
                    Text(
                      option.description!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: (style.rowDescriptionStyle ?? const TextStyle())
                          .copyWith(color: descriptionColor),
                    ),
                  ],
                ],
              ),
            ),
            if (isSelected) ...<Widget>[
              const SizedBox(width: 8.0),
              Icon(
                Icons.check_rounded,
                size: iconSize,
                color: style.checkColor ?? scheme.primary,
              ),
            ],
          ],
        ),
      ),
    );

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      enabled: enabled,
      inMutuallyExclusiveGroup: true,
      child: MouseRegion(
        onEnter: enabled ? (PointerEnterEvent _) => onHover() : null,
        child: OrionPressable(
          pressedScale: style.pressScale ?? 0.98,
          springSpec: style.pressSpring ?? OrionSpringSpec.snappy,
          releaseSpringSpec: style.releaseSpring,
          hapticType: OrionHapticType.none,
          onTap: enabled ? onSelect : null,
          child: content,
        ),
      ),
    );
  }
}

/// Paints the gliding highlight behind the rows, in list-content coordinates so
/// scrolling translates it rigidly and only an active-index change retargets
/// the spring.
class _OrionDropdownGliderPainter extends CustomPainter {
  _OrionDropdownGliderPainter({
    required this.driver,
    required this.rects,
    required this.color,
    required this.radius,
  }) : super(repaint: driver);

  final Animation<double> driver;
  final List<Rect> rects;
  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (rects.isEmpty || color.a == 0) return;
    final double position = driver.value.clamp(
      0.0,
      (rects.length - 1).toDouble(),
    );
    final int base = position.floor();
    final int next = math.min(rects.length - 1, base + 1);
    final double t = position - base;
    final Rect rect = Rect.lerp(rects[base], rects[next], t)!;
    canvas.drawRRect(radius.toRRect(rect), Paint()..color = color);
  }

  @override
  bool shouldRepaint(_OrionDropdownGliderPainter oldDelegate) =>
      oldDelegate.rects != rects ||
      oldDelegate.color != color ||
      oldDelegate.radius != radius;
}
