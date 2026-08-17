import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/realtime_service.dart';
import '../widgets/notification_overlay.dart';
import 'inventory_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  final RealtimeService _realtimeService = RealtimeService();

  StreamSubscription<Map<String, dynamic>>? _orderSubscription;
  StreamSubscription<Map<String, dynamic>>? _stockSubscription;
  StreamSubscription<bool>? _connectionSubscription;

  bool _isLoading = true;
  bool _isRealtimeConnected = false;
  String? _errorMessage;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    _realtimeService.connect();
    _isRealtimeConnected = _realtimeService.isConnected;

    _connectionSubscription = _realtimeService.connectionStream.listen((connected) {
      if (mounted) {
        setState(() {
          _isRealtimeConnected = connected;
        });
      }
    });

    // 💰 ดักฟังออเดอร์ใหม่จาก POS / API
    _orderSubscription = _realtimeService.orderStream.listen((data) {
      if (!mounted) return;

      final orderNum = data['orderNumber'] ?? 'N/A';
      final customer = data['customerName'] ?? 'ลูกค้าทั่วไป';
      final total = double.tryParse(data['totalAmount'].toString()) ?? 0.0;
      final createdBy = data['createdBy'] ?? 'พนักงาน';

      // 1. แสดง Live Toast มุมขวาบน
      LiveNotificationService.show(
        context,
        LiveNotification(
          title: 'มีรายการสั่งซื้อใหม่! ($orderNum)',
          message: '💰 ยอดขาย ฿${total.toStringAsFixed(2)} บาท ($customer)',
          subMessage: 'ทำรายการโดย: $createdBy',
          type: NotificationType.newOrder,
        ),
      );

      // 2. รีเฟรชข้อมูลกราฟและสถิติหลังบ้านแบบ Real-time
      _loadDashboardData(silent: true);
    });

    // 📦 ดักฟังการขยับสต๊อก
    _stockSubscription = _realtimeService.stockStream.listen((data) {
      if (!mounted) return;

      final sku = data['productSku'] ?? '';
      final name = data['productName'] ?? '';
      final type = data['type'] ?? '';
      final qty = data['quantity'] ?? 0;
      final performedBy = data['performedBy'] ?? 'พนักงาน';

      final typeLabel = type == 'IN' ? 'รับเข้า' : type == 'OUT' ? 'เบิกออก' : 'ปรับสต๊อก';

      LiveNotificationService.show(
        context,
        LiveNotification(
          title: 'อัปเดตสต๊อกสินค้า ($sku)',
          message: '📦 $typeLabel $qty ชิ้น ($name)',
          subMessage: 'บันทึกโดย: $performedBy',
          type: NotificationType.stockUpdated,
        ),
      );

      _loadDashboardData(silent: true);
    });
  }

  @override
  void dispose() {
    _orderSubscription?.cancel();
    _stockSubscription?.cancel();
    _connectionSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }

    try {
      final data = await _apiService.fetchProducts();
      if (!mounted) return;
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: Row(
          children: [
            const Icon(Icons.dashboard_customize, color: Colors.white),
            const SizedBox(width: 10),
            const Text(
              'Executive Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 12),
            // 🔴 LIVE WebSocket Indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _isRealtimeConnected
                    ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                    : Colors.red.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _isRealtimeConnected ? const Color(0xFF22C55E) : Colors.red,
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _isRealtimeConnected ? const Color(0xFF22C55E) : Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _isRealtimeConnected ? '🔴 LIVE WS' : '⚪ CONNECTING...',
                    style: TextStyle(
                      color: _isRealtimeConnected ? const Color(0xFF22C55E) : Colors.red.shade200,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _loadDashboardData(),
            tooltip: 'รีเฟรชสถิติ',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              Navigator.pop(context);
              context.read<AuthProvider>().logout();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          'เกิดข้อผิดพลาด: $_errorMessage',
          style: const TextStyle(color: Colors.red),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text('ไม่มีข้อมูลสินค้าในระบบ กรุณาเพิ่มสินค้าก่อน'),
      );
    }

    final totalProductsCount = _products.length;
    final totalInventoryValue = _products.fold<double>(
      0,
      (sum, item) => sum + item.totalValue,
    );
    final lowStockProducts = _products.where((p) => p.isLowStock).toList();
    final normalStockCount = totalProductsCount - lowStockProducts.length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // KPI Cards
          LayoutBuilder(
            builder: (context, constraints) {
              final isDesktop = constraints.maxWidth > 800;
              return GridView.count(
                crossAxisCount: isDesktop ? 4 : 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isDesktop ? 2.2 : 1.5,
                children: [
                  _buildKpiCard(
                    'มูลค่าคลังรวม (บาท)',
                    '฿${totalInventoryValue.toStringAsFixed(0)}',
                    Icons.account_balance_wallet,
                    Colors.green,
                  ),
                  _buildKpiCard(
                    'รายการสินค้าทั้งหมด',
                    '$totalProductsCount SKU',
                    Icons.category,
                    Colors.blue,
                  ),
                  _buildKpiCard(
                    'สถานะสต๊อกปกติ',
                    '$normalStockCount รายการ',
                    Icons.check_circle_outline,
                    Colors.teal,
                  ),
                  _buildKpiCard(
                    '⚠️ สินค้าใกล้หมด (ต้องสั่งเพิ่ม)',
                    '${lowStockProducts.length} รายการ',
                    Icons.warning_amber_rounded,
                    Colors.red,
                    isAlert: lowStockProducts.isNotEmpty,
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // Bar Chart
          const Text(
            '📊 กราฟวิเคราะห์ปริมาณสต๊อกรายสินค้า (Stock Level Distribution)',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 350,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: _buildStockBarChart(),
          ),
          const SizedBox(height: 32),

          // Low Stock Table
          if (lowStockProducts.isNotEmpty) ...[
            const Row(
              children: [
                Icon(Icons.add_alert, color: Colors.red, size: 24),
                SizedBox(width: 8),
                Text(
                  '🚨 รายการสินค้าเฝ้าระวัง (Low Stock Alert - ปริมาณต่ำกว่าเกณฑ์)',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildLowStockTable(lowStockProducts),
          ],
        ],
      ),
    );
  }

  Widget _buildKpiCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    bool isAlert = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isAlert ? Colors.red.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: isAlert ? Border.all(color: Colors.red, width: 2) : null,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: TextStyle(
                    color: isAlert ? Colors.red : const Color(0xFF1E293B),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: (_products
                    .map((p) => p.currentStock)
                    .reduce((a, b) => a > b ? a : b) +
                10)
            .toDouble(),
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= _products.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Text(
                    _products[index].sku,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 40),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        barGroups: _products.asMap().entries.map((entry) {
          final index = entry.key;
          final product = entry.value;
          final barColor = product.isLowStock
              ? Colors.redAccent
              : Colors.blueAccent;
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: product.currentStock.toDouble(),
                color: barColor,
                width: 24,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(6),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildLowStockTable(List<Product> lowStockProducts) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(Colors.red.shade50),
            columns: const [
              DataColumn(
                label: Text(
                  'รหัส SKU',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'ชื่อสินค้า',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'คงเหลือในคลัง',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),
              ),
              DataColumn(
                label: Text(
                  'สถานะ',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              DataColumn(
                label: Text(
                  'จัดการ (Action)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
            rows: lowStockProducts.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      product.sku,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  DataCell(Text(product.name)),
                  DataCell(
                    Text(
                      '${product.currentStock} ชิ้น',
                      style: const TextStyle(
                        color: Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  DataCell(
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'ต้องสั่งเพิ่ม!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  DataCell(
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue.shade800,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      label: const Text(
                        'ออกใบ PO',
                        style: TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _showCreatePODialog(product),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showCreatePODialog(Product product) async {
    List<Map<String, dynamic>> suppliers = [];
    try {
      suppliers = await _apiService.fetchSuppliers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('โหลดซัพพลายเออร์ล้มเหลว: $e')),
      );
      return;
    }

    if (suppliers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'ไม่พบรายชื่อซัพพลายเออร์ในระบบ (กรุณาเพิ่มใน Database ก่อน)',
          ),
        ),
      );
      return;
    }

    int selectedSupplierId = suppliers.first['id'];
    final qtyController = TextEditingController(text: '10');
    final costController = TextEditingController(
      text: (product.price * 0.7).toStringAsFixed(0),
    );

    if (!mounted) return;

    showDialog(
      context: context,
      builder: (ctx) {
        bool isSubmitting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('📄 ออกใบสั่งซื้อ (PO) - ${product.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    decoration: const InputDecoration(
                      labelText: 'เลือกบริษัทซัพพลายเออร์',
                      border: OutlineInputBorder(),
                    ),
                    value: selectedSupplierId,
                    items: suppliers.map((sup) {
                      return DropdownMenuItem<int>(
                        value: sup['id'],
                        child: Text(sup['name']),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() => selectedSupplierId = val);
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: qtyController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'จำนวนที่สั่ง (ชิ้น)',
                            prefixIcon: Icon(Icons.numbers),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: costController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'ต้นทุน/ชิ้น (บาท)',
                            prefixIcon: Icon(Icons.money),
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '⚠️ หมายเหตุ: การออก PO จะยังไม่เพิ่มสต๊อกในคลัง จนกว่าพนักงานคลังจะกด "รับของ" ตามใบ PO',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue.shade800,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          setDialogState(() => isSubmitting = true);
                          try {
                            await _apiService.createPurchaseOrder(
                              selectedSupplierId,
                              [
                                {
                                  'productId': product.id,
                                  'quantity': int.parse(qtyController.text),
                                  'unitCost': double.parse(costController.text),
                                },
                              ],
                            );

                            if (ctx.mounted) {
                              Navigator.pop(ctx);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    '🎉 ส่งใบสั่งซื้อ (PO) ไปให้ซัพพลายเออร์เรียบร้อยแล้ว!',
                                  ),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (ctx.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(e.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('ยืนยันสร้างใบสั่งซื้อ'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
