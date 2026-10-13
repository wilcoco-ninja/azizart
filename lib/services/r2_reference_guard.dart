import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';

import 'r2_storage_service.dart';

/// Empêche de supprimer de R2 un fichier encore utilisé ailleurs.
///
/// Une même image peut être référencée par plusieurs lignes (photo d'atelier
/// et œuvre issues du script de contenu initial, noms de fichiers hérités…,
/// photo de profil ou bannière de la page À propos).
/// À appeler APRÈS la mise à jour ou la suppression de la ligne concernée,
/// pour que cette ligne ne compte plus comme référence.
///
/// Au moindre doute (erreur réseau, colonne illisible) le fichier est
/// conservé : un fichier orphelin est moins grave qu'une image cassée.
class R2ReferenceGuard {
  const R2ReferenceGuard._();

  static const Map<String, List<String>> _columnsByTable = {
    'artworks': ['image_url', 'image_path'],
    'atelier_photos': ['image_url', 'image_path'],
    'media_items': ['thumbnail_url', 'thumbnail_path', 'url'],
    'home_events': ['image_url'],
    'about_content': ['avatar_path', 'avatar_url', 'banner_url'],
  };

  /// Échappe les caractères spéciaux de LIKE (`\`, `%`, `_`).
  static String _escapeLike(String value) => value
      .replaceAll(r'\', r'\\')
      .replaceAll('%', r'\%')
      .replaceAll('_', r'\_');

  static Future<bool> isStillReferenced(String key) async {
    final db = Supabase.instance.client;
    final fileName = _escapeLike(key.split('/').last);
    for (final entry in _columnsByTable.entries) {
      for (final column in entry.value) {
        try {
          final rows = await db
              .from(entry.key)
              .select('id')
              .ilike(column, '%$fileName%')
              .limit(1);
          if (rows.isNotEmpty) return true;
        } catch (e) {
          debugPrint(
            'R2ReferenceGuard: contrôle impossible (${entry.key}.$column) — $e',
          );
          return true;
        }
      }
    }
    return false;
  }

  /// Clés R2 (dédoublonnées) désignées par [references] et qu'aucune ligne
  /// ne référence plus : ce sont les seules à supprimer.
  static Future<List<String>> unreferenced(
    Iterable<String?> references, {
    String? defaultFolder,
  }) async {
    final result = <String>[];
    final seen = <String>{};
    for (final reference in references) {
      final key = R2StorageService.keyFromReference(
        (reference ?? '').trim(),
        defaultFolder: defaultFolder,
      );
      if (key == null || !seen.add(key)) continue;
      if (!await isStillReferenced(key)) result.add(key);
    }
    return result;
  }
}