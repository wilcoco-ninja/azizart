import 'package:flutter/material.dart';

// ══════════════════════════════════════════════════════════════════════════════
// GalleryCategory — enum des catégories de la galerie
//
// Chaque valeur expose :
//   • filterValues  : noms acceptés dans artwork.category (JSON + Firestore)
//   • coverAsset    : image de couverture locale pour la tuile catégorie
//   • icon          : icône Material
//   • label(ctx)    : libellé localisé FR/EN
//   • description(ctx) : description courte localisée
// ══════════════════════════════════════════════════════════════════════════════
enum GalleryCategory {
  tableau,
  vetements,
  tisuPagne,
  nappeDTable,
  sculpture,
  objet,
}

extension GalleryCategoryX on GalleryCategory {
  // ── Valeurs de filtrage (JSON + Firestore) ────────────────────────────────
  List<String> get filterValues {
    switch (this) {
      case GalleryCategory.tableau:
        return ['Tableau', 'Batik sur toile', 'batik sur toile'];
      case GalleryCategory.vetements:
        return ['Vêtements', 'Batik sur tissu', 'batik sur tissu'];
      case GalleryCategory.tisuPagne:
        return ['Tissu Pagne', 'tissu pagne', 'Pagne'];
      case GalleryCategory.nappeDTable:
        return ['Nappe de Table', 'Art de la table', 'art de la table'];
      case GalleryCategory.sculpture:
        return ['Sculpture', 'sculpture'];
      case GalleryCategory.objet:
        return ['Objet', 'objet', 'Accessoire'];
    }
  }

  // ── Image de couverture locale ────────────────────────────────────────────
  String get coverAsset {
    switch (this) {
      case GalleryCategory.tableau:     return 'assets/images/gallery/tableau2.jpeg';
      case GalleryCategory.vetements:   return 'assets/images/gallery/a1.jpg';
      case GalleryCategory.tisuPagne:   return 'assets/images/gallery/o1.jpeg';
      case GalleryCategory.nappeDTable: return 'assets/images/gallery/4.jpeg';
      case GalleryCategory.sculpture:   return 'assets/images/gallery/a5.jpg';
      case GalleryCategory.objet:       return 'assets/images/gallery/a8.jpg';
    }
  }

  // ── Icône ─────────────────────────────────────────────────────────────────
  IconData get icon {
    switch (this) {
      case GalleryCategory.tableau:     return Icons.palette_outlined;
      case GalleryCategory.vetements:   return Icons.checkroom_outlined;
      case GalleryCategory.tisuPagne:   return Icons.texture_outlined;
      case GalleryCategory.nappeDTable: return Icons.table_restaurant_outlined;
      case GalleryCategory.sculpture:   return Icons.architecture_outlined;
      case GalleryCategory.objet:       return Icons.category_outlined;
    }
  }

  // ── Libellé localisé ──────────────────────────────────────────────────────
  String label(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    switch (this) {
      case GalleryCategory.tableau:
        return isEn ? 'Paintings'     : 'Tableaux';
      case GalleryCategory.vetements:
        return isEn ? 'Clothing'      : 'Vêtements';
      case GalleryCategory.tisuPagne:
        return isEn ? 'Fabric Pagne'  : 'Tissu Pagne';
      case GalleryCategory.nappeDTable:
        return isEn ? 'Table Linens'  : 'Nappe de Table';
      case GalleryCategory.sculpture:
        return isEn ? 'Sculptures'    : 'Sculptures';
      case GalleryCategory.objet:
        return isEn ? 'Objects'       : 'Objets';
    }
  }

  // ── Description courte ────────────────────────────────────────────────────
  String description(BuildContext context) {
    final isEn = Localizations.maybeLocaleOf(context)?.languageCode == 'en';
    switch (this) {
      case GalleryCategory.tableau:
        return isEn ? 'Original batik paintings on canvas'
                    : 'Peintures batik originales sur toile';
      case GalleryCategory.vetements:
        return isEn ? 'Hand-dyed batik clothing'
                    : 'Vêtements batik teints à la main';
      case GalleryCategory.tisuPagne:
        return isEn ? 'Aho hand-woven fabric lengths'
                    : 'Coupes de tissu Aho tissé à la main';
      case GalleryCategory.nappeDTable:
        return isEn ? 'Batik table linens & runners'
                    : 'Nappes et chemins de table batik';
      case GalleryCategory.sculpture:
        return isEn ? 'Mixed-media sculptures'
                    : 'Sculptures en technique mixte';
      case GalleryCategory.objet:
        return isEn ? 'Decorative objects & accessories'
                    : 'Objets décoratifs & accessoires';
    }
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// GalleryNavigationRequest — signal de navigation vers une catégorie
//
// Utilisé par _CategoriesSection (home_page) pour pré-filtrer la GalleryPage
// avant que Flutter ne la construise.
// ══════════════════════════════════════════════════════════════════════════════
class GalleryNavigationRequest {
  static GalleryCategory? _pending;

  /// Consomme la demande en attente (retourne null s'il n'y en a pas).
  static GalleryCategory? consume() {
    final cat = _pending;
    _pending  = null;
    return cat;
  }

  /// Enregistre une demande de filtrage par catégorie.
  static void requestCategory(GalleryCategory category) {
    _pending = category;
  }
}