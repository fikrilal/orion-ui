import 'package:flutter/widgets.dart';

import 'package:orion_ui/src/components/toast/orion_toast_style.dart';

/// Semantic status of an [OrionToastData].
enum OrionToastStatus { neutral, info, success, warning, error, loading }

/// Placement position for the toast stack.
enum OrionToastPosition { topCenter, bottomCenter }

/// An interactive action button displayed on a toast.
@immutable
class OrionToastAction {
  const OrionToastAction({required this.label, required this.onPressed});

  /// The button label.
  final String label;

  /// Invoked when the action button is pressed.
  final VoidCallback onPressed;
}

/// Immutable data payload representing a single toast.
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

  /// Optional action button.
  final OrionToastAction? action;

  /// Auto-dismiss duration. Pass null or [Duration.zero] to persist until dismissed.
  final Duration? duration;

  /// Whether the user can swipe or tap to dismiss this toast.
  final bool dismissible;

  /// Instance-level style overrides.
  final OrionToastStyle? style;

  /// Returns a copy of this toast with the provided fields replaced.
  ///
  /// A field left out keeps its current value, so a null argument cannot clear
  /// [description], [icon], [action], [duration] or [style]. Build a fresh
  /// payload to drop one - which is what the `OrionToast` facade does on every
  /// call, so an in-place update never carries stale content forward.
  OrionToastData copyWith({
    String? id,
    String? title,
    String? description,
    OrionToastStatus? status,
    Widget? icon,
    OrionToastAction? action,
    Duration? duration,
    bool? dismissible,
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
        other.duration == duration &&
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
    duration,
    style,
  );
}
