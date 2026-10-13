import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../services/r2_storage_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// AboutContentService — table 'about_content' (textes de la page À propos)
//
// Les textes vivent dans Supabase ; la photo de profil (avatar_path) et la
// photo de couverture (banner_url) sont des fichiers Cloudflare R2.
// Vérification de session + appartenance à `admins` avant toute écriture.
// Quand une photo est remplacée, l'ancien fichier est supprimé de R2.
// ══════════════════════════════════════════════════════════════════════════════
class AboutContentService {
  final _db = Supabase.instance.client;
  static const _table = 'about_content';
  static const _rowId = 1;

  /// Colonne de la table → dossier R2 correspondant.
  static const Map<String, String> _mediaColumns = {
    'avatar_path': 'about_avatars',
    'banner_url': 'about_banners',
  };

  /// Lecture publique (utilisée par about_page.dart au chargement).
  Future<Map<String, dynamic>?> getContent() async {
    try {
      final row =
          await _db.from(_table).select().eq('id', _rowId).maybeSingle();
      return row;
    } catch (e) {
      debugPrint('AboutContentService.getContent: indisponible ($e)');
      return null;
    }
  }

  /// Flux temps réel (écrans admin).
  Stream<Map<String, dynamic>?> watchContent() {
    return _db
        .from(_table)
        .stream(primaryKey: ['id'])
        .eq('id', _rowId)
        .map((rows) => rows.isNotEmpty ? rows.first : null)
        .handleError(
            (e) => debugPrint('AboutContentService.watchContent error: $e'));
  }

  /// Met à jour (ou crée si absente) la ligne de contenu unique.
  Future<void> updateContent(Map<String, dynamic> fields) async {
    final user = _db.auth.currentUser;
    if (user == null) {
      throw Exception(
          'Utilisateur non connecté. Veuillez vous connecter pour publier.');
    }

    final adminCheck = await _db
        .from('admins')
        .select('id')
        .eq('id', user.id)
        .maybeSingle();

    if (adminCheck == null) {
      throw Exception(
          'Permissions insuffisantes. Votre compte n\'est pas enregistré comme administrateur.');
    }

    Map<String, dynamic>? before;
    try {
      before = await _db
          .from(_table)
          .select(_mediaColumns.keys.join(', '))
          .eq('id', _rowId)
          .maybeSingle();
    } catch (e) {
      debugPrint('AboutContentService: lecture des anciennes photos impossible — $e');
    }

    final data = {
      'id': _rowId,
      ...fields,
      'updated_at': DateTime.now().toIso8601String(),
      // ⚠️ Pas de 'updated_by' : la colonne n'existe pas en base.
    };

    try {
      await _db.from(_table).upsert(data);
      debugPrint('AboutContentService: contenu About mis à jour par ${user.id}');
    } catch (e) {
      debugPrint('AboutContentService: erreur updateContent — $e');
      rethrow;
    }

    await _purgeReplaced(before, fields);
  }

  String? _keyOf(Object? reference, String folder) =>
      R2StorageService.keyFromReference(
        reference is String ? reference : '',
        defaultFolder: folder,
      );

  /// Supprime de R2 les photos remplacées ou retirées (sans interrompre
  /// l'appelant : le contenu est déjà enregistré).
  Future<void> _purgeReplaced(
    Map<String, dynamic>? before,
    Map<String, dynamic> fields,
  ) async {
    if (before == null) return;

    final stale = <String>{};
    _mediaColumns.forEach((column, folder) {
      if (!fields.containsKey(column)) return;
      final oldKey = _keyOf(before[column], folder);
      if (oldKey == null) return;
      if (_keyOf(fields[column], folder) != oldKey) stale.add(oldKey);
    });
    if (stale.isEmpty) return;

    try {
      await R2StorageService().deleteReferences(stale);
    } catch (e) {
      debugPrint('AboutContentService: ancienne photo non supprimée — $e');
    }
  }
}