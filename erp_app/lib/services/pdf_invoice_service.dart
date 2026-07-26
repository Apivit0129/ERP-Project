import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class PdfInvoiceService {
  // ฟังก์ชันสร้างและเปิดหน้าต่างพรีวิวพิมพ์ใบแจ้งหนี้/ใบเสร็จรับเงิน
  static Future<void> generateAndPrintInvoice({
    required String orderNumber,
    required String customerName,
    required double totalAmount,
    required List<Map<String, dynamic>> items,
    required String sellerName,
  }) async {
    final doc = pw.Document();

    // 💡 ดึงฟอนต์ไทยมาตรฐาน "Sarabun" จาก Google Fonts สำหรับพิมพ์ข้อความภาษาไทย
    final fontRegular = await PdfGoogleFonts.sarabunRegular();
    final fontBold = await PdfGoogleFonts.sarabunBold();

    // สไตล์ข้อความมาตรฐาน
    final styleRegular = pw.TextStyle(font: fontRegular, fontSize: 12);
    final styleBold = pw.TextStyle(
      font: fontBold,
      fontSize: 12,
      fontWeight: pw.FontWeight.bold,
    );
    final styleTitle = pw.TextStyle(
      font: fontBold,
      fontSize: 20,
      color: PdfColors.blue800,
    );

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ------------------------------------------
              // ส่วนหัวกระดาษ (Header)
              // ------------------------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ERP PORTFOLIO CO., LTD.', style: styleTitle),
                      pw.Text(
                        'ระบบบริหารจัดการทรัพยากรองค์กรแบบครบวงจร',
                        style: styleRegular,
                      ),
                      pw.Text(
                        'โทร: 02-123-4567 | อีเมล: contact@erpportfolio.com',
                        style: styleRegular,
                      ),
                    ],
                  ),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.blue50,
                      border: pw.Border.all(color: PdfColors.blue800, width: 2),
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                    ),
                    child: pw.Text(
                      'ใบส่งสินค้า / ใบเสร็จรับเงิน\nINVOICE',
                      style: styleBold,
                      textAlign: pw.TextAlign.center,
                    ),
                  ),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Divider(thickness: 1, color: PdfColors.grey400),
              pw.SizedBox(height: 16),

              // ------------------------------------------
              // ข้อมูลลูกค้าและเลขบิล (Customer & Order Info)
              // ------------------------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('ลูกค้า (Customer):', style: styleBold),
                      pw.Text(customerName, style: styleRegular),
                      pw.Text(
                        'วันที่สั่งซื้อ: ${DateTime.now().toString().substring(0, 10)}',
                        style: styleRegular,
                      ),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('เลขที่บิล (Order No.):', style: styleBold),
                      pw.Text(
                        orderNumber,
                        style: styleBold.copyWith(
                          color: PdfColors.blue800,
                          fontSize: 14,
                        ),
                      ),
                      pw.Text('พนักงานขาย: $sellerName', style: styleRegular),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 24),

              // ------------------------------------------
              // ตารางรายการสินค้า (Item Table)
              // ------------------------------------------
              pw.Table.fromTextArray(
                headers: [
                  'ลำดับ',
                  'รหัส SKU',
                  'รายการสินค้า',
                  'จำนวน',
                  'ราคา/หน่วย',
                  'รวมเป็นเงิน (บาท)',
                ],
                data: List<List<String>>.generate(items.length, (index) {
                  final item = items[index];
                  final total = item['quantity'] * item['unitPrice'];
                  return [
                    '${index + 1}',
                    item['sku'].toString(),
                    item['name'].toString(),
                    '${item['quantity']}',
                    '฿${item['unitPrice'].toStringAsFixed(2)}',
                    '฿${total.toStringAsFixed(2)}',
                  ];
                }),
                headerStyle: pw.TextStyle(
                  font: fontBold,
                  fontSize: 11,
                  color: PdfColors.white,
                ),
                headerDecoration: const pw.BoxDecoration(
                  color: PdfColors.blue800,
                ),
                cellStyle: styleRegular,
                cellAlignment: pw.Alignment.centerLeft,
                cellAlignments: {
                  0: pw.Alignment.center,
                  1: pw.Alignment.center,
                  3: pw.Alignment.centerRight,
                  4: pw.Alignment.centerRight,
                  5: pw.Alignment.centerRight,
                },
                border: pw.TableBorder.all(color: PdfColors.grey300),
              ),
              pw.SizedBox(height: 20),

              // ------------------------------------------
              // สรุปยอดเงินรวม (Total Amount)
              // ------------------------------------------
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.end,
                children: [
                  pw.Container(
                    width: 250,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(
                        pw.Radius.circular(8),
                      ),
                      border: pw.Border.all(color: PdfColors.grey400),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('ยอดสุทธิ (Grand Total):', style: styleBold),
                        pw.Text(
                          '฿${totalAmount.toStringAsFixed(2)}',
                          style: styleBold.copyWith(
                            color: PdfColors.blue800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              pw.Spacer(),

              // ------------------------------------------
              // ส่วนท้ายกระดาษ (Footer & Signatures)
              // ------------------------------------------
              pw.Divider(color: PdfColors.grey300),
              pw.SizedBox(height: 16),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
                children: [
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 120,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('ผู้ส่งสินค้า / พนักงานขาย', style: styleRegular),
                    ],
                  ),
                  pw.Column(
                    children: [
                      pw.Container(
                        width: 120,
                        height: 1,
                        color: PdfColors.black,
                      ),
                      pw.SizedBox(height: 4),
                      pw.Text('ผู้รับสินค้า / ลูกค้า', style: styleRegular),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 12),
              pw.Center(
                child: pw.Text(
                  'ขอบคุณที่ใช้บริการระบบ ERP Portfolio',
                  style: pw.TextStyle(
                    font: fontRegular,
                    fontSize: 10,
                    color: PdfColors.grey600,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    // ⭐ เรียกหน้าต่างพรีวิวและดาวน์โหลด PDF ขึ้นมาบนจอของ Flutter / Chrome ทันที
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => doc.save(),
      name: 'Invoice-$orderNumber.pdf',
    );
  }
}
