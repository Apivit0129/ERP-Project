import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// ERP Status Badge — inventory / order status chip
enum ErpStatus {
  inStock,
  lowStock,
  outOfStock,
  pending,
  completed,
  cancelled,
  active,
  inactive,
}

class ErpStatusBadge extends StatelessWidget {
  final ErpStatus status;
  final String? customLabel;
  final double fontSize;

  const ErpStatusBadge({
    super.key,
    required this.status,
    this.customLabel,
    this.fontSize = 11,
  });

  /// Create from string — convenience factory for API data
  factory ErpStatusBadge.fromString(String value, {double fontSize = 11}) {
    final s = value.toUpperCase().replaceAll(' ', '_');
    ErpStatus status;
    switch (s) {
      case 'IN_STOCK':
      case 'INSTOCK':
        status = ErpStatus.inStock;
        break;
      case 'LOW_STOCK':
      case 'LOWSTOCK':
      case 'LOW':
        status = ErpStatus.lowStock;
        break;
      case 'OUT_OF_STOCK':
      case 'OUTOFSTOCK':
      case 'OUT':
        status = ErpStatus.outOfStock;
        break;
      case 'PENDING':
        status = ErpStatus.pending;
        break;
      case 'COMPLETED':
      case 'RECEIVED':
        status = ErpStatus.completed;
        break;
      case 'CANCELLED':
      case 'CANCELED':
        status = ErpStatus.cancelled;
        break;
      case 'ACTIVE':
        status = ErpStatus.active;
        break;
      default:
        status = ErpStatus.inactive;
    }
    return ErpStatusBadge(
      status: status,
      customLabel: _getLabel(status),
      fontSize: fontSize,
    );
  }

  static String _getLabel(ErpStatus s) {
    switch (s) {
      case ErpStatus.inStock:
        return 'ปกติ';
      case ErpStatus.lowStock:
        return 'ใกล้หมด';
      case ErpStatus.outOfStock:
        return 'หมดสต๊อก';
      case ErpStatus.pending:
        return 'รอดำเนินการ';
      case ErpStatus.completed:
        return 'เสร็จสิ้น';
      case ErpStatus.cancelled:
        return 'ยกเลิก';
      case ErpStatus.active:
        return 'ใช้งาน';
      case ErpStatus.inactive:
        return 'ไม่ใช้งาน';
    }
  }

  @override
  Widget build(BuildContext context) {
    final (color, bg, icon) = _resolve();
    final label = customLabel ?? _getLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withAlpha(60), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color, IconData) _resolve() {
    switch (status) {
      case ErpStatus.inStock:
      case ErpStatus.active:
      case ErpStatus.completed:
        return (
          AppColors.success,
          AppColors.success.withAlpha(18),
          Icons.check_circle_outline,
        );
      case ErpStatus.lowStock:
      case ErpStatus.pending:
        return (
          AppColors.warning,
          AppColors.warning.withAlpha(18),
          Icons.warning_amber_outlined,
        );
      case ErpStatus.outOfStock:
      case ErpStatus.cancelled:
      case ErpStatus.inactive:
        return (
          AppColors.destructive,
          AppColors.destructive.withAlpha(18),
          Icons.cancel_outlined,
        );
    }
  }
}
