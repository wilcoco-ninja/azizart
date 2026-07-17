import 'dart:convert';
import 'package:flutter/foundation.dart'; // ✅ ajouté pour debugPrint
import 'package:flutter/services.dart';
import '../../features/gallery/models/artwork.dart';
import '../../features/atelier/models/atelier_model.dart';
import '../../features/media/models/media_model.dart';

// FIX (robustesse) : auparavant, tout le fichier JSON était décodé puis
// entièrement transformé en une seule expression `.map().toList()` à
// l'intérieur d'un unique try/catch. Conséquence : si UNE SEULE entrée
// du tableau posait problème (champ du mauvais type, etc.), l'exception
// faisait échouer TOUTE la liste, qui retombait à `[]` — page qui semble
// vide alors que 5 des 6 entrées étaient parfaitement valides.
// Désormais, chaque entrée est analysée individuellement : une entrée
// invalide est ignorée (avec un message dans les logs) sans affecter
// les autres.
class JsonDataService {
  static const String _baseUrl = 'assets/data';

  Future<List<Artwork>> loadArtworks() async {
    try {
      final String response =
          await rootBundle.loadString('$_baseUrl/artworks.json');
      final List<dynamic> data = json.decode(response);
      return _parseEach(data, 'artworks.json', Artwork.fromMap);
    } catch (e) {
      debugPrint('Erreur chargement artworks: $e');
      return [];
    }
  }

  Future<List<AtelierPhoto>> loadAtelierPhotos() async {
    try {
      final String response =
          await rootBundle.loadString('$_baseUrl/atelier_photos.json');
      final List<dynamic> data = json.decode(response);
      return _parseEach(data, 'atelier_photos.json', AtelierPhoto.fromMap);
    } catch (e) {
      debugPrint('Erreur chargement atelier photos: $e');
      return [];
    }
  }

  Future<List<MediaItem>> loadMediaItems() async {
    try {
      final String response =
          await rootBundle.loadString('$_baseUrl/media_items.json');
      final List<dynamic> data = json.decode(response);
      return _parseEach(data, 'media_items.json', MediaItem.fromMap);
    } catch (e) {
      debugPrint('Erreur chargement media items: $e');
      return [];
    }
  }

  /// Parse chaque élément individuellement ; une entrée en erreur est
  /// journalisée puis ignorée, au lieu de faire échouer tout le fichier.
  List<T> _parseEach<T>(
    List<dynamic> data,
    String fileName,
    T Function(Map<String, dynamic>) parser,
  ) {
    final results = <T>[];
    for (var i = 0; i < data.length; i++) {
      try {
        results.add(parser(data[i] as Map<String, dynamic>));
      } catch (e) {
        debugPrint('$fileName : entrée #$i ignorée (invalide) — $e');
      }
    }
    return results;
  }

  Future<Map<String, dynamic>> loadAllData() async {
    final results = await Future.wait([
      loadArtworks(),
      loadAtelierPhotos(),
      loadMediaItems(),
    ]);
    return {
      'artworks': results[0] as List<Artwork>,
      'atelierPhotos': results[1] as List<AtelierPhoto>,
      'mediaItems': results[2] as List<MediaItem>,
    };
  }
}
