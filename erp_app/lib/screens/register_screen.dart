import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_theme.dart';

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
  String _selectedRole = 'WAREHOUSE_STAFF';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final List<String> _roles = ['WAREHOUSE_STAFF', 'MANAGER', 'ADMIN'];
  final Map<String, String> _roleLabels = {
    'WAREHOUSE_STAFF': 'พนักงานคลังสินค้า',
    'MANAGER': 'ผู้จัดการ',
    'ADMIN': 'ผู้ดูแลระบบ',
  };
  final Map<String, IconData> _roleIcons = {
    'WAREHOUSE_STAFF': Icons.warehouse_outlined,
    'MANAGER': Icons.manage_accounts_outlined,
    'ADMIN': Icons.admin_panel_settings_outlined,
  };

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = 'รหัสผ่านไม่ตรงกัน');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().register(
            _usernameController.text.trim(),
            _passwordController.text.trim(),
            _selectedRole,
          );

      if (mounted) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.success.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.check_circle_outline,
                      color: AppColors.success, size: 22),
                ),
                AppSpacing.w(12),
                const Text('สมัครสมาชิกสำเร็จ!'),
              ],
            ),
            content: const Text('บัญชีของคุณถูกสร้างแล้ว\nกรุณาล็อกอินเข้าสู่ระบบ'),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
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
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('สมัครสมาชิก'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.elevatedShadow,
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.person_add_outlined,
                              color: AppColors.primary, size: 22),
                        ),
                        AppSpacing.w(14),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('สมัครสมาชิก ERP',
                                style: AppTextStyles.headingLarge),
                            Text('สร้างบัญชีใหม่เพื่อเข้าใช้ระบบ',
                                style: AppTextStyles.bodySmall),
                          ],
                        ),
                      ],
                    ),
                    AppSpacing.gapXL,

                    // Error banner
                    if (_errorMessage != null) ...[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.destructive.withAlpha(18),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: AppColors.destructive.withAlpha(60)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline,
                                color: AppColors.destructive, size: 18),
                            AppSpacing.w(10),
                            Expanded(
                              child: Text(
                                _errorMessage!,
                                style: AppTextStyles.bodySmall
                                    .copyWith(color: AppColors.destructive),
                              ),
                            ),
                          ],
                        ),
                      ),
                      AppSpacing.gapBase,
                    ],

                    // Username
                    TextFormField(
                      controller: _usernameController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'ชื่อผู้ใช้ (Username)',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                        hintText: 'ป้อนชื่อผู้ใช้ 4-20 ตัวอักษร',
                      ),
                      validator: (val) {
                        if (val!.isEmpty) return 'กรุณาระบุชื่อผู้ใช้';
                        if (val.length < 4) {
                          return 'ชื่อผู้ใช้ต้องมีอย่างน้อย 4 ตัวอักษร';
                        }
                        if (val.length > 20) {
                          return 'ชื่อผู้ใช้ต้องไม่เกิน 20 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapBase,

                    // Password
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'รหัสผ่าน (Password)',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        hintText: 'ป้อนรหัสผ่าน 6+ ตัวอักษร',
                        suffixIcon: IconButton(
                          icon: Icon(_obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 20),
                          onPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (val) {
                        if (val!.isEmpty) return 'กรุณาระบุรหัสผ่าน';
                        if (val.length < 6) {
                          return 'รหัสผ่านต้องมีอย่างน้อย 6 ตัวอักษร';
                        }
                        return null;
                      },
                    ),
                    AppSpacing.gapBase,

                    // Confirm Password
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      decoration: InputDecoration(
                        labelText: 'ยืนยันรหัสผ่าน',
                        prefixIcon: const Icon(Icons.lock_outline_rounded),
                        hintText: 'ป้อนรหัสผ่านอีกครั้ง',
                        suffixIcon: IconButton(
                          icon: Icon(_obscureConfirmPassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                              size: 20),
                          onPressed: () => setState(() =>
                              _obscureConfirmPassword =
                                  !_obscureConfirmPassword),
                        ),
                      ),
                      validator: (val) =>
                          val!.isEmpty ? 'กรุณายืนยันรหัสผ่าน' : null,
                    ),
                    AppSpacing.gapBase,

                    // Role selector
                    Text('ตำแหน่ง', style: AppTextStyles.labelMedium
                        .copyWith(color: AppColors.mutedForeground)),
                    AppSpacing.gapXS,
                    ...(_roles.map((role) => _buildRoleTile(role))),
                    AppSpacing.gapXL,

                    // Register Button
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _handleRegister,
                        icon: _isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.person_add_outlined, size: 18),
                        label: Text(_isLoading ? 'กำลังสมัคร...' : 'สมัครสมาชิก'),
                      ),
                    ),

                    AppSpacing.gapBase,

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('มีบัญชีแล้ว?', style: AppTextStyles.bodySmall),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('ล็อกอินเลย'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleTile(String role) {
    final isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: AppDurations.fast,
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withAlpha(15)
              : AppColors.muted,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _roleIcons[role] ?? Icons.person_outline,
              color: isSelected ? AppColors.primary : AppColors.mutedForeground,
              size: 20,
            ),
            AppSpacing.w(12),
            Expanded(
              child: Text(
                _roleLabels[role] ?? role,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: isSelected
                      ? AppColors.primary
                      : AppColors.foreground,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.primary, size: 18),
          ],
        ),
      ),
    );
  }
}
