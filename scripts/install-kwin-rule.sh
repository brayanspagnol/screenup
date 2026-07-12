#!/usr/bin/env bash
set -euo pipefail

RULE_ID="screenup-pip-keep-above"
RULES_FILE="kwinrulesrc"

if ! command -v kwriteconfig6 >/dev/null 2>&1; then
  echo "kwriteconfig6 nao encontrado; regra KWin nao instalada."
  exit 0
fi

existing_rules=""
if command -v kreadconfig6 >/dev/null 2>&1; then
  existing_rules="$(kreadconfig6 --file "${RULES_FILE}" --group General --key rules || true)"
fi

if [[ ",${existing_rules}," != *",${RULE_ID},"* ]]; then
  if [[ -n "${existing_rules}" ]]; then
    updated_rules="${existing_rules},${RULE_ID}"
  else
    updated_rules="${RULE_ID}"
  fi

  kwriteconfig6 --file "${RULES_FILE}" --group General --key rules "${updated_rules}"
fi

rule_count="$(awk -F',' '{ print NF }' <<<"$(kreadconfig6 --file "${RULES_FILE}" --group General --key rules 2>/dev/null || echo "${RULE_ID}")")"
kwriteconfig6 --file "${RULES_FILE}" --group General --key count "${rule_count}"

kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key Description "ScreenUp PiP sempre acima"
kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key title "ScreenUp PiP"
kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key titlematch 1
kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key wmclass "screenup-pip"
kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key wmclassmatch 1
kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key wmclasscomplete false
kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key above true
kwriteconfig6 --file "${RULES_FILE}" --group "${RULE_ID}" --key aboverule 2

echo "Regra KWin instalada: ${RULE_ID}"

if command -v qdbus6 >/dev/null 2>&1; then
  qdbus6 org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || echo "Nao foi possivel recarregar KWin via qdbus6."
elif command -v qdbus >/dev/null 2>&1; then
  qdbus org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || echo "Nao foi possivel recarregar KWin via qdbus."
elif command -v busctl >/dev/null 2>&1; then
  busctl --user call org.kde.KWin /KWin org.kde.KWin reconfigure >/dev/null 2>&1 || echo "Nao foi possivel recarregar KWin via busctl."
else
  echo "qdbus nao encontrado; se a regra nao aplicar agora, saia e entre novamente na sessao."
fi
