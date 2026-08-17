require('dotenv').config(); // 💡 โหลด .env ก่อนทุกอย่าง!
const express = require('express');
const http = require('http');           // ⭐ ต้องใช้ http.createServer เพื่อแชร์กับ socket.io
const { Server } = require('socket.io'); // ⭐ โหลด socket.io Server
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('./db');
const { authenticateToken, authorizeRoles, SECRET_KEY } = require('./auth');

const app = express();
const PORT = 3000;

// สร้าง HTTP server แยกเพื่อแชร์กับ Socket.io
const server = http.createServer(app);

// ⭐ ตั้งค่า Socket.io พร้อม CORS สำหรับ Flutter Web (localhost ทุก port)
const io = new Server(server, {
  cors: {
    origin: '*',           // ใน Production ให้ระบุ domain จริง เช่น 'https://erp.company.com'
    methods: ['GET', 'POST']
  }
});

// Log เมื่อ client เชื่อมต่อ/ตัดการเชื่อมต่อ (สำหรับ Debugging)
io.on('connection', (socket) => {
  console.log(`🔌 [Socket.io] Client เชื่อมต่อแล้ว: ${socket.id} (รวม: ${io.engine.clientsCount} เครื่อง)`);
  socket.on('disconnect', () => {
    console.log(`❌ [Socket.io] Client ตัดการเชื่อมต่อ: ${socket.id}`);
  });
});

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

// 2.1 ดึงสินค้าแบบ Server-side Pagination / Search / Sorting
app.get('/api/products', authenticateToken, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page, 10) || 1);
    const limit = Math.min(100, Math.max(1, parseInt(req.query.limit, 10) || 20));
    const skip = (page - 1) * limit;
    const search = (req.query.search || '').trim();
    const stockStatus = req.query.stockStatus || 'ALL';
    const allowedSortFields = ['id', 'sku', 'name', 'price', 'currentStock', 'createdAt'];
    // Map Flutter camelCase → Prisma field (ซึ่ง map ไปยัง snake_case ใน DB อยู่แล้ว)
    const sortBy = allowedSortFields.includes(req.query.sortBy) ? req.query.sortBy : 'id';
    const order = req.query.order === 'desc' ? 'desc' : 'asc';

    // ⭐ FIX: LOW_STOCK ต้องเปรียบ currentStock <= minStockAlert ซึ่งเป็น column อื่น
    // Prisma WHERE ไม่รองรับ column-to-column comparison โดยตรง → ใช้ $queryRaw เฉพาะกรณีนี้
    if (stockStatus === 'LOW_STOCK') {
      const searchClause = search ? `AND (sku ILIKE $4 OR name ILIKE $4)` : '';
      const searchParam = search ? `%${search}%` : null;
      const orderCol = sortBy === 'currentStock' ? 'current_stock'
                     : sortBy === 'minStockAlert' ? 'min_stock_alert'
                     : sortBy === 'createdAt' ? 'created_at'
                     : sortBy;
      const orderDir = order.toUpperCase();

      // สร้าง query ด้วย tagged template (Prisma Sql) ไม่ได้เพราะ dynamic ORDER BY
      // ใช้ $queryRawUnsafe อย่างปลอดภัย เพราะ orderCol/orderDir ผ่าน allowlist แล้ว
      const productsRaw = await prisma.$queryRawUnsafe(
        `SELECT id, sku, name, price::text, current_stock AS "currentStock", min_stock_alert AS "minStockAlert", created_at AS "createdAt", updated_at AS "updatedAt"
         FROM products
         WHERE current_stock <= min_stock_alert AND current_stock > 0
         ${searchParam ? `AND (sku ILIKE $3 OR name ILIKE $3)` : ''}
         ORDER BY "${orderCol}" ${orderDir}
         LIMIT $1 OFFSET $2`,
        ...(searchParam ? [limit, skip, searchParam] : [limit, skip])
      );
      const countRaw = await prisma.$queryRawUnsafe(
        `SELECT COUNT(*) AS total FROM products
         WHERE current_stock <= min_stock_alert AND current_stock > 0
         ${searchParam ? `AND (sku ILIKE $1 OR name ILIKE $1)` : ''}`,
        ...(searchParam ? [searchParam] : [])
      );
      const totalCount = Number(countRaw[0].total);
      // แปลง price กลับเป็น string ให้ตรงกับ Decimal format ของ Prisma
      const products = productsRaw.map(p => ({ ...p, minStockAlert: p.minStockAlert }));
      const totalPages = Math.ceil(totalCount / limit);
      const meta = { page, limit, totalCount, totalPages };
      return res.status(200).json({
        success: true,
        data: products,
        meta: meta,
        pagination: meta
      });
    }

    // กรณีอื่น: ใช้ Prisma ORM ปกติ
    const filters = [];
    if (search) {
      filters.push({
        OR: [
          { sku: { contains: search, mode: 'insensitive' } },
          { name: { contains: search, mode: 'insensitive' } }
        ]
      });
    }
    if (stockStatus === 'OUT_OF_STOCK') {
      filters.push({ currentStock: 0 });
    } else if (stockStatus === 'IN_STOCK') {
      filters.push({ currentStock: { gt: 0 } });
    }
    const where = filters.length ? { AND: filters } : {};
    const [products, totalCount] = await prisma.$transaction([
      prisma.product.findMany({
        where,
        skip,
        take: limit,
        orderBy: { [sortBy]: order }
      }),
      prisma.product.count({ where })
    ]);
    const totalPages = Math.ceil(totalCount / limit);
    const meta = { page, limit, totalCount, totalPages };
    res.status(200).json({
      success: true,
      data: products,
      meta: meta,
      pagination: meta
    });
  } catch (error) {
    console.error('[products error]', error);
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

    // ⭐ Real-time: Broadcast ข่าวการขยับสต๊อกไปหาทุก client ที่เชื่อมต่ออยู่
    io.emit('stock_updated', {
      productId: parseInt(productId),
      productName: product.name,
      productSku: product.sku,
      type,
      quantity: parseInt(quantity),
      newStock,
      referenceId: referenceId || 'MANUAL-ADJUSTMENT',
      performedBy: req.user.username,
      timestamp: new Date().toISOString()
    });
    console.log(`📡 [Socket.io] Emit 'stock_updated' → SKU: ${product.sku} | Type: ${type} | Qty: ${quantity}`);

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

    // ⭐ Real-time: Broadcast บิลใหม่ไปทุก client ทันที!
    io.emit('new_order', {
      orderNumber: resultOrder.orderNumber,
      customerName: resultOrder.customerName,
      totalAmount: parseFloat(resultOrder.totalAmount),
      itemCount: validatedItems.length,
      itemNames: validatedItems.map(i => i.name).join(', '),
      createdBy: req.user.username,
      timestamp: new Date().toISOString()
    });
    console.log(`📡 [Socket.io] Emit 'new_order' → ${resultOrder.orderNumber} | ฿${resultOrder.totalAmount}`);

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

// =========================================================================
// โซนที่ 3: โมดูลจัดซื้อ (Procurement - Purchase Orders)
// =========================================================================

// 3.1 API: ดึงรายการซัพพลายเออร์ (เพื่อทำ Dropdown ในหน้าแอป)
app.get('/api/suppliers', authenticateToken, async (req, res) => {
  try {
    const suppliers = await prisma.supplier.findMany();
    res.status(200).json({ success: true, data: suppliers });
  } catch (error) {
    res.status(500).json({ success: false, message: "ดึงข้อมูลซัพพลายเออร์ล้มเหลว" });
  }
});

// 3.2 API: ดู PO สำหรับติดตามสถานะ/หน้ารับของ
app.get('/api/purchase-orders', authenticateToken, async (req, res) => {
  try {
    const where = req.query.status ? { status: req.query.status } : {};
    const purchaseOrders = await prisma.purchaseOrder.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: {
        supplier: true,
        items: { include: { product: true } },
        createdBy: { select: { username: true } }
      }
    });
    res.status(200).json({ success: true, data: purchaseOrders });
  } catch (error) {
    res.status(500).json({ success: false, message: "ดึงรายการใบสั่งซื้อล้มเหลว" });
  }
});

// 3.3 API: ดูรายละเอียด PO จากเลขที่ใช้สแกน/กรอกในหน้ารับของ
app.get('/api/purchase-orders/:id', authenticateToken, async (req, res) => {
  try {
    const purchaseOrder = await prisma.purchaseOrder.findUnique({
      where: { id: parseInt(req.params.id) },
      include: { supplier: true, items: { include: { product: true } } }
    });
    if (!purchaseOrder) return res.status(404).json({ success: false, message: "ไม่พบใบสั่งซื้อนี้" });
    res.status(200).json({ success: true, data: purchaseOrder });
  } catch (error) {
    res.status(400).json({ success: false, message: "รหัสใบสั่งซื้อไม่ถูกต้อง" });
  }
});

// 3.4 API: เปิดใบสั่งซื้อ (Create Purchase Order)
app.post('/api/purchase-orders', authenticateToken, authorizeRoles('ADMIN', 'MANAGER'), async (req, res) => {
  try {
    const { supplierId, items } = req.body;
    if (!supplierId || !Array.isArray(items) || items.length === 0) return res.status(400).json({ success: false, message: "กรุณาระบุซัพพลายเออร์และรายการสินค้า" });

    const supplier = await prisma.supplier.findUnique({ where: { id: parseInt(supplierId) } });
    if (!supplier) return res.status(404).json({ success: false, message: "ไม่พบซัพพลายเออร์ที่เลือก" });

    const productIds = items.map((item) => parseInt(item.productId));
    const hasInvalidItem = items.some((item, index) =>
      !Number.isInteger(productIds[index]) ||
      !Number.isInteger(Number(item.quantity)) || Number(item.quantity) <= 0 ||
      !Number.isFinite(Number(item.unitCost)) || Number(item.unitCost) < 0
    );
    if (hasInvalidItem || new Set(productIds).size !== productIds.length) {
      return res.status(400).json({ success: false, message: "รายการสินค้า จำนวน และต้นทุนต้องถูกต้อง และห้ามซ้ำกัน" });
    }

    const productCount = await prisma.product.count({ where: { id: { in: productIds } } });
    if (productCount !== productIds.length) return res.status(404).json({ success: false, message: "พบสินค้าที่ไม่มีอยู่ในระบบ" });

    const poNumber = `PO-${Date.now()}-${Math.floor(100 + Math.random() * 900)}`;

    const newPO = await prisma.$transaction(async (tx) => {
      // 1. สร้างหัวบิล PO
      const po = await tx.purchaseOrder.create({
        data: {
          poNumber: poNumber,
          supplierId: parseInt(supplierId),
          status: 'PENDING', // ⭐ สำคัญ: สั่งเฉยๆ ยังไม่ได้ของ สต๊อกยังไม่ขึ้น!
          createdById: req.user.id
        }
      });

      // 2. บันทึกรายการสินค้าใน PO
      for (const item of items) {
        await tx.purchaseOrderItem.create({
          data: {
            purchaseOrderId: po.id,
            productId: parseInt(item.productId),
            orderQuantity: parseInt(item.quantity),
            unitCost: parseFloat(item.unitCost)
          }
        });
      }
      return po;
    });

    res.status(201).json({ success: true, message: "สร้างใบสั่งซื้อ (PO) สำเร็จ! สต๊อกยังไม่ถูกเพิ่มจนกว่าจะรับของ", data: newPO });
  } catch (error) {
    res.status(500).json({ success: false, message: "สร้างใบสั่งซื้อล้มเหลว" });
  }
});

// 3.5 API: รับของเข้าคลังจากใบ PO (Receive PO & Update Stock)
app.post('/api/purchase-orders/:id/receive', authenticateToken, authorizeRoles('ADMIN', 'MANAGER', 'WAREHOUSE_STAFF'), async (req, res) => {
  try {
    const poId = parseInt(req.params.id);
    const { receivedItems } = req.body; // อาเรย์เก็บ productId และ จำนวนที่รับจริง
    if (!Array.isArray(receivedItems) || receivedItems.length === 0) {
      return res.status(400).json({ success: false, message: "กรุณาระบุรายการที่รับเข้า" });
    }

    const po = await prisma.purchaseOrder.findUnique({ where: { id: poId }, include: { items: true } });
    if (!po) return res.status(404).json({ success: false, message: "ไม่พบใบสั่งซื้อนี้" });
    if (po.status === 'RECEIVED') return res.status(400).json({ success: false, message: "ใบสั่งซื้อนี้รับของเข้าคลังไปแล้ว" });

    const receivedByProductId = new Map();
    for (const item of receivedItems) {
      const productId = parseInt(item.productId);
      const quantity = Number(item.receivedQuantity);
      if (!Number.isInteger(productId) || !Number.isInteger(quantity) || quantity < 0 || receivedByProductId.has(productId)) {
        return res.status(400).json({ success: false, message: "ข้อมูลจำนวนรับเข้าไม่ถูกต้อง" });
      }
      receivedByProductId.set(productId, quantity);
    }

    // ปิด PO ได้ต่อเมื่อรับครบทุกสินค้าเท่านั้น เพื่อไม่ให้สต๊อกและ Audit Trail ผิดพลาด
    const isComplete = po.items.length === receivedByProductId.size && po.items.every((item) =>
      receivedByProductId.get(item.productId) === item.orderQuantity
    );
    if (!isComplete) {
      return res.status(400).json({
        success: false,
        message: "ยอดรับไม่ตรงกับใบ PO กรุณาตรวจสอบจำนวนก่อนยืนยันรับของ"
      });
    }

    // ⭐ พระเอก SA: Transaction ตัดยอดรับของ + อัปเดตสต๊อก + สร้าง Audit Trail พร้อมกัน!
    const result = await prisma.$transaction(async (tx) => {
      for (const poItem of po.items) {
        const receivedQuantity = receivedByProductId.get(poItem.productId);
          await tx.purchaseOrderItem.update({
            where: { id: poItem.id },
            data: { receivedQuantity }
          });

          // อัปเดตสต๊อกหลักในคลัง (เพิ่มของเข้า)
          await tx.product.update({
            where: { id: poItem.productId },
            data: { currentStock: { increment: receivedQuantity } }
          });

          // ⭐ บันทึก Audit Trail อัตโนมัติ อ้างอิงเลข PO!
          await tx.stockMovement.create({
            data: {
              productId: poItem.productId,
              type: 'IN', // ประเภทรับเข้า
              quantity: receivedQuantity,
              referenceId: po.poNumber, // อ้างอิงว่าเข้าเพราะใบสั่งซื้อเบอร์นี้!
              performedById: req.user.id
            }
          });
      }

      // ปิดงาน: เปลี่ยนสถานะหัวบิล PO เป็น RECEIVED
      const updatedPO = await tx.purchaseOrder.update({
        where: { id: poId },
        data: { status: 'RECEIVED' }
      });

      return updatedPO;
    });

    res.status(200).json({ success: true, message: `รับสินค้าจากใบสั่งซื้อ ${po.poNumber} เข้าคลังสำเร็จ!`, data: result });
  } catch (error) {
    res.status(500).json({ success: false, message: "รับสินค้าเข้าคลังล้มเหลว" });
  }
});

// ⭐ ใช้ server.listen แทน app.listen เพื่อให้ Socket.io ใช้ HTTP server เดียวกัน!
server.listen(PORT, () => {
  console.log(`🚀 เซิร์ฟเวอร์ ERP + Socket.io Real-time เปิดแล้วที่ http://localhost:${PORT}`);
  console.log(`🔌 Socket.io พร้อมรับ client เชื่อมต่อแล้ว (CORS: *)`);
});
