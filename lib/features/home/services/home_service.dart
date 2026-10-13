import 'package:flutter/foundation.dart';

import '../../gallery/models/artwork.dart';
import '../../gallery/services/gallery_service.dart';
import '../models/home_model.dart';

/// Données de la page d'accueil, dérivées de la collection d'œuvres
/// (images hébergées sur Cloudflare R2).
class HomeService {
  final GalleryService _galleryService = GalleryService();

  /// Nombre maximal d'œuvres vedettes pour la lecture ponctuelle.
  static const int _featuredLimit = 6;

  Future<HomeData> fetchHomeData() async {
    try {
      final artworks = await _galleryService.fetchArtworks();
      final featured = _pickFeatured(artworks);
      debugPrint('HomeService: ${featured.length} œuvres vedettes chargées');
      return HomeData(featuredArtworks: featured);
    } catch (e) {
      debugPrint('HomeService: erreur chargement ($e) — aucune donnée affichée');
      return const HomeData();
    }
  }

  Stream<HomeData> watchHomeData() {
    return _galleryService
        .watchArtworks()
        .map((artworks) => HomeData(featuredArtworks: _pickFeatured(artworks)));
  }

  List<Artwork> _pickFeatured(List<Artwork> artworks) {
    return artworks
        .where((a) => a.featured && a.isPublished)
        .take(_featuredLimit)
        .toList();
  }
}