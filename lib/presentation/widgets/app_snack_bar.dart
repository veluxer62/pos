import 'package:flutter/material.dart';
import 'package:pos/presentation/theme/app_colors.dart';
import 'package:pos/presentation/theme/app_spacing.dart';

enum SnackBarType { success, error, warning, info }

abstract final class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    SnackBarType type = SnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (backgroundColor, icon) = switch (type) {
      SnackBarType.success => (AppColors.success, Icons.check_circle_outline),
      SnackBarType.error => (AppColors.error, Icons.error_outline),
      SnackBarType.warning => (AppColors.warning, Icons.warning_amber_outlined),
      SnackBarType.info => (AppColors.info, Icons.info_outline),
    };

    ScaffoldMessenger.of(context)
      ..clearSnackBars()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(icon, color: Colors.white, size: AppSpacing.iconMd),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
          backgroundColor: backgroundColor,
          duration: duration,
          action: (actionLabel != null && onAction != null)
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction,
                )
              : null,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(AppSpacing.lg),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.success);

  static void error(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.error);

  static void warning(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.warning);

  static void info(BuildContext context, String message) =>
      show(context, message: message, type: SnackBarType.info);
}
