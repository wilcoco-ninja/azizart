import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ⚠️ Si le build répond « Not found » sur la ligne ci-dessous, cherchez le
// vrai emplacement avec :  dir /s /b lib\r2_storage_service.dart
// puis corrigez uniquement ce chemin relatif.
import '../../services/image_compressor_service.dart';
import '../../services/image_sniffer.dart';
import '../../services/r2_storage_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_design.dart';
import '../media/models/media_model.dart';
import '../media/services/media_service.dart';
import 'layout/admin_app_bar.dart';

class MediaFormPage extends StatefulWidget {
  final MediaItem? existing;

  const MediaFormPage({super.key, this.existing});

  @override
  State<MediaFormPage> createState() => _MediaFormPageState();
}

class _MediaFormPageState extends State<MediaFormPage> {
  // Le fichier est lu entièrement en mémoire avant l'envoi vers R2 :
  // au-delà de ces limites, mieux vaut coller un lien YouTube / Vimeo.
  static const int _maxThumbBytes = 5 * 1024 * 1024; // 5 Mo
  static const int _maxMediaBytes = 100 * 1024 * 1024; // 100 Mo

  // Dossier R2 autorisé par R2StorageService._uploadAllowedFolders.
  static const String _r2Folder = 'media';

  final _formKey = GlobalKey<FormState>();
  final _r2 = R2StorageService();
  final _mediaService = MediaService();

  /// Fichiers envoyés pendant l'enregistrement en cours : supprimés de R2
  /// si l'écriture en base échoue (aucun fichier orphelin).
  final List<String> _uploadedThisSave = [];

  late final TextEditingController _titleFrCtrl;
  late final TextEditingController _titleEnCtrl;
  late final TextEditingController _descFrCtrl;
  late final TextEditingController _descEnCtrl;
  late final TextEditingController _urlCtrl;
  late final TextEditingController _durationCtrl;
  late final TextEditingController _yearCtrl;
  late final TextEditingController _sourceCtrl;

  MediaType _type = MediaType.video;
  DateTime? _date;
  bool _isPublished = true;
  String _existingThumbUrl = '';
  PlatformFile? _selectedThumbFile;
  PlatformFile? _selectedMediaFile;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;

    _titleFrCtrl = TextEditingController(text: e?.titleFr ?? '');
    _titleEnCtrl = TextEditingController(text: e?.titleEn ?? '');
    _descFrCtrl = TextEditingController(text: e?.descriptionFr ?? '');
    _descEnCtrl = TextEditingController(text: e?.descriptionEn ?? '');
    _urlCtrl = TextEditingController(text: e?.url ?? '');
    _durationCtrl = TextEditingController(text: e?.duration ?? '');
    _yearCtrl = TextEditingController(
      text: e?.year ?? DateTime.now().year.toString(),
    );
    _sourceCtrl = TextEditingController(text: e?.source ?? 'YouTube');

    _type = e?.type ?? MediaType.video;
    _date = e?.date;
    _isPublished = e?.isPublished ?? true;
    _existingThumbUrl = e?.thumbnailUrl ?? '';
  }

  @override
  void dispose() {
    _titleFrCtrl.dispose();
    _titleEnCtrl.dispose();
    _descFrCtrl.dispose();
    _descEnCtrl.dispose();
    _urlCtrl.dispose();
    _durationCtrl.dispose();
    _yearCtrl.dispose();
    _sourceCtrl.dispose();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════
  // SNACKBAR + LOG
  // ══════════════════════════════════════════════════════════════════════
  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    debugPrint('[MEDIA_FORM] ${isError ? "✖" : "✔"} $message');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? AdminColors.danger : AdminColors.success,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: isError ? 6 : 3),
      ),
    );
  }

  String? _validateMediaUrl(String? value) {
    final t = (value ?? '').trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    final ok = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return ok ? null : 'URL invalide (ex. https://…)';
  }

  String _friendlyError(Object e) {
    if (e is R2UploadException) return e.message;
    final s = e.toString().toLowerCase();
    if (s.contains('failed to fetch') ||
        s.contains('xmlhttprequest') ||
        s.contains('cors')) {
      return 'Stockage inaccessible (CORS). Contactez l\'administrateur.';
    }
    if (s.contains('presign échec (404)')) {
      return 'Service de stockage indisponible.';
    }
    if (s.contains('presign échec (500)')) {
      return 'Service de stockage mal configuré.';
    }
    if (s.contains('dossier r2 invalide')) {
      return 'Dossier de destination invalide.';
    }
    if (s.contains('row-level security')) {
      return 'Permissions insuffisantes pour enregistrer ce média.';
    }
    if (s.contains('duplicate key') || s.contains('unique constraint')) {
      return 'Ce média existe déjà.';
    }
    if (s.contains('jwt') || s.contains('not authenticated')) {
      return 'Session expirée. Reconnectez-vous.';
    }
    return 'Erreur : $e';
  }

  // ══════════════════════════════════════════════════════════════════════
  // VALIDATION DE FICHIER
  // ══════════════════════════════════════════════════════════════════════
  Future<bool> _fitsLimit(
    PlatformFile file,
    int maxBytes,
    String label,
  ) async {
    final size = file.lengthSync() ?? await file.length();
    if (size != null && size > maxBytes) {
      final maxMo = maxBytes ~/ (1024 * 1024);
      final sizeMo = (size / (1024 * 1024)).toStringAsFixed(1);
      _snack('$label dépasse $maxMo Mo ($sizeMo Mo).', isError: true);
      return false;
    }
    return true;
  }

  // ══════════════════════════════════════════════════════════════════════
  // SÉLECTION DE FICHIERS
  // ══════════════════════════════════════════════════════════════════════
  // ⚠️ `FilePicker.pickFile()` est l'API utilisée dans votre codebase.
  //    Si elle ne compile pas dans votre version de file_picker, remplacez
  //    chaque appel par :
  //
  //      final result = await FilePicker.platform.pickFiles(
  //        type: FileType.image, allowMultiple: false,
  //      );
  //      final file = result?.files.firstOrNull;
  //
  Future<void> _pickThumbnail() async {
    try {
      final file = await FilePicker.pickFile(type: FileType.image);
      if (file == null || !mounted) return;
      if (!await _fitsLimit(file, _maxThumbBytes, 'La vignette')) return;
      setState(() => _selectedThumbFile = file);
    } catch (e) {
      debugPrint('[MEDIA_FORM] ✖ _pickThumbnail: $e');
      _snack('Sélection impossible : $e', isError: true);
    }
  }

  Future<void> _pickMediaFile() async {
    try {
      final file = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['mp4', 'mov', 'mp3', 'wav', 'pdf'],
      );
      if (file == null || !mounted) return;
      if (!await _fitsLimit(file, _maxMediaBytes, 'Le fichier')) return;
      setState(() => _selectedMediaFile = file);
    } catch (e) {
      debugPrint('[MEDIA_FORM] ✖ _pickMediaFile: $e');
      _snack('Sélection impossible : $e', isError: true);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final first = DateTime(1990);
    final last = DateTime(2035);
    var initial = _date ?? DateTime.now();
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AdminColors.accent,
            surface: AdminColors.surfaceElevated,
            onSurface: AdminColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _date = picked);
  }

  // ══════════════════════════════════════════════════════════════════════
  // UPLOAD R2 (avec contentType réel)
  // ══════════════════════════════════════════════════════════════════════
  /// Envoie un fichier vers Cloudflare R2 et retourne son URL publique.
  /// Une vignette ([compressImage]) est réduite et convertie en JPEG.
  Future<String> _uploadToR2(
    PlatformFile file,
    String prefix, {
    bool compressImage = false,
  }) async {
    var bytes = await file.readAsBytes();
    var fileName = file.name;
    String? contentType;

    if (compressImage) {
      // JPEG / PNG / WEBP uniquement : un GIF animé ne doit pas être aplati.
      // Le HEIC n'est décodable que par le navigateur (Web).
      final sniffed = ImageSniffer.detectMime(bytes);
      final compressible = <String>{
        'image/jpeg',
        'image/png',
        'image/webp',
        if (kIsWeb) ImageSniffer.heic,
      };
      if (compressible.contains(sniffed)) {
        try {
          final result = await ImageCompressorService.compress(
            rawBytes: bytes,
            type: ImageTargetType.avatar,
            fileName: file.name,
          );
          bytes = result.bytes;
          if (result.wasCompressed) {
            final dot = file.name.lastIndexOf('.');
            final base = dot > 0 ? file.name.substring(0, dot) : file.name;
            fileName = '$base.jpg';
            contentType = 'image/jpeg';
          }
        } catch (e) {
          // Image illisible pour le compresseur : on tente l'original.
          debugPrint('[MEDIA_FORM] compression ignorée : $e');
        }
      }
      if (ImageSniffer.detectMime(bytes) == ImageSniffer.heic) {
        throw const R2UploadException(
          'Format HEIC (iPhone) non supporté. Exportez la vignette en JPG.',
        );
      }
    }

    final sniffedType = ImageSniffer.detectMime(bytes);
    contentType ??= sniffedType != ImageSniffer.unknown
        ? sniffedType
        : _contentTypeFromName(fileName);

    final key = _r2.buildKey(
      folder: _r2Folder,
      fileName: '${prefix}_$fileName',
    );

    final url = await _r2.upload(
      key: key,
      bytes: bytes,
      contentType: contentType,
      fileName: fileName,
    );
    _uploadedThisSave.add(url);
    return url;
  }

  String _contentTypeFromName(String name) {
    final lower = name.toLowerCase();
    if (lower.endsWith('.mp4')) return 'video/mp4';
    if (lower.endsWith('.mov')) return 'video/quicktime';
    if (lower.endsWith('.mp3')) return 'audio/mpeg';
    if (lower.endsWith('.wav')) return 'audio/wav';
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    return 'application/octet-stream';
  }

  /// Supprime de R2 des fichiers envoyés mais jamais rattachés à une ligne.
  Future<void> _cleanupUploads(List<String> urls) async {
    try {
      await _r2.deleteReferences(urls);
    } catch (e) {
      debugPrint('[MEDIA_FORM] fichiers R2 non nettoyés — $e');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // SAUVEGARDE
  // ══════════════════════════════════════════════════════════════════════
  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_urlCtrl.text.trim().isEmpty && _selectedMediaFile == null) {
      _snack('Ajoutez une URL ou téléversez un fichier média.',
          isError: true);
      return;
    }

    // ① Vérifie la session AVANT tout appel réseau.
    if (Supabase.instance.client.auth.currentUser == null) {
      _snack('Session expirée. Reconnectez-vous.', isError: true);
      return;
    }

    setState(() => _saving = true);
    _uploadedThisSave.clear();

    try {
      // ② Upload vignette (si nouvelle) : réduite et convertie en JPEG.
      var thumbUrl = _existingThumbUrl;
      final thumbFile = _selectedThumbFile;
      if (thumbFile != null) {
        thumbUrl = await _uploadToR2(thumbFile, 'thumb', compressImage: true);
      }

      // ③ Upload média (si nouveau)
      var mediaUrl = _urlCtrl.text.trim();
      final mediaFile = _selectedMediaFile;
      if (mediaFile != null) {
        mediaUrl = await _uploadToR2(mediaFile, 'file');
      }

      final existing = widget.existing;
      final duration = _durationCtrl.text.trim();
      final item = MediaItem(
        id: existing?.id ?? '',
        titleFr: _titleFrCtrl.text.trim(),
        titleEn: _titleEnCtrl.text.trim(),
        descriptionFr: _descFrCtrl.text.trim(),
        descriptionEn: _descEnCtrl.text.trim(),
        type: _type,
        source: (mediaFile != null &&
                _sourceCtrl.text.trim().toLowerCase() == 'youtube')
            ? 'Fichier'
            : _sourceCtrl.text.trim(),
        url: mediaUrl,
        thumbnailUrl: thumbUrl,
        // L'ancienne clé relative n'est conservée que si aucune URL n'existe.
        thumbnailPath:
            thumbUrl.isEmpty ? (existing?.thumbnailPath ?? '') : '',
        year: _yearCtrl.text.trim(),
        duration: duration.isEmpty ? null : duration,
        date: _date,
        isPublished: _isPublished,
      );

      // ④ MediaService : vérifie le rôle admin et supprime de R2 les fichiers
      //    remplacés (vignette ou média).
      if (existing == null) {
        await _mediaService.addMedia(item);
      } else {
        await _mediaService.updateMedia(existing.id, item);
      }
      _uploadedThisSave.clear();

      if (!mounted) return;

      _snack(
        existing != null
            ? 'Média mis à jour avec succès'
            : 'Média créé avec succès',
      );

      Navigator.of(context).pop(true);
    } catch (e, st) {
      debugPrint('[MEDIA_FORM] ✖ _save: $e\n$st');
      // Fichiers envoyés mais jamais rattachés à une ligne : on les retire.
      if (_uploadedThisSave.isNotEmpty) {
        unawaited(_cleanupUploads(List<String>.of(_uploadedThisSave)));
        _uploadedThisSave.clear();
      }
      _snack(_friendlyError(e), isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // WIDGETS DE FORMULAIRE
  // ══════════════════════════════════════════════════════════════════════
  Widget _buildAdminTextField(
    TextEditingController controller,
    String label, {
    String? hintText,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AdminColors.text, fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: const TextStyle(color: AdminColors.textMuted),
        hintStyle: const TextStyle(color: AdminColors.textMuted),
        filled: true,
        fillColor: AdminColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminDesign.rSm),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminDesign.rSm),
          borderSide: const BorderSide(color: AdminColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AdminDesign.rSm),
          borderSide: const BorderSide(color: AdminColors.accent),
        ),
      ),
    );
  }

  Widget _row(Widget left, Widget right, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          left,
          const SizedBox(height: AdminDesign.sp12),
          right,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: left),
        const SizedBox(width: AdminDesign.sp12),
        Expanded(child: right),
      ],
    );
  }

  Widget _dateTile() {
    final dateStr = _date != null
        ? '${_date!.day.toString().padLeft(2, '0')}/'
            '${_date!.month.toString().padLeft(2, '0')}/${_date!.year}'
        : 'Sélectionner une date (Optionnel)';

    return Container(
      decoration: BoxDecoration(
        color: AdminColors.bg.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(AdminDesign.rSm),
        border: Border.all(color: AdminColors.border),
      ),
      child: ListTile(
        title: const Text(
          'Date de l\'événement / publication',
          style: TextStyle(
            color: AdminColors.text,
            fontSize: AdminDesign.fsBody,
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          dateStr,
          style: TextStyle(
            color:
                _date != null ? AdminColors.accent : AdminColors.textMuted,
            fontSize: AdminDesign.fsLabel,
          ),
        ),
        trailing: const Icon(
          Icons.calendar_today_outlined,
          color: AdminColors.accent,
          size: 20,
        ),
        onTap: () => _selectDate(context),
      ),
    );
  }

  Widget _cardSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AdminDesign.sp16),
      decoration: BoxDecoration(
        color: AdminColors.surface,
        borderRadius: BorderRadius.circular(AdminDesign.rMd),
        border: Border.all(color: AdminColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: AdminColors.text,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AdminDesign.sp12),
          ...children,
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < 600;
    final hasExistingThumb = _existingThumbUrl.isNotEmpty ||
        (widget.existing?.thumbnailPath.isNotEmpty ?? false);

    return PopScope(
      canPop: !_saving,
      child: Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kAdminAppBarHeight),
        child: AdminAppBar(
          title:
              widget.existing != null ? 'Modifier le média' : 'Nouveau média',
          onBack: () => Navigator.of(context).pop(),
          actions: const [],
        ),
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints:
              const BoxConstraints(maxWidth: AdminDesign.formMaxWidth),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(AdminDesign.sp16),
              children: [
                _cardSection(
                  title: 'Informations Générales',
                  children: [
                    _row(
                      _buildAdminTextField(
                        _titleFrCtrl,
                        'Titre (FR)',
                        hintText: 'Titre en français',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Titre requis'
                            : null,
                      ),
                      _buildAdminTextField(
                        _titleEnCtrl,
                        'Titre (EN)',
                        hintText: 'Titre en anglais',
                      ),
                      isMobile,
                    ),
                    const SizedBox(height: AdminDesign.sp12),
                    _row(
                      _buildAdminTextField(
                        _descFrCtrl,
                        'Description (FR)',
                        hintText: 'Description en français',
                        maxLines: 3,
                      ),
                      _buildAdminTextField(
                        _descEnCtrl,
                        'Description (EN)',
                        hintText: 'Description en anglais',
                        maxLines: 3,
                      ),
                      isMobile,
                    ),
                  ],
                ),
                const SizedBox(height: AdminDesign.sp16),
                _cardSection(
                  title: 'Type & Source',
                  children: [
                    DropdownButtonFormField<MediaType>(
                      initialValue: _type,
                      dropdownColor: AdminColors.surfaceElevated,
                      style: const TextStyle(color: AdminColors.text),
                      decoration: const InputDecoration(
                        labelText: 'Type de média',
                        labelStyle: TextStyle(color: AdminColors.textMuted),
                        filled: true,
                        fillColor: AdminColors.bg,
                        border: OutlineInputBorder(),
                      ),
                      items: MediaType.values
                          .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.getLabel(context)),
                              ))
                          .toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _type = val);
                      },
                    ),
                    const SizedBox(height: AdminDesign.sp12),
                    _row(
                      _buildAdminTextField(
                        _sourceCtrl,
                        'Source',
                        hintText: 'YouTube, Vimeo, etc.',
                      ),
                      _buildAdminTextField(
                        _urlCtrl,
                        'URL du média / vidéo',
                        hintText: 'https://...',
                        validator: _validateMediaUrl,
                      ),
                      isMobile,
                    ),
                  ],
                ),
                const SizedBox(height: AdminDesign.sp16),
                _cardSection(
                  title: 'Métadonnées',
                  children: [
                    _row(
                      _buildAdminTextField(
                        _durationCtrl,
                        'Durée',
                        hintText: '12:34',
                      ),
                      _buildAdminTextField(
                        _yearCtrl,
                        'Année',
                        hintText: '2024',
                      ),
                      isMobile,
                    ),
                    const SizedBox(height: AdminDesign.sp12),
                    _dateTile(),
                    const SizedBox(height: AdminDesign.sp12),
                    Container(
                      decoration: BoxDecoration(
                        color: AdminColors.bg.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(AdminDesign.rSm),
                        border: Border.all(
                          color: _isPublished
                              ? AdminColors.success.withValues(alpha: 0.5)
                              : AdminColors.border,
                        ),
                      ),
                      child: SwitchListTile(
                        title: const Text(
                          'Statut de publication',
                          style: TextStyle(
                            color: AdminColors.text,
                            fontSize: AdminDesign.fsBody,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          _isPublished
                              ? 'Visible par le public'
                              : 'Caché (Brouillon)',
                          style: TextStyle(
                            color: _isPublished
                                ? AdminColors.success
                                : AdminColors.textMuted,
                            fontSize: AdminDesign.fsLabel,
                          ),
                        ),
                        value: _isPublished,
                        activeThumbColor: AdminColors.success,
                        onChanged: (val) =>
                            setState(() => _isPublished = val),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AdminDesign.sp16),
                _cardSection(
                  title: 'Fichiers & Vignette',
                  children: [
                    ListTile(
                      tileColor: AdminColors.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AdminDesign.rSm),
                        side:
                            const BorderSide(color: AdminColors.border),
                      ),
                      leading: const Icon(
                        Icons.image_outlined,
                        color: AdminColors.accent,
                      ),
                      title: Text(
                        _selectedThumbFile != null
                            ? _selectedThumbFile!.name
                            : (hasExistingThumb
                                ? 'Vignette existante'
                                : 'Choisir une image de vignette'),
                        style: const TextStyle(
                          color: AdminColors.text,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'JPG, PNG ou WEBP — 5 Mo maximum',
                        style: TextStyle(
                          color: AdminColors.textMuted,
                          fontSize: AdminDesign.fsLabel,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: _pickThumbnail,
                        child: const Text('Parcourir'),
                      ),
                    ),
                    const SizedBox(height: AdminDesign.sp12),
                    ListTile(
                      tileColor: AdminColors.bg,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AdminDesign.rSm),
                        side:
                            const BorderSide(color: AdminColors.border),
                      ),
                      leading: const Icon(
                        Icons.attach_file,
                        color: AdminColors.accent,
                      ),
                      title: Text(
                        _selectedMediaFile != null
                            ? _selectedMediaFile!.name
                            : 'Téléverser un fichier média (optionnel)',
                        style: const TextStyle(
                          color: AdminColors.text,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: const Text(
                        'MP4, MOV, MP3, WAV, PDF — 100 Mo maximum. '
                        'Au-delà, collez plutôt un lien YouTube / Vimeo.',
                        style: TextStyle(
                          color: AdminColors.textMuted,
                          fontSize: AdminDesign.fsLabel,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: _pickMediaFile,
                        child: const Text('Parcourir'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AdminDesign.sp24),
                SizedBox(
                  height: 48,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AdminColors.accent,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(AdminDesign.rSm),
                      ),
                    ),
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.black,
                            ),
                          )
                        : const Icon(Icons.save_outlined),
                    label: Text(
                      _saving
                          ? 'Enregistrement...'
                          : 'Enregistrer le média',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
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
    );
  }
}