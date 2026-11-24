import 'package:flutter/material.dart';

import 'package:orion_ui/src/components/button/orion_button.dart';
import 'package:orion_ui/src/components/button/orion_button_style.dart';
import 'package:orion_ui/src/components/chip/orion_chip.dart';
import 'package:orion_ui/src/components/chip/orion_chip_style.dart';
import 'package:orion_ui/src/theme/orion_tokens.dart';

/// How [OrionChipGroup] updates selection when a chip is tapped.
enum OrionChipSelectionMode {
  /// At most one chip is selected at a time (choice chips).
  single,

  /// Any number of chips can be selected simultaneously (filter chips).
  multiple,
}

/// How [OrionChipGroup] lays out its chips.
enum OrionChipGroupLayout {
  /// Single horizontal scrolling strip.
  horizontal,

  /// Multi-line wrapping layout.
  wrap,
}

/// Callback invoked whenever [OrionChipGroup]'s selected values change.
typedef OrionChipSelectionChanged<T> = void Function(Set<T> selectedValues);

/// Optional builder for a summary label above the chip group (for example
/// `"2 filters active"`). Return null or an empty string to hide the label.
typedef OrionChipSelectedCountLabelBuilder =
    String? Function(int selectedCount);

/// Key assigned to the optional clear action in [OrionChipGroup].
const Key orionChipGroupClearKey = Key('orion_chip_group_clear_action');

/// One option rendered by [OrionChipGroup].
@immutable
class OrionChipItem<T> {
  const OrionChipItem({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.enabled = true,
    this.semanticLabel,
  });

  /// Logical value represented by this chip.
  final T value;

  /// Visible label text.
  final String label;

  /// Optional leading widget (for example an [Icon]).
  final Widget? leading;

  /// Optional trailing widget.
  final Widget? trailing;

  /// Whether this individual chip can be toggled.
  final bool enabled;

  /// Optional spoken override for screen readers.
  final String? semanticLabel;
}

/// A managed group of [OrionChip] items supporting single- and multi-select
/// modes, horizontal or wrapping layout, and an optional summary/clear bar.
///
/// When [showCheckmark] is omitted, it defaults to `true` in
/// [OrionChipSelectionMode.multiple] and `false` in
/// [OrionChipSelectionMode.single], preventing horizontal reflow jitter when
/// switching between mutually exclusive choices.
class OrionChipGroup<T> extends StatelessWidget {
  const OrionChipGroup({
    super.key,
    required this.items,
    required this.selectedValues,
    required this.onSelectionChanged,
    this.selectionMode = OrionChipSelectionMode.multiple,
    this.layout = OrionChipGroupLayout.wrap,
    this.allowDeselect = true,
    this.showCheckmark,
    this.enabled = true,
    this.size = OrionChipSize.medium,
    this.spacing = OrionSpacing.space8,
    this.runSpacing = OrionSpacing.space8,
    this.padding,
    this.clipBehavior = Clip.none,
    this.style,
    this.showClearAction = false,
    this.clearActionLabel = 'Clear',
    this.onClear,
    this.selectedCountLabelBuilder,
  }) : assert(spacing >= 0, 'spacing must be greater than or equal to zero.'),
       assert(
         runSpacing >= 0,
         'runSpacing must be greater than or equal to zero.',
       );

  /// The options to render in order.
  final List<OrionChipItem<T>> items;

  /// Currently selected values. The parent owns this set.
  final Set<T> selectedValues;

  /// Called with the next selection set. Null disables the entire group.
  final OrionChipSelectionChanged<T>? onSelectionChanged;

  /// Whether taps toggle multiple selections or choose a single option.
  final OrionChipSelectionMode selectionMode;

  /// Whether chips wrap across lines or scroll horizontally in a single strip.
  final OrionChipGroupLayout layout;

  /// In [OrionChipSelectionMode.single], whether tapping the already-selected
  /// chip clears the selection. Ignored in [OrionChipSelectionMode.multiple].
  final bool allowDeselect;

  /// Whether chips display an animated checkmark when selected.
  ///
  /// Defaults to `true` for [OrionChipSelectionMode.multiple] and `false` for
  /// [OrionChipSelectionMode.single].
  final bool? showCheckmark;

  /// Master enabled flag for all chips and the optional clear button.
  final bool enabled;

  /// Size step applied to every chip in the group.
  final OrionChipSize size;

  /// Horizontal spacing between adjacent chips.
  final double spacing;

  /// Vertical spacing between wrapped rows when [layout] is
  /// [OrionChipGroupLayout.wrap].
  final double runSpacing;

  /// Optional padding around the group. In [OrionChipGroupLayout.horizontal],
  /// horizontal insets are applied inside the scroll view so chips scroll
  /// smoothly to the edge without clipping at the gutter.
  final EdgeInsetsGeometry? padding;

  /// Clip behavior forwarded to the horizontal [SingleChildScrollView].
  final Clip clipBehavior;

  /// Optional style override forwarded to every [OrionChip] in the group.
  final OrionChipStyle? style;

  /// Whether to show a trailing clear button in the optional header meta row.
  final bool showClearAction;

  /// Label for the clear button when [showClearAction] is true.
  final String clearActionLabel;

  /// Custom callback for the clear button. Defaults to calling
  /// [onSelectionChanged] with an empty set.
  final VoidCallback? onClear;

  /// Optional summary text builder displayed on the leading side of the header
  /// meta row.
  final OrionChipSelectedCountLabelBuilder? selectedCountLabelBuilder;

  bool get _groupEnabled => enabled && onSelectionChanged != null;

  bool get _isClearEnabled => _groupEnabled && selectedValues.isNotEmpty;

  bool get _effectiveShowCheckmark =>
      showCheckmark ?? selectionMode == OrionChipSelectionMode.multiple;

  void _handleClear() {
    if (onClear != null) {
      onClear!();
      return;
    }
    onSelectionChanged?.call(<T>{});
  }

  void _handleChipSelected({required T value, required bool nextSelected}) {
    final OrionChipSelectionChanged<T>? callback = onSelectionChanged;
    if (callback == null) {
      return;
    }

    switch (selectionMode) {
      case OrionChipSelectionMode.single:
        if (nextSelected) {
          callback(<T>{value});
        } else if (allowDeselect) {
          callback(<T>{});
        }
      case OrionChipSelectionMode.multiple:
        final Set<T> nextValues = Set<T>.from(selectedValues);
        if (nextSelected) {
          nextValues.add(value);
        } else {
          nextValues.remove(value);
        }
        callback(nextValues);
    }
  }

  List<Widget> _buildChips() {
    final bool checkmark = _effectiveShowCheckmark;
    return items
        .map<Widget>((OrionChipItem<T> item) {
          final bool itemEnabled = _groupEnabled && item.enabled;
          final bool isSelected = selectedValues.contains(item.value);

          return OrionChip(
            text: item.label,
            leading: item.leading,
            trailing: item.trailing,
            semanticLabel: item.semanticLabel,
            selected: isSelected,
            showCheckmark: checkmark,
            size: size,
            style: style,
            onSelected: itemEnabled
                ? (bool nextSelected) => _handleChipSelected(
                    value: item.value,
                    nextSelected: nextSelected,
                  )
                : null,
          );
        })
        .toList(growable: false);
  }

  List<Widget> _chipsWithSpacing() {
    final List<Widget> chips = _buildChips();
    if (chips.isEmpty) {
      return const <Widget>[];
    }
    final List<Widget> spaced = <Widget>[];
    for (int i = 0; i < chips.length; i++) {
      if (i > 0) {
        spaced.add(SizedBox(width: spacing));
      }
      spaced.add(chips[i]);
    }
    return spaced;
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final EdgeInsets resolvedPadding = (padding ?? EdgeInsets.zero).resolve(
      Directionality.of(context),
    );
    final EdgeInsets horizontalInset = EdgeInsets.only(
      left: resolvedPadding.left,
      right: resolvedPadding.right,
    );

    final String? countText = selectedCountLabelBuilder
        ?.call(selectedValues.length)
        ?.trim();
    final bool showCount = countText != null && countText.isNotEmpty;
    final bool showMetaRow = showCount || showClearAction;

    return Padding(
      padding: EdgeInsets.only(
        top: resolvedPadding.top,
        bottom: resolvedPadding.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          if (showMetaRow) ...<Widget>[
            Padding(
              padding: horizontalInset,
              child: Row(
                children: <Widget>[
                  if (showCount)
                    Expanded(
                      child: Text(
                        countText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  if (showClearAction)
                    OrionButton(
                      key: orionChipGroupClearKey,
                      variant: OrionButtonVariant.flat,
                      size: OrionButtonSize.small,
                      label: clearActionLabel,
                      onPressed: _isClearEnabled ? _handleClear : null,
                    ),
                ],
              ),
            ),
            const SizedBox(height: OrionSpacing.space4),
          ],
          switch (layout) {
            OrionChipGroupLayout.horizontal => SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              clipBehavior: clipBehavior,
              padding: horizontalInset,
              child: Row(children: _chipsWithSpacing()),
            ),
            OrionChipGroupLayout.wrap => Padding(
              padding: horizontalInset,
              child: Wrap(
                spacing: spacing,
                runSpacing: runSpacing,
                children: _buildChips(),
              ),
            ),
          },
        ],
      ),
    );
  }
}
