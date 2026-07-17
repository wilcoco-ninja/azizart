import 'package:flutter/material.dart';

/// 🎨 PALETTE AZIZART · TERRE & ÉMAIL
/// Nouvelle direction artistique : un fond profond "vin/brique" qui rappelle
/// les teintures batik, réchauffé par un accent ambre lumineux et ponctué de
/// touches franches (bleu pétrole, vert tilleul, lavande) — plus contrasté
/// et plus "atelier d'artiste" que la précédente palette pastel.
///
/// Couleurs sources fournies :
///   #D9F3E4  Menthe très pâle   (texte clair / highlights)
///   #007FA9  Bleu pétrole       (accent secondaire / Médias)
///   #B7CE66  Vert tilleul       (accent vif / détails)
///   #8FB43A  Vert sauge vif     (disponibilité / succès)
///   #BE9CC7  Lavande            (accent doux / Atelier)
///   #A9CEF4  Bleu ciel pâle     (variante claire du bleu pétrole)
///   #EE7A46  Orange brûlé       (accent chaud / "vendu")
///   #753E4E  Vin profond        (fond sombre / texte sur ambre)
///   #FFB83C  Ambre              (COULEUR PRINCIPALE / CTA)
class AzizColors {
  AzizColors._();

  // ══════════════════════════════════════════════════════════════════════════════
  // PALETTE BRUTE — les 9 couleurs sources, accessibles directement
  // ══════════════════════════════════════════════════════════════════════════════
  static const Color paletteMint = Color(0xFFD9F3E4);
  static const Color paletteTeal = Color(0xFF007FA9);
  static const Color paletteLime = Color(0xFFB7CE66);
  static const Color paletteSage = Color(0xFF8FB43A);
  static const Color paletteLavender = Color(0xFFBE9CC7);
  static const Color paletteSkyBlue = Color(0xFFA9CEF4);
  static const Color paletteBurntOrange = Color(0xFFEE7A46);
  static const Color paletteWine = Color(0xFF753E4E);
  static const Color paletteAmber = Color(0xFFFFB83C);

  // ══════════════════════════════════════════════════════════════════════════════
  // COULEURS PRINCIPALES — Terre & Émail
  // ══════════════════════════════════════════════════════════════════════════════

  /// 🍷 Vin Profond — FOND SOMBRE PRINCIPAL (ex Brun Olive Nuit)
  static const Color indigoDeep = paletteWine;

  /// 🔵 Bleu Pétrole — COULEUR SECONDAIRE (ex Sauge Bleutée)
  static const Color greenBatik = paletteTeal;

  /// 🟡 Ambre — ACCENT PRINCIPAL · BOUTONS CTA (ex Vert Menthe)
  static const Color saffron = paletteAmber;

  /// 🟠 Orange Brûlé — ACCENT CHAUD · BADGE "VENDU" (ex Brun Olive)
  static const Color terraCotta = paletteBurntOrange;

  // ══════════════════════════════════════════════════════════════════════════════
  // FONDS — Univers Vin Profond
  // ══════════════════════════════════════════════════════════════════════════════

  /// 🌑 Vin Profond — FOND SOMBRE · PRINCIPAL
  static const Color background = paletteWine;

  /// 🌃 Vin Nuit — FOND SOMBRE ALTERNATIF
  static const Color backgroundDark = Color(0xFF522C38);

  /// 🌆 Vin Adouci — FOND SECONDAIRE
  static const Color backgroundMedium = Color(0xFF8C4D5D);

  /// 🟤 Surface Vin — SURFACE DES CARTES
  static const Color surface = Color(0xFF693846);

  /// 🟤 Carte Vin — FOND DES CARTES
  static const Color card = Color(0xFF623441);

  /// 🟤 Carte Vin Alternative
  static const Color cardBackground = Color(0xFF693846);

  /// 🌿 Menthe Très Pâle — FOND CLAIR
  /// Utilisé pour le thème clair et les zones lumineuses.
  static const Color mistIndigo = paletteMint;

  // ══════════════════════════════════════════════════════════════════════════════
  // ACCENTS & DÉCLINAISONS
  // ══════════════════════════════════════════════════════════════════════════════

  /// 🟡 Ambre Clair — pour survols et états actifs
  static const Color saffronLight = Color(0xFFFFD37D);

  /// 🟡 Ambre Foncé — pour états pressés
  static const Color saffronDark = Color(0xFFD89328);

  /// 🔵 Bleu Ciel Pâle — variante claire du bleu pétrole (fournie dans la palette)
  static const Color greenBatikLight = paletteSkyBlue;

  /// 🔵 Bleu Pétrole Foncé — pour profondeur
  static const Color greenBatikDark = Color(0xFF015C7D);

  /// 🍷 Vin Clair — pour éléments secondaires
  static const Color indigoLight = Color(0xFF9A5C6C);

  /// 🟠 Orange Brûlé Clair — pour variations chaudes
  static const Color terraCottaLight = Color(0xFFF3A179);

  // ══════════════════════════════════════════════════════════════════════════════
  // ACCENTS COMPLÉMENTAIRES — Vert Tilleul & Lavande
  // ══════════════════════════════════════════════════════════════════════════════
  // Apportés par la nouvelle palette pour diversifier les catégories de la
  // Galerie et les petites touches décoratives (badges de catégorie, puces,
  // icônes), sans toucher aux rôles déjà établis ci-dessus.

  /// 🟢 Vert Tilleul — accent vif (catégories, détails, hover secondaire)
  static const Color lime = paletteLime;

  /// 🌸 Lavande — accent doux (catégories, Atelier, détails délicats)
  static const Color lavender = paletteLavender;

  // ══════════════════════════════════════════════════════════════════════════════
  // TEXTE — Menthe Très Pâle & déclinaisons
  // ══════════════════════════════════════════════════════════════════════════════

  /// 📜 Menthe Très Pâle — TEXTE PRINCIPAL (sur fonds sombres)
  static const Color textPrimary = paletteMint;

  /// 📜 Menthe Adoucie — TEXTE SECONDAIRE
  static const Color textSecondary = Color(0xFFB9D9C7);

  /// 📜 Menthe Estompée — TEXTE TERTIAIRE / MUTED
  static const Color textMuted = Color(0xFF8FAE9C);

  /// 📜 Texte sur accent (ambre) — pour lisibilité
  static const Color textOnAccent = paletteWine;

  // ══════════════════════════════════════════════════════════════════════════════
  // BORDURES & SÉPARATEURS
  // ══════════════════════════════════════════════════════════════════════════════

  static const Color border = Color(0xFF8C5C68);
  static const Color cardBorder = Color(0xFF8C5C68);
  static const Color divider = Color(0xFF8C5C68);

  // ══════════════════════════════════════════════════════════════════════════════
  // OVERLAY
  // ══════════════════════════════════════════════════════════════════════════════

  /// Couleur de superposition semi-transparente (ex : VENDU sur image)
  static const Color overlay = Color(0x8C753E4E); // Vin profond 55%

  // ══════════════════════════════════════════════════════════════════════════════
  // DISPONIBILITÉ DES ŒUVRES
  // ══════════════════════════════════════════════════════════════════════════════

  /// ✅ Vert Sauge Vif pour les œuvres disponibles
  static const Color available = paletteSage;

  /// ❌ Orange Brûlé pour les œuvres vendues
  static const Color unavailable = paletteBurntOrange;

  // ══════════════════════════════════════════════════════════════════════════════
  // ÉTATS & FEEDBACK
  // ══════════════════════════════════════════════════════════════════════════════

  static const Color error =
      Color(0xFFD45B43); // dérivé orange brûlé, plus rouge
  static const Color success = paletteSage; // vert sauge vif pour succès

  // ══════════════════════════════════════════════════════════════════════════════
  // DÉGRADÉS — Harmonie Terre & Émail
  // ══════════════════════════════════════════════════════════════════════════════

  /// Dégradé principal — du Vin Nuit au Vin Profond
  static LinearGradient get bannerGradient => const LinearGradient(
        colors: [Color(0xFF522C38), Color(0xFF753E4E), Color(0xFF522C38)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dégradé Ambre — pour boutons et CTA
  static LinearGradient get saffronGradient => const LinearGradient(
        colors: [Color(0xFFFFB83C), Color(0xFFFFD37D), Color(0xFFFFB83C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dégradé Vin — pour éléments secondaires
  static LinearGradient get indigoGradient => const LinearGradient(
        colors: [Color(0xFF753E4E), Color(0xFF9A5C6C)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dégradé Orange Brûlé — pour accents chauds
  static LinearGradient get terraCottaGradient => const LinearGradient(
        colors: [Color(0xFFEE7A46), Color(0xFFD45B43)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dégradé Bleu Pétrole — pour éléments naturels
  static LinearGradient get greenBatikGradient => const LinearGradient(
        colors: [Color(0xFF007FA9), Color(0xFFA9CEF4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dégradé Vert Tilleul / Sauge — pour badges "disponible" et accents nature
  static LinearGradient get limeGradient => const LinearGradient(
        colors: [Color(0xFFB7CE66), Color(0xFF8FB43A)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  /// Dégradé Lavande — pour accents doux (Atelier, catégories)
  static LinearGradient get lavenderGradient => const LinearGradient(
        colors: [Color(0xFFBE9CC7), Color(0xFF9A6FA4)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      );

  // ══════════════════════════════════════════════════════════════════════════════
  // THÈME CLAIR — Page d'accueil (Home page)
  // Ces couleurs permettent au home_page.dart d'utiliser un fond crème/lin
  // élégant qui contraste avec le thème sombre des autres pages (wine/vin).
  // ══════════════════════════════════════════════════════════════════════════════

  /// 🏠 Fond principal crème/lin — home page
  static const Color lightBackground = Color(0xFFF8F4EE);

  /// 🏠 Fond alternatif légèrement plus chaud — sections alternées home
  static const Color lightBackgroundAlt = Color(0xFFF2EDE5);

  /// 🏠 Surface des cartes home — légèrement contrastée
  static const Color lightSurface = Color(0xFFEDE8E0);

  /// 🏠 Fond des cartes home — ton lin foncé
  static const Color lightCard = Color(0xFFE8E2D8);

  /// 📝 Texte principal — brun foncé (lisible sur fond crème)
  static const Color lightTextPrimary = Color(0xFF2C1A12);

  /// 📝 Texte secondaire — brun moyen
  static const Color lightTextSecondary = Color(0xFF6B5B4E);

  /// 📝 Texte atténué / muted — brun clair
  static const Color lightTextMuted = Color(0xFF9E8C7D);

  /// 🔲 Bordure légère — séparateur discret sur fond clair
  static const Color lightBorder = Color(0xFFD4C8BB);

  // ══════════════════════════════════════════════════════════════════════════════
  // ALIASES DE COMPATIBILITÉ
  // Pour assurer la transition avec l'ancien code (artwork_card.dart, navbar.dart…)
  // ══════════════════════════════════════════════════════════════════════════════

  /// @deprecated Utiliser [indigoDeep] à la place
  static const Color indigo = indigoDeep;

  /// @deprecated Utiliser [background] à la place
  @Deprecated('Utiliser background ou backgroundDark selon le contexte')
  static const Color accent = saffron;

  /// @deprecated Utiliser [saffronLight] à la place
  @Deprecated('Utiliser saffronLight')
  static const Color accentLight = saffronLight;

  /// @deprecated Utiliser [saffronDark] à la place
  @Deprecated('Utiliser saffronDark')
  static const Color accentDark = saffronDark;

  /// @deprecated Utiliser [saffron] à la place (ambre, accent principal)
  @Deprecated('Utiliser saffron (ambre)')
  static const Color gold = saffron;

  /// @deprecated Utiliser [saffronLight] à la place
  @Deprecated('Utiliser saffronLight')
  static const Color goldLight = saffronLight;

  /// @deprecated Utiliser [terraCotta] à la place
  @Deprecated('Utiliser terraCotta')
  static const Color terracotta = terraCotta;

  /// @deprecated Utiliser [indigoLight] à la place
  @Deprecated('Utiliser indigoLight')
  static const Color indigoDark = indigoLight;

  /// Dégradé ambre — alias pour compatibilité
  /// @deprecated Utiliser [saffronGradient]
  @Deprecated('Utiliser saffronGradient')
  static LinearGradient get goldGradient => saffronGradient;

  /// Dégradé orange brûlé — alias pour compatibilité
  /// @deprecated Utiliser [terraCottaGradient]
  @Deprecated('Utiliser terraCottaGradient')
  static LinearGradient get terracottaGradient => terraCottaGradient;
}
