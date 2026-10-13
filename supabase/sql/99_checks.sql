-- ============================================================================
-- 99 — CONTRÔLES (lecture seule : ne modifie rien)
-- À lancer après les scripts 01 à 08 et à chaque doute sur la connexion.
-- ============================================================================

-- A. Comptes de connexion.
--    Attendu : vos comptes avec est_admin = true, un pseudo, email_coherent = true.
SELECT u.email,
       u.last_sign_in_at,
       (a.id IS NOT NULL)            AS est_admin,
       s.pseudo,
       (s.email = lower(u.email))    AS email_coherent
FROM auth.users u
LEFT JOIN public.admins         a ON a.id = u.id
LEFT JOIN public.admin_settings s ON s.id = u.id
ORDER BY u.created_at;

-- B. Tables du schéma public SANS sécurité RLS.  Attendu : 0 ligne.
SELECT c.relname AS table_sans_rls
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relkind = 'r' AND NOT c.relrowsecurity;

-- C. Droits des visiteurs anonymes.
--    Attendu : lecture (SELECT) sur le contenu public, INSERT sur messages,
--    et AUCUNE ligne pour admins / admin_settings.
SELECT table_name,
       string_agg(privilege_type, ', ' ORDER BY privilege_type) AS droits_anon
FROM information_schema.role_table_grants
WHERE table_schema = 'public' AND grantee = 'anon'
GROUP BY table_name
ORDER BY table_name;

-- D. Fonctions sensibles.  Attendu : toutes les colonnes à false.
SELECT has_function_privilege('anon', 'public.is_admin()',                   'EXECUTE') AS anon_is_admin,
       has_function_privilege('anon', 'public.add_admin(text,text)',         'EXECUTE') AS anon_add_admin,
       has_function_privilege('authenticated', 'public.add_admin(text,text)','EXECUTE') AS auth_add_admin,
       has_function_privilege('anon', 'public.remove_admin(text)',           'EXECUTE') AS anon_remove_admin;

-- E. Tables en temps réel.  Attendu : 6 tables.
SELECT tablename AS table_temps_reel
FROM pg_publication_tables
WHERE pubname = 'supabase_realtime' AND schemaname = 'public'
ORDER BY tablename;

-- F. Politiques RLS en place.
SELECT tablename, policyname, cmd, roles
FROM pg_policies
WHERE schemaname = 'public'
ORDER BY tablename, policyname;

-- G. Images : chemins en double.  Attendu : 0 ligne.
SELECT image_path, count(*) AS occurrences
FROM (
    SELECT image_path FROM public.artworks
    UNION ALL
    SELECT image_path FROM public.atelier_photos
) AS all_paths
WHERE image_path <> ''
GROUP BY image_path
HAVING count(*) > 1;

-- H. Œuvres ou photos sans aucune image.  Attendu : 0 ligne.
SELECT 'artworks' AS source, id, title_fr
FROM public.artworks
WHERE image_path = '' AND image_url = ''
UNION ALL
SELECT 'atelier_photos', id, title_fr
FROM public.atelier_photos
WHERE image_path = '' AND image_url = '';

-- I. Images de la page « À propos ».
--    Vides = la page utilise ses images R2 par défaut (about_banners/ et about_avatars/).
SELECT avatar_path, banner_url FROM public.about_content;