#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
DIST_DIR="${ROOT_DIR}/dist"
rm -rf "${DIST_DIR}"
mkdir -p "${DIST_DIR}"

# Preserve the existing static website at / while placing the Flutter app at /app/.
for item in "${ROOT_DIR}"/* "${ROOT_DIR}"/.[!.]*; do
  [ -e "${item}" ] || continue
  name="$(basename "${item}")"
  case "${name}" in
    .|..|.git|.github|.vercel|apps|supabase|docs|documentation|node_modules|dist|build|.dart_tool|creatorverse-ai.zip)
      continue
      ;;
  esac
  cp -a "${item}" "${DIST_DIR}/"
done

cd "${ROOT_DIR}/apps/mobile"
bash ./vercel-flutter.sh pub get
bash ./vercel-flutter.sh build web --release --base-href "/app/"

mkdir -p "${DIST_DIR}/app"
cp -a build/web/. "${DIST_DIR}/app/"

test -s "${DIST_DIR}/index.html"
test -s "${DIST_DIR}/app/index.html"
printf 'Combined CreatorVerse website + Flutter app built in %s\n' "${DIST_DIR}"
