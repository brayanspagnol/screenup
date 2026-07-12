#!/usr/bin/env bash
set -euo pipefail

APP_NAME="screenup"
APP_TITLE="ScreenUp"
SOURCE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL_DIR="${HOME}/.local/share/${APP_NAME}"
BIN_DIR="${HOME}/.local/bin"
APPLICATIONS_DIR="${HOME}/.local/share/applications"
ICON_THEME_DIR="${HOME}/.local/share/icons/hicolor"
SCALABLE_ICON_DIR="${ICON_THEME_DIR}/scalable/apps"
BIN_PATH="${BIN_DIR}/${APP_NAME}"
DESKTOP_PATH="${APPLICATIONS_DIR}/${APP_NAME}.desktop"
ICON_PATH="${SCALABLE_ICON_DIR}/${APP_NAME}.svg"

mkdir -p "${INSTALL_DIR}" "${BIN_DIR}" "${APPLICATIONS_DIR}" "${SCALABLE_ICON_DIR}"
rm -rf "${INSTALL_DIR}/src" "${INSTALL_DIR}/gnome-extension" "${INSTALL_DIR}/scripts" "${INSTALL_DIR}/assets"
cp -R "${SOURCE_DIR}/src" "${INSTALL_DIR}/src"
cp -R "${SOURCE_DIR}/gnome-extension" "${INSTALL_DIR}/gnome-extension"
cp -R "${SOURCE_DIR}/scripts" "${INSTALL_DIR}/scripts"
cp -R "${SOURCE_DIR}/assets" "${INSTALL_DIR}/assets"
cp "${SOURCE_DIR}/README.md" "${INSTALL_DIR}/README.md"
cp "${SOURCE_DIR}/assets/${APP_NAME}.svg" "${ICON_PATH}"

for size in 16 24 32 48 64 128 256; do
  png_dir="${ICON_THEME_DIR}/${size}x${size}/apps"
  png_path="${png_dir}/${APP_NAME}.png"
  mkdir -p "${png_dir}"

  if command -v magick >/dev/null 2>&1; then
    magick -background none "${SOURCE_DIR}/assets/${APP_NAME}.svg" -resize "${size}x${size}" "${png_path}" >/dev/null 2>&1 || true
  elif command -v convert >/dev/null 2>&1; then
    convert -background none "${SOURCE_DIR}/assets/${APP_NAME}.svg" -resize "${size}x${size}" "${png_path}" >/dev/null 2>&1 || true
  fi
done

cat >"${BIN_PATH}" <<EOF
#!/usr/bin/env bash
set -euo pipefail
cd "${INSTALL_DIR}"
export PYTHONPATH="${INSTALL_DIR}/src"
exec python3 -m screenup "\$@"
EOF

chmod +x "${BIN_PATH}"

cat >"${DESKTOP_PATH}" <<EOF
[Desktop Entry]
Type=Application
Name=${APP_TITLE}
Comment=Picture-in-Picture nativo usando mpv
Exec=${BIN_PATH}
Icon=${APP_NAME}
Terminal=false
Categories=AudioVideo;Player;
StartupNotify=true
StartupWMClass=local.screenup.Pip
EOF

if command -v update-desktop-database >/dev/null 2>&1; then
  timeout 5s update-desktop-database "${APPLICATIONS_DIR}" >/dev/null 2>&1 || true
fi

if command -v gtk-update-icon-cache >/dev/null 2>&1; then
  timeout 5s gtk-update-icon-cache "${ICON_THEME_DIR}" >/dev/null 2>&1 || true
fi

if command -v xdg-icon-resource >/dev/null 2>&1; then
  timeout 5s xdg-icon-resource forceupdate --theme hicolor >/dev/null 2>&1 || true
fi

if command -v kbuildsycoca6 >/dev/null 2>&1; then
  timeout 5s kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
fi

echo "${APP_TITLE} instalado."
echo "Executavel: ${BIN_PATH}"
echo "Launcher: ${DESKTOP_PATH}"
echo "Icone: ${ICON_PATH}"
