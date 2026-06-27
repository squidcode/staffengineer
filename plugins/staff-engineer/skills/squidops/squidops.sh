#!/usr/bin/env bash
# squidops — verify the devops toolchain is installed AND authenticated.
# No -e: we want to check every tool even when earlier ones fail.
set -uo pipefail

ok()   { printf '  \033[32m✅ %s\033[0m\n' "$1"; }
warn() { printf '  \033[33m⚠️  %s\033[0m\n' "$1"; }
bad()  { printf '  \033[31m❌ %s\033[0m\n' "$1"; }
info() { printf '     %s\n' "$1"; }

# check_tool <name> <bin> <install_cmd> <auth_cmd> <what-it-is> <auth_help>
# auth_cmd empty → tool needs no auth. auth_cmd exits 0 when authenticated.
check_tool() {
  local name="$1" bin="$2" install="$3" authcmd="$4" what="$5" authhelp="$6"
  printf '\n\033[1m%s\033[0m — %s\n' "$name" "$what"

  if ! command -v "$bin" >/dev/null 2>&1; then
    bad "$name not installed."
    info "install: $install"
    printf '  Install now? [y = install / anything else = skip]: ' >&2
    read -r reply
    case "$reply" in
      y|Y) eval "$install" || warn "install failed — run manually: $install" ;;
      *)   warn "skipped — devops actions needing $name won't be available." ; return ;;
    esac
    command -v "$bin" >/dev/null 2>&1 || { warn "$name still not found."; return; }
  fi
  ok "$name installed."

  [ -z "$authcmd" ] && return
  if eval "$authcmd" >/dev/null 2>&1; then
    ok "$name authenticated."
  else
    warn "$name installed but NOT authenticated."
    info "$authhelp"
  fi
}

printf '\033[1msquidops — devops toolchain check\033[0m\n'

# brew first — it installs most of the rest.
check_tool "Homebrew (brew)" brew \
  '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"' \
  "" \
  "macOS package manager — installs most tools below." \
  ""

check_tool "git" git \
  "brew install git" \
  "git config user.email" \
  "version control." \
  "set identity: git config --global user.name '…' && git config --global user.email '…'. Push auth comes from gh."

check_tool "GitHub CLI (gh)" gh \
  "brew install gh" \
  "gh auth status" \
  "manage GitHub — PRs, reviews, repos, releases, issues." \
  "run 'gh auth login' (choose GitHub.com → login with a browser). Need an account? github.com/signup."

check_tool "DigitalOcean (doctl)" doctl \
  "brew install doctl" \
  "doctl account get" \
  "manage DigitalOcean — apps, droplets, databases, container registry." \
  "create a FULL-ACCESS token at cloud.digitalocean.com/account/api/tokens, then 'doctl auth init'. Per project use 'doctl --context <name> …'; never 'doctl auth switch'."

check_tool "AWS CLI (aws)" aws \
  "brew install awscli" \
  'aws sts get-caller-identity' \
  "Amazon Web Services — S3, EC2, Lambda, IAM, etc." \
  "inject from Doppler — keeps creds off disk: export AWS_ACCESS_KEY_ID / AWS_SECRET_ACCESS_KEY (e.g. via 'doppler run -- …'). 'aws configure' also works but writes ~/.aws/credentials. Keys from IAM. Account? aws.amazon.com."

check_tool "Google Cloud (gcloud)" gcloud \
  "brew install --cask google-cloud-sdk" \
  "gcloud auth list --filter=status:ACTIVE --format='value(account)' 2>/dev/null | grep -q ." \
  "Google Cloud SDK — GKE, Cloud Run, GCS, Cloud SQL, etc." \
  "run 'gcloud auth login' (browser), or a service account: 'gcloud auth activate-service-account --key-file=<json>' / set GOOGLE_APPLICATION_CREDENTIALS (e.g. via Doppler) to keep it off disk. Account? cloud.google.com."

check_tool "Doppler (doppler)" doppler \
  "brew install dopplerhq/cli/doppler" \
  "doppler me" \
  "secrets/password manager — stores env secrets and injects them at runtime ('doppler run -- …'); the source of truth, no committed .env." \
  "run 'doppler login' (browser auth). Need an account? dashboard.doppler.com."

check_tool "New Relic (newrelic)" newrelic \
  "brew install newrelic-cli" \
  '[ -n "${NEW_RELIC_API_KEY:-}${NEW_RELIC_USER_KEY:-}" ] || newrelic profile list 2>/dev/null | grep -q .' \
  "observability — with a USER key the CLI can create apps, dashboards, alerts and query NerdGraph, not just read." \
  "inject from Doppler at runtime — keeps the key off disk: 'doppler run -p <proj> -c <cfg> -- …'. squidops accepts NEW_RELIC_API_KEY or NEW_RELIC_USER_KEY; the newrelic CLI reads NEW_RELIC_API_KEY, so if Doppler names it NEW_RELIC_USER_KEY alias it: NEW_RELIC_API_KEY=\"\$NEW_RELIC_USER_KEY\". Avoid 'newrelic profile add' — it writes the token to ~/.newrelic (Doppler should stay the single source of truth). User keys: one.newrelic.com → Administration → API keys. Account? newrelic.com/signup."

check_tool "Cloudflare Wrangler (wrangler)" wrangler \
  "npm i -g wrangler" \
  "wrangler whoami" \
  "Cloudflare Workers CLI — deploy/manage Workers, Pages, KV, R2, D1, Queues. https://developers.cloudflare.com/workers/wrangler/" \
  "run 'wrangler login' (OAuth in browser) or export CLOUDFLARE_API_TOKEN. Need an account? dash.cloudflare.com/sign-up."

check_tool "Resend (resend)" resend \
  "brew install resend/cli/resend" \
  '[ -n "${RESEND_API_KEY:-}" ] || resend whoami' \
  "transactional email — send emails, verify domains, manage API keys; built for humans, AI agents, and CI/CD. https://resend.com/docs/cli" \
  "inject from Doppler — keeps the key off disk: export RESEND_API_KEY=re_… (e.g. via 'doppler run -- …'). 'resend login' also works but stores the key in the macOS Keychain. API keys: resend.com/api-keys. Account? resend.com/signup."

printf '\n\033[1mDone.\033[0m ✅ ready · ⚠️ needs attention · ❌ missing. Re-run after fixing anything flagged.\n'
