import 'package:flutter/material.dart';

/// Role and appearance variant for an [OrionDialogAction].
enum OrionDialogActionVariant {
  /// Primary elevated or solid action (e.g. "Save", "Submit").
  primary,

  /// Secondary neutral action (e.g. "Learn More").
  secondary,

  /// Destructive action tinted with error role (e.g. "Delete", "Disconnect").
  destructive,

  /// Flat or quiet cancel action.
  cancel,
}

/// A structured action button configuration for an [OrionDialog].
@immutable
class OrionDialogAction {
  const OrionDialogAction({
    required this.label,
    required this.onPressed,
    this.variant = OrionDialogActionVariant.primary,
    this.leading,
    this.isLoading = false,
    this.enabled = true,
  });

  /// The text displayed inside the button.
  final String label;

  /// Callback executed when the button is tapped. If null, the button is disabled.
  final VoidCallback? onPressed;

  /// Visual and semantic role of this action.
  final OrionDialogActionVariant variant;

  /// Optional leading icon or widget.
  final Widget? leading;

  /// Whether the button is displaying an in-flight loading spinner.
  final bool isLoading;

  /// Whether the action is interactable.
  final bool enabled;

  /// Convenience factory for a standard primary confirmation action.
  factory OrionDialogAction.primary({
    required String label,
    required VoidCallback? onPressed,
    Widget? leading,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return OrionDialogAction(
      label: label,
      onPressed: onPressed,
      variant: OrionDialogActionVariant.primary,
      leading: leading,
      isLoading: isLoading,
      enabled: enabled,
    );
  }

  /// Convenience factory for a secondary action.
  factory OrionDialogAction.secondary({
    required String label,
    required VoidCallback? onPressed,
    Widget? leading,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return OrionDialogAction(
      label: label,
      onPressed: onPressed,
      variant: OrionDialogActionVariant.secondary,
      leading: leading,
      isLoading: isLoading,
      enabled: enabled,
    );
  }

  /// Convenience factory for a destructive action.
  factory OrionDialogAction.destructive({
    required String label,
    required VoidCallback? onPressed,
    Widget? leading,
    bool isLoading = false,
    bool enabled = true,
  }) {
    return OrionDialogAction(
      label: label,
      onPressed: onPressed,
      variant: OrionDialogActionVariant.destructive,
      leading: leading,
      isLoading: isLoading,
      enabled: enabled,
    );
  }

  /// Convenience factory for a standard dismissive cancel action.
  factory OrionDialogAction.cancel({
    String label = 'Cancel',
    VoidCallback? onPressed,
    Widget? leading,
    bool enabled = true,
  }) {
    return OrionDialogAction(
      label: label,
      onPressed: onPressed,
      variant: OrionDialogActionVariant.cancel,
      leading: leading,
      enabled: enabled,
    );
  }
}
