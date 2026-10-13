import 'dart:ui';

import 'package:flutter/material.dart';

import '../../theme/aziz_colors.dart';
import '../../widgets/optimized_image.dart';
import '../admin/gallery_form_page.dart';
import '../admin/layout/admin_app_bar.dart';
import '../gallery/models/artwork.dart';
import '../gallery/services/gallery_service.dart';

class AdminGalleryPage extends StatefulWidget {
  final bool embedded;
  const AdminGalleryPage({super.key, this.embedded = false});

  @override
  State<AdminGalleryPage> createState() => _AdminGalleryPageState();
}

class _AdminGalleryPageState extends State<AdminGalleryPage> {
  final _galleryService = GalleryService();

  /// Flux temps réel (brouillons inclus pour l'administrateur connecté) :
  /// une œuvre ajoutée, modifiée ou supprimée depuis n'importe quel écran
  /// apparaît aussitôt, sans actualisation manuelle.
  late Stream<List<Artwork>> _stream = _galleryService.watchArtworks();

  void _reconnect() {
    if (!mounted) return;
    setState(() => _stream = _galleryService.watchArtworks());
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  String _titleOf(Artwork artwork) {
    if (artwork.titleFr.isNotEmpty) return artwork.titleFr;
    if (artwork.titleEn.isNotEmpty) return artwork.titleEn;
    return '(sans titre)';
  }

  Future<void> _deleteArtwork(Artwork artwork) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AzizColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Supprimer l\'œuvre ?',
          style: TextStyle(color: AzizColors.textPrimary),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${_titleOf(artwork)}" ? '
          'Son image sera aussi supprimée.',
          style: const TextStyle(color: AzizColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AzizColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    try {
      await _galleryService.deleteArtwork(artwork.id);
      _showMessage('Œuvre supprimée avec succès');
    } catch (e) {
      _showMessage('Erreur de suppression : $e', isError: true);
    }
  }

  Future<void> _toggleDraftStatus(Artwork artwork) async {
    try {
      final updated = artwork.copyWith(isPublished: !artwork.isPublished);
      await _galleryService.updateArtwork(artwork.id, updated);
      _showMessage(artwork.isPublished
          ? 'Œuvre retirée du site public'
          : 'Œuvre publiée sur le site public');
    } catch (e) {
      _showMessage('Erreur lors de la mise à jour : $e', isError: true);
    }
  }

  void _navigateToForm([Artwork? artwork]) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => GalleryFormPage(existing: artwork)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final isDesktop = width > 900;
    final isMobile = width <= 600;

    final body = StreamBuilder<List<Artwork>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return _buildErrorState();
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AzizColors.gold),
          );
        }

        final artworks = snapshot.data!;
        if (artworks.isEmpty) return _buildEmptyState();

        return RefreshIndicator(
          color: AzizColors.gold,
          backgroundColor: AzizColors.surface,
          onRefresh: () async {
            _reconnect();
            await Future<void>.delayed(const Duration(milliseconds: 400));
          },
          child: _buildResponsiveGrid(artworks, isMobile, isDesktop),
        );
      },
    );

    if (widget.embedded) {
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Galerie',
                    style: TextStyle(
                      color: AzizColors.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AzizColors.gold,
                    foregroundColor: AzizColors.backgroundDark,
                  ),
                  onPressed: () => _navigateToForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Nouvelle',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: body),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AzizColors.backgroundDark,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kAdminAppBarHeight),
        child: AdminAppBar(
          title: 'Galerie',
          onBack: () => Navigator.of(context).maybePop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AzizColors.textPrimary),
              iconSize: 24,
              tooltip: 'Actualiser',
              onPressed: _reconnect,
            ),
            if (isDesktop)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.add,
                      color: AzizColors.backgroundDark),
                  label: const Text(
                    'Nouvelle Œuvre',
                    style: TextStyle(
                      color: AzizColors.backgroundDark,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AzizColors.gold,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                  ),
                  onPressed: () => _navigateToForm(),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: isDesktop
          ? null
          : FloatingActionButton.extended(
              heroTag: 'fab_admin_gallery',
              backgroundColor: AzizColors.gold,
              foregroundColor: AzizColors.backgroundDark,
              onPressed: () => _navigateToForm(),
              icon: const Icon(Icons.add),
              label: const Text(
                'Nouvelle',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
      body: body,
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: Colors.redAccent),
          const SizedBox(height: 14),
          const Text(
            'Impossible de charger la galerie.',
            style: TextStyle(color: AzizColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: _reconnect,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Réessayer'),
            style: OutlinedButton.styleFrom(foregroundColor: AzizColors.gold),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections_outlined,
            size: 80,
            color: AzizColors.textMuted.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune œuvre dans la galerie',
            style: TextStyle(color: AzizColors.textSecondary, fontSize: 18),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToForm(),
            style: ElevatedButton.styleFrom(
              backgroundColor: AzizColors.gold,
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.add, color: AzizColors.backgroundDark),
            label: const Text(
              'Créer une œuvre',
              style: TextStyle(
                color: AzizColors.backgroundDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveGrid(
    List<Artwork> artworks,
    bool isMobile,
    bool isDesktop,
  ) {
    final double maxCrossAxisExtent;
    final double childAspectRatio;
    final double crossSpacing;
    final double mainSpacing;
    final double padding;

    if (isMobile) {
      maxCrossAxisExtent = 170;
      childAspectRatio = 0.68;
      crossSpacing = 10;
      mainSpacing = 10;
      padding = 12;
    } else if (isDesktop) {
      maxCrossAxisExtent = 220;
      childAspectRatio = 0.75;
      crossSpacing = 16;
      mainSpacing = 16;
      padding = 20;
    } else {
      maxCrossAxisExtent = 190;
      childAspectRatio = 0.72;
      crossSpacing = 12;
      mainSpacing = 12;
      padding = 16;
    }

    return GridView.builder(
      padding: EdgeInsets.all(padding),
      physics: const AlwaysScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: maxCrossAxisExtent,
        childAspectRatio: childAspectRatio,
        crossAxisSpacing: crossSpacing,
        mainAxisSpacing: mainSpacing,
      ),
      itemCount: artworks.length,
      itemBuilder: (context, index) {
        final item = artworks[index];
        return _AdminArtworkCard(
          artwork: item,
          title: _titleOf(item),
          onEdit: () => _navigateToForm(item),
          onDelete: () => _deleteArtwork(item),
          onToggleDraft: () => _toggleDraftStatus(item),
        );
      },
    );
  }
}

class _AdminArtworkCard extends StatelessWidget {
  final Artwork artwork;
  final String title;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggleDraft;

  const _AdminArtworkCard({
    required this.artwork,
    required this.title,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleDraft,
  });

  Widget _fallback({bool broken = false}) => Container(
        color: AzizColors.surface,
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              broken
                  ? Icons.broken_image_outlined
                  : Icons.image_not_supported_outlined,
              color: broken ? Colors.redAccent : AzizColors.textMuted,
              size: 30,
            ),
            if (broken) ...[
              const SizedBox(height: 4),
              const Text(
                'Image introuvable',
                style: TextStyle(color: AzizColors.textMuted, fontSize: 10),
              ),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final src = artwork.displayImage.trim();

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: AzizColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AzizColors.gold.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (src.isEmpty)
                    _fallback()
                  else if (src.startsWith('assets/'))
                    Image.asset(
                      src,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _fallback(broken: true),
                    )
                  else
                    OptimizedImage(
                      url: src,
                      folder: 'gallery',
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      errorWidget: _fallback(broken: true),
                    ),
                  Positioned.fill(
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.transparent,
                              Colors.black.withValues(alpha: 0.4),
                            ],
                            stops: const [0.6, 1.0],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _Badge(
                      label: artwork.isPublished ? 'Publié' : 'Brouillon',
                      color: artwork.isPublished
                          ? Colors.greenAccent
                          : Colors.orangeAccent,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 6, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AzizColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      _IconAction(
                        icon: artwork.isPublished
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        tooltip: artwork.isPublished
                            ? 'Passer en brouillon'
                            : 'Publier',
                        onTap: onToggleDraft,
                      ),
                      _IconAction(
                        icon: Icons.edit_outlined,
                        tooltip: 'Modifier',
                        onTap: onEdit,
                      ),
                      _IconAction(
                        icon: Icons.delete_outline,
                        tooltip: 'Supprimer',
                        color: Colors.redAccent,
                        onTap: onDelete,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          color: Colors.black.withValues(alpha: 0.45),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 5,
                height: 5,
                decoration:
                    BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? color;

  const _IconAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18, color: color ?? AzizColors.textSecondary),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}