import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

enum AppToastKind { info, success, error }

class AppToast {
  const AppToast._();

  static void show(
    BuildContext context,
    String message, {
    AppToastKind kind = AppToastKind.info,
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
  }) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    if (messenger == null) return;

    final Color background;
    final IconData icon;
    switch (kind) {
      case AppToastKind.success:
        background = AppColors.success;
        icon = Icons.check_circle_rounded;
      case AppToastKind.error:
        background = AppColors.error;
        icon = Icons.error_outline_rounded;
      case AppToastKind.info:
        background = AppColors.primary;
        icon = Icons.info_outline_rounded;
    }

    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: duration,
        backgroundColor: background,
        behavior: SnackBarBehavior.floating,
        margin: margin,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: action,
        content: Row(
          children: [
            Icon(icon, size: 20, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppTypography.inter(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void info(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
  }) {
    show(context, message, duration: duration, action: action, margin: margin);
  }

  static void success(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
  }) {
    show(
      context,
      message,
      kind: AppToastKind.success,
      duration: duration,
      action: action,
      margin: margin,
    );
  }

  static void error(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
    EdgeInsetsGeometry? margin,
  }) {
    show(
      context,
      message,
      kind: AppToastKind.error,
      duration: duration,
      action: action,
      margin: margin,
    );
  }
}
