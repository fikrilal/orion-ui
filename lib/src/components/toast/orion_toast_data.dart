import 'package:flutter/widgets.dart';

import 'package:orion_ui/src/components/toast/orion_toast_style.dart';

/// Semantic status of an [OrionToastData].
enum OrionToastStatus { neutral, info, success, warning, error, loading }

/// Screen anchor placement for an `OrionToaster` stack.
enum OrionToastPosition {
  topLeft,
  topCenter,
  topRight,
  bottomLeft,
  bottomCenter,
  bottomRight;

  /// Whether this placement anchors to the top edge of the viewport.
  bool get isTop =>
      this == OrionToastPosition.topLeft ||
      this == OrionToastPosition.topCenter ||
      this == OrionToastPosition.topRight;

  /// Corresponding [Alignment] inside the viewport.
  Alignment get alignment => switch (this) {
    OrionToastPosition.topLeft => Alignment.topLeft,
    OrionToastPosition.topCenter => Alignment.topCenter,
    OrionToastPosition.topRight => Alignment.topRight,
    OrionToastPosition.bottomLeft => Alignment.bottomLeft,
    OrionToastPosition.bottomCenter => Alignment.bottomCenter,
    OrionToastPosition.bottomRight => Alignment.bottomRight,
  };
}

/// Why a toast was dismissed from the stack.
enum OrionToastDismissReason {
  /// Auto-dismiss timer expired.
  timeout,

  /// Dismissed by horizontal or anchor-edge vertical swipe gesture.
  swiped,

  /// Dismissed by tapping the close button.
  closeButton,

  /// Dismissed by invoking an [OrionToastAction] with `dismissOnPress: true`.
  action,

  /// Dismissed imperatively via `OrionToast.dismiss(...)` or controller API.
  programmatic,

  /// Removed via `OrionToast.clear()` or `controller.clear()`.
  cleared,
}

/// An interactive action button displayed on a toast.
@immutable
class OrionToastAction {
  const OrionToastAction({
    required this.label,
    required this.onPressed,
    this.dismissOnPress = true,
  });

  /// The button label.
  final String label;

  /// Invoked when the action button is pressed.
  final VoidCallback onPressed;

  /// Whether pressing the action button automatically dismisses the toast.
  /// Set `false` when the action updates the toast in place.
  final bool dismissOnPress;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionToastAction &&
        other.label == label &&
        other.onPressed == onPressed &&
        other.dismissOnPress == dismissOnPress;
  }

  @override
  int get hashCode => Object.hash(label, onPressed, dismissOnPress);
}

/// Immutable data payload representing a single toast notification.
@immutable
class OrionToastData {
  const OrionToastData({
    required this.id,
    required this.title,
    this.description,
    this.status = OrionToastStatus.neutral,
    this.icon,
    this.action,
    this.duration = const Duration(milliseconds: 4000),
    this.dismissible = true,
    this.showCloseButton,
    this.showProgressBar,
    this.onTap,
    this.onDismissed,
    this.style,
  });

  /// Unique identifier of this toast.
  final String id;

  /// Primary title message.
  final String title;

  /// Optional secondary descriptive text.
  final String? description;

  /// Semantic visual role.
  final OrionToastStatus status;

  /// Custom icon widget overriding the status default.
  final Widget? icon;

  /// Optional interactive action button.
  final OrionToastAction? action;

  /// Auto-dismiss duration. Pass null or [Duration.zero] to persist until
  /// dismissed manually or updated.
  final Duration? duration;

  /// Whether the user can swipe to dismiss this toast.
  final bool dismissible;

  /// Whether to show the inline close (`×`) button. When null, inherits
  /// `OrionToaster.showCloseButtons` (and hides automatically when
  /// [dismissible] is false).
  final bool? showCloseButton;

  /// Whether to show a subtle auto-dismiss countdown progress bar along the
  /// bottom edge of the card. When null, inherits `OrionToaster.showProgressBar`.
  final bool? showProgressBar;

  /// Optional callback invoked when the user taps the toast body.
  final VoidCallback? onTap;

  /// Optional callback invoked once when the toast is dismissed from the queue,
  /// reporting why it left ([OrionToastDismissReason]).
  final ValueChanged<OrionToastDismissReason>? onDismissed;

  /// Instance-level style overrides.
  final OrionToastStyle? style;

  /// Returns a copy of this toast with the provided fields replaced.
  OrionToastData copyWith({
    String? id,
    String? title,
    String? description,
    OrionToastStatus? status,
    Widget? icon,
    OrionToastAction? action,
    Duration? duration,
    bool? dismissible,
    bool? showCloseButton,
    bool? showProgressBar,
    VoidCallback? onTap,
    ValueChanged<OrionToastDismissReason>? onDismissed,
    OrionToastStyle? style,
  }) {
    return OrionToastData(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      icon: icon ?? this.icon,
      action: action ?? this.action,
      duration: duration ?? this.duration,
      dismissible: dismissible ?? this.dismissible,
      showCloseButton: showCloseButton ?? this.showCloseButton,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      onTap: onTap ?? this.onTap,
      onDismissed: onDismissed ?? this.onDismissed,
      style: style ?? this.style,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is OrionToastData &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.status == status &&
        other.icon == icon &&
        other.action == action &&
        other.dismissible == dismissible &&
        other.showCloseButton == showCloseButton &&
        other.showProgressBar == showProgressBar &&
        other.duration == duration &&
        other.onTap == onTap &&
        other.onDismissed == onDismissed &&
        other.style == style;
  }

  @override
  int get hashCode => Object.hash(
    id,
    title,
    description,
    status,
    icon,
    action,
    dismissible,
    showCloseButton,
    showProgressBar,
    duration,
    onTap,
    onDismissed,
    style,
  );
}
