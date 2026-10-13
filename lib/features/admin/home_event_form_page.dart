import 'dart:async';

import 'package:flutter/material.dart';

import '../home/models/home_event_model.dart';
import '../home/services/home_event_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_design.dart';
import 'admin_forms.dart';
import 'upload_session_cleanup.dart';

class HomeEventFormPage extends StatefulWidget {
  final HomeEvent? existing;
  final FutureOr<void> Function(HomeEvent event)? onSave;

  const HomeEventFormPage({super.key, this.existing, this.onSave});

  @override
  State<HomeEventFormPage> createState() => _HomeEventFormPageState();
}

class _HomeEventFormPageState extends State<HomeEventFormPage>
    with UploadSessionCleanup<HomeEventFormPage> {
  // Dossier R2 autorisé (R2StorageService.allowedFolders).
  static const String _folder = 'home_events';

  final _formKey = GlobalKey<FormState>();
  final _homeEventService = HomeEventService();

  late final TextEditingController _titleFrController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _descFrController;
  late final TextEditingController _descEnController;
  late final TextEditingController _externalUrlController;

  String _imageUrl = '';
  HomeEventType _type = HomeEventType.news;
  DateTime? _eventDate;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _titleFrController = TextEditingController(text: e?.titleFr ?? '');
    _titleEnController = TextEditingController(text: e?.titleEn ?? '');
    _descFrController = TextEditingController(text: e?.descriptionFr ?? '');
    _descEnController = TextEditingController(text: e?.descriptionEn ?? '');
    _externalUrlController = TextEditingController(text: e?.externalUrl ?? '');
    _imageUrl = e?.imageUrl ?? '';
    _type = e?.type ?? HomeEventType.news;
    final d = e?.eventDate?.toLocal();
    _eventDate = d == null ? null : DateTime(d.year, d.month, d.day);
  }

  @override
  void dispose() {
    _titleFrController.dispose();
    _titleEnController.dispose();
    _descFrController.dispose();
    _descEnController.dispose();
    _externalUrlController.dispose();
    super.dispose();
  }

  HomeEvent _eventFromFields({String? id}) {
    final e = widget.existing;
    return HomeEvent(
      id: id ?? e?.id ?? '',
      titleFr: _titleFrController.text.trim(),
      titleEn: _titleEnController.text.trim(),
      descriptionFr: _descFrController.text.trim(),
      descriptionEn: _descEnController.text.trim(),
      imageUrl: _imageUrl.trim(),
      type: _type,
      eventDate: _eventDate,
      createdAt: e?.createdAt,
      isPublished: e?.isPublished ?? true,
      source: e?.source ?? '',
      externalUrl: _externalUrlController.text.trim(),
    );
  }

  String? _validateExternalUrl(String? value) {
    final t = (value ?? '').trim();
    if (t.isEmpty) return null;
    final uri = Uri.tryParse(t);
    final ok = uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    return ok ? null : 'URL invalide (ex. https://…)';
  }

  String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final first = DateTime(2000);
    final last = DateTime(2100);
    var initial = _eventDate ?? DateTime(now.year, now.month, now.day);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: AdminColors.accent,
            onPrimary: AdminColors.textOnAccent,
            surface: AdminColors.surfaceElevated,
            onSurface: AdminColors.text,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null && mounted) setState(() => _eventDate = picked);
  }

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
    if (_imageUrl.trim().isEmpty) {
      _snack('L\'image est requise.', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    final e = widget.existing;
    final oldImageUrl = e?.imageUrl ?? '';

    try {
      var event = _eventFromFields();
      if (e == null) {
        final createdId = await _homeEventService.addEvent(event);
        event = _eventFromFields(id: createdId);
      } else {
        await _homeEventService.updateEvent(event);
        if (oldImageUrl.isNotEmpty && oldImageUrl != event.imageUrl) {
          await _homeEventService.purgeOrphanImage(imageUrl: oldImageUrl);
        }
      }
      // L'enregistrement en base est fait : un échec du rappel ne doit pas
      // faire croire à un échec (un nouvel appui créerait un doublon).
      final onSave = widget.onSave;
      if (onSave != null) {
        try {
          await onSave(event);
        } catch (err) {
          debugPrint('HomeEventFormPage: rappel onSave en échec — $err');
        }
      }
      await commitUploads(keep: [event.imageUrl]);
      if (mounted) Navigator.pop(context, event);
    } catch (err) {
      _snack('Échec : $err', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildDateField() {
    final date = _eventDate;
    return InkWell(
      onTap: _pickDate,
      borderRadius: BorderRadius.circular(AdminDesign.rSm),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Date (facultatif)',
          labelStyle: const TextStyle(
            color: AdminColors.textMuted,
            fontSize: AdminDesign.fsLabel,
          ),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AdminDesign.sp12,
            vertical: AdminDesign.sp12,
          ),
          filled: true,
          fillColor: AdminColors.bg.withValues(alpha: 0.4),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AdminDesign.rSm),
            borderSide: const BorderSide(color: AdminColors.border),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.event_outlined,
                size: 18, color: AdminColors.textMuted),
            const SizedBox(width: AdminDesign.sp8),
            Expanded(
              child: Text(
                date == null ? 'Aucune date' : _formatDate(date),
                style: TextStyle(
                  color:
                      date == null ? AdminColors.textMuted : AdminColors.text,
                  fontSize: AdminDesign.fsBody,
                ),
              ),
            ),
            if (date != null)
              GestureDetector(
                onTap: () => setState(() => _eventDate = null),
                child: const Icon(Icons.close_rounded,
                    size: 16, color: AdminColors.textMuted),
              ),
          ],
        ),
      ),
    );
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
          isEditing ? 'Modifier l\'événement' : 'Ajouter un événement',
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
                  // ═══════════════════════════════════════════════════════
                  // CARTE « VISUEL » — mode compact
                  // ═══════════════════════════════════════════════════════
                  // L'ancien `aspectRatio: 16/9` produisait un rectangle de
                  // ~560×315 px sur desktop et monopolisait le premier écran
                  // sur mobile. Le mode compact (défaut) affiche une preview
                  // 96×96 + texte + boutons, sans paramètre de ratio.
                  //
                  // Pour revenir au grand format :
                  //   compact: false,
                  //   aspectRatio: 16 / 9,
                  //   maxPreviewHeight: 300,
                  // ═══════════════════════════════════════════════════════
                  AdminCard(
                    title: 'Visuel *',
                    icon: Icons.image_outlined,
                    child: AdminImageUploadField(
                      folder: _folder,
                      currentUrl: _imageUrl,
                      compact: true,
                      label: 'Image de l\'événement',
                      helperText:
                          'JPG, PNG ou WEBP — 5 Mo maximum.\nPaysage 16:9 recommandé.',
                      onUploaded: (url) {
                        trackUpload(url);
                        setState(() => _imageUrl = url);
                      },
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp12),
                  AdminCard(
                    title: 'Textes',
                    icon: Icons.edit_note_outlined,
                    child: LocalizedFieldGroup(
                      titleFrController: _titleFrController,
                      titleEnController: _titleEnController,
                      descriptionFrController: _descFrController,
                      descriptionEnController: _descEnController,
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp12),
                  AdminCard(
                    title: 'Type, date & lien',
                    icon: Icons.tune_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: AdminDesign.sp8,
                          runSpacing: AdminDesign.sp8,
                          children: [
                            for (final type in HomeEventType.values)
                              ChoiceChip(
                                avatar: Icon(type.icon,
                                    size: 14, color: type.color),
                                label: Text(type.getLabel(context),
                                    style: const TextStyle(
                                        fontSize: AdminDesign.fsLabel)),
                                selected: _type == type,
                                showCheckmark: false,
                                backgroundColor: AdminColors.bg,
                                selectedColor:
                                    type.color.withValues(alpha: 0.22),
                                side: BorderSide(
                                  color: _type == type
                                      ? type.color
                                      : AdminColors.border,
                                ),
                                labelStyle: TextStyle(
                                  color: _type == type
                                      ? AdminColors.text
                                      : AdminColors.textMuted,
                                  fontSize: AdminDesign.fsLabel,
                                  fontWeight: FontWeight.w600,
                                ),
                                visualDensity: VisualDensity.compact,
                                onSelected: (_) =>
                                    setState(() => _type = type),
                              ),
                          ],
                        ),
                        const SizedBox(height: AdminDesign.sp12),
                        _buildDateField(),
                        const SizedBox(height: AdminDesign.sp12),
                        adminTextField(
                          _externalUrlController,
                          'Lien externe (facultatif)',
                          hintText: 'https://…',
                          keyboardType: TextInputType.url,
                          validator: _validateExternalUrl,
                        ),
                      ],
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