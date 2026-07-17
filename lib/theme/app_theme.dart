import 'package:flutter/material.dart';
import 'aziz_colors.dart';

/// 🎨 THÈME AZIZART · OASIS VÉGÉTALE
/// Nouvelle direction visuelle, plus fraîche et organique :
/// - Fonds brun olive profond, chaleureux et feutré
/// - Accents vert menthe lumineux pour les actions principales
/// - Touches sauge bleutée pour les éléments secondaires
/// - Texte citron pâle pour une lisibilité douce et naturelle
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Playfair Display';
  static const String _fontFamilyBody = 'Raleway';

  static ThemeData get theme => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // ══════════════════════════════════════════════════════════════════════════════
    // ColorScheme — Palette Oasis Végétale
    // ══════════════════════════════════════════════════════════════════════════════

    final colorScheme = isDark
        ? const ColorScheme.dark(
            // Primaire : Vert Menthe — boutons CTA, actions principales
            primary: AzizColors.saffron,
            // Secondaire : Sauge Bleutée — éléments calmes, info
            secondary: AzizColors.greenBatik,
            // Surface : Olive moyen pour les cartes et surfaces
            surface: AzizColors.surface,
            // Erreur : Rouge doux pour les erreurs
            error: AzizColors.error,
            // Texte sur primaire (menthe) : Olive nuit pour contraste
            onPrimary: AzizColors.textOnAccent,
            // Texte sur secondaire (sauge) : Citron pour lisibilité
            onSecondary: AzizColors.textOnAccent,
            // Texte sur surface : Citron Pâle
            onSurface: AzizColors.textPrimary,
          )
        : const ColorScheme.light(
            // Mode clair : fonds Citron Pâle, accents Menthe
            primary: AzizColors.saffron,
            secondary: AzizColors.greenBatik,
            surface: AzizColors.mistIndigo,
            error: AzizColors.error,
            onPrimary: AzizColors.textOnAccent,
            onSecondary: AzizColors.textOnAccent,
            onSurface: AzizColors.background,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: _fontFamilyBody,
      // Fond principal : Olive Nuit (sombre) ou Citron Pâle (clair)
      scaffoldBackgroundColor:
          isDark ? AzizColors.background : AzizColors.mistIndigo,

      // ════════════════════════════════════════════════════════════════════════════
      // AppBar — Bandeau Olive Profond
      // ════════════════════════════════════════════════════════════════════════════
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AzizColors.backgroundMedium : AzizColors.indigoDeep,
        foregroundColor: AzizColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AzizColors.saffron,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: 3,
        ),
        iconTheme: const IconThemeData(color: AzizColors.textPrimary),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Card — Cartes Olive, coins plus doux pour un rendu organique
      // ════════════════════════════════════════════════════════════════════════════
      cardTheme: CardThemeData(
        color: isDark ? AzizColors.cardBackground : AzizColors.mistIndigo,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: isDark ? AzizColors.cardBorder : AzizColors.indigoLight,
            width: 0.6,
          ),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Dialog — Fenêtres modales Olive
      // ════════════════════════════════════════════════════════════════════════════
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AzizColors.backgroundMedium : AzizColors.mistIndigo,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        titleTextStyle: const TextStyle(
          fontFamily: _fontFamily,
          color: AzizColors.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w400,
        ),
        contentTextStyle: TextStyle(
          color: isDark ? AzizColors.textSecondary : AzizColors.background,
          fontSize: 14,
        ),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // TabBar — Onglets Vert Menthe
      // ════════════════════════════════════════════════════════════════════════════
      tabBarTheme: const TabBarThemeData(
        labelColor: AzizColors.saffron,
        unselectedLabelColor: AzizColors.textMuted,
        indicatorColor: AzizColors.saffron,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle:
            TextStyle(fontWeight: FontWeight.w400, fontSize: 13),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // ElevatedButton — Boutons Vert Menthe (CTA principaux)
      // ════════════════════════════════════════════════════════════════════════════
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AzizColors.textMuted;
            }
            return AzizColors.saffron;
          }),
          foregroundColor: WidgetStateProperty.all(AzizColors.textOnAccent),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AzizColors.saffronDark.withValues(alpha: 0.3);
            }
            return null;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return 2;
          }),
        ),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // OutlinedButton — Boutons contour Vert Menthe
      // ════════════════════════════════════════════════════════════════════════════
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AzizColors.textMuted;
            }
            return AzizColors.saffron;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AzizColors.textMuted);
            }
            return const BorderSide(color: AzizColors.saffron, width: 1.2);
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AzizColors.saffron.withValues(alpha: 0.1);
            }
            return null;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // TextButton — Boutons texte Vert Menthe
      // ════════════════════════════════════════════════════════════════════════════
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AzizColors.saffron),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AzizColors.saffron.withValues(alpha: 0.08);
            }
            return null;
          }),
        ),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // InputDecoration — Champs Olive
      // ════════════════════════════════════════════════════════════════════════════
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AzizColors.surface : AzizColors.mistIndigo,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: const TextStyle(color: AzizColors.textMuted, fontSize: 14),
        labelStyle:
            const TextStyle(color: AzizColors.textSecondary, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? AzizColors.border : AzizColors.indigoLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
              color: isDark ? AzizColors.border : AzizColors.indigoLight,
              width: 0.8),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AzizColors.saffron, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AzizColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AzizColors.error, width: 1.5),
        ),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Text — Typographie Citron Pâle
      // ════════════════════════════════════════════════════════════════════════════
      textTheme: TextTheme(
        displayLarge: const TextStyle(
            fontFamily: _fontFamily,
            color: AzizColors.textPrimary,
            fontSize: 48,
            fontWeight: FontWeight.w300,
            letterSpacing: 2),
        displayMedium: const TextStyle(
            fontFamily: _fontFamily,
            color: AzizColors.textPrimary,
            fontSize: 36,
            fontWeight: FontWeight.w300),
        displaySmall: const TextStyle(
            fontFamily: _fontFamily,
            color: AzizColors.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w400),
        headlineLarge: const TextStyle(
            fontFamily: _fontFamily,
            color: AzizColors.textPrimary,
            fontSize: 24,
            fontWeight: FontWeight.w400),
        headlineMedium: const TextStyle(
            fontFamily: _fontFamily,
            color: AzizColors.textPrimary,
            fontSize: 20,
            fontWeight: FontWeight.w400),
        headlineSmall: const TextStyle(
            fontFamily: _fontFamily,
            color: AzizColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w400),
        titleLarge: TextStyle(
            color: isDark ? AzizColors.textPrimary : AzizColors.background,
            fontSize: 16,
            fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: isDark ? AzizColors.textPrimary : AzizColors.background,
            fontSize: 14,
            fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: isDark ? AzizColors.textSecondary : AzizColors.background,
            fontSize: 12,
            fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(
            color: isDark ? AzizColors.textPrimary : AzizColors.background,
            fontSize: 16,
            height: 1.6),
        bodyMedium: TextStyle(
            color: isDark ? AzizColors.textSecondary : AzizColors.background,
            fontSize: 14,
            height: 1.6),
        bodySmall: TextStyle(
            color: isDark ? AzizColors.textMuted : AzizColors.background,
            fontSize: 12,
            height: 1.5),
        labelLarge: const TextStyle(
            color: AzizColors.textPrimary,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 1),
        labelMedium: TextStyle(
            color: isDark ? AzizColors.textSecondary : AzizColors.background,
            fontSize: 12,
            letterSpacing: 0.5),
        labelSmall: TextStyle(
            color: isDark ? AzizColors.textMuted : AzizColors.background,
            fontSize: 10,
            letterSpacing: 0.5),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Divider — Séparateurs Olive
      // ════════════════════════════════════════════════════════════════════════════
      dividerTheme: DividerThemeData(
        color: isDark ? AzizColors.divider : AzizColors.indigoLight,
        thickness: 0.5,
        space: 1,
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // BottomNavigationBar — Navigation Olive & Menthe
      // ════════════════════════════════════════════════════════════════════════════
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? AzizColors.backgroundMedium : AzizColors.mistIndigo,
        selectedItemColor: AzizColors.saffron,
        unselectedItemColor: AzizColors.textMuted,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // SnackBar — Notifications Olive
      // ════════════════════════════════════════════════════════════════════════════
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AzizColors.surface : AzizColors.indigoDeep,
        contentTextStyle: const TextStyle(color: AzizColors.textPrimary),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Tooltip — Infobulles Olive
      // ════════════════════════════════════════════════════════════════════════════
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AzizColors.surface : AzizColors.indigoDeep,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark ? AzizColors.border : AzizColors.indigoLight),
        ),
        textStyle: const TextStyle(color: AzizColors.textPrimary, fontSize: 12),
        constraints: const BoxConstraints(minHeight: 32),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Chip — Étiquettes Olive
      // ════════════════════════════════════════════════════════════════════════════
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AzizColors.surface : AzizColors.mistIndigo,
        labelStyle: TextStyle(
            color: isDark ? AzizColors.textSecondary : AzizColors.background,
            fontSize: 12),
        side: BorderSide(
            color: isDark ? AzizColors.border : AzizColors.indigoLight),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // IconButton — Boutons icône Citron
      // ════════════════════════════════════════════════════════════════════════════
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(AzizColors.textPrimary),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AzizColors.saffron.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Floating Action Button — FAB Vert Menthe
      // ════════════════════════════════════════════════════════════════════════════
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AzizColors.saffron,
        foregroundColor: AzizColors.textOnAccent,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Navigation Rail — Rail latéral Olive
      // ════════════════════════════════════════════════════════════════════════════
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isDark ? AzizColors.backgroundMedium : AzizColors.mistIndigo,
        indicatorColor: AzizColors.saffron.withValues(alpha: 0.15),
      ),

      // ════════════════════════════════════════════════════════════════════════════
      // Scrollbar — Barre de défilement Menthe visible
      // ════════════════════════════════════════════════════════════════════════════
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          isDark
              ? AzizColors.saffron.withValues(alpha: 0.6)
              : AzizColors.saffron.withValues(alpha: 0.8),
        ),
        trackColor: WidgetStateProperty.all(
          isDark
              ? AzizColors.saffron.withValues(alpha: 0.1)
              : AzizColors.saffron.withValues(alpha: 0.15),
        ),
        trackBorderColor: WidgetStateProperty.all(
          isDark
              ? AzizColors.saffron.withValues(alpha: 0.05)
              : AzizColors.saffron.withValues(alpha: 0.1),
        ),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(3),
        crossAxisMargin: 4,
        mainAxisMargin: 4,
      ),
    );
  }
}
