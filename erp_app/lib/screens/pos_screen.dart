import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/elegant_notification_service.dart';
import '../services/pdf_invoice_service.dart';
import '../widgets/skeleton_loader.dart';
import '../core/theme/index.dart';

class PosScreen extends StatefulWidget {
  const PosScreen({super.key});

  @override
  State<PosScreen> createState() => _PosScreenState();
}

class _PosScreenState extends State<PosScreen> {
  final ApiService _apiService = ApiService();
  final _customerController = TextEditingController(
    text: 'ลูกค้าทั่วไป (General Customer)',
  );

  List<Product> _products = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  // ตะกร้าสินค้า: เก็บ Map ของ { productId: { product: Product, quantity: int } }
  final Map<int, Map<String, dynamic>> _cart = {};

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  @override
  void dispose() {
    _customerController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() => _isLoading = true);
    try {
      final data = await _apiService.fetchProducts();
      setState(() {
        // กรองเอาเฉพาะสินค้าที่ยังมีของเหลือในคลังมาขาย
        _products = data.where((p) => p.currentStock > 0).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ElegantNotificationService.error(
          context,
          title: 'เกิดข้อมูล',
          description: 'ดึงข้อมูลสินค้าล้มเหลว: $e',
        );
      }
    }
  }

  // ฟังก์ชันหยิบใส่ตะกร้า
  void _addToCart(Product product) {
    setState(() {
      if (_cart.containsKey(product.id)) {
        // เช็คว่าถ้าหยิบเพิ่ม จะเกินสต๊อกที่มีในคลังไหม?
        if (_cart[product.id]!['quantity'] < product.currentStock) {
          _cart[product.id]!['quantity'] += 1;
        } else {
          ElegantNotificationService.warning(
            context,
            title: '🗐️ สตอกไม่เพิ่ม',
            description:
                'ไม่สามารถหยิบเพิ่มได้เนื่องจากสตอกมีเพิ่ม ${product.currentStock} ชิ้น',
          );
        }
      } else {
        _cart[product.id] = {'product': product, 'quantity': 1};
      }
    });
  }

  // ปรับจำนวนในตะกร้า
  void _updateQuantity(int productId, int delta) {
    setState(() {
      if (_cart.containsKey(productId)) {
        final currentQty = _cart[productId]!['quantity'] as int;
        final maxStock = (_cart[productId]!['product'] as Product).currentStock;
        final newQty = currentQty + delta;

        if (newQty <= 0) {
          _cart.remove(productId); // ถ้าลดเหลือ 0 ให้เอาออกจากตะกร้า
        } else if (newQty <= maxStock) {
          _cart[productId]!['quantity'] = newQty;
        }
      }
    });
  }

  // คำนวณราคารวมทั้งตะกร้า
  double get _totalAmount {
    double sum = 0;
    _cart.forEach((_, item) {
      final product = item['product'] as Product;
      final qty = item['quantity'] as int;
      sum += product.price * qty;
    });
    return sum;
  }

  // =========================================================================
  // ฟังก์ชันเปิดบิลคำสั่งซื้อ (ยิง API & พิมพ์ PDF)
  // =========================================================================
  Future<void> _handleCheckout() async {
    if (_cart.isEmpty) {
      ElegantNotificationService.warning(
        context,
        title: '📑 กรุณาเลือกสินค้า',
        description: 'กรุณาเลือกสินค้าลงตะกร้าก่อน',
      );
      return;
    }
    if (_customerController.text.trim().isEmpty) {
      ElegantNotificationService.warning(
        context,
        title: '📑 กรุณาระบุชื่อลูกค้า',
        description: 'กรุณาระบุชื่อลูกค้า',
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      // 1. เตรียม Items payload
      final List<Map<String, dynamic>> orderItemsPayload = _cart.values.map((
        item,
      ) {
        final product = item['product'] as Product;
        return {'productId': product.id, 'quantity': item['quantity']};
      }).toList();

      // 2. ยิง API เปิดบิลผ่าน ApiService (มี Token แนบอัตโนมัติ)
      final orderData = await _apiService.createOrder(
        customerName: _customerController.text.trim(),
        items: orderItemsPayload,
      );

      // 3. เตรียม PDF items
      final List<Map<String, dynamic>> pdfItems = _cart.values.map((item) {
        final product = item['product'] as Product;
        return {
          'sku': product.sku,
          'name': product.name,
          'quantity': item['quantity'],
          'unitPrice': product.price,
        };
      }).toList();

      final totalForPdf = _totalAmount; // เก็บค่าก่อน clear cart
      if (!mounted) return;
      final seller = context.read<AuthProvider>().username ?? 'Staff';
      final orderNo = orderData['orderNumber'] ?? 'INV-MOCK-001';

      // 4. เคลียร์ตะกร้าและรีเฟรชสต๊อก
      setState(() {
        _cart.clear();
        _isSubmitting = false;
      });
      _loadProducts();

      if (mounted) {
        ElegantNotificationService.success(
          context,
          title: '🎉 สำเร็จ!',
          description: 'เปิดบิล $orderNo สำเร็จ! กำลังสร้างไฟล์ PDF...',
        );
      }

      // 5. สร้าง PDF
      await PdfInvoiceService.generateAndPrintInvoice(
        orderNumber: orderNo,
        customerName: _customerController.text.trim(),
        totalAmount: totalForPdf,
        items: pdfItems,
        sellerName: seller,
      );
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ElegantNotificationService.error(
          context,
          title: 'เกิดข้อผิดพลาด',
          description: e.toString(),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const GridSkeletonLoader(itemCount: 12, crossAxisCount: 3)
          : LayoutBuilder(
              builder: (context, constraints) {
                // ถ้าเป็นหน้าจอกว้าง (เช่น Web Chrome) ให้แบ่งจอ ซ้าย-ขวา
                // ถ้าเป็นหน้าจอมือถือแคบๆ ให้เรียง บน-ล่าง
                final isWideScreen = constraints.maxWidth > 700;

                if (isWideScreen) {
                  return Row(
                    children: [
                      Expanded(flex: 3, child: _buildProductCatalog()),
                      const VerticalDivider(width: 1),
                      Expanded(flex: 2, child: _buildCartSection()),
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      Expanded(flex: 3, child: _buildProductCatalog()),
                      const Divider(height: 1),
                      Expanded(flex: 3, child: _buildCartSection()),
                    ],
                  );
                }
              },
            ),
    );
  }

  // ฝั่งซ้าย: รายการสินค้า
  Widget _buildProductCatalog() {
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.apps_rounded, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'เลือกสินค้าลงตะกร้า',
                style: AppTextStyles.headingLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.85,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final inCartQty = _cart[product.id]?['quantity'] ?? 0;
                final hasInCart = inCartQty > 0;

                return AnimatedContainer(
                  duration: AppDurations.fast,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: hasInCart ? AppColors.primary : AppColors.cardBorder,
                      width: hasInCart ? 2 : 1,
                    ),
                    boxShadow: AppShadows.cardShadow,
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _addToCart(product),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Stack(
                            alignment: Alignment.topRight,
                            children: [
                              CircleAvatar(
                                radius: 26,
                                backgroundColor: hasInCart
                                    ? AppColors.primary.withAlpha(20)
                                    : AppColors.muted,
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: hasInCart ? AppColors.primary : AppColors.mutedForeground,
                                  size: 24,
                                ),
                              ),
                              if (hasInCart)
                                CircleAvatar(
                                  radius: 11,
                                  backgroundColor: AppColors.success,
                                  child: Text(
                                    '$inCartQty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.name,
                            style: AppTextStyles.headingSmall,
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${product.price.toStringAsFixed(2)}',
                            style: AppTextStyles.kpiMedium.copyWith(
                              color: AppColors.success,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'เหลือ: ${product.currentStock} ชิ้น',
                            style: AppTextStyles.bodySmall,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ฝั่งขวา: ตะกร้าสินค้าและปุ่มเปิดบิล
  Widget _buildCartSection() {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(20),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.shopping_cart_outlined, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: 10),
              Text(
                'รายการคำสั่งซื้อปัจจุบัน',
                style: AppTextStyles.headingLarge,
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'ชื่อลูกค้า / บริษัท',
              prefixIcon: Icon(Icons.person_outline),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),

          // รายการในตะกร้า
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 48,
                          color: AppColors.mutedForeground.withAlpha(128),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ตะกร้าสินค้าว่างเปล่า\nกรุณาเลือกสินค้าจากฝั่งซ้าย',
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodySmall,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final key = _cart.keys.elementAt(index);
                      final item = _cart[key]!;
                      final product = item['product'] as Product;
                      final qty = item['quantity'] as int;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          title: Text(
                            product.name,
                            style: AppTextStyles.headingSmall,
                          ),
                          subtitle: Text(
                            '฿${product.price.toStringAsFixed(2)} x $qty = ฿${(product.price * qty).toStringAsFixed(2)}',
                            style: AppTextStyles.bodySmall,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.remove_circle_outline_rounded,
                                  color: AppColors.destructive,
                                ),
                                onPressed: () => _updateQuantity(product.id, -1),
                              ),
                              Text(
                                '$qty',
                                style: AppTextStyles.bodyMedium.copyWith(fontWeight: FontWeight.bold),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  color: AppColors.success,
                                ),
                                onPressed: () => _updateQuantity(product.id, 1),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
          const Divider(thickness: 2),

          // สรุปยอดและปุ่มจ่ายเงิน
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ยอดรวมทั้งสิ้น:',
                style: AppTextStyles.headingLarge,
              ),
              Text(
                '฿${_totalAmount.toStringAsFixed(2)}',
                style: AppTextStyles.kpiLarge.copyWith(
                  color: AppColors.success,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.white,
                elevation: 2,
              ),
              onPressed: _isSubmitting ? null : _handleCheckout,
              icon: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.print_outlined, size: 24),
              label: Text(
                _isSubmitting
                    ? 'กำลังบันทึกและสร้าง PDF...'
                    : 'ยืนยันคำสั่งซื้อ & พิมพ์ใบเสร็จ PDF',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
