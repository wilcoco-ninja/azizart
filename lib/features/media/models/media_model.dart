import 'package:flutter/material.dart';

import '../../../services/media_url_resolver.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MediaType
// ══════════════════════════════════════════════════════════════════════════════
enum MediaType { video, press, documentary }

extension MediaTypeX on MediaType {
  String getLabel(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    switch (this) {
      case MediaType.video:
        return isEn ? 'Video' : 'Vidéo';
      case MediaType.press:
        return isEn ? 'Press' : 'Presse';
      case MediaType.documentary:
        return isEn ? 'Documentary' : 'Documentaire';
    }
  }

  IconData get icon {
    switch (this) {
      case MediaType.video:
        return Icons.play_circle_outline;
      case MediaType.press:
        return Icons.newspaper_outlined;
      case MediaType.documentary:
        return Icons.movie_outlined;
    }
  }

  Color get color {
    switch (this) {
      case MediaType.video:
        return const Color(0xFF3F51B5);
      case MediaType.press:
        return const Color(0xFFE8C56A);
      case MediaType.documentary:
        return const Color(0xFF6B4FA0);
    }
  }

  static MediaType fromString(String s) {
    switch (s.toLowerCase().trim()) {
      case 'press':
      case 'presse':
        return MediaType.press;
      case 'documentary':
      case 'documentaire':
        return MediaType.documentary;
      default:
        return MediaType.video;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MediaItem
// ══════════════════════════════════════════════════════════════════════════════

/// Élément média (vidéo, presse, documentaire) affiché sur le site.
/// Les vignettes sont hébergées sur Cloudflare R2 (dossier `media/`).
@immutable
class MediaItem {
  final String id;
  final String titleFr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionEn;
  final MediaType type;
  final String source;
  final String url;

  /// Clé R2 relative de la vignette (ex. `media/thumb.jpg` ou `thumb.jpg`).
  final String thumbnailPath;

  /// URL publique R2 complète de la vignette (optionnelle).
  final String thumbnailUrl;
  final String year;
  final String? duration;
  final DateTime? date;
  final bool isPublished;

  const MediaItem({
    required this.id,
    this.titleFr = '',
    this.titleEn = '',
    this.descriptionFr = '',
    this.descriptionEn = '',
    this.type = MediaType.video,
    this.source = '',
    this.url = '',
    this.thumbnailPath = '',
    this.thumbnailUrl = '',
    this.year = '',
    this.duration,
    this.date,
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

  bool get hasNetworkThumb =>
      thumbnailUrl.isNotEmpty && thumbnailUrl.startsWith('http');

  /// URL publique R2 de la vignette (dossier `media/` par défaut).
  /// Les anciennes URLs Supabase / r2.dev sont ramenées au domaine actuel.
  String get displayThumb {
    final direct = thumbnailUrl.trim();
    final reference = direct.isNotEmpty ? direct : thumbnailPath.trim();
    if (reference.startsWith('assets/')) return reference;
    return MediaUrlResolver.resolve(reference, folder: 'media');
  }

  /// Lien d'ouverture du média. Un lien externe (YouTube, site de presse)
  /// reste inchangé ; un fichier hébergé sur R2 (ancien domaine inclus)
  /// est ramené au domaine actuel.
  String get displayUrl {
    final raw = url.trim();
    if (!raw.startsWith('http')) return raw;
    return MediaUrlResolver.resolve(raw, folder: 'media');
  }

  MediaItem copyWith({
    String? id,
    String? titleFr,
    String? titleEn,
    String? descriptionFr,
    String? descriptionEn,
    MediaType? type,
    String? source,
    String? url,
    String? thumbnailPath,
    String? thumbnailUrl,
    String? year,
    String? duration,
    DateTime? date,
    bool? isPublished,
  }) {
    return MediaItem(
      id: id ?? this.id,
      titleFr: titleFr ?? this.titleFr,
      titleEn: titleEn ?? this.titleEn,
      descriptionFr: descriptionFr ?? this.descriptionFr,
      descriptionEn: descriptionEn ?? this.descriptionEn,
      type: type ?? this.type,
      source: source ?? this.source,
      url: url ?? this.url,
      thumbnailPath: thumbnailPath ?? this.thumbnailPath,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      year: year ?? this.year,
      duration: duration ?? this.duration,
      date: date ?? this.date,
      isPublished: isPublished ?? this.isPublished,
    );
  }

  /// Lecture d'une ligne de la table `media_items`.
  factory MediaItem.fromMap(Map<String, dynamic> d) {
    final rawDate = d['date'];
    return MediaItem(
      id: d['id']?.toString() ?? '',
      titleFr: d['title_fr'] as String? ?? '',
      titleEn: d['title_en'] as String? ?? '',
      descriptionFr: d['description_fr'] as String? ?? '',
      descriptionEn: d['description_en'] as String? ?? '',
      type: MediaTypeX.fromString(d['type'] as String? ?? 'video'),
      source: d['source'] as String? ?? '',
      url: d['url'] as String? ?? '',
      thumbnailPath: d['thumbnail_path'] as String? ?? '',
      thumbnailUrl: d['thumbnail_url'] as String? ?? '',
      year: d['year']?.toString() ?? '',
      duration: d['duration'] as String?,
      date: rawDate is String && rawDate.isNotEmpty
          ? DateTime.tryParse(rawDate)
          : null,
      isPublished: d['is_published'] as bool? ?? true,
    );
  }

  factory MediaItem.fromJson(Map<String, dynamic> json) =>
      MediaItem.fromMap(json);

  Map<String, dynamic> toMap() => {
        'title_fr': titleFr,
        'title_en': titleEn.isEmpty ? titleFr : titleEn,
        'description_fr': descriptionFr,
        'description_en': descriptionEn.isEmpty ? descriptionFr : descriptionEn,
        'type': type.name,
        'source': source,
        'url': url,
        'thumbnail_path': thumbnailPath,
        'thumbnail_url': thumbnailUrl,
        'year': year,
        'duration': duration,
        'date': date?.toIso8601String(),
        'is_published': isPublished,
      };

  @override
  String toString() =>
      'MediaItem(id: $id, type:${type.name}, published: $isPublished, titleFr:$titleFr)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is MediaItem &&
          other.id == id &&
          other.titleFr == titleFr &&
          other.titleEn == titleEn &&
          other.descriptionFr == descriptionFr &&
          other.descriptionEn == descriptionEn &&
          other.type == type &&
          other.source == source &&
          other.url == url &&
          other.thumbnailPath == thumbnailPath &&
          other.thumbnailUrl == thumbnailUrl &&
          other.year == year &&
          other.duration == duration &&
          other.date == date &&
          other.isPublished == isPublished);

  @override
  int get hashCode => Object.hashAll([
        id,
        titleFr,
        titleEn,
        descriptionFr,
        descriptionEn,
        type,
        source,
        url,
        thumbnailPath,
        thumbnailUrl,
        year,
        duration,
        date,
        isPublished,
      ]);
}