import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/elegant_notification_service.dart';
import '../widgets/skeleton_loader.dart';
import '../core/theme/index.dart';
import '../core/widgets/erp_status_badge.dart';
import '../core/widgets/erp_section_header.dart';

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
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text('รับสินค้า: ${po['poNumber']}',
                      style: AppTextStyles.headingMedium),
                ),
              ],
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('ซัพพลายเออร์: ${po['supplier']['name']}',
                        style: AppTextStyles.bodyMedium),
                    const SizedBox(height: 12),
                    const Text(
                      'ตรวจนับของที่รับจริงให้ตรงกับใบ PO ก่อนยืนยัน',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
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
                              child: Text(
                                '${product['sku']} — ${product['name']}\nสั่ง: $ordered ชิ้น',
                                style: AppTextStyles.bodyMedium,
                              ),
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
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    if (!isComplete) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withAlpha(20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.destructive.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.warning_amber_outlined,
                                color: AppColors.destructive, size: 16),
                            AppSpacing.w(8),
                            Expanded(
                              child: Text(
                                'ยอดรับต้องตรงกับยอดสั่งทุกสินค้า จึงจะรับเข้าคลังได้',
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.destructive,
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton(
                onPressed: isSubmitting
                    ? null
                    : () => Navigator.pop(dialogContext),
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
                                .map(
                                  (item) => {
                                    'productId': item['productId'],
                                    'receivedQuantity': int.parse(
                                      controllers[item['productId'] as int]!
                                          .text,
                                    ),
                                  },
                                )
                                .toList(),
                          );
                          if (!context.mounted) return;
                          Navigator.pop(dialogContext);
                          ElegantNotificationService.success(
                            context,
                            title: '🎉 สำเร็จ!',
                            description:
                                'รับสินค้า ${po['poNumber']} เข้าคลังเรียบร้อย',
                          );
                          _loadPurchaseOrders();
                        } catch (error) {
                          setDialogState(() => isSubmitting = false);
                          if (context.mounted) {
                            ElegantNotificationService.error(
                              context,
                              title: 'เกิดข้อผิดพลาด',
                              description: error.toString().replaceFirst(
                                    'Exception: ',
                                    '',
                                  ),
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
                    : const Icon(Icons.inventory_2_outlined, size: 16),
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
      backgroundColor: AppColors.background,
      body: _isLoading
          ? const TableSkeletonLoader(rowCount: 6, columnCount: 4)
          : _errorMessage != null
              ? ErpErrorState(
                  message: _errorMessage!,
                  onRetry: _loadPurchaseOrders,
                )
              : Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
                      child: TextField(
                        onChanged: (value) => setState(() => _poSearch = value),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search),
                          labelText: 'ค้นหาเลขที่ PO',
                          hintText: 'กรอกเลข PO หรือเลขบิล...',
                        ),
                      ),
                    ),
                    Expanded(
                      child: visibleOrders.isEmpty
                          ? ErpEmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: _purchaseOrders.isEmpty
                                  ? 'ไม่มีใบ PO ที่รอรับสินค้า'
                                  : 'ไม่พบเลข PO ที่สแกน',
                              subtitle: _purchaseOrders.isEmpty
                                  ? 'ระบบเปิดใบ PO เสร็จสิ้นหมดแล้ว'
                                  : 'ตรวจสอบเลขอ้างอิงและลองใหม่อีกครั้ง',
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: visibleOrders.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                final po = visibleOrders[index];
                                final items = List<Map<String, dynamic>>.from(
                                  po['items'] as List,
                                );
                                return Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: AppColors.cardBorder),
                                    boxShadow: AppShadows.cardShadow,
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            const Icon(
                                              Icons.receipt_long_outlined,
                                              color: AppColors.primary,
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                po['poNumber'] as String,
                                                style: AppTextStyles.headingLarge,
                                              ),
                                            ),
                                            const ErpStatusBadge(
                                              status: ErpStatus.pending,
                                              customLabel: 'รอรับสินค้า',
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 12),
                                        RichText(
                                          text: TextSpan(
                                            style: AppTextStyles.bodyMedium,
                                            children: [
                                              const TextSpan(
                                                text: 'ซัพพลายเออร์: ',
                                                style: TextStyle(fontWeight: FontWeight.bold),
                                              ),
                                              TextSpan(
                                                text: '${po['supplier']['name']}',
                                              ),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          items
                                              .map((item) {
                                                final product =
                                                    item['product']
                                                        as Map<String, dynamic>;
                                                return '${product['name']} × ${item['orderQuantity']}';
                                              })
                                              .join(' • '),
                                          style: AppTextStyles.bodySmall,
                                        ),
                                        const SizedBox(height: 14),
                                        Align(
                                          alignment: Alignment.centerRight,
                                          child: ElevatedButton.icon(
                                            onPressed: () => _showReceiveDialog(po),
                                            icon: const Icon(Icons.qr_code_scanner_outlined, size: 18),
                                            label: const Text(
                                              'ตรวจ PO / รับสินค้า',
                                            ),
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
