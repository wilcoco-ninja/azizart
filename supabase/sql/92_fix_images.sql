-- ============================================================================
-- 92 — ALIGNEMENT DES IMAGES SUR LE CONTENU RÉEL DU BUCKET R2 (azizart-media)
-- Dépend de : 04, 91. Idempotent.
-- ============================================================================

-- 1. Œuvres du seed dont le fichier n'existe pas dans R2 (erreur 404)
DELETE FROM public.artworks
WHERE image_path IN (
    'gallery/1790210806847_532682291.jpeg',
    'gallery/1790211025391_114211990.jpeg',
    'gallery/1790211315530_292778744.jpeg',
    'gallery/gallery0.jpeg',
    'gallery/gallery2.jpeg',
    'gallery/gallery3.jpeg',
    'gallery/gallery5.jpeg',
    'gallery/gallery7.jpeg',
    'gallery/vedette0.jpeg',
    'gallery/vedette1.jpeg',
    'gallery/vedette2.jpeg',
    'gallery/vedette3.jpeg'
);

-- 2. Images de galerie présentes dans R2 mais sans ligne en base
--    (titres provisoires : à renommer depuis l'admin)
INSERT INTO public.artworks
    (title_fr, title_en, image_path, category, technique,
     featured, status, is_published, created_at)
SELECT v.title_fr, v.title_en, v.image_path, 'tableaux', '',
       FALSE, 'available', TRUE, NOW() - make_interval(mins => v.n)
FROM (VALUES
    (0, 'Création 1', 'Creation 1', 'gallery/hmvehzjspc.jpg'),
    (1, 'Création 2', 'Creation 2', 'gallery/hmvf10579s.jpg'),
    (2, 'Création 3', 'Creation 3', 'gallery/hmvf1l6nsg.jpg'),
    (3, 'Création 4', 'Creation 4', 'gallery/hmvf27ijls.jpg')
) AS v(n, title_fr, title_en, image_path)
WHERE NOT EXISTS (
    SELECT 1 FROM public.artworks a WHERE a.image_path = v.image_path
);

-- 3. Photos d'atelier du seed : aucun des 5 fichiers n'existe dans R2
DELETE FROM public.atelier_photos
WHERE image_path IN (
    'atelier/1790209345206_52918918.jpeg',
    'atelier/1790211653846_73970587.jpeg',
    'atelier/1790211683043_138929819.jpeg',
    'atelier/1790211744085_156027354.jpeg',
    'atelier/1790211828342_248435931.jpeg'
);

-- 4. Photos d'atelier présentes dans R2 (ordre chronologique d'envoi)
INSERT INTO public.atelier_photos
    (image_path, title_fr, title_en, sort_order, is_published)
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
WHERE NOT EXISTS (
    SELECT 1 FROM public.atelier_photos p WHERE p.image_path = v.image_path
);

-- 5. Contrôle.  Attendu : artworks = 9 (dont 2 vedettes), atelier_photos = 7
SELECT 'artworks' AS t, count(*) AS total,
       count(*) FILTER (WHERE featured) AS vedettes
FROM public.artworks
UNION ALL
SELECT 'atelier_photos', count(*), NULL FROM public.atelier_photos;