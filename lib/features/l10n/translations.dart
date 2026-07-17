// ══════════════════════════════════════════════════════════════════════════════
// Translations — Système i18n FR / EN pour AZIZART
// Usage : T.get('clé')  →  retourne la chaîne dans la locale courante
// ══════════════════════════════════════════════════════════════════════════════
class T {
  T._();

  // Locale active (modifiée par LocaleService)
  static String _currentLocale = 'fr';

  static void setLocale(String code) {
    if (supported.containsKey(code)) _currentLocale = code;
  }

  static String get currentLocale => _currentLocale;

  /// Retourne la traduction de [key] dans la locale courante.
  /// Replie sur le français si la clé est absente dans la locale demandée.
  static String get(String key) {
    return supported[_currentLocale]?[key] ?? supported['fr']?[key] ?? key;
  }

  // ── Dictionnaires ──────────────────────────────────────────────────────────
  static const Map<String, Map<String, String>> supported = {
    'fr': _fr,
    'en': _en,
  };

  // ── Français ───────────────────────────────────────────────────────────────
  static const Map<String, String> _fr = {
    // Navigation
    'nav_home': 'Accueil',
    'nav_gallery': 'Galerie',
    'nav_atelier': 'Atelier',
    'nav_media': 'Médias',
    'nav_about': 'À propos',
    'nav_contact': 'Contact',

    // Page d'accueil
    'home_hero_title': 'AZIZART',
    'home_hero_subtitle': 'L\'art du batik — Olga Indigo',
    'home_hero_cta': 'Découvrir la galerie',
    'home_featured': 'Œuvres à la une',
    'home_see_all': 'Voir toute la galerie',
    'home_about_title': 'L\'Artiste',
    'home_contact_cta': 'Prendre contact',

    // Galerie
    'gallery_title': 'Galerie',
    'gallery_all': 'Tout',
    'gallery_available': 'Disponibles',
    'gallery_sold': 'Vendues',
    'gallery_available_badge': 'Disponible',
    'gallery_sold_badge': 'Vendue',
    'gallery_price_on_request': 'Prix sur demande',
    'gallery_contact': 'Contacter pour acquérir',
    'gallery_empty': 'Aucune œuvre dans cette catégorie.',
    'gallery_dimensions': 'Dimensions',
    'gallery_year': 'Année',
    'gallery_technique': 'Technique',
    'gallery_category': 'Catégorie',

    // Atelier
    'atelier_title': 'L\'Atelier',
    'atelier_subtitle': 'Découvrez le processus créatif',
    'atelier_intro': 'Un espace de création et de transmission',
    'atelier_description': 'Au cœur de Cotonou, l\'atelier d\'Olga Indigo est '
        'un lieu vivant où la tradition du batik rencontre la création contemporaine.',
    'atelier_cta': 'Visiter l\'atelier',
    'atelier_contact_cta': 'Réserver une visite',

    // Médias
    'media_title': 'Médias',
    'media_subtitle': 'Vidéos, reportages et actualités',
    'media_all': 'Tous',
    'media_videos': 'Vidéos',
    'media_reportages': 'Reportages',
    'media_news': 'Actualités',
    'media_watch': 'Regarder',
    'media_read': 'Lire',
    'media_source': 'Source',

    // À propos
    'about_title': 'À propos',
    'about_biography': 'Biographie',
    'about_exhibitions': 'Expositions',
    'about_techniques': 'Techniques',
    'about_awards': 'Distinctions',
    'about_artist_quote':
        '"L\'indigo est ma langue maternelle, la cire mon écriture."',
    // Données biographiques issues du CV officiel (Biennale Dakar 2026)
    'about_born': 'Née le 1er janvier 1975 à Bohicon (Bénin)',
    'about_heritage_note':
        'Héritière d\'une lignée liée au Royaume du Dahomey (1600–1904)',
    'about_representation': 'Galerie SAGA, France — www.galeriesaga.com',
    'about_years_active': '30+ ans de création',

    // Section artiste — home page (_ArtistPreviewSection)
    'home.about_tag': 'L\'ARTISTE',
    'home.about_title': 'Olga Indigo',
    'home.about_cta': 'Découvrir son parcours',

    // Section atelier — home page (_WorkshopSection)
    'home.workshop_tag': 'ATELIER',
    'home.workshop_title': 'L\'art du batik,\ngeste après geste',
    'home.workshop_desc':
        'Dans l\'atelier de Cotonou, chaque toile naît d\'un dialogue entre '
            'la cire, le pigment et le tissu Aho tissé à la main. Un savoir-faire '
            'transmis sur trois générations.',
    'home.workshop_cta': 'VISITER L\'ATELIER',

    // Contact (Mise à jour et ajouts)
    'contact_title': 'Contactez-nous',
    'contact_subtitle': 'Prenons contact',
    'contact_intro':
        'N\'hésitez pas à nous écrire pour toute question ou demande de projet.',
    'contact_info_title': 'Nos Coordonnées',
    'contact_info': 'Informations',
    'contact_loc': 'Localisation',
    'contact_loc_v': 'Cotonou, Bénin',
    'contact_avail': 'Disponibilité',
    'contact_avail_v': 'Lun – Sam : 9h – 18h',
    'contact_follow_us': 'Suivez-nous',
    'contact_follow': 'SUIVRE',

    // Champs du formulaire
    'contact_name': 'Nom complet',
    'contact_email': 'Adresse e-mail',
    'contact_phone': 'Numéro de téléphone (Optionnel)',
    'contact_subject': 'Sujet',
    'contact_message': 'Votre message',
    'contact_send': 'Envoyer le message',

    // Validations du formulaire
    'contact_name_required': 'Veuillez renseigner votre nom complet.',
    'contact_email_required': 'Veuillez renseigner une adresse e-mail valide.',
    'contact_subject_required': 'Veuillez indiquer le sujet de votre message.',
    'contact_message_required':
        'Veuillez écrire votre message avant d\'envoyer.',

    // Retours d'action
    'contact_success': 'Votre message a été envoyé avec succès !',
    'contact_error':
        'Une erreur est survenue. Veuillez vérifier les champs obligatoires.',
    'contact_quote':
        '"Chaque fil, chaque couleur est un mot dans ma poésie textile."',
  };

  // ── Anglais ────────────────────────────────────────────────────────────────
  static const Map<String, String> _en = {
    // Navigation
    'nav_home': 'Home',
    'nav_gallery': 'Gallery',
    'nav_atelier': 'Studio',
    'nav_media': 'Media',
    'nav_about': 'About',
    'nav_contact': 'Contact',

    // Home page
    'home_hero_title': 'AZIZART',
    'home_hero_subtitle': 'The art of batik — Olga Indigo',
    'home_hero_cta': 'Discover the gallery',
    'home_featured': 'Featured artworks',
    'home_see_all': 'View full gallery',
    'home_about_title': 'The Artist',
    'home_contact_cta': 'Get in touch',

    // Gallery
    'gallery_title': 'Gallery',
    'gallery_all': 'All',
    'gallery_available': 'Available',
    'gallery_sold': 'Sold',
    'gallery_available_badge': 'Available',
    'gallery_sold_badge': 'Sold',
    'gallery_price_on_request': 'Price on request',
    'gallery_contact': 'Contact to acquire',
    'gallery_empty': 'No artworks in this category.',
    'gallery_dimensions': 'Dimensions',
    'gallery_year': 'Year',
    'gallery_technique': 'Technique',
    'gallery_category': 'Category',

    // Studio
    'atelier_title': 'The Studio',
    'atelier_subtitle': 'Discover the creative process',
    'atelier_intro': 'A space for creation and sharing',
    'atelier_description': 'At the heart of Cotonou, Olga Indigo\'s studio is '
        'a living space where the tradition of batik meets contemporary creation.',
    'atelier_cta': 'Visit the studio',
    'atelier_contact_cta': 'Book a visit',

    // Media
    'media_title': 'Media',
    'media_subtitle': 'Videos, reports and news',
    'media_all': 'All',
    'media_videos': 'Videos',
    'media_reportages': 'Reports',
    'media_news': 'News',
    'media_watch': 'Watch',
    'media_read': 'Read',
    'media_source': 'Source',

    // About
    'about_title': 'About',
    'about_biography': 'Biography',
    'about_exhibitions': 'Exhibitions',
    'about_techniques': 'Techniques',
    'about_awards': 'Awards',
    'about_artist_quote': '"Indigo is my mother tongue, wax my writing."',
    // Biographical data from official CV (Dakar Biennale 2026)
    'about_born': 'Born 1 January 1975 in Bohicon, Benin',
    'about_heritage_note':
        'Heir to a lineage connected to the Kingdom of Dahomey (1600–1904)',
    'about_representation': 'Galerie SAGA, France — www.galeriesaga.com',
    'about_years_active': '30+ years of creation',

    // Artist section — home page (_ArtistPreviewSection)
    'home.about_tag': 'THE ARTIST',
    'home.about_title': 'Olga Indigo',
    'home.about_cta': 'Discover her journey',

    // Workshop section — home page (_WorkshopSection)
    'home.workshop_tag': 'STUDIO',
    'home.workshop_title': 'The art of batik,\none gesture at a time',
    'home.workshop_desc':
        'In the Cotonou studio, every canvas is born from a dialogue between '
            'wax, pigment, and hand-woven Aho cloth — a craft passed down across '
            'three generations.',
    'home.workshop_cta': 'VISIT THE STUDIO',

    // Contact (Mise à jour et ajouts)
    'contact_title': 'Contact Us',
    'contact_subtitle': 'Get in touch',
    'contact_intro':
        'Feel free to reach out with any questions or project inquiries.',
    'contact_info_title': 'Our Contact Info',
    'contact_info': 'Information',
    'contact_loc': 'Location',
    'contact_loc_v': 'Cotonou, Benin',
    'contact_avail': 'Availability',
    'contact_avail_v': 'Mon – Sat : 9am – 6pm',
    'contact_follow_us': 'Follow Us',
    'contact_follow': 'FOLLOW',

    // Champs du formulaire
    'contact_name': 'Full Name',
    'contact_email': 'Email Address',
    'contact_phone': 'Phone Number (Optional)',
    'contact_subject': 'Subject',
    'contact_message': 'Your Message',
    'contact_send': 'Send Message',

    // Validations du formulaire
    'contact_name_required': 'Please enter your full name.',
    'contact_email_required': 'Please enter a valid email address.',
    'contact_subject_required': 'Please provide a subject for your message.',
    'contact_message_required': 'Please write your message before sending.',

    // Retours d'action
    'contact_success': 'Your message has been sent successfully!',
    'contact_error': 'An error occurred. Please check the required fields.',
    'contact_quote':
        '"Every thread, every colour is a word in my textile poetry."',
  };
}
