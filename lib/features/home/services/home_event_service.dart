import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HomeEvent — modèle événement/actualité page d'accueil
// HomeEventService — CRUD Supabase (table 'home_events')
//
// Postgres n'a pas la limitation "index composite" de Firestore : on peut
// combiner .eq() et .order() librement dans une seule requête, sans
// configuration manuelle supplémentaire.
// ══════════════════════════════════════════════════════════════════════════════

class HomeEvent {
  final String id;
  final String titleFr;
  final String titleEn;
  final String descriptionFr;
  final String descriptionEn;
  final String imageUrl;
  final String type; // 'news' | 'event' | 'exhibition'
  final DateTime? eventDate;
  final DateTime? createdAt;
  final bool isPublished;

  const HomeEvent({
    required this.id,
    required this.titleFr,
    this.titleEn = '',
    required this.descriptionFr,
    this.descriptionEn = '',
    this.imageUrl = '',
    this.type = 'news',
    this.eventDate,
    this.createdAt,
    this.isPublished = true,
  });

  Map<String, dynamic> toMap() => {
        'title_fr': titleFr,
        'title_en': titleEn.isEmpty ? titleFr : titleEn,
        'description_fr': descriptionFr,
        'description_en': descriptionEn.isEmpty ? descriptionFr : descriptionEn,
        'image_url': imageUrl,
        'type': type,
        'event_date': eventDate?.toIso8601String(),
        'is_published': isPublished,
      };

  factory HomeEvent.fromSupabase(Map<String, dynamic> d) => HomeEvent(
        id: d['id']?.toString() ?? '',
        titleFr: d['title_fr'] as String? ?? '',
        titleEn: d['title_en'] as String? ?? '',
        descriptionFr: d['description_fr'] as String? ?? '',
        descriptionEn: d['description_en'] as String? ?? '',
        imageUrl: d['image_url'] as String? ?? '',
        type: d['type'] as String? ?? 'news',
        eventDate: d['event_date'] != null
            ? DateTime.tryParse(d['event_date'].toString())
            : null,
        createdAt: d['created_at'] != null
            ? DateTime.tryParse(d['created_at'].toString())
            : null,
        isPublished: d['is_published'] as bool? ?? true,
      );
}

class HomeEventService {
  final _db = Supabase.instance.client;
  static const _table = 'home_events';

  Future<String> addEvent(HomeEvent event) async {
    final row = await _db.from(_table).insert(event.toMap()).select().single();
    return row['id'].toString();
  }

  /// Lecture ponctuelle (sans abonnement temps réel) des actualités
  /// publiées. Utilisée par _NewsEventsSection comme repli en cas
  /// d'échec de watchPublished() (ex. réseau bloquant les WebSocket).
  Future<List<HomeEvent>> fetchPublished() async {
    final rows = await _db
        .from(_table)
        .select()
        .eq('is_published', true)
        .order('created_at', ascending: false);
    return rows.map(HomeEvent.fromSupabase).toList();
  }

  Future<void> updateEvent(HomeEvent event) async {
    await _db.from(_table).update({
      ...event.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', event.id);
  }

  Future<void> deleteEvent(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }

  /// Actualités publiées, triées de la plus récente à la plus ancienne.
  Stream<List<HomeEvent>> watchPublished() => _db
      .from(_table)
      .stream(primaryKey: ['id'])
      .eq('is_published', true)
      .order('created_at', ascending: false)
      .map((rows) => rows.map(HomeEvent.fromSupabase).toList())
      .handleError(
          (e) => debugPrint('HomeEventService watchPublished error: $e'));

  /// Toutes les actualités (publiées ou non), pour l'écran d'admin.
  Stream<List<HomeEvent>> watchAll() => _db
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('created_at', ascending: false)
      .map((rows) => rows.map(HomeEvent.fromSupabase).toList())
      .handleError((e) => debugPrint('HomeEventService watchAll error: $e'));
}
