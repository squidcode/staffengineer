# __APP_NAME__

Next.js (frontend) + NestJS/Prisma (backend) + Postgres. Local dev via OrbStack + Doppler.

## Run dependency / prisma / build commands INSIDE the container

The host is macOS; production and the dev containers are Linux. Native deps
(esbuild, prisma engines, bcrypt, etc.) are platform-specific, so installing on
the host produces binaries that break in the container and in prod. **Always run
`npm install`, `npm i <pkg>`, and `prisma` inside the running container** so the
installed binaries match production.

```bash
# add/update deps (pick the service)
docker compose exec backend  npm i <pkg>
docker compose exec frontend npm i <pkg>

# prisma (needs the DB env → go through doppler run)
doppler run -- docker compose exec backend npx prisma migrate dev
doppler run -- docker compose exec backend npx prisma generate
```

`node_modules` are container-only anonymous volumes (see `docker-compose.yml`) —
the host copy is never used, which is why host installs are pointless here.

## Secrets

In Doppler only (project `__DOPPLER_PROJECT__`, config `dev`) — never a committed
`.env`. Every run that needs secrets is `doppler run -- …`.

## Logging — New Relic

The backend uses pino (`nestjs-pino`); New Relic forwards those logs to NR Logs
when `NEW_RELIC_LICENSE_KEY` is set (otherwise they just go to stdout — the code
is always there, the agent is dormant without keys). The agent is **preloaded via
`node -r newrelic` in `services/backend/start.sh`** (prod) — the proven way; never
add an in-app `require('newrelic')` / `import`, it loads too late to instrument.
**As you write backend code,
log everything**: `debug` for flow/state, `info` for meaningful events, and
`error` for every caught failure (with the error object). Inject the logger
(`PinoLogger` / Nest `Logger`) rather than using `console.*` so the lines reach NR.

## Worklog — `docs/work/log-YYYY-MM-DD.md`

Keep a running daily worklog as the app is developed.

1. **Get the real system date — never guess it:** `date +%F`.
2. Create or append to `docs/work/log-<that-date>.md`.
3. Log continuously: what we did, what we learned, what worked, what didn't.
   Append entries at natural checkpoints **automatically**, and always when the
   user says to log work. One file per day; append, don't rewrite earlier entries.
