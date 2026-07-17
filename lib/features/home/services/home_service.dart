import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import '../models/home_model.dart';
import '../../gallery/models/artwork.dart';
import '../../../core/data/json_data_service.dart';

// ══════════════════════════════════════════════════════════════════════════════
// HomeService — charge les œuvres "vedettes" (featured: true).
//
// STRATÉGIE À DOUBLE SOURCE (inchangée) :
//   1. Supabase → si des lignes existent avec featured=true, on les prend.
//   2. JSON local → sinon, on lit artworks.json et on filtre featured==true.
// ══════════════════════════════════════════════════════════════════════════════
class HomeService {
  final _db = Supabase.instance.client;
  final _jsonService = JsonDataService();
  static const _table = 'artworks';

  // ── Charge les œuvres vedettes (Supabase → JSON fallback) ────────────────
  Future<HomeData> fetchHomeData() async {
    // 1. Essai Supabase
    try {
      final rows =
          await _db.from(_table).select().eq('featured', true).limit(6);

      if (rows.isNotEmpty) {
        final artworks = rows.map(Artwork.fromSupabase).toList();
        debugPrint(
            'HomeService: ${artworks.length} œuvres vedettes depuis Supabase');
        return HomeData(featuredArtworks: artworks);
      }
    } catch (e) {
      debugPrint('HomeService: Supabase indisponible ($e) — fallback JSON');
    }

    // 2. Fallback JSON local (artworks.json)
    return _loadFromJson();
  }

  // ── Fallback : lecture artworks.json filtré sur featured==true ───────────
  Future<HomeData> _loadFromJson() async {
    try {
      final all = await _jsonService.loadArtworks();
      final featured = all.where((a) => a.featured).take(6).toList();

      debugPrint(
          'HomeService: ${featured.length} œuvres vedettes depuis JSON local');

      if (featured.isEmpty) {
        return HomeData(featuredArtworks: all.take(6).toList());
      }
      return HomeData(featuredArtworks: featured);
    } catch (e) {
      debugPrint('HomeService: erreur JSON ($e)');
      return const HomeData();
    }
  }

  // ── Stream temps-réel (Supabase seulement — facultatif) ───────────────────
  Stream<List<Artwork>> watchFeatured() => _db
      .from(_table)
      .stream(primaryKey: ['id'])
      .eq('featured', true)
      .limit(6)
      .map((rows) => rows.map(Artwork.fromSupabase).toList());
}
