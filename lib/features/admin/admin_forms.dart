import 'dart:ui';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kDebugMode, kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:azizart/theme/admin_colors.dart';
import 'package:azizart/theme/admin_design.dart';
import 'package:azizart/services/image_compressor_service.dart';
import 'package:azizart/services/image_sniffer.dart';
import 'package:azizart/services/r2_storage_service.dart';
import 'package:azizart/widgets/optimized_image.dart';

/// Champ de texte d'administration moderne : libellé flottant, fond plus
/// sombre que la carte (le champ ressort), icône optionnelle, bouton
/// afficher/masquer pour les mots de passe.
Widget adminTextField(
  TextEditingController controller,
  String label, {
  bool req = false,
  bool isPassword = false,
  String? hint,
  String? hintText, // alias de `hint` (anciens appels)
  String? helper,
  IconData? icon,
  int maxLines = 1,
  TextInputType? keyboardType,
  TextInputAction? textInputAction,
  Iterable<String>? autofillHints,
  ValueChanged<String>? onSubmitted,
  String? Function(String?)? validator,
}) {
  return _AdminTextField(
    controller: controller,
    label: label,
    req: req,
    isPassword: isPassword,
    hint: hint ?? hintText,
    helper: helper,
    icon: icon,
    maxLines: maxLines,
    keyboardType: keyboardType,
    textInputAction: textInputAction,
    autofillHints: autofillHints,
    onSubmitted: onSubmitted,
    validator: validator,
  );
}

class _AdminTextField extends StatefulWidget {
  final TextEditingController controller;
  final String label;
  final bool req;
  final bool isPassword;
  final String? hint;
  final String? helper;
  final IconData? icon;
  final int maxLines;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onSubmitted;
  final String? Function(String?)? validator;

  const _AdminTextField({
    required this.controller,
    required this.label,
    required this.req,
    required this.isPassword,
    required this.hint,
    required this.helper,
    required this.icon,
    required this.maxLines,
    required this.keyboardType,
    required this.textInputAction,
    required this.autofillHints,
    required this.onSubmitted,
    required this.validator,
  });

  @override
  State<_AdminTextField> createState() => _AdminTextFieldState();
}

class _AdminTextFieldState extends State<_AdminTextField> {
  bool _obscure = true;

  OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: color, width: width),
      );

  @override
  Widget build(BuildContext context) {
    final multiline = !widget.isPassword && widget.maxLines > 1;

    return Padding(
      padding: const EdgeInsets.only(bottom: AdminDesign.sp12),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.isPassword && _obscure,
        maxLines: widget.isPassword ? 1 : widget.maxLines,
        keyboardType: widget.keyboardType,
        textInputAction: widget.textInputAction,
        autofillHints: widget.autofillHints,
        onFieldSubmitted: widget.onSubmitted,
        cursorColor: AdminColors.accent,
        style: const TextStyle(
          color: AdminColors.text,
          fontSize: AdminDesign.fsBody,
          height: 1.35,
        ),
        decoration: InputDecoration(
          labelText: widget.req ? '${widget.label} *' : widget.label,
          alignLabelWithHint: multiline,
          hintText: widget.hint,
          helperText: widget.helper,
          helperStyle: const TextStyle(
            color: AdminColors.textMuted,
            fontSize: 12,
          ),
          labelStyle: const TextStyle(
            color: AdminColors.textMuted,
            fontSize: AdminDesign.fsBody,
          ),
          floatingLabelStyle: const TextStyle(
            color: AdminColors.accent,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: AdminColors.textMuted.withValues(alpha: 0.55),
          ),
          errorStyle: const TextStyle(
            color: AdminColors.danger,
            fontSize: 12,
          ),
          prefixIcon: widget.icon == null
              ? null
              : Icon(widget.icon, size: 20, color: AdminColors.textMuted),
          suffixIcon: widget.isPassword
              ? IconButton(
                  tooltip: _obscure ? 'Afficher' : 'Masquer',
                  icon: Icon(
                    _obscure
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    size: 20,
                    color: AdminColors.textMuted,
                  ),
                  onPressed: () => setState(() => _obscure = !_obscure),
                )
              : null,
          filled: true,
          fillColor: AdminColors.bg.withValues(alpha: 0.55),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 16,
          ),
          border: _border(AdminColors.border),
          enabledBorder: _border(AdminColors.border),
          focusedBorder: _border(AdminColors.accent, 1.6),
          errorBorder: _border(AdminColors.danger),
          focusedErrorBorder: _border(AdminColors.danger, 1.6),
        ),
        validator: (value) {
          if (widget.req && (value == null || value.trim().isEmpty)) {
            return 'Ce champ est obligatoire';
          }
          return widget.validator?.call(value);
        },
      ),
    );
  }
}

/// Composant complet d'upload d'image d'administration.
///
/// L'image est réduite et convertie en JPEG avant l'envoi vers Cloudflare R2
/// (via la fonction Edge `r2-presign`) ; seule l'URL publique est renvoyée à
/// [onUploaded]. L'aperçu passe par `OptimizedImage` : les anciennes URLs et
/// les clés relatives s'affichent comme sur le site public.
class AdminImageUploadField extends StatefulWidget {
  final String currentUrl;
  final ValueChanged<String> onUploaded;
  final String label;
  final String? helperText;
  /// Dossier R2 de destination (voir `R2StorageService.allowedFolders`).
  final String folder;
  final String? fixedFileName;
  final bool compact;
  final double aspectRatio;
  final double maxPreviewHeight;

  const AdminImageUploadField({
    super.key,
    required this.currentUrl,
    required this.onUploaded,
    required this.label,
    this.helperText,
    required this.folder,
    @Deprecated('Ignoré : le stockage est uniquement Cloudflare R2.')
    String? bucket,
    this.fixedFileName,
    this.compact = false,
    this.aspectRatio = 1.0,
    this.maxPreviewHeight = 280.0,
  });

  @override
  State<AdminImageUploadField> createState() => _AdminImageUploadFieldState();
}

class _AdminImageUploadFieldState extends State<AdminImageUploadField> {
  String get _folder => widget.folder;

  /// Profil de compression selon le dossier ; `null` = aucun traitement
  /// (logo : la transparence PNG doit être conservée).
  ImageTargetType? get _targetType {
    switch (_folder) {
      case 'logo':
        return null;
      case 'about_avatars':
        return ImageTargetType.avatar;
      case 'about_banners':
        return ImageTargetType.banner;
      default:
        return ImageTargetType.artwork;
    }
  }

  static const int _maxBytes = 5 * 1024 * 1024; // 5 Mo

  final _picker = ImagePicker();
  final _r2 = R2StorageService();
  bool _isUploading = false;
  String? _error;
  bool _hoveringPreview = false;

  void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  // ─────────────────────────────────────────────────────────────────────
  // DÉTECTION MIME PAR MAGIC NUMBERS (fiable sur Web ET mobile)
  // ─────────────────────────────────────────────────────────────────────
  // ─────────────────────────────────────────────────────────────────────
  // COMPRESSION
  // ─────────────────────────────────────────────────────────────────────
  /// Réduit et convertit en JPEG (orientation EXIF appliquée). Les GIF, les
  /// fichiers à nom fixe et le dossier `logo` restent inchangés. En cas
  /// d'échec de décodage, l'original est envoyé tel quel.
  Future<({Uint8List bytes, String mime})> _prepare(
    Uint8List bytes,
    String mime,
    String fileName,
  ) async {
    final type = _targetType;
    final compressible = <String>{
      'image/jpeg',
      'image/png',
      'image/webp',
      if (kIsWeb) ImageSniffer.heic,
    };
    if (type == null ||
        widget.fixedFileName != null ||
        !compressible.contains(mime)) {
      return (bytes: bytes, mime: mime);
    }

    try {
      final result = await ImageCompressorService.compress(
        rawBytes: bytes,
        type: type,
        fileName: fileName,
      );
      if (result.wasCompressed) {
        return (bytes: result.bytes, mime: 'image/jpeg');
      }
    } catch (e) {
      _log('[IMG] ✖ compression ignorée : $e');
    }
    return (bytes: bytes, mime: mime);
  }

  // ─────────────────────────────────────────────────────────────────────
  // SÉLECTION + UPLOAD
  // ─────────────────────────────────────────────────────────────────────
  Future<void> _pickAndUpload() async {
    if (_isUploading) return;
    setState(() {
      _error = null;
      _isUploading = true;
    });

    try {
      XFile? file;
      try {
        // Le dossier `logo` reste intact (transparence PNG) ; les autres
        // images sont réduites par ImageCompressorService, pas ici.
        final keepOriginal = _targetType == null;
        file = await _picker.pickImage(
          source: ImageSource.gallery,
          maxWidth: keepOriginal ? null : 2400,
          maxHeight: keepOriginal ? null : 2400,
          requestFullMetadata: false,
        );
      } catch (e, st) {
        _log('[IMG] ✖ picker a levé: $e\n$st');
        _setError('Sélection impossible. Vérifiez les permissions.');
        return;
      }

      if (file == null) {
        _log('[IMG] ▶ sélection annulée');
        return;
      }

      Uint8List bytes;
      try {
        bytes = await file.readAsBytes();
      } catch (e) {
        _log('[IMG] ✖ readAsBytes: $e');
        _setError('Impossible de lire le fichier.');
        return;
      }

      final detectedMime = ImageSniffer.detectMime(bytes);
      _log('[IMG] ▶ MIME détecté: $detectedMime');

      if (detectedMime == 'application/octet-stream') {
        _setError('Format non reconnu. Utilisez JPG, PNG, WEBP ou GIF.');
        return;
      }

      if (detectedMime == ImageSniffer.heic && !kIsWeb) {
        _setError(
          'Format HEIC (iPhone) non supporté. Exportez en JPG depuis Photos.',
        );
        return;
      }

      final prepared = await _prepare(bytes, detectedMime, file.name);
      if (!mounted) return;

      if (prepared.mime == ImageSniffer.heic) {
        _setError(
          'Format HEIC (iPhone) non supporté. Exportez en JPG depuis Photos.',
        );
        return;
      }
      if (prepared.bytes.length > _maxBytes) {
        final mo = (prepared.bytes.length / 1024 / 1024).toStringAsFixed(1);
        _setError('Fichier trop volumineux ($mo Mo, maximum 5 Mo).');
        return;
      }
      _log(
        '[IMG] ▶ après traitement: ${prepared.bytes.length} octets '
        '(${prepared.mime})',
      );

      final user = Supabase.instance.client.auth.currentUser;
      if (user == null) {
        _setError('Session expirée. Reconnectez-vous.');
        return;
      }

      final ext = ImageSniffer.extensionFromMime(prepared.mime);
      final String key;
      try {
        key = widget.fixedFileName != null
            ? '$_folder/${widget.fixedFileName}$ext'
            : _r2.buildKey(folder: _folder, fileName: 'image$ext');
      } on ArgumentError {
        _setError('Dossier de destination invalide.');
        return;
      }

      _log('[IMG] ▶ upload key=$key mime=${prepared.mime}');
      String publicUrl;
      try {
        publicUrl = await _r2.upload(
          key: key,
          bytes: prepared.bytes,
          contentType: prepared.mime,
          fileName: 'image$ext',
        );
      } catch (e, st) {
        _log('[IMG] ✖ upload R2: $e\n$st');
        _setError(_friendlyUploadError(e));
        return;
      }

      final finalUrl = widget.fixedFileName != null
          ? '$publicUrl?v=${DateTime.now().millisecondsSinceEpoch}'
          : publicUrl;

      _log('[IMG] ✔ upload OK → $finalUrl');
      widget.onUploaded(finalUrl);
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  String _friendlyUploadError(Object e) {
    // Les erreurs de R2StorageService sont déjà rédigées en français et
    // contiennent le diagnostic exact (code R2, statut HTTP) : on les
    // affiche telles quelles au lieu de les masquer.
    if (e is R2UploadException) return e.message;
    final s = e.toString().toLowerCase();
    if (s.contains('failed to fetch') ||
        s.contains('xmlhttprequest') ||
        s.contains('cors')) {
      return 'Stockage inaccessible (CORS). Contactez l\'administrateur.';
    }
    return 'Échec de l\'envoi. Réessayez dans un instant.';
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() => _error = message);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AdminColors.danger,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 6),
      ),
    );
  }

  void _removeImage() {
    if (_error != null) setState(() => _error = null);
    widget.onUploaded('');
  }

  @override
  Widget build(BuildContext context) {
    return widget.compact ? _buildCompact(context) : _buildExpanded(context);
  }

  Widget _buildCompact(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stackVertically = constraints.maxWidth < 340;

        final preview = _CompactPreview(
          url: widget.currentUrl,
          folder: _folder,
          size: 96,
          isUploading: _isUploading,
          onTap: _isUploading ? null : _pickAndUpload,
        );

        final textBlock = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: AdminColors.text,
                fontSize: AdminDesign.fsBody,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.helperText ??
                  'JPG, PNG ou WEBP — 5 Mo maximum. Format recommandé : 3:4.',
              style: TextStyle(
                color: AdminColors.textMuted.withValues(alpha: 0.9),
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ],
        );

        final buttons = Wrap(
          spacing: 8,
          runSpacing: 8,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            _CompactButton(
              icon: widget.currentUrl.isEmpty
                  ? Icons.add_photo_alternate_outlined
                  : Icons.swap_horiz_rounded,
              label: widget.currentUrl.isEmpty ? 'Choisir' : 'Changer',
              primary: true,
              onTap: _isUploading ? null : _pickAndUpload,
            ),
            if (widget.currentUrl.isNotEmpty && !_isUploading)
              _CompactButton(
                icon: Icons.delete_outline_rounded,
                label: 'Retirer',
                primary: false,
                onTap: _removeImage,
              ),
          ],
        );

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (stackVertically) ...[
              Center(child: preview),
              const SizedBox(height: 16),
              textBlock,
              const SizedBox(height: 12),
              buttons,
            ] else
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  preview,
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        textBlock,
                        const SizedBox(height: 12),
                        buttons,
                      ],
                    ),
                  ),
                ],
              ),
            if (_error != null) _ErrorBox(message: _error!),
          ],
        );
      },
    );
  }

  Widget _buildExpanded(BuildContext context) {
    final hasImage = widget.currentUrl.isNotEmpty;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth;
        final idealHeight = availableWidth / widget.aspectRatio;
        final actualHeight = idealHeight > widget.maxPreviewHeight
            ? widget.maxPreviewHeight
            : idealHeight;
        final actualWidth = actualHeight * widget.aspectRatio;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.label,
              style: const TextStyle(
                color: AdminColors.textMuted,
                fontSize: AdminDesign.fsLabel,
              ),
            ),
            const SizedBox(height: AdminDesign.sp8),
            Center(
              child: MouseRegion(
                onEnter: (_) => setState(() => _hoveringPreview = true),
                onExit: (_) => setState(() => _hoveringPreview = false),
                child: SizedBox(
                  width: actualWidth,
                  height: actualHeight,
                  child: InkWell(
                    onTap: _isUploading ? null : _pickAndUpload,
                    borderRadius: BorderRadius.circular(AdminDesign.rMd),
                    child: CustomPaint(
                      foregroundPainter: _DashedBorderPainter(
                        color:
                            hasImage ? Colors.transparent : AdminColors.border,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AdminDesign.rMd),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            if (hasImage)
                              OptimizedImage(
                                url: widget.currentUrl,
                                folder: _folder,
                                fit: BoxFit.cover,
                                memCacheWidth: 900,
                                placeholder:
                                    Container(color: AdminColors.surfaceHi),
                                errorWidget: Container(
                                  color: AdminColors.surfaceHi,
                                  child: const Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      color: AdminColors.textMuted,
                                      size: 32,
                                    ),
                                  ),
                                ),
                              )
                            else
                              Container(color: AdminColors.surface),
                            if (hasImage)
                              Container(
                                color: Colors.black.withValues(
                                  alpha: _hoveringPreview ? 0.45 : 0.15,
                                ),
                              ),
                            if (!_isUploading)
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      hasImage
                                          ? Icons.edit_outlined
                                          : Icons.add_photo_alternate_outlined,
                                      color: Colors.white,
                                      size: 26,
                                    ),
                                    const SizedBox(height: AdminDesign.sp4),
                                    Text(
                                      hasImage
                                          ? 'Changer'
                                          : 'Cliquer pour importer',
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: AdminDesign.fsLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            if (_isUploading)
                              Container(
                                color: Colors.black.withValues(alpha: 0.5),
                                child: const Center(
                                  child: CircularProgressIndicator(
                                    color: AdminColors.accent,
                                    strokeWidth: 2,
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
            ),
            if (_error != null) _ErrorBox(message: _error!),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS AUXILIAIRES D'INTERFACE D'UPLOAD
// ─────────────────────────────────────────────────────────────────────────────

class _CompactPreview extends StatelessWidget {
  final String url;
  final String folder;
  final double size;
  final bool isUploading;
  final VoidCallback? onTap;

  const _CompactPreview({
    required this.url,
    required this.folder,
    required this.size,
    required this.isUploading,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasImage = url.isNotEmpty;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AdminDesign.rMd),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AdminColors.surface,
          borderRadius: BorderRadius.circular(AdminDesign.rMd),
          border: Border.all(color: AdminColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AdminDesign.rMd - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                OptimizedImage(
                  url: url,
                  folder: folder,
                  fit: BoxFit.cover,
                  memCacheWidth: 300,
                  placeholder: Container(color: AdminColors.surfaceHi),
                  errorWidget: Container(
                    color: AdminColors.surfaceHi,
                    child: const Center(
                      child: Icon(
                        Icons.broken_image,
                        color: AdminColors.textMuted,
                      ),
                    ),
                  ),
                )
              else
                const Center(
                  child: Icon(
                    Icons.add_a_photo_outlined,
                    color: AdminColors.textMuted,
                    size: 28,
                  ),
                ),
              if (isUploading)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: AdminColors.accent,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool primary;
  final VoidCallback? onTap;

  const _CompactButton({
    required this.icon,
    required this.label,
    required this.primary,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = primary ? AdminColors.accent : AdminColors.textMuted;
    final bg = primary
        ? AdminColors.accent.withValues(alpha: 0.14)
        : AdminColors.bg.withValues(alpha: 0.5);

    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            // 44 px de haut : zone tactile confortable sur mobile.
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: primary
                    ? AdminColors.accent.withValues(alpha: 0.35)
                    : AdminColors.border,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
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

class _ErrorBox extends StatelessWidget {
  final String message;
  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: AdminInfoBanner(message: message, isWarning: true),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  static const double _strokeWidth = 1.5;
  static const double _dash = 5;
  static const double _gap = 3;

  final Color color;

  _DashedBorderPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (color == Colors.transparent) return;

    final paint = Paint()
      ..color = color
      ..strokeWidth = _strokeWidth
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..addRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(0, 0, size.width, size.height),
          const Radius.circular(AdminDesign.rMd),
        ),
      );

    final dashPath = Path();
    for (final PathMetric metric in path.computeMetrics()) {
      double distance = 0;
      while (distance < metric.length) {
        dashPath.addPath(
          metric.extractPath(distance, distance + _dash),
          Offset.zero,
        );
        distance += _dash + _gap;
      }
    }

    canvas.drawPath(dashPath, paint);
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// WIDGETS DE FORMULAIRE PARTAGÉS
// ─────────────────────────────────────────────────────────────────────────────

/// Carte de section : surface élevée, coins arrondis, ombre douce et
/// en-tête avec pastille d'icône.
class AdminCard extends StatelessWidget {
  final Widget child;
  final String? title;
  final IconData? icon;
  final EdgeInsetsGeometry padding;

  const AdminCard({
    super.key,
    required this.child,
    this.title,
    this.icon,
    this.padding = const EdgeInsets.all(AdminDesign.sp16),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AdminColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null || icon != null) ...[
            Row(
              children: [
                if (icon != null) ...[
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AdminColors.accent.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, size: 18, color: AdminColors.accent),
                  ),
                  const SizedBox(width: 10),
                ],
                if (title != null)
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        color: AdminColors.text,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.1,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AdminDesign.sp16),
          ],
          child,
        ],
      ),
    );
  }
}

/// Bouton principal (Enregistrer / Publier) : 52 px, halo coloré,
/// état de chargement.
class AdminPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const AdminPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = !loading && onPressed != null;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AdminColors.accent.withValues(alpha: 0.28),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: FilledButton(
          onPressed: enabled ? onPressed : null,
          style: FilledButton.styleFrom(
            backgroundColor: AdminColors.accent,
            foregroundColor: AdminColors.textOnAccent,
            disabledBackgroundColor: AdminColors.accent.withValues(alpha: 0.55),
            disabledForegroundColor: AdminColors.textOnAccent,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: loading
                ? const SizedBox(
                    key: ValueKey('loading'),
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      color: AdminColors.textOnAccent,
                    ),
                  )
                : Row(
                    key: const ValueKey('label'),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        label,
                        style: const TextStyle(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
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

/// Bouton secondaire (Annuler, Retour…) : contour fin.
class AdminSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const AdminSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: onPressed,
        icon: icon == null ? const SizedBox.shrink() : Icon(icon, size: 18),
        label: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: AdminColors.text,
          side: const BorderSide(color: AdminColors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}

/// Bandeau d'information (ou d'avertissement si [isWarning]).
class AdminInfoBanner extends StatelessWidget {
  final String message;
  final bool isWarning;

  const AdminInfoBanner({
    super.key,
    required this.message,
    this.isWarning = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isWarning ? AdminColors.danger : AdminColors.accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isWarning ? Icons.error_outline_rounded : Icons.info_outline_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: isWarning ? color : AdminColors.text,
                fontSize: 13,
                height: 1.45,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Groupe de champs bilingue FR / EN : titre (obligatoire en FR) et,
/// si les contrôleurs sont fournis, description.
class LocalizedFieldGroup extends StatelessWidget {
  final TextEditingController titleFrController;
  final TextEditingController titleEnController;
  final TextEditingController? descriptionFrController;
  final TextEditingController? descriptionEnController;
  final int descriptionMaxLines;

  const LocalizedFieldGroup({
    super.key,
    required this.titleFrController,
    required this.titleEnController,
    this.descriptionFrController,
    this.descriptionEnController,
    this.descriptionMaxLines = 4,
  });

  Widget _column({
    required String lang,
    required TextEditingController title,
    required TextEditingController? description,
    required bool req,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        adminTextField(title, 'Titre ($lang)', req: req),
        if (description != null) ...[
          adminTextField(
            description,
            'Description ($lang)',
            maxLines: descriptionMaxLines,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final fr = _column(
      lang: 'FR',
      title: titleFrController,
      description: descriptionFrController,
      req: true,
    );
    final en = _column(
      lang: 'EN',
      title: titleEnController,
      description: descriptionEnController,
      req: false,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 600) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [fr, const SizedBox(height: AdminDesign.sp16), en],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: fr),
            const SizedBox(width: AdminDesign.sp16),
            Expanded(child: en),
          ],
        );
      },
    );
  }
}

/// Mise en page formulaire + aperçu : côte à côte sur grand écran,
/// empilés (aperçu en premier) sur mobile.
class AdminFormPreviewLayout extends StatelessWidget {
  final Widget form;
  final Widget preview;
  final double breakpoint;

  const AdminFormPreviewLayout({
    super.key,
    required this.form,
    required this.preview,
    this.breakpoint = 900,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              preview,
              const SizedBox(height: AdminDesign.sp16),
              form,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: form),
            const SizedBox(width: AdminDesign.sp24),
            Expanded(flex: 2, child: preview),
          ],
        );
      },
    );
  }
}