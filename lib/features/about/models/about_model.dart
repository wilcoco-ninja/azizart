// ══════════════════════════════════════════════════════════════════════════════
// AboutModel — Données biographiques d'Olga Indigo
// Source : CV officiel — Biennale de l'Art Africain Contemporain 2026
// ══════════════════════════════════════════════════════════════════════════════

class Exhibition {
  final String title;
  final String location;
  final int year;
  final String? description;

  const Exhibition({
    required this.title,
    required this.location,
    required this.year,
    this.description,
  });
}

class AboutModel {
  final String artistName;
  final String bio;
  final String shortBio;
  final List<Exhibition> exhibitions;
  final List<String> techniques;
  final List<String> awards;
  final String representation;

  const AboutModel({
    required this.artistName,
    required this.bio,
    required this.shortBio,
    required this.exhibitions,
    required this.techniques,
    required this.awards,
    this.representation = '',
  });
}

// ── Instance centralisée — mise à jour depuis le CV officiel 2026 ──────────
const aboutData = AboutModel(
  artistName: 'Olga Indigo',

  shortBio:
      'Artiste visuelle béninoise née à Bohicon (1975), spécialisée dans le '
      'batik, l\'art textile et les teintures naturelles. Héritière d\'une '
      'lignée liée au Royaume du Dahomey (1600–1904).',

  bio: 'Née le 1er janvier 1975 à Bohicon (Bénin), Olga Indigo est une '
      'artiste visuelle dont le travail se situe à la croisée de la peinture, '
      'de l\'art textile et des techniques traditionnelles de teinture '
      'naturelle. Héritière d\'une lignée liée à l\'ancien Royaume du Dahomey '
      '(1600–1904), elle développe depuis plus de trente ans une œuvre fondée '
      'sur les pigments organiques, les tissus Aho tissés à la main et les '
      'savoir-faire transmis au sein de sa famille. Ses recherches portent sur '
      'la mémoire collective, les héritages féminins, les cosmologies africaines '
      'et la transmission des savoirs vernaculaires.',

  // ── Expositions sélectionnées (ordre antéchronologique) ─────────────────
  exhibitions: [
    Exhibition(
      title: 'FINAB — Festival International des Arts du Bénin (4e éd.)',
      location: 'Cotonou, Bénin',
      year: 2026,
    ),
    Exhibition(
      title: 'FINAB — Festival International des Arts du Bénin (3e éd.)',
      location: 'Cotonou, Bénin',
      year: 2025,
    ),
    Exhibition(
      title:
          'FINAB — Festival International des Arts du Bénin (2e éd.) + Institut Français / Hôtel Maison Rouge / Yes Papa / Pura Vida',
      location: 'Cotonou, Bénin',
      year: 2024,
    ),
    Exhibition(
      title: 'FINAB — Festival International des Arts du Bénin (1re éd.)',
      location: 'Cotonou, Bénin',
      year: 2023,
    ),
    Exhibition(
      title: 'Galerie Anne de Villepoix',
      location: 'Paris, France',
      year: 2020,
      description: 'Exposition personnelle.',
    ),
    Exhibition(
      title: 'Galerie SAGA',
      location: 'Lille, France',
      year: 2020,
    ),
    Exhibition(
      title:
          'BISO — Biennale Internationale de Sculpture de Ouagadougou + FESPACO 26e éd.',
      location: 'Ouagadougou, Burkina Faso',
      year: 2019,
      description:
          'Vernissage au Restaurant Le Gondwana ; exposition collective à l\'Institut Français et à l\'Institut Américain.',
    ),
    Exhibition(
      title:
          'SIAO — Salon International de l\'Artisanat de Ouagadougou (15e éd.)',
      location: 'Ouagadougou, Burkina Faso',
      year: 2018,
    ),
    Exhibition(
      title: 'FESPACO — Festival panafricain du cinéma (25e éd.)',
      location: 'Ouagadougou, Burkina Faso',
      year: 2017,
    ),
    Exhibition(
      title:
          'SIAO — Salon International de l\'Artisanat de Ouagadougou (14e éd.)',
      location: 'Ouagadougou, Burkina Faso',
      year: 2016,
    ),
    Exhibition(
      title: 'SITA — Salon International du Tourisme d\'Abidjan',
      location: 'Abidjan, Côte d\'Ivoire',
      year: 2015,
    ),
    Exhibition(
      title: 'Abidjan Art Festival — exposition collective à l\'Atelier Sié',
      location: 'Abidjan, Côte d\'Ivoire',
      year: 2014,
    ),
    Exhibition(
      title: 'Exposition « AHO du Bénin »',
      location: 'Paris, France',
      year: 2009,
    ),
    Exhibition(
      title: 'Exposition « AHO du Bénin »',
      location: 'Berlin, Allemagne',
      year: 2008,
    ),
    Exhibition(
      title: 'Festival sur le Niger (éditions 2005–2008)',
      location: 'Ségou, Mali',
      year: 2005,
      description:
          'L\'un des plus grands festivals culturels d\'Afrique de l\'Ouest. Expositions régulières à l\'Hôtel Ambedjele (Sévaré) et à l\'Hôtel Tamana / Bla Bla Bar (Bamako) de 2000 à 2010.',
    ),
  ],

  // ── Techniques ────────────────────────────────────────────────────────────
  techniques: [
    'Batik sur toile',
    'Batik sur tissu Aho (tissé à la main)',
    'Teintures naturelles (indigo, cola, baobab, teck)',
    'Pigments organiques',
    'Superposition de cires',
    'Réserve à la cire (wax-resist)',
  ],

  // ── Distinctions ─────────────────────────────────────────────────────────
  // Note : aucune distinction explicitement listée dans le CV fourni.
  // À compléter dès que l'artiste transmet ses prix officiels.
  awards: [],

  // ── Représentation ────────────────────────────────────────────────────────
  representation: 'Galerie SAGA, France — www.galeriesaga.com',
);
