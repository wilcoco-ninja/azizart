#!/usr/bin/env bash
# ════════════════════════════════════════════════════════════════════════
# Déploie la fonction r2-presign + ses secrets à partir de ton .env local.
# Les valeurs secrètes ne sont jamais affichées ni écrites ailleurs que dans
# un fichier temporaire (permissions 600) supprimé en sortie.
#
# Usage (depuis la racine du projet, là où se trouve le dossier supabase/) :
#   bash scripts/deploy_backend.sh --dry-run     # valide seulement
#   bash scripts/deploy_backend.sh               # valide puis déploie
#   bash scripts/deploy_backend.sh --dry-run chemin/vers/.env
#
# Prérequis : Supabase CLI connecté (supabase login).
# ════════════════════════════════════════════════════════════════════════
set -euo pipefail

PROJECT_REF="nqzrynteyovxzvahonpx"
DRY=0
ENV_FILE=".env"
for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY=1 ;;
    *) ENV_FILE="$arg" ;;
  esac
done

[ -f "$ENV_FILE" ] || { echo "❌ Fichier introuvable : $ENV_FILE (copie .env.example en .env)"; exit 1; }

# Lit CLE=valeur (ignore commentaires, retire guillemets et espaces)
get() {
  grep -E "^[[:space:]]*$1=" "$ENV_FILE" | tail -n1 | cut -d= -f2- | tr -d '\r' \
    | sed -E 's/^[[:space:]]+//; s/[[:space:]]+$//; s/^"(.*)"$/\1/' || true
}
mask() { local v="$1"; echo "(${#v} caractères)"; }

ACCOUNT="$(get R2_ACCOUNT_ID)"
BUCKET="$(get R2_BUCKET_NAME)"; [ -n "$BUCKET" ] || BUCKET="$(get R2_BUCKET)"
KEYID="$(get R2_ACCESS_KEY_ID)"
SECRET="$(get R2_SECRET_ACCESS_KEY)"
PUBLIC="$(get R2_PUBLIC_URL)"
while [[ "$PUBLIC" == */ ]]; do PUBLIC="${PUBLIC%/}"; done

echo "Validation de $ENV_FILE"
ERR=0; WARN=0
bad()  { echo "  ❌ $1"; ERR=1; }
warn() { echo "  ⚠️  $1"; WARN=$((WARN+1)); }
good() { echo "  ✅ $1"; }

[[ "$ACCOUNT" =~ ^[0-9a-f]{32}$ ]]  && good "R2_ACCOUNT_ID : $(mask "$ACCOUNT")" || bad "R2_ACCOUNT_ID : 32 caractères hexadécimaux attendus"
[[ "$BUCKET"  =~ ^[a-z0-9][a-z0-9-]{1,61}[a-z0-9]$ ]] && good "Bucket : $BUCKET" || bad "R2_BUCKET_NAME invalide ou vide"
[[ "$KEYID"   =~ ^[0-9a-f]{32}$ ]]  && good "R2_ACCESS_KEY_ID : $(mask "$KEYID")" || bad "R2_ACCESS_KEY_ID : 32 caractères hexadécimaux attendus"
[[ "$SECRET"  =~ ^[0-9a-f]{64}$ ]]  && good "R2_SECRET_ACCESS_KEY : $(mask "$SECRET")" || bad "R2_SECRET_ACCESS_KEY : 64 caractères hexadécimaux attendus"
[[ "$PUBLIC"  =~ ^https://[^/[:space:]]+$ ]] && good "R2_PUBLIC_URL : $PUBLIC" || bad "R2_PUBLIC_URL doit être https://domaine (sans chemin, sans « / » final)"

[[ "$PUBLIC" == *r2.dev* ]] && warn "R2_PUBLIC_URL pointe vers r2.dev (limité, sans cache) : domaine personnalisé conseillé en production"

# Lignes au mauvais format (« CLE: valeur, ») : ignorées par ce script
if grep -nE '^[A-Z][A-Z0-9_]*:[[:space:]]' "$ENV_FILE" >/dev/null 2>&1; then
  warn "Des lignes au format « CLE: valeur » sont ignorées (format attendu : CLE=valeur) :"
  grep -nE '^[A-Z][A-Z0-9_]*:[[:space:]]' "$ENV_FILE" | cut -d: -f1,2 | sed 's/^/        ligne /'
fi

if [ "$ERR" -ne 0 ]; then echo; echo "Arrêt : corrige les ❌ ci-dessus."; exit 1; fi
echo "  → $WARN avertissement(s)"

if [ "$DRY" -eq 1 ]; then echo; echo "Mode --dry-run : rien n'a été déployé."; exit 0; fi

# ── Déploiement ───────────────────────────────────────────────────────
command -v supabase >/dev/null || { echo "❌ Supabase CLI introuvable (https://supabase.com/docs/guides/cli)"; exit 1; }
[ -d supabase/functions/r2-presign ] || { echo "❌ Lance ce script depuis la racine du projet (dossier supabase/functions/r2-presign introuvable)"; exit 1; }

umask 077
TMP="$(mktemp)"; chmod 600 "$TMP"; trap 'rm -f "$TMP"' EXIT
{
  echo "R2_ACCOUNT_ID=$ACCOUNT"
  echo "R2_BUCKET=$BUCKET"
  echo "R2_ACCESS_KEY_ID=$KEYID"
  echo "R2_SECRET_ACCESS_KEY=$SECRET"
  echo "R2_PUBLIC_URL=$PUBLIC"
} > "$TMP"

echo; echo "Envoi des secrets…"
supabase secrets set --env-file "$TMP" --project-ref "$PROJECT_REF"

echo; echo "Déploiement de r2-presign (vérification JWT de la passerelle désactivée)…"
supabase functions deploy r2-presign --no-verify-jwt --project-ref "$PROJECT_REF"

echo; echo "✅ Terminé. Lance maintenant : bash scripts/verify_backend.sh"