import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/r2_reference_guard.dart';
import '../../../services/r2_storage_service.dart';
import '../models/atelier_model.dart';

/// Photos de l'atelier : métadonnées dans la table `atelier_photos`,
/// fichiers sur Cloudflare R2 (dossier `atelier/`).
class AtelierService {
  SupabaseClient get _db => Supabase.instance.client;
  static const String _table = 'atelier_photos';
  static const String _folder = 'atelier';

  // ═══════════════════════════════════════════════════════════════════════
  // CONTRÔLE ADMIN
  // ═══════════════════════════════════════════════════════════════════════

  Future<void> _checkAdmin() async {
    if (_db.auth.currentUser == null) {
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
  }

  // ═══════════════════════════════════════════════════════════════════════
  // LECTURE
  // ═══════════════════════════════════════════════════════════════════════

  /// Flux temps réel (écrans admin uniquement : le site public utilise
  /// [fetchPhotos] via AppDataProvider).
  Stream<List<AtelierPhoto>> watchPhotos({bool adminOnly = false}) {
    var query = _db.from(_table).stream(primaryKey: ['id']);
    if (!adminOnly) query = query.eq('is_published', true);
    return query
        .order('sort_order', ascending: true)
        .map((rows) => rows.map(AtelierPhoto.fromMap).toList());
  }

  Future<List<AtelierPhoto>> fetchPhotos({bool adminOnly = false}) async {
    try {
      final base = _db.from(_table).select();
      final rows = await (adminOnly ? base : base.eq('is_published', true))
          .order('sort_order', ascending: true);
      return rows.map(AtelierPhoto.fromMap).toList();
    } catch (e) {
      debugPrint('AtelierService: erreur fetchPhotos — $e');
      return [];
    }
  }

  /// Prochaine position d'affichage (dernier `sort_order` + 1, minimum 1).
  Future<int> getNextSortOrder() async {
    final rows = await _db
        .from(_table)
        .select('sort_order')
        .order('sort_order', ascending: false)
        .limit(1);
    if (rows.isEmpty) return 1;
    final last = rows.first['sort_order'];
    return (last is num ? last.toInt() : 0) + 1;
  }

  // ═══════════════════════════════════════════════════════════════════════
  // ÉCRITURE
  // ═══════════════════════════════════════════════════════════════════════

  /// Ajoute une photo et retourne son identifiant.
  Future<String> addPhoto(AtelierPhoto photo) async {
    await _checkAdmin();
    try {
      final row =
          await _db.from(_table).insert(photo.toMap()).select().single();
      final id = row['id'].toString();
      debugPrint('AtelierService: photo ajoutée — id: $id');
      return id;
    } catch (e) {
      debugPrint('AtelierService: erreur addPhoto — $e');
      rethrow;
    }
  }

  /// Met à jour une photo. Si l'image a été remplacée, l'ancien fichier est
  /// supprimé de R2, sauf si une autre ligne le référence encore.
  Future<void> updatePhoto(String id, AtelierPhoto photo) async {
    await _checkAdmin();

    Map<String, dynamic>? before;
    try {
      before = await _db
          .from(_table)
          .select('image_url, image_path')
          .eq('id', id)
          .maybeSingle();
    } catch (e) {
      debugPrint('AtelierService: lecture de l\'ancienne image impossible — $e');
    }

    try {
      await _db.from(_table).update(photo.toMap()).eq('id', id);
      debugPrint('AtelierService: photo mise à jour — id: $id');
    } catch (e) {
      debugPrint('AtelierService: erreur updatePhoto — $e');
      rethrow;
    }

    if (before == null) return;

    String? keyOf(Object? reference) => R2StorageService.keyFromReference(
          reference is String ? reference : '',
          defaultFolder: _folder,
        );

    final keep = <String>{
      ?keyOf(photo.imageUrl),
      ?keyOf(photo.imagePath),
    };
    final stale = <String>{
      for (final reference in [before['image_url'], before['image_path']])
        if (keyOf(reference) case final key? when !keep.contains(key)) key,
    };
    if (stale.isEmpty) return;

    await _purgeUnreferenced(stale);
  }

  /// Supprime la photo PUIS son fichier R2 (si plus aucune ligne ne le
  /// référence). Un refus de la RLS (0 ligne) ne fait ainsi jamais perdre
  /// l'image d'une photo qui reste affichée.
  Future<void> deletePhoto(String id) async {
    await _checkAdmin();

    final row = await _db
        .from(_table)
        .select('image_url, image_path')
        .eq('id', id)
        .maybeSingle();
    if (row == null) {
      debugPrint('AtelierService: photo déjà supprimée — id: $id');
      return;
    }

    final deleted = await _db.from(_table).delete().eq('id', id).select('id');
    if (deleted.isEmpty) {
      throw Exception(
        'Suppression refusée : droits insuffisants ou photo introuvable.',
      );
    }
    debugPrint('AtelierService: photo supprimée — id: $id');

    await _purgeUnreferenced([
      row['image_url'] as String?,
      row['image_path'] as String?,
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════
  // STOCKAGE — Cloudflare R2
  // ═══════════════════════════════════════════════════════════════════════

  /// Supprime de R2 les fichiers que plus aucune ligne ne référence.
  /// N'interrompt jamais l'appelant : la base est déjà à jour.
  Future<void> _purgeUnreferenced(Iterable<String?> references) async {
    try {
      final deletable = await R2ReferenceGuard.unreferenced(
        references,
        defaultFolder: _folder,
      );
      if (deletable.isEmpty) return;
      await R2StorageService().deleteReferences(deletable);
    } catch (e) {
      debugPrint('AtelierService: fichier R2 non supprimé — $e');
    }
  }

  /// Supprime de R2 un fichier devenu inutile, sauf si une autre ligne le
  /// référence encore (sans interrompre l'appelant en cas d'échec : la ligne
  /// est déjà enregistrée).
  Future<void> purgeOrphanImage({
    String imageUrl = '',
    String imagePath = '',
  }) =>
      _purgeUnreferenced([imageUrl, imagePath]);
}