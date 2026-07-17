// ══════════════════════════════════════════════════════════════════════════════
// Artwork — modèle galerie
// Compatible JSON local (titleFr/titleEn, camelCase — inchangé) et
// Supabase/Postgres (title_fr/title_en, snake_case — voir schema.sql).
// ══════════════════════════════════════════════════════════════════════════════
class Artwork {
  final String  id;
  final String  titleFr;
  final String  titleEn;
  final String  descriptionFr;
  final String  descriptionEn;
  final String  imagePath;   // asset local
  final String  imageUrl;    // Supabase Storage URL
  final String  category;
  final String  technique;
  final String  dimensions;
  final String  year;
  final double? price;
  final bool    isAvailable;
  final bool    featured;

  const Artwork({
    required this.id,
    this.titleFr       = '',
    this.titleEn       = '',
    this.descriptionFr = '',
    this.descriptionEn = '',
    this.imagePath     = '',
    this.imageUrl      = '',
    this.category      = '',
    this.technique     = '',
    this.dimensions    = '',
    this.year          = '',
    this.price,
    this.isAvailable   = true,
    this.featured      = false,
  });

  // ── Getters utilitaires ──────────────────────────────────────────────────
  /// Titre affiché (FR par défaut, EN si titleFr vide)
  String get title => titleFr.isNotEmpty ? titleFr : titleEn;

  /// Vraie URL réseau (Supabase Storage)
  bool   get hasNetworkImage =>
      imageUrl.isNotEmpty && imageUrl.startsWith('http');

  /// Source d'image à utiliser (URL réseau > asset local)
  String get displayImage => hasNetworkImage ? imageUrl : imagePath;

  // ── Parsing JSON local (assets/data/artworks.json) — INCHANGÉ ───────────
  /// Alias pour json_data_service.dart qui appelle fromMap()
  factory Artwork.fromMap(Map<String, dynamic> j) => Artwork.fromJson(j);

  factory Artwork.fromJson(Map<String, dynamic> j) => Artwork(
    id:            j['id']?.toString() ?? '',
    titleFr:       j['titleFr']  as String? ?? j['title'] as String? ?? '',
    titleEn:       j['titleEn']  as String? ?? '',
    descriptionFr: j['descriptionFr'] as String? ?? '',
    descriptionEn: j['descriptionEn'] as String? ?? '',
    imagePath:     j['imagePath'] as String? ?? '',
    imageUrl:      j['imageUrl']  as String? ?? '',
    category:      j['category']  as String? ?? '',
    technique:     j['technique'] as String? ?? '',
    dimensions:    j['dimensions'] as String? ?? '',
    year:          j['year']?.toString() ?? '',
    price:         (j['price'] as num?)?.toDouble(),
    isAvailable:   j['isAvailable'] as bool? ?? true,
    featured:      j['featured']   as bool? ?? false,
  );

  // ── Parsing Supabase (table public.artworks, colonnes snake_case) ───────
  factory Artwork.fromSupabase(Map<String, dynamic> d) => Artwork(
    id:            d['id']?.toString() ?? '',
    titleFr:       d['title_fr']       as String? ?? '',
    titleEn:       d['title_en']       as String? ?? '',
    descriptionFr: d['description_fr'] as String? ?? '',
    descriptionEn: d['description_en'] as String? ?? '',
    imagePath:     d['image_path']     as String? ?? '',
    imageUrl:      d['image_url']      as String? ?? '',
    category:      d['category']       as String? ?? '',
    technique:     d['technique']      as String? ?? '',
    dimensions:    d['dimensions']     as String? ?? '',
    year:          d['year']?.toString() ?? '',
    price:         (d['price'] as num?)?.toDouble(),
    isAvailable:   d['is_available']   as bool? ?? true,
    featured:      d['featured']       as bool? ?? false,
  );

  // ── Sérialisation vers Supabase (insert / update) ───────────────────────
  Map<String, dynamic> toMap() => {
    'title_fr':       titleFr,
    'title_en':       titleEn.isEmpty ? titleFr : titleEn,
    'description_fr': descriptionFr,
    'description_en': descriptionEn.isEmpty ? descriptionFr : descriptionEn,
    'image_path':     imagePath,
    'image_url':      imageUrl,
    'category':       category,
    'technique':      technique,
    'dimensions':     dimensions,
    'year':           year,
    'price':          price,
    'is_available':   isAvailable,
    'featured':       featured,
  };

  Artwork copyWith({
    String?  titleFr, String? titleEn,
    String?  descriptionFr, String? descriptionEn,
    String?  imagePath, String? imageUrl, String? category,
    String?  technique, String? dimensions, String? year,
    double?  price, bool? isAvailable, bool? featured,
  }) => Artwork(
    id: id,
    titleFr:       titleFr       ?? this.titleFr,
    titleEn:       titleEn       ?? this.titleEn,
    descriptionFr: descriptionFr ?? this.descriptionFr,
    descriptionEn: descriptionEn ?? this.descriptionEn,
    imagePath:     imagePath     ?? this.imagePath,
    imageUrl:      imageUrl      ?? this.imageUrl,
    category:      category      ?? this.category,
    technique:     technique     ?? this.technique,
    dimensions:    dimensions    ?? this.dimensions,
    year:          year          ?? this.year,
    price:         price         ?? this.price,
    isAvailable:   isAvailable   ?? this.isAvailable,
    featured:      featured      ?? this.featured,
  );
}