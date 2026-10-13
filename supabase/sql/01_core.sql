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