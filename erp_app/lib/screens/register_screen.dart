import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  String? _errorMessage;
  String _selectedRole = 'WAREHOUSE_STAFF'; // ค่าเริ่มต้น
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _roles = ['WAREHOUSE_STAFF', 'MANAGER', 'ADMIN'];
  final Map<String, String> _roleLabels = {
    'WAREHOUSE_STAFF': '👷 พนักงานคลังสินค้า',
    'MANAGER': '👔 ผู้จัดการ',
    'ADMIN': '🔑 ผู้ดูแลระบบ',
  };

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'รหัสผ่านไม่ตรงกัน';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // เรียก Provider ให้ยิง API Register
      await context.read<AuthProvider>().register(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
        _selectedRole,
      );

      if (mounted) {
        // แสดง Success Dialog แล้วพากลับไปหน้า Login
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
            title: const Text('สมัครสมาชิกสำเร็จ! ✨'),
            content: const Text(
              'บัญชีของคุณถูกสร้างแล้ว\nกรุณาล็อกอินเข้าสู่ระบบ',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop(); // ปิด Dialog
                  Navigator.of(context).pop(); // กลับไปหน้า Login
                },
                child: const Text('ล็อกอินเลย'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 450),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 15,
                ),
              ],
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.person_add,
                    size: 64,
                    color: Colors.greenAccent,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'สมัครสมาชิก ERP',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'สร้างบัญชีใหม่เพื่อเข้าใช้ระบบ',
                    style: TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 32),
                  // Error Message
                  if (_errorMessage != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error, color: Colors.red),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(color: Colors.red),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Username Field
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'ชื่อผู้ใช้ (Username)',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(),
                      hintText: 'ป้อนชื่อผู้ใช้ 4-20 ตัวอักษร',
                    ),
                    validator: (val) {
                      if (val!.isEmpty) return 'กรุณาระบุชื่อผู้ใช้';
                      if (val.length < 4)
                        return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 4 ตัวอักษร';
                      if (val.length > 20)
                        return 'ชื่อผู้ใช้ต้องไม่เกิน 20 ตัวอักษร';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'รหัสผ่าน (Password)',
                      prefixIcon: const Icon(Icons.lock),
                      border: const OutlineInputBorder(),
                      hintText: 'ป้อนรหัสผ่าน 6+ ตัวอักษร',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val!.isEmpty) return 'กรุณาระบุรหัสผ่าน';
                      if (val.length < 6)
                        return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirm Password Field
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'ยืนยันรหัสผ่าน',
                      prefixIcon: const Icon(Icons.lock_outline),
                      border: const OutlineInputBorder(),
                      hintText: 'ป้อนรหัสผ่านอีกครั้ง',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    validator: (val) {
                      if (val!.isEmpty) return 'กรุณายืนยันรหัสผ่าน';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Role Dropdown
                  DropdownButtonFormField<String>(
                    value: _selectedRole,
                    decoration: const InputDecoration(
                      labelText: 'ตำแหน่ง (Role)',
                      prefixIcon: Icon(Icons.badge),
                      border: OutlineInputBorder(),
                    ),
                    items: _roles.map((role) {
                      return DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabels[role] ?? role),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          _selectedRole = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Register Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.greenAccent,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _isLoading ? null : _handleRegister,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'สมัครสมาชิก',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  // Login Link
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text('มีบัญชีแล้ว? '),
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop(); // กลับไปหน้า Login
                        },
                        child: const Text(
                          'ล็อกอินเลย',
                          style: TextStyle(
                            color: Colors.blueAccent,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }
}
