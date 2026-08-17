import 'package:flutter/material.dart';
import 'app_colors.dart';

/// ──────────────────────────────────────────────────────────────────
///  ERP App — Typography Tokens
///  Pairing: "Dashboard Data" — Fira Code (numbers/KPI) + Fira Sans (body)
///  Source: Design System MASTER.md (ui-ux-pro-max)
/// ──────────────────────────────────────────────────────────────────
///
///  Note: เพิ่ม google_fonts ใน pubspec.yaml:
///    google_fonts: ^6.2.1
///  แล้วรัน: flutter pub get
///
///  ถ้าไม่ต้องการใช้ google_fonts ให้ใช้ system font fallback ด้านล่าง
/// ──────────────────────────────────────────────────────────────────
class AppTextStyles {
  AppTextStyles._();

  // ── Base font families
  static const String _heading = 'FiraCode';
  static const String _body = 'FiraSans';

  // ─────────────────────────────────────────
  //  DISPLAY / HERO
  // ─────────────────────────────────────────

  /// ใช้กับ: Page title, Screen header ใหญ่
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _heading,
    fontSize: 32,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.foreground,
  );

  /// ใช้กับ: Dashboard title, Section heading
  static const TextStyle displayMedium = TextStyle(
    fontFamily: _heading,
    fontSize: 26,
    fontWeight: FontWeight.w700,
    height: 1.25,
    letterSpacing: -0.3,
    color: AppColors.foreground,
  );

  // ─────────────────────────────────────────
  //  HEADINGS
  // ─────────────────────────────────────────

  /// ใช้กับ: Card header, Section title
  static const TextStyle headingLarge = TextStyle(
    fontFamily: _body,
    fontSize: 20,
    fontWeight: FontWeight.w600,
    height: 1.3,
    letterSpacing: -0.2,
    color: AppColors.foreground,
  );

  /// ใช้กับ: Widget title, Dialog title
  static const TextStyle headingMedium = TextStyle(
    fontFamily: _body,
    fontSize: 17,
    fontWeight: FontWeight.w600,
    height: 1.35,
    color: AppColors.foreground,
  );

  /// ใช้กับ: Table column header, Sub-section
  static const TextStyle headingSmall = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.4,
    color: AppColors.foreground,
  );

  // ─────────────────────────────────────────
  //  KPI / NUMBERS (Fira Code — tabular figures)
  // ─────────────────────────────────────────

  /// ใช้กับ: KPI card number ใหญ่ (Revenue, Orders)
  static const TextStyle kpiHero = TextStyle(
    fontFamily: _heading,
    fontSize: 36,
    fontWeight: FontWeight.w700,
    height: 1.1,
    letterSpacing: -1,
    color: AppColors.foreground,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// ใช้กับ: KPI card number กลาง
  static const TextStyle kpiLarge = TextStyle(
    fontFamily: _heading,
    fontSize: 28,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
    color: AppColors.foreground,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// ใช้กับ: Table number, Price, Amount
  static const TextStyle kpiMedium = TextStyle(
    fontFamily: _heading,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.foreground,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  /// ใช้กับ: Small numeric badge, footnote
  static const TextStyle kpiSmall = TextStyle(
    fontFamily: _heading,
    fontSize: 13,
    fontWeight: FontWeight.w500,
    height: 1.4,
    color: AppColors.mutedForeground,
    fontFeatures: [FontFeature.tabularFigures()],
  );

  // ─────────────────────────────────────────
  //  BODY TEXT
  // ─────────────────────────────────────────

  /// ใช้กับ: Main content, paragraph, description
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _body,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.5,
    color: AppColors.foreground,
  );

  /// ใช้กับ: Table cell, list item, form content
  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.45,
    color: AppColors.foreground,
  );

  /// ใช้กับ: Helper text, caption, secondary info
  static const TextStyle bodySmall = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.mutedForeground,
  );

  // ─────────────────────────────────────────
  //  LABELS / UI ELEMENTS
  // ─────────────────────────────────────────

  /// ใช้กับ: Button text, Tab label
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _body,
    fontSize: 15,
    fontWeight: FontWeight.w600,
    height: 1.2,
    letterSpacing: 0.1,
    color: AppColors.foreground,
  );

  /// ใช้กับ: Tag, Badge, Chip
  static const TextStyle labelMedium = TextStyle(
    fontFamily: _body,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.2,
    color: AppColors.foreground,
  );

  /// ใช้กับ: Footer note, Timestamp, Metadata
  static const TextStyle labelSmall = TextStyle(
    fontFamily: _body,
    fontSize: 11,
    fontWeight: FontWeight.w500,
    height: 1.2,
    letterSpacing: 0.3,
    color: AppColors.mutedForeground,
  );

  // ─────────────────────────────────────────
  //  NAV / SIDEBAR
  // ─────────────────────────────────────────

  /// ใช้กับ: Sidebar menu item
  static const TextStyle navItem = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.3,
    color: AppColors.sidebarForeground,
  );

  /// ใช้กับ: Sidebar active menu item
  static const TextStyle navItemActive = TextStyle(
    fontFamily: _body,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.3,
    color: AppColors.onPrimary,
  );

  // ─────────────────────────────────────────
  //  STATUS / SEMANTIC COLORS
  // ─────────────────────────────────────────

  static TextStyle statusSuccess({double size = 12}) => bodySmall.copyWith(
        color: AppColors.success,
        fontSize: size,
        fontWeight: FontWeight.w500,
      );

  static TextStyle statusError({double size = 12}) => bodySmall.copyWith(
        color: AppColors.destructive,
        fontSize: size,
        fontWeight: FontWeight.w500,
      );

  static TextStyle statusWarning({double size = 12}) => bodySmall.copyWith(
        color: AppColors.warning,
        fontSize: size,
        fontWeight: FontWeight.w500,
      );
}

/// ──────────────────────────────────────────────────────────────────
///  MaterialApp textTheme ที่ครบถ้วน — ส่งเข้า AppTheme
/// ──────────────────────────────────────────────────────────────────
class AppTypography {
  AppTypography._();

  static const TextTheme textTheme = TextTheme(
    displayLarge: AppTextStyles.displayLarge,
    displayMedium: AppTextStyles.displayMedium,
    displaySmall: AppTextStyles.headingLarge,
    headlineLarge: AppTextStyles.headingLarge,
    headlineMedium: AppTextStyles.headingMedium,
    headlineSmall: AppTextStyles.headingSmall,
    titleLarge: AppTextStyles.headingMedium,
    titleMedium: AppTextStyles.headingSmall,
    titleSmall: AppTextStyles.labelLarge,
    bodyLarge: AppTextStyles.bodyLarge,
    bodyMedium: AppTextStyles.bodyMedium,
    bodySmall: AppTextStyles.bodySmall,
    labelLarge: AppTextStyles.labelLarge,
    labelMedium: AppTextStyles.labelMedium,
    labelSmall: AppTextStyles.labelSmall,
  );
}
