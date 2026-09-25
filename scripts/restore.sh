#!/usr/bin/env bash
# Restore skills, references, and config onto a new machine.
#
# Usage:
#   bash scripts/restore.sh              # dry run — shows what would happen
#   bash scripts/restore.sh --apply      # actually copy
#
# Safe by default: it never overwrites settings.yaml (which holds machine-local
# provider config) and never touches .credentials.yaml.

set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
APPLY=0

[[ "${1:-}" == "--apply" ]] && APPLY=1

run() {
  if [[ $APPLY -eq 1 ]]; then
    "$@"
  else
    echo "  [dry-run] $*"
  fi
}

echo "repo:     $REPO"
echo "dsh home: $DSH_HOME"
echo

# --- skills -----------------------------------------------------------------
echo "==> skills (29)"
mkdir -p "$DSH_HOME/skills"
for d in "$REPO"/skills/*/; do
  name="$(basename "$d")"
  mkdir -p "$DSH_HOME/skills/$name"
  run cp -r "$d". "$DSH_HOME/skills/$name/"
done

# --- shared references ------------------------------------------------------
# Several addyosmani skills reference ../../references/*.md relative to the
# skill directory, which resolves to ~/.dsh/references/ once installed.
echo
echo "==> shared references (7 files)"
mkdir -p "$DSH_HOME/references"
run cp -r "$REPO"/references/. "$DSH_HOME/references/"

# --- config -----------------------------------------------------------------
echo
echo "==> config"
run cp "$REPO/config/AGENTS.md" "$DSH_HOME/AGENTS.md"
run cp "$REPO/config/cordis.patch.yml" "$DSH_HOME/cordis.patch.yml"
[[ -f "$REPO/config/pet.json" ]] && run cp "$REPO/config/pet.json" "$DSH_HOME/pet.json"
[[ -f "$REPO/config/skin-center-active.json" ]] && run cp "$REPO/config/skin-center-active.json" "$DSH_HOME/skin-center-active.json"

if [[ -f "$DSH_HOME/settings.yaml" ]]; then
  echo "  [skip] settings.yaml exists — not overwriting."
  echo "         Compare against config/settings.template.yaml manually."
else
  run cp "$REPO/config/settings.template.yaml" "$DSH_HOME/settings.yaml"
fi

# --- deliberately NOT copied ------------------------------------------------
echo
echo "==> deliberately NOT restored (machine- or secret-specific)"
echo "  .credentials.yaml   secrets — recreate via the GUI Models page"
echo "  sessions/           conversation history"
echo "  storages/           projection caches"
echo "  profiles/           plugin installs — see scripts/install-plugins.sh"

echo
if [[ $APPLY -eq 0 ]]; then
  echo "DRY RUN — nothing changed. Re-run with --apply to copy."
else
  echo "Done. Restart DeepSeek Harness."
fi
