import 'package:flutter/material.dart';
import 'api_service.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoggedIn = false;
  String? _username;
  String? _role;

  bool get isLoggedIn => _isLoggedIn;
  String? get username => _username;
  String? get role => _role;

  // เช็คสิทธิ์เพื่อใช้ซ่อน/แสดงปุ่ม (RBAC Helpers)
  bool get isManagerOrAdmin => _role == 'MANAGER' || _role == 'ADMIN';

  // เมื่อเปิดแอปมา เช็คก่อนว่าเคยล็อกอินค้างไว้ไหม?
  Future<void> checkLoginStatus() async {
    _role = await _apiService.getUserRole();
    _username = await _apiService.getUsername();
    _isLoggedIn = (_role != null && _username != null);
    notifyListeners(); // แจ้งเตือนแอปให้ปรับหน้าจอ
  }

  // สั่งสมัครสมาชิก
  Future<void> register(String username, String password, String? role) async {
    await _apiService.register(username, password, role);
  }

  // สั่งล็อกอิน
  Future<void> login(String username, String password) async {
    final user = await _apiService.login(username, password);
    _username = user['username'];
    _role = user['role'];
    _isLoggedIn = true;
    notifyListeners();
  }

  // สั่งล็อกเอาท์
  Future<void> logout() async {
    await _apiService.logout();
    _isLoggedIn = false;
    _username = null;
    _role = null;
    notifyListeners();
  }
}
