import 'package:flutter/material.dart';

import '../gallery/models/artwork.dart';
import '../gallery/services/gallery_service.dart';
import '../../theme/admin_colors.dart';
import '../../theme/admin_design.dart';
import 'admin_forms.dart';
import 'upload_session_cleanup.dart';

class GalleryFormPage extends StatefulWidget {
  final Artwork? existing;
  const GalleryFormPage({super.key, this.existing});

  @override
  State<GalleryFormPage> createState() => _GalleryFormPageState();
}

class _GalleryFormPageState extends State<GalleryFormPage>
    with UploadSessionCleanup<GalleryFormPage> {
  // Dossier R2 de la galerie (`azizart-media/gallery/`).
  static const String _folder = 'gallery';

  final _formKey = GlobalKey<FormState>();
  final _galleryService = GalleryService();

  late final TextEditingController _titleFrController;
  late final TextEditingController _titleEnController;
  late final TextEditingController _descFrController;
  late final TextEditingController _descEnController;
  late final TextEditingController _imageUrlController;
  late final TextEditingController _categoryController;
  late final TextEditingController _techniqueController;
  late final TextEditingController _dimensionsController;
  late final TextEditingController _yearController;
  late final TextEditingController _priceController;

  /// Ancien `image_path` (ex. 'assets/…') conservé tant qu'aucune image
  /// réseau n'est définie : évite de l'effacer lors d'une simple édition.
  String _originalImagePath = '';

  bool _featured = false;
  String _status = 'available';
  bool _isSaving = false;
  late bool _isPublished;

  @override
  void initState() {
    super.initState();
    final a = widget.existing;
    _titleFrController = TextEditingController(text: a?.titleFr ?? '');
    _titleEnController = TextEditingController(text: a?.titleEn ?? '');
    _descFrController = TextEditingController(text: a?.descriptionFr ?? '');
    _descEnController = TextEditingController(text: a?.descriptionEn ?? '');
    // L'URL enregistrée en base est conservée telle quelle ; `displayImage`
    // ne sert qu'à convertir une clé relative (ancien `image_path`) en URL R2.
    final display = (a != null && a.imageUrl.startsWith('http'))
        ? a.imageUrl
        : (a?.displayImage ?? '');
    final hasHttpImage = display.startsWith('http');
    _imageUrlController =
        TextEditingController(text: hasHttpImage ? display : '');
    _originalImagePath = (a != null && !hasHttpImage) ? a.imagePath : '';
    _categoryController = TextEditingController(text: a?.category ?? '');
    _techniqueController = TextEditingController(text: a?.technique ?? '');
    _dimensionsController = TextEditingController(text: a?.dimensions ?? '');
    _yearController = TextEditingController(text: a?.year ?? '');
    _priceController = TextEditingController(text: _formatPrice(a?.price));
    _featured = a?.featured ?? false;
    _status = a?.status ?? 'available';
    _isPublished = a?.isPublished ?? false;
  }

  @override
  void dispose() {
    _titleFrController.dispose();
    _titleEnController.dispose();
    _descFrController.dispose();
    _descEnController.dispose();
    _imageUrlController.dispose();
    _categoryController.dispose();
    _techniqueController.dispose();
    _dimensionsController.dispose();
    _yearController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Artwork _buildArtworkFromFields() => Artwork(
        id: widget.existing?.id ?? '',
        titleFr: _titleFrController.text.trim(),
        titleEn: _titleEnController.text.trim(),
        descriptionFr: _descFrController.text.trim(),
        descriptionEn: _descEnController.text.trim(),
        imageUrl: _imageUrlController.text.trim(),
        imagePath:
            _imageUrlController.text.trim().isEmpty ? _originalImagePath : '',
        category: _categoryController.text.trim(),
        technique: _techniqueController.text.trim(),
        dimensions: _dimensionsController.text.trim(),
        year: _yearController.text.trim(),
        price: _parsePrice(_priceController.text),
        featured: _featured,
        status: _status,
        isPublished: _isPublished,
      );

  /// Accepte « 120 », « 120.50 » et « 120,50 » (saisie française).
  static double? _parsePrice(String raw) {
    final t = raw.trim().replaceAll(',', '.');
    return t.isEmpty ? null : double.tryParse(t);
  }

  static String _formatPrice(double? price) {
    if (price == null) return '';
    return price == price.roundToDouble()
        ? price.toStringAsFixed(0)
        : price.toString();
  }

  String? _validatePrice(String? value) {
    final t = (value ?? '').trim();
    if (t.isEmpty) return null;
    final n = _parsePrice(t);
    return (n == null || n < 0) ? 'Prix invalide (ex. 120 ou 120,50)' : null;
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
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_imageUrlController.text.trim().isEmpty && _originalImagePath.isEmpty) {
      _snack('L\'image est requise.', isError: true);
      return;
    }
    setState(() => _isSaving = true);
    try {
      final artwork = _buildArtworkFromFields();
      if (widget.existing == null) {
        await _galleryService.addArtwork(artwork);
      } else {
        await _galleryService.updateArtwork(artwork.id, artwork);
      }
      await commitUploads(keep: [artwork.imageUrl, artwork.imagePath]);
      if (mounted) Navigator.pop(context, artwork);
    } catch (e) {
      _snack('Échec : $e', isError: true);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _row(Widget a, Widget b, bool isMobile) {
    if (isMobile) return Column(children: [a, b]);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: a),
        const SizedBox(width: AdminDesign.sp12),
        Expanded(child: b),
      ],
    );
  }

  Widget _statusChip(String label, String value, Color color) {
    final selected = _status == value;
    return ChoiceChip(
      label: Text(label,
          style: const TextStyle(fontSize: AdminDesign.fsLabel)),
      selected: selected,
      onSelected: (val) {
        if (val) setState(() => _status = value);
      },
      showCheckmark: false,
      selectedColor: color,
      backgroundColor: AdminColors.bg,
      side: BorderSide(color: selected ? color : AdminColors.border),
      labelStyle: TextStyle(
        color: selected ? Colors.white : AdminColors.textMuted,
        fontWeight: FontWeight.w500,
        fontSize: AdminDesign.fsLabel,
      ),
      visualDensity: VisualDensity.compact,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.existing != null;
    final isMobile = MediaQuery.sizeOf(context).width < 600;

    return Scaffold(
      backgroundColor: AdminColors.bg,
      appBar: AppBar(
        backgroundColor: AdminColors.bg,
        foregroundColor: AdminColors.text,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text(
          isEditing ? 'Modifier l\'œuvre' : 'Nouvelle œuvre',
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
                  if (!isEditing) ...[
                    const AdminInfoBanner(
                      message:
                          'L\'œuvre sera enregistrée en brouillon. Publiez-la depuis la liste.',
                    ),
                    const SizedBox(height: AdminDesign.sp12),
                  ],
                  AdminCard(
                    title: 'Visuel',
                    icon: Icons.image_outlined,
                    child: AdminImageUploadField(
                      folder: _folder,
                      currentUrl: _imageUrlController.text,
                      compact: true,
                      label: 'Image principale',
                      helperText:
                          'JPG, PNG ou WEBP — 5 Mo maximum.\nFormat recommandé : portrait 3:4.',
                      onUploaded: (url) {
                        trackUpload(url);
                        setState(() => _imageUrlController.text = url);
                      },
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp12),
                  AdminCard(
                    title: 'Informations générales',
                    icon: Icons.edit_note_outlined,
                    child: LocalizedFieldGroup(
                      titleFrController: _titleFrController,
                      titleEnController: _titleEnController,
                      descriptionFrController: _descFrController,
                      descriptionEnController: _descEnController,
                      descriptionMaxLines: 3,
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp12),
                  AdminCard(
                    title: 'Détails techniques',
                    icon: Icons.brush_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _row(
                          adminTextField(_categoryController, 'Catégorie',
                              hintText: 'Peinture'),
                          adminTextField(_techniqueController, 'Technique',
                              hintText: 'Huile sur toile'),
                          isMobile,
                        ),
                        _row(
                          adminTextField(_dimensionsController, 'Dimensions',
                              hintText: '100x80 cm'),
                          adminTextField(_yearController, 'Année',
                              hintText: '2024',
                              keyboardType: TextInputType.number),
                          isMobile,
                        ),
                        adminTextField(_priceController, 'Prix (€)',
                            keyboardType:
                                const TextInputType.numberWithOptions(
                                    decimal: true),
                            validator: _validatePrice),
                      ],
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp12),
                  AdminCard(
                    title: 'Mise en avant & disponibilité',
                    icon: Icons.star_border_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          value: _featured,
                          onChanged: (v) => setState(() => _featured = v),
                          activeTrackColor: AdminColors.accent,
                          title: const Text('Œuvre vedette',
                              style: TextStyle(
                                color: AdminColors.text,
                                fontSize: AdminDesign.fsBody,
                                fontWeight: FontWeight.w500,
                              )),
                          subtitle: const Text('Afficher dans le carrousel',
                              style: TextStyle(
                                color: AdminColors.textMuted,
                                fontSize: AdminDesign.fsLabel,
                              )),
                        ),
                        const SizedBox(height: AdminDesign.sp8),
                        const Text('Statut de vente',
                            style: TextStyle(
                              color: AdminColors.textMuted,
                              fontSize: AdminDesign.fsLabel,
                              fontWeight: FontWeight.w500,
                            )),
                        const SizedBox(height: AdminDesign.sp8),
                        Wrap(
                          spacing: AdminDesign.sp8,
                          runSpacing: AdminDesign.sp8,
                          children: [
                            _statusChip('Disponible', 'available',
                                AdminColors.success),
                            _statusChip('Vendue', 'sold', AdminColors.danger),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AdminDesign.sp20),
                  AdminPrimaryButton(
                    onPressed: _submitForm,
                    loading: _isSaving,
                    icon: isEditing ? Icons.check_rounded : Icons.add_rounded,
                    label: isEditing
                        ? 'Mettre à jour'
                        : 'Enregistrer en brouillon',
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