import 'package:flutter/material.dart';
import '../models/navigation.dart' as nav;

class NavigationProvider with ChangeNotifier {
  nav.AppRoute _currentDestination = nav.AppRoute.warehouse;

  nav.AppRoute get currentDestination => _currentDestination;

  void setDestination(nav.AppRoute destination) {
    if (_currentDestination != destination) {
      _currentDestination = destination;
      notifyListeners();
    }
  }

  /// ตรวจสอบว่าบทบาทนี้สามารถเข้าถึงเมนูได้หรือไม่
  /// - WAREHOUSE_STAFF: warehouse, pos (ไม่มี dashboard, purchase)
  /// - MANAGER: warehouse, pos, purchase (ไม่มี dashboard)
  /// - ADMIN: ทั้งหมด
  bool canAccess(nav.AppRoute destination, String? userRole) {
    if (userRole == 'ADMIN') return true;

    switch (destination) {
      case nav.AppRoute.warehouse:
        return true; // ทั้งหมดมีสิทธิ์
      case nav.AppRoute.pos:
        return userRole != null; // WAREHOUSE_STAFF, MANAGER, ADMIN
      case nav.AppRoute.purchase:
        return userRole == 'MANAGER' || userRole == 'ADMIN';
      case nav.AppRoute.dashboard:
        return userRole == 'ADMIN';
    }
  }

  /// ดึงเมนูที่เข้าถึงได้ตามบทบาท
  List<nav.AppRoute> getAccessibleMenus(String? userRole) {
    return nav.AppRoute.values
        .where((dest) => canAccess(dest, userRole))
        .toList();
  }
}
