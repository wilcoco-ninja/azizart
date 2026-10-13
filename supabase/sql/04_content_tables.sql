-- ============================================================================
-- 04 — CONTENU : galerie, atelier, médias, événements d'accueil
-- Dépend de : 01, 02. Idempotent.
--
-- Règles communes aux 4 tables :
--   • visiteur (anon)  : lecture des contenus PUBLIÉS uniquement ;
--   • administrateur   : lecture complète + création, modification, suppression.
-- ============================================================================

-- 4.1 Tables de base --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.artworks (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.atelier_photos (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.media_items (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.home_events (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4.2 Colonnes alignées sur le code Flutter (idempotent) ---------------------
ALTER TABLE public.artworks
    ADD COLUMN IF NOT EXISTS title_fr        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_fr  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_en  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS image_path      TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS image_url       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS category        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS technique       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS dimensions      TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS year            TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS price           NUMERIC(12,2),
    ADD COLUMN IF NOT EXISTS featured        BOOLEAN NOT NULL DEFAULT FALSE,
    ADD COLUMN IF NOT EXISTS status          TEXT NOT NULL DEFAULT 'available',
    ADD COLUMN IF NOT EXISTS created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.atelier_photos
    ADD COLUMN IF NOT EXISTS image_path      TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS image_url       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_fr        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_fr  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_en  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS sort_order      INTEGER NOT NULL DEFAULT 99,
    ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.media_items
    ADD COLUMN IF NOT EXISTS title_fr        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_fr  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_en  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS type            TEXT NOT NULL DEFAULT 'video',
    ADD COLUMN IF NOT EXISTS source          TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS url             TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS thumbnail_path  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS thumbnail_url   TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS year            TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS duration        TEXT,
    ADD COLUMN IF NOT EXISTS date            TIMESTAMPTZ,
    ADD COLUMN IF NOT EXISTS created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.home_events
    ADD COLUMN IF NOT EXISTS title_fr        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_fr  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_en  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS image_url       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS type            TEXT NOT NULL DEFAULT 'news',
    ADD COLUMN IF NOT EXISTS event_date      DATE,
    ADD COLUMN IF NOT EXISTS source          TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS external_url    TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 4.3 Contraintes -----------------------------------------------------------
ALTER TABLE public.artworks DROP CONSTRAINT IF EXISTS artworks_price_check;
ALTER TABLE public.artworks ADD CONSTRAINT artworks_price_check
    CHECK (price IS NULL OR price >= 0);

-- 4.4 Index -----------------------------------------------------------------
CREATE INDEX IF NOT EXISTS artworks_published_created_idx
    ON public.artworks (is_published, created_at DESC);
CREATE INDEX IF NOT EXISTS artworks_category_idx
    ON public.artworks (category);
CREATE INDEX IF NOT EXISTS artworks_featured_idx
    ON public.artworks (created_at DESC) WHERE featured AND is_published;

CREATE INDEX IF NOT EXISTS atelier_photos_published_sort_idx
    ON public.atelier_photos (is_published, sort_order);

CREATE INDEX IF NOT EXISTS media_items_published_created_idx
    ON public.media_items (is_published, created_at DESC);

CREATE INDEX IF NOT EXISTS home_events_published_date_idx
    ON public.home_events (is_published, event_date DESC);

-- 4.5 Privilèges, RLS, politiques, triggers ---------------------------------
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['artworks', 'atelier_photos', 'media_items', 'home_events']
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);

        EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC, anon, authenticated', t);
        EXECUTE format('GRANT SELECT ON public.%I TO anon', t);
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
        EXECUTE format('GRANT ALL ON public.%I TO service_role', t);

        EXECUTE format('DROP POLICY IF EXISTS public_read_published ON public.%I', t);
        EXECUTE format('CREATE POLICY public_read_published ON public.%I
                        FOR SELECT TO anon USING (is_published)', t);

        EXECUTE format('DROP POLICY IF EXISTS auth_read ON public.%I', t);
        EXECUTE format('CREATE POLICY auth_read ON public.%I
                        FOR SELECT TO authenticated
                        USING (is_published OR (SELECT public.is_admin()))', t);

        EXECUTE format('DROP POLICY IF EXISTS admin_insert ON public.%I', t);
        EXECUTE format('CREATE POLICY admin_insert ON public.%I
                        FOR INSERT TO authenticated
                        WITH CHECK ((SELECT public.is_admin()))', t);

        EXECUTE format('DROP POLICY IF EXISTS admin_update ON public.%I', t);
        EXECUTE format('CREATE POLICY admin_update ON public.%I
                        FOR UPDATE TO authenticated
                        USING ((SELECT public.is_admin()))
                        WITH CHECK ((SELECT public.is_admin()))', t);

        EXECUTE format('DROP POLICY IF EXISTS admin_delete ON public.%I', t);
        EXECUTE format('CREATE POLICY admin_delete ON public.%I
                        FOR DELETE TO authenticated
                        USING ((SELECT public.is_admin()))', t);

        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON public.%I', t);
        EXECUTE format('CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.%I
                        FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()', t);
    END LOOP;
END $$;

NOTIFY pgrst, 'reload schema';