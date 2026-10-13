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