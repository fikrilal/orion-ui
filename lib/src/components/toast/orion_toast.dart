import 'dart:async';
import 'package:flutter/widgets.dart';

import 'package:orion_ui/src/components/toast/orion_toast_controller.dart';
import 'package:orion_ui/src/components/toast/orion_toast_data.dart';
import 'package:orion_ui/src/components/toast/orion_toast_style.dart';

/// Ergonomic imperative dispatch API for the toast notification stack.
abstract final class OrionToast {
  /// Shows or updates a toast. Returns the assigned toast id.
  static String show(
    String title, {
    String? description,
    OrionToastStatus status = OrionToastStatus.neutral,
    Widget? icon,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    OrionToastStyle? style,
    String? id,
  }) {
    return OrionToastController.instance.show(
      OrionToastData(
        id: id ?? '',
        title: title,
        description: description,
        status: status,
        icon: icon,
        action: action,
        duration: duration,
        dismissible: dismissible,
        style: style,
      ),
    );
  }

  /// Displays a success toast.
  static String success(
    String title, {
    String? description,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    OrionToastStyle? style,
    String? id,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.success,
      action: action,
      duration: duration,
      dismissible: dismissible,
      style: style,
      id: id,
    );
  }

  /// Displays an error toast.
  static String error(
    String title, {
    String? description,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    OrionToastStyle? style,
    String? id,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.error,
      action: action,
      duration: duration,
      dismissible: dismissible,
      style: style,
      id: id,
    );
  }

  /// Displays an info toast.
  static String info(
    String title, {
    String? description,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    OrionToastStyle? style,
    String? id,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.info,
      action: action,
      duration: duration,
      dismissible: dismissible,
      style: style,
      id: id,
    );
  }

  /// Displays a warning toast.
  static String warning(
    String title, {
    String? description,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    OrionToastStyle? style,
    String? id,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.warning,
      action: action,
      duration: duration,
      dismissible: dismissible,
      style: style,
      id: id,
    );
  }

  /// Displays a persistent loading toast with an activity spinner.
  static String loading(
    String title, {
    String? description,
    OrionToastStyle? style,
    String? id,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.loading,
      duration: Duration.zero, // persistent until updated or dismissed
      dismissible: false,
      style: style,
      id: id,
    );
  }

  /// Tracks a [future], showing a loading spinner then resolving to success or error in place.
  static Future<T> promise<T>(
    Future<T> future, {
    required String loading,
    required String Function(T result) success,
    required String Function(Object error) error,
    OrionToastAction? action,
    OrionToastStyle? style,
  }) async {
    final String toastId = OrionToast.loading(loading, style: style);
    try {
      final T result = await future;
      OrionToast.success(
        success(result),
        action: action,
        style: style,
        id: toastId,
      );
      return result;
    } catch (err) {
      OrionToast.error(error(err), action: action, style: style, id: toastId);
      rethrow;
    }
  }

  /// Dismisses an active toast by [id], or the top toast if [id] is null.
  static void dismiss([String? id]) {
    OrionToastController.instance.dismiss(id);
  }

  /// Clears all active toasts immediately.
  static void clear() {
    OrionToastController.instance.clear();
  }
}
