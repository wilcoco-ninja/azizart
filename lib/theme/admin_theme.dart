import 'package:flutter/material.dart';
import 'aziz_colors.dart';

/// Palette du back-office, alignée sur AzizColors.
/// Ajuste les valeurs littérales (surfaceHi) selon ton thème réel.
class AdminColors {
  AdminColors._();

  static const Color accent = AzizColors.saffron;
  static const Color danger = AzizColors.error;
  static const Color surface = AzizColors.surface;
  static const Color surfaceHi = Color(0xFF2A2A2E);
  static const Color border = AzizColors.cardBorder;
  static const Color text = AzizColors.textPrimary;
  static const Color textMuted = AzizColors.textMuted;
}

/// Tokens de design du back-office (espacements, rayons, tailles de texte).
class AdminDesign {
  AdminDesign._();

  // Espacements
  static const double sp4 = 4;
  static const double sp8 = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp24 = 24;

  // Rayons
  static const double rMd = 12;

  // Tailles de texte
  static const double fsLabel = 13;
  static const double fsBody = 15;
}