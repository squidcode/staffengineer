---
name: squidapp
description: Scaffold a new squidcode app locally — Next.js (TS) frontend + NestJS/Prisma (TS) backend + Postgres container, wired with a root docker-compose using OrbStack magic domains (no host port conflicts), secrets in a per-app Doppler project (never a committed .env), husky pre-commit running eslint/prettier/tsc/jest, and a GitHub Actions workflow running those four checks in parallel on every PR. Use when the user says "squidapp", "scaffold an app", "new squidcode app", "bootstrap a project", or describes wanting this FE/BE/Postgres stack.
---

# squidapp

Run the bundled script **from inside an empty, freshly-created folder** — it scaffolds in place into `$PWD`. It is the deterministic source of truth; don't hand-recreate the boilerplate.

```bash
mkdir -p ~/dev/squidcode/myapp && cd ~/dev/squidcode/myapp
~/.claude/skills/squidapp/scaffold.sh                 # app-name defaults to folder name
```

⚠️ It writes into the current directory (including `CLAUDE.md`, `README.md`, `package.json`). **Never run it in a non-empty folder or an umbrella dir of projects** — it would bury existing files. The script refuses to run unless `$PWD` is empty (a `.git`/`.envrc` is tolerated), but always `mkdir && cd` into a new dir first.

`app-name` defaults to the current folder name; it's the Postgres DB name + `.local` domain base (kebab-case). Pass it as `$1` to override. Optional `doppler-project` (`$2`) overrides the Doppler project name (reused as-is if it exists).

### Preflight (runs first)

The script checks tooling before scaffolding and offers `brew` installs (relay any prompt to the user):
- **Doppler** (required) — must be installed and logged in (`doppler login`); secrets + every run depend on it. Exits if missing/unauthed.
- **OrbStack** (required) — must be the active Docker provider (`docker context show` = `orbstack`); the `.local` HTTPS domains depend on it. Exits if Docker Desktop is active instead.
- **New Relic CLI** (optional, non-blocking) — only suggested; APM/logs stay dormant without a key.

If no `doppler-project` is given and a Doppler project named `<app-name>` already exists, the script prompts **before** scaffolding anything: `1) use existing  2) stop  3) enter a new name`. Relay this choice to the user. To run non-interactively, pass the project name as the 2nd arg.

## What you get

```
<app>/
  services/frontend     Next.js, TS, App Router, Tailwind  → <app>.local
  services/backend      NestJS, TS, Prisma (postgresql)    → <app>-api.local
                        + pino logging + New Relic APM (optional, dormant w/o keys)
  README.md             run/secrets quickref + Doppler project name
  docker-compose.yml    frontend + backend + postgres:16   (OrbStack domains, no host ports)
  package.json          npm workspaces + root check scripts
  CLAUDE.md             "run npm/prisma inside the container" rule
  .gitignore            node_modules, .env (secrets never committed)
  .husky/pre-commit     lint → format:check → typecheck → test
  .github/workflows/ci.yml   4 parallel jobs on every PR
```

Plus a Doppler project named `<app>` (config `dev`) holding `POSTGRES_PASSWORD` + `DATABASE_URL` (generated password). No `.env` file — Prisma's is deleted on scaffold.

## After scaffolding

```bash
doppler run -- docker compose up          # FE https://<app>.local, API https://<app>-api.local
```

Dependencies and prisma always run **inside the container** (binary-compatible with prod), e.g. `docker compose exec backend npm i <pkg>`. See the scaffolded app's `CLAUDE.md`.

## Secrets — Doppler only

Secrets live in Doppler, never in a committed `.env`. `${VAR}` in `docker-compose.yml` is interpolated from the Doppler-injected shell, so every run is `doppler run -- …`. Add a secret with `doppler secrets set KEY=value -p <app> -c dev`; never write it to a file.

## Deploying

This skill only scaffolds local dev. The rest of the lifecycle: **squidinfra** (registry + `.do/app.yaml` + managed Postgres) → **squidci** (GitHub Actions: push to `main` → test → build amd64 → push DOCR → deploy) → **squidmon** (New Relic APM, Browser, logs, /health, dashboard, alerts).

## New Relic (optional)

Backend preloads the agent the proven way — `start.sh` runs `node -r newrelic …` only when `NEW_RELIC_LICENSE_KEY` is set (an in-app require loads too late to instrument) — plus `newrelic.js` config with log forwarding on. No key → plain `node`, fully dormant. To turn on: `doppler secrets set NEW_RELIC_LICENSE_KEY=… -p <app> -c prd` (squidmon does this) and redeploy. APM traces + pino logs then flow to NR.

## .squid manifest

Scaffolding writes `.squid/config.yml` — the app's choices, read by every squid skill (a missing file or key = the opinionated default, so a clean repo just works). Committed; never holds secrets. Edit it to deviate:

```yaml
app: myapp
secrets: doppler          # doppler | dotenv  (dotenv = tracked follow-up, not honored yet)
monitoring: newrelic      # newrelic | none   (none → squidmon skips)
realtime: none            # pusher | none     (squidpush sets pusher)
workflows: none           # inngest | none    (squidflow sets inngest)
dopplerProject: myapp
# added as you run the other skills:
infraProject: squidcode-infra   # squidinfra/squidci
region: nyc                      # squidinfra
infra: digitalocean             # squidinfra
ci: github                       # squidci
```

Every skill reads this for its defaults (so you don't re-pass `infra-project` / Doppler project to each one) and records its decisions back. Precedence: **explicit arg > env > manifest > built-in default**. Shared reader: `lib/squid.sh` (`squid_get` / `squid_set` / `squid_default`) — flat YAML, no `yq`.

## Notes

- Checks are uniform across both services via root workspace scripts (`npm run lint|format:check|typecheck|test`). Pre-commit and CI both call these, so they never drift.
- CI parallelism is a `fail-fast: false` matrix over the four check names — one job each.
- If the user wants a different stack (no Tailwind, pnpm, extra service), edit the script/templates rather than improvising per-run.
