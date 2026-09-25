#!/usr/bin/env bash
# Install the DSH plugins used on the source machine into a target profile.
#
# Usage:
#   bash scripts/install-plugins.sh ~/.dsh/profiles/desktop
#
# Requires pnpm on PATH. If it is missing, enable it with:
#   corepack enable pnpm
#
# The DeepSeek Harness desktop launcher always uses the `desktop` profile
# (hardcoded in apps/desktop/src/paths.ts), so that is the right target for a
# desktop setup. The `web` profile is what `dsh web` uses.

set -euo pipefail

PROFILE="${1:-$HOME/.dsh/profiles/desktop}"

if [[ ! -f "$PROFILE/package.json" ]]; then
  echo "error: no package.json in $PROFILE" >&2
  echo "hint: start DeepSeek Harness once so the profile is initialised" >&2
  exit 1
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "error: pnpm not found on PATH" >&2
  echo "hint: corepack enable pnpm" >&2
  exit 1
fi

echo "==> installing third-party plugins into $PROFILE"
cd "$PROFILE"

pnpm add \
  "@linxin666/dsh-web-all@0.3.24" \
  "@liustack/modsearch@5.10.3" \
  "@roarpeng/graphflow@1.25.1" \
  "dshmarket@1.51.0"

echo
echo "==> native build scripts"
echo "pnpm may have refused to run build scripts for native modules."
echo "If it printed ERR_PNPM_IGNORED_BUILDS, edit pnpm-workspace.yaml in the"
echo "profile and set these to true under allowBuilds, then re-run:"
echo "    pnpm install"
for p in node-pty better-sqlite3 onnxruntime-node sharp cloudflared; do
  echo "    $p: true"
done

echo
echo "==> registering bundles"
echo "Add these entries to the dsh.profile.bundles array in $PROFILE/package.json:"
cat <<'EOF'
    "@linxin666/dsh-web-all",
    "@liustack/modsearch",
    "@roarpeng/graphflow",
    "dshmarket"
EOF

echo
echo "==> done. Restart DeepSeek Harness for the plugins to load."
