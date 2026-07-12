#!/usr/bin/env bash
set -euo pipefail

UUID="screenup-pip@screenup.local"
DESKTOP="${XDG_CURRENT_DESKTOP:-desconhecido}"

echo "ScreenUp doctor"
echo
echo "Sessao: ${XDG_SESSION_TYPE:-desconhecida}"
echo "Desktop: ${DESKTOP}"
echo

for binary in python3 mpv yt-dlp; do
  if command -v "${binary}" >/dev/null 2>&1; then
    echo "ok: ${binary} -> $(command -v "${binary}")"
  else
    echo "erro: ${binary} nao encontrado"
  fi
done

echo

case "${DESKTOP,,}" in
  *gnome*)
    if command -v gnome-extensions >/dev/null 2>&1; then
      echo "ok: gnome-extensions -> $(command -v gnome-extensions)"
      echo "Estado da extensao:"
      gnome-extensions info "${UUID}" || true
    else
      echo "erro: gnome-extensions nao encontrado em uma sessao GNOME"
    fi
    ;;
  *kde*|*plasma*)
    echo "GNOME Shell: ignorado nesta sessao KDE/Plasma"
    ;;
  *)
    echo "GNOME Shell: desktop nao identificado como GNOME; extensao GNOME pode nao ser usada"
    ;;
esac

echo

if command -v kreadconfig6 >/dev/null 2>&1; then
  echo "KWin rule:"
  rules="$(kreadconfig6 --file kwinrulesrc --group General --key rules 2>/dev/null || true)"
  if [[ ",${rules}," == *",screenup-pip-keep-above,"* ]]; then
    echo "ok: regra screenup-pip-keep-above instalada"
    echo "above=$(kreadconfig6 --file kwinrulesrc --group screenup-pip-keep-above --key above 2>/dev/null || true)"
    echo "aboverule=$(kreadconfig6 --file kwinrulesrc --group screenup-pip-keep-above --key aboverule 2>/dev/null || true)"
  else
    echo "erro: regra screenup-pip-keep-above nao encontrada"
  fi
else
  case "${DESKTOP,,}" in
    *kde*|*plasma*)
      echo "erro: kreadconfig6 nao encontrado em uma sessao KDE/Plasma"
      ;;
    *)
      echo "KWin rule: ignorada fora do KDE/Plasma"
      ;;
  esac
fi

echo

if command -v mpv >/dev/null 2>&1; then
  echo "Opcoes mpv importantes:"
  mpv --list-options 2>/dev/null | awk '/x11-name|wayland-app-id|ontop-level|gpu-context/ { print }' || true
fi

echo
echo "Logs recentes da extensao:"
journalctl --user -b 0 2>/dev/null | awk '/ScreenUp PiP/ { lines[++count] = $0 } END { start = count - 19; if (start < 1) start = 1; for (i = start; i <= count; i++) print lines[i] }' || true
