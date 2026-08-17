import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:socket_io_client/socket_io_client.dart' as io;

// ============================================================
// ⭐ RealtimeService — Singleton ที่จัดการ Socket.io connection
//
// การใช้งาน:
//   final svc = RealtimeService();
//   svc.orderStream.listen((data) { ... });
//   svc.stockStream.listen((data) { ... });
//   svc.connect();        // เรียกตอน App เริ่มต้น
//   svc.disconnect();     // เรียกตอน Logout
// ============================================================

class RealtimeService {
  // ── Singleton pattern ──
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  // ── State ──
  io.Socket? _socket;
  bool _isConnected = false;
  bool get isConnected => _isConnected;

  // ── Stream controllers ──
  // new_order event: เมื่อมีบิลขายใหม่เข้าระบบ
  final _orderController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get orderStream => _orderController.stream;

  // stock_updated event: เมื่อมีการขยับสต๊อก (IN/OUT/ADJUST)
  final _stockController =
      StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get stockStream => _stockController.stream;

  // connection_status event: แจ้ง UI ว่า connect/disconnect
  final _statusController = StreamController<bool>.broadcast();
  Stream<bool> get connectionStream => _statusController.stream;

  // ── Server URL ──
  static String get _serverUrl {
    // Flutter Web รันที่ localhost:* ส่วน Android Emulator ใช้ 10.0.2.2
    if (kIsWeb) return 'http://localhost:3000';
    return 'http://10.0.2.2:3000';
  }

  // ============================================================
  // connect() — เชื่อมต่อกับ Socket.io server
  // ============================================================
  void connect() {
    if (_socket != null && _isConnected) return; // ป้องกันการ connect ซ้ำ

    _socket = io.io(
      _serverUrl,
      io.OptionBuilder()
          .setTransports(['websocket', 'polling']) // Fallback polling สำหรับ Web
          .setReconnectionAttempts(5)              // ลอง reconnect สูงสุด 5 ครั้ง
          .setReconnectionDelay(2000)              // รอ 2 วิก่อน reconnect
          .enableAutoConnect()
          .enableReconnection()
          .build(),
    );

    // ── Event Handlers ──
    _socket!.onConnect((_) {
      _isConnected = true;
      _statusController.add(true);
      print('🔌 [RealtimeService] Socket.io เชื่อมต่อสำเร็จ! ID: ${_socket!.id}');
    });

    _socket!.onDisconnect((_) {
      _isConnected = false;
      _statusController.add(false);
      print('❌ [RealtimeService] Socket.io ตัดการเชื่อมต่อ');
    });

    _socket!.onConnectError((err) {
      _isConnected = false;
      _statusController.add(false);
      print('⚠️ [RealtimeService] เชื่อมต่อล้มเหลว: $err');
    });

    // ── Listen ต่อ event จาก Server ──

    // เมื่อมีบิลขายใหม่ (จาก POST /api/orders)
    _socket!.on('new_order', (data) {
      print('💰 [RealtimeService] new_order: ${data['orderNumber']}');
      if (!_orderController.isClosed) {
        _orderController.add(Map<String, dynamic>.from(data as Map));
      }
    });

    // เมื่อมีการปรับสต๊อก (จาก POST /api/stock-movements)
    _socket!.on('stock_updated', (data) {
      print('📦 [RealtimeService] stock_updated: ${data['productSku']}');
      if (!_stockController.isClosed) {
        _stockController.add(Map<String, dynamic>.from(data as Map));
      }
    });

    _socket!.connect();
  }

  // ============================================================
  // disconnect() — ตัดการเชื่อมต่อ (เรียกตอน Logout)
  // ============================================================
  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
    _isConnected = false;
    print('🔌 [RealtimeService] Disconnected and disposed');
  }

  // ============================================================
  // dispose() — ทำลาย stream controllers (เรียกตอน App ปิด)
  // ============================================================
  void dispose() {
    disconnect();
    _orderController.close();
    _stockController.close();
    _statusController.close();
  }
}
