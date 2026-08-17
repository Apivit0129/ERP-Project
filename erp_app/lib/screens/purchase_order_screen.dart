import 'package:flutter/material.dart';
import '../services/api_service.dart';

class PurchaseOrderScreen extends StatefulWidget {
  const PurchaseOrderScreen({super.key});

  @override
  State<PurchaseOrderScreen> createState() => _PurchaseOrderScreenState();
}

class _PurchaseOrderScreenState extends State<PurchaseOrderScreen> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _purchaseOrders = [];
  String _poSearch = '';

  @override
  void initState() {
    super.initState();
    _loadPurchaseOrders();
  }

  Future<void> _loadPurchaseOrders() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final orders = await _apiService.fetchPurchaseOrders(status: 'PENDING');
      if (!mounted) return;
      setState(() {
        _purchaseOrders = orders;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString().replaceFirst('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  void _showReceiveDialog(Map<String, dynamic> po) {
    final items = List<Map<String, dynamic>>.from(po['items'] as List);
    final controllers = <int, TextEditingController>{
      for (final item in items)
        item['productId'] as int: TextEditingController(
          text: item['orderQuantity'].toString(),
        ),
    };
    bool isSubmitting = false;

    showDialog(
      context: context,
      barrierDismissible: !isSubmitting,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isComplete = items.every((item) {
            final received = int.tryParse(
              controllers[item['productId'] as int]!.text,
            );
            return received == item['orderQuantity'];
          });
          return AlertDialog(
            title: Text('รับสินค้า: ${po['poNumber']}'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ซัพพลายเออร์: ${po['supplier']['name']}'),
                    const SizedBox(height: 12),
                    const Text(
                      'ตรวจนับของที่รับจริงให้ตรงกับใบ PO ก่อนยืนยัน',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    ...items.map((item) {
                      final product = item['product'] as Map<String, dynamic>;
                      final ordered = item['orderQuantity'] as int;
                      final controller = controllers[item['productId'] as int]!;
                      final received = int.tryParse(controller.text);
                      final mismatch = received != null && received != ordered;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text('${product['sku']} — ${product['name']}\nสั่ง: $ordered ชิ้น'),
                            ),
                            const SizedBox(width: 12),
                            SizedBox(
                              width: 130,
                              child: TextFormField(
                                controller: controller,
                                keyboardType: TextInputType.number,
                                onChanged: (_) => setDialogState(() {}),
                                decoration: InputDecoration(
                                  labelText: 'รับจริง',
                                  errorText: mismatch ? 'ไม่ตรง PO' : null,
                                  border: const OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (!isComplete)
                      const Text(
                        'ยอดรับต้องตรงกับยอดสั่งทุกสินค้า จึงจะรับเข้าคลังได้',
                        style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                      ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: isSubmitting ? null : () => Navigator.pop(dialogContext),
                child: const Text('ยกเลิก'),
              ),
              ElevatedButton.icon(
                onPressed: isSubmitting || !isComplete
                    ? null
                    : () async {
                        setDialogState(() => isSubmitting = true);
                        try {
                          await _apiService.receivePurchaseOrder(
                            po['id'] as int,
                            items
                                .map((item) => {
                                      'productId': item['productId'],
                                      'receivedQuantity': int.parse(
                                        controllers[item['productId'] as int]!.text,
                                      ),
                                    })
                                .toList(),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(dialogContext);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('รับสินค้า ${po['poNumber']} เข้าคลังเรียบร้อย'),
                              backgroundColor: Colors.green,
                            ),
                          );
                          _loadPurchaseOrders();
                        } catch (error) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(error.toString().replaceFirst('Exception: ', '')),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      },
                icon: isSubmitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.inventory),
                label: const Text('ยืนยันรับของเข้าคลัง'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleOrders = _purchaseOrders.where((po) {
      return po['poNumber'].toString().toLowerCase().contains(
        _poSearch.trim().toLowerCase(),
      );
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('รับสินค้าเข้า — Purchase Orders'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'รีเฟรชรายการ PO',
            onPressed: _loadPurchaseOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text(_errorMessage!, style: const TextStyle(color: Colors.red)))
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: TextField(
                        onChanged: (value) => setState(() => _poSearch = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.qr_code_scanner),
                          labelText: 'สแกนหรือกรอกเลข PO เพื่อค้นหา',
                          hintText: 'เช่น PO-176...',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    Expanded(
                      child: visibleOrders.isEmpty
                          ? Center(
                              child: Text(
                                _purchaseOrders.isEmpty
                                    ? 'ไม่มีใบ PO ที่รอรับสินค้า'
                                    : 'ไม่พบเลข PO ที่สแกน',
                                style: const TextStyle(fontSize: 16),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: visibleOrders.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final po = visibleOrders[index];
                        final items = List<Map<String, dynamic>>.from(po['items'] as List);
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.receipt_long, color: Colors.indigo),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        po['poNumber'] as String,
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                    const Chip(label: Text('รอรับสินค้า')),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text('ซัพพลายเออร์: ${po['supplier']['name']}'),
                                const SizedBox(height: 4),
                                Text(items.map((item) {
                                  final product = item['product'] as Map<String, dynamic>;
                                  return '${product['name']} × ${item['orderQuantity']}';
                                }).join(' • ')),
                                const SizedBox(height: 14),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: ElevatedButton.icon(
                                    onPressed: () => _showReceiveDialog(po),
                                    icon: const Icon(Icons.qr_code_scanner),
                                    label: const Text('ตรวจ PO / รับสินค้า'),
                                  ),
                                ),
                              ],
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
}
