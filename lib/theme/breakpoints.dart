// ══════════════════════════════════════════════════════════════════════
// BREAKPOINTS UNIFIÉS — AZIZART
// ══════════════════════════════════════════════════════════════════════
// Un seul système remplace les trois qui cohabitaient :
//   • mobile   : < 640 px   (téléphone portrait / petit paysage)
//   • tablet   : 640–1024   (tablette portrait, téléphone paysage)
//   • desktop  : 1024–1440  (laptop, petite tour)
//   • wide     : ≥ 1440     (grand écran, tour)
//
// Ces 4 paliers permettent d'adapter finement les espacements, les tailles
// de police et les grilles sans créer 12 cas particuliers.
//
// Utilisation :
//   final bp = AzizBreakpoint.of(context);
//   if (bp.isMobile) { ... }
// ══════════════════════════════════════════════════════════════════════

import 'package:flutter/widgets.dart';

enum AzizBreakpoint { mobile, tablet, desktop, wide }

extension AzizBreakpointX on AzizBreakpoint {
  bool get isMobile => this == AzizBreakpoint.mobile;
  bool get isTablet => this == AzizBreakpoint.tablet;
  bool get isDesktop => this == AzizBreakpoint.desktop;
  bool get isWide => this == AzizBreakpoint.wide;

  /// `true` dès tablette — utile pour les règles « desktop à partir de »
  bool get isTabletOrAbove => index >= AzizBreakpoint.tablet.index;

  /// `true` jusqu'à tablette incluse
  bool get isTabletOrBelow => index <= AzizBreakpoint.tablet.index;
}

extension AzizBreakpointContext on BuildContext {
  AzizBreakpoint get breakpoint {
    final width = MediaQuery.sizeOf(this).width;
    if (width < 640) return AzizBreakpoint.mobile;
    if (width < 1024) return AzizBreakpoint.tablet;
    if (width < 1440) return AzizBreakpoint.desktop;
    return AzizBreakpoint.wide;
  }
}

/// Espacement horizontal entre colonnes, adaptatif
double azizColumnGap(BuildContext context) {
  switch (context.breakpoint) {
    case AzizBreakpoint.mobile:
      return 0;         // pas de colonne en mobile : layout vertical
    case AzizBreakpoint.tablet:
      return 40;        // tablette : gap moyen
    case AzizBreakpoint.desktop:
      return 64;        // laptop : gap large
    case AzizBreakpoint.wide:
      return 88;        // grand écran : gap généreux
  }
}

/// Padding horizontal de page, adaptatif
double azizPageHPad(BuildContext context) {
  switch (context.breakpoint) {
    case AzizBreakpoint.mobile:
      return 20;
    case AzizBreakpoint.tablet:
      return 40;
    case AzizBreakpoint.desktop:
      return 64;
    case AzizBreakpoint.wide:
      return 96;
  }
}

/// Padding vertical de section, adaptatif
double azizSectionVPad(BuildContext context) {
  switch (context.breakpoint) {
    case AzizBreakpoint.mobile:
      return 56;
    case AzizBreakpoint.tablet:
      return 80;
    case AzizBreakpoint.desktop:
      return 112;
    case AzizBreakpoint.wide:
      return 132;
  }
}