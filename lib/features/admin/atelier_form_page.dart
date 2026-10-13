import 'dart:async';

import 'package:flutter/material.dart';

import '../atelier/models/atelier_model.dart';
import '../atelier/services/atelier_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_design.dart';
import 'admin_forms.dart';
import 'upload_session_cleanup.dart';

class AtelierFormPage extends StatefulWidget {
  final AtelierPhoto? existing;
  final FutureOr<void> Function(AtelierPhoto photo)? onSave;

  const AtelierFormPage({super.key, this.existing, this.onSave});

  @override
  State<AtelierFormPage> createState() => _AtelierFormPageState();
}

class _AtelierFormPageState extends State<AtelierFormPage>
    with UploadSessionCleanup<AtelierFormPage> {
  // Dossier R2 autorisé (R2StorageService.allowedFolders) — ne pas modifier
  // sans mettre à jour la liste blanche du service ET de `r2-presign`.
  static const String _folder = 'atelier';

  final _formKey = GlobalKey<FormState>();
  final _atelierService = AtelierService();

  late final String _currentId;
  late final TextEditingController _titleFrController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _descFrController;
  late final TextEditingController _descEnController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _imagePathController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final photo = widget.existing;
    _currentId = photo?.id ?? DateTime.now().millisecondsSinceEpoch.toString();
    _titleFrController = TextEditingController(text: photo?.titleFr ?? '');
    _titleEnController = TextEditingController(text: photo?.titleEn ?? '');
    _descFrController = TextEditingController(text: photo?.descriptionFr ?? '');
    _descEnController = TextEditingController(text: photo?.descriptionEn ?? '');
    // L'URL enregistrée en base est conservée telle quelle ; `displayImage`
    // ne sert qu'à convertir une clé relative (photos du script de contenu
    // initial) : l'aperçu s'affiche et l'enregistrement migre vers `image_url`.
    final display = (photo != null && photo.imageUrl.startsWith('http'))
        ? photo.imageUrl
        : (photo?.displayImage ?? '');
    final hasHttpImage = display.startsWith('http');
    _imageUrlController =
        TextEditingController(text: hasHttpImage ? display : '');
    _imagePathController = TextEditingController(
      text: hasHttpImage ? '' : (photo?.imagePath ?? ''),
    );
  }

  @override
  void dispose() {
    _titleFrController.dispose();
    _titleEnController.dispose();
    _descFrController.dispose();
    _descEnController.dispose();
    _imageUrlController.dispose();
    _imagePathController.dispose();
    super.dispose();
  }

  AtelierPhoto _photoFromFields({int? orderOverride}) => AtelierPhoto(
        id: _currentId,
        titleFr: _titleFrController.text.trim(),
        titleEn: _titleEnController.text.trim(),
        descriptionFr: _descFrController.text.trim(),
        descriptionEn: _descEnController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        imagePath: _imagePathController.text.trim(),
        order: orderOverride ?? widget.existing?.order ?? 99,
        isPublished: widget.existing?.isPublished ?? true,
      );

  void _snack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: const TextStyle(fontSize: AdminDesign.fsBody)),
        backgroundColor: isError ? AdminColors.danger : AdminColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AdminDesign.sp16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AdminDesign.rSm),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    if (_imageUrlController.text.trim().isEmpty &&
        _imagePathController.text.trim().isEmpty) {
      _snack('L\'image est requise.', isError: true);
      return;
    }

    setState(() => _isSaving = true);
    final wasEditing = widget.existing != null;

    try {
      int? orderOverride;
      if (!wasEditing) orderOverride = await _atelierService.getNextSortOrder();

      var photo = _photoFromFields(orderOverride: orderOverride);

      if (!wasEditing) {
        final createdId = await _atelierService.addPhoto(photo);
        photo = photo.copyWith(id: createdId);
      } else {
        // L'ancien fichier R2 est supprimé par le service si l'image a changé.
        await _atelierService.updatePhoto(widget.existing!.id, photo);
      }

      // L'enregistrement en base est fait : un échec du rappel ne doit pas
      // faire croire à un échec (un nouvel appui créerait un doublon).
      final onSave = widget.onSave;
      if (onSave != null) {
        try {
          await onSave(photo);
        } catch (e) {
          debugPrint('AtelierFormPage: rappel onSave en échec — $e');
        }
      }
      await commitUploads(keep: [photo.imageUrl, photo.imagePath]);
      if (mounted) Navigator.pop(context, photo);
    } catch (e) {
      _snack('Échec de l\'enregistrement : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        foregroundColor: AdminColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isEditing ? 'Modifier la photo' : 'Ajouter une photo',
          style: const TextStyle(
            fontSize: AdminDesign.fsAppBar,
            fontWeight: FontWeight.w600,
            color: AdminColors.text,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(
          horizontal: AdminDesign.pagePadH,
          vertical: AdminDesign.pagePadV,
        ),
        child: Center(
          child: ConstrainedBox(
            constraints:
                const BoxConstraints(maxWidth: AdminDesign.formMaxWidth),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AdminCard(
                    title: 'Photo *',
                    icon: Icons.image_outlined,
                    child: AdminImageUploadField(
                      folder: _folder,
                      currentUrl: _imageUrlController.text,
                      compact: true,
                      label: 'Photo d\'atelier',
                      helperText:
                          'JPG, PNG ou WEBP — 5 Mo maximum.\nPortrait ou carré recommandé.',
                      onUploaded: (url) {
                        trackUpload(url);
                        setState(() {
                          _imageUrlController.text = url;
                          _imagePathController.clear();
                        });
                      },
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp12),
                  AdminCard(
                    title: 'Informations',
                    icon: Icons.edit_note_outlined,
                    child: LocalizedFieldGroup(
                      titleFrController: _titleFrController,
                      titleEnController: _titleEnController,
                      descriptionFrController: _descFrController,
                      descriptionEnController: _descEnController,
                      descriptionMaxLines: 2,
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp20),
                  AdminPrimaryButton(
                    onPressed: _submitForm,
                    loading: _isSaving,
                    icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
                    label: isEditing ? 'Mettre à jour' : 'Enregistrer',
                  ),
                  const SizedBox(height: AdminDesign.sp16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}