# __APP_NAME__

Next.js (frontend) + NestJS/Prisma (backend) + Postgres, local dev via OrbStack + Doppler.

## Run

```bash
doppler run -- docker compose up
```

- Frontend: https://__APP_NAME__.local
- API: https://__APP_NAME__-api.local

## Secrets — Doppler only

Secrets live in Doppler, **never** in a committed `.env`.

- Doppler project: **`__DOPPLER_PROJECT__`** (config `dev`)
- Add a secret: `doppler secrets set KEY=value -p __DOPPLER_PROJECT__ -c dev`

## Prisma

```bash
doppler run -- npm -w services/backend exec prisma migrate dev
```

## Deploy (DigitalOcean)

1. **squidinfra** — registry + `.do/app.yaml` (App Platform spec + managed Postgres).
2. **squidci** — GitHub Actions: push to `main` → 4 parallel checks → build amd64 images → push to DOCR → deploy.

Secrets stay in Doppler (`prd` config) and are injected at deploy — never committed to `.do/app.yaml`.

3. **squidmon** — New Relic APM + Browser monitoring, structured logs, `/health` synthetic, dashboard, and alerts.
