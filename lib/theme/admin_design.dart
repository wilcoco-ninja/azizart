import 'package:flutter/material.dart';
import 'admin_colors.dart';

/// Design system admin — une seule source de vérité.
class AdminDesign {
  AdminDesign._();

  // ─── SPACING ───
  static const double sp4  = 4;
  static const double sp8  = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;

  // ─── LAYOUT ───
  static const double formMaxWidth = 560;
  static const double pagePadH     = 16;
  static const double pagePadV     = 16;

  // ─── RADII ───
  static const double rSm   = 8;
  static const double rMd   = 12;
  static const double rLg   = 16;
  static const double rPill = 999;

  // ─── TYPO ───
  static const double fsAppBar    = 16;
  static const double fsSection   = 15;
  static const double fsCardTitle = 13;
  static const double fsBody      = 14;
  static const double fsLabel     = 12;
  static const double fsButton    = 14;

  // ─── BOUTONS ───
  static const double btnHeight   = 44;
  static const double btnMaxWidth = 280;

  // ─── DÉCORATIONS ───
  static BoxDecoration card() => BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(rMd),
        border: Border.all(color: AdminColors.border),
      );

  static ButtonStyle primaryButton() => ElevatedButton.styleFrom(
        backgroundColor: AdminColors.accent,
        foregroundColor: AdminColors.textOnAccent,
        elevation: 0,
        minimumSize: const Size.fromHeight(btnHeight),
        padding: const EdgeInsets.symmetric(horizontal: sp16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        textStyle: const TextStyle(
          fontSize: fsButton,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.1,
        ),
      );

  static ButtonStyle secondaryButton() => OutlinedButton.styleFrom(
        foregroundColor: AdminColors.accent,
        side: BorderSide(color: AdminColors.accent.withValues(alpha: 0.5)),
        minimumSize: const Size.fromHeight(btnHeight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(rSm)),
        textStyle: const TextStyle(fontSize: fsButton, fontWeight: FontWeight.w600),
      );

  static InputDecoration input({
    required String label,
    String? hint,
    Widget? prefixIcon,
    Widget? suffixIcon,
  }) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(rSm),
          borderSide: BorderSide(color: c, width: w),
        );
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      isDense: true,
      contentPadding:
          const EdgeInsets.symmetric(horizontal: sp12, vertical: sp12),
      labelStyle:
          const TextStyle(color: AdminColors.textMuted, fontSize: fsLabel),
      hintStyle: TextStyle(
        color: AdminColors.textMuted.withValues(alpha: 0.5),
        fontSize: fsLabel,
      ),
      filled: true,
      fillColor: AdminColors.bg.withValues(alpha: 0.4),
      border: border(AdminColors.border),
      enabledBorder: border(AdminColors.border),
      focusedBorder: border(AdminColors.accent, 1.2),
      errorBorder: border(AdminColors.danger),
      focusedErrorBorder: border(AdminColors.danger, 1.2),
    );
  }
}