import 'package:flutter/widgets.dart';

/// Represents a single tab descriptor in an [OrionTabs] navigation bar.
@immutable
class OrionTab<T> {
  const OrionTab({
    required this.value,
    required this.label,
    this.icon,
    this.badge,
    this.disabled = false,
  });

  /// The unique value or identifier representing this tab.
  final T value;

  /// Visible text label.
  final String label;

  /// Optional leading icon widget.
  final Widget? icon;

  /// Optional trailing badge widget (e.g., [OrionBadge] or counter count).
  final Widget? badge;

  /// Whether this tab is disabled from interaction.
  final bool disabled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrionTab<T> &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          label == other.label &&
          icon == other.icon &&
          badge == other.badge &&
          disabled == other.disabled;

  @override
  int get hashCode => Object.hash(value, label, icon, badge, disabled);
}
