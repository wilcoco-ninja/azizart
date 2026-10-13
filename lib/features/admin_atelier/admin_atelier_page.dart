import 'package:flutter/material.dart';

import '../../theme/admin_colors.dart';
import '../../widgets/optimized_image.dart';
import '../admin/atelier_form_page.dart';
import '../admin/layout/admin_app_bar.dart';
import '../atelier/models/atelier_model.dart';
import '../atelier/services/atelier_service.dart';

/// Gestion des photos d'atelier : liste en temps réel (brouillons inclus),
/// publication / retrait, ordre d'affichage, modification et suppression
/// (le fichier Cloudflare R2 est supprimé en même temps que la ligne).
class AdminAtelierPage extends StatefulWidget {
  /// `true` dans le hub (pas de barre propre) ; `false` en écran autonome.
  final bool embedded;

  const AdminAtelierPage({super.key, this.embedded = true});

  @override
  State<AdminAtelierPage> createState() => _AdminAtelierPageState();
}

class _AdminAtelierPageState extends State<AdminAtelierPage> {
  final _service = AtelierService();
  late Stream<List<AtelierPhoto>> _stream =
      _service.watchPhotos(adminOnly: true);

  bool _busy = false;

  void _reconnect() {
    if (!mounted) return;
    setState(() => _stream = _service.watchPhotos(adminOnly: true));
  }

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AdminColors.danger : AdminColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _openForm([AtelierPhoto? photo]) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => AtelierFormPage(existing: photo)),
    );
  }

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await action();
    } catch (e) {
      _snack('Erreur : $e', isError: true);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _togglePublish(AtelierPhoto photo) {
    return _run(() async {
      await _service.updatePhoto(
        photo.id,
        photo.copyWith(isPublished: !photo.isPublished),
      );
      _snack(photo.isPublished
          ? 'Photo retirée du site public'
          : 'Photo publiée sur le site public');
    });
  }

  /// Déplace une photo d'un cran. L'ordre est renormalisé (1, 2, 3…) pour
  /// éviter les égalités de `sort_order`.
  Future<void> _move(List<AtelierPhoto> photos, int index, int delta) {
    final target = index + delta;
    if (target < 0 || target >= photos.length) return Future.value();

    return _run(() async {
      final list = List<AtelierPhoto>.of(photos);
      final item = list.removeAt(index);
      list.insert(target, item);
      for (var i = 0; i < list.length; i++) {
        if (list[i].order != i + 1) {
          await _service.updatePhoto(list[i].id, list[i].copyWith(order: i + 1));
        }
      }
    });
  }

  Future<void> _delete(AtelierPhoto photo) async {
    final label = photo.caption.isNotEmpty ? '« ${photo.caption} »' : 'Cette photo';
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AdminColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer cette photo ?',
          style: TextStyle(
            color: AdminColors.text,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          '$label sera définitivement supprimée, ainsi que son fichier.',
          style: const TextStyle(color: AdminColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: AdminColors.textSecondary),
            ),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AdminColors.danger),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await _run(() async {
      await _service.deletePhoto(photo.id);
      _snack('Photo supprimée');
    });
  }

  @override
  Widget build(BuildContext context) {
    final body = StreamBuilder<List<AtelierPhoto>>(
      stream: _stream,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return _ErrorState(
            message: 'Impossible de charger les photos d\'atelier.',
            onRetry: _reconnect,
          );
        }
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AdminColors.accent),
          );
        }

        final photos = snapshot.data!;
        if (photos.isEmpty) {
          return _EmptyState(onAdd: () => _openForm());
        }

        final width = MediaQuery.sizeOf(context).width;
        final isMobile = width <= 600;

        return Stack(
          children: [
            RefreshIndicator(
              color: AdminColors.accent,
              backgroundColor: AdminColors.surface,
              onRefresh: () async {
                _reconnect();
                await Future<void>.delayed(const Duration(milliseconds: 400));
              },
              child: GridView.builder(
                padding: EdgeInsets.all(isMobile ? 12 : 20),
                physics: const AlwaysScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: isMobile ? 190 : 230,
                  childAspectRatio: isMobile ? 0.66 : 0.72,
                  crossAxisSpacing: isMobile ? 10 : 16,
                  mainAxisSpacing: isMobile ? 10 : 16,
                ),
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final photo = photos[index];
                  return _PhotoCard(
                    photo: photo,
                    position: index + 1,
                    canMoveBack: index > 0,
                    canMoveForward: index < photos.length - 1,
                    onMoveBack: () => _move(photos, index, -1),
                    onMoveForward: () => _move(photos, index, 1),
                    onToggle: () => _togglePublish(photo),
                    onEdit: () => _openForm(photo),
                    onDelete: () => _delete(photo),
                  );
                },
              ),
            ),
            if (_busy)
              const Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: LinearProgressIndicator(
                  minHeight: 3,
                  color: AdminColors.accent,
                ),
              ),
          ],
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
                    'Atelier',
                    style: TextStyle(
                      color: AdminColors.text,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AdminColors.accent,
                    foregroundColor: AdminColors.textOnAccent,
                  ),
                  onPressed: () => _openForm(),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text(
                    'Ajouter',
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
      backgroundColor: AdminColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kAdminAppBarHeight),
        child: AdminAppBar(
          title: 'Atelier',
          onBack: () => Navigator.of(context).maybePop(),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh, color: AdminColors.text),
              tooltip: 'Actualiser',
              onPressed: _reconnect,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_atelier',
        backgroundColor: AdminColors.accent,
        foregroundColor: AdminColors.textOnAccent,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text(
          'Ajouter',
          style: TextStyle(fontWeight: FontWeight.w700),
        ),
      ),
      body: body,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARTE PHOTO
// ─────────────────────────────────────────────────────────────────────────────

class _PhotoCard extends StatelessWidget {
  final AtelierPhoto photo;
  final int position;
  final bool canMoveBack;
  final bool canMoveForward;
  final VoidCallback onMoveBack;
  final VoidCallback onMoveForward;
  final VoidCallback onToggle;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PhotoCard({
    required this.photo,
    required this.position,
    required this.canMoveBack,
    required this.canMoveForward,
    required this.onMoveBack,
    required this.onMoveForward,
    required this.onToggle,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final src = photo.displayImage.trim();
    final title = photo.caption.isNotEmpty ? photo.caption : '(sans titre)';

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (src.isEmpty)
                    const _ImageFallback()
                  else if (src.startsWith('assets/'))
                    Image.asset(
                      src,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => const _ImageFallback(),
                    )
                  else
                    OptimizedImage(
                      url: src,
                      folder: 'atelier',
                      fit: BoxFit.cover,
                      memCacheWidth: 600,
                      errorWidget: const _ImageFallback(broken: true),
                    ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: _StatusBadge(published: photo.isPublished),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '#$position',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 6, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AdminColors.text,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconAction(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Avancer dans la liste',
                            onTap: canMoveBack ? onMoveBack : null,
                          ),
                          _IconAction(
                            icon: Icons.arrow_forward_rounded,
                            tooltip: 'Reculer dans la liste',
                            onTap: canMoveForward ? onMoveForward : null,
                          ),
                        ],
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _IconAction(
                            icon: photo.isPublished
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            tooltip: photo.isPublished
                                ? 'Retirer du site'
                                : 'Publier',
                            onTap: onToggle,
                          ),
                          _IconAction(
                            icon: Icons.edit_outlined,
                            tooltip: 'Modifier',
                            onTap: onEdit,
                          ),
                          _IconAction(
                            icon: Icons.delete_outline,
                            tooltip: 'Supprimer',
                            color: AdminColors.danger,
                            onTap: onDelete,
                          ),
                        ],
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

class _ImageFallback extends StatelessWidget {
  final bool broken;
  const _ImageFallback({this.broken = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AdminColors.surfaceHi,
      alignment: Alignment.center,
      child: Icon(
        broken
            ? Icons.broken_image_outlined
            : Icons.image_not_supported_outlined,
        color: broken ? AdminColors.danger : AdminColors.textMuted,
        size: 30,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool published;
  const _StatusBadge({required this.published});

  @override
  Widget build(BuildContext context) {
    final color = published ? Colors.greenAccent : Colors.orangeAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            published ? 'Publié' : 'Brouillon',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;
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
      icon: Icon(
        icon,
        size: 18,
        color: onTap == null
            ? AdminColors.textMuted.withValues(alpha: 0.35)
            : (color ?? AdminColors.textSecondary),
      ),
      tooltip: tooltip,
      onPressed: onTap,
      visualDensity: VisualDensity.compact,
      padding: const EdgeInsets.all(4),
      constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;
  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_camera_back_outlined,
            size: 72,
            color: AdminColors.textMuted.withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          const Text(
            'Aucune photo d\'atelier',
            style: TextStyle(color: AdminColors.textSecondary, fontSize: 16),
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AdminColors.accent,
              foregroundColor: AdminColors.textOnAccent,
            ),
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text(
              'Ajouter une photo',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 40, color: AdminColors.danger),
          const SizedBox(height: 14),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: AdminColors.textSecondary),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Réessayer'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AdminColors.accent,
              side: BorderSide(
                color: AdminColors.accent.withValues(alpha: 0.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}