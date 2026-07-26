import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'screens/login_screen.dart';
import 'screens/inventory_screen.dart';

void main() {
  runApp(
    // หุ้มแอปด้วย Provider เพื่อให้ทุกหน้าจอดูสถานะ Login/Logout ได้
    ChangeNotifierProvider(
      create: (context) =>
          AuthProvider()..checkLoginStatus(), // เปิดแอปมาให้เช็คสิทธิ์เดิมทันที
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP Portfolio App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blueAccent),
        useMaterial3: true,
      ),
      // ⭐ หัวใจของ Auth Guard: เช็คจาก Provider ว่า isLoggedIn เป็นจริงไหม?
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            return const InventoryScreen(); // ถ้าล็อกอินแล้ว พาไปหน้าคลัง
          } else {
            return const LoginScreen(); // ถ้ายังไม่ล็อกอิน บังคับอยู่หน้า Login
          }
        },
      ),
    );
  }
}
