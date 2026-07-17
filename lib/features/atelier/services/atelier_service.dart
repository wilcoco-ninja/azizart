import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:azizart/features/atelier/models/atelier_model.dart';

/// Service Supabase pour les photos d'Atelier — même schéma que
/// GalleryService. Mêmes noms de méthodes qu'avant : aucun changement
/// requis dans admin_forms.dart ni atelier_page.dart.
class AtelierService {
  final _db = Supabase.instance.client;
  static const _table = 'atelier_photos';

  Stream<List<AtelierPhoto>> watchPhotos() => _db
      .from(_table)
      .stream(primaryKey: ['id'])
      .order('order', ascending: true)
      .map((rows) => rows.map(AtelierPhoto.fromSupabase).toList());

  Future<List<AtelierPhoto>> fetchPhotos() async {
    final rows = await _db.from(_table).select().order('order');
    return rows.map(AtelierPhoto.fromSupabase).toList();
  }

  Future<AtelierPhoto?> fetchPhotoById(String id) async {
    final row = await _db.from(_table).select().eq('id', id).maybeSingle();
    if (row == null) return null;
    return AtelierPhoto.fromSupabase(row);
  }

  /// Ajoute une nouvelle photo. Retourne l'id du document créé.
  Future<String> addPhoto(AtelierPhoto photo) async {
    final row = await _db.from(_table).insert(photo.toMap()).select().single();
    return row['id'].toString();
  }

  /// Met à jour une photo existante.
  Future<void> updatePhoto(String id, AtelierPhoto photo) async {
    await _db.from(_table).update({
      ...photo.toMap(),
      'updated_at': DateTime.now().toIso8601String(),
    }).eq('id', id);
  }

  /// Supprime une photo.
  Future<void> deletePhoto(String id) async {
    await _db.from(_table).delete().eq('id', id);
  }
}
