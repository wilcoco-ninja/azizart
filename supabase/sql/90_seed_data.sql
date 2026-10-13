-- ============================================================================
-- 90 — DONNÉES DE DÉPART (galerie + atelier) alignées sur le bucket R2
-- Dépend de : 04. OPTIONNEL : à exécuter UNE SEULE FOIS sur une base vide.
-- Remplace les anciens 91 et 92 : seuls les fichiers réellement présents dans
-- le bucket azizart-media sont référencés (plus d'image en erreur 404).
-- Ne pas relancer ensuite : les œuvres supprimées depuis l'admin réapparaîtraient.
-- ============================================================================

-- Galerie : 9 œuvres dont 2 vedettes (titres provisoires, à renommer depuis l'admin)
INSERT INTO public.artworks
    (title_fr, title_en, image_path, category, technique, featured, status, is_published, created_at)
SELECT v.title_fr, v.title_en, v.image_path, v.category, v.technique, v.featured,
       'available', TRUE, NOW() - make_interval(mins => v.n)
FROM (VALUES
    (0,  'Création 1',              'Creation 1',            'gallery/hmvehzjspc.jpg',     'tableaux',       '',                     FALSE),
    (1,  'Création 2',              'Creation 2',            'gallery/hmvf10579s.jpg',     'tableaux',       '',                     FALSE),
    (2,  'Création 3',              'Creation 3',            'gallery/hmvf1l6nsg.jpg',     'tableaux',       '',                     FALSE),
    (3,  'Création 4',              'Creation 4',            'gallery/hmvf27ijls.jpg',     'tableaux',       '',                     FALSE),
    (5,  'Tissu Pagne Indigo 1',    'Indigo Fabric 1',       'gallery/gallery1.jpeg',      'tissu pagne',    'Teinture à l''indigo', FALSE),
    (8,  'Accessoire Décoratif 4',  'Decorative Accessory 4','gallery/gallery4.jpeg',      'objets',         'Artisanat',            FALSE),
    (10, 'Pagne Motif Floral 6',    'Floral Pattern Fabric 6','gallery/gallery6.jpeg',     'tissu pagne',    'Teinture artisanale',  FALSE),
    (16, 'Linge de Table d''Art 4', 'Art Tableware 4',       'gallery/vedette4.jpeg',      'nappe de table', '',                     TRUE),
    (17, 'Objet de Collection 5',   'Collector Object 5',    'gallery/vedette5.jpeg',      'objets',         '',                     TRUE)
) AS v(n, title_fr, title_en, image_path, category, technique, featured)
WHERE NOT EXISTS (SELECT 1 FROM public.artworks a WHERE a.image_path = v.image_path);

-- Atelier : 7 photos
INSERT INTO public.atelier_photos (image_path, title_fr, title_en, sort_order, is_published)
SELECT v.image_path, v.title_fr, v.title_en, v.sort_order, TRUE
FROM (VALUES
    ('atelier/hmvejpxlgw.jpg',                   'Atelier - Image 1', 'Workshop - Image 1', 1),
    ('atelier/hmvg5lay2w.jpg',                   'Atelier - Image 2', 'Workshop - Image 2', 2),
    ('atelier/hmvg6jkkko.jpg',                   'Atelier - Image 3', 'Workshop - Image 3', 3),
    ('atelier/hmvg79w4gg.jpg',                   'Atelier - Image 4', 'Workshop - Image 4', 4),
    ('atelier/hmy1fbm4z4.jpg',                   'Atelier - Image 5', 'Workshop - Image 5', 5),
    ('atelier/hmy1hdthyg.jpg',                   'Atelier - Image 6', 'Workshop - Image 6', 6),
    ('atelier/20261006_110950_wpe0s9_image.jpg', 'Atelier - Image 7', 'Workshop - Image 7', 7)
) AS v(image_path, title_fr, title_en, sort_order)
WHERE NOT EXISTS (SELECT 1 FROM public.atelier_photos p WHERE p.image_path = v.image_path);

-- Contrôle.  Attendu : artworks = 9 (dont 2 vedettes), atelier_photos = 7
SELECT 'artworks' AS table_name, count(*) AS total,
       count(*) FILTER (WHERE featured) AS vedettes
FROM public.artworks
UNION ALL
SELECT 'atelier_photos', count(*), NULL FROM public.atelier_photos;