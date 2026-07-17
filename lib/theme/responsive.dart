import 'package:flutter/material.dart';

class Responsive {
  Responsive._();

  static const double _mobileBreakpoint  = 600;
  static const double _tabletBreakpoint  = 1024;
  static const double _desktopBreakpoint = 1440;

  static bool isMobile(BuildContext context)  =>
      MediaQuery.of(context).size.width < _mobileBreakpoint;
  static bool isTablet(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    return w >= _mobileBreakpoint && w < _tabletBreakpoint;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= _tabletBreakpoint;
  static bool isWide(BuildContext context) =>
      MediaQuery.of(context).size.width >= _desktopBreakpoint;

  /// Padding horizontal adaptatif (double)
  static double hPad(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < _mobileBreakpoint)  return 20;
    if (w < _tabletBreakpoint)  return 40;
    if (w < _desktopBreakpoint) return 64;
    return 80;
  }

  /// Padding vertical adaptatif
  static double vPad(BuildContext context) => isMobile(context) ? 32 : 56;

  /// Padding de page complet (EdgeInsets) — utilisé par AtelierPhotoGrid etc.
  static EdgeInsets pagePadding(BuildContext context) {
    final h = hPad(context);
    final v = vPad(context);
    return EdgeInsets.symmetric(horizontal: h, vertical: v);
  }

  /// Largeur de contenu maximale
  static double maxContentWidth(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < _mobileBreakpoint)  return w;
    if (w < _tabletBreakpoint)  return 720;
    return 1200;
  }

  /// Colonnes pour grilles génériques
  static int gridColumns(BuildContext context) {
    if (isMobile(context))  return 1;
    if (isTablet(context))  return 2;
    if (isDesktop(context)) return 3;
    return 4;
  }

  /// Colonnes pour galeries photo/atelier (légèrement différent)
  static int galleryColumns(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    if (w < _mobileBreakpoint)  return 1;
    if (w < 900)                return 2;
    if (w < _tabletBreakpoint)  return 3;
    return 4;
  }

  static double fontSize(BuildContext context,
      {double mobile = 14, double tablet = 15, double desktop = 16}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet;
    return desktop;
  }

  static T value<T>(BuildContext context,
      {required T mobile, required T desktop, T? tablet}) {
    if (isMobile(context)) return mobile;
    if (isTablet(context)) return tablet ?? desktop;
    return desktop;
  }
}
