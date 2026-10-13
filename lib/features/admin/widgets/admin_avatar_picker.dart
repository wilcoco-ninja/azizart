/*
 * Developed by Wilcoco
 * Application: AzizArt
 * Description: Sélecteur + upload d'avatar ou de bannière.
 *
 * Stockage : Cloudflare R2 via l'Edge Function `r2-presign`
 * (voir `R2StorageService`).
 */

import 'package:flutter/foundation.dart' show debugPrint, kIsWeb, kDebugMode;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../services/image_compressor_service.dart';
import '../../../services/image_sniffer.dart';
import '../../../services/r2_storage_service.dart';
import '../../../theme/aziz_colors.dart';
import '../../../widgets/optimized_image.dart';
import 'image_source_sheet.dart';

class AdminAvatarPicker extends StatefulWidget {
  final String? imageUrl;

  /// Clé R2 où l'image sera envoyée (upsert).
  ///
  /// ⚠️ Le préfixe DOIT appartenir à `R2StorageService.allowedFolders`.
  /// Exemples valides :
  ///   • `about_avatars/avatar.jpg`
  ///   • `about_banners/banner.jpg`
  ///
  /// L'extension est alignée automatiquement sur le format réellement envoyé.
  /// Comme la clé est fixe et que l'upload écrase (PUT), un même chemin ne
  /// conserve qu'une seule image.
  final String storagePath;

  final ValueChanged<String> onImageSelected;
  final ValueChanged<String>? onError;
  final double size;
  final double? width;
  final double? height;

  /// Si fourni, le sélecteur est rectangulaire (bannière) au lieu d'un cercle.
  final BorderRadius? borderRadius;

  const AdminAvatarPicker({
    super.key,
    this.imageUrl,
    required this.storagePath,
    required this.onImageSelected,
    this.onError,
    this.size = 100,
    this.width,
    this.height,
    this.borderRadius,
  });

  @override
  State<AdminAvatarPicker> createState() => _AdminAvatarPickerState();
}

class _AdminAvatarPickerState extends State<AdminAvatarPicker> {
  static const int _maxBytes = 5 * 1024 * 1024; // 5 Mo

  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  bool get _isRect => widget.borderRadius != null;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  /// Remplace l'extension de [key] par [ext] (avec point).
  String _alignExtension(String key, String ext) {
    final slash = key.lastIndexOf('/');
    final dot = key.lastIndexOf('.');
    final base = dot > slash ? key.substring(0, dot) : key;
    return '$base$ext';
  }

  Future<void> _pickAndUpload() async {
    if (_isUploading) return;

    final source = await showImageSourceSheet(context);
    if (source == null || !mounted) return;

    setState(() => _isUploading = true);
    try {
      XFile? picked;
      try {
        picked = await _picker.pickImage(
          source: source,
          maxWidth: 2400,
          maxHeight: 2400,
          requestFullMetadata: false,
        );
      } catch (e) {
        _log('[AVATAR] ✖ picker: $e');
        _fail('Sélection impossible. Vérifiez les permissions.');
        return;
      }
      if (picked == null) return;

      var bytes = await picked.readAsBytes();
      var mime = ImageSniffer.detectMime(bytes);
      _log('[AVATAR] ▶ mime=$mime, ${bytes.length} octets');

      if (mime == ImageSniffer.unknown) {
        _fail('Format non reconnu. Utilisez JPG, PNG, WEBP ou GIF.');
        return;
      }
      if (mime == ImageSniffer.heic && !kIsWeb) {
        _fail('Format HEIC (iPhone) non supporté. Exportez en JPG depuis Photos.');
        return;
      }

      // Réduction (avatar 800 px, bannière 1920 px) ; GIF conservé tel quel.
      if (mime != 'image/gif') {
        try {
          final result = await ImageCompressorService.compress(
            rawBytes: bytes,
            type: _isRect ? ImageTargetType.banner : ImageTargetType.avatar,
            fileName: picked.name,
          );
          bytes = result.bytes;
          if (result.wasCompressed) mime = 'image/jpeg';
        } catch (e) {
          _log('[AVATAR] compression ignorée : $e');
        }
        if (ImageSniffer.detectMime(bytes) == ImageSniffer.heic) {
          _fail('Format HEIC (iPhone) non supporté. Exportez en JPG depuis Photos.');
          return;
        }
      }

      if (bytes.length > _maxBytes) {
        final mo = (bytes.length / 1024 / 1024).toStringAsFixed(1);
        _fail('Fichier trop volumineux ($mo Mo, maximum 5 Mo).');
        return;
      }

      final rawKey = widget.storagePath.replaceFirst(RegExp(r'^/+'), '');
      if (rawKey.isEmpty) {
        _fail('storagePath (clé R2) est vide.');
        return;
      }
      final key = _alignExtension(rawKey, ImageSniffer.extensionFromMime(mime));

      String publicUrl;
      try {
        publicUrl = await R2StorageService().upload(
          key: key,
          bytes: bytes,
          contentType: mime,
        );
      } catch (e) {
        _log('[AVATAR] ✖ upload R2: $e');
        _fail(e is R2UploadException ? e.message : 'Échec de l\'envoi. Réessayez.');
        return;
      }

      // Cache-busting : la clé est figée, l'URL resterait identique.
      final url = '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}';
      if (mounted) widget.onImageSelected(url);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _fail(String message) {
    if (!mounted) return;
    final onError = widget.onError;
    if (onError != null) {
      onError(message);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AzizColors.error,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  Widget get _placeholderIcon => const Icon(
        Icons.person_rounded,
        size: 40,
        color: AzizColors.textSecondary,
      );

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = widget.width ?? widget.size;
    final effectiveHeight = widget.height ?? widget.size;
    final url = widget.imageUrl;
    final hasImage = url != null && url.isNotEmpty;
    final folder = widget.storagePath.split('/').first;

    return MouseRegion(
      cursor: _isUploading
          ? SystemMouseCursors.basic
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: _isUploading ? null : _pickAndUpload,
        child: Semantics(
          button: true,
          label: _isRect ? 'Changer la bannière' : 'Changer la photo de profil',
          child: SizedBox(
            width: effectiveWidth,
            height: effectiveHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: effectiveWidth,
                  height: effectiveHeight,
                  decoration: BoxDecoration(
                    shape: _isRect ? BoxShape.rectangle : BoxShape.circle,
                    borderRadius: _isRect ? widget.borderRadius : null,
                    color: AzizColors.surface,
                    border: Border.all(
                      color: AzizColors.saffron.withValues(alpha: 0.5),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: _isRect
                      ? ClipRRect(
                          borderRadius: widget.borderRadius!,
                          child: _content(hasImage, url, folder),
                        )
                      : ClipOval(child: _content(hasImage, url, folder)),
                ),
                if (!_isUploading)
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AzizColors.saffron,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AzizColors.background,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.edit_rounded,
                        size: 16,
                        color: AzizColors.textOnAccent,
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

  Widget _content(bool hasImage, String? url, String folder) {
    if (_isUploading) {
      return const Center(
        child: CircularProgressIndicator(color: AzizColors.saffron),
      );
    }
    if (!hasImage) return Center(child: _placeholderIcon);
    // OptimizedImage : résolution d'URL, repli <img> sur le Web, cache.
    return OptimizedImage(
      url: url,
      folder: folder,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      memCacheWidth: 600,
      errorWidget: Center(child: _placeholderIcon),
    );
  }
}