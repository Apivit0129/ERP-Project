class Product {
  final int id;
  final String sku;
  final String name;
  final double price;
  final int currentStock;
  final int minStockAlert;

  // Constructor
  Product({
    required this.id,
    required this.sku,
    required this.name,
    required this.price,
    required this.currentStock,
    required this.minStockAlert,
  });

  // Factory Method: มีหน้าที่รับก้อน JSON (Map) จาก API แล้วแปลงกลับมาเป็น Object Product
  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'],
      sku: json['sku'],
      name: json['name'],
      // หมายเหตุ SA: ค่า Decimal ใน Prisma เมื่อส่งเป็น JSON อาจมาเป็น String หรือ Number
      // เราจึงต้องแปลงด้วย double.parse(json['price'].toString()) เพื่อความชัวร์ 100%
      price: double.parse(json['price'].toString()),
      currentStock: json['currentStock'],
      minStockAlert: json['minStockAlert'],
    );
  }

  // ฟังก์ชันช่วยเช็คว่าสินค้านี้ "ใกล้หมดสต๊อก" หรือยัง? (Business Logic สำหรับ UI)
  bool get isLowStock => currentStock <= minStockAlert;
  // ฟังก์ชันช่วยคำนวณมูลค่าสต๊อกสินค้าชิ้นนี้รวมทั้งหมด (ราคา x จำนวนชิ้น) - สำหรับ Dashboard ผู้บริหาร
  double get totalValue => price * currentStock;
}
