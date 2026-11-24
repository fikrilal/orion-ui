import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// One selectable row in an [OrionDropdown].
///
/// The option carries its [label] as plain text so the trigger, the row, and
/// the semantics tree all read one string — there is no duplicate visual tree
/// to keep in sync.
@immutable
class OrionDropdownOption<T> {
  const OrionDropdownOption({
    required this.value,
    required this.label,
    this.leading,
    this.trailing,
    this.description,
    this.group,
    this.searchTerms,
    this.enabled = true,
  });

  /// The value committed to the host when this option is selected.
  final T value;

  /// The option's text: the selected label on the trigger and the row title.
  final String label;

  /// Optional leading icon, badge, or avatar shown before the label.
  final Widget? leading;

  /// Optional trailing widget (for example a count, badge, or shortcut hint)
  /// displayed beside the selection indicator.
  final Widget? trailing;

  /// Optional secondary description line under the label.
  final String? description;

  /// Optional section header name. Consecutive options sharing a [group] are
  /// displayed under a single non-selectable group header.
  final String? group;

  /// Optional extra search aliases (for example `['USA', 'US']` on
  /// `'United States'`) matched when `OrionDropdown.searchable` is true.
  final List<String>? searchTerms;

  /// Whether the option can be selected. Disabled rows are skipped by the
  /// keyboard cursor and muted, and a tap on them commits nothing.
  final bool enabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrionDropdownOption<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label &&
          leading == other.leading &&
          trailing == other.trailing &&
          description == other.description &&
          group == other.group &&
          listEquals(searchTerms, other.searchTerms) &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(
    value,
    label,
    leading,
    trailing,
    description,
    group,
    searchTerms == null ? null : Object.hashAll(searchTerms!),
    enabled,
  );
}
