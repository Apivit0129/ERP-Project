import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../services/elegant_notification_service.dart';
import '../widgets/notification_overlay.dart';
import '../widgets/skeleton_loader.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_theme.dart';
import '../core/widgets/erp_kpi_card.dart';
import '../core/widgets/erp_status_badge.dart';
import '../core/widgets/erp_section_header.dart';

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
  String? _errorMessage;
  List<Product> _products = [];

  DateTime? _dateRangeStart;
  DateTime? _dateRangeEnd;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _initRealtimeListeners();
  }

  void _initRealtimeListeners() {
    _realtimeService.connect();

    _connectionSubscription = _realtimeService.connectionStream.listen((_) {});

    _orderSubscription = _realtimeService.orderStream.listen((data) {
      if (!mounted) return;
      final orderNum = data['orderNumber'] ?? 'N/A';
      final customer = data['customerName'] ?? 'ลูกค้าทั่วไป';
      final total = double.tryParse(data['totalAmount'].toString()) ?? 0.0;
      final createdBy = data['createdBy'] ?? 'พนักงาน';

      LiveNotificationService.show(
        context,
        LiveNotification(
          title: 'มีรายการสั่งซื้อใหม่! ($orderNum)',
          message: 'ยอดขาย ฿${total.toStringAsFixed(2)} บาท ($customer)',
          subMessage: 'ทำรายการโดย: $createdBy',
          type: NotificationType.newOrder,
        ),
      );
      _loadDashboardData(silent: true);
    });

    _stockSubscription = _realtimeService.stockStream.listen((data) {
      if (!mounted) return;
      final sku = data['productSku'] ?? '';
      final name = data['productName'] ?? '';
      final type = data['type'] ?? '';
      final qty = data['quantity'] ?? 0;
      final performedBy = data['performedBy'] ?? 'พนักงาน';

      final typeLabel = type == 'IN'
          ? 'รับเข้า'
          : type == 'OUT'
          ? 'เบิกออก'
          : 'ปรับสต๊อก';

      LiveNotificationService.show(
        context,
        LiveNotification(
          title: 'อัปเดตสต๊อกสินค้า ($sku)',
          message: '$typeLabel $qty ชิ้น ($name)',
          subMessage: 'บันทึกโดย: $performedBy',
          type: NotificationType.stockUpdated,
        ),
      );
      _loadDashboardData(silent: true);
    });
  }

  Map<String, double> _getCategoryValueDistribution() {
    final distribution = <String, double>{};
    for (final product in _products) {
      final category = product.sku.length >= 3
          ? product.sku.substring(0, 3).toUpperCase()
          : product.sku.toUpperCase();
      distribution[category] =
          (distribution[category] ?? 0) + product.totalValue;
    }
    return distribution;
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
    return Scaffold(backgroundColor: AppColors.background, body: _buildBody());
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const DashboardSkeletonLoader(cardCount: 4);
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.destructive.withAlpha(18),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.error_outline,
                color: AppColors.destructive,
                size: 30,
              ),
            ),
            AppSpacing.gapBase,
            Text('เกิดข้อผิดพลาด', style: AppTextStyles.headingSmall),
            AppSpacing.gapSM,
            Text(_errorMessage!, style: AppTextStyles.bodySmall),
            AppSpacing.gapLG,
            OutlinedButton.icon(
              onPressed: _loadDashboardData,
              icon: const Icon(Icons.refresh),
              label: const Text('ลองใหม่'),
            ),
          ],
        ),
      );
    }

    if (_products.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              size: 48,
              color: AppColors.mutedForeground,
            ),
            AppSpacing.gapBase,
            Text('ไม่มีข้อมูลสินค้าในระบบ', style: AppTextStyles.headingSmall),
            Text(
              'กรุณาเพิ่มสินค้าก่อนใช้งาน Dashboard',
              style: AppTextStyles.bodySmall,
            ),
          ],
        ),
      );
    }

    final totalProductsCount = _products.length;
    final totalInventoryValue = _products.fold<double>(
      0,
      (sum, item) => sum + item.totalValue,
    );
    final lowStockProducts = _products.where((p) => p.isLowStock).toList();
    final normalStockCount = totalProductsCount - lowStockProducts.length;

    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Page header row ───────────────────────────
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard', style: AppTextStyles.displayMedium),
                      Text(
                        'ภาพรวมคลังสินค้าแบบ Real-time',
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ),
                // Date range picker
                _buildDateRangePicker(),
              ],
            ),
            AppSpacing.gapXL,

            // ── KPI Grid ──────────────────────────────────
            LayoutBuilder(
              builder: (context, constraints) {
                final isDesktop = constraints.maxWidth > 700;
                return GridView.count(
                  crossAxisCount: isDesktop ? 4 : 2,
                  crossAxisSpacing: AppSpacing.base,
                  mainAxisSpacing: AppSpacing.base,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: isDesktop ? 1.7 : 1.4,
                  children: [
                    ErpKpiCard(
                      title: 'มูลค่าคลังรวม',
                      value: '฿${_formatNumber(totalInventoryValue)}',
                      subtitle: 'บาท',
                      icon: Icons.account_balance_wallet_outlined,
                      iconColor: AppColors.success,
                      iconBackground: AppColors.success.withAlpha(20),
                    ),
                    ErpKpiCard(
                      title: 'รายการสินค้า',
                      value: '$totalProductsCount',
                      subtitle: 'SKU ทั้งหมด',
                      icon: Icons.inventory_2_outlined,
                      iconColor: AppColors.primary,
                      iconBackground: AppColors.primary.withAlpha(20),
                    ),
                    ErpKpiCard(
                      title: 'สต๊อกปกติ',
                      value: '$normalStockCount',
                      subtitle: 'รายการ',
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: AppColors.info,
                      iconBackground: AppColors.info.withAlpha(20),
                    ),
                    ErpKpiCard(
                      title: 'สินค้าใกล้หมด',
                      value: '${lowStockProducts.length}',
                      subtitle: 'ต้องสั่งเพิ่ม',
                      icon: Icons.warning_amber_rounded,
                      iconColor: lowStockProducts.isNotEmpty
                          ? AppColors.destructive
                          : AppColors.warning,
                      iconBackground: lowStockProducts.isNotEmpty
                          ? AppColors.destructive.withAlpha(20)
                          : AppColors.warning.withAlpha(20),
                    ),
                  ],
                );
              },
            ),

            // ── Bar Chart ─────────────────────────────────
            ErpSectionHeader(
              title: 'ปริมาณสต๊อกรายสินค้า',
              subtitle: 'Stock Level Distribution',
              icon: Icons.bar_chart_rounded,
            ),
            _buildChartCard(height: 320, child: _buildStockBarChart()),

            // ── Pie Chart ─────────────────────────────────
            ErpSectionHeader(
              title: 'สัดส่วนมูลค่าตามหมวดหมู่',
              subtitle: 'Category Value Distribution',
              icon: Icons.pie_chart_outline_rounded,
            ),
            _buildChartCard(height: 320, child: _buildCategoryPieChart()),

            // ── Low Stock Alert Table ─────────────────────
            if (lowStockProducts.isNotEmpty) ...[
              ErpSectionHeader(
                title: 'รายการสินค้าเฝ้าระวัง',
                subtitle: 'สินค้าที่ต้องสั่งเพิ่มด่วน',
                icon: Icons.notification_important_outlined,
              ),
              _buildLowStockTable(lowStockProducts),
            ],

            AppSpacing.gapXL2,
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangePicker() {
    return OutlinedButton.icon(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.foreground,
        side: const BorderSide(color: AppColors.border),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      ),
      icon: const Icon(Icons.date_range_outlined, size: 17),
      label: Text(
        _dateRangeStart != null
            ? '${_dateRangeStart!.day}/${_dateRangeStart!.month} - ${_dateRangeEnd!.day}/${_dateRangeEnd!.month}'
            : '7 วันล่าสุด',
        style: AppTextStyles.labelMedium,
      ),
      onPressed: () async {
        final today = DateTime.now();
        final sevenDaysAgo = today.subtract(const Duration(days: 7));
        final picked = await showDateRangePicker(
          context: context,
          firstDate: DateTime(2024),
          lastDate: today,
          initialDateRange: _dateRangeStart != null
              ? DateTimeRange(start: _dateRangeStart!, end: _dateRangeEnd!)
              : DateTimeRange(start: sevenDaysAgo, end: today),
          builder: (context, child) => Theme(
            data: Theme.of(context).copyWith(
              colorScheme: Theme.of(
                context,
              ).colorScheme.copyWith(primary: AppColors.primary),
            ),
            child: child!,
          ),
        );
        if (picked != null) {
          setState(() {
            _dateRangeStart = picked.start;
            _dateRangeEnd = picked.end;
          });
        }
      },
    );
  }

  Widget _buildChartCard({required double height, required Widget child}) {
    return Container(
      height: height,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.cardShadow,
      ),
      child: child,
    );
  }

  // ── Bar Chart ─────────────────────────────────────────────
  Widget _buildStockBarChart() {
    if (_products.isEmpty) return const SizedBox();

    final maxStock = _products
        .map((p) => p.currentStock)
        .reduce((a, b) => a > b ? a : b)
        .toDouble();

    return BarChart(
      BarChartData(
        alignment: BarChartAlignment.spaceAround,
        maxY: maxStock + (maxStock * 0.15),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            direction: TooltipDirection.auto,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final product = _products[groupIndex];
              return BarTooltipItem(
                '${product.name}\n${product.currentStock} ชิ้น',
                AppTextStyles.bodySmall.copyWith(
                  color: Colors.white,
                  height: 1.6,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          show: true,
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (double value, TitleMeta meta) {
                final index = value.toInt();
                if (index < 0 || index >= _products.length) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _products[index].sku,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontFamily: 'FiraCode',
                          fontSize: 10,
                        ),
                      ),
                      if (_products[index].isLowStock)
                        const Icon(
                          Icons.warning_amber_rounded,
                          size: 10,
                          color: AppColors.warning,
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) => Text(
                value.toInt().toString(),
                style: AppTextStyles.labelSmall,
              ),
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: AppColors.border, strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: _products.asMap().entries.map((entry) {
          final product = entry.value;
          final stockPct = product.currentStock / maxStock;
          Color barColor;
          if (product.isLowStock) {
            barColor = AppColors.destructive;
          } else if (stockPct > 0.75) {
            barColor = AppColors.success;
          } else if (stockPct > 0.50) {
            barColor = AppColors.primary;
          } else {
            barColor = AppColors.warning;
          }
          return BarChartGroupData(
            x: entry.key,
            barRods: [
              BarChartRodData(
                toY: product.currentStock.toDouble(),
                color: barColor,
                width: 18,
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

  // ── Pie Chart ─────────────────────────────────────────────
  Widget _buildCategoryPieChart() {
    final categoryDistribution = _getCategoryValueDistribution();

    if (categoryDistribution.isEmpty) {
      return const Center(child: Text('ไม่มีข้อมูลหมวดหมู่สินค้า'));
    }

    final totalValue = categoryDistribution.values.fold<double>(
      0,
      (a, b) => a + b,
    );

    final chartColors = [
      AppColors.chart1,
      AppColors.chart2,
      AppColors.chart3,
      AppColors.chart4,
      AppColors.chart5,
      AppColors.chart6,
      AppColors.primaryLight,
      AppColors.info,
    ];

    final entries = categoryDistribution.entries.toList();

    final sections = entries.asMap().entries.map((e) {
      final idx = e.key;
      final entry = e.value;
      final pct = entry.value / totalValue * 100;
      return PieChartSectionData(
        color: chartColors[idx % chartColors.length],
        value: entry.value,
        title: '${pct.toStringAsFixed(1)}%',
        radius: 90,
        titleStyle: AppTextStyles.labelSmall.copyWith(color: Colors.white),
      );
    }).toList();

    return Row(
      children: [
        Expanded(
          flex: 3,
          child: PieChart(
            PieChartData(
              sections: sections,
              centerSpaceRadius: 44,
              sectionsSpace: 2,
            ),
          ),
        ),
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: entries.asMap().entries.map((e) {
                final idx = e.key;
                final entry = e.value;
                final pct = entry.value / totalValue * 100;
                final color = chartColors[idx % chartColors.length];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      AppSpacing.w(8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              entry.key,
                              style: AppTextStyles.labelMedium.copyWith(
                                fontFamily: 'FiraCode',
                              ),
                            ),
                            Text(
                              '฿${_formatNumber(entry.value)} (${pct.toStringAsFixed(1)}%)',
                              style: AppTextStyles.bodySmall.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }

  // ── Low Stock Table ───────────────────────────────────────
  Widget _buildLowStockTable(List<Product> lowStockProducts) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.destructive.withAlpha(50)),
        boxShadow: AppShadows.cardShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: WidgetStateProperty.all(
              AppColors.destructive.withAlpha(12),
            ),
            columns: [
              DataColumn(
                label: Text(
                  'รหัส SKU',
                  style: AppTextStyles.headingSmall.copyWith(
                    fontFamily: 'FiraCode',
                  ),
                ),
              ),
              DataColumn(
                label: Text('ชื่อสินค้า', style: AppTextStyles.headingSmall),
              ),
              DataColumn(
                label: Text(
                  'คงเหลือ',
                  style: AppTextStyles.headingSmall.copyWith(
                    color: AppColors.destructive,
                  ),
                ),
              ),
              DataColumn(
                label: Text('สถานะ', style: AppTextStyles.headingSmall),
              ),
              DataColumn(
                label: Text('Action', style: AppTextStyles.headingSmall),
              ),
            ],
            rows: lowStockProducts.map((product) {
              return DataRow(
                cells: [
                  DataCell(
                    Text(
                      product.sku,
                      style: AppTextStyles.kpiSmall.copyWith(
                        fontFamily: 'FiraCode',
                        color: AppColors.foreground,
                      ),
                    ),
                  ),
                  DataCell(Text(product.name, style: AppTextStyles.bodyMedium)),
                  DataCell(
                    Text(
                      '${product.currentStock} ชิ้น',
                      style: AppTextStyles.kpiMedium.copyWith(
                        color: AppColors.destructive,
                      ),
                    ),
                  ),
                  DataCell(ErpStatusBadge.fromString('LOW_STOCK')),
                  DataCell(
                    OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        minimumSize: const Size(0, 36),
                      ),
                      icon: const Icon(
                        Icons.add_shopping_cart_outlined,
                        size: 15,
                      ),
                      label: Text('ออกใบ PO', style: AppTextStyles.labelMedium),
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

  // ── Create PO Dialog ──────────────────────────────────────
  void _showCreatePODialog(Product product) async {
    List<Map<String, dynamic>> suppliers = [];
    try {
      suppliers = await _apiService.fetchSuppliers();
    } catch (e) {
      ElegantNotificationService.error(
        context,
        title: 'โหลดข้อมูลล้มเหลว',
        description: 'ไม่สามารถโหลดรายชื่อซัพพลายเออร์: $e',
      );
      return;
    }

    if (suppliers.isEmpty) {
      ElegantNotificationService.warning(
        context,
        title: 'ไม่พบข้อมูล',
        description:
            'ไม่พบรายชื่อซัพพลายเออร์ในระบบ กรุณาเพิ่มใน Database ก่อน',
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
              title: Row(
                children: [
                  const Icon(
                    Icons.receipt_long_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  AppSpacing.w(10),
                  Expanded(
                    child: Text(
                      'ออกใบสั่งซื้อ (PO)',
                      style: AppTextStyles.headingMedium,
                    ),
                  ),
                ],
              ),
              content: SizedBox(
                width: 480,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.muted,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.inventory_2_outlined,
                            size: 16,
                            color: AppColors.primary,
                          ),
                          AppSpacing.w(8),
                          Text(
                            product.name,
                            style: AppTextStyles.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    AppSpacing.gapBase,
                    DropdownButtonFormField<int>(
                      decoration: const InputDecoration(
                        labelText: 'ซัพพลายเออร์',
                        prefixIcon: Icon(Icons.business_outlined, size: 18),
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
                    AppSpacing.gapBase,
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: qtyController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'จำนวนสั่ง (ชิ้น)',
                              prefixIcon: Icon(
                                Icons.numbers_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                        AppSpacing.w(12),
                        Expanded(
                          child: TextFormField(
                            controller: costController,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'ต้นทุน/ชิ้น (฿)',
                              prefixIcon: Icon(
                                Icons.monetization_on_outlined,
                                size: 18,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    AppSpacing.gapBase,
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withAlpha(18),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: AppColors.warning.withAlpha(60),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            color: AppColors.warning,
                            size: 16,
                          ),
                          AppSpacing.w(8),
                          Expanded(
                            child: Text(
                              'การออก PO จะยังไม่เพิ่มสต๊อก จนกว่าพนักงานคลังจะกด "รับของ"',
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
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
                              ElegantNotificationService.success(
                                context,
                                title: 'สร้างใบสั่งซื้อสำเร็จ',
                                description:
                                    'ส่ง PO ให้ซัพพลายเออร์เรียบร้อยแล้ว',
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSubmitting = false);
                            if (ctx.mounted) {
                              ElegantNotificationService.error(
                                context,
                                title: 'เกิดข้อผิดพลาด',
                                description: e.toString(),
                              );
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.send_outlined, size: 16),
                  label: const Text('ยืนยันสร้างใบสั่งซื้อ'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ── Helpers ───────────────────────────────────────────────
  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k';
    }
    return value.toStringAsFixed(0);
  }
}
