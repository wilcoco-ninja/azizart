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