// ══════════════════════════════════════════════════════════════════════════════
// AtelierPhoto — modèle photo atelier
// Compatible JSON local (camelCase — inchangé) et Supabase/Postgres
// (snake_case — voir schema.sql).
// ══════════════════════════════════════════════════════════════════════════════
class AtelierPhoto {
  final String id;
  final String imagePath; // asset local
  final String imageUrl; // Supabase Storage URL
  final String titleFr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionEn;
  final int order;

  const AtelierPhoto({
    required this.id,
    this.imagePath = '',
    this.imageUrl = '',
    this.titleFr = '',
    this.titleEn = '',
    this.descriptionFr = '',
    this.descriptionEn = '',
    this.order = 99,
  });

  bool get hasNetworkImage =>
      imageUrl.isNotEmpty && imageUrl.startsWith('http');
  String get displayImage => hasNetworkImage ? imageUrl : imagePath;

  // ── Getters de compatibilité (utilisés dans atelier_page.dart) ───────────
  String get caption => titleFr.isNotEmpty ? titleFr : titleEn;
  String get detail => descriptionFr.isNotEmpty ? descriptionFr : descriptionEn;

  // ── JSON local (assets/data/atelier_photos.json) — INCHANGÉ ─────────────
  factory AtelierPhoto.fromMap(Map<String, dynamic> j) =>
      AtelierPhoto.fromJson(j);

  factory AtelierPhoto.fromJson(Map<String, dynamic> j) => AtelierPhoto(
        id: j['id']?.toString() ?? '',
        imagePath: j['imagePath'] as String? ?? '',
        imageUrl: j['imageUrl'] as String? ?? '',
        titleFr: j['titleFr'] as String? ?? '',
        titleEn: j['titleEn'] as String? ?? '',
        descriptionFr: j['descriptionFr'] as String? ?? '',
        descriptionEn: j['descriptionEn'] as String? ?? '',
        order: j['order'] as int? ?? 99,
      );

  // ── Parsing Supabase (table public.atelier_photos) ──────────────────────
  factory AtelierPhoto.fromSupabase(Map<String, dynamic> d) => AtelierPhoto(
        id: d['id']?.toString() ?? '',
        imagePath: d['image_path'] as String? ?? '',
        imageUrl: d['image_url'] as String? ?? '',
        titleFr: d['title_fr'] as String? ?? '',
        titleEn: d['title_en'] as String? ?? '',
        descriptionFr: d['description_fr'] as String? ?? '',
        descriptionEn: d['description_en'] as String? ?? '',
        order: (d['order'] as num?)?.toInt() ?? 99,
      );

  // ── Sérialisation vers Supabase (insert / update) ───────────────────────
  Map<String, dynamic> toMap() => {
        'image_path': imagePath,
        'image_url': imageUrl,
        'title_fr': titleFr,
        'title_en': titleEn.isEmpty ? titleFr : titleEn,
        'description_fr': descriptionFr,
        'description_en': descriptionEn.isEmpty ? descriptionFr : descriptionEn,
        'order': order,
      };
}
