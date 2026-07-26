import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'dashboard_screen.dart';
import 'pos_screen.dart';
import 'package:flutter/material.dart';
import '../models/product.dart';
import '../services/api_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final ApiService _apiService = ApiService();

  bool _isLoading = true;
  String? _errorMessage;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
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

  // =========================================================================
  // ฟังก์ชันแสดง Pop-up Dialog สำหรับกรอกข้อมูลสินค้าใหม่ (UI Form & Validation)
  // =========================================================================
  void _showAddProductDialog() {
    final formKey = GlobalKey<FormState>();

    // ตัวควบคุมการอ่านค่าจากช่องกรอกข้อความ (TextField Controllers)
    final skuController = TextEditingController();
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController(
      text: '0',
    ); // ตั้งค่าเริ่มต้นเป็น 0
    final minAlertController = TextEditingController(
      text: '10',
    ); // ตั้งค่าเริ่มต้นเป็น 10

    bool isSubmitting =
        false; // เอาไว้หมุนสปินเนอร์ปุ่มกดตอนกำลังส่งข้อมูลไป DB

    showDialog(
      context: context,
      barrierDismissible:
          false, // บังคับให้ผู้ใช้กดปุ่มบันทึกหรือยกเลิกเท่านั้น (กดพื้นหลังเพื่อปิดไม่ได้)
      builder: (ctx) {
        // ใช้ StatefulBuilder เพื่อให้เราสามารถเปลี่ยนสถานะปุ่ม (กดแล้วหมุนรอ) ภายใน Dialog ได้
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Row(
                children: [
                  Icon(Icons.add_box, color: Colors.blueAccent),
                  SizedBox(width: 8),
                  Text(
                    'เพิ่มสินค้าใหม่เข้าคลัง',
                    style: TextStyle(fontSize: 18),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ช่องที่ 1: รหัส SKU
                      TextFormField(
                        controller: skuController,
                        decoration: const InputDecoration(
                          labelText: 'รหัส SKU (บาร์โค้ด) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.qr_code),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'กรุณาระบุรหัส SKU'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ช่องที่ 2: ชื่อสินค้า
                      TextFormField(
                        controller: nameController,
                        decoration: const InputDecoration(
                          labelText: 'ชื่อสินค้า *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.shopping_bag_outlined),
                        ),
                        validator: (value) => value == null || value.isEmpty
                            ? 'กรุณาระบุชื่อสินค้า'
                            : null,
                      ),
                      const SizedBox(height: 12),

                      // ช่องที่ 3: ราคา
                      TextFormField(
                        controller: priceController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        decoration: const InputDecoration(
                          labelText: 'ราคาขาย (บาท) *',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.attach_money),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'กรุณาระบุราคา';
                          }
                          if (double.tryParse(value) == null) {
                            return 'กรุณากรอกตัวเลขให้ถูกต้อง';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // ช่องที่ 4 & 5: สต๊อกเริ่มต้น และ จุดแจ้งเตือน (วางคู่กันในแถวเดียว)
                      Row(
                        children: [
                          Expanded(
                            child: TextFormField(
                              controller: stockController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'สต๊อกเริ่มต้น',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  int.tryParse(value ?? '') == null
                                  ? 'ต้องเป็นตัวเลข'
                                  : null,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: TextFormField(
                              controller: minAlertController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'เตือนเมื่อต่ำกว่า',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  int.tryParse(value ?? '') == null
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
                // ปุ่มยกเลิก
                TextButton(
                  onPressed: isSubmitting
                      ? null
                      : () => Navigator.of(ctx).pop(),
                  child: const Text(
                    'ยกเลิก',
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                // ปุ่มบันทึกข้อมูล
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blueAccent,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isSubmitting
                      ? null // ถ้ากำลังส่งข้อมูลอยู่ให้ Disable ปุ่มไว้ป้องกันการกดซ้ำซ้อน
                      : () async {
                          // 1. ตรวจสอบความถูกต้องของฟอร์ม (Form Validation)
                          if (formKey.currentState!.validate()) {
                            setDialogState(
                              () => isSubmitting = true,
                            ); // เริ่มหมุนตัวโหลด

                            try {
                              // 2. ยิง API บันทึกลง PostgreSQL ผ่าน ApiService
                              await _apiService.createProduct(
                                sku: skuController.text.trim(),
                                name: nameController.text.trim(),
                                price: double.parse(priceController.text),
                                currentStock: int.parse(stockController.text),
                                minStockAlert: int.parse(
                                  minAlertController.text,
                                ),
                              );

                              // 3. ปิด Pop-up แล้วโหลดข้อมูลใหม่จาก DB ขึ้นมาแสดงทันที
                              if (ctx.mounted) {
                                Navigator.of(ctx).pop();
                                _loadProducts(); // รีเฟรชหน้าจอ

                                // แสดงข้อความแจ้งเตือนสีเขียวด้านล่างจอ (SnackBar)
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      '🎉 บันทึกสินค้าลง Database เรียบร้อยแล้ว!',
                                    ),
                                    backgroundColor: Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            } catch (e) {
                              // ถ้ามี Error (เช่น กรอก SKU ซ้ำ) ให้แจ้งเตือนสีแดง
                              setDialogState(() => isSubmitting = false);
                              if (ctx.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      e.toString().replaceAll(
                                        'Exception: ',
                                        '',
                                      ),
                                    ),
                                    backgroundColor: Colors.red,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            }
                          }
                        },
                  child: isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Text('บันทึกข้อมูล'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<AuthProvider>(
          builder: (context, auth, _) =>
              Text('📦 คลังสินค้า (${auth.username} - ${auth.role})'),
        ),
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        actions: [
          // ⭐ จุดขาย RBAC: ถ้าเป็น Manager หรือ Admin ให้แสดงปุ่ม "ดูรายงาน Dashboard"
          // ถ้าเป็นพนักงาน Staff ปุ่มนี้จะหายไปโดยอัตโนมัติ!
          Consumer<AuthProvider>(
            builder: (context, auth, _) {
              if (auth.isManagerOrAdmin) {
                return IconButton(
                  icon: const Icon(Icons.bar_chart),
                  tooltip: 'สำหรับผู้จัดการ: ดูรายงาน Dashboard',
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const DashboardScreen(),
                      ),
                    );
                  },
                );
              }
              return const SizedBox(); // ถ้าไม่ใช่ Manager ไม่ต้องโชว์ปุ่ม
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProducts,
            tooltip: 'รีเฟรชข้อมูล',
          ),
          // ปุ่ม ล็อกเอาท์ (Logout)
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'ออกจากระบบ',
            onPressed: () {
              context
                  .read<AuthProvider>()
                  .logout(); // กดปุ่มแล้วระบบจะดีดกลับหน้า Login ทันที
            },
          ),
          // 💡 ปุ่มเข้าหน้า POS / เปิดบิลคำสั่งซื้อ (เข้าได้ทั้งพนักงานและผู้จัดการ)
          IconButton(
            icon: const Icon(
              Icons.point_of_sale,
              size: 28,
              color: Colors.amber,
            ),
            tooltip: 'เปิดบิลขายสินค้า (POS / Sales Order)',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PosScreen()),
              ).then(
                (_) => _loadProducts(),
              ); // ปิดหน้าขายของกลับมา ให้รีเฟรชสต๊อกในคลังเสมอ
            },
          ),
        ],
      ),
      body: _buildBody(),
      // 💡 เพิ่ม Floating Action Button มุมขวาล่างของหน้าจอตรงนี้ครับ
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddProductDialog,
        backgroundColor: Colors.blueAccent,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'เพิ่มสินค้า',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('กำลังโหลดข้อมูลคลังสินค้า...'),
          ],
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              Text(
                'เกิดข้อผิดพลาด:\n$_errorMessage',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadProducts,
                icon: const Icon(Icons.refresh),
                label: const Text('ลองใหม่อีกครั้ง (Retry)'),
              ),
            ],
          ),
        ),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          '📭 ยังไม่มีสินค้าในคลัง\nกดปุ่ม "+ เพิ่มสินค้า" ด้านล่างขวาเพื่อเพิ่มชิ้นแรกได้เลยครับ!',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(
        left: 12,
        top: 12,
        right: 12,
        bottom: 80,
      ), // เผื่อพื้นที่ด้านล่างไม่ให้บังปุ่ม FAB
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final product = _products[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      // 💡 ห่อด้วย InkWell เพื่อให้แตะที่การ์ดแล้วเรียก Bottom Sheet ปรับสต๊อกขึ้นมา
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _showStockMovementBottomSheet(
          product,
        ), // เรียกฟังก์ชันที่เราเพิ่งสร้าง!
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: product.isLowStock
                    ? Colors.red.shade100
                    : Colors.blue.shade100,
                child: Icon(
                  product.isLowStock
                      ? Icons.warning_amber_rounded
                      : Icons.inventory_2_outlined,
                  color: product.isLowStock ? Colors.red : Colors.blue,
                  size: 30,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'SKU: ${product.sku}  👆 (แตะเพื่อเบิก/รับของ)', // เพิ่มคำแนะนำเล็กๆ ให้ผู้ใช้รู้ว่ากดได้
                      style: TextStyle(
                        color: Colors.blue.shade700,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'ราคา: ฿${product.price.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${product.currentStock}',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: product.isLowStock ? Colors.red : Colors.black87,
                    ),
                  ),
                  Text(
                    'ชิ้นในคลัง',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                  ),
                  if (product.isLowStock)
                    Container(
                      margin: const EdgeInsets.only(top: 6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Text(
                        'สต๊อกต่ำ!',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================================================================
  // ฟังก์ชันแสดง Bottom Sheet สำหรับรับของเข้า/เบิกของออก (Stock Movement UI)
  // =========================================================================
  void _showStockMovementBottomSheet(Product product) {
    final formKey = GlobalKey<FormState>();
    final quantityController = TextEditingController();
    final refController = TextEditingController(
      text:
          'PO-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
    ); // สุ่มเลขบิลจำลอง

    String selectedType = 'OUT'; // ตั้งค่าเริ่มต้นให้เป็นการ "เบิกของออก (ขาย)"
    bool isSubmitting = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled:
          true, // ทำให้ถาดเลื่อนขยายขึ้นตามคีย์บอร์ดได้ ไม่โดนคีย์บอร์ดบัง
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              // ดันพื้นที่ด้านล่างหลบคีย์บอร์ดของมือถือ
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // หัวข้อบอกชื่อสินค้าและสต๊อกปัจจุบัน
                    Row(
                      children: [
                        const Icon(
                          Icons.sync_alt,
                          color: Colors.blueAccent,
                          size: 28,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'จัดการสต๊อก: ${product.name}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'คงเหลือในคลังปัจจุบัน: ${product.currentStock} ชิ้น',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Divider(height: 24),

                    // ตัวเลือกประเภท: รับของเข้า (IN) vs เบิกของออก (OUT)
                    const Text(
                      'เลือกการกระทำ:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // ปุ่มรับของเข้า (IN - สีเขียว)
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text('➕ รับของเข้า (IN)'),
                            ),
                            selected: selectedType == 'IN',
                            selectedColor: Colors.green.shade100,
                            labelStyle: TextStyle(
                              color: selectedType == 'IN'
                                  ? Colors.green.shade800
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) =>
                                setSheetState(() => selectedType = 'IN'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        // ปุ่มเบิกของออก (OUT - สีส้มแดง)
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(
                              child: Text('➖ เบิกออก/ขาย (OUT)'),
                            ),
                            selected: selectedType == 'OUT',
                            selectedColor: Colors.orange.shade100,
                            labelStyle: TextStyle(
                              color: selectedType == 'OUT'
                                  ? Colors.orange.shade800
                                  : Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                            onSelected: (val) =>
                                setSheetState(() => selectedType = 'OUT'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // ช่องกรอกจำนวนสินค้า
                    TextFormField(
                      controller: quantityController,
                      keyboardType: TextInputType.number,
                      autofocus:
                          true, // เปิดคีย์บอร์ดเด้งรอทันทีเพื่อความรวดเร็ว
                      decoration: InputDecoration(
                        labelText: selectedType == 'IN'
                            ? 'จำนวนที่ต้องการรับเข้า (ชิ้น) *'
                            : 'จำนวนที่ต้องการเบิกออก (ชิ้น) *',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.numbers),
                      ),
                      validator: (val) {
                        if (val == null || val.isEmpty) {
                          return 'กรุณาระบุจำนวน';
                        }
                        final num = int.tryParse(val);
                        if (num == null || num <= 0) {
                          return 'จำนวนต้องเป็นตัวเลขมากกว่า 0';
                        }
                        // Validation สไตล์ SA: ถ้าเบิกออก ต้องเช็คด้วยว่าเบิกเกินสต๊อกที่มีไหม?
                        if (selectedType == 'OUT' &&
                            num > product.currentStock) {
                          return 'สต๊อกไม่พอ! (เบิกได้สูงสุด ${product.currentStock} ชิ้น)';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),

                    // ช่องรหัสอ้างอิงบิล (Audit Trail Reference)
                    TextFormField(
                      controller: refController,
                      decoration: const InputDecoration(
                        labelText: 'เลขอ้างอิงบิล / เหตุผล (Reference ID)',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.receipt_long),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ปุ่มกดบันทึกการทำรายการ
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: selectedType == 'IN'
                              ? Colors.green
                              : Colors.orange.shade800,
                          foregroundColor: Colors.white,
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
                                      Navigator.of(
                                        ctx,
                                      ).pop(); // ปิด Bottom Sheet
                                      _loadProducts(); // รีเฟรชหน้าจอตารางสินค้า

                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            selectedType == 'IN'
                                                ? '📦 รับของเข้าสต๊อก ${quantityController.text} ชิ้น เรียบร้อย!'
                                                : '🚀 เบิกของออก ${quantityController.text} ชิ้น เรียบร้อย!',
                                          ),
                                          backgroundColor: selectedType == 'IN'
                                              ? Colors.green
                                              : Colors.orange.shade800,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  } catch (e) {
                                    setSheetState(() => isSubmitting = false);
                                    if (ctx.mounted) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString().replaceAll(
                                              'Exception: ',
                                              '',
                                            ),
                                          ),
                                          backgroundColor: Colors.red,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  }
                                }
                              },
                        child: isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
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
}
