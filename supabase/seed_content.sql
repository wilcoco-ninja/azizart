-- ============================================================================
-- AZIZART COLORS — contenu initial (artworks + atelier_photos)
-- Idempotent : ne réinsère pas une image déjà présente (clé image_path).
-- À exécuter dans le SQL Editor de Supabase.
-- ============================================================================

-- 1. Colonnes utilisées par ce script (sans effet si elles existent déjà)
ALTER TABLE public.artworks
    ADD COLUMN IF NOT EXISTS title_fr     TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en     TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS image_path   TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS category     TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS technique    TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS featured     BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS status       TEXT NOT NULL DEFAULT 'available',
    ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.atelier_photos
    ADD COLUMN IF NOT EXISTS image_path   TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_fr     TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en     TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS sort_order   INTEGER NOT NULL DEFAULT 99,
    ADD COLUMN IF NOT EXISTS is_published BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 2. Œuvres de la galerie (dossier gallery/)
--    `n` fixe l'ordre d'affichage : le site trie par date de création décroissante.
INSERT INTO public.artworks
    (title_fr, title_en, image_path, category, technique,
     featured, status, is_published, created_at)
SELECT v.title_fr, v.title_en, v.image_path, v.category, v.technique,
       v.featured, 'available', TRUE, NOW() - make_interval(mins => v.n)
FROM (VALUES
    (1,  'Composition Indigo 1790',   'Indigo Composition 1790',  'gallery/1790210806847_532682291.jpeg', 'tableaux',       'Batik sur coton',      FALSE),
    (2,  'Motif Nuance 2110',         'Shade Pattern 2110',       'gallery/1790211025391_114211990.jpeg', 'tissu pagne',    'Teinture artisanale',  FALSE),
    (3,  'Batik Création 2113',       'Batik Creation 2113',      'gallery/1790211315530_292778744.jpeg', 'tableaux',       'Batik ancestral',      FALSE),
    (4,  'Galerie Batik 0',           'Gallery Batik 0',          'gallery/gallery0.jpeg',                'tableaux',       'Batik',                FALSE),
    (5,  'Tissu Pagne Indigo 1',      'Indigo Fabric 1',          'gallery/gallery1.jpeg',                'tissu pagne',    'Teinture à l''indigo', FALSE),
    (6,  'Nappe de Table Signée 2',   'Signature Tablecloth 2',   'gallery/gallery2.jpeg',                'nappe de table', 'Broderie & Teinture',  FALSE),
    (7,  'Tenue Traditionnelle 3',    'Traditional Outfit 3',     'gallery/gallery3.jpeg',                'vêtements',      'Couture sur mesure',   FALSE),
    (8,  'Accessoire Décoratif 4',    'Decorative Accessory 4',   'gallery/gallery4.jpeg',                'objets',         'Artisanat',            FALSE),
    (9,  'Tableau Mural 5',           'Wall Painting 5',          'gallery/gallery5.jpeg',                'tableaux',       'Peinture Indigo',      FALSE),
    (10, 'Pagne Motif Floral 6',      'Floral Pattern Fabric 6',  'gallery/gallery6.jpeg',                'tissu pagne',    'Teinture artisanale',  FALSE),
    (11, 'Vêtement d''Art 7',         'Art Clothing 7',           'gallery/gallery7.jpeg',                'vêtements',      'Indigo & Coton',       FALSE),
    (12, 'Chef-d''œuvre Vedette 0',   'Featured Masterpiece 0',   'gallery/vedette0.jpeg',                'tableaux',       'Batik d''exception',   TRUE),
    (13, 'Création Vedette 1',        'Featured Creation 1',      'gallery/vedette1.jpeg',                'tableaux',       '',                     TRUE),
    (14, 'Collection Prestige 2',     'Prestige Collection 2',    'gallery/vedette2.jpeg',                'vêtements',      '',                     TRUE),
    (15, 'Pagne d''Élite 3',          'Elite Fabric 3',           'gallery/vedette3.jpeg',                'tissu pagne',    '',                     TRUE),
    (16, 'Linge de Table d''Art 4',   'Art Tableware 4',          'gallery/vedette4.jpeg',                'nappe de table', '',                     TRUE),
    (17, 'Objet de Collection 5',     'Collector Object 5',       'gallery/vedette5.jpeg',                'objets',         '',                     TRUE)
) AS v(n, title_fr, title_en, image_path, category, technique, featured)
WHERE NOT EXISTS (
    SELECT 1 FROM public.artworks a WHERE a.image_path = v.image_path
);

-- 3. Photos de l'atelier (dossier atelier/)
INSERT INTO public.atelier_photos
    (image_path, title_fr, title_en, sort_order, is_published)
SELECT v.image_path, v.title_fr, v.title_en, v.sort_order, TRUE
FROM (VALUES
    ('atelier/1790209345206_52918918.jpeg',  'Atelier - Image 1', 'Workshop - Image 1', 1),
    ('atelier/1790211653846_73970587.jpeg',  'Atelier - Image 2', 'Workshop - Image 2', 2),
    ('atelier/1790211683043_138929819.jpeg', 'Atelier - Image 3', 'Workshop - Image 3', 3),
    ('atelier/1790211744085_156027354.jpeg', 'Atelier - Image 4', 'Workshop - Image 4', 4),
    ('atelier/1790211828342_248435931.jpeg', 'Atelier - Image 5', 'Workshop - Image 5', 5)
) AS v(image_path, title_fr, title_en, sort_order)
WHERE NOT EXISTS (
    SELECT 1 FROM public.atelier_photos p WHERE p.image_path = v.image_path
);

-- 4. Contrôle
SELECT 'artworks' AS t, count(*) AS total,
       count(*) FILTER (WHERE featured) AS vedettes
FROM public.artworks
UNION ALL
SELECT 'atelier_photos', count(*), NULL FROM public.atelier_photos;