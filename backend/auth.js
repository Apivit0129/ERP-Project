const jwt = require('jsonwebtoken');

// 💡 ในระบบจริงต้องเก็บในไฟล์ .env แต่เพื่อความสะดวกในการเทสโปรเจกต์สัมภาษณ์ เรากำหนดไว้ตรงนี้ก่อนครับ
const SECRET_KEY = "ERP_SUPER_SECRET_KEY_2026";

// Middleware 1: ตรวจสอบว่าล็อกอินมาหรือยัง? (Verify Token)
const authenticateToken = (req, res, next) => {
  // ดึง Token จาก Header ช่อง Authorization (มักส่งมาในรูปแบบ "Bearer <token>")
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    return res.status(401).json({ success: false, message: "กรุณาล็อกอินเข้าสู่ระบบก่อนใช้งาน (Unauthorized)" });
  }

  jwt.verify(token, SECRET_KEY, (err, user) => {
    if (err) {
      return res.status(403).json({ success: false, message: "บัตรพนักงานหมดอายุหรือไม่ถูกต้อง (Forbidden)" });
    }
    // ถ้าถูกต้อง ให้เอาข้อมูล User (เช่น id, username, role) แนบไปกับ Request เพื่อให้ API ถัดไปเอาไปใช้ต่อได้
    req.user = user;
    next(); // เปิดทางให้เดินผ่านไปที่ Endpoint ได้
  });
};

// Middleware 2: ตรวจสอบระดับสิทธิ์ผู้ใช้งาน (RBAC - Role Based Access Control)
const authorizeRoles = (...allowedRoles) => {
  return (req, res, next) => {
    // เช็คว่า Role ของคนที่ล็อกอินมา อยู่ในรายการสิทธิ์ที่อนุญาตหรือไม่
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ 
        success: false, 
        message: `สิทธิ์ของคุณ (${req.user.role}) ไม่สามารถเข้าถึงข้อมูลส่วนนี้ได้ อนุญาตเฉพาะ: ${allowedRoles.join(', ')}` 
      });
    }
    next(); // ถ้าสิทธิ์ถูกต้อง เปิดทางให้ผ่านได้
  };
};

module.exports = { authenticateToken, authorizeRoles, SECRET_KEY };