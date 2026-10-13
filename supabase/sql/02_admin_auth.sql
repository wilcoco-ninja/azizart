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