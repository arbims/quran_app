#!/usr/bin/env bash
# Télécharge les assets runtime (mushaf + modèles ONNX) et les extrait à la racine du repo.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

BASE_URL="${RUNTIME_ASSETS_BASE_URL:-https://raw.githubusercontent.com/arbims/quran_app/runtime-assets}"
EXPECTED_SHA256="${RUNTIME_ASSETS_SHA256:-bf241ece8027c845362bbdd61344dc2c573d919b2b2e754793a749c840655704}"
PARTS=(00 01 02 03 04)

WORKDIR="$(mktemp -d)"
cleanup() { rm -rf "$WORKDIR"; }
trap cleanup EXIT

echo "→ Téléchargement des parties depuis ${BASE_URL}"
for part in "${PARTS[@]}"; do
  url="${BASE_URL}/quran_app_runtime_assets.zip.part${part}"
  out="${WORKDIR}/quran_app_runtime_assets.zip.part${part}"
  echo "  part${part}..."
  curl -fL --retry 3 --retry-delay 2 -o "$out" "$url"
done

ARCHIVE="${WORKDIR}/quran_app_runtime_assets.zip"
cat "${WORKDIR}"/quran_app_runtime_assets.zip.part* > "$ARCHIVE"

actual="$(sha256sum "$ARCHIVE" | awk '{print $1}')"
if [[ "$actual" != "$EXPECTED_SHA256" ]]; then
  echo "Checksum SHA256 incorrecte." >&2
  echo "  attendu : ${EXPECTED_SHA256}" >&2
  echo "  obtenu  : ${actual}" >&2
  exit 1
fi

echo "→ Extraction dans ${ROOT}"
unzip -o "$ARCHIVE"
echo "✓ Assets runtime installés (assets/mushaf, assets/models)."
