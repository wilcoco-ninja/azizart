import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../theme/aziz_colors.dart';

import 'admin_forms.dart';
import 'admin_account_page.dart';

/// Page Hub d'administration — corrigée
/// Corrections :
///  • Matrix4.scaleByDouble inexistant → supprimé (AnimatedContainer suffit)
///  • AzizColors.accent/@deprecated → .saffron
///  • AzizColors.indigo/@deprecated → .indigoDeep
///  • AzizColors.terracotta/@deprecated → .terraCotta
///  • 4e carte ajoutée : "Publier sur l'Accueil" → HomeEventFormPage
///  • Bouton "Mon compte" ajouté (AppBar) → changer pseudo/mot de passe
class AdminHubPage extends StatelessWidget {
  const AdminHubPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: AzizColors.backgroundDark,
        appBar: AppBar(
          backgroundColor: AzizColors.backgroundMedium,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            color: AzizColors.textPrimary,
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: const Text(
            'Administration',
            style: TextStyle(
              fontFamily: 'Playfair Display',
              color: AzizColors.saffron,
              fontSize: 18,
              letterSpacing: 3,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.person_outline_rounded),
              color: AzizColors.textSecondary,
              tooltip: 'Mon compte (pseudo / mot de passe)',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminAccountPage()),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              color: AzizColors.textSecondary,
              tooltip: 'Se déconnecter',
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => AlertDialog(
                    backgroundColor: AzizColors.surface,
                    title: const Text(
                      'Se déconnecter ?',
                      style: TextStyle(color: AzizColors.textPrimary),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Annuler'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Déconnexion',
                          style: TextStyle(color: AzizColors.error),
                        ),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  await Supabase.instance.client.auth.signOut();
                }
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Que souhaitez-vous faire aujourd\'hui ?',
                  style: TextStyle(
                    fontFamily: 'Playfair Display',
                    color: AzizColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Choisissez une action pour ajouter ou publier du contenu.',
                  style: TextStyle(
                    color: AzizColors.textSecondary,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final cols = constraints.maxWidth < 600
                          ? 1
                          : constraints.maxWidth < 900
                              ? 2
                              : 2;
                      return GridView.count(
                        crossAxisCount: cols,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: cols == 1 ? 2.2 : 1.4,
                        children: [
                          _ActionCard(
                            icon: Icons.palette_outlined,
                            title: 'Ajouter à la Galerie',
                            subtitle:
                                'Tableaux, œuvres d\'art, vêtements, tissus…',
                            color: AzizColors.saffron,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const GalleryFormPage()),
                            ),
                          ),
                          _ActionCard(
                            icon: Icons.home_outlined,
                            title: 'Publier sur l\'Accueil',
                            subtitle:
                                'Actualités, événements et expositions à venir',
                            color: AzizColors.saffronLight,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const HomeEventFormPage()),
                            ),
                          ),
                          _ActionCard(
                            icon: Icons.workspace_premium_outlined,
                            title: 'Ajouter à l\'Atelier',
                            subtitle:
                                'Photos de création, coulisses et processus',
                            color: AzizColors.terraCotta,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const AtelierFormPage()),
                            ),
                          ),
                          _ActionCard(
                            icon: Icons.video_library_outlined,
                            title: 'Ajouter aux Médias',
                            subtitle:
                                'Vidéos YouTube, reportages et actualités presse',
                            color: AzizColors.greenBatik,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const MediaFormPage()),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ──────────────────────────────────────────────────────────────────────────────
// Carte d'action — Matrix4.scaleByDouble retiré, AnimatedContainer suffit
// ──────────────────────────────────────────────────────────────────────────────
class _ActionCard extends StatefulWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  State<_ActionCard> createState() => _ActionCardState();
}

class _ActionCardState extends State<_ActionCard> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: _hovered
                ? widget.color.withValues(alpha: 0.08)
                : AzizColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _hovered ? widget.color : AzizColors.cardBorder,
              width: _hovered ? 2 : 0.5,
            ),
            boxShadow: _hovered
                ? [
                    BoxShadow(
                      color: widget.color.withValues(alpha: 0.18),
                      blurRadius: 24,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : const [],
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(widget.icon, size: 28, color: widget.color),
              ),
              const SizedBox(height: 16),
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Playfair Display',
                  color: AzizColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                widget.subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AzizColors.textSecondary,
                  fontSize: 12,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
