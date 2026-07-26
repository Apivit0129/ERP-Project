require('dotenv').config(); // 💡 โหลด .env ก่อนทุกอย่าง!
const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('./db');
const { authenticateToken, authorizeRoles, SECRET_KEY } = require('./auth'); // 💡 เรียกใช้พี่การ์ดตรวจบัตร

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

// =========================================================================
// โซนที่ 1: Authentication API (ระบบสมัครสมาชิก และ ล็อกอิน)
// =========================================================================

// 1.1 API สมัครสมาชิก (สร้าง User จำลองเพื่อใช้เทสระบบ)
app.post('/api/auth/register', async (req, res) => {
  try {
    const { username, password, role } = req.body;

    // ✅ Validation: ตรวจสอบ username และ password ไม่ว่างเปล่า
    if (!username || !password) {
      return res.status(400).json({ 
        success: false, 
        message: "กรุณาระบุ username และ password" 
      });
    }

    // ✅ Validation: ตรวจสอบความยาว username (4-20 ตัวอักษร)
    if (username.length < 4 || username.length > 20) {
      return res.status(400).json({ 
        success: false, 
        message: "ชื่อผู้ใช้ต้องมีความยาว 4-20 ตัวอักษร" 
      });
    }

    // ✅ Validation: ตรวจสอบว่า username เป็นตัวอักษร และตัวเลขเท่านั้น
    if (!/^[a-zA-Z0-9_]+$/.test(username)) {
      return res.status(400).json({ 
        success: false, 
        message: "ชื่อผู้ใช้ต้องประกอบด้วยตัวอักษร ตัวเลข และ underscore เท่านั้น" 
      });
    }

    // ✅ Validation: ตรวจสอบความยาวรหัสผ่าน (อย่างน้อย 6 ตัว)
    if (password.length < 6) {
      return res.status(400).json({ 
        success: false, 
        message: "รหัสผ่านต้องมีความยาวอย่างน้อย 6 ตัวอักษร" 
      });
    }

    // ✅ Validation: ตรวจสอบ role ถูกต้อง (ถ้ามีการระบุ)
    const validRoles = ['ADMIN', 'MANAGER', 'WAREHOUSE_STAFF'];
    if (role && !validRoles.includes(role)) {
      return res.status(400).json({ 
        success: false, 
        message: `Role ต้องเป็นหนึ่งใน: ${validRoles.join(', ')}` 
      });
    }

    // เช็คว่ามี username ซ้ำไหม
    const existingUser = await prisma.user.findUnique({ where: { username } });
    if (existingUser) {
      return res.status(400).json({ 
        success: false, 
        message: "ชื่อผู้ใช้นี้มีในระบบแล้ว" 
      });
    }

    // เข้ารหัสผ่านก่อนลง DB (Never save plain text password!)
    const hashedPassword = await bcrypt.hash(password, 10);

    const newUser = await prisma.user.create({
      data: {
        username: username,
        passwordHash: hashedPassword,
        role: role || 'WAREHOUSE_STAFF' // ถ้าไม่ระบุ ให้เป็นพนักงานคลังสินค้า
      }
    });

    res.status(201).json({ 
      success: true, 
      message: "สร้างบัญชีสำเร็จ!", 
      data: { 
        id: newUser.id, 
        username: newUser.username, 
        role: newUser.role 
      } 
    });
  } catch (error) {
    console.error('[register error]', error); // 💡 ดู error จริงใน terminal
    res.status(500).json({ 
      success: false, 
      message: "เกิดข้อผิดพลาดในการสร้างบัญชี", 
      error: error.message 
    });
  }
});

// 1.2 API ล็อกอิน (ตรวจสอบรหัสผ่าน และออกบัตร JWT)
app.post('/api/auth/login', async (req, res) => {
  try {
    const { username, password } = req.body;
    const user = await prisma.user.findUnique({ where: { username } });

    // ถ้าไม่พบ user หรือรหัสผ่านไม่ตรงกัน
    if (!user || !(await bcrypt.compare(password, user.passwordHash))) {
      return res.status(401).json({ success: false, message: "ชื่อผู้ใช้หรือรหัสผ่านไม่ถูกต้อง" });
    }

    // สร้างบัตร JWT โดยแนบ id, username และ role เข้าไปในบัตร (มีอายุ 1 วัน)
    const token = jwt.sign(
      { id: user.id, username: user.username, role: user.role },
      SECRET_KEY,
      { expiresIn: '24h' }
    );

    // ตอบกลับ Token พร้อมข้อมูลสิทธิ์ไปให้ Flutter
    res.status(200).json({
      success: true,
      message: "เข้าสู่ระบบสำเร็จ!",
      token: token,
      user: { id: user.id, username: user.username, role: user.role }
    });
  } catch (error) {
    console.error('[login error]', error);
    res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในการล็อกอิน", error: error.message });
  }
});

// =========================================================================
// โซนที่ 2: Protected ERP Endpoints (ต้องมี JWT บัตรพนักงานถึงจะเข้าได้!)
// =========================================================================

// 2.1 ดึงสินค้าทั้งหมด (เข้าได้ทุกคนที่มี Token)
app.get('/api/products', authenticateToken, async (req, res) => {
  try {
    const products = await prisma.product.findMany({ orderBy: { id: 'asc' } });
    res.status(200).json({ success: true, count: products.length, data: products });
  } catch (error) {
    res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดที่เซิร์ฟเวอร์" });
  }
});

// 2.2 สร้างสินค้าใหม่ (เข้าได้ทุกคนที่ล็อกอิน - แต่ในระบบใหญ่ อาจล็อกเฉพาะ MANAGER)
app.post('/api/products', authenticateToken, async (req, res) => {
  try {
    const { sku, name, price, currentStock, minStockAlert } = req.body;
    if (!sku || !name || price === undefined) return res.status(400).json({ success: false, message: "ข้อมูลไม่ครบถ้วน" });

    const existingProduct = await prisma.product.findUnique({ where: { sku } });
    if (existingProduct) return res.status(400).json({ success: false, message: `รหัส SKU '${sku}' นี้มีในระบบแล้ว` });

    const newProduct = await prisma.product.create({
      data: {
        sku, name,
        price: parseFloat(price),
        currentStock: currentStock ? parseInt(currentStock) : 0,
        minStockAlert: minStockAlert ? parseInt(minStockAlert) : 10
      }
    });
    res.status(201).json({ success: true, message: "สร้างสินค้าสำเร็จ!", data: newProduct });
  } catch (error) {
    res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในการสร้างสินค้า" });
  }
});

// 2.3 ตัดยอดสต๊อกและบันทึก Audit Trail (เข้าได้ทุกคนที่ล็อกอิน)
app.post('/api/stock-movements', authenticateToken, async (req, res) => {
  try {
    const { productId, type, quantity, referenceId } = req.body;
    if (!productId || !type || !quantity || quantity <= 0) return res.status(400).json({ success: false, message: "ข้อมูลไม่ครบถ้วน" });

    const product = await prisma.product.findUnique({ where: { id: parseInt(productId) } });
    if (!product) return res.status(404).json({ success: false, message: "ไม่พบสินค้านี้" });

    if (type === 'OUT' && product.currentStock < quantity) {
      return res.status(400).json({ success: false, message: `สต๊อกไม่เพียงพอ! (มี ${product.currentStock} ชิ้น)` });
    }

    let newStock = product.currentStock;
    if (type === 'IN') newStock += parseInt(quantity);
    if (type === 'OUT') newStock -= parseInt(quantity);
    if (type === 'ADJUST') newStock = parseInt(quantity);

    const result = await prisma.$transaction(async (tx) => {
      const updatedProduct = await tx.product.update({
        where: { id: parseInt(productId) },
        data: { currentStock: newStock }
      });

      const movementLog = await tx.stockMovement.create({
        data: {
          productId: parseInt(productId),
          type, quantity: parseInt(quantity),
          referenceId: referenceId || 'MANUAL-ADJUSTMENT',
          performedById: req.user.id // 💡 ใช้ ID ของคนที่ล็อกอินอยู่จริงจากบัตร JWT ไม่ใช้ Default User อีกต่อไป!
        }
      });
      return { updatedProduct, movementLog };
    });

    res.status(201).json({ success: true, message: "ปรับสต๊อกสำเร็จ!", data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในการประมวลผล Transaction" });
  }
});

// 2.4 ⭐ API โบนัส: ดึงสถิติผู้บริหาร (ล็อกสิทธิ์ RBAC - อนุญาตเฉพาะ ADMIN และ MANAGER เท่านั้น!)
app.get('/api/admin/reports', authenticateToken, authorizeRoles('ADMIN', 'MANAGER'), async (req, res) => {
  try {
    // ดึงประวัติ Audit Trail 20 รายการล่าสุดมาให้ผู้บริหารดู
    const recentMovements = await prisma.stockMovement.findMany({
      take: 20,
      orderBy: { createdAt: 'desc' },
      include: { product: true, performedBy: { select: { username: true, role: true } } }
    });
    res.status(200).json({ success: true, data: recentMovements });
  } catch (error) {
    res.status(500).json({ success: false, message: "ดึงข้อมูลรายงานล้มเหลว" });
  }
});

// ==========================================
// Endpoint 4: POST /api/orders (สร้างคำสั่งซื้อ + ตัดสต๊อกหลายรายการ + สร้าง Audit Trail)
// ==========================================
app.post('/api/orders', authenticateToken, async (req, res) => {
  try {
    const { customerName, items } = req.body;

    // 1. Validate Input: ต้องมีชื่อลูกค้า และมีสินค้าในตะกร้าอย่างน้อย 1 ชิ้น
    if (!customerName || !items || !Array.isArray(items) || items.length === 0) {
      return res.status(400).json({ success: false, message: "กรุณาระบุชื่อลูกค้าและรายการสินค้าให้ถูกต้อง" });
    }

    // 2. ดึงข้อมูลสินค้าทั้งหมดจาก DB มาตรวจสอบสต๊อกและราคาจริงปัจจุบัน (ไม่เชื่อราคาที่ส่งมาจากหน้าแอป!)
    let totalAmount = 0;
    const validatedItems = [];

    for (const item of items) {
      const product = await prisma.product.findUnique({ where: { id: parseInt(item.productId) } });
      if (!product) {
        return res.status(404).json({ success: false, message: `ไม่พบสินค้า ID ${item.productId} ในระบบ` });
      }
      if (product.currentStock < item.quantity) {
        return res.status(400).json({ 
          success: false, 
          message: `สินค้า '${product.name}' สต๊อกไม่พอ! (เหลือ ${product.currentStock} ชิ้น แต่ต้องการ ${item.quantity} ชิ้น)` 
        });
      }

      // คำนวณราคารวมของแต่ละรายการ
      const itemTotal = parseFloat(product.price) * parseInt(item.quantity);
      totalAmount += itemTotal;

      validatedItems.push({
        productId: product.id,
        name: product.name,
        sku: product.sku,
        quantity: parseInt(item.quantity),
        unitPrice: parseFloat(product.price),
        currentStock: product.currentStock
      });
    }

    // 3. สร้างเลขที่บิลอัตโนมัติ เช่น INV-20260724-1721
    const orderNumber = `INV-${new Date().toISOString().slice(0, 10).replace(/-/g, '')}-${Math.floor(1000 + Math.random() * 9000)}`;

    // 4. ⭐ พระเอก SA: ประมวลผลทุกอย่างใน 1 Transaction!
    const resultOrder = await prisma.$transaction(async (tx) => {
      // 4.1 สร้างหัวบิลคำสั่งซื้อ (Order Header)
      const newOrder = await tx.order.create({
        data: {
          orderNumber: orderNumber,
          customerName: customerName.trim(),
          totalAmount: totalAmount,
          status: 'CONFIRMED',
          createdById: req.user.id
        }
      });

      // 4.2 วนลูปบันทึกรายการสินค้าย่อย (Order Items), ตัดยอดสต๊อก, และบันทึก Log
      for (const item of validatedItems) {
        // บันทึกรายการลงบิล
        await tx.orderItem.create({
          data: {
            orderId: newOrder.id,
            productId: item.productId,
            quantity: item.quantity,
            unitPrice: item.unitPrice
          }
        });

        // ตัดสต๊อกในตาราง Product
        await tx.product.update({
          where: { id: item.productId },
          data: { currentStock: item.currentStock - item.quantity }
        });

        // บันทึก Audit Trail ในตาราง StockMovement
        await tx.stockMovement.create({
          data: {
            productId: item.productId,
            type: 'OUT',
            quantity: item.quantity,
            referenceId: orderNumber, // อ้างอิงเลขบิลนี้!
            performedById: req.user.id
          }
        });
      }

      return newOrder;
    });

    res.status(201).json({
      success: true,
      message: "เปิดบิลขายและตัดสต๊อกสำเร็จ!",
      data: {
        orderNumber: resultOrder.orderNumber,
        customerName: resultOrder.customerName,
        totalAmount: resultOrder.totalAmount,
        items: validatedItems
      }
    });

  } catch (error) {
    console.error("Order Transaction Error:", error);
    res.status(500).json({ success: false, message: "เกิดข้อผิดพลาดในการเปิดบิลคำสั่งซื้อ" });
  }
});

app.listen(PORT, () => {
  console.log(`🚀 เซิร์ฟเวอร์ ERP พร้อมระบบ Security เปิดทำงานแล้วที่พอร์ต http://localhost:${PORT}`);
});
