import 'package:flutter/material.dart';
import 'aziz_colors.dart';

/// 🎨 THÈME AZIZART COLORS — galerie d'art.
/// Mur clair, encre indigo, accents ambre, angles quasi droits (2 px),
/// boutons de 48 px sans ombre.
class AppTheme {
  AppTheme._();

  static const String _fontFamily = 'Playfair Display';
  static const String _fontFamilyBody = 'Raleway';

  /// Rayon commun : angles presque droits, comme un cadre ou un cartel.
  static const double _radius = 2;

  static ThemeData get theme => _buildTheme(Brightness.light);
  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final shape =
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(_radius));

    final ink = isDark ? AzizColors.textPrimary : AzizColors.lightTextPrimary;
    final inkSoft =
        isDark ? AzizColors.textSecondary : AzizColors.lightTextSecondary;
    final inkMuted = isDark ? AzizColors.textMuted : AzizColors.lightTextMuted;
    final line = isDark ? AzizColors.border : AzizColors.lightBorder;
    final action = isDark ? AzizColors.saffron : AzizColors.trueIndigo;

    final colorScheme = isDark
        ? const ColorScheme.dark(
            primary: AzizColors.saffron,
            secondary: AzizColors.petrolBlue,
            surface: AzizColors.surface,
            error: AzizColors.error,
            onPrimary: AzizColors.textOnAccent,
            onSecondary: AzizColors.textOnAccent,
            onSurface: AzizColors.textPrimary,
          )
        : const ColorScheme.light(
            primary: AzizColors.saffron,
            secondary: AzizColors.trueIndigo,
            surface: AzizColors.lightSurface,
            error: AzizColors.error,
            onPrimary: AzizColors.textOnAccent,
            onSecondary: AzizColors.lightBackground,
            onSurface: AzizColors.lightTextPrimary,
          );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      fontFamily: _fontFamilyBody,
      scaffoldBackgroundColor:
          isDark ? AzizColors.background : AzizColors.lightBackground,

      // ── AppBar ─────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AzizColors.backgroundMedium : AzizColors.lightBackground,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: ink,
          fontSize: 20,
          fontWeight: FontWeight.w400,
          letterSpacing: 1,
        ),
        iconTheme: IconThemeData(color: ink),
      ),

      // ── Card : cadre fin, sans ombre ───────────────────────────────────
      cardTheme: CardThemeData(
        color: isDark ? AzizColors.cardBackground : AzizColors.mat,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: line, width: 0.8),
        ),
        margin: const EdgeInsets.all(8),
      ),

      // ── Dialog ─────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AzizColors.backgroundMedium : AzizColors.mat,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        titleTextStyle: TextStyle(
          fontFamily: _fontFamily,
          color: ink,
          fontSize: 22,
          fontWeight: FontWeight.w400,
        ),
        contentTextStyle: TextStyle(color: inkSoft, fontSize: 14, height: 1.6),
      ),

      // ── TabBar ─────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: isDark ? AzizColors.saffron : AzizColors.trueIndigoDark,
        unselectedLabelColor: inkMuted,
        indicatorColor: AzizColors.saffron,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: line,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        unselectedLabelStyle:
            const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
      ),

      // ── Boutons ────────────────────────────────────────────────────────
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return isDark ? AzizColors.textMuted : AzizColors.lightBorder;
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
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: _fontFamilyBody,
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
          shape: WidgetStateProperty.all(shape),
          elevation: WidgetStateProperty.all(0),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return inkMuted;
            return action;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return BorderSide(color: line);
            }
            return BorderSide(color: action.withValues(alpha: 0.6), width: 1);
          }),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return action.withValues(alpha: 0.1);
            }
            return null;
          }),
          minimumSize: WidgetStateProperty.all(const Size(0, 48)),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: _fontFamilyBody,
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
          shape: WidgetStateProperty.all(shape),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(action),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return action.withValues(alpha: 0.08);
            }
            return null;
          }),
          shape: WidgetStateProperty.all(shape),
          textStyle: WidgetStateProperty.all(
            const TextStyle(
              fontFamily: _fontFamilyBody,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ),
      ),

      // ── Champs de saisie : champ blanc sur le mur ───────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AzizColors.surface : AzizColors.mat,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: inkMuted, fontSize: 14),
        labelStyle: TextStyle(color: inkSoft, fontSize: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: line, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: BorderSide(color: action, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AzizColors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(_radius),
          borderSide: const BorderSide(color: AzizColors.error, width: 1.5),
        ),
      ),

      // ── Texte ──────────────────────────────────────────────────────────
      textTheme: TextTheme(
        displayLarge: TextStyle(
            fontFamily: _fontFamily,
            color: ink,
            fontSize: 56,
            fontWeight: FontWeight.w400,
            letterSpacing: -1),
        displayMedium: TextStyle(
            fontFamily: _fontFamily,
            color: ink,
            fontSize: 40,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.5),
        displaySmall: TextStyle(
            fontFamily: _fontFamily,
            color: ink,
            fontSize: 30,
            fontWeight: FontWeight.w400),
        headlineLarge: TextStyle(
            fontFamily: _fontFamily,
            color: ink,
            fontSize: 26,
            fontWeight: FontWeight.w400),
        headlineMedium: TextStyle(
            fontFamily: _fontFamily,
            color: ink,
            fontSize: 22,
            fontWeight: FontWeight.w400),
        headlineSmall: TextStyle(
            fontFamily: _fontFamily,
            color: ink,
            fontSize: 19,
            fontWeight: FontWeight.w400),
        titleLarge: TextStyle(
            color: ink, fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(
            color: ink, fontSize: 15, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(
            color: inkSoft, fontSize: 13, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(color: ink, fontSize: 16, height: 1.7),
        bodyMedium: TextStyle(color: inkSoft, fontSize: 14.5, height: 1.65),
        bodySmall: TextStyle(color: inkMuted, fontSize: 12.5, height: 1.5),
        labelLarge: TextStyle(
            color: ink,
            fontSize: 14.5,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2),
        labelMedium:
            TextStyle(color: inkSoft, fontSize: 12.5, letterSpacing: 0.2),
        labelSmall:
            TextStyle(color: inkMuted, fontSize: 11.5, letterSpacing: 0.2),
      ),

      // ── Divider ────────────────────────────────────────────────────────
      dividerTheme: DividerThemeData(color: line, thickness: 0.8, space: 1),

      // ── BottomNavigationBar ────────────────────────────────────────────
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor:
            isDark ? AzizColors.backgroundMedium : AzizColors.lightBackground,
        selectedItemColor: isDark ? AzizColors.saffron : AzizColors.trueIndigo,
        unselectedItemColor: inkMuted,
        showSelectedLabels: true,
        showUnselectedLabels: false,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      ),

      // ── SnackBar ───────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        backgroundColor:
            isDark ? AzizColors.surface : AzizColors.trueIndigoDark,
        contentTextStyle: TextStyle(
          color: isDark ? AzizColors.textPrimary : AzizColors.lightBackground,
        ),
        behavior: SnackBarBehavior.floating,
        shape: shape,
      ),

      // ── Tooltip ────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AzizColors.surface : AzizColors.trueIndigoDark,
          borderRadius: BorderRadius.circular(_radius),
        ),
        textStyle: TextStyle(
          color: isDark ? AzizColors.textPrimary : AzizColors.lightBackground,
          fontSize: 12.5,
        ),
        constraints: const BoxConstraints(minHeight: 32),
      ),

      // ── Chip ───────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AzizColors.surface : AzizColors.mat,
        labelStyle: TextStyle(color: inkSoft, fontSize: 13),
        side: BorderSide(color: line),
        shape: shape,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),

      // ── IconButton ─────────────────────────────────────────────────────
      iconButtonTheme: IconButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.all(ink),
          shape: WidgetStateProperty.all(shape),
          overlayColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AzizColors.saffron.withValues(alpha: 0.15);
            }
            return null;
          }),
        ),
      ),

      // ── Floating Action Button ─────────────────────────────────────────
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AzizColors.saffron,
        foregroundColor: AzizColors.textOnAccent,
        elevation: 2,
        shape: shape,
      ),

      // ── Navigation Rail ────────────────────────────────────────────────
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor:
            isDark ? AzizColors.backgroundMedium : AzizColors.lightBackground,
        indicatorColor: AzizColors.saffron.withValues(alpha: 0.2),
      ),

      // ── Scrollbar ──────────────────────────────────────────────────────
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(
          isDark
              ? AzizColors.saffron.withValues(alpha: 0.6)
              : AzizColors.trueIndigo.withValues(alpha: 0.45),
        ),
        trackColor: WidgetStateProperty.all(
          isDark
              ? AzizColors.saffron.withValues(alpha: 0.1)
              : AzizColors.lightBorder.withValues(alpha: 0.5),
        ),
        trackBorderColor: WidgetStateProperty.all(Colors.transparent),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(2),
        crossAxisMargin: 4,
        mainAxisMargin: 4,
      ),
    );
  }
}