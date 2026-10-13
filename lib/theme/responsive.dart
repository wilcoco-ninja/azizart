import 'package:flutter/widgets.dart';
import 'breakpoints.dart';

class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) => context.breakpoint.isMobile;
  static bool isTablet(BuildContext context) => context.breakpoint.isTablet;
  static bool isDesktop(BuildContext context) => context.breakpoint.isTabletOrAbove;
  static double hPad(BuildContext context) => azizPageHPad(context);

  static EdgeInsets pagePadding(BuildContext context) {
    return EdgeInsets.symmetric(
      horizontal: hPad(context),
      vertical: azizSectionVPad(context),
    );
  }

  static double maxContentWidth(BuildContext context) => 1200.0;

  // 🔴 NOUVEAU : Calcul dynamique de la taille du cache image
  /// Calcule la taille optimale en pixels physiques pour le cache mémoire.
  /// [widgetWidth] : La largeur allouée à l'image (via LayoutBuilder par exemple).
  /// Si non fourni, utilise la largeur totale de l'écran.
  static int getMemCacheWidth(BuildContext context, {double? widgetWidth}) {
    final pixelRatio = MediaQuery.of(context).devicePixelRatio;
    final logicalWidth = widgetWidth ?? MediaQuery.of(context).size.width;
    
    // On multiplie par la densité de pixels de l'écran.
    // On utilise clamp() pour éviter un cache inutilement lourd sur les écrans 4K,
    // tout en gardant un minimum vital pour la netteté.
    return (logicalWidth * pixelRatio).toInt().clamp(300, 1600);
  }

  // 🔴 NOUVEAU : Facteur d'échelle pour les icônes de navigation
  /// Retourne la taille idéale des icônes selon le type d'écran.
  static double navIconSize(BuildContext context) {
    if (isMobile(context)) return 24.0;
    if (isTablet(context)) return 28.0;
    return 32.0; // Desktop
  }
}