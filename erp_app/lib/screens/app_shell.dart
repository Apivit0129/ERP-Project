import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/navigation.dart' as nav;
import '../services/navigation_provider.dart';
import '../services/auth_provider.dart';
import '../core/theme/app_colors.dart';
import '../core/theme/app_typography.dart';
import '../core/theme/app_theme.dart';
import 'inventory_screen.dart';
import 'pos_screen.dart';
import 'purchase_order_screen.dart';
import 'dashboard_screen.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  @override
  Widget build(BuildContext context) {
    return Consumer2<NavigationProvider, AuthProvider>(
      builder: (context, navProvider, authProvider, child) {
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWideScreen = constraints.maxWidth > 800;

            return Scaffold(
              backgroundColor: AppColors.background,
              appBar: _buildAppBar(context, authProvider, isWideScreen),
              body: Row(
                children: [
                  if (isWideScreen)
                    _buildSidebar(context, navProvider, authProvider),
                  Expanded(
                    child: _buildScreenContent(navProvider.currentDestination),
                  ),
                ],
              ),
              drawer: !isWideScreen
                  ? _buildDrawer(context, navProvider, authProvider)
                  : null,
            );
          },
        );
      },
    );
  }

  // ─── AppBar ───────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(
    BuildContext context,
    AuthProvider auth,
    bool isWideScreen,
  ) {
    return AppBar(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.foreground,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: AppColors.cardShadow,
      leading: isWideScreen
          ? Padding(
              padding: const EdgeInsets.all(10),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.primary.withAlpha(15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.grid_view_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            )
          : null,
      title: Row(
        children: [
          // Logo mark
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.bar_chart_rounded,
                color: Colors.white, size: 18),
          ),
          AppSpacing.w(10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'ERP System',
                style: AppTextStyles.headingSmall.copyWith(
                  color: AppColors.foreground,
                  letterSpacing: 0.3,
                ),
              ),
              Text(
                'Enterprise Resource Planning',
                style: AppTextStyles.labelSmall.copyWith(fontSize: 9),
              ),
            ],
          ),
        ],
      ),
      actions: [
        // User info chip
        _buildUserChip(auth),
        // Logout
        Tooltip(
          message: 'ออกจากระบบ',
          child: IconButton(
            icon: const Icon(Icons.logout_rounded, size: 20),
            onPressed: () => _showLogoutDialog(context),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.destructive,
            ),
          ),
        ),
        AppSpacing.w(8),
      ],
    );
  }

  Widget _buildUserChip(AuthProvider auth) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(12),
        border: Border.all(color: AppColors.border, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 11,
            backgroundColor: AppColors.primary,
            child: Text(
              (auth.username ?? '?').isNotEmpty
                  ? (auth.username ?? '?')[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          AppSpacing.w(8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                auth.username ?? '?',
                style: AppTextStyles.labelMedium.copyWith(
                  color: AppColors.foreground,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                _getRoleLabel(auth.role),
                style:
                    AppTextStyles.labelSmall.copyWith(color: AppColors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Sidebar (Desktop) ────────────────────────────────────
  Widget _buildSidebar(
    BuildContext context,
    NavigationProvider navProvider,
    AuthProvider authProvider,
  ) {
    final menus = navProvider.getAccessibleMenus(authProvider.role);

    return Container(
      width: 220,
      color: AppColors.sidebarBackground,
      child: Column(
        children: [
          // Top divider
          Container(
            height: 1,
            color: Colors.white.withAlpha(15),
          ),
          const SizedBox(height: 12),

          // Section label
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Text(
                  'MENU',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: AppColors.sidebarForeground.withAlpha(100),
                    letterSpacing: 1.5,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Menu items
          ...menus.map((nav.AppRoute destination) {
            final isActive = navProvider.currentDestination == destination;
            return _buildSidebarItem(
              context: context,
              destination: destination,
              isActive: isActive,
              onTap: () => navProvider.setDestination(destination),
            );
          }),

          const Spacer(),

          // Version footer
          Container(
            margin: const EdgeInsets.all(12),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(8),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.white.withAlpha(15)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Colors.white38, size: 14),
                AppSpacing.w(8),
                Text(
                  'ERP v1.0.0',
                  style: AppTextStyles.labelSmall.copyWith(
                    color: Colors.white38,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSidebarItem({
    required BuildContext context,
    required nav.AppRoute destination,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: AppDurations.fast,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.primary.withAlpha(40)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? Border.all(
                      color: AppColors.primaryLight.withAlpha(60), width: 1)
                  : null,
            ),
            child: Row(
              children: [
                // Left accent bar
                AnimatedContainer(
                  duration: AppDurations.fast,
                  width: 3,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isActive
                        ? AppColors.primaryLight
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                AppSpacing.w(10),
                Icon(
                  isActive ? destination.activeIcon : destination.icon,
                  color: isActive
                      ? AppColors.primaryLight
                      : AppColors.sidebarForeground.withAlpha(160),
                  size: 20,
                ),
                AppSpacing.w(12),
                Expanded(
                  child: Text(
                    destination.label,
                    style: AppTextStyles.navItem.copyWith(
                      color: isActive
                          ? AppColors.primaryLight
                          : AppColors.sidebarForeground.withAlpha(180),
                      fontWeight: isActive
                          ? FontWeight.w600
                          : FontWeight.w400,
                    ),
                  ),
                ),
                if (isActive)
                  const Icon(
                    Icons.chevron_right,
                    color: AppColors.primaryLight,
                    size: 16,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ─── Drawer (Mobile) ──────────────────────────────────────
  Widget _buildDrawer(
    BuildContext context,
    NavigationProvider navProvider,
    AuthProvider authProvider,
  ) {
    final menus = navProvider.getAccessibleMenus(authProvider.role);

    return Drawer(
      backgroundColor: AppColors.sidebarBackground,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.sidebarBackground,
                    AppColors.primary.withAlpha(80),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppColors.primary, AppColors.primaryLight],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bar_chart_rounded,
                        color: Colors.white, size: 22),
                  ),
                  AppSpacing.w(12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'ERP System',
                          style: AppTextStyles.headingMedium.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${authProvider.username} · ${_getRoleLabel(authProvider.role)}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: Colors.white60,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white54),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // Menu items
            ...menus.map((nav.AppRoute destination) {
              final isActive = navProvider.currentDestination == destination;
              return _buildSidebarItem(
                context: context,
                destination: destination,
                isActive: isActive,
                onTap: () {
                  navProvider.setDestination(destination);
                  Navigator.pop(context);
                },
              );
            }),

            const Spacer(),

            // Logout
            Padding(
              padding: const EdgeInsets.all(12),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context);
                    _showLogoutDialog(context);
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.destructive.withAlpha(20),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.destructive.withAlpha(40)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.logout_rounded,
                            color: AppColors.destructive, size: 20),
                        AppSpacing.w(12),
                        Text(
                          'ออกจากระบบ',
                          style: AppTextStyles.navItem.copyWith(
                            color: AppColors.destructive,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ─── Screen Router ────────────────────────────────────────
  Widget _buildScreenContent(nav.AppRoute destination) {
    switch (destination) {
      case nav.AppRoute.warehouse:
        return const InventoryScreen();
      case nav.AppRoute.pos:
        return const PosScreen();
      case nav.AppRoute.purchase:
        return const PurchaseOrderScreen();
      case nav.AppRoute.dashboard:
        return const DashboardScreen();
    }
  }

  // ─── Logout Dialog ────────────────────────────────────────
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.destructive.withAlpha(18),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.destructive, size: 20),
            ),
            AppSpacing.w(12),
            const Text('ออกจากระบบ'),
          ],
        ),
        content: const Text('คุณต้องการออกจากระบบหรือไม่?'),
        actions: [
          OutlinedButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('ยกเลิก'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.destructive,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              context.read<AuthProvider>().logout();
            },
            child: const Text('ออกจากระบบ'),
          ),
        ],
      ),
    );
  }

  // ─── Helpers ──────────────────────────────────────────────
  String _getRoleLabel(String? role) {
    switch (role) {
      case 'ADMIN':
        return 'ผู้ดูแลระบบ';
      case 'MANAGER':
        return 'ผู้จัดการ';
      case 'WAREHOUSE_STAFF':
        return 'พนักงานคลัง';
      default:
        return 'ผู้ใช้งาน';
    }
  }
}
