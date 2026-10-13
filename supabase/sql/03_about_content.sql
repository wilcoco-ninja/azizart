-- ============================================================================
-- 03 — PAGE « À PROPOS » (table à ligne unique : id = 1)
-- Dépend de : 01, 02. Idempotent.
--
-- Ce script remplace les anciens 03 et 07_about_content_columns : toutes les
-- colonnes de l'éditeur admin sont ici (y compris custom_sections).
-- `career_start_year` est un ENTIER optionnel : l'éditeur envoie NULL quand le
-- champ est vide.
-- ============================================================================

-- 3.1 Table de base ---------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.about_content (
    id         INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3.2 Colonnes fixes ---------------------------------------------------------
ALTER TABLE public.about_content
    ADD COLUMN IF NOT EXISTS artist_name       TEXT    NOT NULL DEFAULT 'Olga Indigo',
    ADD COLUMN IF NOT EXISTS career_start_year INTEGER,
    ADD COLUMN IF NOT EXISTS avatar_path       TEXT    NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS avatar_url        TEXT    NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS banner_url        TEXT    NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS hidden_fields     JSONB   NOT NULL DEFAULT '[]'::jsonb,
    -- Colonnes historiques conservées pour compatibilité avec l'ancien code
    ADD COLUMN IF NOT EXISTS artist_name_fr    TEXT             DEFAULT 'Olga Indigo',
    ADD COLUMN IF NOT EXISTS artist_name_en    TEXT             DEFAULT 'Olga Indigo',
    ADD COLUMN IF NOT EXISTS artist_title      TEXT             DEFAULT 'Artiste Peintre Batik',
    ADD COLUMN IF NOT EXISTS artist_title_fr   TEXT             DEFAULT 'Artiste Peintre Batik',
    ADD COLUMN IF NOT EXISTS artist_title_en   TEXT             DEFAULT 'Batik Painter & Artist',
    ADD COLUMN IF NOT EXISTS bio_fr            TEXT             DEFAULT '',
    ADD COLUMN IF NOT EXISTS bio_en            TEXT             DEFAULT '',
    ADD COLUMN IF NOT EXISTS philosophy_fr     TEXT             DEFAULT '',
    ADD COLUMN IF NOT EXISTS philosophy_en     TEXT             DEFAULT '',
    ADD COLUMN IF NOT EXISTS timeline_events   JSONB            DEFAULT '[]'::jsonb;

-- 3.3 Colonnes localisées (FR / EN) -------------------------------------------
DO $$
DECLARE
    c TEXT;
    l TEXT;
BEGIN
    -- Textes
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

    -- Listes (tableaux JSON)
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
            -- Anciennes bases : valeurs nulles remplacées par un tableau vide.
            EXECUTE format(
                'UPDATE public.about_content SET %1$I = ''[]''::jsonb WHERE %1$I IS NULL',
                c || '_' || l);
            EXECUTE format(
                'ALTER TABLE public.about_content ALTER COLUMN %I SET DEFAULT ''[]''::jsonb',
                c || '_' || l);
            EXECUTE format(
                'ALTER TABLE public.about_content ALTER COLUMN %I SET NOT NULL',
                c || '_' || l);
        END LOOP;
    END LOOP;
END $$;

-- 3.4 Conversion de career_start_year sur une ancienne base ------------------
-- (la colonne avait été créée en TEXT NOT NULL DEFAULT '').
DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = 'public'
          AND table_name   = 'about_content'
          AND column_name  = 'career_start_year'
          AND data_type   <> 'integer'
    ) THEN
        ALTER TABLE public.about_content ALTER COLUMN career_start_year DROP DEFAULT;
        ALTER TABLE public.about_content ALTER COLUMN career_start_year DROP NOT NULL;
        ALTER TABLE public.about_content
            ALTER COLUMN career_start_year TYPE INTEGER
            USING NULLIF(regexp_replace(career_start_year::text, '[^0-9]', '', 'g'), '')::INTEGER;
    END IF;
END $$;

-- 3.5 Intégrité : les colonnes de listes doivent contenir un tableau JSON ----
DO $$
DECLARE
    c TEXT;
BEGIN
    FOREACH c IN ARRAY ARRAY[
        'technique_steps_fr', 'technique_steps_en',
        'natural_dyes_fr',    'natural_dyes_en',
        'stats_fr',           'stats_en',
        'timeline_events_fr', 'timeline_events_en',
        'disciplines_fr',     'disciplines_en',
        'custom_sections_fr', 'custom_sections_en',
        'hidden_fields'
    ]
    LOOP
        EXECUTE format(
            'ALTER TABLE public.about_content DROP CONSTRAINT IF EXISTS %I',
            c || '_is_array');
        EXECUTE format(
            'ALTER TABLE public.about_content ADD CONSTRAINT %I CHECK (jsonb_typeof(%I) = ''array'')',
            c || '_is_array', c);
    END LOOP;
END $$;

-- 3.6 Ligne unique ----------------------------------------------------------
INSERT INTO public.about_content (id, artist_name)
VALUES (1, 'Olga Indigo')
ON CONFLICT (id) DO NOTHING;

-- 3.7 Trigger updated_at ----------------------------------------------------
DROP TRIGGER IF EXISTS trg_set_updated_at ON public.about_content;
CREATE TRIGGER trg_set_updated_at
    BEFORE UPDATE ON public.about_content
    FOR EACH ROW EXECUTE FUNCTION public.set_updated_at();

-- 3.8 Privilèges ------------------------------------------------------------
REVOKE ALL ON public.about_content FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.about_content TO anon, authenticated;
GRANT INSERT, UPDATE ON public.about_content TO authenticated;   -- pas de DELETE
GRANT ALL ON public.about_content TO service_role;

-- 3.9 RLS -------------------------------------------------------------------
ALTER TABLE public.about_content ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Lecture publique pour about_content" ON public.about_content;
DROP POLICY IF EXISTS about_public_read   ON public.about_content;
CREATE POLICY about_public_read ON public.about_content
    FOR SELECT TO anon, authenticated
    USING (true);

DROP POLICY IF EXISTS about_admin_insert ON public.about_content;
CREATE POLICY about_admin_insert ON public.about_content
    FOR INSERT TO authenticated
    WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS about_admin_update ON public.about_content;
CREATE POLICY about_admin_update ON public.about_content
    FOR UPDATE TO authenticated
    USING      ((SELECT public.is_admin()))
    WITH CHECK ((SELECT public.is_admin()));

NOTIFY pgrst, 'reload schema';