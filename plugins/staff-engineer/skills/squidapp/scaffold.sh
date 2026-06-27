#!/usr/bin/env bash
set -euo pipefail

# Scaffolds INTO the current directory. App name defaults to the folder name.
# usage: scaffold.sh [app-name] [doppler-project]
APP="${1:-$(basename "$PWD")}"
DIR="$(cd "$(dirname "$0")" && pwd -P)"   # -P resolves the install symlink so ../lib is reachable

# Safety: this writes INTO $PWD (and would overwrite a CLAUDE.md/README.md/package.json
# already here). Refuse unless the directory is empty, so running it from the wrong
# place — an existing project, or an umbrella folder of projects — can't clobber files.
# A few benign dotfiles are allowed (a freshly `git init`ed or direnv'd dir still passes).
if [ -n "$(ls -A 2>/dev/null | grep -vxE '\.(git|envrc|DS_Store|idea|vscode)')" ]; then
  echo "Refusing to scaffold: $(pwd) is not empty." >&2
  echo "Run from an empty app dir, e.g.:  mkdir -p ~/dev/squidcode/$APP && cd \"\$_\" && $(basename "$0") $APP" >&2
  exit 1
fi

# --- preflight: required tooling (Doppler, OrbStack) + optional (New Relic CLI) ---
offer_install() {  # $1 name, $2 install cmd; returns nonzero if declined
  printf 'Install %s now? [y/N]: ' "$1" >&2
  read -r ans
  case "$ans" in y|Y) eval "$2" ;; *) return 1 ;; esac
}

# Doppler — REQUIRED. Holds this app's secrets (no committed .env); every run is
# `doppler run -- …`. Free account at https://dashboard.doppler.com.
if ! command -v doppler >/dev/null 2>&1; then
  echo "Doppler CLI not found — it stores secrets and injects them at runtime." >&2
  offer_install "Doppler" "brew install dopplerhq/cli/doppler" || \
    { echo "Install it, sign up at dashboard.doppler.com, then re-run." >&2; exit 1; }
fi
if ! doppler me >/dev/null 2>&1; then
  echo "Doppler not logged in. Run 'doppler login' (browser auth), then re-run." >&2
  exit 1
fi

# OrbStack — REQUIRED. Provides the automatic *.local HTTPS domains (no host
# ports, no /etc/hosts). It's a fast, lightweight Docker/Linux runtime for macOS:
# far less CPU/RAM and quicker startup than Docker Desktop, with built-in local
# domains + TLS — which this compose setup depends on.
if [ "$(docker context show 2>/dev/null)" != "orbstack" ]; then
  echo "OrbStack isn't your active Docker provider (this stack needs its *.local domains)." >&2
  if command -v orb >/dev/null 2>&1 || [ -d /Applications/OrbStack.app ]; then
    echo "OrbStack is installed — start it ('open -a OrbStack'), then re-run." >&2
  else
    offer_install "OrbStack" "brew install --cask orbstack"
  fi
  echo "Then re-run." >&2; exit 1
fi

# New Relic CLI — OPTIONAL. APM + log monitoring. The backend ships the agent but
# stays dormant until NEW_RELIC_LICENSE_KEY is set, so this is non-blocking. Free
# account: https://newrelic.com/signup — add the license key to Doppler to turn on.
if ! command -v newrelic >/dev/null 2>&1; then
  echo "(Optional) New Relic CLI not found — APM/log monitoring stays off until you add a key." >&2
  offer_install "New Relic CLI" "brew install newrelic-cli" || true
fi

# --- resolve the Doppler project up front (before scaffolding anything) ---
# 2nd arg = use this name as-is (reuse if it exists). Otherwise default to $APP
# and, on a name collision, ask what to do.
DOPPLER_PROJECT="${2:-$APP}"
if [ "$#" -lt 2 ]; then
  while doppler projects get "$DOPPLER_PROJECT" >/dev/null 2>&1; do
    printf 'Doppler project "%s" already exists.\n  1) use existing  2) stop  3) enter a new name\nchoice [1/2/3]: ' "$DOPPLER_PROJECT" >&2
    read -r c
    case "$c" in
      1) break ;;
      2) echo "aborted." >&2; exit 1 ;;
      3) printf 'new doppler project name: ' >&2; read -r DOPPLER_PROJECT ;;
      *) echo 'pick 1, 2, or 3.' >&2 ;;
    esac
  done
fi

mkdir -p services   # create-next-app needs the parent dir to exist
# Init a repo here unless THIS dir is already a repo root. (rev-parse walks up to
# a parent repo, so compare its toplevel to $PWD — otherwise we'd skip the init
# when scaffolding inside an outer repo and leave the app without its own .git.)
if [ "$(git rev-parse --show-toplevel 2>/dev/null)" != "$(pwd -P)" ]; then
  git -c init.templateDir= init -q   # empty templateDir avoids a "templates not found" warning
fi

# --- services (skip install + git; root workspace install handles deps once) ---
npx --yes create-next-app@latest services/frontend \
  --ts --eslint --app --src-dir --tailwind --import-alias "@/*" --use-npm --skip-install --disable-git --yes
npx --yes @nestjs/cli new services/backend --package-manager npm --skip-install --skip-git

# --- root files from templates ---
for f in package.json docker-compose.yml; do
  sed "s/__APP_NAME__/$APP/g" "$DIR/templates/$f" > "$f"
done
sed "s/__APP_NAME__/$APP/g" "$DIR/templates/docker-compose.prod.yml" > docker-compose.prod.yml
for f in README.md CLAUDE.md; do
  sed -e "s/__APP_NAME__/$APP/g" -e "s/__DOPPLER_PROJECT__/$DOPPLER_PROJECT/g" \
    "$DIR/templates/$f" > "$f"
done
mkdir -p .github/workflows .husky
cp "$DIR/templates/ci.yml" .github/workflows/ci.yml
cp "$DIR/templates/gitignore" .gitignore
cp "$DIR/templates/dockerignore" .dockerignore

# production: multi-stage Dockerfiles (compiled output only) + Next standalone output
cp "$DIR/templates/frontend.Dockerfile" services/frontend/Dockerfile
cp "$DIR/templates/backend.Dockerfile" services/backend/Dockerfile
rm -f services/frontend/next.config.*
cp "$DIR/templates/next.config.ts" services/frontend/next.config.ts

# backend: New Relic APM + pino log forwarding (dormant without NEW_RELIC_LICENSE_KEY).
# Agent is preloaded via `node -r newrelic` in start.sh (the proven way) — not an in-app require.
cp "$DIR/templates/backend/main.ts"       services/backend/src/main.ts
cp "$DIR/templates/backend/app.module.ts" services/backend/src/app.module.ts
cp "$DIR/templates/backend/start.sh"      services/backend/start.sh
chmod +x services/backend/start.sh
sed "s/__APP_NAME__/$APP/g" "$DIR/templates/backend/newrelic.js" > services/backend/newrelic.js

# uniform typecheck script in each service (Next/Nest don't add one)
npm pkg set scripts.typecheck="tsc --noEmit" -w services/frontend -w services/backend

# --- Doppler: secrets live here, NEVER in a committed .env ---
PW="$(openssl rand -hex 16)"
doppler projects create "$DOPPLER_PROJECT" >/dev/null 2>&1 || true   # no-op if reusing
doppler setup -p "$DOPPLER_PROJECT" -c dev --no-interactive
doppler secrets set \
  POSTGRES_PASSWORD="$PW" \
  DATABASE_URL="postgresql://postgres:$PW@db:5432/$APP" \
  -p "$DOPPLER_PROJECT" -c dev >/dev/null

# backend: Prisma + New Relic + pino
npm install                                  # workspace install (also pulls husky/prettier)
npm i @prisma/client newrelic nestjs-pino pino-http -w services/backend   # runtime deps
npm i -D prisma dotenv -w services/backend                                # build/CLI deps (dotenv: prisma.config.ts)
( cd services/backend && npx --yes prisma init --datasource-provider postgresql )
# Prisma 7 emits TS into the generator output dir — point it INTO src/ so `nest build`
# compiles the client into dist (prod runs only compiled output, no node_modules/.prisma).
sed 's#\.\./generated/prisma#../src/generated/prisma#' services/backend/prisma/schema.prisma > services/backend/prisma/schema.prisma.tmp
mv services/backend/prisma/schema.prisma.tmp services/backend/prisma/schema.prisma
rm -f services/backend/.env services/backend/prisma/.env  # DATABASE_URL comes from Doppler, not a file
# Keep prisma.config.ts (backend root, outside src) out of the app build, so tsc's
# rootDir stays = src and compiled output lands at dist/main.js (not dist/src/main.js).
node -e 'const fs=require("fs"),f="services/backend/tsconfig.build.json";const j=JSON.parse(fs.readFileSync(f,"utf8"));j.exclude=[...new Set([...(j.exclude||[]),"prisma.config.ts"])];fs.writeFileSync(f,JSON.stringify(j,null,2)+"\n")'

# husky pre-commit (after install so the binary exists; overwrite husky's sample)
npx --yes husky init
cp "$DIR/templates/pre-commit" .husky/pre-commit
chmod +x .husky/pre-commit

# .squid manifest — the app's choices; every squid skill reads it (missing key = default).
. "$DIR/../lib/squid.sh"
squid_init
squid_default app "$APP"
squid_default secrets doppler          # doppler | dotenv (dotenv = tracked follow-up)
squid_default monitoring newrelic      # newrelic | none
squid_default realtime none            # pusher | none
squid_default workflows none           # inngest | none
squid_default dopplerProject "$DOPPLER_PROJECT"
[ "$(squid_get secrets doppler)" = dotenv ] && \
  echo "note: .squid secrets=dotenv isn't honored yet — scaffolded with Doppler." >&2

echo
echo "Scaffolded $APP (Doppler project: $DOPPLER_PROJECT). Next:"
echo "  doppler run -- docker compose up"
echo "  FE  https://$APP.local"
echo "  API https://$APP-api.local"
echo "  migrate: doppler run -- npm -w services/backend exec prisma migrate dev"
