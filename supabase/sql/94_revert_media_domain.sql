-- ============================================================================
-- 94 — Retour de media.azizart.com vers l'adresse r2.dev (sans effet si le
--      script 93 n'a jamais été exécuté)
-- ============================================================================

DO $$
DECLARE
    old_base TEXT := 'https://media.azizart.com';
    new_base TEXT := 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev';
    pair     TEXT[];
    n        BIGINT;
BEGIN
    FOREACH pair SLICE 1 IN ARRAY ARRAY[
        ARRAY['artworks',       'image_url'],
        ARRAY['artworks',       'image_path'],
        ARRAY['atelier_photos', 'image_url'],
        ARRAY['atelier_photos', 'image_path'],
        ARRAY['media_items',    'thumbnail_url'],
        ARRAY['media_items',    'thumbnail_path'],
        ARRAY['media_items',    'url'],
        ARRAY['home_events',    'image_url'],
        ARRAY['about_content',  'avatar_path'],
        ARRAY['about_content',  'avatar_url'],
        ARRAY['about_content',  'banner_url']
    ]
    LOOP
        IF EXISTS (
            SELECT 1
              FROM information_schema.columns
             WHERE table_schema = 'public'
               AND table_name   = pair[1]
               AND column_name  = pair[2]
        ) THEN
            EXECUTE format(
                'UPDATE public.%I SET %I = replace(%I, %L, %L) WHERE %I LIKE %L',
                pair[1], pair[2], pair[2], old_base, new_base,
                pair[2], '%' || old_base || '%'
            );
            GET DIAGNOSTICS n = ROW_COUNT;
            RAISE NOTICE '%.% : % ligne(s) modifiée(s)', pair[1], pair[2], n;
        END IF;
    END LOOP;
END $$;