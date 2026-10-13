import 'package:flutter/material.dart';

import '../../../services/media_url_resolver.dart';

/// Représente une photo de l'atelier.
@immutable
class AtelierPhoto {
  final String id;

  /// Clé R2 relative (ex. `atelier/photo.jpeg` ou `photo.jpeg`) ou asset.
  final String imagePath;

  /// URL publique R2 complète (optionnelle).
  final String imageUrl;

  final String titleFr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionEn;

  /// Position d'affichage — correspond à la colonne `sort_order`.
  final int order;

  final bool isPublished;

  const AtelierPhoto({
    required this.id,
    this.imagePath = '',
    this.imageUrl = '',
    this.titleFr = '',
    this.titleEn = '',
    this.descriptionFr = '',
    this.descriptionEn = '',
    this.order = 99,
    this.isPublished = true,
  });

  String getTitle(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return (isEn && titleEn.isNotEmpty) ? titleEn : titleFr;
  }

  String getDescription(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return (isEn && descriptionEn.isNotEmpty) ? descriptionEn : descriptionFr;
  }

  bool get hasNetworkImage =>
      imageUrl.isNotEmpty && imageUrl.startsWith('http');

  /// URL publique Cloudflare R2 de la photo.
  ///
  /// Une URL enregistrée est ramenée au domaine actuel (anciennes URLs
  /// Supabase ou `r2.dev` comprises). Une clé relative garde son dossier
  /// (`atelier/…`, `gallery/…`) ; un nom de fichier seul est cherché dans
  /// `gallery/`, comme les photos du contenu initial.
  String get displayImage {
    final direct = imageUrl.trim();
    final reference = direct.isNotEmpty ? direct : imagePath.trim();
    if (reference.startsWith('assets/')) return reference;
    return MediaUrlResolver.resolve(
      reference,
      folder: reference.contains('/') ? null : 'gallery',
    );
  }

  String get caption => titleFr.isNotEmpty ? titleFr : titleEn;
  String get detail => descriptionFr.isNotEmpty ? descriptionFr : descriptionEn;

  factory AtelierPhoto.fromJson(Map<String, dynamic> j) {
    String pickStr(List<String> keys) {
      for (final k in keys) {
        final v = j[k];
        if (v is String && v.isNotEmpty) return v;
      }
      return '';
    }

    final titleFr = pickStr(['titleFr', 'title_fr', 'title']);
    final titleEn = pickStr(['titleEn', 'title_en', 'title']);
    final descFr = pickStr(['descriptionFr', 'description_fr', 'description']);
    final descEn = pickStr(['descriptionEn', 'description_en', 'description']);

    final rawOrder = j['sortOrder'] ?? j['sort_order'] ?? j['order'];
    final rawPublished = j['isPublished'] ?? j['is_published'];

    return AtelierPhoto(
      id: j['id']?.toString() ?? '',
      imagePath: (j['imagePath'] ?? j['image_path']) as String? ?? '',
      imageUrl: (j['imageUrl'] ?? j['image_url']) as String? ?? '',
      titleFr: titleFr,
      titleEn: titleEn.isNotEmpty ? titleEn : titleFr,
      descriptionFr: descFr,
      descriptionEn: descEn.isNotEmpty ? descEn : descFr,
      order: (rawOrder is num) ? rawOrder.toInt() : 99,
      isPublished: (rawPublished is bool) ? rawPublished : true,
    );
  }

  factory AtelierPhoto.fromMap(Map<String, dynamic> j) =>
      AtelierPhoto.fromJson(j);

  Map<String, dynamic> toMap() => {
        'image_path': imagePath,
        'image_url': imageUrl,
        'title_fr': titleFr,
        'title_en': titleEn.isEmpty ? titleFr : titleEn,
        'description_fr': descriptionFr,
        'description_en': descriptionEn.isEmpty ? descriptionFr : descriptionEn,
        'sort_order': order,
        'is_published': isPublished,
      };

  AtelierPhoto copyWith({
    String? id,
    String? imagePath,
    String? imageUrl,
    String? titleFr,
    String? titleEn,
    String? descriptionFr,
    String? descriptionEn,
    int? order,
    bool? isPublished,
  }) {
    return AtelierPhoto(
      id: id ?? this.id,
      imagePath: imagePath ?? this.imagePath,
      imageUrl: imageUrl ?? this.imageUrl,
      titleFr: titleFr ?? this.titleFr,
      titleEn: titleEn ?? this.titleEn,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      order: order ?? this.order,
      isPublished: isPublished ?? this.isPublished,
    );
  }
}