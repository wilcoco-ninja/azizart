import 'package:flutter/material.dart';

/// 🎨 PALETTE AZIZART COLORS — mur de galerie, encre indigo, accents ambre.
class AzizColors {
  AzizColors._();

  // ══════════════════════════════════════════════════════════════════════
  // ── Direction "Immersion Indigo" — accueil public (v3) ──────────────────
  // ══════════════════════════════════════════════════════════════════════
  static const Color dyeVoid = Color(0xFF0A0D1C);
  static const Color dyeSurface = Color(0xFF161B3D);
  static const Color dyeSurfaceHi = Color(0xFF232A5C);
  static const Color dyeCurrent = Color(0xFF6B74E8);
  static const Color dyeGold = Color(0xFFC9A24B);
  static const Color dyeGoldLight = Color(0xFFE3C275);
  static const Color dyeParchment = Color(0xFFEDE6D6);
  static const Color dyeDust = Color(0xFF8B87A8);

  // ══════════════════════════════════════════════════════════════════════
  // PALETTE BRUTE
  // ══════════════════════════════════════════════════════════════════════
  static const Color paletteTeal = Color(0xFF007FA9);
  static const Color paletteLime = Color(0xFFB7CE66);
  static const Color paletteSage = Color(0xFF8FB43A);
  static const Color paletteLavender = Color(0xFFBE9CC7);
  static const Color paletteSkyBlue = Color(0xFFA9CEF4);
  static const Color paletteBurntOrange = Color(0xFFEE7A46);
  static const Color paletteWine = Color(0xFF753E4E);
  static const Color paletteAmber = Color(0xFFFFB83C);

  // ══════════════════════════════════════════════════════════════════════
  // ✨ ACCENT SIGNATURE — le véritable Indigo
  // ══════════════════════════════════════════════════════════════════════
  static const Color trueIndigo = Color(0xFF223A63);
  static const Color trueIndigoLight = Color(0xFF4C6690);
  static const Color trueIndigoDark = Color(0xFF152845);

  static LinearGradient get trueIndigoGradient => const LinearGradient(
        colors: [trueIndigoDark, trueIndigo, trueIndigoLight],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ══════════════════════════════════════════════════════════════════════
  // COULEURS PRINCIPALES
  // ══════════════════════════════════════════════════════════════════════
  static const Color deepWine = paletteWine;
  static const Color petrolBlue = paletteTeal;
  static const Color saffron = paletteAmber;
  static const Color terraCotta = paletteBurntOrange;

  // ══════════════════════════════════════════════════════════════════════
  // FONDS SOMBRES (admin, bandes de contraste)
  // ══════════════════════════════════════════════════════════════════════
  static const Color background = paletteWine;
  static const Color backgroundDark = Color(0xFF522C38);
  static const Color backgroundMedium = Color(0xFF8C4D5D);
  static const Color surface = Color(0xFF693846);
  static const Color card = Color(0xFF623441);
  static const Color cardBackground = Color(0xFF693846);

  // ══════════════════════════════════════════════════════════════════════
  // ACCENTS & DÉCLINAISONS
  // ══════════════════════════════════════════════════════════════════════
  static const Color saffronLight = Color(0xFFFFD37D);
  static const Color saffronDark = Color(0xFFD89328);
  static const Color petrolBlueLight = paletteSkyBlue;
  static const Color petrolBlueDark = Color(0xFF015C7D);
  static const Color wineLight = Color(0xFF9A5C6C);
  static const Color terraCottaLight = Color(0xFFF3A179);

  static const Color lime = paletteLime;
  static const Color lavender = paletteLavender;

  // ══════════════════════════════════════════════════════════════════════
  // TEXTE — sur fonds foncés
  // ══════════════════════════════════════════════════════════════════════
  static const Color textPrimary = Color(0xFFC8CEF0);
  static const Color textSecondary = Color(0xFFA0A8D0);
  static const Color textMuted = Color(0xFF7B85AE);
  static const Color textOnAccent = paletteWine;

  // ══════════════════════════════════════════════════════════════════════
  // TEXTE — indigo foncé, pour fonds clairs
  // ══════════════════════════════════════════════════════════════════════
  static const Color textIndigoDeeper = trueIndigoDark;
  static const Color textIndigoDark = trueIndigo;
  static const Color textIndigo = trueIndigoLight;

  // ══════════════════════════════════════════════════════════════════════
  // ÉLÉMENTS D'INTERFACE
  // ══════════════════════════════════════════════════════════════════════
  static const Color border = Color(0xFF8C5C68);
  static const Color cardBorder = Color(0xFF8C5C68);
  static const Color divider = Color(0xFF8C5C68);
  static const Color overlay = Color(0x8C753E4E);
  static const Color available = paletteSage;
  static const Color unavailable = paletteBurntOrange;
  static const Color error = Color(0xFFD45B43);
  static const Color success = paletteSage;

  // ══════════════════════════════════════════════════════════════════════
  // DÉGRADÉS
  // ══════════════════════════════════════════════════════════════════════
  static LinearGradient get bannerGradient => const LinearGradient(
        colors: [Color(0xFF522C38), Color(0xFF753E4E), Color(0xFF522C38)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient get saffronGradient => const LinearGradient(
        colors: [Color(0xFFFFB83C), Color(0xFFFFD37D), Color(0xFFFFB83C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient get wineGradient => const LinearGradient(
        colors: [Color(0xFF753E4E), Color(0xFF9A5C6C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient get terraCottaGradient => const LinearGradient(
        colors: [Color(0xFFEE7A46), Color(0xFFD45B43)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient get petrolBlueGradient => const LinearGradient(
        colors: [Color(0xFF007FA9), Color(0xFFA9CEF4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient get limeGradient => const LinearGradient(
        colors: [Color(0xFFB7CE66), Color(0xFF8FB43A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient get lavenderGradient => const LinearGradient(
        colors: [Color(0xFFBE9CC7), Color(0xFF9A6FA4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );
  static LinearGradient get heroVeil => LinearGradient(
        colors: [
          trueIndigoDark.withValues(alpha: 0.15),
          trueIndigoDark.withValues(alpha: 0.42),
          trueIndigoDark.withValues(alpha: 0.88),
        ],
        stops: const [0.0, 0.42, 1.0],
        begin: Alignment.topRight,
        end: Alignment.bottomLeft,
      );

  // ══════════════════════════════════════════════════════════════════════
  // THÈME CLAIR — « mur de galerie »
  // Blanc neutre, filets gris, passe-partout blanc, encre indigo.
  // ══════════════════════════════════════════════════════════════════════
  static const Color lightBackground = Color(0xFFF4F4F1);
  static const Color lightBackgroundAlt = Color(0xFFEAEAE6);
  static const Color lightSurface = Color(0xFFE2E2DD);
  static const Color lightCard = Color(0xFFD9D9D3);
  static const Color lightBorder = Color(0xFFCFCFC8);

  /// Passe-partout des œuvres.
  static const Color mat = Color(0xFFFFFFFF);

  static const Color lightTextPrimary = trueIndigoDark;
  static const Color lightTextSecondary = Color(0xFF3B4A63);
  static const Color lightTextMuted = trueIndigoLight;

  // ══════════════════════════════════════════════════════════════════════
  // 🔄 ALIAS DE COMPATIBILITÉ (anciens noms → nouveaux noms)
  // ══════════════════════════════════════════════════════════════════════

  /// Alias historique — préférer `saffron` (ou `dyeGold`).
  static const Color accent = saffron;

  /// Alias historique — préférer `petrolBlue`.
  static const Color greenBatik = petrolBlue;

  /// Alias historique (casse) — préférer `terraCotta` (camelCase).
  static const Color terracotta = terraCotta;

  /// Alias historique (casse) — préférer `terraCottaGradient`.
  static LinearGradient get terracottaGradient => terraCottaGradient;

  /// Alias historique — préférer `saffron` (ou `dyeGold`).
  static const Color gold = saffron;

  /// Alias historique — préférer `trueIndigoGradient`.
  static LinearGradient get indigoGradient => trueIndigoGradient;
}