# azizart — Mise en production du backend

Ordre à respecter. Chaque étape se termine par un **test vérifiable**.

## Contenu du dossier

| Fichier | Rôle |
|---|---|
| `supabase/functions/r2-presign/index.ts` | Fonction Edge finale (auth, admin, validation, URLs signées 5 min) |
| `supabase/config.toml` | Désactive la vérification JWT « legacy » de la passerelle |
| `supabase/migrations/20261002000000_production_hardening.sql` | RLS `about_content` + requêtes de vérification |
| `lib/services/r2_storage_service.dart` | Service Flutter : délais adaptés, 2 tentatives, erreurs claires |
| `lib/config.dart` | Clé publishable, plus de clé legacy |
| `.env.example` | Modèle du `.env` (secrets backend) au bon format `CLE=valeur` |
| `.gitignore` | Empêche de commiter `.env` et autres secrets |
| `supabase/verify_folders.sql` | Vérifie que chaque page range ses images dans le bon dossier R2 |
| `lib/admin/admin_avatar_picker.dart` | Picker corrigé (messages d'erreur fiables) |
| `scripts/deploy_backend.sh` | Valide le `.env`, pousse les secrets et déploie la fonction |
| `env.json` | Variables publiques du build (nouvelle clé publishable, aucun secret) |
| `scripts/verify_backend.sh` | Test réel de bout en bout |

---

## Étape 0 — Deux fichiers, deux rôles (important)

| Fichier | Contenu | Utilisé par | Commit ? |
|---|---|---|---|
| `.env` | **secrets** R2 | `scripts/deploy_backend.sh` uniquement | ❌ jamais |
| `env.json` | valeurs **publiques** | `flutter build … --dart-define-from-file=env.json` | ✅ possible |

Ne passe **jamais** le `.env` à Flutter : tout ce qui est défini via
`--dart-define` peut finir dans le build public. Le `.env` doit aussi suivre
le format `CLE=valeur` (pas `CLE: valeur,`).

## Étape 1 — Fonction Edge

```bash
cp .env.example .env        # puis remplis les valeurs R2
bash scripts/deploy_backend.sh --dry-run   # valide le .env, ne déploie rien
bash scripts/deploy_backend.sh             # pousse les secrets + déploie
```

Le script vérifie le format de chaque valeur, n'affiche jamais les secrets,
et déploie avec `--no-verify-jwt`.

Vérifie dans le dashboard (fonction → Settings) que **Verify JWT with legacy
secret** est sur **OFF**. Le jeton R2 doit avoir **Object Read & Write** sur
`azizart-media`.

Si tu changes `ALLOWED_FOLDERS` dans la fonction, change aussi
`_uploadAllowedFolders` dans `r2_storage_service.dart`.

## Étape 2 — Base de données

Exécute la migration dans le SQL Editor, puis les 4 requêtes de vérification
(A à D) en bas du fichier. Attendu :

- **A** : `rls_active = true` pour toutes les tables ;
- **B** : aucune policy d'écriture accessible à `anon` ;
- **C** : ton e-mail de connexion apparaît dans la liste `admins` ;
- **D** : `1` ligne dans `about_content`.

## Étape 3 — App Flutter

1. Remplace `r2_storage_service.dart` et `config.dart`.
2. Dans **tous** les sélecteurs d'images (`AdminImageUploadField`, grille
   réordonnable…), utilise :
   `pickImage(source: ..., maxWidth: 1920, imageQuality: 85)`.
   Une photo passe ainsi de plusieurs Mo à quelques centaines de Ko, ce qui
   règle l'essentiel des délais dépassés sur connexion lente.
3. Build de production (Flutter ne lit pas `.env`) :

```bash
flutter build web --release --dart-define-from-file=env.json
```

`env.json` est fourni dans ce dossier (aucun secret) :

```json
{
  "SUPABASE_URL": "https://nqzrynteyovxzvahonpx.supabase.co",
  "SUPABASE_ANON_KEY": "sb_publishable_JiIWJ1SGBT7DoBM9ZiIolg_nd3qoLI3",
  "R2_PUBLIC_URL": "https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev",
  "BASE_URL": "https://azizart.com"
}
```

En développement, lance toujours `flutter run -d chrome --web-port=8080`
(le port 8080 est celui autorisé par la CORS R2).

## Étape 4 — Test réel

```bash
export SUPABASE_URL="https://nqzrynteyovxzvahonpx.supabase.co"
export SUPABASE_KEY="sb_publishable_JiIWJ1SGBT7DoBM9ZiIolg_nd3qoLI3"
export ADMIN_EMAIL="..." ADMIN_PASSWORD="..."
bash scripts/verify_backend.sh
```

Tu dois obtenir **0 échec**. Colle-moi la sortie complète si une ligne
est en ❌ : chaque ligne indique la cause exacte.

## Étape 5 — Domaine personnalisé (recommandé avant le lancement public)

L'URL `r2.dev` est limitée en débit et sans cache : c'est la cause la plus
probable des images lentes ou absentes en production.

1. Cloudflare → R2 → `azizart-media` → Settings → **Custom Domains** →
   Connect Domain → `media.azizart.com` (le domaine doit être dans ta zone
   Cloudflare). Attends le statut **Active**.
2. Cloudflare → Caching → **Cache Rules** : pour `media.azizart.com`,
   « Eligible for cache », Edge TTL 1 mois, Browser TTL 1 an. (Les noms de
   fichiers contiennent un horodatage et les avatars utilisent `?v=`, donc
   pas de risque d'image périmée.)
3. Mets à jour le secret `R2_PUBLIC_URL` de la fonction et
   `R2_PUBLIC_URL` dans `env.json`, puis redéploie.
4. Migre les URLs déjà enregistrées en base **avant** de désactiver
   `r2.dev` (adapte les colonnes à tes tables ; teste d'abord avec `SELECT`) :

```sql
BEGIN;
UPDATE public.artworks       SET image_url = replace(image_url, 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev', 'https://media.azizart.com');
UPDATE public.atelier_photos SET image_url = replace(image_url, 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev', 'https://media.azizart.com');
UPDATE public.home_events    SET image_url = replace(image_url, 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev', 'https://media.azizart.com');
UPDATE public.media_items    SET thumbnail_url = replace(thumbnail_url, 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev', 'https://media.azizart.com');
UPDATE public.about_content  SET avatar_path = replace(avatar_path, 'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev', 'https://media.azizart.com'),
                                 banner_url  = replace(banner_url,  'https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev', 'https://media.azizart.com');
COMMIT;
```

5. Relance `verify_backend.sh` : l'avertissement `r2.dev` doit disparaître et
   `cf-cache-status` doit apparaître (HIT à la 2ᵉ lecture).
6. Ensuite seulement : désactive **Public Development URL** dans R2.

## Étape 6 — Contrôles finaux

- Supabase → Authentication → **désactive les inscriptions publiques** si
  seuls les admins se connectent.
- Cloudflare → R2 → API Tokens : jeton limité au bucket `azizart-media`.
- Supabase → Edge Functions → `r2-presign` → Logs : aucune erreur 4xx/5xx
  inattendue après tes essais.
- R2 → Settings : **R2 Data Catalog** (Iceberg) est activé alors qu'il ne
  sert pas à des images. S'il ne t'est d'aucune utilité, tu peux le
  désactiver (non urgent).
- Garde **Local Uploads** activé : il accélère les envois depuis ta région
  vers un bucket situé en Europe de l'Ouest.

## Rotation des clés R2 (à faire si les clés ont été partagées)

Si `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY` ont été collées dans un chat,
un mail ou un dépôt, remplace-les :

1. Cloudflare → R2 → **Manage R2 API Tokens** → *Create API Token* :
   permission **Object Read & Write**, limité au bucket `azizart-media`.
2. Mets les 2 nouvelles valeurs dans ton `.env` local.
3. `bash scripts/deploy_backend.sh` (le nouveau jeton remplace l'ancien côté fonction).
4. `bash scripts/verify_backend.sh` → 0 échec.
5. Seulement ensuite : supprime l'**ancien** jeton dans Cloudflare.

## Rotation de la clé publishable

La fonction `r2-presign` lit automatiquement la clé courante dans
`SUPABASE_PUBLISHABLE_KEYS` : **aucun secret à mettre à jour** côté fonction.
Côté app, la nouvelle clé est dans `config.dart` et `env.json`.

Ordre sûr pour retirer l'ancienne clé :

1. Rebuild et redéploie le site avec la nouvelle clé.
2. Vérifie le site et lance `verify_backend.sh`.
3. Seulement ensuite, supprime/révoque l'ancienne clé dans Supabase →
   Settings → API Keys (et désactive les clés *legacy* si tu n'en as plus
   besoin). Les visiteurs qui ont encore l'ancienne version en cache
   perdront l'accès tant qu'ils ne rechargent pas la page.

## Dépannage : « Clés de stockage expirées »

Ce texte vient de l'ancien `_friendlyUploadError` : il s'affichait pour toute
erreur contenant « 401 » ou « 403 ». Il peut donc cacher 4 causes différentes.
Avec les fichiers de ce dossier, le message devient précis :

| Nouveau message | Cause | Action |
|---|---|---|
| Session expirée. Reconnectez-vous. | jeton de session ancien (rotation des clés Supabase) | se déconnecter / reconnecter |
| Ce compte n'est pas autorisé… | ton UUID n'est pas dans `public.admins` | requête C de la migration |
| R2_ACCESS_KEY_ID inconnu ou révoqué | ancien jeton R2 supprimé dans Cloudflare | `deploy_backend.sh` avec le nouveau jeton |
| R2_SECRET_ACCESS_KEY incorrect | secret erroné dans les secrets de la fonction | idem |
| jeton R2 sans permission Object Read & Write | jeton R2 trop restreint | recréer le jeton |

Cherche aussi d'autres copies du message dans ton projet :
`grep -rn "Clés de stockage expirées" lib/` (notamment `admin_forms.dart`) et
remplace-les par `if (e is R2UploadException) return e.message;`.

## Vérifier les dossiers de stockage

Exécute `supabase/verify_folders.sql` : la requête 1 donne, pour chaque page,
le dossier réel de ses images (✅ conforme / ⚠️ à vérifier).

## Cause n°1 trouvée : clés R2 du `.env` ≠ secrets déployés dans Supabase

Le `.env` local n'a **aucun effet** tant que `deploy_backend.sh` n'a pas poussé
ses valeurs dans les secrets de la fonction. Pour comparer sans révéler les
secrets, calcule l'empreinte locale et compare-la à la colonne **Digest** du
dashboard (Edge Functions → Secrets) :

```bash
printf '%s' "VALEUR_DU_SECRET" | sha256sum
```

Si les deux empreintes diffèrent, la fonction signe avec d'anciennes clés : R2
répond 403 (`InvalidAccessKeyId` / `SignatureDoesNotMatch`) et l'app affiche
« Clés de stockage expirées ». Correction : nouveau jeton R2 →
`bash scripts/deploy_backend.sh`.

## Dossiers vérifiés dans le code des écrans

| Écran | Dossier R2 | Autorisé par la fonction |
|---|---|---|
| Galerie (`gallery_form_page`) | `gallery` | ✅ |
| Atelier (`atelier_form_page`) | `atelier` | ✅ |
| Événements (`home_event_form_page`) | `home_events` | ✅ |
| Média : vignette et fichier (`media_form_page`) | `media` | ✅ |
| À propos : profil / couverture | `about_avatars` / `about_banners` | ✅ |
| `logo/` | aucun écran n'y envoie : fichiers déposés à la main | — |

## Limites alignées sur `media_form_page`

- Images : 10 Mo max. Médias (vidéo, audio, PDF) : 100 Mo max.
- Types acceptés par la fonction : images (jpeg, png, webp, gif, avif),
  vidéo (mp4, webm, mov), audio (mp3, m4a, wav, ogg), PDF.
  Un fichier d'un autre type est refusé avec « Type de fichier non autorisé ».
- La console du navigateur affiche maintenant chaque étape :
  `[R2] presign → HTTP 200`, `[R2] PUT → HTTP 403`, etc.