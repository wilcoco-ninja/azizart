import 'package:flutter/material.dart';

/// Entrée de navigation admin. Une seule liste pour la barre basse ET la
/// barre latérale : plus de libellés ou d'icônes qui divergent.
class AdminNavItem {
  final IconData icon;
  final IconData selectedIcon;
  final String label;

  const AdminNavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
}

const List<AdminNavItem> kAdminNavItems = [
  AdminNavItem(
    icon: Icons.home_outlined,
    selectedIcon: Icons.home_rounded,
    label: 'Accueil',
  ),
  AdminNavItem(
    icon: Icons.grid_view_outlined,
    selectedIcon: Icons.grid_view_rounded,
    label: 'Galerie',
  ),
  AdminNavItem(
    icon: Icons.palette_outlined,
    selectedIcon: Icons.palette_rounded,
    label: 'Atelier',
  ),
  AdminNavItem(
    icon: Icons.play_circle_outline_rounded,
    selectedIcon: Icons.play_circle_rounded,
    label: 'Médias',
  ),
  AdminNavItem(
    icon: Icons.person_outline_rounded,
    selectedIcon: Icons.person_rounded,
    label: 'Profil',
  ),
];