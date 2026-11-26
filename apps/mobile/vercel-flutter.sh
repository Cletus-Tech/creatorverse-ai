#!/usr/bin/env bash
set -euo pipefail

FLUTTER_VERSION="3.47.9"
CACHE_DIR="${HOME}/.cache"
SDK_DIR="${CACHE_DIR}/creatorverse-flutter-${FLUTTER_VERSION}"
ARCHIVE="${CACHE_DIR}/flutter-linux-${FLUTTER_VERSION}.tar.xz"

export CI=true
export FLUTTER_SUPPRESS_ANALYTICS=true

if [ ! -x "${SDK_DIR}/bin/flutter" ]; then
  mkdir -p "${CACHE_DIR}"
  rm -rf "${SDK_DIR}"
  curl --fail --location --retry 3 --retry-delay 2 \
    "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
    --output "${ARCHIVE}"
  TEMP_DIR="$(mktemp -d "${CACHE_DIR}/flutter-extract.XXXXXX")"
  tar -xf "${ARCHIVE}" -C "${TEMP_DIR}"
  mv "${TEMP_DIR}/flutter" "${SDK_DIR}"
  rm -rf "${TEMP_DIR}" "${ARCHIVE}"
fi

FLUTTER="${SDK_DIR}/bin/flutter"
"${FLUTTER}" config --enable-web

# This repository intentionally generates platform scaffolding during CI.
# Generate the web runner here as well so Vercel builds the same Flutter app.
if [ ! -f "web/index.html" ]; then
  "${FLUTTER}" create --platforms=web --org com.cletustech --project-name creatorverse_mobile .
fi

exec "${FLUTTER}" "$@"
