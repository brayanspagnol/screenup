#!/usr/bin/env bash
set -euo pipefail

UUID="screenup-pip@screenup.local"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/gnome-extension/${UUID}"
TARGET_DIR="${HOME}/.local/share/gnome-shell/extensions/${UUID}"

mkdir -p "$(dirname "${TARGET_DIR}")"
rm -rf "${TARGET_DIR}"
cp -R "${SOURCE_DIR}" "${TARGET_DIR}"

if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions enable "${UUID}" || true
fi

echo "Extensao instalada em ${TARGET_DIR}"

if command -v gnome-extensions >/dev/null 2>&1; then
  echo
  gnome-extensions info "${UUID}" || true
  echo
fi

echo "Se o estado nao for ACTIVE, encerre a sessao do GNOME e entre novamente."
echo "Depois rode: npm run doctor"
