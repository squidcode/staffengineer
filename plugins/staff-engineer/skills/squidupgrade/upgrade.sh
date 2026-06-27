#!/usr/bin/env bash
set -euo pipefail
# Upgrade from the free Staff Engineer skills to the full paid squid pack.
SHOP_URL="${SQUID_SHOP_URL:-https://squidcode.com/staffengineer}"
KEY_SVC=squidskills-license
DIR="$(cd "$(dirname "$0")" && pwd -P)"

license="$(security find-generic-password -a "$USER" -s "$KEY_SVC" -w 2>/dev/null || true)"
if [ -n "$license" ]; then
  echo "License already saved — upgrading to the latest full pack…"
  exec "$DIR/../squidup/update.sh"
fi

cat <<EOF
The full squid pack adds:
  squidinfra  — DigitalOcean infra (registry, App Platform, managed Postgres)
  squidci     — GitHub Actions CI/CD (build amd64, push DOCR, deploy)
  squidmon    — New Relic (APM, Browser, logs, dashboard, alerts)
  squidpush   — real-time messaging (Pusher / Soketi)
  squidflow   — durable workflows / background jobs (Inngest)

Opening the shop: $SHOP_URL
EOF
command -v open >/dev/null && open "$SHOP_URL" || echo "Visit: $SHOP_URL"

printf 'Paste your license key after purchase (blank to cancel): '
read -r key
[ -n "$key" ] || { echo "Cancelled — run squidupgrade again anytime."; exit 0; }
security add-generic-password -a "$USER" -s "$KEY_SVC" -w "$key" -U -T /usr/bin/security
echo "✓ License saved to the macOS Keychain."
# TODO(shop): once the licensing Worker is live, fetch + install the full pack here (see docs/distribution-plan.md).
echo "Full-pack download activates once the shop backend is live; free skills stay current via squidup."
