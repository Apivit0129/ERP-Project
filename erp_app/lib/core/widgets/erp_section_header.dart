import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_theme.dart';

/// ERP Section Header — consistent section title across all screens
class ErpSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action; // e.g. TextButton or ElevatedButton
  final IconData? icon;
  final EdgeInsets padding;

  const ErpSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.icon,
    this.padding = const EdgeInsets.only(
      left: AppSpacing.base,
      right: AppSpacing.base,
      top: AppSpacing.xl,
      bottom: AppSpacing.sm,
    ),
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: AppColors.primary.withAlpha(18),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Icon(icon, color: AppColors.primary, size: 16),
            ),
            AppSpacing.w(10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title, style: AppTextStyles.headingMedium),
                if (subtitle != null)
                  Text(subtitle!, style: AppTextStyles.bodySmall),
              ],
            ),
          ),
          ?action,
        ],
      ),
    );
  }
}

/// ERP Empty State — shown when lists are empty
class ErpEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;

  const ErpEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(icon, color: AppColors.mutedForeground, size: 32),
            ),
            AppSpacing.gapLG,
            Text(title, style: AppTextStyles.headingSmall),
            if (subtitle != null) ...[
              AppSpacing.gapSM,
              Text(
                subtitle!,
                style: AppTextStyles.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
            if (action != null) ...[AppSpacing.gapLG, action!],
          ],
        ),
      ),
    );
  }
}

/// ERP Error State
class ErpErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErpErrorState({super.key, required this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.destructive.withAlpha(18),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Icon(Icons.error_outline,
                  color: AppColors.destructive, size: 30),
            ),
            AppSpacing.gapLG,
            Text('เกิดข้อผิดพลาด',
                style: AppTextStyles.headingSmall
                    .copyWith(color: AppColors.destructive)),
            AppSpacing.gapSM,
            Text(
              message,
              style: AppTextStyles.bodySmall,
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              AppSpacing.gapLG,
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
