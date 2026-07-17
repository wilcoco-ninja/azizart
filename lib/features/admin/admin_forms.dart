import 'dart:typed_data';

import 'package:flutter/material.dart';

// Imports absolus via package pour résoudre les erreurs "Target of URI doesn't exist"
import 'package:azizart/features/gallery/models/artwork.dart';
import 'package:azizart/features/gallery/services/gallery_service.dart';
import 'package:azizart/features/atelier/models/atelier_model.dart';
import 'package:azizart/features/atelier/services/atelier_service.dart';
import 'package:azizart/features/media/models/media_model.dart';
import 'package:azizart/features/media/services/media_service.dart';
import 'package:azizart/features/home/services/home_event_service.dart';
import '../../../core/service/image_upload_service.dart';
import '../../../theme/aziz_colors.dart';

// ══════════════════════════════════════════════════════════════════════════════
// GalleryFormPage
// ══════════════════════════════════════════════════════════════════════════════
class GalleryFormPage extends StatefulWidget {
  const GalleryFormPage({super.key});
  @override
  State<GalleryFormPage> createState() => _GalleryFormPageState();
}

class _GalleryFormPageState extends State<GalleryFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _titleC = TextEditingController();
  final _descFrC = TextEditingController();
  final _descEnC = TextEditingController();
  final _techC = TextEditingController(text: 'Batik sur toile');
  final _dimsC = TextEditingController();
  final _yearC = TextEditingController();
  final _priceC = TextEditingController();

  String _cat = 'Tableau';
  bool _available = true;
  bool _featured = false;
  bool _saving = false;
  String? _err;
  Uint8List? _bytes;

  final _up = ImageUploadService();
  final _svc = GalleryService();

  static const _cats = [
    'Tableau',
    'Vêtements',
    'Tissu Pagne',
    'Nappe de Table',
    'Sculpture',
    'Objet'
  ];

  @override
  void dispose() {
    // Correction de l'avertissement avoid_function_literals_in_foreach_calls
    for (final c in [
      _titleC,
      _descFrC,
      _descEnC,
      _techC,
      _dimsC,
      _yearC,
      _priceC
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final b = await _up.pickImage();
    if (b != null) setState(() => _bytes = b);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bytes == null) {
      setState(() => _err = 'Sélectionner une image');
      return;
    }
    setState(() => _saving = true);
    try {
      final url = await _up.upload(_bytes!, folder: 'gallery');
      if (url == null) throw Exception('Échec upload');
      await _svc.addArtwork(Artwork(
          id: '',
          titleFr: _titleC.text.trim(),
          descriptionFr: _descFrC.text.trim(),
          descriptionEn: _descEnC.text.trim(),
          imagePath: '',
          imageUrl: url,
          category: _cat,
          technique: _techC.text.trim(),
          dimensions: _dimsC.text.trim(),
          year: _yearC.text.trim(),
          price: double.tryParse(_priceC.text.trim()),
          isAvailable: _available,
          featured: _featured));
      if (!mounted) return;
      _snack(context, 'Oeuvre ajoutée ✓', AzizColors.greenBatik);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => _Shell(
      title: 'Ajouter à la Galerie',
      accent: AzizColors.saffron,
      child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Img(bytes: _bytes, onTap: _pick),
            _g,
            _f(_titleC, 'Titre *', req: true),
            _g,
            _lbl('Catégorie *'),
            const SizedBox(height: 8),
            _dd(_cats, _cat, (v) => setState(() => _cat = v!)),
            _g,
            _f(_techC, 'Technique'),
            _g,
            _f(_dimsC, 'Dimensions (ex: 60 × 80 cm)'),
            _g,
            _f(_yearC, 'Année', kb: TextInputType.number),
            _g,
            _f(_priceC, 'Prix (€) — vide = Sur demande',
                kb: TextInputType.number),
            _g,
            _f(_descFrC, 'Description (FR)', ml: 4),
            _g,
            _f(_descEnC, 'Description (EN)', ml: 4),
            _g,
            _tog('Disponible à la vente', _available,
                (v) => setState(() => _available = v), AzizColors.greenBatik),
            _tog('Mettre en vedette (accueil)', _featured,
                (v) => setState(() => _featured = v), AzizColors.saffron),
            const SizedBox(height: 24),
            if (_err != null) ...[_Err(_err!), _g],
            _Btn(saving: _saving, onTap: _save),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
// AtelierFormPage
// ══════════════════════════════════════════════════════════════════════════════
class AtelierFormPage extends StatefulWidget {
  const AtelierFormPage({super.key});
  @override
  State<AtelierFormPage> createState() => _AtelierFormPageState();
}

class _AtelierFormPageState extends State<AtelierFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tfr = TextEditingController(),
      _ten = TextEditingController(),
      _dfr = TextEditingController(),
      _den = TextEditingController(),
      _ord = TextEditingController(text: '99');

  bool _saving = false;
  String? _err;
  Uint8List? _bytes;
  final _up = ImageUploadService(), _svc = AtelierService();

  @override
  void dispose() {
    for (final c in [_tfr, _ten, _dfr, _den, _ord]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final b = await _up.pickImage();
    if (b != null) setState(() => _bytes = b);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_bytes == null) {
      setState(() => _err = 'Sélectionner une image');
      return;
    }
    setState(() => _saving = true);
    try {
      final url = await _up.upload(_bytes!, folder: 'atelier');
      if (url == null) throw Exception('Échec upload');
      await _svc.addPhoto(AtelierPhoto(
          id: '',
          imagePath: '',
          imageUrl: url,
          titleFr: _tfr.text.trim(),
          titleEn: _ten.text.trim(),
          descriptionFr: _dfr.text.trim(),
          descriptionEn: _den.text.trim(),
          order: int.tryParse(_ord.text.trim()) ?? 99));
      if (!mounted) return;
      _snack(context, 'Photo atelier ajoutée ✓', AzizColors.terraCotta);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => _Shell(
      title: "Ajouter à l'Atelier",
      accent: AzizColors.terraCotta,
      child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Img(bytes: _bytes, onTap: _pick),
            _g,
            _f(_tfr, 'Titre (FR) *', req: true),
            _g,
            _f(_ten, 'Titre (EN)'),
            _g,
            _f(_dfr, 'Description (FR)', ml: 3),
            _g,
            _f(_den, 'Description (EN)', ml: 3),
            _g,
            _f(_ord, "Ordre d'affichage", kb: TextInputType.number),
            const SizedBox(height: 24),
            if (_err != null) ...[_Err(_err!), _g],
            _Btn(saving: _saving, onTap: _save),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
// MediaFormPage
// ══════════════════════════════════════════════════════════════════════════════
class MediaFormPage extends StatefulWidget {
  const MediaFormPage({super.key});
  @override
  State<MediaFormPage> createState() => _MediaFormPageState();
}

class _MediaFormPageState extends State<MediaFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tfr = TextEditingController(),
      _ten = TextEditingController(),
      _src = TextEditingController(),
      _url = TextEditingController(),
      _yr = TextEditingController();

  String _type = 'video';
  bool _saving = false;
  String? _err;
  Uint8List? _thumb;
  final _up = ImageUploadService(), _svc = MediaService();
  static const _types = ['video', 'reportage', 'news'];

  @override
  void dispose() {
    for (final c in [_tfr, _ten, _src, _url, _yr]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final b = await _up.pickImage();
    if (b != null) setState(() => _thumb = b);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String thumbUrl = '';
      if (_thumb != null) {
        thumbUrl = await _up.upload(_thumb!, folder: 'media') ?? '';
      }
      final mt = MediaType.values
          .firstWhere((t) => t.name == _type, orElse: () => MediaType.video);
      await _svc.addMedia(MediaItem(
          id: '',
          titleFr: _tfr.text.trim(),
          titleEn: _ten.text.trim(),
          type: mt,
          source: _src.text.trim(),
          url: _url.text.trim(),
          thumbnailUrl: thumbUrl,
          thumbnailPath: '',
          year: _yr.text.trim()));
      if (!mounted) return;
      _snack(context, 'Média ajouté ✓', AzizColors.greenBatik);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => _Shell(
      title: 'Ajouter aux Médias',
      accent: AzizColors.greenBatik,
      child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Img(bytes: _thumb, onTap: _pick, label: 'Vignette (optionnel)'),
            _g,
            _lbl('Type *'),
            const SizedBox(height: 8),
            _dd(
                _types.map((t) => t.toUpperCase()).toList(),
                _type.toUpperCase(),
                (v) => setState(() => _type = v!.toLowerCase()),
                raw: _types),
            _g,
            _f(_tfr, 'Titre (FR) *', req: true),
            _g,
            _f(_ten, 'Titre (EN)'),
            _g,
            _f(_src, 'Source (ex: RFI, TV5 Monde…)'),
            _g,
            _f(_url, 'URL (YouTube, article…)', kb: TextInputType.url),
            _g,
            _f(_yr, 'Année', kb: TextInputType.number),
            const SizedBox(height: 24),
            if (_err != null) ...[_Err(_err!), _g],
            _Btn(saving: _saving, onTap: _save),
          ])));
}

// ══════════════════════════════════════════════════════════════════════════════
// HomeEventFormPage
// ══════════════════════════════════════════════════════════════════════════════
class HomeEventFormPage extends StatefulWidget {
  const HomeEventFormPage({super.key});
  @override
  State<HomeEventFormPage> createState() => _HomeEventFormPageState();
}

class _HomeEventFormPageState extends State<HomeEventFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _tfr = TextEditingController(),
      _ten = TextEditingController(),
      _dfr = TextEditingController(),
      _den = TextEditingController();

  String _type = 'news';
  bool _pub = true, _saving = false;
  String? _err;
  Uint8List? _bytes;
  DateTime? _date;
  final _up = ImageUploadService(), _svc = HomeEventService();
  static const _types = ['news', 'event', 'exhibition'];

  @override
  void dispose() {
    for (final c in [_tfr, _ten, _dfr, _den]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pick() async {
    final b = await _up.pickImage();
    if (b != null) setState(() => _bytes = b);
  }

  Future<void> _pickDate() async {
    final d = await showDatePicker(
        context: context,
        initialDate: DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 730)));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      String imgUrl = '';
      if (_bytes != null) {
        imgUrl = await _up.upload(_bytes!, folder: 'home_events') ?? '';
      }
      await _svc.addEvent(HomeEvent(
          id: '',
          titleFr: _tfr.text.trim(),
          titleEn: _ten.text.trim(),
          descriptionFr: _dfr.text.trim(),
          descriptionEn: _den.text.trim(),
          imageUrl: imgUrl,
          type: _type,
          eventDate: _date,
          isPublished: _pub));
      if (!mounted) return;
      _snack(context, 'Publication ajoutée ✓', AzizColors.saffron);
      Navigator.pop(context);
    } catch (e) {
      setState(() => _err = 'Erreur: $e');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext ctx) => _Shell(
      title: "Publier sur l'Accueil",
      accent: AzizColors.saffronLight,
      child: Form(
          key: _formKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _Img(bytes: _bytes, onTap: _pick, label: 'Image (optionnel)'),
            _g,
            _lbl('Type *'),
            const SizedBox(height: 8),
            _dd(
                _types.map((t) => t.toUpperCase()).toList(),
                _type.toUpperCase(),
                (v) => setState(() => _type = v!.toLowerCase()),
                raw: _types),
            _g,
            _f(_tfr, 'Titre (FR) *', req: true),
            _g,
            _f(_ten, 'Titre (EN)'),
            _g,
            _f(_dfr, 'Description (FR) *', ml: 4, req: true),
            _g,
            _f(_den, 'Description (EN)', ml: 4),
            if (_type == 'event' || _type == 'exhibition') ...[
              _g,
              _lbl("Date de l'événement"),
              const SizedBox(height: 8),
              InkWell(
                  onTap: _pickDate,
                  child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                          border: Border.all(color: AzizColors.cardBorder),
                          borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.calendar_today,
                            color: AzizColors.textSecondary, size: 18),
                        const SizedBox(width: 12),
                        Text(
                            _date != null
                                ? '${_date!.day}/${_date!.month}/${_date!.year}'
                                : 'Sélectionner une date',
                            style: TextStyle(
                                color: _date != null
                                    ? AzizColors.textPrimary
                                    : AzizColors.textSecondary)),
                      ])))
            ],
            _g,
            _tog('Publier immédiatement', _pub, (v) => setState(() => _pub = v),
                AzizColors.saffron),
            const SizedBox(height: 24),
            if (_err != null) ...[_Err(_err!), _g],
            _Btn(saving: _saving, onTap: _save),
          ])));
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared private helpers
// ═════════════════════════════════════════════════════════════════════════════

const _g = SizedBox(height: 16);

Widget _lbl(String t) => Text(t,
    style: const TextStyle(
        color: AzizColors.textSecondary, fontSize: 11, letterSpacing: 1.2));

// Renommé de _F en _f pour respecter la convention de nommage lowerCamelCase
Widget _f(TextEditingController c, String hint,
        {int ml = 1, TextInputType? kb, bool req = false}) =>
    TextFormField(
        controller: c,
        maxLines: ml,
        keyboardType: kb,
        style: const TextStyle(color: AzizColors.textPrimary),
        validator: req
            ? (v) =>
                (v == null || v.trim().isEmpty) ? 'Champ obligatoire' : null
            : null,
        decoration: _dec(hint));

Widget _dd(List<String> labels, String val, ValueChanged<String?> fn,
        {List<String>? raw}) =>
    DropdownButtonFormField<String>(
        // Correction de l'erreur sur 'value' déprécié -> Remplacé par initialValue
        initialValue: val,
        dropdownColor: AzizColors.surface,
        style: const TextStyle(color: AzizColors.textPrimary),
        decoration: _dec(''),
        items: List.generate(
            labels.length,
            (i) => DropdownMenuItem(
                value: (raw ?? labels)[i], child: Text(labels[i]))),
        onChanged: fn);

Widget _tog(String label, bool val, ValueChanged<bool> fn, Color col) =>
    Row(children: [
      // Correction de 'activeColor' déprécié -> Remplacé par activeThumbColor
      Switch(value: val, onChanged: fn, activeThumbColor: col),
      const SizedBox(width: 12),
      Text(label,
          style: const TextStyle(color: AzizColors.textPrimary, fontSize: 14))
    ]);

InputDecoration _dec(String h) => InputDecoration(
    hintText: h,
    hintStyle: const TextStyle(color: AzizColors.textSecondary),
    filled: true,
    fillColor: AzizColors.surface,
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AzizColors.cardBorder, width: .5)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AzizColors.cardBorder, width: .5)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AzizColors.saffron, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AzizColors.error, width: 1)));

void _snack(BuildContext ctx, String msg, Color color) =>
    ScaffoldMessenger.of(ctx)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));

class _Shell extends StatelessWidget {
  final String title;
  final Color accent;
  final Widget child;
  const _Shell(
      {required this.title, required this.accent, required this.child});
  @override
  Widget build(BuildContext ctx) => Scaffold(
      backgroundColor: AzizColors.backgroundDark,
      appBar: AppBar(
          backgroundColor: AzizColors.backgroundMedium,
          elevation: 0,
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AzizColors.textPrimary),
              onPressed: () => Navigator.pop(ctx)),
          title: Text(title,
              style: TextStyle(
                  fontFamily: 'Playfair Display',
                  color: accent,
                  fontSize: 18,
                  letterSpacing: 2))),
      body: SafeArea(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(children: [child, const SizedBox(height: 40)]))));
}

class _Img extends StatelessWidget {
  final Uint8List? bytes;
  final VoidCallback onTap;
  final String label;
  const _Img(
      {required this.bytes, required this.onTap, this.label = 'Image *'});
  @override
  Widget build(BuildContext ctx) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _lbl(label),
        const SizedBox(height: 10),
        GestureDetector(
            onTap: onTap,
            child: Container(
                height: 180,
                decoration: BoxDecoration(
                    color: AzizColors.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: bytes != null
                            ? AzizColors.saffron
                            : AzizColors.cardBorder,
                        width: bytes != null ? 2 : .5)),
                child: bytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(11),
                        child: Image.memory(bytes!,
                            fit: BoxFit.cover, width: double.infinity))
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                color: AzizColors.textSecondary, size: 36),
                            SizedBox(height: 10),
                            Text('Appuyer pour choisir une image',
                                style: TextStyle(
                                    color: AzizColors.textSecondary,
                                    fontSize: 13))
                          ])))
      ]);
}

class _Btn extends StatelessWidget {
  final bool saving;
  final VoidCallback onTap;
  const _Btn({required this.saving, required this.onTap});
  @override
  Widget build(BuildContext ctx) => SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
          onPressed: saving ? null : onTap,
          style: ElevatedButton.styleFrom(
              backgroundColor: AzizColors.saffron,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0),
          child: saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.black))
              : const Text('SAUVEGARDER',
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      letterSpacing: 2,
                      fontSize: 13))));
}

class _Err extends StatelessWidget {
  final String msg;
  const _Err(this.msg);
  @override
  Widget build(BuildContext ctx) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: AzizColors.error.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AzizColors.error, width: .5)),
      child: Text(msg,
          style: const TextStyle(color: AzizColors.error, fontSize: 13)));
}
