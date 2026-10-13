import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/r2_reference_guard.dart';
import '../../../services/r2_storage_service.dart';
import '../models/home_event_model.dart';

/// Actualités et événements de l'accueil : table `home_events`,
/// images sur Cloudflare R2 (dossier `home_events/`).
class HomeEventService {
  final _db = Supabase.instance.client;
  static const _table = 'home_events';
  static const _folder = 'home_events';

  // ── CONTRÔLE ADMIN ─────────────────────────────────────────────────────

  Future<User> _checkAdmin() async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception(
        'Utilisateur non connecté. Veuillez vous connecter pour publier.',
      );
    }
    try {
      final isAdmin = await _db.rpc('is_admin');
      if (isAdmin != true) {
        throw Exception(
          'Permissions insuffisantes. Votre compte n\'a pas les droits administrateur.',
        );
      }
    } on PostgrestException catch (e) {
      throw Exception(
        'Impossible de vérifier vos droits administrateur (${e.message}). Réessayez.',
      );
    }
    return user;
  }

  // ── LECTURE ────────────────────────────────────────────────────────────

  Future<List<HomeEvent>> fetchAll() async {
    final rows =
        await _db.from(_table).select().order('event_date', ascending: false);
    return rows.map(HomeEvent.fromMap).toList();
  }

  Future<List<HomeEvent>> fetchPublished() async {
    try {
      final rows = await _db
          .from(_table)
          .select()
          .eq('is_published', true)
          .order('event_date', ascending: false);
      return rows.map(HomeEvent.fromMap).toList();
    } catch (e) {
      debugPrint('HomeEventService: erreur fetchPublished — $e');
      return [];
    }
  }

  /// Flux temps réel : réservé aux écrans admin.
  Stream<List<HomeEvent>> watchAll() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('event_date', ascending: false)
        .map((list) => list.map(HomeEvent.fromMap).toList());
  }

  Stream<List<HomeEvent>> watchPublished() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('is_published', true)
        .order('event_date', ascending: false)
        .map((list) => list.map(HomeEvent.fromMap).toList());
  }

  // ── ÉCRITURE ───────────────────────────────────────────────────────────

  Future<String> addEvent(HomeEvent event) async {
    final user = await _checkAdmin();

    final data = {
      ...event.toMap(),
      'created_by': user.id,
    };

    try {
      final row = await _db.from(_table).insert(data).select().single();
      final id = row['id'].toString();
      debugPrint('HomeEventService: événement ajouté — id: $id');
      return id;
    } catch (e) {
      debugPrint('HomeEventService: erreur addEvent — $e');
      rethrow;
    }
  }

  Future<void> updateEvent(HomeEvent event) async {
    await _checkAdmin();

    try {
      await _db.from(_table).update({
        ...event.toMap(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', event.id);
      debugPrint('HomeEventService: événement mis à jour — id: ${event.id}');
    } catch (e) {
      debugPrint('HomeEventService: erreur updateEvent — $e');
      rethrow;
    }
  }

  /// Publie / retire un événement sans réécrire les autres champs.
  /// Lève une exception si la RLS refuse l'écriture (aucune ligne modifiée).
  Future<void> setPublished(String id, bool value) async {
    await _checkAdmin();
    final rows = await _db
        .from(_table)
        .update({
          'is_published': value,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', id)
        .select('id');
    if (rows.isEmpty) {
      throw Exception(
        'Modification refusée : droits insuffisants ou événement introuvable.',
      );
    }
    debugPrint('HomeEventService: publication=$value — id: $id');
  }

  // ── SUPPRESSION & STOCKAGE (Cloudflare R2) ──────────────────────────────

  /// Supprime de R2 une image devenue inutile, sauf si une autre ligne la
  /// référence encore. Sans interrompre l'appelant en cas d'échec :
  /// l'événement est déjà enregistré.
  Future<void> purgeOrphanImage({required String imageUrl}) async {
    final url = imageUrl.trim();
    if (url.isEmpty) return;
    try {
      final keys = await R2ReferenceGuard.unreferenced(
        [url],
        defaultFolder: _folder,
      );
      if (keys.isNotEmpty) await R2StorageService().deleteReferences(keys);
    } catch (e) {
      debugPrint('HomeEventService.purgeOrphanImage: échec — $e');
    }
  }

  /// Supprime la ligne PUIS l'image R2. Un refus de la RLS (0 ligne) ne fait
  /// ainsi jamais perdre l'image d'un événement qui reste affiché.
  Future<void> deleteEvent(String id) async {
    await _checkAdmin();

    final row = await _db
        .from(_table)
        .select('image_url')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      debugPrint('HomeEventService: événement déjà supprimé — id: $id');
      return;
    }

    final deleted = await _db.from(_table).delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw Exception(
        'Suppression refusée : droits insuffisants ou événement introuvable.',
      );
    }
    debugPrint('HomeEventService: événement supprimé — id: $id');

    await purgeOrphanImage(imageUrl: (row['image_url'] as String?) ?? '');
  }
}