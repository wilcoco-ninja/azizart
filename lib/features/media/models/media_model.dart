import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MediaType
// ══════════════════════════════════════════════════════════════════════════════
enum MediaType { video, reportage, news }

extension MediaTypeX on MediaType {
  // Libellé localisé
  String getLabel(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    switch (this) {
      case MediaType.video:
        return isEn ? 'VIDEO' : 'VIDÉO';
      case MediaType.reportage:
        return isEn ? 'REPORT' : 'REPORTAGE';
      case MediaType.news:
        return isEn ? 'NEWS' : 'ACTUALITÉ';
    }
  }

  // Couleur accent par type (utilisée dans media_page.dart)
  Color get color {
    switch (this) {
      case MediaType.video:
        return const Color(0xFFE53935); // rouge YouTube
      case MediaType.reportage:
        return const Color(0xFF1565C0); // bleu presse
      case MediaType.news:
        return const Color(0xFF2E7D32); // vert actu
    }
  }

  // Icône par type
  IconData get icon {
    switch (this) {
      case MediaType.video:
        return Icons.play_circle_outline;
      case MediaType.reportage:
        return Icons.article_outlined;
      case MediaType.news:
        return Icons.newspaper_outlined;
    }
  }

  // Parse depuis chaîne (JSON / Supabase)
  // Accepte les anciennes valeurs FR ('actualite', 'reportage')
  static MediaType fromString(String s) {
    switch (s.toLowerCase().trim()) {
      case 'reportage':
        return MediaType.reportage;
      case 'actualite':
      case 'actualité':
      case 'news':
        return MediaType.news;
      default:
        return MediaType.video;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// MediaItem
// Compatible JSON local (camelCase — inchangé) et Supabase/Postgres
// (snake_case — voir schema.sql).
//
// FIX : `descriptionFr` / `descriptionEn` ajoutés — le JSON local
// (media_items.json) contient ces textes sous les clés `subtitleFr` /
// `subtitleEn`, mais l'ancien modèle ne les lisait pas du tout : le texte
// existait dans les données mais disparaissait silencieusement au
// parsing, jamais affiché nulle part.
// ══════════════════════════════════════════════════════════════════════════════
class MediaItem {
  final String id;
  final String titleFr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionEn;
  final MediaType type;
  final String source;
  final String url;
  final String thumbnailPath;
  final String thumbnailUrl;
  final String year;
  final String? duration; // ex: "2:45" ou "45 min"
  final DateTime? date; // date de parution / événement

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
  });

  // Titre localisé (avec BuildContext)
  String getTitle(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return (isEn && titleEn.isNotEmpty) ? titleEn : titleFr;
  }

  // Description/sous-titre localisé (avec BuildContext)
  String getDescription(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return (isEn && descriptionEn.isNotEmpty) ? descriptionEn : descriptionFr;
  }

  bool get hasNetworkThumb =>
      thumbnailUrl.isNotEmpty && thumbnailUrl.startsWith('http');
  String get displayThumb => hasNetworkThumb ? thumbnailUrl : thumbnailPath;

  // ── JSON local (assets/data/media_items.json) ───────────────────────────
  factory MediaItem.fromMap(Map<String, dynamic> j) => MediaItem.fromJson(j);

  factory MediaItem.fromJson(Map<String, dynamic> j) {
    DateTime? parsedDate;
    final rawDate = j['date'];
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }
    return MediaItem(
      id: j['id']?.toString() ?? '',
      titleFr: j['titleFr'] as String? ?? j['title'] as String? ?? '',
      titleEn: j['titleEn'] as String? ?? '',
      // FIX : lit désormais subtitleFr/subtitleEn (présents dans le JSON
      // mais jusqu'ici jamais capturés par le modèle).
      descriptionFr:
          j['subtitleFr'] as String? ?? j['descriptionFr'] as String? ?? '',
      descriptionEn:
          j['subtitleEn'] as String? ?? j['descriptionEn'] as String? ?? '',
      type: MediaTypeX.fromString(j['type'] as String? ?? 'video'),
      source: j['source'] as String? ?? '',
      url: j['url'] as String? ?? '',
      thumbnailPath: j['thumbnailPath'] as String? ?? '',
      thumbnailUrl: j['thumbnailUrl'] as String? ?? '',
      year: j['year']?.toString() ?? '',
      duration: j['duration'] as String?,
      date: parsedDate,
    );
  }

  // ── Parsing Supabase (table public.media_items) ─────────────────────────
  factory MediaItem.fromSupabase(Map<String, dynamic> d) {
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
    );
  }

  // ── Sérialisation vers Supabase (insert / update) ───────────────────────
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
      };
}
