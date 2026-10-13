-- ============================================================================
-- AZIZART COLORS — MISE EN PLACE SUPABASE (production, NON destructif)
-- Exécutable plusieurs fois sans perte de données.
-- Prérequis : les comptes des administrateurs existent déjà dans
-- Authentication → Users (sinon la table `admins` reste vide).
-- ⚠️ Contient des adresses e-mail réelles : ne pas publier ce fichier.
-- ============================================================================

-- 1. TABLES D'ADMINISTRATION ------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admins (
    id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    pseudo     TEXT UNIQUE NOT NULL,
    full_name  TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admin_settings (
    id         TEXT PRIMARY KEY,
    pseudo     TEXT UNIQUE NOT NULL,
    email      TEXT NOT NULL,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 2. PAGE À PROPOS (une seule ligne : id = 1) --------------------------------
CREATE TABLE IF NOT EXISTS public.about_content (
    id               INTEGER PRIMARY KEY DEFAULT 1 CHECK (id = 1),
    artist_name      TEXT NOT NULL DEFAULT 'Olga Indigo',
    artist_name_fr   TEXT DEFAULT 'Olga Indigo',
    artist_name_en   TEXT DEFAULT 'Olga Indigo',
    artist_title     TEXT DEFAULT 'Artiste Peintre Batik',
    artist_title_fr  TEXT DEFAULT 'Artiste Peintre Batik',
    artist_title_en  TEXT DEFAULT 'Batik Painter & Artist',
    avatar_path      TEXT DEFAULT '',
    banner_url       TEXT DEFAULT '',
    bio_fr           TEXT DEFAULT '',
    bio_en           TEXT DEFAULT '',
    philosophy_fr    TEXT DEFAULT '',
    philosophy_en    TEXT DEFAULT '',
    timeline_events  JSONB DEFAULT '[]'::jsonb,
    created_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at       TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 3. TABLES DE CONTENU --------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.artworks (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_fr     TEXT NOT NULL DEFAULT '',
    title_en     TEXT NOT NULL DEFAULT '',
    image_path   TEXT NOT NULL DEFAULT '',
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.atelier_photos (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    image_path   TEXT NOT NULL DEFAULT '',
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.media_items (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_fr     TEXT NOT NULL DEFAULT '',
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.home_events (
    id           UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title_fr     TEXT NOT NULL DEFAULT '',
    is_published BOOLEAN NOT NULL DEFAULT TRUE,
    created_at   TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- 4. ALIGNEMENT DES COLONNES SUR LE CODE FLUTTER (tables neuves ou existantes)
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
    ADD COLUMN IF NOT EXISTS is_published    BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.atelier_photos
    ADD COLUMN IF NOT EXISTS image_path      TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS image_url       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_fr        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_fr  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_en  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS sort_order      INTEGER NOT NULL DEFAULT 99,
    ADD COLUMN IF NOT EXISTS is_published    BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
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
    ADD COLUMN IF NOT EXISTS is_published    BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.home_events
    ADD COLUMN IF NOT EXISTS title_fr        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS title_en        TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_fr  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS description_en  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS image_url       TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS type            TEXT NOT NULL DEFAULT 'news',
    ADD COLUMN IF NOT EXISTS event_date      DATE,
    ADD COLUMN IF NOT EXISTS is_published    BOOLEAN NOT NULL DEFAULT TRUE,
    ADD COLUMN IF NOT EXISTS source          TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS external_url    TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS created_by      UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    ADD COLUMN IF NOT EXISTS created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    ADD COLUMN IF NOT EXISTS updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW();

-- 5. FONCTIONS ---------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.admins WHERE id = (SELECT auth.uid())
    );
$$;

CREATE OR REPLACE FUNCTION public.resolve_admin_email(p_pseudo TEXT)
RETURNS TEXT
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_email TEXT;
BEGIN
    SELECT email INTO v_email
    FROM public.admin_settings
    WHERE lower(pseudo) = lower(p_pseudo)
    LIMIT 1;

    RETURN v_email;
END;
$$;

CREATE OR REPLACE FUNCTION public.set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SET search_path = public, pg_catalog
AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated;

REVOKE ALL ON FUNCTION public.resolve_admin_email(TEXT) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.resolve_admin_email(TEXT) TO anon, authenticated;

-- 6. ADMINISTRATEURS (liés aux comptes Auth existants) ------------------------
INSERT INTO public.admins (id, pseudo, full_name)
SELECT id, 'olga', 'Olga Indigo'
FROM auth.users
WHERE lower(email) = 'azizart.color@gmail.com'
ON CONFLICT (id) DO UPDATE
SET pseudo = EXCLUDED.pseudo, full_name = EXCLUDED.full_name;

INSERT INTO public.admins (id, pseudo, full_name)
SELECT id, 'alida', 'Alida'
FROM auth.users
WHERE lower(email) = 'alidaindigo@yahoo.com'
ON CONFLICT (id) DO UPDATE
SET pseudo = EXCLUDED.pseudo, full_name = EXCLUDED.full_name;

INSERT INTO public.admin_settings (id, pseudo, email)
SELECT a.id::text, lower(a.pseudo), u.email
FROM public.admins a
JOIN auth.users u ON u.id = a.id
ON CONFLICT (id) DO UPDATE
SET pseudo = EXCLUDED.pseudo, email = EXCLUDED.email;

-- 7. LIGNE ANCRE DE LA PAGE À PROPOS -------------------------------------------
INSERT INTO public.about_content (id, artist_name, artist_title)
VALUES (1, 'Olga Indigo', 'Artiste Peintre Batik')
ON CONFLICT (id) DO NOTHING;

-- 8. PRIVILÈGES ----------------------------------------------------------------
GRANT USAGE ON SCHEMA public TO anon, authenticated;

GRANT SELECT ON public.admins TO authenticated;

GRANT SELECT ON public.about_content TO anon, authenticated;
GRANT INSERT, UPDATE ON public.about_content TO authenticated;
REVOKE DELETE ON public.about_content FROM authenticated;

GRANT SELECT ON public.artworks, public.atelier_photos,
                public.media_items, public.home_events TO anon;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.artworks, public.atelier_photos,
                public.media_items, public.home_events TO authenticated;

-- admin_settings : aucun accès direct (lecture uniquement via resolve_admin_email)
REVOKE ALL ON public.admin_settings FROM anon, authenticated;

-- 9. ROW LEVEL SECURITY ----------------------------------------------------------
ALTER TABLE public.admins         ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.about_content  ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Les admins peuvent voir leur propre profil" ON public.admins;
CREATE POLICY "Les admins peuvent voir leur propre profil"
    ON public.admins FOR SELECT TO authenticated
    USING (id = (SELECT auth.uid()));

DROP POLICY IF EXISTS "Lecture publique pour about_content" ON public.about_content;
CREATE POLICY "Lecture publique pour about_content"
    ON public.about_content FOR SELECT TO anon, authenticated
    USING (true);

DROP POLICY IF EXISTS "Écriture réservée aux administrateurs pour about_content" ON public.about_content;
DROP POLICY IF EXISTS about_admin_insert ON public.about_content;
DROP POLICY IF EXISTS about_admin_update ON public.about_content;
CREATE POLICY about_admin_insert
    ON public.about_content FOR INSERT TO authenticated
    WITH CHECK (public.is_admin());
CREATE POLICY about_admin_update
    ON public.about_content FOR UPDATE TO authenticated
    USING (public.is_admin()) WITH CHECK (public.is_admin());

-- Tables de contenu : visiteurs = contenu publié ; admins = tout.
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['artworks', 'atelier_photos', 'media_items', 'home_events']
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);

        EXECUTE format('DROP POLICY IF EXISTS public_read_published ON public.%I', t);
        EXECUTE format(
            'CREATE POLICY public_read_published ON public.%I
             FOR SELECT TO anon USING (is_published)', t);

        EXECUTE format('DROP POLICY IF EXISTS auth_read ON public.%I', t);
        EXECUTE format(
            'CREATE POLICY auth_read ON public.%I
             FOR SELECT TO authenticated USING (is_published OR public.is_admin())', t);

        EXECUTE format('DROP POLICY IF EXISTS admin_insert ON public.%I', t);
        EXECUTE format(
            'CREATE POLICY admin_insert ON public.%I
             FOR INSERT TO authenticated WITH CHECK (public.is_admin())', t);

        EXECUTE format('DROP POLICY IF EXISTS admin_update ON public.%I', t);
        EXECUTE format(
            'CREATE POLICY admin_update ON public.%I
             FOR UPDATE TO authenticated
             USING (public.is_admin()) WITH CHECK (public.is_admin())', t);

        EXECUTE format('DROP POLICY IF EXISTS admin_delete ON public.%I', t);
        EXECUTE format(
            'CREATE POLICY admin_delete ON public.%I
             FOR DELETE TO authenticated USING (public.is_admin())', t);
    END LOOP;
END
$$;

-- 10. `updated_at` AUTOMATIQUE -----------------------------------------------------
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['artworks', 'atelier_photos', 'media_items',
                             'home_events', 'about_content']
    LOOP
        EXECUTE format('DROP TRIGGER IF EXISTS trg_set_updated_at ON public.%I', t);
        EXECUTE format(
            'CREATE TRIGGER trg_set_updated_at BEFORE UPDATE ON public.%I
             FOR EACH ROW EXECUTE FUNCTION public.set_updated_at()', t);
    END LOOP;
END
$$;

-- 11. REALTIME (nécessaire aux `.stream()` de l'application) -------------------------
DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['artworks', 'atelier_photos', 'media_items',
                             'home_events', 'about_content']
    LOOP
        IF NOT EXISTS (
            SELECT 1 FROM pg_publication_tables
            WHERE pubname = 'supabase_realtime'
              AND schemaname = 'public'
              AND tablename = t
        ) THEN
            EXECUTE format('ALTER PUBLICATION supabase_realtime ADD TABLE public.%I', t);
        END IF;
    END LOOP;
END
$$;

-- 12. RECHARGEMENT DU SCHÉMA POSTGREST ----------------------------------------------
NOTIFY pgrst, 'reload schema';