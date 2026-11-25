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
    bool? showCloseButton,
    bool? showProgressBar,
    VoidCallback? onTap,
    ValueChanged<OrionToastDismissReason>? onDismissed,
    OrionToastStyle? style,
    String? id,
    OrionToastController? controller,
  }) {
    return (controller ?? OrionToastController.instance).show(
      OrionToastData(
        id: id ?? '',
        title: title,
        description: description,
        status: status,
        icon: icon,
        action: action,
        duration: duration,
        dismissible: dismissible,
        showCloseButton: showCloseButton,
        showProgressBar: showProgressBar,
        onTap: onTap,
        onDismissed: onDismissed,
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
    bool? showCloseButton,
    bool? showProgressBar,
    VoidCallback? onTap,
    ValueChanged<OrionToastDismissReason>? onDismissed,
    OrionToastStyle? style,
    String? id,
    OrionToastController? controller,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.success,
      action: action,
      duration: duration,
      dismissible: dismissible,
      showCloseButton: showCloseButton,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      style: style,
      id: id,
      controller: controller,
    );
  }

  /// Displays an error toast.
  static String error(
    String title, {
    String? description,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    bool? showCloseButton,
    bool? showProgressBar,
    VoidCallback? onTap,
    ValueChanged<OrionToastDismissReason>? onDismissed,
    OrionToastStyle? style,
    String? id,
    OrionToastController? controller,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.error,
      action: action,
      duration: duration,
      dismissible: dismissible,
      showCloseButton: showCloseButton,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      style: style,
      id: id,
      controller: controller,
    );
  }

  /// Displays an info toast.
  static String info(
    String title, {
    String? description,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    bool? showCloseButton,
    bool? showProgressBar,
    VoidCallback? onTap,
    ValueChanged<OrionToastDismissReason>? onDismissed,
    OrionToastStyle? style,
    String? id,
    OrionToastController? controller,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.info,
      action: action,
      duration: duration,
      dismissible: dismissible,
      showCloseButton: showCloseButton,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      style: style,
      id: id,
      controller: controller,
    );
  }

  /// Displays a warning toast.
  static String warning(
    String title, {
    String? description,
    OrionToastAction? action,
    Duration? duration = const Duration(milliseconds: 4000),
    bool dismissible = true,
    bool? showCloseButton,
    bool? showProgressBar,
    VoidCallback? onTap,
    ValueChanged<OrionToastDismissReason>? onDismissed,
    OrionToastStyle? style,
    String? id,
    OrionToastController? controller,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.warning,
      action: action,
      duration: duration,
      dismissible: dismissible,
      showCloseButton: showCloseButton,
      showProgressBar: showProgressBar,
      onTap: onTap,
      onDismissed: onDismissed,
      style: style,
      id: id,
      controller: controller,
    );
  }

  /// Displays a persistent loading toast with an activity spinner.
  static String loading(
    String title, {
    String? description,
    bool dismissible = false,
    bool? showCloseButton,
    VoidCallback? onTap,
    ValueChanged<OrionToastDismissReason>? onDismissed,
    OrionToastStyle? style,
    String? id,
    OrionToastController? controller,
  }) {
    return show(
      title,
      description: description,
      status: OrionToastStatus.loading,
      duration: Duration.zero,
      dismissible: dismissible,
      showCloseButton: showCloseButton,
      showProgressBar: false,
      onTap: onTap,
      onDismissed: onDismissed,
      style: style,
      id: id,
      controller: controller,
    );
  }

  /// Tracks a [future], showing a loading spinner then morphing in place into
  /// a success or error toast once settled.
  static Future<T> promise<T>(
    Future<T> future, {
    required String loading,
    String? loadingDescription,
    required String Function(T result) success,
    String? Function(T result)? successDescription,
    required String Function(Object error) error,
    String? Function(Object error)? errorDescription,
    OrionToastAction? action,
    OrionToastAction? successAction,
    OrionToastAction? errorAction,
    Duration? duration = const Duration(milliseconds: 4000),
    bool? showCloseButton,
    bool? showProgressBar,
    OrionToastStyle? style,
    OrionToastController? controller,
  }) async {
    final String toastId = OrionToast.loading(
      loading,
      description: loadingDescription,
      style: style,
      controller: controller,
    );
    try {
      final T result = await future;
      OrionToast.success(
        success(result),
        description: successDescription?.call(result),
        action: successAction ?? action,
        duration: duration,
        showCloseButton: showCloseButton,
        showProgressBar: showProgressBar,
        style: style,
        id: toastId,
        controller: controller,
      );
      return result;
    } catch (err) {
      OrionToast.error(
        error(err),
        description: errorDescription?.call(err),
        action: errorAction,
        duration: duration,
        showCloseButton: showCloseButton,
        showProgressBar: showProgressBar,
        style: style,
        id: toastId,
        controller: controller,
      );
      rethrow;
    }
  }

  /// Dismisses an active toast by [id], or the frontmost toast if [id] is null.
  static void dismiss([String? id, OrionToastController? controller]) {
    (controller ?? OrionToastController.instance).dismiss(id);
  }

  /// Clears all active toasts immediately.
  static void clear({OrionToastController? controller}) {
    (controller ?? OrionToastController.instance).clear();
  }
}
