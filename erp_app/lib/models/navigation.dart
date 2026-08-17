import 'package:flutter/material.dart';

/// Navigation model for routing and menu state
enum AppRoute {
  warehouse, // 📦 คลังสินค้า
  pos, // 🛒 จุดขาย POS
  purchase, // 📄 จัดซื้อ PO
  dashboard, // 📊 แดชบอร์ด
}

extension AppRouteExt on AppRoute {
  String get label {
    switch (this) {
      case AppRoute.warehouse:
        return '📦 คลังสินค้า';
      case AppRoute.pos:
        return '🛒 จุดขาย POS';
      case AppRoute.purchase:
        return '📄 จัดซื้อ PO';
      case AppRoute.dashboard:
        return '📊 แดชบอร์ด';
    }
  }

  String get tooltip {
    switch (this) {
      case AppRoute.warehouse:
        return 'คลังสินค้า';
      case AppRoute.pos:
        return 'เปิดบิลขาย';
      case AppRoute.purchase:
        return 'รับสินค้าเข้า';
      case AppRoute.dashboard:
        return 'รายงานแดชบอร์ด';
    }
  }

  IconData get icon {
    switch (this) {
      case AppRoute.warehouse:
        return Icons.inventory_2_outlined;
      case AppRoute.pos:
        return Icons.point_of_sale_outlined;
      case AppRoute.purchase:
        return Icons.local_shipping_outlined;
      case AppRoute.dashboard:
        return Icons.bar_chart_outlined;
    }
  }

  IconData get activeIcon {
    switch (this) {
      case AppRoute.warehouse:
        return Icons.inventory_2;
      case AppRoute.pos:
        return Icons.point_of_sale;
      case AppRoute.purchase:
        return Icons.local_shipping;
      case AppRoute.dashboard:
        return Icons.bar_chart;
    }
  }
}
