#!/usr/bin/env bash
set -euo pipefail

install_fedora() {
  local packages=(python3-gobject gtk4 mpv yt-dlp)
  if [[ "${DESKTOP:-}" == *gnome* ]]; then
    packages+=(gnome-extensions-app)
  fi
  echo "Instalando dependencias com dnf..."
  sudo dnf install -y "${packages[@]}"
}

install_debian() {
  local packages=(python3-gi python3-gi-cairo gir1.2-gtk-4.0 mpv yt-dlp)
  if [[ "${DESKTOP:-}" == *gnome* ]]; then
    packages+=(gnome-shell-extensions)
  fi
  echo "Instalando dependencias com apt..."
  sudo apt update
  sudo apt install -y "${packages[@]}"
}

install_arch() {
  local packages=(python python-gobject gtk4 mpv yt-dlp)
  echo "Instalando dependencias com pacman..."
  sudo pacman -S --needed --noconfirm "${packages[@]}"
}

DESKTOP="${XDG_CURRENT_DESKTOP:-}"
DESKTOP="${DESKTOP,,}"

if command -v mpv >/dev/null 2>&1 \
  && command -v yt-dlp >/dev/null 2>&1 \
  && python3 -c "import gi; gi.require_version('Gtk', '4.0')" >/dev/null 2>&1; then
  echo "Dependencias do sistema ja estao instaladas."
  exit 0
fi

if command -v dnf >/dev/null 2>&1; then
  install_fedora
elif command -v apt-get >/dev/null 2>&1; then
  install_debian
elif command -v pacman >/dev/null 2>&1; then
  install_arch
else
  echo "Nao consegui detectar o gerenciador de pacotes."
  echo "Instale manualmente: python3, GTK 4, mpv e yt-dlp."
  exit 1
fi

echo "Dependencias instaladas."
