import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../theme/admin_colors.dart';
import 'admin_app_bar.dart';
import 'admin_bottom_nav.dart';
import 'admin_sidebar.dart';

// Paliers alignés sur breakpoints.dart (mobile < 640, desktop ≥ 1024).
const double kAdminMobileBreakpoint = 640.0;
const double kAdminDesktopBreakpoint = 1024.0;

class AdminScaffold extends StatefulWidget {
  final Widget? body;

  /// Onglet actif. `null` = aucun onglet sélectionné (sous-page).
  final int? currentIndex;
  final ValueChanged<int>? onTap;
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onAdd;
  final Widget? header;
  final List<Widget>? appBarActions;

  /// Style « profil » (titre plus grand, sans logo). Nom historique conservé.
  final bool isInstagramProfile;
  final VoidCallback? onAccount;
  final Future<void> Function()? onLogout;
  final Map<int, int>? badgeCounts;
  final bool hideAppBar;

  const AdminScaffold({
    super.key,
    this.body,
    this.currentIndex,
    this.onTap,
    this.title = '',
    this.onBack,
    this.onAdd,
    this.header,
    this.appBarActions,
    this.isInstagramProfile = false,
    this.onAccount,
    this.onLogout,
    this.badgeCounts,
    this.hideAppBar = false,
  });

  @override
  State<AdminScaffold> createState() => _AdminScaffoldState();
}

class _AdminScaffoldState extends State<AdminScaffold> {
  /// Clé globale : quand la largeur franchit le seuil mobile/desktop, le
  /// contenu est DÉPLACÉ dans le nouvel arbre au lieu d'être détruit
  /// (scroll et formulaires saisis conservés).
  final GlobalKey _contentKey = GlobalKey();

  /// -1 = aucun onglet sélectionné.
  int get _effectiveIndex => widget.currentIndex ?? -1;

  void _handleTap(int index) => widget.onTap?.call(index);

  Future<void> _logout() async {
    final custom = widget.onLogout;
    if (custom != null) {
      await custom();
      return;
    }
    // On capture avant le await : aucun BuildContext utilisé après.
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    try {
      await Supabase.instance.client.auth.signOut();
    } catch (_) {
      messenger.showSnackBar(const SnackBar(
        content: Text('Déconnexion impossible. Vérifiez votre connexion.'),
      ));
      return;
    }
    navigator.pushNamedAndRemoveUntil('/', (route) => false);
  }

  Future<void> _confirmAndLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AdminColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                style: TextStyle(color: AdminColors.textMuted)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
                backgroundColor: AdminColors.danger),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Déconnexion'),
          ),
        ],
      ),
    );
    if (confirm == true) await _logout();
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AdminColors.surfaceElevated,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              height: 3,
              width: 32,
              decoration: BoxDecoration(
                color: AdminColors.border,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            if (widget.onAccount != null)
              ListTile(
                dense: true,
                leading: const Icon(Icons.person_outline,
                    color: AdminColors.text, size: 20),
                title: const Text(
                  'Mon compte',
                  style: TextStyle(
                    color: AdminColors.text,
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                  ),
                ),
                onTap: () {
                  Navigator.pop(sheetContext);
                  widget.onAccount!();
                },
              ),
            ListTile(
              dense: true,
              leading: const Icon(Icons.logout,
                  color: AdminColors.danger, size: 20),
              title: const Text(
                'Se déconnecter',
                style: TextStyle(
                  color: AdminColors.danger,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmAndLogout();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < kAdminMobileBreakpoint;
          final isLargeDesktop =
              constraints.maxWidth >= kAdminDesktopBreakpoint;

          final content = KeyedSubtree(
            key: _contentKey,
            child: Column(
              children: [
                if (widget.header != null) widget.header!,
                Expanded(child: widget.body ?? const SizedBox.shrink()),
              ],
            ),
          );

          return isMobile
              ? _buildMobileLayout(content)
              : _buildDesktopLayout(content,
                  autoExpandSidebar: isLargeDesktop);
        },
      ),
    );
  }

  Widget _buildMobileLayout(Widget content) {
    final actions = <Widget>[
      ...?widget.appBarActions,
      if (widget.onAdd != null)
        IconButton(
          tooltip: 'Ajouter',
          icon: const Icon(Icons.add_box_outlined,
              color: AdminColors.text, size: 22),
          onPressed: widget.onAdd,
        ),
      IconButton(
        tooltip: 'Menu',
        icon: const Icon(Icons.menu_rounded,
            color: AdminColors.text, size: 22),
        onPressed: _showMenu,
      ),
    ];

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: widget.hideAppBar
          ? null
          : AdminAppBar(
              title: widget.title,
              isInstagramStyle: widget.isInstagramProfile,
              actions: actions,
              onBack: widget.onBack,
              showLogo: !widget.isInstagramProfile,
            ),
      body: content,
      bottomNavigationBar: AdminBottomNav(
        currentIndex: _effectiveIndex,
        onTap: _handleTap,
        badgeCounts: widget.badgeCounts,
      ),
    );
  }

  Widget _buildDesktopLayout(Widget content,
      {required bool autoExpandSidebar}) {
    return Scaffold(
      backgroundColor: AdminColors.bg,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AdminSidebar(
            currentIndex: _effectiveIndex,
            onTap: _handleTap,
            onAccount: widget.onAccount,
            onLogout: _logout, // la barre latérale demande déjà confirmation
            badgeCounts: widget.badgeCounts,
            initialExpanded: autoExpandSidebar,
          ),
          Expanded(
            child: SafeArea(
              child: Column(
                children: [
                  if (!widget.hideAppBar)
                    AdminAppBar(
                      title: widget.title,
                      isInstagramStyle: widget.isInstagramProfile,
                      actions: widget.appBarActions,
                      onBack: widget.onBack,
                      showLogo: false,
                    ),
                  Expanded(child: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}