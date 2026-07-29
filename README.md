# ERPflutter

โปรเจคนี้เป็นระบบ ERP ต้นแบบที่ประกอบด้วยส่วน backend และ frontend ดังนี้:

- `backend/` - Node.js + Express API server พร้อม Prisma ORM, JWT authentication, bcrypt, CORS
- `erp_app/` - แอป Flutter สำหรับหน้าจอผู้ใช้, เก็บข้อมูลปลอดภัย, แสดงกราฟ, สร้าง PDF, และเชื่อมต่อกับ API

## โครงสร้างโปรเจค

- `backend/`
  - `index.js` - entry point ของ API server
  - `auth.js` - จัดการการล็อกอิน JWT และการยืนยันสิทธิ์
  - `db.js` - ตั้งค่า Prisma client สำหรับเชื่อมต่อฐานข้อมูล
  - `deleteUser.js` - ตัวอย่าง API สำหรับลบผู้ใช้
  - `package.json` / `package-lock.json` - ตั้งค่า dependencies
  - `.env` - ใส่คอนฟิกฐานข้อมูลและรหัสลับ JWT (ไม่เก็บขึ้น Git)

- `erp_app/`
  - `lib/` - โค้ด Flutter หลัก
  - `pubspec.yaml` - ตั้งค่า dependencies ของ Flutter
  - `android/`, `ios/`, `web/`, `macos/`, `windows/`, `linux/` - platform targets

## เทคโนโลยีหลัก

### Backend

- Node.js, Express
- Prisma ORM
- PostgreSQL / relational database (กำหนดใน Prisma schema)
- JWT authentication
- bcryptjs for password hashing

### Frontend

- Flutter
- Provider สำหรับ state management
- `http` สำหรับเรียก API
- `flutter_secure_storage` สำหรับเก็บ token อย่างปลอดภัย
- `fl_chart` สำหรับแสดงกราฟ
- `pdf` และ `printing` สำหรับสร้างและพิมพ์เอกสาร PDF
- `shared_preferences` สำหรับเก็บข้อมูลสถานะพื้นฐาน

## วิธีใช้งาน

### 1. Backend

```bash
cd backend
npm install
cp .env.example .env
# แก้ไข .env ให้ถูกต้อง
npm run dev
```

ไฟล์ `.env` ไม่ควรถูกเก็บขึ้น GitHub เนื่องจากมีค่าลับ เช่น `DATABASE_URL` และ `JWT_SECRET`.

### 2. Frontend

```bash
cd erp_app
flutter pub get
flutter run
```

### การเชื่อมต่อจาก Android

ต้องเปิด backend ก่อนด้วย `cd backend && npm run dev` เสมอ เพราะแอปจะล็อกอินไม่ได้หาก API ที่พอร์ต 3000 ไม่ทำงาน

- Android Emulator ใช้ `http://10.0.2.2:3000/api` ให้อัตโนมัติ
- เครื่องจริง ต้องระบุ IP ของเครื่องที่รัน backend (และอยู่ Wi-Fi เดียวกัน) เช่น

```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:3000/api
```

`usesCleartextTraffic` เปิดไว้สำหรับ API HTTP ในการพัฒนาเท่านั้น; ก่อนนำขึ้นใช้งานจริงควรใช้ HTTPS

## สร้าง repo GitHub และผลักดันโค้ด

1. สร้าง repository ใหม่ใน GitHub ชื่อ `erp-project` หรือชื่อที่ต้องการ
2. เพิ่ม remote และ push:

```bash
git remote add origin https://github.com/Apivit0129/erp-project.git
git branch -M main
git push -u origin main
```

> หากใช้ SSH ให้เปลี่ยนเป็น `git@github.com:Apivit0129/erp-project.git`

## หมายเหตุ

- อย่าเก็บไฟล์ `.env` ขึ้น GitHub
- หากต้องการใช้งานจริง ควรตั้งค่า database และ secrets ใน production อย่างปลอดภัย
