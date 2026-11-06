import 'package:flutter/material.dart';

/// Clean Neo-brutalist Design System Color Palette for SakuKu
class AppColors {
  AppColors._();

  // --- Brand Colors ---
  static const Color primary = Color(0xFF2563EB); // Bold Cobalt Blue
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFFDBEAFE);

  // --- Background & Surface ---
  static const Color background = Color(0xFFF8FAFC); // Clean Off-White
  static const Color surface = Color(0xFFFFFFFF); // Crisp White
  static const Color surfaceVariant = Color(0xFFF1F5F9);

  // --- Financial Semantics ---
  static const Color income = Color(0xFF10B981); // Emerald Green
  static const Color incomeLight = Color(0xFFD1FAE5);
  static const Color expense = Color(0xFFEF4444); // Crimson / Coral Red
  static const Color expenseLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B); // Warm Amber
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color info = Color(0xFF0284C7); // Sky Blue
  static const Color infoLight = Color(0xFFE0F2FE);

  // --- Neutral & Borders (Neo-brutalist High Contrast) ---
  static const Color borderDark = Color(0xFF0F172A); // 2px Solid Dark Border
  static const Color borderSubtle = Color(0xFFCBD5E1); // Subtle divider border
  static const Color borderLight = Color(0xFFE2E8F0);

  // --- Typography ---
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textSecondary = Color(0xFF475569); // Slate 600
  static const Color textMuted = Color(0xFF94A3B8); // Slate 400
  static const Color textOnPrimary = Color(0xFFFFFFFF);

  // --- Offline Synchronization Status Colors ---
  static const Color syncSuccess = Color(0xFF10B981); // Synced
  static const Color syncPending = Color(0xFFF59E0B); // Pending Create/Update/Delete
  static const Color syncFailed = Color(0xFFEF4444); // Sync Failed

  // --- Neo-Glassmorphism Tokens ---
  static const Color glassSurface = Color(0xEEFFFFFF); // 93% Frosted White
  static const Color glassSurfaceDark = Color(0xD90F172A); // 85% Frosted Dark Slate
  static const Color glassCardTint = Color(0xCCF8FAFC); // 80% Frosted Tint
  static const Color glassHighlight = Color(0x80FFFFFF); // 50% Top Sheen Highlight
  static const Color glassBorderLight = Color(0x40FFFFFF); // Frosted Rim Light
}
