import 'package:flutter/material.dart';

enum GalleryCategory {
  vetements,
  tissuPagne,
  tableaux,
  nappe,
  objets;

  IconData get icon {
    switch (this) {
      case GalleryCategory.vetements:
        return Icons.checkroom_outlined;
      case GalleryCategory.tissuPagne:
        return Icons.dry_cleaning_outlined;
      case GalleryCategory.tableaux:
        return Icons.palette_outlined;
      case GalleryCategory.nappe:
        return Icons.table_restaurant_outlined;
      case GalleryCategory.objets:
        return Icons.category_outlined;
    }
  }

  String label(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    switch (this) {
      case GalleryCategory.vetements:
        return isEn ? 'Clothing' : 'Vêtements';
      case GalleryCategory.tissuPagne:
        return isEn ? 'Pagne fabric' : 'Tissu pagne';
      case GalleryCategory.tableaux:
        return isEn ? 'Batik paintings' : 'Tableau';
      case GalleryCategory.nappe:
        return isEn ? 'Tablecloth' : 'Nappe de table';
      case GalleryCategory.objets:
        return isEn ? 'Objects' : 'Objets';
    }
  }

  String description(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    switch (this) {
      case GalleryCategory.vetements:
        return isEn
            ? 'Fashion and accessories in indigo patterns.'
            : 'Mode et accessoires aux motifs Indigo.';
      case GalleryCategory.tissuPagne:
        return isEn
            ? 'Hand-dyed fabrics, cut to your measure.'
            : 'Tissus teints à la main, coupés à votre mesure.';
      case GalleryCategory.tableaux:
        return isEn
            ? 'Discover our authentic wall artworks.'
            : 'Découvrez nos œuvres murales authentiques.';
      case GalleryCategory.nappe:
        return isEn
            ? 'Table linens with a unique signature.'
            : 'Nappes et linges de table à la signature unique.';
      case GalleryCategory.objets:
        return isEn
            ? 'Small decorative pieces and accessories.'
            : 'Petits objets décoratifs et accessoires.';
    }
  }

  List<String> get filterValues {
    switch (this) {
      case GalleryCategory.vetements:
        return ['vêtements', 'vetements', 'vêtement', 'vetement', 'clothing'];
      case GalleryCategory.tissuPagne:
        return ['tissu pagne', 'tissu', 'pagne', 'fabric'];
      case GalleryCategory.tableaux:
        return ['tableaux', 'tableau', 'peinture', 'painting', 'paintings'];
      case GalleryCategory.nappe:
        return ['nappe de table', 'nappe', 'tablecloth', 'tablecloths'];
      case GalleryCategory.objets:
        return ['objets', 'objet', 'object', 'objects', 'accessoires'];
    }
  }

  static String _normalize(String value) {
    var s = value.toLowerCase().trim();
    const replacements = {
      'à': 'a', 'â': 'a', 'ä': 'a', 'á': 'a', 'ã': 'a',
      'é': 'e', 'è': 'e', 'ê': 'e', 'ë': 'e',
      'î': 'i', 'ï': 'i', 'í': 'i',
      'ô': 'o', 'ö': 'o', 'ó': 'o', 'õ': 'o',
      'ù': 'u', 'û': 'u', 'ü': 'u', 'ú': 'u',
      'ç': 'c', 'ñ': 'n',
    };
    replacements.forEach((k, v) => s = s.replaceAll(k, v));
    return s.replaceAll(RegExp(r'\s+'), ' ');
  }

  bool matches(String artworkCategory) {
    final target = _normalize(artworkCategory);
    if (target.isEmpty) return false;
    return filterValues.any((v) => _normalize(v) == target);
  }
}

class GalleryNavigationRequest {
  static GalleryCategory? _requestedCategory;

  static void requestCategory(GalleryCategory category) {
    _requestedCategory = category;
  }

  static GalleryCategory? consume() {
    final category = _requestedCategory;
    _requestedCategory = null;
    return category;
  }
}