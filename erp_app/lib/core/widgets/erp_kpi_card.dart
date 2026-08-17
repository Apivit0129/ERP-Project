import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_theme.dart';

/// ERP KPI Card — reusable KPI metric card
/// ใช้กับ Dashboard สำหรับแสดง Revenue, Orders, Stock summary ฯลฯ
class ErpKpiCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color? iconColor;
  final Color? iconBackground;
  final Widget? trend; // e.g. TrendBadge
  final VoidCallback? onTap;
  final bool isLoading;

  const ErpKpiCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.iconColor,
    this.iconBackground,
    this.trend,
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppTheme.cardBorderRadius,
        child: Container(
          padding: AppSpacing.cardPaddingDense,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppTheme.cardBorderRadius,
            border: Border.all(color: AppColors.cardBorder, width: 1),
            boxShadow: AppShadows.cardShadow,
          ),
          child: isLoading ? _buildSkeleton() : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    final effectiveIconBg =
        iconBackground ?? AppColors.primary.withAlpha(20);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            // Icon badge
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: effectiveIconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: effectiveIconColor, size: 18),
            ),
            const Spacer(),
            ?trend,
          ],
        ),
        AppSpacing.gapMD,
        // Value (KPI number — Fira Code)
        Text(value, style: AppTextStyles.kpiLarge),
        const SizedBox(height: 2),
        // Title
        Text(
          title,
          style: AppTextStyles.labelSmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.bodySmall.copyWith(fontSize: 11),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  Widget _buildSkeleton() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            _SkeletonBox(width: 36, height: 36, radius: 8),
            const Spacer(),
            _SkeletonBox(width: 48, height: 18, radius: 9),
          ],
        ),
        AppSpacing.gapMD,
        _SkeletonBox(width: 100, height: 28, radius: 4),
        const SizedBox(height: 6),
        _SkeletonBox(width: 80, height: 14, radius: 4),
      ],
    );
  }
}

class _SkeletonBox extends StatelessWidget {
  final double width, height, radius;
  const _SkeletonBox(
      {required this.width, required this.height, required this.radius});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.muted,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Trend badge — shows +/- percentage
class ErpTrendBadge extends StatelessWidget {
  final double percent;
  final String? label;

  const ErpTrendBadge({super.key, required this.percent, this.label});

  @override
  Widget build(BuildContext context) {
    final isPositive = percent >= 0;
    final color = isPositive ? AppColors.success : AppColors.destructive;
    final bg = isPositive
        ? AppColors.success.withAlpha(18)
        : AppColors.destructive.withAlpha(18);
    final icon = isPositive ? Icons.trending_up : Icons.trending_down;
    final sign = isPositive ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 12),
          const SizedBox(width: 2),
          Text(
            '$sign${percent.toStringAsFixed(1)}%',
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (label != null) ...[
            const SizedBox(width: 2),
            Text(
              label!,
              style: AppTextStyles.labelSmall.copyWith(color: color),
            ),
          ],
        ],
      ),
    );
  }
}
