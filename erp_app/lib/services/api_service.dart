import 'dart:async' show TimeoutException;
import 'dart:convert';
import 'dart:io' show Platform, SocketException;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart'; // ✅ รองรับ Web!
import '../models/product.dart';

class ApiService {
  // Override ได้ด้วย --dart-define=API_BASE_URL=http://<IP-เครื่อง-server>:3000/api
  // Android Emulator มอง localhost เป็นตัว emulator เอง จึงต้องเรียกเครื่อง host ผ่าน 10.0.2.2
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    if (_configuredBaseUrl.isNotEmpty) return _configuredBaseUrl;
    if (kIsWeb || !Platform.isAndroid) return 'http://localhost:3000/api';
    return 'http://10.0.2.2:3000/api';
  }

  // ==========================================
  // ส่วนที่ 1: จัดการ Token และ Login
  // ==========================================

  // สมัครสมาชิก (Register)
  Future<Map<String, dynamic>> register(
    String username,
    String password,
    String? role,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'username': username,
        'password': password,
        'role': role ?? 'WAREHOUSE_STAFF',
      }),
    );

    final data = json.decode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'สมัครสมาชิกไม่สำเร็จ');
    }
  }

  // ล็อกอินและเก็บ Token พร้อมสิทธิ์ผู้ใช้ลง SharedPreferences (รองรับ Web)
  Future<Map<String, dynamic>> login(String username, String password) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/login'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({'username': username, 'password': password}),
          )
          .timeout(const Duration(seconds: 15));

      final data = json.decode(response.body) as Map<String, dynamic>;
      if (response.statusCode == 200 && data['success'] == true) {
        // บันทึก Token และสิทธิ์เก็บไว้ใน SharedPreferences
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('jwt_token', data['token']);
        await prefs.setString('user_role', data['user']['role']);
        await prefs.setString('username', data['user']['username']);
        return data['user'];
      }
      throw Exception(data['message'] ?? 'เข้าสู่ระบบไม่สำเร็จ');
    } on SocketException {
      throw Exception(
        'เชื่อมต่อเซิร์ฟเวอร์ไม่ได้ กรุณาเปิด backend และตรวจสอบ API_BASE_URL',
      );
    } on FormatException {
      throw Exception('เซิร์ฟเวอร์ตอบกลับข้อมูลไม่ถูกต้อง');
    } on TimeoutException {
      throw Exception('เชื่อมต่อเซิร์ฟเวอร์นานเกินไป กรุณาลองใหม่');
    }
  }

  // ล็อกเอาท์ (ลบ Token ทิ้งทั้งหมด)
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_role');
    await prefs.remove('username');
  }

  // อ่านข้อมูลสิทธิ์ที่ล็อกอินอยู่ปัจจุบัน
  Future<String?> getUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('user_role');
  }

  Future<String?> getUsername() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('username');
  }

  // 💡 ฟังก์ชันลับของ SA: เตรียม Header พร้อมเหน็บ Token (Bearer <token>)
  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwt_token');
    return {
      'Content-Type': 'application/json',
      if (token != null)
        'Authorization': 'Bearer $token', // ถ้ามี Token ให้เหน็บไปด้วยเสมอ!
    };
  }

  // ==========================================
  // ส่วนที่ 2: ERP API (เหน็บ _getHeaders() ทุกจุด!)
  // ==========================================

  Future<List<Product>> fetchProducts() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/products'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = json.decode(response.body);
        final List<dynamic> productsJson = jsonResponse['data'];
        return productsJson.map((json) => Product.fromJson(json)).toList();
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        throw Exception('เซสชันหมดอายุ กรุณาล็อกอินใหม่');
      } else {
        throw Exception('ดึงข้อมูลล้มเหลว (Status: ${response.statusCode})');
      }
    } catch (e) {
      throw Exception('ข้อผิดพลาด: $e');
    }
  }

  Future<void> createProduct({
    required String sku,
    required String name,
    required double price,
    required int currentStock,
    required int minStockAlert,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: headers,
      body: json.encode({
        'sku': sku,
        'name': name,
        'price': price,
        'currentStock': currentStock,
        'minStockAlert': minStockAlert,
      }),
    );
    if (response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'บันทึกไม่สำเร็จ');
    }
  }

  Future<void> recordStockMovement({
    required int productId,
    required String type,
    required int quantity,
    String? referenceId,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/stock-movements'),
      headers: headers,
      body: json.encode({
        'productId': productId,
        'type': type,
        'quantity': quantity,
        'referenceId': referenceId,
      }),
    );
    if (response.statusCode != 201) {
      final data = json.decode(response.body);
      throw Exception(data['message'] ?? 'ปรับสต๊อกไม่สำเร็จ');
    }
  }

  // ==========================================
  // ส่วนที่ 3: Orders API (เปิดบิล POS)
  // ==========================================

  Future<Map<String, dynamic>> createOrder({
    required String customerName,
    required List<Map<String, dynamic>> items,
  }) async {
    final headers = await _getHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/orders'),
      headers: headers,
      body: json.encode({'customerName': customerName, 'items': items}),
    );
    final data = json.decode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return data['data'];
    } else {
      throw Exception(data['message'] ?? 'เปิดบิลไม่สำเร็จ');
    }
  }

  // ดึงรายการซัพพลายเออร์
  Future<List<Map<String, dynamic>>> fetchSuppliers() async {
    final response = await http.get(
      Uri.parse('$baseUrl/suppliers'),
      headers: await _getHeaders(),
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = json.decode(response.body)['data'];
      return data.cast<Map<String, dynamic>>();
    }
    throw Exception('ดึงข้อมูลซัพพลายเออร์ล้มเหลว');
  }

  // สร้างใบสั่งซื้อ (PO)
  Future<void> createPurchaseOrder(
    int supplierId,
    List<Map<String, dynamic>> items,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/purchase-orders'),
      headers: await _getHeaders(),
      body: json.encode({'supplierId': supplierId, 'items': items}),
    );
    if (response.statusCode != 201) {
      throw Exception(
        json.decode(response.body)['message'] ?? 'เปิด PO ล้มเหลว',
      );
    }
  }
}
