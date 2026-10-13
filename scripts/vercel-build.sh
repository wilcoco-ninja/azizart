#!/usr/bin/env bash
set -euo pipefail

FLUTTER="$HOME/flutter/bin/flutter"

# Valeurs de repli : un --dart-define vide écraserait la valeur par défaut du code.
R2_PUBLIC_URL="${R2_PUBLIC_URL:-https://pub-683ade17eed84c96a53d0631e8f03742.r2.dev}"
IMAGE_RESIZING="${IMAGE_RESIZING:-false}"

# --pwa-strategy=none : pas de service worker, donc jamais d'ancienne version
# servie depuis le cache après un déploiement.
"$FLUTTER" build web --release --pwa-strategy=none \
  --dart-define=R2_PUBLIC_URL="$R2_PUBLIC_URL" \
  --dart-define=IMAGE_RESIZING="$IMAGE_RESIZING"