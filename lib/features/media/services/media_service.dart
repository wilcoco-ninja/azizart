import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/r2_storage_service.dart';
import '../models/media_model.dart';

/// Médias (vidéos, presse, documentaires) : métadonnées dans `media_items`,
/// vignettes et fichiers hébergés sur Cloudflare R2 (dossier `media/`).
class MediaService {
  SupabaseClient get _db => Supabase.instance.client;
  static const String _table = 'media_items';
  static const String _folder = 'media';

  // ═══════════════════════════════════════════════════════════════════════
  // CONTRÔLE ADMIN
  // ═══════════════════════════════════════════════════════════════════════

  /// Vérifie la session ET le rôle admin. Retourne l'identifiant de
  /// l'utilisateur connecté, ou lève une exception.
  Future<String> _checkAdmin() async {
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
    return user.id;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LECTURE
  // ═══════════════════════════════════════════════════════════════════════

  Stream<List<MediaItem>> watchAll() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false)
        .map((rows) => rows.map(MediaItem.fromMap).toList());
  }

  Stream<List<MediaItem>> watchByType(String type) {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('type', type)
        .order('created_at', ascending: false)
        .map((rows) => rows.map(MediaItem.fromMap).toList());
  }

  Future<List<MediaItem>> fetchAll() async {
    try {
      final rows =
          await _db.from(_table).select().order('created_at', ascending: false);
      return rows.map(MediaItem.fromMap).toList();
    } catch (e) {
      debugPrint('MediaService: erreur fetchAll — $e');
      return [];
    }
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ÉCRITURE
  // ═══════════════════════════════════════════════════════════════════════

  Future<String> addMedia(MediaItem item) async {
    final userId = await _checkAdmin();

    final data = {
      ...item.toMap(),
      'created_by': userId,
    };

    try {
      final row = await _db.from(_table).insert(data).select().single();
      final id = row['id'].toString();
      debugPrint('MediaService: média ajouté — id: $id');
      return id;
    } catch (e) {
      debugPrint('MediaService: erreur addMedia — $e');
      rethrow;
    }
  }

  /// Met à jour un média. Si la vignette ou le fichier a été remplacé,
  /// l'ancien fichier est supprimé de R2 (aucun fichier orphelin).
  Future<void> updateMedia(String id, MediaItem item) async {
    await _checkAdmin();

    Map<String, dynamic>? before;
    try {
      before = await _db
          .from(_table)
          .select('thumbnail_url, thumbnail_path, url')
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      debugPrint('MediaService: lecture des anciens fichiers impossible — $e');
    }

    try {
      await _db.from(_table).update({
        ...item.toMap(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      debugPrint('MediaService: média mis à jour — id: $id');
    } catch (e) {
      debugPrint('MediaService: erreur updateMedia — $e');
      rethrow;
    }

    if (before == null) return;

    String? keyOf(Object? reference) => R2StorageService.keyFromReference(
          reference is String ? reference : '',
          defaultFolder: _folder,
        );

    final keep = <String>{
      ?keyOf(item.thumbnailUrl),
      ?keyOf(item.thumbnailPath),
      ?keyOf(item.url),
    };
    final stale = <String>{
      for (final reference in [
        before['thumbnail_url'],
        before['thumbnail_path'],
        before['url'],
      ])
        if (keyOf(reference) case final key? when !keep.contains(key)) key,
    };
    if (stale.isEmpty) return;

    try {
      await R2StorageService().deleteReferences(stale);
    } catch (e) {
      debugPrint('MediaService: ancien fichier non supprimé — $e');
    }
  }

  Future<void> togglePublishStatus(String id, bool isPublished) async {
    await _checkAdmin();

    try {
      await _db.from(_table).update({
        'is_published': isPublished,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', id);
      debugPrint(
          'MediaService: statut publication mis à jour — id: $id ($isPublished)');
    } catch (e) {
      debugPrint('MediaService: erreur togglePublishStatus — $e');
      rethrow;
    }
  }

  /// Supprime le média ET ses fichiers R2 (vignette, et fichier si l'URL
  /// pointe vers le bucket ; un lien externe comme YouTube est ignoré).
  /// Les fichiers sont supprimés en premier : en cas d'échec, la ligne reste
  /// en base et la suppression peut être relancée.
  Future<void> deleteMedia(String id) async {
    await _checkAdmin();

    final row = await _db
        .from(_table)
        .select('thumbnail_url, thumbnail_path, url')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      debugPrint('MediaService: média déjà supprimé — id: $id');
      return;
    }

    await R2StorageService().deleteReferences(
      [
        row['thumbnail_url'] as String?,
        row['thumbnail_path'] as String?,
        row['url'] as String?,
      ],
      defaultFolder: _folder,
    );
    await _db.from(_table).delete().eq('id', id);
    debugPrint('MediaService: média supprimé — id: $id');
  }
}