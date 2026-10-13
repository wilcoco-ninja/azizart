-- ============================================================================
-- 07 — ABOUT_CONTENT : colonnes éditables par l'admin (idempotent)
-- Dépend de : 01, 02
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.about_content (
    id         INTEGER PRIMARY KEY,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

DO $$
DECLARE
    c TEXT;
    l TEXT;
BEGIN
    -- Textes localisés
    FOREACH c IN ARRAY ARRAY[
        'hero_label', 'heritage_line', 'heritage_badge',
        'intro_title', 'intro_text', 'intro_text2',
        'origins_title', 'origins_text1', 'origins_text2',
        'quote', 'quote_author',
        'art_title', 'art_text1', 'art_text2',
        'dyes_title', 'timeline_title',
        'representation_title', 'representation_text',
        'location'
    ]
    LOOP
        FOREACH l IN ARRAY ARRAY['fr', 'en']
        LOOP
            EXECUTE format(
                'ALTER TABLE public.about_content ADD COLUMN IF NOT EXISTS %I TEXT NOT NULL DEFAULT ''''',
                c || '_' || l);
        END LOOP;
    END LOOP;

    -- Listes localisées (JSONB)
    FOREACH c IN ARRAY ARRAY[
        'technique_steps', 'natural_dyes', 'timeline_events',
        'stats', 'disciplines', 'custom_sections'
    ]
    LOOP
        FOREACH l IN ARRAY ARRAY['fr', 'en']
        LOOP
            EXECUTE format(
                'ALTER TABLE public.about_content ADD COLUMN IF NOT EXISTS %I JSONB',
                c || '_' || l);
        END LOOP;
    END LOOP;
END $$;

ALTER TABLE public.about_content
    ADD COLUMN IF NOT EXISTS artist_name       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS career_start_year INTEGER,
    ADD COLUMN IF NOT EXISTS avatar_path       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS avatar_url        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS banner_url        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS hidden_fields     JSONB NOT NULL DEFAULT '[]'::jsonb;

NOTIFY pgrst, 'reload schema';