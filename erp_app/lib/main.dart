import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_provider.dart';
import 'services/navigation_provider.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell.dart';
import 'core/theme/index.dart';

void main() {
  runApp(
    // หุ้มแอปด้วย MultiProvider สำหรับ Auth + Navigation
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => AuthProvider()..checkLoginStatus(),
        ),
        ChangeNotifierProvider(create: (context) => NavigationProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ERP App',
      debugShowCheckedModeBanner: false,
      // ⭐ Design System: Teal Professional (ui-ux-pro-max)
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light, // เปลี่ยนเป็น ThemeMode.system เพื่อตาม OS
      // ⭐ Auth Guard: เช็คจาก Provider ว่า isLoggedIn?
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isLoggedIn) {
            return const AppShell(); // ถ้าล็อกอินแล้ว ใช้ AppShell
          } else {
            return const LoginScreen(); // ถ้ายังไม่ล็อกอิน บังคับอยู่หน้า Login
          }
        },
      ),
    );
  }
}
