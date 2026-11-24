import 'dart:math' as math;
import 'dart:ui' show FlutterView;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:orion_ui/src/components/button/orion_button.dart';
import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/components/dropdown/orion_dropdown_option.dart';
import 'package:orion_ui/src/components/dropdown/orion_dropdown_presets.dart';
import 'package:orion_ui/src/components/dropdown/orion_dropdown_style.dart';
import 'package:orion_ui/src/components/dropdown/orion_dropdown_theme.dart';
import 'package:orion_ui/src/components/popover/orion_popover.dart';
import 'package:orion_ui/src/components/popover/orion_popover_controller.dart';
import 'package:orion_ui/src/components/popover/orion_popover_geometry.dart';
import 'package:orion_ui/src/components/sheet/orion_bottom_sheet.dart';
import 'package:orion_ui/src/components/sheet/orion_sheet_controller.dart';
import 'package:orion_ui/src/core/orion_haptics.dart';
import 'package:orion_ui/src/core/orion_pressable.dart';
import 'package:orion_ui/src/motion/orion_spring_driver.dart';
import 'package:orion_ui/src/motion/orion_spring_spec.dart';
import 'package:orion_ui/src/theme/orion_theme.dart';
import 'package:orion_ui/src/theme/orion_theme_data.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// Optional custom search filter predicate for searchable dropdowns.
typedef OrionDropdownFilter<T> =
    bool Function(OrionDropdownOption<T> option, String query);

/// Optional custom builder for rendering an option row's body inside the menu.
typedef OrionDropdownOptionBuilder<T> =
    Widget Function(
      BuildContext context,
      OrionDropdownOption<T> option,
      bool isSelected,
    );

/// Optional custom builder for the closed trigger face content.
typedef OrionDropdownSelectedBuilder<T> =
    Widget Function(
      BuildContext context,
      List<OrionDropdownOption<T>> selectedOptions,
    );

/// Key assigned to the clear-selection button inside the open panel or sheet
/// when single-select `clearable` is true and a value is selected.
const Key orionDropdownClearButtonKey = Key('orion_dropdown_clear_button');

/// Key assigned to the in-panel / in-sheet search [TextField] when `searchable`
/// is true.
const Key orionDropdownSearchFieldKey = Key('orion_dropdown_search_field');

/// Key assigned to the clear-query button inside the search bar.
const Key orionDropdownSearchClearKey = Key(
  'orion_dropdown_search_clear_button',
);

/// Key assigned to the multi-select "Clear" footer button.
const Key orionDropdownMultiClearKey = Key('orion_dropdown_multi_clear_button');

/// Key assigned to the multi-select "Done" footer button.
const Key orionDropdownMultiDoneKey = Key('orion_dropdown_multi_done_button');

/// A physics-driven single- or multi-select dropdown and combobox form control.
///
/// Use the default constructor for single-select fields and
/// [OrionDropdown.multi] for multi-select fields.
///
/// Features:
/// - **Full trigger-width anchored popover** (`OrionDropdownPresentation.popover`)
///   or **modal bottom-sheet picker** (`OrionDropdownPresentation.sheet`, or
///   responsive `OrionDropdownPresentation.auto`) backed by [OrionBottomSheet].
/// - **In-panel / in-sheet search** (`searchable: true`) with keyboard inset
///   awareness, customizable `searchPlaceholder`, `filter`, `emptyText` /
///   `emptyState`, and `OrionDropdownOption.searchTerms`.
/// - **Clearable selection** (`clearable: true`), **option grouping**
///   (`OrionDropdownOption.group`), **loading state** (`isLoading: true`),
///   **graceful async values** (`unknownValueLabel`), and optional custom
///   `optionBuilder` / `selectedBuilder`.
/// - **Full keyboard navigation** (wrapping Up/Down skipping disabled options,
///   Home/End, Enter/Space, Escape with focus restore, Tab form advance) and
///   [FormField] validation aligned with `OrionTextField`.
class OrionDropdown<T> extends StatefulWidget {
  /// Creates a single-select dropdown control.
  const OrionDropdown({
    super.key,
    required this.options,
    this.value,
    this.onChanged,
    this.clearable = false,
    this.onCleared,
    this.unknownValueLabel,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.prefix,
    this.validator,
    this.autovalidateMode,
    this.reserveCaption = false,
    this.enabled = true,
    this.isLoading = false,
    this.searchable = false,
    this.autofocusSearch = false,
    this.searchPlaceholder = 'Search...',
    this.filter,
    this.emptyText = 'No matches',
    this.emptyState,
    this.sheetTitle,
    this.presentation = OrionDropdownPresentation.popover,
    this.optionBuilder,
    this.selectedBuilder,
    this.variant = OrionDropdownVariant.outline,
    this.size = OrionDropdownSize.medium,
    this.placement = OrionPopoverPlacement.bottomStart,
    this.autoFlip = true,
    this.dismissOnScroll = true,
    this.controller,
    this.focusNode,
    this.style,
  }) : _isMulti = false,
       values = const <Never>{},
       onValuesChanged = null,
       multiValidator = null,
       maxVisibleTags = 2;

  /// Creates a multi-select dropdown control.
  ///
  /// Options display leading [OrionCheckbox] indicators and toggling keeps the
  /// panel or bottom sheet open until dismissed or confirmed via `Done`.
  const OrionDropdown.multi({
    super.key,
    required this.options,
    required this.values,
    this.onValuesChanged,
    this.clearable = true,
    this.maxVisibleTags = 2,
    this.label,
    this.placeholder,
    this.helper,
    this.error,
    this.prefix,
    FormFieldValidator<Set<T>>? validator,
    this.autovalidateMode,
    this.reserveCaption = false,
    this.enabled = true,
    this.isLoading = false,
    this.searchable = false,
    this.autofocusSearch = false,
    this.searchPlaceholder = 'Search...',
    this.filter,
    this.emptyText = 'No matches',
    this.emptyState,
    this.sheetTitle,
    this.presentation = OrionDropdownPresentation.popover,
    this.optionBuilder,
    this.selectedBuilder,
    this.variant = OrionDropdownVariant.outline,
    this.size = OrionDropdownSize.medium,
    this.placement = OrionPopoverPlacement.bottomStart,
    this.autoFlip = true,
    this.dismissOnScroll = true,
    this.controller,
    this.focusNode,
    this.style,
  }) : _isMulti = true,
       value = null,
       onChanged = null,
       onCleared = null,
       unknownValueLabel = null,
       validator = null,
       multiValidator = validator;

  final bool _isMulti;

  /// The ordered options.
  final List<OrionDropdownOption<T>> options;

  /// The selected value in single-select mode, owned by the host.
  final T? value;

  /// Called once per commit whose value differs from [value] in single-select.
  final ValueChanged<T>? onChanged;

  /// Whether a clear action is shown inside the open menu/sheet when a
  /// selection is active (defaults to `false` for single-select and `true` for
  /// [OrionDropdown.multi]).
  final bool clearable;

  /// Called when the clear button is tapped in single-select mode.
  final VoidCallback? onCleared;

  /// Optional label builder used when [value] is non-null but not yet present
  /// in [options] (for example while options load asynchronously).
  final String Function(T value)? unknownValueLabel;

  /// The selected values in multi-select mode (`OrionDropdown.multi`).
  final Set<T> values;

  /// Called whenever the selected set changes in multi-select mode.
  final ValueChanged<Set<T>>? onValuesChanged;

  /// Maximum number of inline selected tags shown on the trigger in multi-select
  /// mode before collapsing remaining selections into a `+N` badge.
  final int maxVisibleTags;

  /// The field label shown above the face.
  final String? label;

  /// Shown in the face while no value is selected.
  final String? placeholder;

  /// Caption below the face, replaced by the error text when one exists.
  final String? helper;

  /// Explicit error text; the field's validator result wins when present.
  final String? error;

  /// Optional fixed leading widget shown before the text / selected option
  /// leading.
  final Widget? prefix;

  /// Form validation over the nullable single-select value.
  final FormFieldValidator<T?>? validator;

  /// Form validation over the multi-select set.
  final FormFieldValidator<Set<T>>? multiValidator;

  /// When validation runs.
  final AutovalidateMode? autovalidateMode;

  /// Keeps the caption row present so validation cannot reflow the form.
  final bool reserveCaption;

  /// False mutes the control and takes no input.
  final bool enabled;

  /// True shows a compact loading spinner on the trigger and a loading state
  /// when [options] is empty.
  final bool isLoading;

  /// When true, renders a search input docked at the top of the panel or sheet
  /// to filter [options].
  final bool searchable;

  /// Whether opening a [searchable] dropdown by tap automatically focuses the
  /// search field (opening the soft keyboard on mobile). Defaults to `false`
  /// so mobile users can browse options first and tap the search bar on demand.
  /// Opening via hardware keyboard always focuses the search field.
  final bool autofocusSearch;

  /// Placeholder text inside the search input when [searchable] is true.
  final String searchPlaceholder;

  /// Optional custom filter predicate. Defaults to a case-insensitive
  /// subsequence across label, description, group, `searchTerms`, and String
  /// values.
  final OrionDropdownFilter<T>? filter;

  /// Message displayed when search yields no matching options (or options are
  /// empty).
  final String emptyText;

  /// Optional custom empty-state widget overriding [emptyText].
  final Widget? emptyState;

  /// Optional title displayed in the header when presented as a bottom sheet.
  /// Defaults to [label] or [placeholder].
  final String? sheetTitle;

  /// Controls whether the option list opens as an anchored popover, a modal
  /// [OrionBottomSheet], or adapts automatically on compact screens.
  final OrionDropdownPresentation presentation;

  /// Optional custom builder for each option row's body.
  final OrionDropdownOptionBuilder<T>? optionBuilder;

  /// Optional custom builder for the trigger face's selected-value area.
  final OrionDropdownSelectedBuilder<T>? selectedBuilder;

  /// The face of the trigger.
  final OrionDropdownVariant variant;

  /// The size step of the trigger face.
  final OrionDropdownSize size;

  /// Preferred placement of the popover panel relative to the field.
  final OrionPopoverPlacement placement;

  /// Whether the popover panel flips to the opposite side when space runs out.
  final bool autoFlip;

  /// Whether scrolling an ancestor dismisses the popover panel.
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
  /// Focus is not a press: the line arrives cleanly without bouncing.
  static const OrionSpringSpec _faceFocus = OrionSpringSpec(
    stiffness: 380,
    dampingRatio: 1,
    clampOvershoot: true,
  );

  final GlobalKey _triggerKey = GlobalKey();
  final GlobalKey _panelSurfaceKey = GlobalKey();
  final GlobalKey<_OrionDropdownPanelState<T>> _panelStateKey =
      GlobalKey<_OrionDropdownPanelState<T>>();
  final OverlayPortalController _portalController = OverlayPortalController();
  final ScrollController _panelScrollController = ScrollController();
  final FocusNode _panelFocusNode = FocusNode(debugLabel: 'OrionDropdownPanel');
  final FocusNode _queryFocus = FocusNode(debugLabel: 'OrionDropdownQuery');
  final TextEditingController _queryController = TextEditingController();
  final ValueNotifier<int> _sheetRevision = ValueNotifier<int>(0);

  late final OrionSpringDriver _openDriver;
  late final OrionSpringDriver _faceFocusDriver;
  late final OrionSpringDriver _highlightDriver;

  OrionPopoverController? _internalController;
  OrionPopoverController get _effectiveController =>
      widget.controller ?? (_internalController ??= OrionPopoverController());

  OrionSheetController? _activeSheetController;
  Set<T> _liveMultiValues = <T>{};

  late FocusNode _focusNode;
  bool _ownsFocus = false;
  bool _focusBound = false;

  bool _isOpen = false;
  bool _isClosing = false;
  bool _isSheetOpen = false;
  bool _hovered = false;
  bool _showActiveHighlight = false;
  bool _queryKeysArmed = false;

  /// Live query inside the search input. Cleared as soon as closing starts.
  String _query = '';

  /// Query applied to the option list. Held through closing so rows do not
  /// jump while the panel leaves.
  String _listQuery = '';

  int? _activeIndex;
  OrionPopoverResolvedLayout? _resolvedLayout;
  Rect? _lastTriggerRect;
  FormFieldState<Object?>? _field;
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

  /// Whether the dropdown (popover or sheet) is currently open.
  @visibleForTesting
  bool get isOpen => _isOpen;

  /// The popover panel's global rect, or null while closed or in sheet mode.
  @visibleForTesting
  Rect? get panelRect {
    final RenderObject? renderObject = _panelSurfaceKey.currentContext
        ?.findRenderObject();
    if (renderObject is! RenderBox || !renderObject.attached) return null;
    return renderObject.localToGlobal(Offset.zero) & renderObject.size;
  }

  @override
  void initState() {
    super.initState();
    _liveMultiValues = Set<T>.of(widget.values);
    _openDriver = OrionSpringDriver(
      vsync: this,
      initialValue: 0.0,
      springSpec: OrionDropdownPresets.openSpring,
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
    _queryFocus.addListener(_onQueryFocusChanged);
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
    if (widget._isMulti) {
      _liveMultiValues = Set<T>.of(widget.values);
    }
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
              !widget.options[current].enabled ||
              _visiblePosition(current) < 0)) {
        _setActive(_resolveFallbackActive(), glide: false);
      }
    }
    if (!widget.enabled && _isOpen) {
      hide();
    }
    _resolvedStyle = _resolveStyle(Theme.of(context));
    _syncMotionSpecs();
    _syncFaceFocus();
    if (_isSheetOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _isSheetOpen) {
          _sheetRevision.value += 1;
        }
      });
    }
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
    if (_queryKeysArmed) {
      FocusManager.instance.removeEarlyKeyEventHandler(_onEarlyQueryKey);
    }
    _queryFocus.removeListener(_onQueryFocusChanged);
    _queryFocus.dispose();
    _queryController.dispose();
    _panelFocusNode.dispose();
    _panelScrollController.dispose();
    _sheetRevision.dispose();
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

  OrionHapticType _effectiveHaptic(BuildContext context) {
    return _resolvedStyle.hapticType ?? OrionTheme.of(context).selectionHaptic;
  }

  void _syncMotionSpecs() {
    _openDriver.springSpec =
        _resolvedStyle.springSpec ?? OrionDropdownPresets.openSpring;
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

  bool _usesSheet(BuildContext context) {
    return switch (widget.presentation) {
      OrionDropdownPresentation.popover => false,
      OrionDropdownPresentation.sheet => true,
      OrionDropdownPresentation.auto =>
        MediaQuery.sizeOf(context).width < 600.0 &&
            (widget.searchable || widget.options.length > 6),
    };
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

  bool _isValueSelected(T optionValue) {
    if (widget._isMulti) {
      return _liveMultiValues.contains(optionValue);
    }
    return widget.value != null && widget.value == optionValue;
  }

  List<OrionDropdownOption<T>> _selectedOptions() {
    if (!widget._isMulti) {
      final int idx = _indexOf(widget.value);
      return idx >= 0
          ? <OrionDropdownOption<T>>[widget.options[idx]]
          : const <OrionDropdownOption<Never>>[];
    }
    final List<OrionDropdownOption<T>> result = <OrionDropdownOption<T>>[];
    for (final OrionDropdownOption<T> option in widget.options) {
      if (_liveMultiValues.contains(option.value)) {
        result.add(option);
      }
    }
    return result;
  }

  /// Case-insensitive subsequence over label, description, group, searchTerms,
  /// and String values. Custom [widget.filter] wins when provided.
  bool _optionMatches(OrionDropdownOption<T> option, String query) {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) return true;
    if (widget.filter != null) {
      return widget.filter!(option, trimmed);
    }
    final String needle = trimmed.toLowerCase();
    final StringBuffer haystack = StringBuffer(option.label);
    final String? description = option.description;
    if (description != null) {
      haystack
        ..write(' ')
        ..write(description);
    }
    final String? group = option.group;
    if (group != null) {
      haystack
        ..write(' ')
        ..write(group);
    }
    final List<String>? terms = option.searchTerms;
    if (terms != null) {
      for (final String term in terms) {
        haystack
          ..write(' ')
          ..write(term);
      }
    }
    final T value = option.value;
    if (value is String) {
      haystack
        ..write(' ')
        ..write(value);
    }
    final String text = haystack.toString().toLowerCase();
    int queryIndex = 0;
    for (int i = 0; i < text.length; i++) {
      if (text[i] == needle[queryIndex]) queryIndex += 1;
      if (queryIndex == needle.length) return true;
    }
    return false;
  }

  List<int> _visibleIndicesFor(String query) {
    final int count = widget.options.length;
    if (!widget.searchable || query.trim().isEmpty) {
      return List<int>.generate(count, (int index) => index);
    }
    final List<int> indices = <int>[];
    for (int i = 0; i < count; i++) {
      if (_optionMatches(widget.options[i], query)) indices.add(i);
    }
    return indices;
  }

  List<int> _visibleIndices() => _visibleIndicesFor(_listQuery);

  int _visiblePosition(int? optionIndex) {
    if (optionIndex == null) return -1;
    return _visibleIndices().indexOf(optionIndex);
  }

  int? _resolveFallbackActive() {
    final List<int> enabled = _enabledIndices();
    if (!widget._isMulti) {
      final int selected = _indexOf(widget.value);
      if (enabled.contains(selected)) return selected;
    } else if (_liveMultiValues.isNotEmpty) {
      for (final int idx in enabled) {
        if (_liveMultiValues.contains(widget.options[idx].value)) return idx;
      }
    }
    if (enabled.isEmpty) return null;
    return enabled.first;
  }

  List<int> _enabledIndices() {
    final List<int> indices = <int>[];
    for (final int index in _visibleIndices()) {
      if (widget.options[index].enabled) indices.add(index);
    }
    return indices;
  }

  void _setActive(
    int? index, {
    bool glide = true,
    bool showHighlight = false,
  }) {
    final bool changed = index != _activeIndex;
    final bool highlightChanged = showHighlight && !_showActiveHighlight;
    _activeIndex = index;
    if (showHighlight) {
      _showActiveHighlight = true;
    }
    if (index == null) {
      if (highlightChanged) setState(() {});
      return;
    }
    final int position = _visiblePosition(index);
    if (position < 0) return;
    final double target = position.toDouble();
    final bool parked =
        (_highlightDriver.target - target).abs() < 0.001 &&
        (_highlightDriver.value - target).abs() < 0.001;
    if (!changed && parked) {
      if (highlightChanged) setState(() {});
      return;
    }
    if (glide && changed && !_highlightDriver.reducedMotion) {
      _highlightDriver.retarget(target);
    } else {
      _highlightDriver.jumpTo(target);
    }
    if (highlightChanged || changed) {
      setState(() {});
    }
  }

  void _clearHoverHighlight() {
    if (_showActiveHighlight) {
      setState(() => _showActiveHighlight = false);
    }
  }

  void _revealActive() {
    final int position = _visiblePosition(_activeIndex);
    _panelStateKey.currentState?.ensureRowVisible(
      position < 0 ? null : position,
    );
  }

  Rect? _measureTriggerRect() {
    final RenderBox? box =
        _triggerKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) return null;
    final Offset globalOffset = box.localToGlobal(Offset.zero);
    return globalOffset & box.size;
  }

  double _resolvePanelWidth(BuildContext context, Rect triggerRect) {
    final double viewportMaxWidth = math.max(
      140.0,
      MediaQuery.sizeOf(context).width - 24.0,
    );
    final double upper = _resolvedStyle.panelMaxWidth != null
        ? math.min(_resolvedStyle.panelMaxWidth!, viewportMaxWidth)
        : viewportMaxWidth;
    final double lower = math.min(140.0, upper);
    return triggerRect.width.clamp(lower, upper);
  }

  double _effectiveKeyboardBottom(BuildContext context, MediaQueryData mq) {
    final FlutterView? view = View.maybeOf(context);
    final double rawBottom = view == null
        ? 0.0
        : view.viewInsets.bottom / view.devicePixelRatio;
    return math.max(mq.viewInsets.bottom, rawBottom);
  }

  /// Opens the dropdown panel or bottom sheet.
  void show({bool fromKeyboard = false}) {
    if ((_isOpen && !_isClosing) || !widget.enabled) return;
    if (_usesSheet(context)) {
      _showSheet();
      return;
    }
    _showPopover(fromKeyboard: fromKeyboard);
  }

  void _showPopover({required bool fromKeyboard}) {
    final Rect? rect = _measureTriggerRect();
    if (rect == null) return;
    _lastTriggerRect = rect;
    _isClosing = false;
    _isOpen = true;
    _showActiveHighlight = fromKeyboard;
    if (widget.searchable) {
      _query = '';
      _listQuery = '';
      _queryController.clear();
    }
    _setActive(
      _resolveFallbackActive(),
      glide: false,
      showHighlight: fromKeyboard,
    );
    _effectiveController.updateOpenState(true);
    _syncMotionSpecs();

    final MediaQueryData mq = MediaQuery.of(context);
    final double panelWidth = _resolvePanelWidth(context, rect);
    final double topInset = mq.padding.top + 12.0;
    final double bottomInset =
        math.max(mq.padding.bottom, _effectiveKeyboardBottom(context, mq)) +
        12.0;
    final double searchChrome = widget.searchable ? 48.0 : 0.0;
    final double footerChrome =
        (widget._isMulti || (widget.clearable && widget.value != null))
        ? 48.0
        : 0.0;
    final double estimatedHeight = math.min(
      _resolvedStyle.panelMaxHeight ?? 320.0,
      searchChrome +
          footerChrome +
          math.max(1, widget.options.length) *
              (_resolvedStyle.rowMinHeight ?? 44.0) +
          ((_resolvedStyle.panelPadding ?? const EdgeInsets.all(8.0))
              .resolve(Directionality.of(context))
              .vertical),
    );
    _resolvedLayout = OrionPopoverGeometry.resolve(
      triggerRect: rect,
      popoverSize: Size(panelWidth, estimatedHeight),
      viewportSize: mq.size,
      viewportPadding: EdgeInsets.fromLTRB(12.0, topInset, 12.0, bottomInset),
      preferredPlacement: _effectivePlacement(context),
      gap: _resolvedStyle.panelGap ?? 6.0,
      autoFlip: widget.autoFlip,
      showArrow: false,
      arrowSize: Size.zero,
    );

    _portalController.show();
    if (_openDriver.reducedMotion) {
      _openDriver.jumpTo(1.0);
    } else {
      _openDriver.springSpec =
          _resolvedStyle.springSpec ?? OrionDropdownPresets.openSpring;
      _openDriver.retarget(1.0);
    }
    OrionHaptics.trigger(_effectiveHaptic(context));
    _syncFaceFocus();
    setState(() {});
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isOpen || _isSheetOpen) return;
      if (widget.searchable && (fromKeyboard || widget.autofocusSearch)) {
        _queryFocus.requestFocus();
      } else {
        _panelFocusNode.requestFocus();
      }
      _revealActive();
    });
  }

  void _showSheet() {
    _isOpen = true;
    _isClosing = false;
    _isSheetOpen = true;
    _query = '';
    _listQuery = '';
    _queryController.clear();
    _effectiveController.updateOpenState(true);
    _syncMotionSpecs();
    if (_openDriver.reducedMotion) {
      _openDriver.jumpTo(1.0);
    } else {
      _openDriver.springSpec =
          _resolvedStyle.springSpec ?? OrionDropdownPresets.openSpring;
      _openDriver.retarget(1.0);
    }
    OrionHaptics.trigger(_effectiveHaptic(context));
    _syncFaceFocus();
    setState(() {});

    final OrionSheetController sheetController = OrionSheetController();
    _activeSheetController = sheetController;

    final bool fitContent = !widget.searchable && widget.options.length <= 7;
    final List<double> detents = widget.searchable
        ? const <double>[0.80]
        : const <double>[0.75];

    showOrionBottomSheet<void>(
      context: context,
      controller: sheetController,
      fitContent: fitContent,
      detents: detents,
      maxHeightFraction: 0.88,
      title: widget.sheetTitle ?? widget.label ?? widget.placeholder ?? 'Select',
      showCloseButton: true,
      builder: (BuildContext sheetContext, ScrollController scrollController) {
        return _OrionDropdownSheetBody<T>(
          revision: _sheetRevision,
          scrollController: scrollController,
          fitContent: fitContent,
          options: widget.options,
          isMulti: widget._isMulti,
          clearable: widget.clearable,
          hasSingleSelection: !widget._isMulti && widget.value != null,
          isLoading: widget.isLoading,
          searchable: widget.searchable,
          autofocusSearch: widget.autofocusSearch,
          searchPlaceholder: widget.searchPlaceholder,
          emptyText: widget.emptyText,
          emptyState: widget.emptyState,
          style: _resolvedStyle,
          optionBuilder: widget.optionBuilder,
          isSelected: _isValueSelected,
          filterOption: _optionMatches,
          selectedCount: () => _liveMultiValues.length,
          onSelectSingle: (int index) {
            _commitSingle(index, closeSheetContext: sheetContext);
          },
          onClearSingle: () {
            _clearSingle(closeSheetContext: sheetContext);
          },
          onToggleMulti: _toggleMulti,
          onClearMulti: _clearAll,
          onDoneMulti: () => OrionBottomSheet.dismissOf<void>(sheetContext),
        );
      },
    ).whenComplete(() {
      _activeSheetController = null;
      sheetController.dispose();
      if (!mounted) return;
      _isSheetOpen = false;
      _isOpen = false;
      _isClosing = false;
      _effectiveController.updateOpenState(false);
      if (_openDriver.reducedMotion) {
        _openDriver.jumpTo(0.0);
      } else {
        _openDriver.springSpec =
            _resolvedStyle.dismissSpringSpec ??
            OrionDropdownPresets.dismissSpring;
        _openDriver.retarget(0.0);
      }
      _syncFaceFocus();
      setState(() {});
    });
  }

  /// Closes the panel or bottom sheet.
  void hide({bool restoreFocus = false}) {
    if (!_isOpen || _isClosing) return;
    if (_isSheetOpen) {
      _isClosing = true;
      _activeSheetController?.dismiss();
      return;
    }
    _isClosing = true;
    if (widget.searchable) {
      _query = '';
      _queryController.clear();
    }
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

  /// Toggles the dropdown between open and closed.
  void toggle() {
    if (_isOpen && !_isClosing) {
      hide();
    } else {
      show();
    }
  }

  void _onOpenTick() {
    if (!_isSheetOpen && _isClosing && _openDriver.value <= 0.02) {
      _finishClose();
    }
  }

  void _onOpenStatus(AnimationStatus status) {
    if (!_isSheetOpen &&
        status == AnimationStatus.completed &&
        _isClosing &&
        _openDriver.value <= 0.02) {
      _finishClose();
    }
  }

  void _finishClose() {
    if (!_isOpen && !_isClosing) return;
    _isClosing = false;
    _isOpen = false;
    _showActiveHighlight = false;
    _listQuery = '';
    if (_openDriver.value > 0.0 || _openDriver.isAnimating) {
      _openDriver.jumpTo(0.0);
    }
    _portalController.hide();
    _effectiveController.updateOpenState(false);
    _syncFaceFocus();
    setState(() {});
  }

  void _commitSingle(int index, {BuildContext? closeSheetContext}) {
    if (index < 0 || index >= widget.options.length) return;
    final OrionDropdownOption<T> option = widget.options[index];
    if (!option.enabled) return;
    final T next = option.value;
    final bool changed = next != widget.value;
    if (closeSheetContext != null) {
      OrionBottomSheet.dismissOf<void>(closeSheetContext);
    } else {
      hide(restoreFocus: true);
    }
    if (!changed) return;
    OrionHaptics.trigger(_effectiveHaptic(context));
    _field?.didChange(next);
    widget.onChanged?.call(next);
  }

  void _toggleMulti(int index) {
    if (index < 0 || index >= widget.options.length) return;
    final OrionDropdownOption<T> option = widget.options[index];
    if (!option.enabled) return;
    final Set<T> next = Set<T>.of(_liveMultiValues);
    if (next.contains(option.value)) {
      next.remove(option.value);
    } else {
      next.add(option.value);
    }
    _liveMultiValues = next;
    OrionHaptics.trigger(_effectiveHaptic(context));
    _field?.didChange(next);
    widget.onValuesChanged?.call(next);
    if (_isSheetOpen) {
      _sheetRevision.value += 1;
    }
    setState(() {});
  }

  void _clearSingle({BuildContext? closeSheetContext}) {
    if (!widget.enabled) return;
    if (closeSheetContext != null) {
      OrionBottomSheet.dismissOf<void>(closeSheetContext);
    } else {
      hide(restoreFocus: true);
    }
    OrionHaptics.trigger(_effectiveHaptic(context));
    _field?.didChange(null);
    widget.onCleared?.call();
  }

  void _clearAll() {
    if (!widget.enabled) return;
    OrionHaptics.trigger(_effectiveHaptic(context));
    if (widget._isMulti) {
      final Set<T> empty = <T>{};
      _liveMultiValues = empty;
      _field?.didChange(empty);
      widget.onValuesChanged?.call(empty);
      if (_isSheetOpen) {
        _sheetRevision.value += 1;
      }
      setState(() {});
      return;
    }
    _field?.didChange(null);
    widget.onCleared?.call();
  }

  void _commitOrToggle(int index) {
    if (widget._isMulti) {
      _toggleMulti(index);
    } else {
      _commitSingle(index);
    }
  }

  void _step(int delta) {
    final List<int> enabled = _enabledIndices();
    if (enabled.isEmpty) return;
    final int at = enabled.indexOf(_activeIndex ?? -1);
    final int next = at < 0
        ? (delta > 0 ? 0 : enabled.length - 1)
        : (at + delta + enabled.length) % enabled.length;
    _setActive(enabled[next], showHighlight: true);
    _revealActive();
  }

  void _setActiveAndReveal(int? index) {
    _setActive(index, showHighlight: true);
    _revealActive();
  }

  void _onQueryFocusChanged() {
    final bool focused = _queryFocus.hasFocus;
    if (focused && !_queryKeysArmed) {
      FocusManager.instance.addEarlyKeyEventHandler(_onEarlyQueryKey);
      _queryKeysArmed = true;
    } else if (!focused && _queryKeysArmed) {
      FocusManager.instance.removeEarlyKeyEventHandler(_onEarlyQueryKey);
      _queryKeysArmed = false;
    }
  }

  /// Runs before the in-panel search TextField so navigation keys move the
  /// option list while Space and letters type into the query.
  KeyEventResult _onEarlyQueryKey(KeyEvent event) {
    if (!_queryFocus.hasFocus || _isSheetOpen) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final LogicalKeyboardKey key = event.logicalKey;
    if (key == LogicalKeyboardKey.arrowDown ||
        key == LogicalKeyboardKey.arrowUp) {
      if (!_isOpen || _isClosing) {
        show(fromKeyboard: true);
      } else {
        _step(key == LogicalKeyboardKey.arrowDown ? 1 : -1);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.home || key == LogicalKeyboardKey.end) {
      if (!_isOpen || _isClosing) return KeyEventResult.ignored;
      final List<int> enabled = _enabledIndices();
      _setActiveAndReveal(
        enabled.isEmpty
            ? null
            : (key == LogicalKeyboardKey.home ? enabled.first : enabled.last),
      );
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.enter) {
      if (_isOpen && !_isClosing && _activeIndex != null) {
        _commitOrToggle(_activeIndex!);
      }
      return KeyEventResult.handled;
    }
    if (key == LogicalKeyboardKey.escape) {
      if (_isOpen && !_isClosing) hide(restoreFocus: true);
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

  void _onQueryChanged(String next) {
    _query = next;
    if (!_isOpen || _isClosing) return;
    _listQuery = next;
    _setActive(
      _resolveFallbackActive(),
      glide: false,
      showHighlight: _showActiveHighlight,
    );
    setState(() {});
  }

  void _clearQuery() {
    _queryController.clear();
    _onQueryChanged('');
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
    show(fromKeyboard: true);
    return KeyEventResult.handled;
  }

  KeyEventResult _onPanelKey(FocusNode node, KeyEvent event) {
    if (_queryFocus.hasFocus) return KeyEventResult.ignored;
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
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
        _commitOrToggle(active);
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
    if (!widget.dismissOnScroll || _isSheetOpen) return;
    if (!_isOpen || _isClosing) return;
    // Ignore layout-induced scroll shifts while the user is typing in the
    // search field (such as the viewport adjusting when the soft keyboard opens).
    if (widget.searchable &&
        _queryFocus.hasFocus &&
        notification is! ScrollStartNotification) {
      return;
    }
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
    return FormField<Object?>(
      initialValue: widget._isMulti ? widget.values : widget.value,
      validator: (Object? fieldValue) {
        if (widget._isMulti) {
          return widget.multiValidator?.call(
            fieldValue is Set<T> ? fieldValue : widget.values,
          );
        }
        return widget.validator?.call(fieldValue is T ? fieldValue : null);
      },
      autovalidateMode: widget.autovalidateMode ?? AutovalidateMode.disabled,
      builder: (FormFieldState<Object?> field) {
        _field = field;
        return _build(context, field);
      },
    );
  }

  Widget _build(BuildContext context, FormFieldState<Object?> field) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionDropdownStyle style = _resolveStyle(theme);
    final bool enabled = widget.enabled;
    final String? errorText = widget.error != null && widget.error!.isNotEmpty
        ? widget.error
        : field.errorText;
    final bool hasError = errorText != null && errorText.isNotEmpty;
    final String? caption = hasError ? errorText : widget.helper;

    final List<OrionDropdownOption<T>> selected = _selectedOptions();
    final OrionDropdownOption<T>? singleSelected =
        !widget._isMulti && selected.isNotEmpty ? selected.first : null;
    final String? fallbackUnknownLabel =
        !widget._isMulti && singleSelected == null && widget.value != null
        ? widget.unknownValueLabel?.call(widget.value as T)
        : null;

    final String? semanticValue;
    if (widget._isMulti) {
      semanticValue = selected.isEmpty
          ? null
          : selected.map((OrionDropdownOption<T> o) => o.label).join(', ');
    } else {
      semanticValue = singleSelected?.label ?? fallbackUnknownLabel;
    }

    final Widget trigger = Semantics(
      container: true,
      button: true,
      enabled: enabled,
      expanded: _isOpen,
      label: widget.label ?? widget.placeholder,
      value: semanticValue,
      child: ExcludeSemantics(
        child: MouseRegion(
          cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
          onEnter: enabled ? (_) => setState(() => _hovered = true) : null,
          onExit: (_) {
            if (_hovered) setState(() => _hovered = false);
          },
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
                selected: selected,
                singleLabel: singleSelected?.label ?? fallbackUnknownLabel,
                singleLeading: singleSelected?.leading,
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
    required List<OrionDropdownOption<T>> selected,
    required String? singleLabel,
    required Widget? singleLeading,
  }) {
    final Set<WidgetState> restingStates = <WidgetState>{
      if (!enabled) WidgetState.disabled,
      if (hasError) WidgetState.error,
    };
    final Set<WidgetState> focusedStates = <WidgetState>{
      WidgetState.focused,
      ...restingStates,
    };
    final Color baseFill =
        style.fillColor?.resolve(restingStates) ?? scheme.surface;
    final Color? hoverOverlay = style.hoverFillColor;
    final Color fill = _hovered && enabled && hoverOverlay != null
        ? Color.alphaBlend(hoverOverlay, baseFill)
        : baseFill;
    final Color borderRest =
        style.borderColor?.resolve(restingStates) ?? scheme.outline;
    final Color borderFocused =
        style.borderColor?.resolve(focusedStates) ?? scheme.primary;
    final double borderWidth = style.borderWidth ?? 1.0;
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
    final bool hasValue = widget._isMulti
        ? selected.isNotEmpty
        : singleLabel != null;

    final bool searchMark =
        widget.searchable &&
        widget.prefix == null &&
        (!hasValue || widget._isMulti);
    final Widget? effectiveLeading =
        widget.prefix ??
        (searchMark
            ? const Icon(Icons.search_rounded)
            : (!widget._isMulti && hasValue ? singleLeading : null));

    final Widget valueArea;
    if (widget.selectedBuilder != null && hasValue) {
      valueArea = widget.selectedBuilder!(context, selected);
    } else if (widget._isMulti && selected.isNotEmpty) {
      valueArea = _buildMultiValueTags(
        context,
        scheme: scheme,
        selected: selected,
        enabled: enabled,
      );
    } else {
      valueArea = Text(
        singleLabel ?? widget.placeholder ?? '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textStyle.copyWith(color: hasValue ? textColor : hintColor),
      );
    }

    final double iconSize = style.iconSize ?? 18.0;

    final Widget content = Padding(
      padding: EdgeInsets.only(
        left: padding.left,
        right: padding.right,
        top: widget._isMulti && selected.isNotEmpty ? 6.0 : padding.top,
        bottom: widget._isMulti && selected.isNotEmpty ? 6.0 : padding.bottom,
      ),
      child: Row(
        children: <Widget>[
          if (effectiveLeading != null) ...<Widget>[
            IconTheme.merge(
              data: IconThemeData(
                color: searchMark || !hasValue ? hintColor : textColor,
                size: iconSize,
              ),
              child: effectiveLeading,
            ),
            const SizedBox(width: 8.0),
          ],
          Expanded(child: valueArea),
          const SizedBox(width: 8.0),
          if (widget.isLoading)
            SizedBox.square(
              dimension: 16.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: scheme.onSurfaceVariant,
              ),
            )
          else
            AnimatedBuilder(
              animation: _openDriver,
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                size: iconSize,
                color: enabled
                    ? (style.chevronColor ?? scheme.onSurfaceVariant)
                    : hintColor,
              ),
              builder: (BuildContext context, Widget? child) =>
                  Transform.rotate(
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
          final double width = borderWidth <= 0
              ? 0.0
              : borderWidth + 0.5 * progress;
          final BorderRadius radius =
              style.radius ?? BorderRadius.circular(OrionRadii.radius8);

          return DecoratedBox(
            decoration: BoxDecoration(
              color: fill,
              borderRadius: radius,
              border: width <= 0
                  ? null
                  : (underline
                        ? Border(
                            bottom: BorderSide(
                              color: borderColor,
                              width: width,
                            ),
                          )
                        : Border.all(color: borderColor, width: width)),
            ),
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildMultiValueTags(
    BuildContext context, {
    required ColorScheme scheme,
    required List<OrionDropdownOption<T>> selected,
    required bool enabled,
  }) {
    final int maxTags = math.max(1, widget.maxVisibleTags);
    final List<OrionDropdownOption<T>> visible = selected.take(maxTags).toList();
    final int overflow = selected.length - visible.length;
    final TextStyle tagStyle =
        (Theme.of(context).textTheme.labelSmall ??
                const TextStyle(fontSize: 12.0))
            .copyWith(
              fontWeight: FontWeight.w500,
              color: enabled
                  ? scheme.onSecondary
                  : scheme.onSurface.withValues(alpha: 0.38),
            );

    return Wrap(
      spacing: 6.0,
      runSpacing: 6.0,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: <Widget>[
        for (final OrionDropdownOption<T> option in visible)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: scheme.secondary,
              borderRadius: BorderRadius.circular(OrionRadii.radius6),
              border: Border.all(color: scheme.outlineVariant, width: 1.0),
            ),
            child: Text(
              option.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: tagStyle,
            ),
          ),
        if (overflow > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7.0, vertical: 3.0),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(OrionRadii.radius6),
            ),
            child: Text(
              '+$overflow',
              style: tagStyle.copyWith(
                fontWeight: FontWeight.w600,
                color: scheme.primary,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildOverlay(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final OrionDropdownStyle style = _resolveStyle(theme);
    final MediaQueryData mq = MediaQuery.of(context);
    final Rect? measuredTrigger = _measureTriggerRect() ?? _lastTriggerRect;
    final Rect triggerRect = measuredTrigger ?? Rect.zero;
    final double panelWidth = _resolvePanelWidth(context, triggerRect);
    final double gap = style.panelGap ?? 6.0;
    final double topInset = mq.padding.top + 12.0;
    final double bottomInset =
        math.max(mq.padding.bottom, _effectiveKeyboardBottom(context, mq)) +
        12.0;
    final EdgeInsets viewportPadding = EdgeInsets.fromLTRB(
      12.0,
      topInset,
      12.0,
      bottomInset,
    );

    final double spaceBelow = math.max(
      0.0,
      mq.size.height - bottomInset - triggerRect.bottom - gap,
    );
    final double spaceAbove = math.max(
      0.0,
      triggerRect.top - topInset - gap,
    );
    final double maxAvailable = widget.autoFlip
        ? math.max(spaceBelow, spaceAbove)
        : (_panelIsAbove ? spaceAbove : spaceBelow);
    final double effectivePanelMaxHeight = math.min(
      style.panelMaxHeight ?? 320.0,
      math.max(120.0, maxAvailable),
    );

    final Widget panel = SizedBox(
      width: panelWidth,
      child: _buildPanelSurface(
        context,
        style,
        ConstrainedBox(
          constraints: BoxConstraints(maxHeight: effectivePanelMaxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              if (widget.searchable)
                _DropdownSearchHeader(
                  controller: _queryController,
                  focusNode: _queryFocus,
                  placeholder: widget.searchPlaceholder,
                  hasQuery: _query.isNotEmpty,
                  onChanged: _onQueryChanged,
                  onClear: _clearQuery,
                ),
              Flexible(
                child: _OrionDropdownPanel<T>(
                  key: _panelStateKey,
                  options: widget.options,
                  rowIndices: _visibleIndices(),
                  activeIndex: _activeIndex,
                  showActiveHighlight: _showActiveHighlight,
                  isMulti: widget._isMulti,
                  isLoading: widget.isLoading,
                  emptyText: widget.emptyText,
                  emptyState: widget.emptyState,
                  style: style,
                  isSelected: _isValueSelected,
                  optionBuilder: widget.optionBuilder,
                  highlightDriver: _highlightDriver,
                  scrollController: _panelScrollController,
                  onSelect: _commitOrToggle,
                  onHover: (int idx) => _setActive(idx, showHighlight: true),
                  onHoverExit: _clearHoverHighlight,
                ),
              ),
              if (widget._isMulti)
                _DropdownMultiFooter(
                  selectedCount: _liveMultiValues.length,
                  compact: true,
                  showClear: widget.clearable,
                  onClear: _liveMultiValues.isNotEmpty ? _clearAll : null,
                  onDone: () => hide(restoreFocus: true),
                )
              else if (widget.clearable && widget.value != null)
                _DropdownSingleClearFooter(
                  compact: true,
                  onClear: _clearSingle,
                ),
            ],
          ),
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
              child: IgnorePointer(
                ignoring: _isClosing,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  excludeFromSemantics: true,
                  onTap: () => hide(),
                  onPanStart: widget.dismissOnScroll
                      ? (DragStartDetails _) => hide()
                      : null,
                ),
              ),
            ),
            Positioned.fill(
              child: IgnorePointer(
                ignoring: _isClosing,
                child: CustomSingleChildLayout(
                  delegate: OrionPopoverLayoutDelegate(
                    triggerRect: triggerRect,
                    viewportPadding: viewportPadding,
                    preferredPlacement: _effectivePlacement(context),
                    gap: gap,
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
                      final double opacity = _isClosing
                          ? progress
                          : (progress * 2.0).clamp(0.0, 1.0);
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
        style.panelBorderRadius ?? BorderRadius.circular(OrionRadii.radius12);
    final double panelBorderWidth = style.panelBorderWidth ?? 1.0;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: DecoratedBox(
        key: _panelSurfaceKey,
        decoration: BoxDecoration(
          color: style.panelColor ?? scheme.surfaceContainer,
          borderRadius: radius,
          border: panelBorderWidth <= 0
              ? null
              : Border.all(
                  color: style.panelBorderColor ?? scheme.outlineVariant,
                  width: panelBorderWidth,
                ),
          boxShadow: style.panelShadow ?? OrionThemeData.defaultShadow,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: Material(type: MaterialType.transparency, child: content),
        ),
      ),
    );
  }
}

class _DropdownSearchHeader extends StatelessWidget {
  const _DropdownSearchHeader({
    required this.controller,
    required this.focusNode,
    required this.placeholder,
    required this.hasQuery,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String placeholder;
  final bool hasQuery;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final TextStyle style =
        (theme.textTheme.bodyMedium ?? const TextStyle(fontSize: 14.0))
            .copyWith(color: scheme.onSurface);

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: scheme.outlineVariant, width: 1.0),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: OrionSpacing.space12,
          vertical: 10.0,
        ),
        child: Row(
          children: <Widget>[
            Icon(
              Icons.search_rounded,
              size: 18.0,
              color: scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8.0),
            Expanded(
              child: TextField(
                key: orionDropdownSearchFieldKey,
                controller: controller,
                focusNode: focusNode,
                maxLines: 1,
                autocorrect: false,
                enableSuggestions: false,
                style: style,
                cursorColor: scheme.primary,
                decoration: InputDecoration(
                  isCollapsed: true,
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  contentPadding: EdgeInsets.zero,
                  hintText: placeholder,
                  hintStyle: style.copyWith(color: scheme.onSurfaceVariant),
                ),
                onChanged: onChanged,
              ),
            ),
            if (hasQuery)
              GestureDetector(
                key: orionDropdownSearchClearKey,
                behavior: HitTestBehavior.opaque,
                onTap: onClear,
                child: Padding(
                  padding: const EdgeInsets.only(left: 8.0),
                  child: Icon(
                    Icons.close_rounded,
                    size: 16.0,
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _DropdownMultiFooter extends StatelessWidget {
  const _DropdownMultiFooter({
    required this.selectedCount,
    required this.compact,
    required this.showClear,
    required this.onClear,
    required this.onDone,
  });

  final int selectedCount;
  final bool compact;
  final bool showClear;
  final VoidCallback? onClear;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionButtonSize buttonSize = compact
        ? OrionButtonSize.small
        : OrionButtonSize.medium;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 1.0),
        ),
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(
                horizontal: OrionSpacing.space12,
                vertical: OrionSpacing.space8,
              )
            : const EdgeInsets.fromLTRB(
                OrionSpacing.space16,
                OrionSpacing.space12,
                OrionSpacing.space16,
                OrionSpacing.space16,
              ),
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                '$selectedCount selected',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    (compact
                            ? theme.textTheme.bodySmall
                            : theme.textTheme.bodyMedium)
                        ?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
              ),
            ),
            const SizedBox(width: OrionSpacing.space8),
            if (showClear) ...<Widget>[
              OrionButton(
                key: orionDropdownMultiClearKey,
                variant: OrionButtonVariant.bordered,
                size: buttonSize,
                label: 'Clear',
                onPressed: onClear,
              ),
              const SizedBox(width: OrionSpacing.space8),
            ],
            OrionButton(
              key: orionDropdownMultiDoneKey,
              variant: OrionButtonVariant.solid,
              size: buttonSize,
              label: 'Done',
              onPressed: onDone,
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownSingleClearFooter extends StatelessWidget {
  const _DropdownSingleClearFooter({
    required this.compact,
    required this.onClear,
  });

  final bool compact;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: scheme.outlineVariant, width: 1.0),
        ),
      ),
      child: Padding(
        padding: compact
            ? const EdgeInsets.symmetric(
                horizontal: OrionSpacing.space8,
                vertical: OrionSpacing.space4,
              )
            : const EdgeInsets.fromLTRB(
                OrionSpacing.space16,
                OrionSpacing.space12,
                OrionSpacing.space16,
                OrionSpacing.space16,
              ),
        child: OrionButton(
          key: orionDropdownClearButtonKey,
          variant: compact
              ? OrionButtonVariant.flat
              : OrionButtonVariant.bordered,
          size: compact ? OrionButtonSize.small : OrionButtonSize.medium,
          isExpanded: true,
          label: 'Clear selection',
          onPressed: onClear,
        ),
      ),
    );
  }
}

class _OrionDropdownSheetBody<T> extends StatefulWidget {
  const _OrionDropdownSheetBody({
    required this.revision,
    required this.scrollController,
    required this.fitContent,
    required this.options,
    required this.isMulti,
    required this.clearable,
    required this.hasSingleSelection,
    required this.isLoading,
    required this.searchable,
    required this.autofocusSearch,
    required this.searchPlaceholder,
    required this.emptyText,
    required this.emptyState,
    required this.style,
    required this.optionBuilder,
    required this.isSelected,
    required this.filterOption,
    required this.selectedCount,
    required this.onSelectSingle,
    required this.onClearSingle,
    required this.onToggleMulti,
    required this.onClearMulti,
    required this.onDoneMulti,
  });

  final ValueNotifier<int> revision;
  final ScrollController scrollController;
  final bool fitContent;
  final List<OrionDropdownOption<T>> options;
  final bool isMulti;
  final bool clearable;
  final bool hasSingleSelection;
  final bool isLoading;
  final bool searchable;
  final bool autofocusSearch;
  final String searchPlaceholder;
  final String emptyText;
  final Widget? emptyState;
  final OrionDropdownStyle style;
  final OrionDropdownOptionBuilder<T>? optionBuilder;
  final bool Function(T value) isSelected;
  final bool Function(OrionDropdownOption<T> option, String query) filterOption;
  final int Function() selectedCount;
  final ValueChanged<int> onSelectSingle;
  final VoidCallback onClearSingle;
  final ValueChanged<int> onToggleMulti;
  final VoidCallback onClearMulti;
  final VoidCallback onDoneMulti;

  @override
  State<_OrionDropdownSheetBody<T>> createState() =>
      _OrionDropdownSheetBodyState<T>();
}

class _OrionDropdownSheetBodyState<T>
    extends State<_OrionDropdownSheetBody<T>> {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocus = FocusNode(
    debugLabel: 'OrionDropdownSheetSearch',
  );
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  List<int> _filteredIndices() {
    if (!widget.searchable || _query.trim().isEmpty) {
      return List<int>.generate(widget.options.length, (int i) => i);
    }
    final List<int> indices = <int>[];
    for (int i = 0; i < widget.options.length; i++) {
      if (widget.filterOption(widget.options[i], _query)) {
        indices.add(i);
      }
    }
    return indices;
  }

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;

    return ValueListenableBuilder<int>(
      valueListenable: widget.revision,
      builder: (BuildContext context, int _, Widget? _) {
        final List<int> indices = _filteredIndices();
        final List<Widget> listItems = _buildGroupedItems<T>(
          context: context,
          options: widget.options,
          rowIndices: indices,
          isMulti: widget.isMulti,
          isLoading: widget.isLoading,
          emptyText: widget.emptyText,
          emptyState: widget.emptyState,
          style: widget.style,
          optionBuilder: widget.optionBuilder,
          isSelected: widget.isSelected,
          rowKeyFor: null,
          onSelect: widget.isMulti
              ? widget.onToggleMulti
              : widget.onSelectSingle,
          onHover: null,
        );

        final Widget listView = SingleChildScrollView(
          controller: widget.scrollController,
          padding: const EdgeInsets.fromLTRB(
            OrionSpacing.space12,
            OrionSpacing.space4,
            OrionSpacing.space12,
            OrionSpacing.space16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: listItems,
          ),
        );

        return Column(
          mainAxisSize: widget.fitContent ? MainAxisSize.min : MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            if (widget.searchable)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  OrionSpacing.space16,
                  0.0,
                  OrionSpacing.space16,
                  OrionSpacing.space8,
                ),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(
                      alpha: 0.65,
                    ),
                    borderRadius: BorderRadius.circular(OrionRadii.radius12),
                    border: Border.all(
                      color: scheme.outlineVariant,
                      width: 1.0,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: OrionSpacing.space12,
                      vertical: 10.0,
                    ),
                    child: Row(
                      children: <Widget>[
                        Icon(
                          Icons.search_rounded,
                          size: 18.0,
                          color: scheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 8.0),
                        Expanded(
                          child: TextField(
                            key: orionDropdownSearchFieldKey,
                            controller: _searchController,
                            focusNode: _searchFocus,
                            autofocus: widget.autofocusSearch,
                            maxLines: 1,
                            autocorrect: false,
                            enableSuggestions: false,
                            decoration: InputDecoration(
                              isCollapsed: true,
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              hintText: widget.searchPlaceholder,
                            ),
                            onChanged: (String value) =>
                                setState(() => _query = value),
                          ),
                        ),
                        if (_query.isNotEmpty)
                          GestureDetector(
                            key: orionDropdownSearchClearKey,
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(left: 8.0),
                              child: Icon(
                                Icons.close_rounded,
                                size: 16.0,
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            if (widget.fitContent)
              Flexible(child: listView)
            else
              Expanded(child: listView),
            if (widget.isMulti)
              _DropdownMultiFooter(
                selectedCount: widget.selectedCount(),
                compact: false,
                showClear: widget.clearable,
                onClear: widget.selectedCount() > 0
                    ? widget.onClearMulti
                    : null,
                onDone: widget.onDoneMulti,
              )
            else if (widget.clearable && widget.hasSingleSelection)
              _DropdownSingleClearFooter(
                compact: false,
                onClear: widget.onClearSingle,
              ),
          ],
        );
      },
    );
  }
}

List<Widget> _buildGroupedItems<T>({
  required BuildContext context,
  required List<OrionDropdownOption<T>> options,
  required List<int> rowIndices,
  required bool isMulti,
  required bool isLoading,
  required String emptyText,
  required Widget? emptyState,
  required OrionDropdownStyle style,
  required OrionDropdownOptionBuilder<T>? optionBuilder,
  required bool Function(T value) isSelected,
  required Key Function(int visiblePosition)? rowKeyFor,
  required ValueChanged<int> onSelect,
  required ValueChanged<int>? onHover,
}) {
  final ColorScheme scheme = Theme.of(context).colorScheme;

  if (rowIndices.isEmpty) {
    if (isLoading) {
      return <Widget>[
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 20.0),
          child: Center(
            child: SizedBox.square(
              dimension: 20.0,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ];
    }
    return <Widget>[
      emptyState ??
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 12.0,
              vertical: 16.0,
            ),
            child: Text(
              emptyText,
              textAlign: TextAlign.center,
              style: (style.rowTitleStyle ?? const TextStyle()).copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
    ];
  }

  final List<Widget> widgets = <Widget>[];
  String? currentGroup;
  for (int i = 0; i < rowIndices.length; i++) {
    final int optionIndex = rowIndices[i];
    final OrionDropdownOption<T> option = options[optionIndex];
    final String? group = option.group;
    bool addedHeader = false;
    if (group != null && group.isNotEmpty && group != currentGroup) {
      currentGroup = group;
      addedHeader = true;
      widgets.add(
        Padding(
          padding: EdgeInsets.fromLTRB(
            12.0,
            i == 0 ? 4.0 : 12.0,
            12.0,
            4.0,
          ),
          child: Text(
            group,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                style.groupHeaderStyle ??
                (Theme.of(context).textTheme.labelSmall ??
                        const TextStyle(fontSize: 11.0))
                    .copyWith(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.4,
                      color: scheme.onSurfaceVariant,
                    ),
          ),
        ),
      );
    }
    if (widgets.isNotEmpty && !addedHeader) {
      widgets.add(const SizedBox(height: 2.0));
    }
    widgets.add(
      _OrionDropdownRow<T>(
        key: rowKeyFor?.call(i),
        option: option,
        style: style,
        isMulti: isMulti,
        isSelected: isSelected(option.value),
        optionBuilder: optionBuilder,
        onSelect: () => onSelect(optionIndex),
        onHover: onHover == null ? null : () => onHover(optionIndex),
      ),
    );
  }
  return widgets;
}

class _OrionDropdownPanel<T> extends StatefulWidget {
  const _OrionDropdownPanel({
    super.key,
    required this.options,
    required this.rowIndices,
    required this.activeIndex,
    required this.showActiveHighlight,
    required this.isMulti,
    required this.isLoading,
    required this.emptyText,
    required this.emptyState,
    required this.style,
    required this.isSelected,
    required this.optionBuilder,
    required this.highlightDriver,
    required this.scrollController,
    required this.onSelect,
    required this.onHover,
    required this.onHoverExit,
  });

  final List<OrionDropdownOption<T>> options;
  final List<int> rowIndices;
  final int? activeIndex;
  final bool showActiveHighlight;
  final bool isMulti;
  final bool isLoading;
  final String emptyText;
  final Widget? emptyState;
  final OrionDropdownStyle style;
  final bool Function(T value) isSelected;
  final OrionDropdownOptionBuilder<T>? optionBuilder;
  final OrionSpringDriver highlightDriver;
  final ScrollController scrollController;
  final ValueChanged<int> onSelect;
  final ValueChanged<int> onHover;
  final VoidCallback onHoverExit;

  @override
  State<_OrionDropdownPanel<T>> createState() => _OrionDropdownPanelState<T>();
}

class _OrionDropdownPanelState<T> extends State<_OrionDropdownPanel<T>> {
  final List<GlobalKey> _rowKeys = <GlobalKey>[];
  final GlobalKey _gliderHostKey = GlobalKey();
  List<Rect> _rowRects = const <Rect>[];
  bool _measureScheduled = false;
  bool _needsMeasure = true;

  @override
  void didUpdateWidget(covariant _OrionDropdownPanel<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_sameIndices(oldWidget.rowIndices, widget.rowIndices) ||
        !identical(oldWidget.options, widget.options)) {
      _rowRects = const <Rect>[];
      _needsMeasure = true;
    }
  }

  bool _sameIndices(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  /// Jumps the smallest scroll that brings [index] fully into view.
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
    if (!_needsMeasure || _measureScheduled) return;
    _measureScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _measureScheduled = false;
      if (!mounted) return;
      final RenderBox? host =
          _gliderHostKey.currentContext?.findRenderObject() as RenderBox?;
      if (host == null) return;
      final List<Rect> rects = <Rect>[];
      final int count = widget.rowIndices.length;
      for (int i = 0; i < count && i < _rowKeys.length; i++) {
        final GlobalKey key = _rowKeys[i];
        final RenderBox? box =
            key.currentContext?.findRenderObject() as RenderBox?;
        if (box == null || !box.attached) return;
        rects.add(box.localToGlobal(Offset.zero, ancestor: host) & box.size);
      }
      _needsMeasure = false;
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
    final List<int> indices = widget.rowIndices;
    final int count = indices.length;
    while (_rowKeys.length < count) {
      _rowKeys.add(GlobalKey());
    }
    while (_rowKeys.length > count) {
      _rowKeys.removeLast();
    }

    final List<Widget> rows = _buildGroupedItems<T>(
      context: context,
      options: widget.options,
      rowIndices: indices,
      isMulti: widget.isMulti,
      isLoading: widget.isLoading,
      emptyText: widget.emptyText,
      emptyState: widget.emptyState,
      style: widget.style,
      optionBuilder: widget.optionBuilder,
      isSelected: widget.isSelected,
      rowKeyFor: (int visiblePosition) => _rowKeys[visiblePosition],
      onSelect: widget.onSelect,
      onHover: widget.onHover,
    );

    _scheduleMeasure();

    final EdgeInsets panelPadding =
        (widget.style.panelPadding ?? const EdgeInsets.all(8.0)).resolve(
          Directionality.of(context),
        );

    return Semantics(
      container: true,
      explicitChildNodes: true,
      child: MouseRegion(
        onExit: (_) => widget.onHoverExit(),
        child: SingleChildScrollView(
          controller: widget.scrollController,
          physics: const BouncingScrollPhysics(),
          child: CustomPaint(
            key: _gliderHostKey,
            painter: _OrionDropdownGliderPainter(
              driver: widget.highlightDriver,
              rects: _rowRects,
              activeIndex: widget.showActiveHighlight
                  ? widget.activeIndex
                  : null,
              color: widget.style.activeRowColor ?? Colors.transparent,
              radius:
                  widget.style.activeRowRadius ??
                  BorderRadius.circular(OrionRadii.radius8),
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

class _OrionDropdownRow<T> extends StatefulWidget {
  const _OrionDropdownRow({
    super.key,
    required this.option,
    required this.style,
    required this.isMulti,
    required this.isSelected,
    required this.optionBuilder,
    required this.onSelect,
    required this.onHover,
  });

  final OrionDropdownOption<T> option;
  final OrionDropdownStyle style;
  final bool isMulti;
  final bool isSelected;
  final OrionDropdownOptionBuilder<T>? optionBuilder;
  final VoidCallback onSelect;
  final VoidCallback? onHover;

  @override
  State<_OrionDropdownRow<T>> createState() => _OrionDropdownRowState<T>();
}

class _OrionDropdownRowState<T> extends State<_OrionDropdownRow<T>> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final ColorScheme scheme = theme.colorScheme;
    final OrionDropdownOption<T> option = widget.option;
    final OrionDropdownStyle style = widget.style;
    final bool enabled = option.enabled;
    final bool isSelected = widget.isSelected;
    final double iconSize = style.iconSize ?? 18.0;
    final BorderRadius rowRadius =
        style.activeRowRadius ?? BorderRadius.circular(OrionRadii.radius8);

    final Color titleColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (isSelected
              ? (style.selectedLabelColor ?? scheme.onSurface)
              : (style.labelColor ?? scheme.onSurface));
    final Color descriptionColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.38)
        : (style.descriptionColor ?? scheme.onSurfaceVariant);

    final Color? rowBackground;
    if (_pressed && enabled) {
      rowBackground = scheme.onSurface.withValues(alpha: 0.08);
    } else if (!widget.isMulti && isSelected && enabled) {
      rowBackground =
          style.selectedRowColor ?? scheme.primary.withValues(alpha: 0.07);
    } else {
      rowBackground = null;
    }

    final Widget body = widget.optionBuilder != null
        ? widget.optionBuilder!(context, option, isSelected)
        : Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                option.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: (style.rowTitleStyle ?? const TextStyle()).copyWith(
                  color: titleColor,
                  fontWeight: isSelected ? FontWeight.w600 : null,
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
          );

    final Widget content = DecoratedBox(
      decoration: BoxDecoration(
        color: rowBackground,
        borderRadius: rowRadius,
      ),
      child: Container(
        constraints: BoxConstraints(minHeight: style.rowMinHeight ?? 44.0),
        alignment: AlignmentDirectional.centerStart,
        child: Padding(
          padding:
              (style.rowPadding ??
                      const EdgeInsets.symmetric(
                        horizontal: 12.0,
                        vertical: 8.0,
                      ))
                  .resolve(Directionality.of(context)),
          child: Row(
            children: <Widget>[
              if (widget.isMulti) ...<Widget>[
                ExcludeSemantics(
                  child: _DropdownCheckBoxIndicator(
                    selected: isSelected,
                    enabled: enabled,
                    accentColor: style.checkColor ?? scheme.primary,
                  ),
                ),
                const SizedBox(width: 10.0),
              ],
              if (option.leading != null) ...<Widget>[
                IconTheme.merge(
                  data: IconThemeData(color: titleColor, size: iconSize),
                  child: option.leading!,
                ),
                const SizedBox(width: 12.0),
              ],
              Expanded(child: body),
              if (option.trailing != null) ...<Widget>[
                const SizedBox(width: 8.0),
                IconTheme.merge(
                  data: IconThemeData(color: descriptionColor, size: iconSize),
                  child: option.trailing!,
                ),
              ],
              if (!widget.isMulti && isSelected) ...<Widget>[
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
      ),
    );

    return Semantics(
      container: true,
      button: true,
      selected: isSelected,
      enabled: enabled,
      inMutuallyExclusiveGroup: !widget.isMulti,
      child: MouseRegion(
        onEnter: enabled && widget.onHover != null
            ? (PointerEnterEvent _) => widget.onHover!()
            : null,
        child: OrionPressable(
          pressedScale: style.pressScale ?? 0.99,
          springSpec: style.pressSpring ?? OrionSpringSpec.snappy,
          releaseSpringSpec: style.releaseSpring,
          hapticType: OrionHapticType.none,
          onPressedChanged: enabled
              ? (bool p) {
                  if (_pressed != p) setState(() => _pressed = p);
                }
              : null,
          onTap: enabled ? widget.onSelect : null,
          child: content,
        ),
      ),
    );
  }
}

/// Compact 18x18 visual checkbox indicator aligned with `OrionCheckbox` for
/// multi-select rows (the parent row already provides the >= 44 pt hit target).
class _DropdownCheckBoxIndicator extends StatelessWidget {
  const _DropdownCheckBoxIndicator({
    required this.selected,
    required this.enabled,
    required this.accentColor,
  });

  final bool selected;
  final bool enabled;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final ColorScheme scheme = Theme.of(context).colorScheme;
    final bool reduced = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final Color fillColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.12)
        : (selected ? accentColor : Colors.transparent);
    final Color borderColor = !enabled
        ? scheme.onSurface.withValues(alpha: 0.24)
        : (selected ? accentColor : scheme.outline);

    return AnimatedContainer(
      duration: reduced ? Duration.zero : const Duration(milliseconds: 140),
      curve: Curves.easeOutCubic,
      width: 18.0,
      height: 18.0,
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(OrionRadii.radius4),
        border: Border.all(color: borderColor, width: 1.5),
      ),
      child: AnimatedScale(
        duration: reduced ? Duration.zero : const Duration(milliseconds: 140),
        curve: Curves.easeOutBack,
        scale: selected ? 1.0 : 0.0,
        child: Icon(
          Icons.check_rounded,
          size: 13.0,
          color: enabled
              ? scheme.onPrimary
              : scheme.onSurface.withValues(alpha: 0.38),
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
    required this.activeIndex,
    required this.color,
    required this.radius,
  }) : super(repaint: driver);

  final Animation<double> driver;
  final List<Rect> rects;
  final int? activeIndex;
  final Color color;
  final BorderRadius radius;

  @override
  void paint(Canvas canvas, Size size) {
    if (activeIndex == null || rects.isEmpty || color.a == 0) return;
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
      oldDelegate.activeIndex != activeIndex ||
      oldDelegate.color != color ||
      oldDelegate.radius != radius;
}
