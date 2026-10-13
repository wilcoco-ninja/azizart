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