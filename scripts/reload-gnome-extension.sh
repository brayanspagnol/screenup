#!/usr/bin/env bash
set -euo pipefail

UUID="screenup-pip@screenup.local"

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/install-gnome-extension.sh"

if command -v gnome-extensions >/dev/null 2>&1; then
  gnome-extensions disable "${UUID}" || true
  gnome-extensions enable "${UUID}" || true
fi

echo "Recarregamento solicitado para ${UUID}"
