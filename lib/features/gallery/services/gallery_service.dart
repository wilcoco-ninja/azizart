import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

import '../../gallery/models/artwork.dart';
import '../../../core/data/json_data_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// GalleryService — CRUD Supabase (table 'artworks')
//
// Remplace Firestore par Supabase (Postgres + Realtime + Row Level
// Security). Mêmes noms de méthodes qu'avant : aucun changement requis
// dans les fichiers qui utilisent GalleryService (admin_forms.dart,
// app.dart, home_service.dart…).
// ══════════════════════════════════════════════════════════════════════════════
class GalleryService {
  final _db = Supabase.instance.client;
  static const _table = 'artworks';

  // ── Streams temps réel ───────────────────────────────────────────────────
  // IMPORTANT : le Stream retourné ici doit être créé UNE SEULE FOIS par
  // l'appelant (ex. dans initState / un champ `late final`), jamais
  // recréé à l'intérieur d'un build() — sinon la connexion Realtime est
  // perdue et recréée à chaque frame (même bug que celui déjà corrigé
  // sur _NewsEventsSection côté Firebase).
  Stream<List<Artwork>> watchArtworks() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .map((rows) => rows.map(Artwork.fromSupabase).toList())
        .handleError((e) => debugPrint('GalleryService stream error: $e'));
  }

  Stream<List<Artwork>> watchFeatured() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('featured', true)
        .limit(6)
        .map((rows) => rows.map(Artwork.fromSupabase).toList())
        .handleError(
            (e) => debugPrint('GalleryService watchFeatured error: $e'));
  }

  // ── Futures ponctuels ────────────────────────────────────────────────────
  Future<List<Artwork>> fetchArtworks() async {
    try {
      final rows = await _db.from(_table).select();
      if (rows.isNotEmpty) {
        return rows.map(Artwork.fromSupabase).toList();
      }
    } catch (e) {
      debugPrint(
          'GalleryService fetchArtworks Supabase error: $e — fallback JSON');
    }
    // Fallback JSON local
    return JsonDataService().loadArtworks();
  }

  Future<Artwork?> fetchById(String id) async {
    final row = await _db.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return Artwork.fromSupabase(row);
  }

  // ── Écriture ─────────────────────────────────────────────────────────────
  /// Ajoute une nouvelle œuvre. Retourne l'id généré par Supabase.
  Future<String> addArtwork(Artwork artwork) async {
    final row =
        await _db.from(_table).insert(artwork.toMap()).select().single();
    final id = row['id'].toString();
    debugPrint('GalleryService: œuvre ajoutée — id: $id');
    return id;
  }

  /// Met à jour une œuvre existante.
  Future<void> updateArtwork(String id, Artwork artwork) async {
    await _db.from(_table).update({
      ...artwork.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
    debugPrint('GalleryService: œuvre mise à jour — id: $id');
  }

  /// Supprime une œuvre.
  Future<void> deleteArtwork(String id) async {
    await _db.from(_table).delete().eq('id', id);
    debugPrint('GalleryService: œuvre supprimée — id: $id');
  }

  /// Bascule la disponibilité d'une œuvre.
  Future<void> toggleAvailability(String id,
      {required bool isAvailable}) async {
    await _db.from(_table).update({
      'is_available': isAvailable,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Bascule le statut "vedette" d'une œuvre.
  Future<void> toggleFeatured(String id, {required bool featured}) async {
    await _db.from(_table).update({
      'featured': featured,
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }
}
