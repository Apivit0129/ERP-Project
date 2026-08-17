import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/elegant_notification_service.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_theme.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppDurations.slow,
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.08),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await context.read<AuthProvider>().login(
        _usernameController.text.trim(),
        _passwordController.text.trim(),
      );
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      setState(() {
        _errorMessage = errorMsg;
        _isLoading = false;
      });
      if (mounted) {
        ElegantNotificationService.error(
          context,
          title: 'เข้าสู่ระบบไม่สำเร็จ',
          description: errorMsg,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 768;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: isWide ? _buildWideLayout() : _buildMobileLayout(),
    );
  }

  // ─── Wide (tablet/desktop) — Split layout ─────────────────
  Widget _buildWideLayout() {
    return Row(
      children: [
        // Left: Branding panel
        Expanded(flex: 5, child: _buildBrandingPanel()),
        // Right: Form
        Expanded(
          flex: 4,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(48),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: FadeTransition(
                  opacity: _fadeAnim,
                  child: SlideTransition(
                    position: _slideAnim,
                    child: _buildFormCard(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── Mobile layout ────────────────────────────────────────
  Widget _buildMobileLayout() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Compact branding header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.sidebarBackground, AppColors.primary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(30),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.bar_chart_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                AppSpacing.gapLG,
                Text(
                  'ERP System',
                  style: AppTextStyles.displayMedium.copyWith(
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Enterprise Resource Planning',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: Colors.white60,
                  ),
                ),
              ],
            ),
          ),
          // Form
          Padding(padding: const EdgeInsets.all(24), child: _buildFormCard()),
        ],
      ),
    );
  }

  // ─── Branding panel ───────────────────────────────────────
  Widget _buildBrandingPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.sidebarBackground, Color(0xFF0D4A46)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Spacer(flex: 2),
            // Logo
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryLight],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withAlpha(80),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(
                Icons.bar_chart_rounded,
                color: Colors.white,
                size: 30,
              ),
            ),
            AppSpacing.gapXL,
            Text(
              'ERP System',
              style: AppTextStyles.displayLarge.copyWith(
                color: Colors.white,
                fontSize: 38,
              ),
            ),
            AppSpacing.gapSM,
            Text(
              'Enterprise Resource Planning',
              style: AppTextStyles.bodyLarge.copyWith(
                color: Colors.white60,
                fontSize: 15,
              ),
            ),
            AppSpacing.gapXL2,
            // Feature bullets
            ...[
              ('ระบบคลังสินค้าแบบ Real-time', Icons.inventory_2_outlined),
              ('ขายหน้าร้านด้วย POS System', Icons.point_of_sale_outlined),
              ('รายงาน Dashboard วิเคราะห์ข้อมูล', Icons.bar_chart_outlined),
              ('บริหาร Purchase Order อัตโนมัติ', Icons.receipt_long_outlined),
            ].map((item) => _buildBulletItem(item.$1, item.$2)),
            const Spacer(flex: 3),
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withAlpha(20)),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.shield_outlined,
                    color: Colors.white54,
                    size: 16,
                  ),
                  AppSpacing.w(8),
                  Text(
                    'ระบบปลอดภัย · เข้ารหัส SSL · PDPA Compliant',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: Colors.white54,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildBulletItem(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: AppColors.primary.withAlpha(50),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, color: AppColors.primaryLight, size: 14),
          ),
          AppSpacing.w(12),
          Text(
            text,
            style: AppTextStyles.bodyMedium.copyWith(
              color: Colors.white.withAlpha(204),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Form card ────────────────────────────────────────────
  Widget _buildFormCard() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppShadows.elevatedShadow,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('เข้าสู่ระบบ', style: AppTextStyles.headingLarge),
            AppSpacing.gapSM,
            Text(
              'กรุณาเข้าสู่ระบบด้วยบัญชีพนักงาน',
              style: AppTextStyles.bodySmall,
            ),
            AppSpacing.gapXL,

            // Error banner
            if (_errorMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.destructive.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.destructive.withAlpha(60),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: AppColors.destructive,
                      size: 18,
                    ),
                    AppSpacing.w(10),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.destructive,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              AppSpacing.gapBase,
            ],

            // Username field
            TextFormField(
              controller: _usernameController,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(
                labelText: 'ชื่อผู้ใช้ (Username)',
                prefixIcon: Icon(Icons.person_outline_rounded),
              ),
              validator: (val) => val!.isEmpty ? 'กรุณาระบุชื่อผู้ใช้' : null,
            ),
            AppSpacing.gapBase,

            // Password field
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _isLoading ? null : _handleLogin(),
              decoration: InputDecoration(
                labelText: 'รหัสผ่าน (Password)',
                prefixIcon: const Icon(Icons.lock_outline_rounded),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              validator: (val) => val!.isEmpty ? 'กรุณาระบุรหัสผ่าน' : null,
            ),
            AppSpacing.gapXL,

            // Login button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('เข้าสู่ระบบ'),
              ),
            ),

            AppSpacing.gapXL,

            // Divider
            Row(
              children: [
                const Expanded(child: Divider()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text('หรือ', style: AppTextStyles.labelSmall),
                ),
                const Expanded(child: Divider()),
              ],
            ),

            AppSpacing.gapBase,

            // Test accounts info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.muted,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'บัญชีทดสอบ',
                    style: AppTextStyles.labelMedium.copyWith(
                      color: AppColors.foreground,
                    ),
                  ),
                  AppSpacing.gapXS,
                  Text(
                    'staff1 / password123  (พนักงาน)\nmanager1 / password123  (ผู้จัดการ)',
                    style: AppTextStyles.bodySmall.copyWith(
                      fontFamily: 'FiraCode',
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),

            AppSpacing.gapBase,

            // Register link
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('ยังไม่มีบัญชี?', style: AppTextStyles.bodySmall),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  child: const Text('สมัครสมาชิก'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
