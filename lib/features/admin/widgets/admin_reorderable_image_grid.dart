/*
 * Developed by Wilcoco
 * Application: AzizArt
 * Description: Grille d'images réordonnable avec tuile "+" pour ajouter
 *              (stockage des images : Cloudflare R2)
 */

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RendererBinding;
import 'package:image_picker/image_picker.dart';

import '../../../services/image_compressor_service.dart';
import '../../../services/image_sniffer.dart';
import '../../../services/media_url_resolver.dart';
import '../../../services/r2_storage_service.dart';
import '../../../theme/aziz_colors.dart';
import '../../../widgets/optimized_image.dart';
import 'image_source_sheet.dart';

class AdminImageItem {
  /// URL publique affichée (R2, ou ancienne URL Supabase Storage).
  final String url;
  int sortOrder;
  final String? id;

  /// Clé de l'objet dans R2 (ex. `atelier/20260105_101530_ab12_photo.jpg`).
  final String? storagePath;

  AdminImageItem({
    required this.url,
    required this.sortOrder,
    this.id,
    this.storagePath,
  });
}

class AdminReorderableImageGrid extends StatefulWidget {
  final List<AdminImageItem> images;

  /// Dossier R2 de destination (voir `R2StorageService.allowedFolders`).
  final String storageFolder;
  final void Function(int from, int to) onReorder;
  final ValueChanged<AdminImageItem> onImageAdded;
  final ValueChanged<AdminImageItem> onImageEdited;
  final ValueChanged<AdminImageItem> onImageDeleted;
  final ValueChanged<String>? onError;
  final int crossAxisCount;
  final double childAspectRatio;
  final int maxImageSize;

  /// Nombre maximal d'images (la tuile « + » disparaît une fois atteint).
  final int? maxImages;

  /// Si vrai, la grille ne supprime AUCUN fichier de R2 : le parent purge
  /// les fichiers retirés ou remplacés une fois la base mise à jour. À
  /// utiliser quand l'enregistrement n'est pas immédiat (sinon, annuler la
  /// page laisserait en base l'URL d'un fichier déjà supprimé).
  final bool deferStorageCleanup;

  const AdminReorderableImageGrid({
    super.key,
    required this.images,
    @Deprecated(
      'Ignoré : R2 est désormais l\'unique stockage d\'images. '
      'Supprimez ce paramètre.',
    )
    String? storageBucket,
    required this.storageFolder,
    required this.onReorder,
    required this.onImageAdded,
    required this.onImageEdited,
    required this.onImageDeleted,
    this.onError,
    this.crossAxisCount = 3,
    this.childAspectRatio = 1.0,
    this.maxImageSize = 2400,
    this.maxImages,
    this.deferStorageCleanup = false,
  });

  @override
  State<AdminReorderableImageGrid> createState() =>
      _AdminReorderableImageGridState();
}

class _AdminReorderableImageGridState extends State<AdminReorderableImageGrid> {
  static const int _maxBytes = 5 * 1024 * 1024; // 5 Mo

  final ImagePicker _picker = ImagePicker();
  final R2StorageService _r2 = R2StorageService();
  bool _busy = false;

  bool get _reachedMax =>
      widget.maxImages != null && widget.images.length >= widget.maxImages!;

  // ══════════════════════════════════════════════════════════════════════
  // CLOUDFLARE R2 — envoi et suppression
  // ══════════════════════════════════════════════════════════════════════

  String get _folder =>
      widget.storageFolder.replaceAll(RegExp(r'^/+|/+$'), '');

  /// Lit, vérifie, réduit puis envoie [file] dans R2 (via `r2-presign`,
  /// aucune clé secrète côté client). Retourne la clé et l'URL publique.
  Future<({String key, String url})> _uploadToR2(XFile file) async {
    var bytes = await file.readAsBytes();
    var mime = ImageSniffer.detectMime(bytes);

    if (mime == ImageSniffer.unknown) {
      throw const R2UploadException(
        'Format non reconnu. Utilisez JPG, PNG, WEBP ou GIF.',
      );
    }
    if (mime == ImageSniffer.heic && !kIsWeb) {
      throw const R2UploadException(
        'Format HEIC (iPhone) non supporté. Exportez en JPG depuis Photos.',
      );
    }

    // GIF : conservé tel quel (animation). Autres formats : réduits en JPEG.
    if (mime != 'image/gif') {
      try {
        final result = await ImageCompressorService.compress(
          rawBytes: bytes,
          type: ImageTargetType.artwork,
          fileName: file.name,
        );
        bytes = result.bytes;
        if (result.wasCompressed) mime = 'image/jpeg';
      } catch (e) {
        debugPrint('AdminReorderableImageGrid: compression ignorée — $e');
      }
      if (ImageSniffer.detectMime(bytes) == ImageSniffer.heic) {
        throw const R2UploadException(
          'Format HEIC (iPhone) non supporté. Exportez en JPG depuis Photos.',
        );
      }
    }

    if (bytes.length > _maxBytes) {
      final mo = (bytes.length / 1024 / 1024).toStringAsFixed(1);
      throw R2UploadException('Fichier trop volumineux ($mo Mo, maximum 5 Mo).');
    }

    final String key;
    try {
      key = _r2.buildKey(
        folder: _folder,
        fileName: 'image${ImageSniffer.extensionFromMime(mime)}',
      );
    } on ArgumentError {
      throw const R2UploadException('Dossier de destination invalide.');
    }

    final url = await _r2.upload(key: key, bytes: bytes, contentType: mime);
    return (key: key, url: url);
  }

  /// Supprime le fichier lié à [item] de R2 (anciennes URL Supabase et
  /// anciens domaines inclus : la résolution les ramène au bucket R2).
  /// Ne fait rien si [AdminReorderableImageGrid.deferStorageCleanup].
  Future<void> _deleteStorageFile(AdminImageItem item) async {
    if (widget.deferStorageCleanup) return;
    final resolved = MediaUrlResolver.resolve(item.url, folder: _folder);
    await _r2.deleteReferences(
      [resolved, item.storagePath],
      defaultFolder: _folder,
    );
  }

  Future<XFile?> _pickImage() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return null;
    return _picker.pickImage(
      source: source,
      maxWidth: widget.maxImageSize.toDouble(),
      maxHeight: widget.maxImageSize.toDouble(),
      requestFullMetadata: false,
    );
  }

  void _fail(String message) {
    if (!mounted) return;
    final onError = widget.onError;
    if (onError != null) {
      onError(message);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AzizColors.error),
    );
  }

  String _describe(Object e) =>
      e is R2UploadException ? e.message : 'Échec de l\'envoi. Réessayez.';

  Future<void> _pickAndUpload() async {
    if (_busy || _reachedMax) return;
    setState(() => _busy = true);
    try {
      final picked = await _pickImage();
      if (picked == null) return;

      final uploaded = await _uploadToR2(picked);
      if (!mounted) return;
      widget.onImageAdded(
        AdminImageItem(
          url: uploaded.url,
          sortOrder: widget.images.length,
          storagePath: uploaded.key,
        ),
      );
    } catch (e) {
      debugPrint('AdminReorderableImageGrid: upload — $e');
      _fail(_describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _replaceImage(AdminImageItem item) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final picked = await _pickImage();
      if (picked == null) return;

      // 1) Nouvelle image d'abord : si l'envoi échoue, l'ancienne reste.
      final uploaded = await _uploadToR2(picked);
      if (!mounted) return;
      widget.onImageEdited(
        AdminImageItem(
          url: uploaded.url,
          sortOrder: item.sortOrder,
          id: item.id,
          storagePath: uploaded.key,
        ),
      );

      // 2) Nettoyage de l'ancien fichier : un échec ne doit pas annuler le
      //    remplacement.
      try {
        await _deleteStorageFile(item);
      } catch (e) {
        debugPrint('AdminReorderableImageGrid: ancien fichier non supprimé — $e');
      }
    } catch (e) {
      debugPrint('AdminReorderableImageGrid: remplacement — $e');
      _fail(_describe(e));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _deleteImage(AdminImageItem item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AzizColors.surface,
        title: const Text(
          'Supprimer l\'image ?',
          style: TextStyle(color: AzizColors.textPrimary),
        ),
        content: const Text(
          'Cette action est irréversible.',
          style: TextStyle(color: AzizColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text(
              'Supprimer',
              style: TextStyle(color: AzizColors.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _deleteStorageFile(item);
      if (mounted) widget.onImageDeleted(item);
    } catch (e) {
      debugPrint('AdminReorderableImageGrid: suppression — $e');
      _fail('Suppression impossible. Réessayez.');
    }
  }

  void _showEditDeleteSheet(AdminImageItem item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: AzizColors.backgroundMedium,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: AzizColors.saffron.withValues(alpha: 0.18),
            ),
          ),
          padding:
              const EdgeInsets.only(top: 12, bottom: 8, left: 16, right: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AzizColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              ImageSheetAction(
                icon: Icons.image_rounded,
                label: 'Remplacer l\'image',
                onTap: () {
                  Navigator.pop(sheetContext);
                  _replaceImage(item);
                },
              ),
              const SizedBox(height: 8),
              ImageSheetAction(
                icon: Icons.delete_rounded,
                label: 'Supprimer l\'image',
                color: AzizColors.error,
                onTap: () {
                  Navigator.pop(sheetContext);
                  _deleteImage(item);
                },
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxWidth.isFinite) return const SizedBox.shrink();

        const spacing = 8.0;
        final itemWidth =
            ((constraints.maxWidth - (widget.crossAxisCount - 1) * spacing) /
                    widget.crossAxisCount)
                .floorToDouble();
        final itemHeight = itemWidth * widget.childAspectRatio;

        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (var i = 0; i < widget.images.length; i++)
              SizedBox(
                key: ValueKey(widget.images[i].id ?? widget.images[i].url),
                width: itemWidth,
                height: itemHeight,
                child: _DraggableImageTile(
                  item: widget.images[i],
                  index: i,
                  tileWidth: itemWidth,
                  tileHeight: itemHeight,
                  onTap: () => _showEditDeleteSheet(widget.images[i]),
                  onReorder: widget.onReorder,
                ),
              ),
            if (!_reachedMax)
              SizedBox(
                width: itemWidth,
                height: itemHeight,
                child: _AddTile(busy: _busy, onTap: _pickAndUpload),
              ),
          ],
        );
      },
    );
  }
}

class _DraggableImageTile extends StatelessWidget {
  final AdminImageItem item;
  final int index;
  final double tileWidth;
  final double tileHeight;
  final VoidCallback onTap;
  final void Function(int from, int to) onReorder;

  const _DraggableImageTile({
    required this.item,
    required this.index,
    required this.tileWidth,
    required this.tileHeight,
    required this.onTap,
    required this.onReorder,
  });

  @override
  Widget build(BuildContext context) {
    // Souris branchée : glisser immédiat. Écran tactile : appui long
    // (sinon le glisser bloquerait le défilement de la page).
    final hasMouse = RendererBinding.instance.mouseTracker.mouseIsConnected;

    final feedback = Material(
      color: Colors.transparent,
      child: SizedBox(
        width: tileWidth,
        height: tileHeight,
        child: Opacity(
          opacity: 0.85,
          child: _ImageTile(item: item, onTap: () {}),
        ),
      ),
    );
    final childWhenDragging = Opacity(
      opacity: 0.3,
      child: _ImageTile(item: item, onTap: onTap),
    );

    return DragTarget<int>(
      onWillAcceptWithDetails: (details) => details.data != index,
      onAcceptWithDetails: (details) => onReorder(details.data, index),
      builder: (context, candidateData, rejectedData) {
        final isDropTarget = candidateData.isNotEmpty;
        final child = AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: isDropTarget
                ? Border.all(color: AzizColors.saffron, width: 2.5)
                : null,
          ),
          child: _ImageTile(item: item, onTap: onTap),
        );

        return hasMouse
            ? Draggable<int>(
                data: index,
                feedback: feedback,
                childWhenDragging: childWhenDragging,
                child: child,
              )
            : LongPressDraggable<int>(
                data: index,
                feedback: feedback,
                childWhenDragging: childWhenDragging,
                child: child,
              );
      },
    );
  }
}

class _ImageTile extends StatelessWidget {
  final AdminImageItem item;
  final VoidCallback onTap;

  const _ImageTile({required this.item, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Image ${item.sortOrder + 1} : modifier ou supprimer',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AzizColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AzizColors.cardBorder.withValues(alpha: 0.3),
                width: 0.5,
              ),
            ),
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: OptimizedImage(
                    url: item.url,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    memCacheWidth: 600,
                    backgroundColor: AzizColors.surface,
                    errorWidget: const Center(
                      child: Icon(
                        Icons.broken_image_rounded,
                        color: AzizColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.5),
                          Colors.transparent,
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color:
                                AzizColors.background.withValues(alpha: 0.7),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.drag_handle_rounded,
                            size: 14,
                            color: AzizColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
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

class _AddTile extends StatelessWidget {
  final bool busy;
  final VoidCallback onTap;

  const _AddTile({required this.busy, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Ajouter une image',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: busy ? null : onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            decoration: BoxDecoration(
              color: AzizColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AzizColors.saffron.withValues(alpha: 0.3),
                width: 1.5,
              ),
            ),
            child: busy
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AzizColors.saffron,
                      ),
                    ),
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AzizColors.saffron.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          size: 24,
                          color: AzizColors.saffron,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Ajouter',
                        style: TextStyle(
                          color: AzizColors.textSecondary,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
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