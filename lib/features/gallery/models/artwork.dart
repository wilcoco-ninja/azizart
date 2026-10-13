import '../../../services/media_url_resolver.dart';

/// Représente une œuvre de la galerie.
class Artwork {
  final String id;
  final String titleFr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionEn;
  final String imagePath; // Clé R2 relative
  final String imageUrl; // URL publique directe
  final String category;
  final String technique;
  final String dimensions;
  final String year;
  final double? price;
  final bool featured;
  final String status; // 'available' ou 'sold'
  final bool isPublished;

  const Artwork({
    required this.id,
    this.titleFr = '',
    this.titleEn = '',
    this.descriptionFr = '',
    this.descriptionEn = '',
    this.imagePath = '',
    this.imageUrl = '',
    this.category = '',
    this.technique = '',
    this.dimensions = '',
    this.year = '',
    this.price,
    bool? featured,
    String? status,
    this.isPublished = true,
  })  : featured = featured ?? false,
        status = status ?? 'available';

  String get title => titleFr.isNotEmpty ? titleFr : titleEn;

  bool get hasNetworkImage =>
      imageUrl.isNotEmpty && imageUrl.startsWith('http');

  bool get isAvailable => status != 'sold';
  bool get isFeatured => featured;

  /// URL publique R2 : URL directe si présente, sinon clé relative
  /// (dossier `gallery/` par défaut). Les anciennes URLs sont corrigées.
  String get displayImage {
    final direct = imageUrl.trim();
    final reference = direct.isNotEmpty ? direct : imagePath.trim();
    if (reference.startsWith('assets/')) return reference;
    return MediaUrlResolver.resolve(reference, folder: 'gallery');
  }

  factory Artwork.fromJson(Map<String, dynamic> d) => Artwork(
        id: d['id']?.toString() ?? '',
        titleFr: d['title_fr'] as String? ??
            d['titleFr'] as String? ??
            d['title'] as String? ??
            '',
        titleEn: d['title_en'] as String? ?? d['titleEn'] as String? ?? '',
        descriptionFr: d['description_fr'] as String? ??
            d['descriptionFr'] as String? ??
            '',
        descriptionEn: d['description_en'] as String? ??
            d['descriptionEn'] as String? ??
            '',
        imagePath:
            d['image_path'] as String? ?? d['imagePath'] as String? ?? '',
        imageUrl: d['image_url'] as String? ?? d['imageUrl'] as String? ?? '',
        category: d['category'] as String? ?? '',
        technique: d['technique'] as String? ?? '',
        dimensions: d['dimensions'] as String? ?? '',
        year: d['year']?.toString() ?? '',
        price: (d['price'] as num?)?.toDouble(),
        featured: d['featured'] as bool? ?? false,
        status: d['status'] as String? ??
            (d['isAvailable'] == false ? 'sold' : 'available'),
        isPublished: d['is_published'] as bool? ??
            d['isPublished'] as bool? ??
            true,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'title_fr': titleFr,
        'title_en': titleEn.isEmpty ? titleFr : titleEn,
        'description_fr': descriptionFr,
        'description_en': descriptionEn.isEmpty ? descriptionFr : descriptionEn,
        'image_path': imagePath,
        'image_url': imageUrl,
        'category': category,
        'technique': technique,
        'dimensions': dimensions,
        'year': year,
        'price': price,
        'featured': featured,
        'status': status,
        'is_published': isPublished,
      };

  Artwork copyWith({
    String? id,
    String? titleFr,
    String? titleEn,
    String? descriptionFr,
    String? descriptionEn,
    String? imagePath,
    String? imageUrl,
    String? category,
    String? technique,
    String? dimensions,
    String? year,
    double? price,
    bool? featured,
    String? status,
    bool? isPublished,
  }) =>
      Artwork(
        id: id ?? this.id,
        titleFr: titleFr ?? this.titleFr,
        titleEn: titleEn ?? this.titleEn,
        descriptionFr: descriptionFr ?? this.descriptionFr,
        descriptionEn: descriptionEn ?? this.descriptionEn,
        imagePath: imagePath ?? this.imagePath,
        imageUrl: imageUrl ?? this.imageUrl,
        category: category ?? this.category,
        technique: technique ?? this.technique,
        dimensions: dimensions ?? this.dimensions,
        year: year ?? this.year,
        price: price ?? this.price,
        featured: featured ?? this.featured,
        status: status ?? this.status,
        isPublished: isPublished ?? this.isPublished,
      );
}