import 'package:flutter/material.dart';

/// Representation of an actionable item inside an [OrionMenu].
@immutable
class OrionMenuItem {
  const OrionMenuItem({
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.value,
    this.onTap,
    this.destructive = false,
    this.enabled = true,
  }) : isDivider = false;

  const OrionMenuItem.divider()
    : title = '',
      subtitle = null,
      leading = null,
      trailing = null,
      value = null,
      onTap = null,
      destructive = false,
      enabled = false,
      isDivider = true;

  /// Primary label text.
  final String title;

  /// Optional secondary description line.
  final String? subtitle;

  /// Optional leading icon or avatar widget.
  final Widget? leading;

  /// Optional trailing badge, chevron, or keyboard shortcut label.
  final Widget? trailing;

  /// Optional typed value associated with this menu item, returned by [showOrionMenu].
  final dynamic value;

  /// Selection callback. If null, the item behaves as non-interactive.
  final VoidCallback? onTap;

  /// Whether this item represents a destructive action (renders in error danger tint).
  final bool destructive;

  /// Whether the item responds to pointer taps.
  final bool enabled;

  /// Whether this item represents a visual hairline separator.
  final bool isDivider;
}
