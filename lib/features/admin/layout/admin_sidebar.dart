import 'package:flutter/material.dart';

import '../../../config.dart';
import '../../../theme/admin_colors.dart';
import '../../../widgets/optimized_image.dart';
import 'admin_nav_badge.dart';
import 'admin_nav_items.dart';

const double kAdminSidebarCollapsedWidth = 72.0;
const double kAdminSidebarExpandedWidth = 232.0;

/// Les libellés n'apparaissent que lorsque la largeur animée dépasse ce
/// seuil : plus de texte tronqué ni d'overflow pendant l'animation.
const double _kLabelsMinWidth = 180.0;

class AdminSidebar extends StatefulWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback? onAccount;
  final Future<void> Function()? onLogout;
  final Map<int, int>? badgeCounts;
  final bool initialExpanded;

  const AdminSidebar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.onAccount,
    this.onLogout,
    this.badgeCounts,
    this.initialExpanded = false,
  });

  static const items = kAdminNavItems;

  @override
  State<AdminSidebar> createState() => _AdminSidebarState();
}

class _AdminSidebarState extends State<AdminSidebar> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.initialExpanded;
  }

  // Ne réinitialise le choix manuel que si le seuil desktop est franchi.
  @override
  void didUpdateWidget(covariant AdminSidebar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialExpanded != widget.initialExpanded) {
      _expanded = widget.initialExpanded;
    }
  }

  Future<void> _confirmLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
        contentPadding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
        title: const Text(
          'Se déconnecter ?',
          style: TextStyle(
            color: AdminColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Annuler',
                style: TextStyle(
                    color: AdminColors.textMuted,
                    fontWeight: FontWeight.w600,
                    fontSize: 14)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.danger,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Déconnexion',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
          ),
        ],
      ),
    );
    if (confirm == true && mounted) await widget.onLogout?.call();
  }

  @override
  Widget build(BuildContext context) {
    final width =
        _expanded ? kAdminSidebarExpandedWidth : kAdminSidebarCollapsedWidth;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      width: width,
      decoration: const BoxDecoration(
        color: AdminColors.surface,
        border: Border(
          right: BorderSide(color: AdminColors.border, width: 1),
        ),
      ),
      child: ClipRect(
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final showLabels =
                  _expanded && constraints.maxWidth >= _kLabelsMinWidth;

              return Column(
                children: [
                  const SizedBox(height: 16),
                  _LogoRow(expanded: showLabels),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      children: [
                        for (var i = 0; i < kAdminNavItems.length; i++)
                          _SidebarTile(
                            icon: widget.currentIndex == i
                                ? kAdminNavItems[i].selectedIcon
                                : kAdminNavItems[i].icon,
                            label: kAdminNavItems[i].label,
                            showLabel: showLabels,
                            selected: widget.currentIndex == i,
                            badgeCount: widget.badgeCounts?[i] ?? 0,
                            onTap: () => widget.onTap(i),
                          ),
                      ],
                    ),
                  ),
                  Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        top: BorderSide(color: AdminColors.border, width: 1),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                    child: Column(
                      children: [
                        _SidebarTile(
                          icon: Icons.person_outline,
                          label: 'Mon compte',
                          showLabel: showLabels,
                          compact: true,
                          onTap: widget.onAccount,
                        ),
                        _SidebarTile(
                          icon: Icons.logout,
                          label: 'Déconnexion',
                          showLabel: showLabels,
                          compact: true,
                          danger: true,
                          onTap:
                              widget.onLogout == null ? null : _confirmLogout,
                        ),
                        _SidebarTile(
                          icon: _expanded
                              ? Icons.chevron_left_rounded
                              : Icons.chevron_right_rounded,
                          label: _expanded ? 'Réduire' : 'Développer',
                          showLabel: showLabels,
                          compact: true,
                          onTap: () => setState(() => _expanded = !_expanded),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _LogoRow extends StatelessWidget {
  final bool expanded;
  const _LogoRow({required this.expanded});

  /// `final` : `AppConfig.logoAdminUrl` n'est pas une constante.
  static final String _logoUrl = AppConfig.logoAdminUrl;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        mainAxisAlignment:
            expanded ? MainAxisAlignment.start : MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: AdminColors.bg.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: SizedBox(
              width: 32,
              height: 32,
              child: OptimizedImage(
                url: _logoUrl,
                folder: 'logo',
                fit: BoxFit.contain,
                memCacheWidth: 128,
                placeholder: const Padding(
                  padding: EdgeInsets.all(6),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AdminColors.accent,
                  ),
                ),
                errorWidget: const Center(
                  child: Text(
                    'AZ',
                    style: TextStyle(
                      color: AdminColors.accent,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
          ),
          if (expanded)
            const Expanded(
              child: Padding(
                padding: EdgeInsets.only(left: 10),
                child: Text(
                  'AZIZART',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AdminColors.text,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Élément unique de la barre latérale (navigation ET actions).
/// Basé sur InkWell : focus clavier (Tab / Entrée), survol, lecteur d'écran.
class _SidebarTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool showLabel;
  final bool selected;
  final bool danger;
  final bool compact;
  final int badgeCount;
  final VoidCallback? onTap;

  const _SidebarTile({
    required this.icon,
    required this.label,
    required this.showLabel,
    this.selected = false,
    this.danger = false,
    this.compact = false,
    this.badgeCount = 0,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;

    final iconColor = danger
        ? AdminColors.danger
        : (selected ? AdminColors.accent : AdminColors.textMuted);
    final labelColor = danger
        ? AdminColors.danger
        : (selected ? AdminColors.text : AdminColors.textMuted);

    Widget tile = Semantics(
      container: true,
      button: true,
      enabled: enabled,
      selected: selected,
      label: label,
      excludeSemantics: true,
      child: Opacity(
        opacity: enabled ? 1 : 0.4,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Material(
            color: selected ? AdminColors.accentSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(8),
              hoverColor:
                  danger ? AdminColors.dangerSoft : AdminColors.surfaceTint,
              mouseCursor: enabled
                  ? SystemMouseCursors.click
                  : SystemMouseCursors.basic,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: showLabel ? 10 : 0,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: showLabel
                      ? MainAxisAlignment.start
                      : MainAxisAlignment.center,
                  children: [
                    AdminNavBadge(
                      count: badgeCount,
                      backgroundColor: AdminColors.surface,
                      child: Icon(icon,
                          size: compact ? 18 : 20, color: iconColor),
                    ),
                    if (showLabel)
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: compact ? 13 : 13.5,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.w500,
                              letterSpacing: 0.1,
                              color: labelColor,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );

    if (!showLabel) {
      tile = Tooltip(
        message: label,
        waitDuration: const Duration(milliseconds: 300),
        child: tile,
      );
    }
    return tile;
  }
}