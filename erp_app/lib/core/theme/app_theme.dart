import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_typography.dart';

/// ──────────────────────────────────────────────────────────────────
///  ERP App — AppTheme
///  Style: "Data-Dense Dashboard" | Density: 8/10 | WCAG AA ✓
///  Palette: Teal Professional
///  Font: Fira Code (heading/numbers) + Fira Sans (body)
///
///  ใช้งาน:
///    MaterialApp(
///      theme:   AppTheme.lightTheme,
///      darkTheme: AppTheme.darkTheme,
///      themeMode: ThemeMode.system,
///    )
/// ──────────────────────────────────────────────────────────────────
class AppTheme {
  AppTheme._();

  // ─────────────────────────────────────────
  //  SHARED HELPERS
  // ─────────────────────────────────────────

  static const _defaultRadius = 10.0;
  static const _cardRadius = 12.0;
  static const _buttonRadius = 8.0;
  static const _chipRadius = 6.0;
  static const _inputRadius = 8.0;

  static BorderRadius get defaultBorderRadius =>
      BorderRadius.circular(_defaultRadius);
  static BorderRadius get cardBorderRadius =>
      BorderRadius.circular(_cardRadius);
  static BorderRadius get buttonBorderRadius =>
      BorderRadius.circular(_buttonRadius);

  // ─────────────────────────────────────────
  //  LIGHT THEME
  // ─────────────────────────────────────────

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,

        // ── Color Scheme
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: AppColors.primary,
          onPrimary: AppColors.onPrimary,
          primaryContainer: Color(0xFFCCFBF1), // Teal 100
          onPrimaryContainer: AppColors.primaryDark,
          secondary: AppColors.secondary,
          onSecondary: AppColors.onSecondary,
          secondaryContainer: Color(0xFFCCFBF1),
          onSecondaryContainer: AppColors.primaryDark,
          tertiary: AppColors.accent,
          onTertiary: AppColors.onAccent,
          tertiaryContainer: Color(0xFFFFEDD5), // Orange 100
          onTertiaryContainer: Color(0xFF7C2D12),
          error: AppColors.destructive,
          onError: AppColors.onDestructive,
          errorContainer: Color(0xFFFEE2E2),
          onErrorContainer: Color(0xFF7F1D1D),
          surface: AppColors.surface,
          onSurface: AppColors.onSurface,
          surfaceContainerHighest: AppColors.surfaceVariant,
          onSurfaceVariant: AppColors.mutedForeground,
          outline: AppColors.border,
          outlineVariant: AppColors.borderStrong,
          shadow: Color(0x1A000000),
          scrim: Color(0x8C000000),
          inverseSurface: AppColors.foreground,
          onInverseSurface: AppColors.background,
          inversePrimary: AppColors.primaryLight,
        ),

        // ── Scaffold
        scaffoldBackgroundColor: AppColors.background,

        // ── Typography
        textTheme: AppTypography.textTheme,

        // ── AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.surface,
          foregroundColor: AppColors.foreground,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: AppColors.cardShadow,
          centerTitle: false,
          titleTextStyle: AppTextStyles.headingMedium,
          toolbarTextStyle: AppTextStyles.bodyMedium,
          iconTheme: const IconThemeData(
            color: AppColors.foreground,
            size: 22,
          ),
          actionsIconTheme: const IconThemeData(
            color: AppColors.mutedForeground,
            size: 22,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.dark.copyWith(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
          ),
        ),

        // ── Card
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 0,
          shadowColor: AppColors.cardShadow,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: const BorderSide(color: AppColors.cardBorder, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        // ── ElevatedButton (CTA Primary)
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.onPrimary,
            disabledBackgroundColor: AppColors.muted,
            disabledForegroundColor: AppColors.mutedForeground,
            elevation: 0,
            shadowColor: Colors.transparent,
            textStyle: AppTextStyles.labelLarge,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            minimumSize: const Size(0, 44), // iOS min touch target
            animationDuration: const Duration(milliseconds: 150),
          ),
        ),

        // ── FilledButton (Accent / CTA Action)
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.accent,
            foregroundColor: AppColors.onAccent,
            textStyle: AppTextStyles.labelLarge,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            minimumSize: const Size(0, 44),
          ),
        ),

        // ── OutlinedButton (Secondary action)
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            textStyle: AppTextStyles.labelLarge,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            minimumSize: const Size(0, 44),
          ),
        ),

        // ── TextButton (Ghost button)
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: AppColors.primary,
            textStyle: AppTextStyles.labelLarge.copyWith(
              fontWeight: FontWeight.w500,
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            minimumSize: const Size(0, 44),
          ),
        ),

        // ── IconButton
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            foregroundColor: AppColors.foreground,
            highlightColor: AppColors.muted,
            minimumSize: const Size(44, 44),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
          ),
        ),

        // ── InputDecoration (TextField, Form fields)
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.border, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.border, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.destructive, width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.destructive, width: 2),
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.mutedForeground,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.mutedForeground.withAlpha(153),
          ),
          errorStyle: AppTextStyles.bodySmall.copyWith(
            color: AppColors.destructive,
          ),
          prefixIconColor: AppColors.mutedForeground,
          suffixIconColor: AppColors.mutedForeground,
        ),

        // ── Chip
        chipTheme: ChipThemeData(
          backgroundColor: AppColors.muted,
          selectedColor: AppColors.primaryLight.withAlpha(51),
          disabledColor: AppColors.muted,
          labelStyle: AppTextStyles.labelMedium,
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_chipRadius),
            side: const BorderSide(color: AppColors.border),
          ),
          side: const BorderSide(color: AppColors.border),
          deleteIconColor: AppColors.mutedForeground,
        ),

        // ── NavigationRail (Sidebar on tablet/desktop)
        navigationRailTheme: NavigationRailThemeData(
          backgroundColor: AppColors.sidebarBackground,
          selectedIconTheme: const IconThemeData(
            color: AppColors.onPrimary,
            size: 22,
          ),
          unselectedIconTheme: IconThemeData(
            color: AppColors.sidebarForeground.withAlpha(204),
            size: 22,
          ),
          selectedLabelTextStyle: AppTextStyles.navItemActive,
          unselectedLabelTextStyle: AppTextStyles.navItem,
          indicatorColor: AppColors.primary,
          indicatorShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          elevation: 0,
        ),

        // ── NavigationBar (Bottom nav on mobile)
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.primaryLight.withAlpha(51),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(
                  color: AppColors.primary, size: 22);
            }
            return const IconThemeData(
                color: AppColors.mutedForeground, size: 22);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppTextStyles.labelSmall.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              );
            }
            return AppTextStyles.labelSmall;
          }),
          elevation: 4,
          shadowColor: AppColors.cardShadow,
        ),

        // ── Drawer (Mobile sidebar)
        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.sidebarBackground,
          elevation: 8,
          shadowColor: const Color(0x40000000),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ),

        // ── ListTile
        listTileTheme: const ListTileThemeData(
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          minVerticalPadding: 8,
          iconColor: AppColors.mutedForeground,
          textColor: AppColors.foreground,
          tileColor: Colors.transparent,
          selectedColor: AppColors.primary,
          selectedTileColor: Color(0x1A0D9488),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),

        // ── DataTable (dense ERP tables)
        dataTableTheme: DataTableThemeData(
          headingTextStyle: AppTextStyles.headingSmall.copyWith(
            color: AppColors.mutedForeground,
            fontWeight: FontWeight.w600,
          ),
          dataTextStyle: AppTextStyles.bodyMedium,
          headingRowColor:
              WidgetStateProperty.all(AppColors.muted),
          dataRowColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.hovered)) {
              return AppColors.primaryLight.withAlpha(20);
            }
            return Colors.transparent;
          }),
          dividerThickness: 1,
          horizontalMargin: 16,
          columnSpacing: 24,
          dataRowMinHeight: 44,
          dataRowMaxHeight: 52,
          decoration: const BoxDecoration(
            color: AppColors.surface,
          ),
        ),

        // ── TabBar
        tabBarTheme: TabBarThemeData(
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.mutedForeground,
          labelStyle: AppTextStyles.labelLarge,
          unselectedLabelStyle: AppTextStyles.labelLarge.copyWith(
            fontWeight: FontWeight.w400,
          ),
          indicator: UnderlineTabIndicator(
            borderSide: const BorderSide(
              color: AppColors.primary,
              width: 2.5,
            ),
            borderRadius: BorderRadius.circular(2),
          ),
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: AppColors.border,
        ),

        // ── Dialog / Modal
        dialogTheme: DialogThemeData(
          backgroundColor: AppColors.surface,
          elevation: 8,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          titleTextStyle: AppTextStyles.headingMedium,
          contentTextStyle: AppTextStyles.bodyMedium,
        ),

        // ── BottomSheet
        bottomSheetTheme: const BottomSheetThemeData(
          backgroundColor: AppColors.surface,
          elevation: 8,
          modalElevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(20)),
          ),
          showDragHandle: true,
          dragHandleColor: AppColors.border,
        ),

        // ── SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.foreground,
          contentTextStyle:
              AppTextStyles.bodyMedium.copyWith(color: Colors.white),
          actionTextColor: AppColors.primaryLight,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: 6,
        ),

        // ── Tooltip
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: AppColors.foreground.withAlpha(230),
            borderRadius: BorderRadius.circular(6),
          ),
          textStyle:
              AppTextStyles.bodySmall.copyWith(color: Colors.white),
          waitDuration: const Duration(milliseconds: 500),
          showDuration: const Duration(seconds: 2),
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        ),

        // ── Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.border,
          thickness: 1,
          space: 1,
        ),

        // ── Progress Indicator
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: AppColors.primary,
          linearTrackColor: AppColors.muted,
          circularTrackColor: AppColors.muted,
        ),

        // ── Switch
        switchTheme: SwitchThemeData(
          thumbColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.onPrimary;
            }
            return AppColors.mutedForeground;
          }),
          trackColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.muted;
          }),
          trackOutlineColor: WidgetStateProperty.resolveWith((_) =>
              Colors.transparent),
        ),

        // ── Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return Colors.transparent;
          }),
          checkColor: WidgetStateProperty.all(AppColors.onPrimary),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        // ── Radio
        radioTheme: RadioThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return AppColors.primary;
            }
            return AppColors.border;
          }),
        ),

        // ── PopupMenu
        popupMenuTheme: PopupMenuThemeData(
          color: AppColors.surface,
          elevation: 4,
          shadowColor: const Color(0x40000000),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.border),
          ),
          textStyle: AppTextStyles.bodyMedium,
          labelTextStyle:
              WidgetStateProperty.all(AppTextStyles.bodyMedium),
        ),

        // ── FloatingActionButton
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: AppColors.accent,
          foregroundColor: AppColors.onAccent,
          elevation: 4,
          focusElevation: 6,
          hoverElevation: 6,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),

        // ── Badge
        badgeTheme: BadgeThemeData(
          backgroundColor: AppColors.destructive,
          textColor: AppColors.onDestructive,
          textStyle: AppTextStyles.labelSmall,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        ),

        // ── Segmented Button
        segmentedButtonTheme: SegmentedButtonThemeData(
          style: SegmentedButton.styleFrom(
            backgroundColor: AppColors.muted,
            foregroundColor: AppColors.mutedForeground,
            selectedBackgroundColor: AppColors.primary,
            selectedForegroundColor: AppColors.onPrimary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            textStyle: AppTextStyles.labelMedium,
            side: const BorderSide(color: AppColors.border),
          ),
        ),

        // ── Slider
        sliderTheme: SliderThemeData(
          activeTrackColor: AppColors.primary,
          inactiveTrackColor: AppColors.muted,
          thumbColor: AppColors.primary,
          overlayColor: AppColors.primary.withAlpha(30),
          valueIndicatorColor: AppColors.foreground,
          valueIndicatorTextStyle:
              AppTextStyles.bodySmall.copyWith(color: Colors.white),
        ),
      );

  // ─────────────────────────────────────────
  //  DARK THEME
  // ─────────────────────────────────────────

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,

        // ── Color Scheme — Dark
        colorScheme: const ColorScheme(
          brightness: Brightness.dark,
          primary: AppColors.primaryLight,
          onPrimary: Color(0xFF003D39),
          primaryContainer: AppColors.primaryDark,
          onPrimaryContainer: Color(0xFFCCFBF1),
          secondary: AppColors.secondary,
          onSecondary: Color(0xFF003D39),
          secondaryContainer: Color(0xFF115E59),
          onSecondaryContainer: Color(0xFFCCFBF1),
          tertiary: AppColors.accentLight,
          onTertiary: Color(0xFF4A1400),
          tertiaryContainer: Color(0xFF7C2D12),
          onTertiaryContainer: Color(0xFFFFEDD5),
          error: Color(0xFFFCA5A5),
          onError: Color(0xFF7F1D1D),
          errorContainer: Color(0xFF991B1B),
          onErrorContainer: Color(0xFFFEE2E2),
          surface: AppColors.darkSurface,
          onSurface: AppColors.darkForeground,
          surfaceContainerHighest: AppColors.darkSurfaceVariant,
          onSurfaceVariant: AppColors.darkMutedForeground,
          outline: AppColors.darkBorder,
          outlineVariant: Color(0xFF1A6460),
          shadow: Color(0x40000000),
          scrim: Color(0x99000000),
          inverseSurface: AppColors.darkForeground,
          onInverseSurface: AppColors.darkBackground,
          inversePrimary: AppColors.primary,
        ),

        scaffoldBackgroundColor: AppColors.darkBackground,
        textTheme: AppTypography.textTheme.apply(
          bodyColor: AppColors.darkForeground,
          displayColor: AppColors.darkForeground,
        ),

        appBarTheme: AppBarTheme(
          backgroundColor: AppColors.darkSurface,
          foregroundColor: AppColors.darkForeground,
          elevation: 0,
          scrolledUnderElevation: 1,
          titleTextStyle: AppTextStyles.headingMedium.copyWith(
            color: AppColors.darkForeground,
          ),
          systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
            statusBarColor: Colors.transparent,
          ),
        ),

        cardTheme: CardThemeData(
          color: AppColors.darkCardBackground,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_cardRadius),
            side: const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
          margin: EdgeInsets.zero,
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primaryLight,
            foregroundColor: const Color(0xFF003D39),
            textStyle: AppTextStyles.labelLarge,
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_buttonRadius),
            ),
            minimumSize: const Size(0, 44),
          ),
        ),

        dividerTheme: const DividerThemeData(
          color: AppColors.darkBorder,
          thickness: 1,
          space: 1,
        ),

        drawerTheme: DrawerThemeData(
          backgroundColor: AppColors.darkSidebarBackground,
          elevation: 8,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.darkSurfaceVariant,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.darkBorder, width: 1),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(_inputRadius),
            borderSide:
                const BorderSide(color: AppColors.primaryLight, width: 2),
          ),
          labelStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkMutedForeground,
          ),
          hintStyle: AppTextStyles.bodyMedium.copyWith(
            color: AppColors.darkMutedForeground.withAlpha(128),
          ),
        ),
      );
}

/// ──────────────────────────────────────────────────────────────────
///  App Spacing Scale (8dp system — Density 8/10)
///  ใช้ใน padding / gap / margin แทนค่า hardcode
/// ──────────────────────────────────────────────────────────────────
class AppSpacing {
  AppSpacing._();

  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xl2 = 32.0;
  static const double xl3 = 40.0;
  static const double xl4 = 48.0;
  static const double xl5 = 64.0;

  // ── Insets
  static const EdgeInsets cardPadding =
      EdgeInsets.all(AppSpacing.base);
  static const EdgeInsets cardPaddingDense =
      EdgeInsets.symmetric(horizontal: 14, vertical: 12);
  static const EdgeInsets screenPadding =
      EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  static const EdgeInsets sectionGap =
      EdgeInsets.only(bottom: AppSpacing.xl);

  // ── SizedBox helpers
  static const SizedBox gapXS = SizedBox(height: xs, width: xs);
  static const SizedBox gapSM = SizedBox(height: sm, width: sm);
  static const SizedBox gapMD = SizedBox(height: md, width: md);
  static const SizedBox gapBase = SizedBox(height: base, width: base);
  static const SizedBox gapLG = SizedBox(height: lg, width: lg);
  static const SizedBox gapXL = SizedBox(height: xl, width: xl);
  static const SizedBox gapXL2 = SizedBox(height: xl2, width: xl2);

  static SizedBox h(double v) => SizedBox(height: v);
  static SizedBox w(double v) => SizedBox(width: v);
}

/// ──────────────────────────────────────────────────────────────────
///  App Shadows
/// ──────────────────────────────────────────────────────────────────
class AppShadows {
  AppShadows._();

  static List<BoxShadow> get cardShadow => [
        BoxShadow(
          color: AppColors.cardShadow,
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ];

  static List<BoxShadow> get elevatedShadow => [
        BoxShadow(
          color: const Color(0x1A000000),
          blurRadius: 16,
          offset: const Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get sidebarShadow => [
        const BoxShadow(
          color: Color(0x30000000),
          blurRadius: 24,
          offset: Offset(4, 0),
        ),
      ];
}

/// ──────────────────────────────────────────────────────────────────
///  App Durations (Motion Guidelines — 5/10 Standard)
/// ──────────────────────────────────────────────────────────────────
class AppDurations {
  AppDurations._();

  /// Tap feedback, toggle: 150ms
  static const Duration micro = Duration(milliseconds: 150);

  /// Hover state, icon swap: 200ms
  static const Duration fast = Duration(milliseconds: 200);

  /// Modal open, page transition: 250ms
  static const Duration normal = Duration(milliseconds: 250);

  /// Card stagger, list load: 350ms
  static const Duration slow = Duration(milliseconds: 350);

  /// Chart animation, complex: 450ms
  static const Duration xSlow = Duration(milliseconds: 450);

  static const Curve defaultCurve = Curves.easeInOut;
  static const Curve enterCurve = Curves.easeOut;
  static const Curve exitCurve = Curves.easeIn;
}
