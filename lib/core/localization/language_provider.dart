import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ══════════════════════════════════════════════════════════════════════════════
// LanguageProvider — Gestion de la locale FR / EN
//
// • Traductions embarquées (zéro chargement async → rebuild immédiat)
// • Format de clés unifié avec POINTS pour couvrir TOUTES les pages
// • context.tr() via extension BuildContext → listen: true, rebuild auto
// ══════════════════════════════════════════════════════════════════════════════

class LanguageProvider extends ChangeNotifier {
  String _languageCode = 'fr';

  String get languageCode => _languageCode;
  Locale get locale => Locale(_languageCode);

  static const List<String> supportedLanguages = ['fr', 'en'];

  void setLocale(Locale locale) {
    final code = locale.languageCode;
    if (!supportedLanguages.contains(code)) return;
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
  }

  String tr(String key) {
    return _translations[_languageCode]?[key] ??
        _translations['fr']?[key] ??
        key;
  }

  static const Map<String, Map<String, String>> _translations = {
    'fr': _fr,
    'en': _en,
  };

  // ════════════════════════════════════════════════════════════════════════════
  // FRANÇAIS
  // ════════════════════════════════════════════════════════════════════════════
  static const Map<String, String> _fr = {
    // ── Navigation ───────────────────────────────────────────────────────────
    'nav.home': 'Accueil',
    'nav.gallery': 'Galerie',
    'nav.atelier': 'Atelier',
    'nav.media': 'Médias',
    'nav.about': 'À propos',
    'nav.contact': 'Contact',

    // ── Page d'accueil ───────────────────────────────────────────────────────
    'home.tagline': "L'art du batik depuis Cotonou, Bénin",
    'home.discover_gallery': 'Découvrir la galerie',
    'home.shop': 'Boutique',
    'home.our_creations': 'Nos créations',
    'home.original_paintings': 'Tableaux originaux',
    'home.unique_pieces': 'Pièces uniques',
    'home.paintings_desc':
        "Chaque toile est une œuvre unique, réalisée à la main avec des pigments naturels et la technique ancestrale du batik à la cire.",
    'home.artwear': 'Art à porter',
    'home.batik_clothing': 'Vêtements batik',
    'home.custom_orders': 'Commandes sur mesure',
    'home.personalized_decor': 'Décoration personnalisée',
    'home.workshop_tag': 'Savoir-faire',
    'home.workshop_title': "La création du tissu batik",
    'home.workshop_desc':
        "Dans notre atelier de Cotonou, chaque pièce naît d'un dialogue entre la cire, l'indigo et le tissu Aho tissé à la main. Un processus ancestral transmis de génération en génération.",
    'home.workshop_cta': "Découvrir l'atelier",
    'home.selection': 'Sélection',
    'home.featured': 'Œuvres à la une',
    'home.view_all': 'Voir tout',
    'home.no_artworks': 'Aucune œuvre à la une pour le moment.',
    'home.available': 'Disponible',
    'home.sold': 'Vendue',
    'home.quote': "L'indigo est ma langue maternelle, la cire mon écriture.",
    'home.explore_tag': 'Explorer',
    'home.explore_title': 'Toute la galerie',
    'home.explore_subtitle':
        "Découvrez l'intégralité des créations d'Olga Indigo : tableaux, vêtements, tissus et objets uniques.",
    'home.view_full_gallery': 'Voir toute la galerie',
    'home.footer_cta_title': 'Vous avez un projet ?',
    'home.footer_cta_subtitle':
        "Commandes personnalisées, expositions, collaborations — parlons-en.",
    'home.footer_email_btn': 'Écrire un e-mail',
    'home.footer_tagline': 'Art Batik Contemporain · Cotonou, Bénin',

    'home.about_tag': "L'ARTISTE",
    'home.about_title': 'Olga Indigo',
    'home.about_cta': 'Découvrir son parcours',
    'home.follow_tag': 'NOUS SUIVRE',
    'home.follow_title': "Suivez l'aventure\ncréative",
    'home.follow_subtitle':
        "Découvrez les coulisses de l'atelier, les nouvelles créations et les expositions à venir sur tous nos réseaux.",
    'home.follow_youtube_desc':
        'Démonstrations batik, processus de création et reportages en vidéo.',
    'home.follow_instagram_desc':
        "Photos de l'atelier, œuvres récentes et actualités quotidiennes.",
    'home.follow_tiktok_desc':
        'Vidéos courtes sur le batik, la teinture naturelle et l\'art textile.',
    'home.follow_facebook_desc':
        'Événements, expositions et actualités de la galerie AZIZART.',

    // ── Galerie ───────────────────────────────────────────────────────────────
    'gallery.title': 'GALERIE',
    'gallery.original_works': 'Œuvres Originales',
    'gallery.batik_description':
        'BATIK SUR TISSU · TEINTURES NATURELLES · ARTISANAT BÉNINOIS',
    'gallery.all': 'Tout',
    'gallery.available_filter': 'Disponibles',
    'gallery.sold_filter': 'Vendues',
    'gallery.artworks_count': 'ŒUVRE',
    'gallery.available': 'Disponible',
    'gallery.sold': 'Vendue',
    'gallery.discover': 'DÉCOUVRIR',
    'gallery.close': 'Fermer',
    'gallery.dimensions': 'Dimensions',
    'gallery.year': 'Année',
    'gallery.technique': 'Technique',
    'gallery.available_for_purchase': 'Disponible à l\'acquisition',
    'gallery.sold_out': 'Œuvre vendue',
    'gallery.no_artworks': 'Aucune œuvre dans cette catégorie.',
    'gallery.indigo_atelier': 'ATELIER OLGA INDIGO · COTONOU',

    // ── Atelier ───────────────────────────────────────────────────────────────
    'atelier.title': "L'ATELIER",
    'atelier.banner_subtitle': "Où naît l'art du batik",
    'atelier.gallery_title': 'LA GALERIE',
    'atelier.gallery_subtitle': 'Instants de création',
    'atelier.our_atelier': "Notre atelier",
    'atelier.our_atelier_desc':
        "Au cœur de Cotonou, l'atelier d'Olga Indigo est un espace vivant où tradition et création se rencontrent chaque jour. La lumière naturelle, les bacs de teinture et l'odeur de la cire chaude y tissent une atmosphère unique.",
    'atelier.philosophy': "Notre philosophie",
    'atelier.philosophy_desc':
        "Chaque pièce est réalisée à la main, dans le respect des techniques ancestrales du batik béninois. Nous utilisons exclusivement des teintures naturelles — indigo, cola, baobab, teck — pour préserver les savoirs vernaculaires et l'environnement.",
    'atelier.contact_cta': 'NOUS CONTACTER',
    'atelier.years_exp': "Années d'expérience",
    'atelier.works_created': "Œuvres créées",
    'atelier.natural_dyes': "Teintures naturelles",
    'atelier.generations': "Générations de transmission",
    'atelier.visit_title': "Visitez notre atelier",
    'atelier.visit_desc':
        "Venez découvrir le processus créatif en direct, rencontrer Olga Indigo et peut-être repartir avec une pièce unique.",
    'atelier.book_appointment': 'PRENDRE RENDEZ-VOUS',

    // ── Médias ────────────────────────────────────────────────────────────────
    'media.banner_title': 'MÉDIAS',
    'media.banner_subtitle': 'Vidéos, Reportages & Actualités',
    'media.filter_all': 'Tous',
    'media.filter_videos': 'Vidéos',
    'media.filter_reportages': 'Reportages',
    'media.filter_news': 'Actualités',
    'media.watch_now': 'Regarder maintenant →',
    'media.click_to_watch': 'Cliquer pour regarder',
    'media.no_media': 'Aucun média dans cette catégorie',
    'media.add_media_hint':
        "Les médias peuvent être ajoutés depuis l'interface d'administration.",
    'media.indigo_atelier': 'ATELIER OLGA INDIGO · COTONOU, BÉNIN',

    // ── À propos ──────────────────────────────────────────────────────────────
    'about.title': 'À PROPOS',
    'about.name': 'Olga Indigo',
    'about.heritage': 'Artiste Batik · Héritière du Dahomey',
    'about.heritage_badge': 'Héritière du Royaume du Dahomey',

    'about.intro_title': "Une artiste enracinée dans l'histoire",
    'about.intro_text':
        "Née le 1er janvier 1975 à Bohicon, Olga Indigo est une artiste visuelle dont l'œuvre se situe à la croisée de la peinture, de l'art textile et des teintures naturelles. Héritière d'une lignée liée à l'ancien Royaume du Dahomey, elle développe depuis plus de trente ans un travail fondé sur les pigments organiques et les tissus Aho tissés à la main.",
    'about.intro_text2':
        "Ses recherches portent sur la mémoire collective, les héritages féminins, les cosmologies africaines et la transmission des savoirs vernaculaires. Son travail est représenté par la Galerie SAGA en France.",

    'about.origins_title': 'Origines & Parcours',
    'about.origins_text1':
        "Bohicon, ville carrefour du Bénin, baignée par l'histoire du Royaume du Dahomey — c'est là qu'Olga Indigo grandit entourée de femmes tisserandes et teinturières. Sa grand-mère lui transmet les secrets de l'indigo dès l'enfance, posant les fondements d'une vocation artistique hors du commun.",
    'about.origins_text2':
        "Après des années de formation auprès des maîtres artisans du Bénin et du Mali, Olga s'installe à Cotonou où elle ouvre son atelier. Elle expose depuis lors à travers l'Afrique de l'Ouest, en Europe et participe aux grandes biennales d'art africain contemporain.",

    'about.grandma_quote':
        "L'indigo ne ment jamais. Il révèle ce que le tissu a toujours su.",
    'about.grandma_author': 'GRAND-MÈRE D\'OLGA · BOHICON, 1985',

    'about.art_title': 'L\'Art du Batik',
    'about.art_text1':
        "Le batik est bien plus qu'une technique — c'est un langage. En appliquant la cire fondue sur le tissu avant chaque bain de teinture, l'artiste crée des réserves qui préservent la couleur originale du tissu, révélant à la fin un motif d'une complexité subtile.",
    'about.art_text2':
        "Olga Indigo a fait évoluer cette technique ancestrale en y intégrant des superpositions de cires, des pigments naturels issus de la flore béninoise et des tissus Aho — un textile traditionnel tissé à la main, particulièrement absorbant et vivant sous la teinture.",

    'about.step1_title': 'Application de la cire',
    'about.step1_text':
        'La cire chaude est appliquée au pinceau ou à la tjanting sur le tissu tendu. Elle pénètre les fibres et crée une barrière imperméable qui protégera la couleur lors du bain de teinture.',
    'about.step2_title': 'Bain de teinture',
    'about.step2_text':
        'Le tissu plonge dans des bains successifs de teintures naturelles — indigo, cola ou baobab. Chaque immersion ajoute une couche de couleur et de profondeur au motif.',
    'about.step3_title': 'Révélation du motif',
    'about.step3_text':
        'La cire est retirée à l\'eau bouillante, révélant le motif final. Les craquelures caractéristiques du batik — appelées "crackle" — sont la signature unique de cette technique.',

    'about.dyes_title': 'Les Teintures Naturelles',
    'about.indigo_title': "L'Indigo",
    'about.indigo_text':
        "Obtenu à partir des feuilles de l'indigotier, l'indigo est la couleur reine du batik béninois. Sa profondeur bleutée, du ciel à la nuit, en fait le pigment de prédilection d'Olga.",
    'about.cola_title': 'La Cola',
    'about.cola_text':
        "La noix de cola offre des teintes chaudes allant du brun doré à l'acajou profond. Associée à l'indigo, elle crée des harmonies chromatiques d'une richesse rare.",
    'about.baobab_title': 'Le Baobab',
    'about.baobab_text':
        "L'écorce et les feuilles du baobab donnent des jaunes dorés et des ocres lumineux. Symbole de l'Afrique, l'arbre nourrit autant l'artiste que ses créations.",
    'about.teck_title': 'Le Teck',
    'about.teck_text':
        "Le bois de teck produit des teintes profondes, du rouge brique au brun chocolat. Utilisé en infusion, il apporte des nuances chaudes et enveloppantes aux tissus.",

    'about.timeline_title': 'Chronologie',
    'about.timeline_year1': '1975',
    'about.timeline_title1': 'Naissance à Bohicon',
    'about.timeline_desc1':
        "Olga naît à Bohicon, ville historique du Bénin, héritière d'une lignée liée au Royaume du Dahomey. Sa grand-mère lui transmet dès l'enfance les techniques de teinture à l'indigo.",
    'about.timeline_year2': '2000',
    'about.timeline_title2': 'Expositions en Afrique de l\'Ouest',
    'about.timeline_desc2':
        "Début des expositions au Festival sur le Niger (Ségou, Mali) et dans plusieurs galeries de Bamako et Ouagadougou. Son style unique commence à se faire connaître sur le continent.",
    'about.timeline_year3': '2008',
    'about.timeline_title3': 'Reconnaissance internationale',
    'about.timeline_desc3':
        "Exposition « AHO du Bénin » à Berlin et Paris. Olga Indigo porte le batik béninois sur la scène internationale et est remarquée par la galerie parisienne Anne de Villepoix.",
    'about.timeline_year4': '2023',
    'about.timeline_title4': 'FINAB & Biennale de Dakar',
    'about.timeline_desc4':
        "Participation aux premières éditions du FINAB (Festival International des Arts du Bénin) à Cotonou. Présence remarquée à la Biennale de l'Art Africain Contemporain de Dakar 2026.",

    'about.stat_aho': '30+',
    'about.stat_aho_label': 'Ans de création artistique',
    'about.stat_dyes': '4',
    'about.stat_dyes_label': 'Teintures naturelles maîtrisées',
    'about.stat_handmade': '100%',
    'about.stat_handmade_label': 'Œuvres faites à la main',
    'about.stat_heritage': '400',
    'about.stat_heritage_label': 'Ans d\'héritage Dahomey',

    'about.representation_title': 'Représentation',
    'about.representation_text': 'Galerie SAGA, France — www.galeriesaga.com',

    // ── Contact ───────────────────────────────────────────────────────────────
    'contact.title': 'Contactez-nous',
    'contact.intro':
        "N'hésitez pas à nous écrire pour toute question, commande ou demande de projet.",
    'contact.available_now': 'Disponible maintenant · Répond sous 24h',
    'contact.whatsapp_cta': 'Écrire sur WhatsApp',
    'contact.email_cta': 'Envoyer un e-mail',
    'contact.info_title': 'Nos Coordonnées',
    'contact.label_address': 'ADRESSE',
    'contact.label_phone': 'TÉLÉPHONE',
    'contact.label_email': 'E-MAIL',
    'contact.follow': 'SUIVRE',
    'contact.response_time': 'Disponible Lun–Sam · 9h–18h\nRéponse sous 24h',
    'contact.copied': 'Copié dans le presse-papier',
    'contact.footer_note':
        'AZIZART · Cotonou, Bénin\nArt Batik Contemporain par Olga Indigo',

    // Formulaire
    'contact.form_title': 'Envoyer un message',
    'contact.form_subtitle': 'Tous les champs marqués * sont obligatoires',
    'contact.name': 'Nom complet *',
    'contact.email': 'Adresse e-mail *',
    'contact.phone': 'Téléphone (optionnel)',
    'contact.subject': 'Sujet *',
    'contact.message': 'Votre message *',
    'contact.message_hint': 'Décrivez votre projet, question ou demande…',
    'contact.send': 'Envoyer le message',
    'contact.privacy_note': 'Vos données ne sont jamais partagées.',
    'contact.field_required': 'Ce champ est obligatoire.',
    'contact.invalid_email': 'Adresse e-mail invalide.',
    'contact.success_msg': 'Message envoyé ! Nous vous répondrons sous 24h.',
    'contact.error_network': 'Erreur réseau. Vérifiez votre connexion.',
    'contact.error': 'Une erreur est survenue. Veuillez réessayer.',
  };

  // ════════════════════════════════════════════════════════════════════════════
  // ANGLAIS
  // ════════════════════════════════════════════════════════════════════════════
  static const Map<String, String> _en = {
    // ── Navigation ───────────────────────────────────────────────────────────
    'nav.home': 'Home',
    'nav.gallery': 'Gallery',
    'nav.atelier': 'Studio',
    'nav.media': 'Media',
    'nav.about': 'About',
    'nav.contact': 'Contact',

    // ── Home ─────────────────────────────────────────────────────────────────
    'home.tagline': 'The art of batik from Cotonou, Benin',
    'home.discover_gallery': 'Discover the gallery',
    'home.shop': 'Shop',
    'home.our_creations': 'Our creations',
    'home.original_paintings': 'Original paintings',
    'home.unique_pieces': 'Unique pieces',
    'home.paintings_desc':
        'Each canvas is a unique work, handcrafted with natural pigments and the ancestral wax-resist batik technique.',
    'home.artwear': 'Art to wear',
    'home.batik_clothing': 'Batik clothing',
    'home.custom_orders': 'Custom orders',
    'home.personalized_decor': 'Personalised decor',
    'home.workshop_tag': 'Craftsmanship',
    'home.workshop_title': 'Creating batik fabric',
    'home.workshop_desc':
        "In our Cotonou studio, each piece is born from a dialogue between wax, indigo and hand-woven Aho fabric. An ancestral process passed down through generations.",
    'home.workshop_cta': 'Discover the studio',
    'home.selection': 'Selection',
    'home.featured': 'Featured artworks',
    'home.view_all': 'View all',
    'home.no_artworks': 'No featured artworks at the moment.',
    'home.available': 'Available',
    'home.sold': 'Sold',
    'home.quote': 'Indigo is my mother tongue, wax my writing.',
    'home.explore_tag': 'Explore',
    'home.explore_title': 'The full gallery',
    'home.explore_subtitle':
        "Discover the complete works of Olga Indigo: paintings, clothing, fabrics and unique objects.",
    'home.view_full_gallery': 'View full gallery',
    'home.footer_cta_title': 'Got a project in mind?',
    'home.footer_cta_subtitle':
        'Custom orders, exhibitions, collaborations — let\'s talk.',
    'home.footer_email_btn': 'Send an email',
    'home.footer_tagline': 'Contemporary Batik Art · Cotonou, Benin',

    'home.about_tag': 'THE ARTIST',
    'home.about_title': 'Olga Indigo',
    'home.about_cta': 'Discover her journey',
    'home.follow_tag': 'FOLLOW US',
    'home.follow_title': 'Follow the\ncreative journey',
    'home.follow_subtitle':
        'Go behind the scenes of the studio, discover new creations and upcoming exhibitions across all our channels.',
    'home.follow_youtube_desc':
        'Batik demonstrations, creation process and video reports.',
    'home.follow_instagram_desc':
        'Studio photos, recent works and daily updates.',
    'home.follow_tiktok_desc':
        'Short videos on batik, natural dyeing and textile art.',
    'home.follow_facebook_desc':
        'Events, exhibitions and news from the AZIZART gallery.',

    // ── Gallery ───────────────────────────────────────────────────────────────
    'gallery.title': 'GALLERY',
    'gallery.original_works': 'Original Works',
    'gallery.batik_description':
        'BATIK ON FABRIC · NATURAL DYES · BENINESE CRAFTSMANSHIP',
    'gallery.all': 'All',
    'gallery.available_filter': 'Available',
    'gallery.sold_filter': 'Sold',
    'gallery.artworks_count': 'ARTWORK',
    'gallery.available': 'Available',
    'gallery.sold': 'Sold',
    'gallery.discover': 'DISCOVER',
    'gallery.close': 'Close',
    'gallery.dimensions': 'Dimensions',
    'gallery.year': 'Year',
    'gallery.technique': 'Technique',
    'gallery.available_for_purchase': 'Available for acquisition',
    'gallery.sold_out': 'Artwork sold',
    'gallery.no_artworks': 'No artworks in this category.',
    'gallery.indigo_atelier': 'ATELIER OLGA INDIGO · COTONOU',

    // ── Studio ────────────────────────────────────────────────────────────────
    'atelier.title': 'THE STUDIO',
    'atelier.banner_subtitle': 'Where batik art is born',
    'atelier.gallery_title': 'THE GALLERY',
    'atelier.gallery_subtitle': 'Moments of creation',
    'atelier.our_atelier': 'Our studio',
    'atelier.our_atelier_desc':
        "In the heart of Cotonou, Olga Indigo's studio is a living space where tradition and creation meet every day. Natural light, dye vats and the scent of hot wax create a unique atmosphere.",
    'atelier.philosophy': 'Our philosophy',
    'atelier.philosophy_desc':
        "Every piece is made by hand, respecting the ancestral techniques of Beninese batik. We use exclusively natural dyes — indigo, cola, baobab, teak — to preserve vernacular knowledge and the environment.",
    'atelier.contact_cta': 'CONTACT US',
    'atelier.years_exp': 'Years of experience',
    'atelier.works_created': 'Works created',
    'atelier.natural_dyes': 'Natural dyes',
    'atelier.generations': 'Generations of transmission',
    'atelier.visit_title': 'Visit our studio',
    'atelier.visit_desc':
        'Come discover the creative process live, meet Olga Indigo and perhaps leave with a unique piece.',
    'atelier.book_appointment': 'BOOK AN APPOINTMENT',

    // ── Media ─────────────────────────────────────────────────────────────────
    'media.banner_title': 'MEDIA',
    'media.banner_subtitle': 'Videos, Reports & News',
    'media.filter_all': 'All',
    'media.filter_videos': 'Videos',
    'media.filter_reportages': 'Reports',
    'media.filter_news': 'News',
    'media.watch_now': 'Watch now →',
    'media.click_to_watch': 'Click to watch',
    'media.no_media': 'No media in this category',
    'media.add_media_hint':
        'Media can be added from the administration interface.',
    'media.indigo_atelier': 'ATELIER OLGA INDIGO · COTONOU, BENIN',

    // ── About ─────────────────────────────────────────────────────────────────
    'about.title': 'ABOUT',
    'about.name': 'Olga Indigo',
    'about.heritage': 'Batik Artist · Heir to Dahomey',
    'about.heritage_badge': 'Heir to the Kingdom of Dahomey',

    'about.intro_title': 'An artist rooted in history',
    'about.intro_text':
        "Born 1 January 1975 in Bohicon, Olga Indigo is a visual artist whose work stands at the intersection of painting, textile art and natural dyeing. Heir to a lineage connected to the ancient Kingdom of Dahomey, she has spent over thirty years building a body of work grounded in organic pigments and hand-woven Aho fabrics.",
    'about.intro_text2':
        "Her research focuses on collective memory, feminine legacies, African cosmologies and the transmission of vernacular knowledge. Her work is represented by Galerie SAGA in France.",

    'about.origins_title': 'Origins & Journey',
    'about.origins_text1':
        "Bohicon, Benin's crossroads city steeped in the history of the Kingdom of Dahomey — it is here that Olga Indigo grew up surrounded by women weavers and dyers. Her grandmother passed on the secrets of indigo to her in childhood, laying the foundations of an exceptional artistic vocation.",
    'about.origins_text2':
        "After years of training with master craftsmen in Benin and Mali, Olga settled in Cotonou where she opened her studio. Since then she has exhibited across West Africa and Europe, and has participated in major contemporary African art biennials.",

    'about.grandma_quote':
        'Indigo never lies. It reveals what the fabric has always known.',
    'about.grandma_author': "OLGA'S GRANDMOTHER · BOHICON, 1985",

    'about.art_title': 'The Art of Batik',
    'about.art_text1':
        "Batik is far more than a technique — it is a language. By applying molten wax to fabric before each dye bath, the artist creates resists that preserve the original colour of the cloth, ultimately revealing a pattern of subtle complexity.",
    'about.art_text2':
        "Olga Indigo has evolved this ancestral technique by integrating wax layering, natural pigments from Beninese flora and Aho fabrics — a traditional hand-woven textile that is particularly absorbent and vibrant under dye.",

    'about.step1_title': 'Wax application',
    'about.step1_text':
        'Hot wax is applied with a brush or tjanting onto stretched fabric. It penetrates the fibres and creates a waterproof barrier that will protect the colour during the dye bath.',
    'about.step2_title': 'Dye bath',
    'about.step2_text':
        'The fabric is immersed in successive baths of natural dyes — indigo, cola or baobab. Each immersion adds a layer of colour and depth to the pattern.',
    'about.step3_title': 'Pattern reveal',
    'about.step3_text':
        'The wax is removed in boiling water, revealing the final pattern. The characteristic cracks of batik — known as "crackle" — are the unique signature of this technique.',

    'about.dyes_title': 'Natural Dyes',
    'about.indigo_title': 'Indigo',
    'about.indigo_text':
        "Obtained from the leaves of the indigo plant, indigo is the queen colour of Beninese batik. Its deep blue tones, from sky to night, make it Olga's pigment of choice.",
    'about.cola_title': 'Cola Nut',
    'about.cola_text':
        "The cola nut offers warm tones ranging from golden brown to deep mahogany. Combined with indigo, it creates chromatic harmonies of rare richness.",
    'about.baobab_title': 'Baobab',
    'about.baobab_text':
        "The bark and leaves of the baobab yield golden yellows and luminous ochres. A symbol of Africa, the tree nourishes both the artist and her creations.",
    'about.teck_title': 'Teak',
    'about.teck_text':
        "Teak wood produces deep tones, from brick red to chocolate brown. Used as an infusion, it brings warm, enveloping nuances to the fabrics.",

    'about.timeline_title': 'Timeline',
    'about.timeline_year1': '1975',
    'about.timeline_title1': 'Born in Bohicon',
    'about.timeline_desc1':
        "Olga is born in Bohicon, a historic city of Benin, heir to a lineage connected to the Kingdom of Dahomey. Her grandmother passes on indigo dyeing techniques to her in childhood.",
    'about.timeline_year2': '2000',
    'about.timeline_title2': 'Exhibitions in West Africa',
    'about.timeline_desc2':
        "First exhibitions at the Festival sur le Niger (Ségou, Mali) and in several galleries in Bamako and Ouagadougou. Her unique style begins to gain recognition across the continent.",
    'about.timeline_year3': '2008',
    'about.timeline_title3': 'International recognition',
    'about.timeline_desc3':
        "The 'AHO du Bénin' exhibition in Berlin and Paris. Olga Indigo brings Beninese batik to the international stage and is noticed by Paris gallery Anne de Villepoix.",
    'about.timeline_year4': '2023',
    'about.timeline_title4': 'FINAB & Dakar Biennale',
    'about.timeline_desc4':
        "Participation in the first editions of FINAB (International Festival of Beninese Arts) in Cotonou. Notable presence at the Contemporary African Art Biennale in Dakar 2026.",

    'about.stat_aho': '30+',
    'about.stat_aho_label': 'Years of artistic creation',
    'about.stat_dyes': '4',
    'about.stat_dyes_label': 'Natural dyes mastered',
    'about.stat_handmade': '100%',
    'about.stat_handmade_label': 'Handmade works',
    'about.stat_heritage': '400',
    'about.stat_heritage_label': 'Years of Dahomey heritage',

    'about.representation_title': 'Representation',
    'about.representation_text': 'Galerie SAGA, France — www.galeriesaga.com',

    // ── Contact ───────────────────────────────────────────────────────────────
    'contact.title': 'Contact Us',
    'contact.intro':
        'Feel free to reach out with any questions, orders or project inquiries.',
    'contact.available_now': 'Available now · Replies within 24h',
    'contact.whatsapp_cta': 'Write on WhatsApp',
    'contact.email_cta': 'Send an email',
    'contact.info_title': 'Our Contact Info',
    'contact.label_address': 'ADDRESS',
    'contact.label_phone': 'PHONE',
    'contact.label_email': 'EMAIL',
    'contact.follow': 'FOLLOW',
    'contact.response_time': 'Available Mon–Sat · 9am–6pm\nReplies within 24h',
    'contact.copied': 'Copied to clipboard',
    'contact.footer_note':
        'AZIZART · Cotonou, Benin\nContemporary Batik Art by Olga Indigo',

    // Form
    'contact.form_title': 'Send a message',
    'contact.form_subtitle': 'All fields marked * are required',
    'contact.name': 'Full name *',
    'contact.email': 'Email address *',
    'contact.phone': 'Phone (optional)',
    'contact.subject': 'Subject *',
    'contact.message': 'Your message *',
    'contact.message_hint': 'Describe your project, question or request…',
    'contact.send': 'Send message',
    'contact.privacy_note': 'Your data is never shared.',
    'contact.field_required': 'This field is required.',
    'contact.invalid_email': 'Invalid email address.',
    'contact.success_msg': 'Message sent! We will reply within 24h.',
    'contact.error_network': 'Network error. Check your connection.',
    'contact.error': 'An error occurred. Please try again.',
  };
}

// ══════════════════════════════════════════════════════════════════════════════
// Extension BuildContext — context.tr('key') avec rebuild automatique
// ══════════════════════════════════════════════════════════════════════════════
extension LanguageProviderExtension on BuildContext {
  /// Retourne la traduction de [key] et s'abonne aux changements de locale.
  /// Tout widget qui appelle context.tr() est rebuilté automatiquement
  /// quand l'utilisateur bascule FR ↔ EN — sans aucun délai.
  String tr(String key) {
    return watch<LanguageProvider>().tr(key);
  }
}
