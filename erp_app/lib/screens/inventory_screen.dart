import 'dart:async';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';
import '../services/elegant_notification_service.dart';
import '../widgets/skeleton_loader.dart';
import '../core/theme/index.dart';
import '../core/widgets/erp_status_badge.dart';
import '../core/widgets/erp_section_header.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen>
    with TickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tableScrollController = ScrollController();

  bool _isLoading = true;
  bool _isLoadingMore = false;
  String? _errorMessage;
  List<Product> _products = [];
  static const int _rowsPerPage = 20;
  late final _ProductDataSource _dataSource;
  Timer? _searchDebounce;

  int _currentPage = 1;
  int _totalCount = 0;
  int _totalPages = 1;
  String _search = '';
  String _stockStatus = 'ALL';
  String _sortBy = 'id';
  String _order = 'asc';

  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  final RealtimeService _realtimeService = RealtimeService();
  StreamSubscription<Map<String, dynamic>>? _orderSubscription;
  StreamSubscription<Map<String, dynamic>>? _stockSubscription;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: AppDurations.normal,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: AppDurations.defaultCurve,
    );
    _dataSource = _ProductDataSource(onSelect: _showStockMovementBottomSheet);
    _loadProducts();

    // 🔌 Realtime listeners
    _realtimeService.connect();
    _stockSubscription = _realtimeService.stockStream.listen((data) {
      if (!mounted) return;
      _loadProducts(silent: true);
    });
    _orderSubscription = _realtimeService.orderStream.listen((data) {
      if (!mounted) return;
      _loadProducts(silent: true);
    });
  }

  @override
  void dispose() {
    _stockSubscription?.cancel();
    _orderSubscription?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _tableScrollController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ============================================================
  // Data Loading
  // ============================================================

  Future<void> _loadProducts({int? page, bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    } else {
      setState(() => _isLoadingMore = true);
    }

    try {
      final targetPage = page ?? _currentPage;
      final data = await _apiService.fetchProductPage(
        page: targetPage,
        limit: _rowsPerPage,
        search: _search,
        stockStatus: _stockStatus,
        sortBy: _sortBy,
        order: _order,
      );
      if (!mounted) return;
      setState(() {
        _products = data.products;
        _currentPage = data.page;
        _totalCount = data.totalCount;
        _totalPages = data.totalPages;
        _isLoading = false;
        _isLoadingMore = false;
      });
      _dataSource.update(
        products: data.products,
        pageStart: (data.page - 1) * _rowsPerPage,
        totalCount: data.totalCount,
      );
      _fadeController.forward(from: 0);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(AppDurations.slow, () {
      if (_search != value.trim()) {
        _search = value.trim();
        _loadProducts(page: 1);
      }
    });
  }

  void _setStockStatus(String status) {
    if (_stockStatus == status) return;
    setState(() => _stockStatus = status);
    _loadProducts(page: 1);
  }

  void _toggleOrder() {
    setState(() => _order = _order == 'asc' ? 'desc' : 'asc');
    _loadProducts(page: 1);
  }

  void _setSortBy(String? value) {
    if (value == null || _sortBy == value) return;
    setState(() => _sortBy = value);
    _loadProducts(page: 1);
  }

  void _goToPage(int page) {
    if (page < 1 || page > _totalPages || page == _currentPage) return;
    _loadProducts(page: page, silent: true);
  }

  // ============================================================
  // Dialogs / Sheets
  // ============================================================

  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();
    final skuController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(text: '0');
    final minAlertController = TextEditingController(text: '10');
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              title: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(20),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.add_box_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'เพิ่มสินค้าใหม่',
                    style: AppTextStyles.headingMedium,
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildFormField(
                        controller: skuController,
                        label: 'รหัส SKU *',
                        icon: Icons.qr_code_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'กรุณาระบุรหัส SKU' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: nameController,
                        label: 'ชื่อสินค้า *',
                        icon: Icons.shopping_bag_outlined,
                        validator: (v) => v == null || v.isEmpty
                            ? 'กรุณาระบุชื่อสินค้า'
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: priceController,
                        label: 'ราคาขาย (บาท) *',
                        icon: Icons.attach_money_outlined,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณาระบุราคา';
                          if (double.tryParse(v) == null) {
                            return 'ต้องเป็นตัวเลข';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFormField(
                              controller: stockController,
                              label: 'สต๊อกเริ่มต้น',
                              icon: Icons.inventory_2_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null
                                  ? 'ต้องเป็นตัวเลข'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildFormField(
                              controller: minAlertController,
                              label: 'เตือนต่ำกว่า',
                              icon: Icons.warning_amber_outlined,
                              keyboardType: TextInputType.number,
                              validator: (v) => int.tryParse(v ?? '') == null
                                  ? 'ต้องเป็นตัวเลข'
                                  : null,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                OutlinedButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: const Text('ยกเลิก'),
                ),
                ElevatedButton.icon(
                  onPressed: isSubmitting
                      ? null
                      : () async {
                          if (formKey.currentState!.validate()) {
                            setDialogState(() => isSubmitting = true);
                            try {
                              await _apiService.createProduct(
                                sku: skuController.text.trim(),
                                name: nameController.text.trim(),
                                price: double.parse(priceController.text),
                                currentStock: int.parse(stockController.text),
                                minStockAlert: int.parse(
                                  minAlertController.text,
                                ),
                              );
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                _loadProducts(page: 1);
                                _showSnackBar(
                                  '🎉 บันทึกสินค้าลง Database เรียบร้อยแล้ว!',
                                  isSuccess: true,
                                );
                              }
                            } catch (e) {
                              setDialogState(() => isSubmitting = false);
                              if (ctx.mounted) {
                                _showSnackBar(
                                  e.toString().replaceAll('Exception: ', ''),
                                  isSuccess: false,
                                );
                              }
                            }
                          }
                        },
                  icon: isSubmitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 18),
                  label: const Text('บันทึกข้อมูล'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showStockMovementBottomSheet(Product product) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final refController = TextEditingController(
      text:
          'REF-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    );
    String selectedType = 'OUT';
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: AppShadows.sidebarShadow,
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 16,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.sync_alt,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: AppTextStyles.headingMedium,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'คงเหลือ: ${product.currentStock} ชิ้น  |  SKU: ${product.sku}',
                                style: AppTextStyles.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    const Divider(),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTypeChip(
                            label: '➕ รับของเข้า (IN)',
                            isSelected: selectedType == 'IN',
                            selectedColor: AppColors.success,
                            onTap: () =>
                                setSheetState(() => selectedType = 'IN'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeChip(
                            label: '➖ เบิกออก (OUT)',
                            isSelected: selectedType == 'OUT',
                            selectedColor: AppColors.warning,
                            onTap: () =>
                                setSheetState(() => selectedType = 'OUT'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildFormField(
                      controller: quantityController,
                      label: selectedType == 'IN'
                          ? 'จำนวนที่รับเข้า (ชิ้น) *'
                          : 'จำนวนที่เบิกออก (ชิ้น) *',
                      icon: Icons.numbers_outlined,
                      keyboardType: TextInputType.number,
                      autofocus: true,
                      validator: (val) {
                        if (val == null || val.isEmpty) return 'กรุณาระบุจำนวน';
                        final num = int.tryParse(val);
                        if (num == null || num <= 0) {
                          return 'ต้องเป็นตัวเลขมากกว่า 0';
                        }
                        if (selectedType == 'OUT' &&
                            num > product.currentStock) {
                          return 'สต๊อกไม่พอ! (สูงสุด ${product.currentStock} ชิ้น)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    _buildFormField(
                      controller: refController,
                      label: 'เลขอ้างอิงบิล / เหตุผล',
                      icon: Icons.receipt_long_outlined,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedType == 'IN'
                              ? AppColors.success
                              : AppColors.warning,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setSheetState(() => isSubmitting = true);
                                  try {
                                    await _apiService.recordStockMovement(
                                      productId: product.id,
                                      type: selectedType,
                                      quantity: int.parse(
                                        quantityController.text,
                                      ),
                                      referenceId: refController.text.trim(),
                                    );
                                    if (ctx.mounted) {
                                      Navigator.of(ctx).pop();
                                      _loadProducts(silent: true);
                                      _showSnackBar(
                                        selectedType == 'IN'
                                            ? '📦 รับของเข้าสต๊อก ${quantityController.text} ชิ้น เรียบร้อย!'
                                            : '🚀 เบิกของออก ${quantityController.text} ชิ้น เรียบร้อย!',
                                        isSuccess: true,
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    if (ctx.mounted) {
                                      _showSnackBar(
                                        e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
                                        isSuccess: false,
                                      );
                                    }
                                  }
                                }
                              },
                        icon: isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Icon(
                                selectedType == 'IN'
                                    ? Icons.add_circle_outline
                                    : Icons.remove_circle_outline,
                                size: 20,
                              ),
                        label: Text(
                          selectedType == 'IN'
                              ? 'ยืนยันรับเข้าคลัง'
                              : 'ยืนยันเบิกออกตัดสต๊อก',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ============================================================
  // Helper Widgets
  // ============================================================

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    bool autofocus = false,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
      ),
    );
  }

  Widget _buildTypeChip({
    required String label,
    required bool isSelected,
    required Color selectedColor,
    required VoidCallback onTap,
  }) {
    return AnimatedContainer(
      duration: AppDurations.fast,
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withAlpha(20)
            : AppColors.muted,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? selectedColor : AppColors.border,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Center(
            child: Text(
              label,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isSelected ? selectedColor : AppColors.mutedForeground,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    if (isSuccess) {
      ElegantNotificationService.success(
        context,
        title: '🎉 สำเร็จ!',
        description: message,
      );
    } else {
      ElegantNotificationService.warning(
        context,
        title: '⚠️ คำเตือน',
        description: message,
      );
    }
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        icon: const Icon(Icons.add),
        label: const Text('เพิ่มสินค้า'),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const TableSkeletonLoader(rowCount: 8, columnCount: 5);
    }

    if (_errorMessage != null) {
      return ErpErrorState(
        message: _errorMessage!,
        onRetry: _loadProducts,
      );
    }

    return Column(
      children: [
        _buildToolbar(),
        _buildSummaryBar(),
        Expanded(child: _buildTable()),
        _buildPaginationBar(),
      ],
    );
  }

  // ============================================================
  // Toolbar
  // ============================================================

  Widget _buildToolbar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'ค้นหาด้วย SKU หรือชื่อสินค้า...',
              suffixIcon: _search.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        _search = '';
                        _loadProducts(page: 1);
                      },
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final f in const [
                        ('ALL', 'ทั้งหมด', 0xFFE2E8F0, 0xFF64748B),
                        ('IN_STOCK', 'มีสินค้า', 0xFFDCFCE7, 0xFF16A34A),
                        ('LOW_STOCK', 'ใกล้หมด', 0xFFFEF3C7, 0xFFD97706),
                        ('OUT_OF_STOCK', 'หมดสต๊อก', 0xFFFEE2E2, 0xFFDC2626),
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: _buildFilterChip(
                            label: f.$2,
                            value: f.$1,
                            bgColor: Color(f.$3),
                            textColor: Color(f.$4),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                height: 38,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    style: AppTextStyles.bodyMedium,
                    icon: const Icon(Icons.swap_vert, size: 18),
                    items: const [
                      DropdownMenuItem(value: 'id', child: Text('รหัส')),
                      DropdownMenuItem(value: 'name', child: Text('ชื่อ')),
                      DropdownMenuItem(value: 'price', child: Text('ราคา')),
                      DropdownMenuItem(
                        value: 'currentStock',
                        child: Text('สต๊อก'),
                      ),
                    ],
                    onChanged: _setSortBy,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: _toggleOrder,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required String value,
    required Color bgColor,
    required Color textColor,
  }) {
    final isSelected = _stockStatus == value;
    return AnimatedContainer(
      duration: AppDurations.fast,
      child: InkWell(
        onTap: () => _setStockStatus(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : AppColors.muted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected
                  ? textColor.withAlpha(128)
                  : AppColors.border,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: AppTextStyles.labelMedium.copyWith(
              color: isSelected ? textColor : AppColors.mutedForeground,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  // ============================================================
  // Summary Bar
  // ============================================================

  Widget _buildSummaryBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(20),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_totalCount รายการ',
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (_search.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.warning.withAlpha(20),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search, size: 12, color: AppColors.warning),
                  const SizedBox(width: 4),
                  Text(
                    '"$_search"',
                    style: AppTextStyles.labelMedium.copyWith(color: AppColors.warning),
                  ),
                ],
              ),
            ),
          ],
          if (_isLoadingMore) ...[
            const Spacer(),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 6),
            const Text(
              'กำลังโหลด...',
              style: TextStyle(fontSize: 11, color: AppColors.mutedForeground),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // Table
  // ============================================================

  Widget _buildTable() {
    if (_products.isEmpty && !_isLoading) {
      return ErpEmptyState(
        icon: Icons.inventory_2_outlined,
        title: _search.isNotEmpty ? 'ไม่พบสินค้าที่ค้นหา' : 'ยังไม่มีสินค้าในคลัง',
        subtitle: _search.isNotEmpty ? '"$_search"' : 'กดปุ่ม "+ เพิ่มสินค้า" เพื่อบันทึกสินค้าใหม่',
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scrollbar(
        controller: _tableScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _tableScrollController,
          child: Theme(
            data: Theme.of(context).copyWith(
              cardTheme: CardThemeData(
                color: AppColors.surface,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.cardBorder),
                ),
              ),
            ),
            child: PaginatedDataTable(
              header: Row(
                children: [
                  Text(
                    'สินค้าในคลัง',
                    style: AppTextStyles.headingMedium,
                  ),
                  const Spacer(),
                  Text(
                    'หน้า $_currentPage / $_totalPages',
                    style: AppTextStyles.bodySmall,
                  ),
                ],
              ),
              rowsPerPage: _rowsPerPage,
              availableRowsPerPage: const [_rowsPerPage],
              showFirstLastButtons: true,
              onPageChanged: (firstRowIndex) {
                final page = (firstRowIndex ~/ _rowsPerPage) + 1;
                _goToPage(page);
              },
              headingRowColor: WidgetStateProperty.all(AppColors.muted),
              columns: [
                DataColumn(label: _buildColumnHeader('SKU', 'sku')),
                DataColumn(label: _buildColumnHeader('ชื่อสินค้า', 'name')),
                DataColumn(
                  label: _buildColumnHeader('ราคา', 'price'),
                  numeric: true,
                ),
                DataColumn(
                  label: _buildColumnHeader('คงเหลือ', 'currentStock'),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(
                    'สถานะ',
                    style: AppTextStyles.headingSmall,
                  ),
                ),
              ],
              source: _dataSource,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildColumnHeader(String label, String field) {
    final isActive = _sortBy == field;
    return InkWell(
      onTap: () {
        if (_sortBy == field) {
          _toggleOrder();
        } else {
          _setSortBy(field);
        }
      },
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTextStyles.headingSmall.copyWith(
              color: isActive ? AppColors.primary : AppColors.foreground,
            ),
          ),
          const SizedBox(width: 4),
          if (isActive)
            Icon(
              _order == 'asc' ? Icons.arrow_upward : Icons.arrow_downward,
              size: 14,
              color: AppColors.primary,
            )
          else
            Icon(Icons.unfold_more, size: 14, color: AppColors.mutedForeground),
        ],
      ),
    );
  }

  // ============================================================
  // Custom Pagination Bar
  // ============================================================

  Widget _buildPaginationBar() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildNavButton(
            icon: Icons.first_page,
            onTap: _currentPage > 1 ? () => _goToPage(1) : null,
          ),
          const SizedBox(width: 4),
          _buildNavButton(
            icon: Icons.chevron_left,
            onTap: _currentPage > 1 ? () => _goToPage(_currentPage - 1) : null,
          ),
          const SizedBox(width: 12),
          ..._buildPageNumbers(),
          const SizedBox(width: 12),
          _buildNavButton(
            icon: Icons.chevron_right,
            onTap: _currentPage < _totalPages
                ? () => _goToPage(_currentPage + 1)
                : null,
          ),
          const SizedBox(width: 4),
          _buildNavButton(
            icon: Icons.last_page,
            onTap: _currentPage < _totalPages
                ? () => _goToPage(_totalPages)
                : null,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPageNumbers() {
    final List<Widget> buttons = [];
    int start = (_currentPage - 2).clamp(1, _totalPages);
    int end = (start + 4).clamp(1, _totalPages);
    if (end - start < 4) start = (end - 4).clamp(1, _totalPages);

    if (start > 1) {
      buttons.add(_buildPageNumBtn(1));
      if (start > 2) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: AppTextStyles.bodySmall),
          ),
        );
      }
    }

    for (int i = start; i <= end; i++) {
      buttons.add(_buildPageNumBtn(i));
    }

    if (end < _totalPages) {
      if (end < _totalPages - 1) {
        buttons.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('...', style: AppTextStyles.bodySmall),
          ),
        );
      }
      buttons.add(_buildPageNumBtn(_totalPages));
    }

    return buttons;
  }

  Widget _buildPageNumBtn(int page) {
    final isActive = page == _currentPage;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: InkWell(
        onTap: () => _goToPage(page),
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: AppDurations.fast,
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive ? null : Border.all(color: AppColors.border),
          ),
          alignment: Alignment.center,
          child: Text(
            '$page',
            style: AppTextStyles.bodyMedium.copyWith(
              color: isActive ? Colors.white : AppColors.mutedForeground,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.border),
        ),
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: onTap != null ? AppColors.primary : AppColors.border,
          ),
        ),
      );
  }
}

// ============================================================
// Data Source สำหรับ PaginatedDataTable
// ============================================================

class _ProductDataSource extends DataTableSource {
  _ProductDataSource({required this.onSelect});

  final ValueChanged<Product> onSelect;
  List<Product> _products = [];
  int _pageStart = 0;
  int _totalCount = 0;

  void update({
    required List<Product> products,
    required int pageStart,
    required int totalCount,
  }) {
    _products = products;
    _pageStart = pageStart;
    _totalCount = totalCount;
    notifyListeners();
  }

  @override
  DataRow? getRow(int index) {
    final localIndex = index - _pageStart;
    if (localIndex < 0 || localIndex >= _products.length) return null;
    final product = _products[localIndex];
    final isOut = product.currentStock == 0;
    final isLow = product.isLowStock && !isOut;

    return DataRow.byIndex(
      index: index,
      onSelectChanged: (_) => onSelect(product),
      color: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.hovered)) {
          return AppColors.primaryLight.withAlpha(20);
        }
        if (isOut) return AppColors.destructive.withAlpha(10);
        if (isLow) return AppColors.warning.withAlpha(10);
        return null;
      }),
      cells: [
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.muted,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              product.sku,
              style: AppTextStyles.bodySmall.copyWith(
                fontFamily: 'FiraCode',
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        DataCell(
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                product.name,
                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'แตะเพื่อปรับสต๊อก',
                style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            '฿${product.price.toStringAsFixed(2)}',
            style: AppTextStyles.kpiMedium.copyWith(
              color: AppColors.success,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(
          Text(
            '${product.currentStock}',
            style: AppTextStyles.kpiMedium.copyWith(
              color: isOut
                  ? AppColors.mutedForeground
                  : isLow
                      ? AppColors.destructive
                      : AppColors.foreground,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(isOut, isLow)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isOut, bool isLow) {
    if (isOut) {
      return ErpStatusBadge.fromString('OUT_OF_STOCK');
    }
    if (isLow) {
      return ErpStatusBadge.fromString('LOW_STOCK');
    }
    return ErpStatusBadge.fromString('IN_STOCK');
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _totalCount;

  @override
  int get selectedRowCount => 0;
}
