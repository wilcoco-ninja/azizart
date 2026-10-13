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