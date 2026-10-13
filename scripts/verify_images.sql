-- ════════════════════════════════════════════════════════════════════════
-- Vérifie que chaque page stocke ses images dans le bon dossier R2.
-- À exécuter dans Supabase → SQL Editor (lecture seule, ne modifie rien).
-- Les correspondances table → dossier suivent admin_content_manager.dart :
--   gallery → artworks · atelier → atelier_photos · media → media_items
--   event → home_events · À propos → about_avatars / about_banners
-- ════════════════════════════════════════════════════════════════════════

-- 1. Répartition réelle par table et par dossier
WITH urls AS (
  SELECT 'artworks (galerie)'          AS page, 'gallery'       AS attendu, image_url     AS url FROM public.artworks
  UNION ALL SELECT 'atelier_photos (atelier)',   'atelier',       image_url     FROM public.atelier_photos
  UNION ALL SELECT 'home_events (événements)',   'home_events',   image_url     FROM public.home_events
  UNION ALL SELECT 'media_items (miniatures)',   'media',         thumbnail_url FROM public.media_items
  UNION ALL SELECT 'about_content (profil)',     'about_avatars', avatar_path   FROM public.about_content
  UNION ALL SELECT 'about_content (couverture)', 'about_banners', banner_url    FROM public.about_content
),
parsed AS (
  SELECT page, attendu,
         substring(url from '^https?://[^/]+/([^/?]+)/') AS dossier
  FROM urls
  WHERE url IS NOT NULL AND url <> ''
)
SELECT page,
       attendu                                   AS dossier_attendu,
       COALESCE(dossier, '(sans dossier)')       AS dossier_reel,
       COUNT(*)                                  AS nb,
       CASE WHEN dossier = attendu THEN '✅ conforme'
            ELSE '⚠️ à vérifier' END             AS statut
FROM parsed
GROUP BY page, attendu, dossier
ORDER BY page, nb DESC;

-- 2. Détail des lignes hors dossier attendu (50 max)
--    « storage » = ancien Supabase Storage ; un autre nom = dossier inattendu.
WITH urls AS (
  SELECT 'artworks' AS tbl, id::text AS id, 'gallery' AS attendu, image_url AS url FROM public.artworks
  UNION ALL SELECT 'atelier_photos', id::text, 'atelier',       image_url     FROM public.atelier_photos
  UNION ALL SELECT 'home_events',    id::text, 'home_events',   image_url     FROM public.home_events
  UNION ALL SELECT 'media_items',    id::text, 'media',         thumbnail_url FROM public.media_items
  UNION ALL SELECT 'about_content.avatar_path', id::text, 'about_avatars', avatar_path FROM public.about_content
  UNION ALL SELECT 'about_content.banner_url',  id::text, 'about_banners', banner_url  FROM public.about_content
)
SELECT tbl, id, attendu, url
FROM urls
WHERE url IS NOT NULL AND url <> ''
  AND COALESCE(substring(url from '^https?://[^/]+/([^/?]+)/'), '') <> attendu
LIMIT 50;