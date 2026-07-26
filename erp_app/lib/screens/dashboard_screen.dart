import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import 'inventory_screen.dart'; // สั่ง import หน้าคลังสินค้าเดิมเข้ามา เพื่อทำปุ่มเปลี่ยนหน้า

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final data = await _apiService.fetchProducts();
      setState(() {
        _products = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(
        0xFFF5F7FA,
      ), // สีพื้นหลังเทาอ่อนสไตล์ Web Admin Dashboard
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.dashboard_customize, color: Colors.white),
            SizedBox(width: 10),
            Text(
              'ERP Executive Dashboard (ระบบรายงานผู้บริหาร)',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF1E293B), // สีน้ำเงินเข้มดูภูมิฐาน
        foregroundColor: Colors.white,
        elevation: 4,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardData,
            tooltip: 'รีเฟรชสถิติ',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              Navigator.pop(context); // ปิดหน้า Dashboard
              context.read<AuthProvider>().logout(); // ล็อกเอาท์
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

    // ==========================================
    // คำนวณตัวเลขสถิติภาพรวม (SA Data Analytics)
    // ==========================================
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
          // ------------------------------------------
          // โซนที่ 1: การ์ดตัวเลขสรุปผล (KPI Cards)
          // ------------------------------------------
          LayoutBuilder(
            builder: (context, constraints) {
              // เช็คความกว้างหน้าจอ (Responsive Web Design): ถ้าจอกว้างให้เรียง 4 การ์ดแนวนอน ถ้าจอแคบให้พับบรรทัด
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

          // ------------------------------------------
          // โซนที่ 2: กราฟแท่งเปรียบเทียบระดับสต๊อก (Bar Chart)
          // ------------------------------------------
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
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                ),
              ],
            ),
            child: _buildStockBarChart(),
          ),
          const SizedBox(height: 32),

          // ------------------------------------------
          // โซนที่ 3: ตารางรายการที่ต้องรีบสั่งซื้อเพิ่ม (Actionable Table)
          // ------------------------------------------
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

  // ดีไซน์สำหรับการ์ด KPI
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
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
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

  // ดีไซน์กราฟแท่งด้วย fl_chart
  Widget _buildStockBarChart() {
    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY:
            (_products
                        .map((p) => p.currentStock)
                        .reduce((a, b) => a > b ? a : b) +
                    10)
                .toDouble(), // หาค่าสูงสุดเพื่อตั้งเพดานกราฟ
        barTouchData: BarTouchData(enabled: true),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= _products.length)
                  return const SizedBox();
                // เอาแค่ชื่อย่อสินค้ามาโชว์ใต้กราฟ
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
          // ถ้าสต๊อกต่ำให้แท่งกราฟเป็นสีแดง ถ้าปกติให้เป็นสีน้ำเงิน
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

  // ดีไซน์ตารางแจ้งเตือนสินค้าใกล้หมด (Web Table Style)
  Widget _buildLowStockTable(List<Product> lowStockProducts) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: DataTable(
          headingRowColor: MaterialStateProperty.all(Colors.red.shade50),
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
                'ราคา/ชิ้น',
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
                'เกณฑ์แจ้งเตือน',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            DataColumn(
              label: Text(
                'สถานะ',
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
                DataCell(Text('฿${product.price.toStringAsFixed(2)}')),
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
                DataCell(Text('${product.minStockAlert} ชิ้น')),
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
              ],
            );
          }).toList(),
        ),
      ),
    );
  }
}
