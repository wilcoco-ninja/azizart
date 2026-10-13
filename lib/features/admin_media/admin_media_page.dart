import 'package:flutter/material.dart';

import '../media/models/media_model.dart';
import '../media/media_card.dart';
import '../media/services/media_service.dart';
import '../../theme/aziz_colors.dart';
import '../../theme/responsive.dart';
import '../admin/media_form_page.dart';
import '../admin/layout/admin_app_bar.dart';

class AdminMediaPage extends StatefulWidget {
  final bool embedded;

  const AdminMediaPage({super.key, this.embedded = false});

  @override
  State<AdminMediaPage> createState() => _AdminMediaPageState();
}

class _AdminMediaPageState extends State<AdminMediaPage> {
  final _mediaService = MediaService();
  MediaType? _typeFilter;

  late Stream<List<MediaItem>> _mediaStream = _mediaService.watchAll();

  void _reconnect() {
    if (!mounted) return;
    setState(() => _mediaStream = _mediaService.watchAll());
  }

  void _openForm(BuildContext context, {MediaItem? existing}) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => MediaFormPage(existing: existing)),
    );
  }

  void _snack(BuildContext context, String message, {bool isError = false}) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
      ),
    );
  }

  void _showItemMenu(BuildContext context, MediaItem item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AzizColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: AzizColors.textMuted.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(
                item.isPublished
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: item.isPublished ? Colors.redAccent : Colors.green,
              ),
              title: Text(
                item.isPublished ? 'Retirer de la publication' : 'Republier',
                style: TextStyle(
                    color: item.isPublished ? Colors.redAccent : Colors.green),
              ),
              onTap: () async {
                Navigator.pop(sheetContext);
                try {
                  await _mediaService.togglePublishStatus(
                      item.id, !item.isPublished);
                  if (!context.mounted) return;
                  _snack(
                    context,
                    item.isPublished
                        ? 'Média retiré de la publication'
                        : 'Média publié avec succès',
                  );
                } catch (e) {
                  if (!context.mounted) return;
                  _snack(context, 'Erreur: $e', isError: true);
                }
              },
            ),
            const Divider(color: AzizColors.cardBorder, height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined,
                  color: AzizColors.textPrimary),
              title: const Text('Modifier',
                  style: TextStyle(color: AzizColors.textPrimary)),
              onTap: () {
                Navigator.pop(sheetContext);
                _openForm(context, existing: item);
              },
            ),
            const Divider(color: AzizColors.cardBorder, height: 1),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: Colors.redAccent),
              title: const Text('Supprimer',
                  style: TextStyle(
                      color: Colors.redAccent, fontWeight: FontWeight.bold)),
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(context, item);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, MediaItem item) async {
    final title = item.titleFr.isNotEmpty
        ? item.titleFr
        : (item.titleEn.isNotEmpty ? item.titleEn : 'Ce média');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AzizColors.surface,
        title: const Text('Supprimer ce média ?',
            style: TextStyle(color: AzizColors.textPrimary)),
        content: Text(
          '« $title » sera définitivement supprimé, ainsi que ses fichiers. '
          'Cette action est irréversible.',
          style: const TextStyle(color: AzizColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annuler',
                style: TextStyle(color: AzizColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Supprimer',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    try {
      await _mediaService.deleteMedia(item.id);
      if (!context.mounted) return;
      _snack(context, 'Média supprimé avec succès');
    } catch (e) {
      if (!context.mounted) return;
      _snack(context, 'Erreur: $e', isError: true);
    }
  }

  Widget _buildTypeFilterBar(List<MediaItem> items, MediaType? activeFilter) {
    final types = items.map((i) => i.type).toSet().toList()
      ..sort((a, b) => a.getLabel(context).compareTo(b.getLabel(context)));

    if (types.length < 2) return const SizedBox.shrink();

    return SizedBox(
      height: 52,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        children: [
          _typeChip(
              label: 'Tout',
              selected: activeFilter == null,
              color: AzizColors.gold,
              onTap: () => setState(() => _typeFilter = null)),
          for (final type in types) ...[
            const SizedBox(width: 8),
            _typeChip(
                label: type.getLabel(context),
                icon: type.icon,
                color: type.color,
                selected: activeFilter == type,
                onTap: () => setState(() => _typeFilter = type)),
          ],
        ],
      ),
    );
  }

  Widget _typeChip(
      {required String label,
      required bool selected,
      required Color color,
      required VoidCallback onTap,
      IconData? icon}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.18) : AzizColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: selected ? color : AzizColors.cardBorder,
              width: selected ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 17, color: selected ? color : AzizColors.textSecondary),
              const SizedBox(width: 6)
            ],
            Text(label,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: selected ? color : AzizColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = Responsive.isMobile(context);

    final body = StreamBuilder<List<MediaItem>>(
      stream: _mediaStream,
      builder: (context, snapshot) {
        if (snapshot.hasError && !snapshot.hasData) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline,
                    size: 40, color: Colors.redAccent),
                const SizedBox(height: 14),
                const Text('Impossible de charger les médias.',
                    style: TextStyle(color: AzizColors.textSecondary)),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: _reconnect,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Réessayer'),
                  style: OutlinedButton.styleFrom(
                      foregroundColor: AzizColors.gold),
                ),
              ],
            ),
          );
        }
        if (!snapshot.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AzizColors.gold));
        }

        final items = snapshot.data!;

        // Un filtre dont plus aucun média ne correspond est ignoré : sinon la
        // page resterait vide, sans barre de filtres pour le retirer.
        final availableTypes = items.map((i) => i.type).toSet();
        final activeFilter =
            (_typeFilter != null && availableTypes.contains(_typeFilter))
                ? _typeFilter
                : null;
        final filtered = activeFilter == null
            ? items
            : items.where((i) => i.type == activeFilter).toList();

        return Column(
          children: [
            _buildTypeFilterBar(items, activeFilter),
            const SizedBox(height: 8),
            Expanded(
              child: filtered.isEmpty
                  ? const Center(
                      child: Text('Aucun contenu disponible.',
                          style: TextStyle(
                              color: AzizColors.textMuted, fontSize: 15)),
                    )
                  : RefreshIndicator(
                      color: AzizColors.gold,
                      backgroundColor: AzizColors.surface,
                      onRefresh: () async {
                        _reconnect();
                        await Future<void>.delayed(
                            const Duration(milliseconds: 400));
                      },
                      child: GridView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        gridDelegate:
                            SliverGridDelegateWithMaxCrossAxisExtent(
                          maxCrossAxisExtent: isMobile ? 500 : 340,
                          mainAxisExtent: isMobile
                              ? MediaCard.horizontalLayoutHeight
                              : MediaCard.verticalLayoutHeight,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                        ),
                        itemCount: filtered.length,
                        itemBuilder: (context, i) {
                          final item = filtered[i];
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: MediaCard(
                                  item: item,
                                  isEn: false,
                                  onTap: () => _showItemMenu(context, item),
                                ),
                              ),
                              if (!item.isPublished)
                                const Positioned(
                                  top: 8,
                                  left: 8,
                                  child: IgnorePointer(child: _DraftBadge()),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
            ),
          ],
        );
      },
    );

    if (widget.embedded) {
      // Dans le hub, pas de Scaffold (donc pas de bouton flottant) :
      // on affiche un bouton « Nouveau » dans un en-tête.
      return Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Médias',
                      style: TextStyle(
                          color: AzizColors.textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800)),
                ),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AzizColors.gold,
                    foregroundColor: AzizColors.backgroundDark,
                  ),
                  onPressed: () => _openForm(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Nouveau',
                      style: TextStyle(fontWeight: FontWeight.w700)),
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
          title: 'Média',
          onBack: () => Navigator.of(context).maybePop(),
          actions: const [],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_admin_media',
        backgroundColor: AzizColors.gold,
        foregroundColor: AzizColors.backgroundDark,
        onPressed: () => _openForm(context),
        icon: const Icon(Icons.add),
        label: const Text('Nouveau',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: body,
    );
  }
}

/// Pastille « Brouillon » : la carte publique n'indique pas le statut.
class _DraftBadge extends StatelessWidget {
  const _DraftBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.visibility_off_outlined,
              size: 12, color: Colors.orangeAccent),
          SizedBox(width: 5),
          Text(
            'Brouillon',
            style: TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}