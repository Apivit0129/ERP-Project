import 'package:flutter/material.dart';

/// ──────────────────────────────────────────────────────────────────
///  ERP App — Color Tokens
///  Palette: "Teal Professional"
///  Source: Design System MASTER.md (ui-ux-pro-max)
///  WCAG AA compliant
/// ──────────────────────────────────────────────────────────────────
class AppColors {
  AppColors._();

  // ── Primary ── Teal 600
  static const Color primary = Color(0xFF0D9488);
  static const Color primaryLight = Color(0xFF14B8A6); // Teal 400
  static const Color primaryDark = Color(0xFF0F766E); // Teal 700
  static const Color onPrimary = Color(0xFFFFFFFF);

  // ── Secondary ── Teal 400
  static const Color secondary = Color(0xFF14B8A6);
  static const Color onSecondary = Color(0xFF134E4A);

  // ── Accent / CTA ── Orange 600 (WCAG 3:1 adjusted)
  static const Color accent = Color(0xFFEA580C);
  static const Color accentLight = Color(0xFFFB923C); // Orange 400
  static const Color onAccent = Color(0xFFFFFFFF);

  // ── Surface / Background
  static const Color background = Color(0xFFF0FDFA); // Teal 50
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFE8F1F4);

  // ── Foreground / Text
  static const Color foreground = Color(0xFF134E4A); // Teal 900
  static const Color onSurface = Color(0xFF134E4A);
  static const Color mutedForeground = Color(0xFF64748B); // Slate 500

  // ── Muted Background
  static const Color muted = Color(0xFFE8F1F4);

  // ── Border
  static const Color border = Color(0xFF99F6E4); // Teal 200
  static const Color borderStrong = Color(0xFF5EEAD4); // Teal 300
  static const Color ring = Color(0xFF0D9488);

  // ── Semantic
  static const Color destructive = Color(0xFFDC2626); // Red 600
  static const Color onDestructive = Color(0xFFFFFFFF);
  static const Color success = Color(0xFF059669); // Emerald 600
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = Color(0xFFF59E0B); // Amber 500
  static const Color onWarning = Color(0xFF1C1917);
  static const Color info = Color(0xFF0369A1); // Sky 700
  static const Color onInfo = Color(0xFFFFFFFF);

  // ── Sidebar specific
  static const Color sidebarBackground = Color(0xFF134E4A); // Teal 900
  static const Color sidebarForeground = Color(0xFFCCFBF1); // Teal 100
  static const Color sidebarItem = Color(0xFF1A6460);
  static const Color sidebarItemActive = Color(0xFF0D9488);
  static const Color sidebarItemHover = Color(0xFF115E59); // Teal 800

  // ── Card / KPI specific
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color cardBorder = Color(0xFFCCFBF1); // Teal 100
  static const Color cardShadow = Color(0x1A0D9488); // Primary @ 10%

  // ── Chart colors (for fl_chart)
  static const Color chart1 = Color(0xFF0D9488);
  static const Color chart2 = Color(0xFFEA580C);
  static const Color chart3 = Color(0xFF059669);
  static const Color chart4 = Color(0xFFF59E0B);
  static const Color chart5 = Color(0xFF6366F1);
  static const Color chart6 = Color(0xFFEC4899);

  // ─────────────────────────────────────────
  //  DARK MODE TOKENS
  // ─────────────────────────────────────────

  static const Color darkBackground = Color(0xFF042F2E); // Teal 950
  static const Color darkSurface = Color(0xFF0D3B38);
  static const Color darkSurfaceVariant = Color(0xFF134E4A);
  static const Color darkForeground = Color(0xFFCCFBF1); // Teal 100
  static const Color darkMutedForeground = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1A6460);
  static const Color darkMuted = Color(0xFF115E59);
  static const Color darkSidebarBackground = Color(0xFF021B1A);
  static const Color darkCardBackground = Color(0xFF0D3B38);
}
