import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';
import '../services/pdf_invoice_service.dart';

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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('ดึงข้อมูลสินค้าล้มเหลว: $e'),
            backgroundColor: Colors.red,
          ),
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
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'ไม่สามารถหยิบเพิ่มได้เนื่องจากสต๊อกมีเพียง ${product.currentStock} ชิ้น',
              ),
              backgroundColor: Colors.orange,
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาเลือกสินค้าลงตะกร้าก่อน'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_customerController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('กรุณาระบุชื่อลูกค้า'),
          backgroundColor: Colors.orange,
        ),
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
      final seller = context.read<AuthProvider>().username ?? 'Staff';
      final orderNo = orderData['orderNumber'] ?? 'INV-MOCK-001';

      // 4. เคลียร์ตะกร้าและรีเฟรชสต๊อก
      setState(() {
        _cart.clear();
        _isSubmitting = false;
      });
      _loadProducts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 เปิดบิล $orderNo สำเร็จ! กำลังสร้างไฟล์ PDF...'),
            backgroundColor: Colors.green,
          ),
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('เกิดข้อผิดพลาด: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🛒 เปิดบิลคำสั่งซื้อ (Sales Order & POS)'),
        backgroundColor: const Color(0xFF1E293B),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
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
      color: const Color(0xFFF8FAFC),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '📦 เลือกสินค้าลงตะกร้า (แตะที่สินค้า)',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                childAspectRatio: 0.9,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: _products.length,
              itemBuilder: (context, index) {
                final product = _products[index];
                final inCartQty = _cart[product.id]?['quantity'] ?? 0;

                return Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
                              const CircleAvatar(
                                radius: 28,
                                backgroundColor: Color(0xFFE3F2FD),
                                child: Icon(
                                  Icons.shopping_bag,
                                  color: Colors.blueAccent,
                                  size: 28,
                                ),
                              ),
                              if (inCartQty > 0)
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: Colors.green,
                                  child: Text(
                                    '$inCartQty',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            product.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                            textAlign: TextAlign.center,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '฿${product.price.toStringAsFixed(2)}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            'เหลือ: ${product.currentStock} ชิ้น',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
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
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '🧾 รายการคำสั่งซื้อปัจจุบัน',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _customerController,
            decoration: const InputDecoration(
              labelText: 'ชื่อลูกค้า / บริษัท',
              prefixIcon: Icon(Icons.person),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Divider(),

          // รายการในตะกร้า
          Expanded(
            child: _cart.isEmpty
                ? const Center(
                    child: Text(
                      'ตะกร้าสินค้าว่างเปล่า\nกรุณาเลือกสินค้าจากฝั่งซ้าย',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final key = _cart.keys.elementAt(index);
                      final item = _cart[key]!;
                      final product = item['product'] as Product;
                      final qty = item['quantity'] as int;

                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          product.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                        subtitle: Text(
                          '฿${product.price.toStringAsFixed(2)} x $qty = ฿${(product.price * qty).toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _updateQuantity(product.id, -1),
                            ),
                            Text(
                              '$qty',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.add_circle_outline,
                                color: Colors.green,
                              ),
                              onPressed: () => _updateQuantity(product.id, 1),
                            ),
                          ],
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
              const Text(
                'ยอดรวมทั้งสิ้น:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                '฿${_totalAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.green,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                elevation: 4,
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
                  : const Icon(Icons.print, size: 26),
              label: Text(
                _isSubmitting
                    ? 'กำลังบันทึกและสร้าง PDF...'
                    : 'ยืนยันคำสั่งซื้อ & พิมพ์ใบเสร็จ PDF',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
