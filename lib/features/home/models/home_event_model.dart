import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HomeEventType
// ══════════════════════════════════════════════════════════════════════════════
enum HomeEventType { news, event, reportage }

extension HomeEventTypeX on HomeEventType {
  String getLabel(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    switch (this) {
      case HomeEventType.news:
        return isEn ? 'NEWS' : 'ACTUALITÉ';
      case HomeEventType.event:
        return isEn ? 'EVENT' : 'ÉVÉNEMENT';
      case HomeEventType.reportage:
        return isEn ? 'REPORT' : 'REPORTAGE';
    }
  }

  Color get color {
    switch (this) {
      case HomeEventType.news:
        return const Color(0xFF2E7D32);
      case HomeEventType.event:
        return const Color(0xFFE8C56A);
      case HomeEventType.reportage:
        return const Color(0xFF6B4FA0);
    }
  }

  IconData get icon {
    switch (this) {
      case HomeEventType.news:
        return Icons.newspaper_outlined;
      case HomeEventType.event:
        return Icons.event_outlined;
      case HomeEventType.reportage:
        return Icons.camera_alt_outlined;
    }
  }

  static HomeEventType fromString(String s) {
    switch (s.toLowerCase().trim()) {
      case 'event':
      case 'exhibition':
        return HomeEventType.event;
      case 'reportage':
        return HomeEventType.reportage;
      default:
        return HomeEventType.news;
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// HomeEvent
// ══════════════════════════════════════════════════════════════════════════════
class HomeEvent {
  final String id;
  final String titleFr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionEn;

  /// URL publique Cloudflare R2 de l'image (dossier `home_events/`).
  final String imageUrl;
  final HomeEventType type;
  final DateTime? eventDate;
  final DateTime? createdAt;
  final bool isPublished;
  final String source;
  final String externalUrl;

  const HomeEvent({
    required this.id,
    this.titleFr = '',
    this.titleEn = '',
    this.descriptionFr = '',
    this.descriptionEn = '',
    this.imageUrl = '',
    this.type = HomeEventType.news,
    this.eventDate,
    this.createdAt,
    this.isPublished = true,
    this.source = '',
    this.externalUrl = '',
  });

  String getTitle(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return (isEn && titleEn.isNotEmpty) ? titleEn : titleFr;
  }

  String getDescription(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    return (isEn && descriptionEn.isNotEmpty) ? descriptionEn : descriptionFr;
  }

  // ── Lecture d'une ligne de la table `home_events` ───────────────────────
  factory HomeEvent.fromMap(Map<String, dynamic> d) => HomeEvent(
        id: d['id']?.toString() ?? '',
        titleFr: d['title_fr'] as String? ?? '',
        titleEn: d['title_en'] as String? ?? '',
        descriptionFr: d['description_fr'] as String? ?? '',
        descriptionEn: d['description_en'] as String? ?? '',
        imageUrl: d['image_url'] as String? ?? '',
        type: HomeEventTypeX.fromString(d['type'] as String? ?? 'news'),
        eventDate: d['event_date'] != null
            ? DateTime.tryParse(d['event_date'].toString())
            : null,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'].toString())
            : null,
        isPublished: d['is_published'] as bool? ?? true,
        source: d['source'] as String? ?? '',
        externalUrl: d['external_url'] as String? ?? '',
      );

  // ── Sérialisation pour insertion / mise à jour ──────────────────────────
  Map<String, dynamic> toMap() => {
        'title_fr': titleFr,
        'title_en': titleEn.isEmpty ? titleFr : titleEn,
        'description_fr': descriptionFr,
        'description_en': descriptionEn.isEmpty ? descriptionFr : descriptionEn,
        'image_url': imageUrl,
        'type': type.name,
        'event_date': eventDate?.toIso8601String().split('T').first,
        'is_published': isPublished,
        'source': source,
        'external_url': externalUrl,
      };
}