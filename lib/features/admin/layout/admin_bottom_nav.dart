import 'package:flutter/material.dart';
import '../../../theme/admin_colors.dart';
import 'admin_nav_badge.dart';

/// Barre de navigation basse moderne : indicateur « pilule » animé derrière
/// l'icône sélectionnée, libellés lisibles (11 px) et zones tactiles pleines.
class AdminBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final Map<int, int>? badgeCounts;
  final bool isTop;

  const AdminBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.badgeCounts,
    this.isTop = false,
  });

  static const double _navBarHeight = 64.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AdminColors.surface,
        border: Border(
          top: isTop
              ? BorderSide.none
              : const BorderSide(color: AdminColors.border, width: 0.5),
          bottom: isTop
              ? const BorderSide(color: AdminColors.border, width: 0.5)
              : BorderSide.none,
        ),
        boxShadow: isTop
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 16,
                  offset: const Offset(0, -4),
                ),
              ],
      ),
      child: SafeArea(
        top: isTop,
        bottom: !isTop,
        child: SizedBox(
          height: _navBarHeight,
          child: Row(
            children: [
              _item(Icons.home_outlined, Icons.home_rounded, 0, 'Accueil'),
              _item(Icons.grid_view_outlined, Icons.grid_view_rounded, 1,
                  'Galerie'),
              _item(Icons.palette_outlined, Icons.palette_rounded, 2,
                  'Atelier'),
              _item(Icons.play_circle_outline_rounded,
                  Icons.play_circle_rounded, 3, 'Médias'),
              _item(Icons.person_outline_rounded, Icons.person_rounded, 4,
                  'Profil'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(IconData icon, IconData selectedIcon, int index, String label) {
    final count = badgeCounts?[index] ?? 0;
    final isSelected = currentIndex == index;
    final color = isSelected ? AdminColors.accent : AdminColors.textMuted;

    return Expanded(
      child: Semantics(
        label: label,
        button: true,
        selected: isSelected,
        excludeSemantics: true,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                width: isSelected ? 58 : 36,
                height: 30,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AdminColors.accent.withValues(alpha: 0.16)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: AdminNavBadge(
                  count: count,
                  backgroundColor: AdminColors.surface,
                  child: Icon(
                    isSelected ? selectedIcon : icon,
                    size: 23,
                    color: color,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  letterSpacing: 0.1,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}