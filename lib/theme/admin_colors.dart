import 'package:flutter/material.dart';

class AdminColors {
  AdminColors._();

  // FONDS
  static const Color bg = Color(0xFF0A0D1C);
  static const Color surface = Color(0xFF161B3D);
  static const Color surfaceHi = Color(0xFF232A5C);
  static const Color surfaceElevated = Color(0xFF1D2450);

  // BORDURES
  static const Color border = Color(0xFF262C52);
  static const Color borderHi = Color(0xFF354072);

  // ACCENT
  static const Color accent = Color(0xFFC9A24B);
  static const Color accentHi = Color(0xFFE3C275);
  static const Color accentDim = Color(0xFFA17F3B);
  static const Color current = Color(0xFF6B74E8);

  // TEXTE
  static const Color text = Color(0xFFEDE6D6);
  static const Color textSecondary = Color(0xFFB9B4CF);
  static const Color textMuted = Color(0xFF8B87A8);
  static const Color textOnAccent = Color(0xFF0A0D1C);

  // ÉTATS
  static const Color danger = Color(0xFFE05A43);
  static const Color success = Color(0xFF4CB287);
  static const Color warning = Color(0xFFE8A23F);
  static const Color info = Color(0xFF5AA9D6);

  // HELPERS
  static Color get borderSoft   => border.withValues(alpha: 0.6);
  static Color get borderSubtle => border.withValues(alpha: 0.35);
  static Color get accentSoft   => accent.withValues(alpha: 0.12);
  static Color get accentSofter => accent.withValues(alpha: 0.08);
  static Color get currentSoft  => current.withValues(alpha: 0.12);
  static Color get dangerSoft   => danger.withValues(alpha: 0.10);
  static Color get surfaceTint  => surfaceHi.withValues(alpha: 0.55);

  static LinearGradient get accentGradient => const LinearGradient(
        colors: [accentHi, accent],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
}