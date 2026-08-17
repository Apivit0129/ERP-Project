import 'dart:async';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'purchase_order_screen.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/realtime_service.dart';

// ============================================================
// Design tokens
// ============================================================
const _kPrimary = Color(0xFF3B82F6);
const _kPrimaryDark = Color(0xFF1D4ED8);
const _kSurface = Color(0xFFF8FAFC);
const _kTextPrimary = Color(0xFF0F172A);
const _kTextSecondary = Color(0xFF64748B);
const _kLowStockColor = Color(0xFFEF4444);
const _kInStockColor = Color(0xFF22C55E);
const _kWarningColor = Color(0xFFF59E0B);

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
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _dataSource = _ProductDataSource(onSelect: _showStockMovementBottomSheet);
    _loadProducts();

    // 🔌 Realtime listeners for Inventory Screen
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
    _searchDebounce = Timer(const Duration(milliseconds: 450), () {
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
                      color: _kPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.add_box, color: _kPrimary, size: 22),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'เพิ่มสินค้าใหม่',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _kTextPrimary,
                    ),
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
                        icon: Icons.qr_code,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'กรุณาระบุรหัส SKU' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: nameController,
                        label: 'ชื่อสินค้า *',
                        icon: Icons.shopping_bag_outlined,
                        validator: (v) =>
                            v == null || v.isEmpty ? 'กรุณาระบุชื่อสินค้า' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildFormField(
                        controller: priceController,
                        label: 'ราคาขาย (บาท) *',
                        icon: Icons.attach_money,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'กรุณาระบุราคา';
                          if (double.tryParse(v) == null) return 'ต้องเป็นตัวเลข';
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
                              icon: Icons.inventory,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  int.tryParse(v ?? '') == null
                                      ? 'ต้องเป็นตัวเลข'
                                      : null,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildFormField(
                              controller: minAlertController,
                              label: 'เตือนต่ำกว่า',
                              icon: Icons.warning_amber,
                              keyboardType: TextInputType.number,
                              validator: (v) =>
                                  int.tryParse(v ?? '') == null
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
                TextButton(
                  onPressed:
                      isSubmitting ? null : () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: _kTextSecondary),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(backgroundColor: _kPrimary),
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
                                minStockAlert:
                                    int.parse(minAlertController.text),
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
                                  e
                                      .toString()
                                      .replaceAll('Exception: ', ''),
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
                      : const Icon(Icons.save, size: 18),
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
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.vertical(top: Radius.circular(24)),
              ),
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
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
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 20),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [_kPrimary, _kPrimaryDark],
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.sync_alt,
                              color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: _kTextPrimary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'คงเหลือ: ${product.currentStock} ชิ้น  |  SKU: ${product.sku}',
                                style: const TextStyle(
                                    fontSize: 12, color: _kTextSecondary),
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
                            selectedColor: _kInStockColor,
                            onTap: () =>
                                setSheetState(() => selectedType = 'IN'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildTypeChip(
                            label: '➖ เบิกออก (OUT)',
                            isSelected: selectedType == 'OUT',
                            selectedColor: _kWarningColor,
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
                      icon: Icons.numbers,
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
                      icon: Icons.receipt_long,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: selectedType == 'IN'
                              ? _kInStockColor
                              : _kWarningColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: isSubmitting
                            ? null
                            : () async {
                                if (formKey.currentState!.validate()) {
                                  setSheetState(
                                      () => isSubmitting = true);
                                  try {
                                    await _apiService.recordStockMovement(
                                      productId: product.id,
                                      type: selectedType,
                                      quantity: int.parse(
                                          quantityController.text),
                                      referenceId:
                                          refController.text.trim(),
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
                                    setSheetState(
                                        () => isSubmitting = false);
                                    if (ctx.mounted) {
                                      _showSnackBar(
                                        e
                                            .toString()
                                            .replaceAll('Exception: ', ''),
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
                                    ? Icons.add_circle
                                    : Icons.remove_circle,
                                size: 20,
                              ),
                        label: Text(
                          selectedType == 'IN'
                              ? 'ยืนยันรับเข้าคลัง'
                              : 'ยืนยันเบิกออกตัดสต๊อก',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: isSelected
            ? selectedColor.withValues(alpha: 0.1)
            : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? selectedColor : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding:
              const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : _kTextSecondary,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showSnackBar(String message, {required bool isSuccess}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? _kInStockColor : _kLowStockColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // ============================================================
  // Build
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _kSurface,
      appBar: _buildAppBar(),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: _kPrimary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: _kPrimary,
      foregroundColor: Colors.white,
      elevation: 0,
      title: Consumer<AuthProvider>(
        builder: (context, auth, _) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📦 คลังสินค้า',
              style:
                  TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              '${auth.username} · ${auth.role}',
              style: const TextStyle(fontSize: 11, color: Colors.white70),
            ),
          ],
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.local_shipping_outlined),
          tooltip: 'รับสินค้าเข้า (Purchase Orders)',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PurchaseOrderScreen()),
          ).then((_) => _loadProducts()),
        ),
        Consumer<AuthProvider>(
          builder: (context, auth, _) {
            if (!auth.isManagerOrAdmin) return const SizedBox();
            return IconButton(
              icon: const Icon(Icons.bar_chart),
              tooltip: 'ดูรายงาน Dashboard',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DashboardScreen()),
              ),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.refresh),
          onPressed: () => _loadProducts(),
          tooltip: 'รีเฟรชข้อมูล',
        ),
        IconButton(
          icon: const Icon(Icons.logout),
          tooltip: 'ออกจากระบบ',
          onPressed: () => context.read<AuthProvider>().logout(),
        ),
        IconButton(
          icon: const Icon(Icons.point_of_sale,
              size: 26, color: Colors.amber),
          tooltip: 'เปิดบิลขายสินค้า (POS)',
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const PosScreen()),
          ).then((_) => _loadProducts()),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: _kPrimary),
            SizedBox(height: 16),
            Text(
              'กำลังโหลดข้อมูลคลังสินค้า...',
              style: TextStyle(color: _kTextSecondary),
            ),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _kLowStockColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.error_outline,
                    color: _kLowStockColor, size: 48),
              ),
              const SizedBox(height: 16),
              const Text(
                'เกิดข้อผิดพลาด',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: _kTextSecondary),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง'),
              ),
            ],
          ),
        ),
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: _onSearchChanged,
            decoration: InputDecoration(
              prefixIcon:
                  const Icon(Icons.search, color: _kTextSecondary),
              hintText: 'ค้นหาด้วย SKU หรือชื่อสินค้า...',
              hintStyle: const TextStyle(color: _kTextSecondary),
              filled: true,
              fillColor: _kSurface,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: _kPrimary, width: 1.5),
              ),
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
                height: 36,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _kSurface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _sortBy,
                    isDense: true,
                    style: const TextStyle(
                        color: _kTextPrimary, fontSize: 13),
                    icon: const Icon(Icons.swap_vert, size: 18),
                    items: const [
                      DropdownMenuItem(value: 'id', child: Text('รหัส')),
                      DropdownMenuItem(
                          value: 'name', child: Text('ชื่อ')),
                      DropdownMenuItem(
                          value: 'price', child: Text('ราคา')),
                      DropdownMenuItem(
                          value: 'currentStock', child: Text('สต๊อก')),
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
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: _kPrimary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _order == 'asc'
                        ? Icons.arrow_upward
                        : Icons.arrow_downward,
                    size: 18,
                    color: _kPrimary,
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
      duration: const Duration(milliseconds: 200),
      child: InkWell(
        onTap: () => _setStockStatus(value),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? bgColor : _kSurface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? textColor.withValues(alpha: 0.5) : Colors.grey.shade200,
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? textColor : _kTextSecondary,
              fontWeight:
                  isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 12,
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
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$_totalCount รายการ',
              style: const TextStyle(
                color: _kPrimary,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          if (_search.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kWarningColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(Icons.search,
                      size: 12, color: _kWarningColor),
                  const SizedBox(width: 4),
                  Text(
                    '"$_search"',
                    style: const TextStyle(
                        color: _kWarningColor, fontSize: 12),
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
                  strokeWidth: 2, color: _kPrimary),
            ),
            const SizedBox(width: 6),
            const Text('กำลังโหลด...',
                style: TextStyle(
                    fontSize: 11, color: _kTextSecondary)),
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
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined,
                size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              _search.isNotEmpty
                  ? 'ไม่พบสินค้าที่ค้นหา\n"$_search"'
                  : '📭 ยังไม่มีสินค้าในคลัง\nกดปุ่ม "+ เพิ่มสินค้า" ด้านล่างขวา',
              textAlign: TextAlign.center,
              style: const TextStyle(color: _kTextSecondary, fontSize: 14),
            ),
          ],
        ),
      );
    }

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Scrollbar(
        controller: _tableScrollController,
        thumbVisibility: true,
        child: SingleChildScrollView(
          controller: _tableScrollController,
          child: PaginatedDataTable(
            header: Row(
              children: [
                const Text(
                  'สินค้าในคลัง',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  'หน้า $_currentPage / $_totalPages',
                  style: const TextStyle(
                    color: _kTextSecondary,
                    fontSize: 12,
                  ),
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
            headingRowColor: WidgetStateProperty.all(
              const Color(0xFFF1F5F9),
            ),
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
              const DataColumn(
                label: Text(
                  'สถานะ',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary,
                  ),
                ),
              ),
            ],
            source: _dataSource,
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
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: isActive ? _kPrimary : _kTextPrimary,
            ),
          ),
          const SizedBox(width: 4),
          if (isActive)
            Icon(
              _order == 'asc'
                  ? Icons.arrow_upward
                  : Icons.arrow_downward,
              size: 14,
              color: _kPrimary,
            )
          else
            Icon(Icons.unfold_more,
                size: 14, color: Colors.grey.shade400),
        ],
      ),
    );
  }

  // ============================================================
  // Custom Pagination Bar
  // ============================================================

  Widget _buildPaginationBar() {
    return Container(
      color: Colors.white,
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
            onTap: _currentPage > 1
                ? () => _goToPage(_currentPage - 1)
                : null,
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
        buttons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: _kTextSecondary)),
        ));
      }
    }

    for (int i = start; i <= end; i++) {
      buttons.add(_buildPageNumBtn(i));
    }

    if (end < _totalPages) {
      if (end < _totalPages - 1) {
        buttons.add(const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4),
          child: Text('...', style: TextStyle(color: _kTextSecondary)),
        ));
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
          duration: const Duration(milliseconds: 200),
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isActive ? _kPrimary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: isActive
                ? null
                : Border.all(color: Colors.grey.shade200),
          ),
          alignment: Alignment.center,
          child: Text(
            '$page',
            style: TextStyle(
              color: isActive ? Colors.white : _kTextSecondary,
              fontWeight:
                  isActive ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavButton(
      {required IconData icon, required VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade200),
        ),
        alignment: Alignment.center,
        child: Icon(
          icon,
          size: 20,
          color: onTap != null ? _kPrimary : Colors.grey.shade300,
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
          return const Color(0xFFEFF6FF);
        }
        if (isOut) return const Color(0xFFFFF1F2).withValues(alpha: 0.3);
        if (isLow) return const Color(0xFFFFFBEB).withValues(alpha: 0.5);
        return null;
      }),
      cells: [
        DataCell(
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              product.sku,
              style: const TextStyle(
                fontSize: 12,
                fontFamily: 'monospace',
                color: Color(0xFF475569),
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
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF0F172A),
                  fontSize: 13,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                'แตะเพื่อปรับสต๊อก',
                style: TextStyle(
                    fontSize: 10, color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
        DataCell(
          Text(
            '฿${product.price.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Color(0xFF059669),
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
        ),
        DataCell(
          Text(
            '${product.currentStock}',
            style: TextStyle(
              color: isOut
                  ? const Color(0xFF94A3B8)
                  : isLow
                      ? const Color(0xFFDC2626)
                      : const Color(0xFF0F172A),
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
        DataCell(_buildStatusBadge(isOut, isLow)),
      ],
    );
  }

  Widget _buildStatusBadge(bool isOut, bool isLow) {
    if (isOut) {
      return _badge(
          'หมดสต๊อก', const Color(0xFF64748B), const Color(0xFFF1F5F9));
    }
    if (isLow) {
      return _badge(
          '⚠️ ใกล้หมด', const Color(0xFFDC2626), const Color(0xFFFEF2F2));
    }
    return _badge(
        '✓ ปกติ', const Color(0xFF16A34A), const Color(0xFFF0FDF4));
  }

  Widget _badge(String label, Color textColor, Color bgColor) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  @override
  bool get isRowCountApproximate => false;

  @override
  int get rowCount => _totalCount;

  @override
  int get selectedRowCount => 0;
}
