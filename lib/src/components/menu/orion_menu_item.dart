import 'package:flutter/material.dart';

/// Representation of an item, section header, or divider inside an [OrionMenu].
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
    this.selected = false,
    this.closeOnTap = true,
  }) : isDivider = false,
       isHeader = false;

  /// Creates a visual hairline divider separating menu groups.
  const OrionMenuItem.divider()
    : title = '',
      subtitle = null,
      leading = null,
      trailing = null,
      value = null,
      onTap = null,
      destructive = false,
      enabled = false,
      selected = false,
      closeOnTap = true,
      isDivider = true,
      isHeader = false;

  /// Creates a non-interactive section header label inside a menu.
  const OrionMenuItem.header(this.title)
    : subtitle = null,
      leading = null,
      trailing = null,
      value = null,
      onTap = null,
      destructive = false,
      enabled = false,
      selected = false,
      closeOnTap = true,
      isDivider = false,
      isHeader = true;

  /// Primary label text (or section title for [OrionMenuItem.header]).
  final String title;

  /// Optional secondary description line.
  final String? subtitle;

  /// Optional leading icon or avatar widget.
  final Widget? leading;

  /// Optional trailing badge, chevron, or keyboard shortcut label.
  final Widget? trailing;

  /// Optional typed value associated with this menu item, returned by [showOrionMenu].
  final dynamic value;

  /// Optional selection callback invoked when the item is activated.
  final VoidCallback? onTap;

  /// Whether this item represents a destructive action (renders in error danger tint).
  final bool destructive;

  /// Whether the item responds to taps and keyboard activation.
  final bool enabled;

  /// Whether this item shows a selected checkmark state.
  final bool selected;

  /// Whether tapping this item dismisses the enclosing menu. Defaults to `true`.
  final bool closeOnTap;

  /// Whether this item represents a visual hairline separator.
  final bool isDivider;

  /// Whether this item represents a non-interactive section header.
  final bool isHeader;

  /// Whether this item can be focused/activated by pointer or keyboard.
  bool get isInteractive => !isDivider && !isHeader && enabled;
}
