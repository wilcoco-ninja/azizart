import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../media/models/media_model.dart';
import '../../../core/data/json_data_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// MediaService — CRUD Supabase (table 'media_items')
// Même architecture que GalleryService. Mêmes noms de méthodes qu'avant.
// ══════════════════════════════════════════════════════════════════════════════
class MediaService {
  final _db = Supabase.instance.client;
  static const _table = 'media_items';

  // ── Streams ──────────────────────────────────────────────────────────────
  Stream<List<MediaItem>> watchAll() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(MediaItem.fromSupabase).toList())
        .handleError((e) => debugPrint('MediaService stream error: $e'));
  }

  Stream<List<MediaItem>> watchByType(String type) {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('type', type)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(MediaItem.fromSupabase).toList());
  }

  // ── Futures ──────────────────────────────────────────────────────────────
  Future<List<MediaItem>> fetchAll() async {
    try {
      final rows =
          await _db.from(_table).select().order('created_at', ascending: false);
      if (rows.isNotEmpty) {
        return rows.map(MediaItem.fromSupabase).toList();
      }
    } catch (e) {
      debugPrint('MediaService fetchAll Supabase error: $e — fallback JSON');
    }
    return JsonDataService().loadMediaItems();
  }

  // ── Écriture ─────────────────────────────────────────────────────────────
  Future<String> addMedia(MediaItem item) async {
    final row = await _db.from(_table).insert(item.toMap()).select().single();
    final id = row['id'].toString();
    debugPrint('MediaService: média ajouté — id: $id');
    return id;
  }

  Future<void> updateMedia(String id, MediaItem item) async {
    await _db.from(_table).update({
      ...item.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  Future<void> deleteMedia(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }
}
