import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

/// ============================================================
/// ⭐ Elegant Notification Service - Toastification-based
///
/// Provides beautiful, animated toast notifications with:
/// - Smooth slide-down animations from top
/// - Customizable icons and colors
/// - Auto-dismiss with optional action buttons
/// - Queue management for multiple notifications
///
/// Usage:
///   ElegantNotificationService.success(context,
///     title: 'สำเร็จ!',
///     description: 'บันทึกข้อมูลเรียบร้อยแล้ว'
///   );
///
///   ElegantNotificationService.error(context,
///     title: 'เกิดข้อผิดพลาด',
///     description: 'กรุณาลองใหม่'
///   );
/// ============================================================

class ElegantNotificationService {
  static const _defaultDuration = Duration(seconds: 5);
  static const _animationDuration = Duration(milliseconds: 600);

  /// Show success notification (Green 🟢)
  static void success(
    BuildContext context, {
    required String title,
    required String description,
    Duration autoCloseDuration = _defaultDuration,
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      title: title,
      description: description,
      type: ToastificationType.success,
      icon: Icons.check_circle_rounded,
      backgroundColor: Colors.green.shade50,
      borderColor: Colors.green.shade300,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  /// Show error notification (Red 🔴)
  static void error(
    BuildContext context, {
    required String title,
    required String description,
    Duration autoCloseDuration = _defaultDuration,
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      title: title,
      description: description,
      type: ToastificationType.error,
      icon: Icons.error_rounded,
      backgroundColor: Colors.red.shade50,
      borderColor: Colors.red.shade300,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  /// Show warning notification (Amber/Orange 🟠)
  static void warning(
    BuildContext context, {
    required String title,
    required String description,
    Duration autoCloseDuration = _defaultDuration,
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      title: title,
      description: description,
      type: ToastificationType.warning,
      icon: Icons.warning_amber_rounded,
      backgroundColor: Colors.amber.shade50,
      borderColor: Colors.amber.shade300,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  /// Show info notification (Blue 🔵)
  static void info(
    BuildContext context, {
    required String title,
    required String description,
    Duration autoCloseDuration = _defaultDuration,
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      title: title,
      description: description,
      type: ToastificationType.info,
      icon: Icons.info_rounded,
      backgroundColor: Colors.blue.shade50,
      borderColor: Colors.blue.shade300,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  /// Show custom notification with full control
  static void custom(
    BuildContext context, {
    required String title,
    required String description,
    required ToastificationType type,
    IconData? icon,
    Duration autoCloseDuration = _defaultDuration,
    Color? backgroundColor,
    Color? borderColor,
    Color? textColor,
    VoidCallback? onTap,
  }) {
    _showNotification(
      context,
      title: title,
      description: description,
      type: type,
      icon: icon,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      textColor: textColor,
      autoCloseDuration: autoCloseDuration,
      onTap: onTap,
    );
  }

  /// Internal method to show notification
  static void _showNotification(
    BuildContext context, {
    required String title,
    required String description,
    required ToastificationType type,
    IconData? icon,
    Color? backgroundColor,
    Color? borderColor,
    Color? textColor,
    Duration autoCloseDuration = _defaultDuration,
    VoidCallback? onTap,
  }) {
    // Determine colors based on type
    final colors = _getColorsForType(type);

    toastification.show(
      context: context,
      type: type,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: autoCloseDuration,
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: textColor ?? colors.textColor,
        ),
      ),
      description: Text(
        description,
        style: TextStyle(
          fontSize: 12,
          color: textColor ?? colors.descriptionColor,
        ),
      ),
      icon: Icon(icon ?? colors.icon, color: colors.iconColor),
      primaryColor: colors.iconColor,
      backgroundColor: backgroundColor ?? colors.bgColor,
      borderRadius: BorderRadius.circular(16),
      showProgressBar: true,
      closeOnClick: true,
      pauseOnHover: true,
      dragToClose: true,
      animationDuration: _animationDuration,
      alignment: Alignment.topRight,
      direction: TextDirection.ltr,
    );
  }

  /// Helper to get colors based on notification type
  static _NotificationColors _getColorsForType(ToastificationType type) {
    switch (type) {
      case ToastificationType.success:
        return _NotificationColors(
          bgColor: Colors.green.shade50,
          textColor: Colors.green.shade900,
          descriptionColor: Colors.green.shade700,
          iconColor: Colors.green.shade600,
          iconBgColor: Colors.green.shade100,
          shadowColor: Colors.green,
          icon: Icons.check_circle_rounded,
        );
      case ToastificationType.error:
        return _NotificationColors(
          bgColor: Colors.red.shade50,
          textColor: Colors.red.shade900,
          descriptionColor: Colors.red.shade700,
          iconColor: Colors.red.shade600,
          iconBgColor: Colors.red.shade100,
          shadowColor: Colors.red,
          icon: Icons.error_rounded,
        );
      case ToastificationType.warning:
        return _NotificationColors(
          bgColor: Colors.amber.shade50,
          textColor: Colors.amber.shade900,
          descriptionColor: Colors.amber.shade700,
          iconColor: Colors.amber.shade600,
          iconBgColor: Colors.amber.shade100,
          shadowColor: Colors.amber,
          icon: Icons.warning_amber_rounded,
        );
      case ToastificationType.info:
        return _NotificationColors(
          bgColor: Colors.blue.shade50,
          textColor: Colors.blue.shade900,
          descriptionColor: Colors.blue.shade700,
          iconColor: Colors.blue.shade600,
          iconBgColor: Colors.blue.shade100,
          shadowColor: Colors.blue,
          icon: Icons.info_rounded,
        );
    }
  }
}

/// Helper class to store notification color scheme
class _NotificationColors {
  final Color bgColor;
  final Color textColor;
  final Color descriptionColor;
  final Color iconColor;
  final Color iconBgColor;
  final Color shadowColor;
  final IconData icon;

  _NotificationColors({
    required this.bgColor,
    required this.textColor,
    required this.descriptionColor,
    required this.iconColor,
    required this.iconBgColor,
    required this.shadowColor,
    required this.icon,
  });
}
