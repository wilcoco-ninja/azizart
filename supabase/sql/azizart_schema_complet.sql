-- ████████ 01_core.sql ████████
-- ============================================================================
-- 01 — CORE : droits sur le schéma et fonctions utilitaires
-- Dépend de : rien. Idempotent (relançable sans risque).
-- ============================================================================

GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- Met à jour la colonne updated_at à chaque modification d'une ligne.
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

-- Fonction de trigger : jamais appelable depuis l'API.
REVOKE ALL ON FUNCTION public.set_updated_at() FROM PUBLIC, anon, authenticated;

NOTIFY pgrst, 'reload schema';

-- ████████ 02_admin_auth.sql ████████
-- ============================================================================
-- 02 — AUTHENTIFICATION ADMIN : comptes, pseudo de connexion, is_admin()
-- Dépend de : 01. Idempotent (relançable sans risque).
--
-- Comment fonctionne la connexion
-- ───────────────────────────────
--  • Les mots de passe sont gérés par Supabase Auth (auth.users). Rien n'est
--    stocké ici : un administrateur peut donc changer son mot de passe à tout
--    moment (« Paramètres du compte » ou « Mot de passe oublié »).
--  • public.admins          : liste des comptes autorisés à administrer le site.
--  • public.admin_settings  : pseudo de connexion de chaque administrateur
--                             (modifiable à tout moment par lui-même).
--  • Connexion par E-MAIL   : directe (signInWithPassword).
--  • Connexion par PSEUDO   : la fonction Edge `admin-login` retrouve l'e-mail
--                             côté serveur. L'e-mail n'est JAMAIS lisible par
--                             les visiteurs (aucun droit pour le rôle anon).
--
-- Règles de sécurité appliquées par la base (non contournables par l'API) :
--  • pseudo : 3 à 40 caractères, sans espace ni « @ », mis en minuscules ;
--  • pseudo unique ; e-mail recopié depuis auth.users (non falsifiable) ;
--  • seuls les comptes présents dans `admins` peuvent écrire leur pseudo
--    (une inscription publique éventuelle ne donne aucun droit).
-- ============================================================================

-- 2.1 Anciennes politiques : toutes supprimées (évite tout doublon ou reste) --
DO $$
DECLARE
    p RECORD;
BEGIN
    FOR p IN
        SELECT schemaname, tablename, policyname
        FROM pg_policies
        WHERE schemaname = 'public'
          AND tablename IN ('admins', 'admin_settings')
    LOOP
        EXECUTE format('DROP POLICY %I ON %I.%I',
                       p.policyname, p.schemaname, p.tablename);
    END LOOP;
END $$;

-- 2.2 Reprise d'une ancienne base : colonnes `id` de type TEXT -> UUID --------
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = 'admins'
                 AND column_name = 'id' AND data_type = 'text') THEN
        DELETE FROM public.admins
        WHERE id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        ALTER TABLE public.admins ALTER COLUMN id TYPE uuid USING id::uuid;
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns
               WHERE table_schema = 'public' AND table_name = 'admin_settings'
                 AND column_name = 'id' AND data_type = 'text') THEN
        DELETE FROM public.admin_settings
        WHERE id !~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$';
        ALTER TABLE public.admin_settings ALTER COLUMN id TYPE uuid USING id::uuid;
    END IF;
END $$;

-- 2.3 Tables ------------------------------------------------------------------
CREATE TABLE IF NOT EXISTS public.admins (
    id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    email      TEXT,
    pseudo     TEXT,                              -- copie de admin_settings.pseudo
    full_name  TEXT NOT NULL DEFAULT '',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.admin_settings (
    id         UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    pseudo     TEXT NOT NULL,
    email      TEXT,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ancienne base : colonnes manquantes ou contraintes trop strictes.
ALTER TABLE public.admins
    ADD COLUMN IF NOT EXISTS email      TEXT,
    ADD COLUMN IF NOT EXISTS pseudo     TEXT,
    ADD COLUMN IF NOT EXISTS full_name  TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS created_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.admins
    ALTER COLUMN pseudo    DROP NOT NULL,
    ALTER COLUMN full_name SET DEFAULT '';

ALTER TABLE public.admin_settings
    ADD COLUMN IF NOT EXISTS pseudo     TEXT,
    ADD COLUMN IF NOT EXISTS email      TEXT,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

DELETE FROM public.admin_settings WHERE pseudo IS NULL OR btrim(pseudo) = '';
ALTER TABLE public.admin_settings ALTER COLUMN pseudo SET NOT NULL;

-- Lignes orphelines (compte supprimé) puis clés étrangères manquantes.
DELETE FROM public.admins a
WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = a.id);
DELETE FROM public.admin_settings s
WHERE NOT EXISTS (SELECT 1 FROM auth.users u WHERE u.id = s.id);

DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                   WHERE conrelid = 'public.admins'::regclass AND contype = 'f') THEN
        ALTER TABLE public.admins
            ADD CONSTRAINT admins_id_fkey
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM pg_constraint
                   WHERE conrelid = 'public.admin_settings'::regclass AND contype = 'f') THEN
        ALTER TABLE public.admin_settings
            ADD CONSTRAINT admin_settings_id_fkey
            FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;
    END IF;
END $$;

-- Un pseudo = un compte. Les pseudos sont stockés en minuscules (trigger 2.5).
UPDATE public.admin_settings
SET pseudo = lower(btrim(pseudo))
WHERE pseudo <> lower(btrim(pseudo));

DROP INDEX IF EXISTS public.admin_settings_pseudo_lower_key;
CREATE UNIQUE INDEX IF NOT EXISTS admin_settings_pseudo_key
    ON public.admin_settings (pseudo);

-- 2.4 is_admin() : utilisée par les politiques RLS de toutes les tables ------
-- SECURITY DEFINER : lit `admins` sans dépendre de la RLS de l'appelant.
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
    SELECT EXISTS (
        SELECT 1 FROM public.admins a WHERE a.id = (SELECT auth.uid())
    );
$$;

REVOKE ALL ON FUNCTION public.is_admin() FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.is_admin() TO authenticated, service_role;

-- 2.5 Triggers de admin_settings ---------------------------------------------
-- Avant écriture : normalise et valide le pseudo, impose l'e-mail réel du compte.
CREATE OR REPLACE FUNCTION public.admin_settings_prepare()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_email TEXT;
BEGIN
    NEW.pseudo := lower(btrim(NEW.pseudo));

    IF NEW.pseudo IS NULL OR NEW.pseudo !~ '^[^@[:space:]]{3,40}$' THEN
        RAISE EXCEPTION
            'Pseudo invalide : 3 à 40 caractères, sans espace ni « @ ».'
            USING ERRCODE = '23514';
    END IF;

    SELECT lower(u.email) INTO v_email FROM auth.users u WHERE u.id = NEW.id;
    IF v_email IS NULL THEN
        RAISE EXCEPTION 'Compte introuvable ou sans adresse e-mail.'
            USING ERRCODE = '23503';
    END IF;

    NEW.email      := v_email;
    NEW.updated_at := NOW();
    RETURN NEW;
END;
$$;

-- Après écriture : recopie le pseudo dans `admins` (une seule source de vérité).
CREATE OR REPLACE FUNCTION public.admin_settings_mirror()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
BEGIN
    UPDATE public.admins
    SET pseudo = NEW.pseudo,
        email  = COALESCE(email, NEW.email)
    WHERE id = NEW.id
      AND (pseudo IS DISTINCT FROM NEW.pseudo OR email IS NULL);
    RETURN NEW;
END;
$$;

REVOKE ALL ON FUNCTION public.admin_settings_prepare() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.admin_settings_mirror()  FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS trg_admin_settings_prepare ON public.admin_settings;
CREATE TRIGGER trg_admin_settings_prepare
    BEFORE INSERT OR UPDATE ON public.admin_settings
    FOR EACH ROW EXECUTE FUNCTION public.admin_settings_prepare();

DROP TRIGGER IF EXISTS trg_admin_settings_mirror ON public.admin_settings;
CREATE TRIGGER trg_admin_settings_mirror
    AFTER INSERT OR UPDATE ON public.admin_settings
    FOR EACH ROW EXECUTE FUNCTION public.admin_settings_mirror();

-- 2.6 Privilèges et RLS : admins ---------------------------------------------
-- Un administrateur lit sa propre ligne. Aucune écriture depuis l'API :
-- les administrateurs s'ajoutent avec public.add_admin() (voir 2.8 / script 08).
ALTER TABLE public.admins ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.admins FROM PUBLIC, anon, authenticated;
GRANT SELECT ON public.admins TO authenticated;
GRANT ALL    ON public.admins TO service_role;

CREATE POLICY admins_self_select ON public.admins
    FOR SELECT TO authenticated
    USING (id = (SELECT auth.uid()));

-- 2.7 Privilèges et RLS : admin_settings -------------------------------------
-- Chaque administrateur ne lit et ne modifie que SA ligne, à tout moment.
ALTER TABLE public.admin_settings ENABLE ROW LEVEL SECURITY;

REVOKE ALL ON public.admin_settings FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE ON public.admin_settings TO authenticated;
GRANT ALL ON public.admin_settings TO service_role;     -- fonction Edge admin-login

CREATE POLICY admin_settings_self_select ON public.admin_settings
    FOR SELECT TO authenticated
    USING (id = (SELECT auth.uid()));

CREATE POLICY admin_settings_self_insert ON public.admin_settings
    FOR INSERT TO authenticated
    WITH CHECK (id = (SELECT auth.uid()) AND (SELECT public.is_admin()));

CREATE POLICY admin_settings_self_update ON public.admin_settings
    FOR UPDATE TO authenticated
    USING      (id = (SELECT auth.uid()) AND (SELECT public.is_admin()))
    WITH CHECK (id = (SELECT auth.uid()) AND (SELECT public.is_admin()));

-- 2.8 Gestion des administrateurs (SQL Editor / service_role uniquement) -----
-- Ajouter un administrateur  : SELECT public.add_admin('mail@exemple.com', 'monpseudo');
-- Changer son pseudo         : SELECT public.add_admin('mail@exemple.com', 'nouveau');
-- Retirer un administrateur  : SELECT public.remove_admin('mail@exemple.com');
CREATE OR REPLACE FUNCTION public.add_admin(p_email TEXT, p_pseudo TEXT DEFAULT NULL)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_email  TEXT := lower(btrim(p_email));
    v_id     UUID;
    v_pseudo TEXT;
BEGIN
    SELECT u.id INTO v_id FROM auth.users u WHERE lower(u.email) = v_email;
    IF v_id IS NULL THEN
        RAISE EXCEPTION 'Aucun compte Authentication pour l''adresse %', p_email;
    END IF;

    INSERT INTO public.admins (id, email) VALUES (v_id, v_email)
    ON CONFLICT (id) DO NOTHING;

    -- Sans pseudo fourni : on garde l'existant, sinon on déduit de l'e-mail.
    IF nullif(btrim(p_pseudo), '') IS NULL
       AND EXISTS (SELECT 1 FROM public.admin_settings WHERE id = v_id) THEN
        RETURN v_id;
    END IF;

    v_pseudo := coalesce(nullif(btrim(p_pseudo), ''), split_part(v_email, '@', 1));

    INSERT INTO public.admin_settings (id, pseudo) VALUES (v_id, v_pseudo)
    ON CONFLICT (id) DO UPDATE SET pseudo = EXCLUDED.pseudo;

    RETURN v_id;
END;
$$;

CREATE OR REPLACE FUNCTION public.remove_admin(p_email TEXT)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, pg_catalog
AS $$
DECLARE
    v_id UUID;
BEGIN
    SELECT u.id INTO v_id FROM auth.users u
    WHERE lower(u.email) = lower(btrim(p_email));
    IF v_id IS NULL THEN
        RAISE EXCEPTION 'Aucun compte Authentication pour l''adresse %', p_email;
    END IF;
    DELETE FROM public.admin_settings WHERE id = v_id;
    DELETE FROM public.admins         WHERE id = v_id;
END;
$$;

REVOKE ALL ON FUNCTION public.add_admin(TEXT, TEXT)  FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.remove_admin(TEXT)     FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.add_admin(TEXT, TEXT) TO service_role;
GRANT EXECUTE ON FUNCTION public.remove_admin(TEXT)    TO service_role;

NOTIFY pgrst, 'reload schema';

-- ████████ 03_about_content.sql ████████
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

-- ████████ 04_content_tables.sql ████████
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

-- ████████ 05_messages.sql ████████
-- ============================================================================
-- 05 — MESSAGES DU FORMULAIRE DE CONTACT
-- Dépend de : 01, 02. Idempotent.
-- Le public peut ÉCRIRE un message (statut « pending » imposé), jamais en lire.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.messages (
    id         UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name       TEXT NOT NULL DEFAULT '',
    email      TEXT NOT NULL DEFAULT '',
    phone      TEXT NOT NULL DEFAULT '',
    subject    TEXT NOT NULL DEFAULT '',
    message    TEXT NOT NULL DEFAULT '',
    status     TEXT NOT NULL DEFAULT 'pending',
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Ancienne base : le formulaire propose un téléphone (champ optionnel).
ALTER TABLE public.messages
    ADD COLUMN IF NOT EXISTS phone TEXT NOT NULL DEFAULT '';

-- Limites de taille (contrôle côté base, indépendant de l'application).
ALTER TABLE public.messages DROP CONSTRAINT IF EXISTS messages_limits;
ALTER TABLE public.messages ADD CONSTRAINT messages_limits CHECK (
    char_length(name)    <= 120  AND
    char_length(email)   <= 254  AND position('@' in email) > 1 AND
    char_length(phone)   <= 40   AND
    char_length(subject) <= 200  AND
    char_length(message) BETWEEN 1 AND 5000
);

CREATE INDEX IF NOT EXISTS messages_created_idx ON public.messages (created_at DESC);
CREATE INDEX IF NOT EXISTS messages_status_idx  ON public.messages (status);

-- Privilèges : le public peut écrire, jamais lire.
REVOKE ALL ON public.messages FROM PUBLIC, anon, authenticated;
GRANT INSERT ON public.messages TO anon, authenticated;
GRANT SELECT, UPDATE, DELETE ON public.messages TO authenticated;
GRANT ALL ON public.messages TO service_role;

ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS messages_insert ON public.messages;
CREATE POLICY messages_insert ON public.messages
    FOR INSERT TO anon, authenticated
    WITH CHECK (status = 'pending');

DROP POLICY IF EXISTS messages_admin_read ON public.messages;
CREATE POLICY messages_admin_read ON public.messages
    FOR SELECT TO authenticated
    USING ((SELECT public.is_admin()));

DROP POLICY IF EXISTS messages_admin_update ON public.messages;
CREATE POLICY messages_admin_update ON public.messages
    FOR UPDATE TO authenticated
    USING      ((SELECT public.is_admin()))
    WITH CHECK ((SELECT public.is_admin()));

DROP POLICY IF EXISTS messages_admin_delete ON public.messages;
CREATE POLICY messages_admin_delete ON public.messages
    FOR DELETE TO authenticated
    USING ((SELECT public.is_admin()));

NOTIFY pgrst, 'reload schema';

-- ████████ 06_career_skills.sql ████████
-- ============================================================================
-- 06 — PARCOURS & COMPÉTENCES (CareerService / SkillsService)
-- Dépend de : 01, 02. Idempotent.
-- Lecture publique, écriture réservée aux administrateurs.
-- ============================================================================

CREATE TABLE IF NOT EXISTS public.career_milestones (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    year          TEXT NOT NULL DEFAULT '',
    title         TEXT NOT NULL DEFAULT '',
    description   TEXT NOT NULL DEFAULT '',
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS public.skills (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name          TEXT NOT NULL DEFAULT '',
    level         INTEGER NOT NULL DEFAULT 50 CHECK (level BETWEEN 0 AND 100),
    display_order INTEGER NOT NULL DEFAULT 0,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at    TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS career_milestones_order_idx ON public.career_milestones (display_order);
CREATE INDEX IF NOT EXISTS skills_order_idx            ON public.skills (display_order);

DO $$
DECLARE
    t TEXT;
BEGIN
    FOREACH t IN ARRAY ARRAY['career_milestones', 'skills']
    LOOP
        EXECUTE format('ALTER TABLE public.%I ENABLE ROW LEVEL SECURITY', t);

        EXECUTE format('REVOKE ALL ON public.%I FROM PUBLIC, anon, authenticated', t);
        EXECUTE format('GRANT SELECT ON public.%I TO anon', t);
        EXECUTE format('GRANT SELECT, INSERT, UPDATE, DELETE ON public.%I TO authenticated', t);
        EXECUTE format('GRANT ALL ON public.%I TO service_role', t);

        EXECUTE format('DROP POLICY IF EXISTS public_read ON public.%I', t);
        EXECUTE format('CREATE POLICY public_read ON public.%I
                        FOR SELECT TO anon, authenticated USING (true)', t);

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

-- ████████ 07_realtime.sql ████████
-- ============================================================================
-- 07 — TEMPS RÉEL
-- Dépend de : 03, 04, 05. Idempotent.
-- Le temps réel respecte la RLS : un visiteur ne reçoit que ce qu'il peut lire.
-- ============================================================================

DO $$
DECLARE
    t TEXT;
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_publication WHERE pubname = 'supabase_realtime') THEN
        RAISE NOTICE 'Publication supabase_realtime absente : étape ignorée.';
        RETURN;
    END IF;

    FOREACH t IN ARRAY ARRAY[
        'artworks', 'atelier_photos', 'media_items',
        'home_events', 'about_content', 'messages'
    ]
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
END $$;

NOTIFY pgrst, 'reload schema';

-- ████████ 08_bootstrap_admins.sql ████████
-- ============================================================================
-- 08 — COMPTES ADMINISTRATEURS EXISTANTS
-- Dépend de : 02. Idempotent (relançable sans risque).
--
-- Les comptes de la section Authentication → Users (avec leurs mots de passe)
-- ne sont PAS touchés par la suppression des tables. Ce script les rattache
-- à la nouvelle table `admins` et leur attribue un pseudo de connexion.
-- Chacun pourra ensuite changer son pseudo et son mot de passe à tout moment
-- depuis « Paramètres du compte ».
--
-- ► Modifiez la liste ci-dessous si besoin (adresse e-mail, pseudo souhaité).
-- ============================================================================

DO $$
DECLARE
    r RECORD;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('alidaindigo@yahoo.com',  'alida'),
            ('azizart.color@gmail.com', 'azizart')
        ) AS v(email, pseudo)
    LOOP
        IF EXISTS (SELECT 1 FROM auth.users WHERE lower(email) = lower(r.email)) THEN
            PERFORM public.add_admin(r.email, r.pseudo);
            RAISE NOTICE 'Administrateur enregistré : % (pseudo : %)', r.email, r.pseudo;
        ELSE
            RAISE NOTICE 'Ignoré — aucun compte Authentication pour : %', r.email;
        END IF;
    END LOOP;
END $$;

-- Vérification : chaque administrateur doit apparaître avec son pseudo.
SELECT a.email, a.pseudo, s.updated_at AS pseudo_modifie_le
FROM public.admins a
LEFT JOIN public.admin_settings s ON s.id = a.id
ORDER BY a.created_at;