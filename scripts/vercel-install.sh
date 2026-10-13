#!/usr/bin/env bash
set -euo pipefail

# Version de Flutter : variable FLUTTER_VERSION dans Vercel (ex. 3.38.0),
# sinon la dernière version stable.
FLUTTER_VERSION="${FLUTTER_VERSION:-stable}"

if [ ! -d "$HOME/flutter" ]; then
  git clone https://github.com/flutter/flutter.git \
    --branch "$FLUTTER_VERSION" --depth 1 "$HOME/flutter"
fi

"$HOME/flutter/bin/flutter" config --enable-web --no-analytics
"$HOME/flutter/bin/flutter" precache --web
"$HOME/flutter/bin/flutter" pub get