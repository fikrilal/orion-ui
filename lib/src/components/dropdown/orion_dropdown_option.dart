import 'package:flutter/widgets.dart';

/// One selectable row in an [OrionDropdown].
///
/// The option carries its [label] as plain text so the trigger, the row, and the
/// semantics tree all read one string - there is no duplicate visual tree to
/// keep in sync.
@immutable
class OrionDropdownOption<T> {
  const OrionDropdownOption({
    required this.value,
    required this.label,
    this.leading,
    this.description,
    this.enabled = true,
  });

  /// The value committed to the host when this option is selected.
  final T value;

  /// The option's text: the selected label on the trigger and the row title.
  final String label;

  /// Optional leading icon or avatar shown before the label.
  final Widget? leading;

  /// Optional secondary description line under the label.
  final String? description;

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
          description == other.description &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(value, label, leading, description, enabled);
}
