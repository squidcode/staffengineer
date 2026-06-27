#!/usr/bin/env bash
set -euo pipefail
# Update the installed squid skills to the latest.
#   no license (macOS Keychain) → refresh the FREE skills from the public Staff Engineer repo
#   license present             → the full paid pack (via the shop — lands with the licensing backend)
SKILLS_DIR="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
FREE_REPO="${SQUID_FREE_REPO:-https://github.com/squidcode/staffengineer.git}"
PLUGIN_SKILLS="plugins/staff-engineer/skills"
FREE_ITEMS="lib squidops squidapp squidup squidupgrade"   # lib is squidapp's ../lib helper

license="$(security find-generic-password -a "$USER" -s squidskills-license -w 2>/dev/null || true)"
if [ -n "$license" ]; then
  echo "License found. Full-pack updates come from the shop, which isn't live yet —" >&2
  echo "refreshing the free skills for now; run squidupgrade once the shop is up." >&2
fi

echo "Updating free Staff Engineer skills from $FREE_REPO …"
tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' EXIT
git clone --depth 1 "$FREE_REPO" "$tmp/se" >/dev/null 2>&1 || { echo "clone failed (is the repo public yet?)" >&2; exit 1; }
mkdir -p "$SKILLS_DIR"
for s in $FREE_ITEMS; do
  src="$tmp/se/$PLUGIN_SKILLS/$s"
  [ -d "$src" ] && { rm -rf "$SKILLS_DIR/$s"; cp -R "$src" "$SKILLS_DIR/$s"; echo "  ✓ $s"; }
done
echo "Done — restart Claude Code (or /reload) to pick up changes. (Marketplace users: /plugin update.)"
