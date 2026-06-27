# Staff Engineer 🦑

**Free [Claude Code](https://code.claude.com) skills that give Claude staff-engineer instincts for shipping real apps.**

A small, opinionated toolkit: scaffold a production-shaped full-stack app in seconds, and keep your dev machine's toolchain honest — all with best practices baked in (Docker, Doppler secrets, OrbStack domains, pre-commit checks, parallel CI).

## Install (Claude Code marketplace)

```
/plugin marketplace add squidcode/staffengineer
/plugin install staff-engineer@staffengineer
```

Then just talk to Claude — e.g. *"scaffold a new app called orbit"* or *"check my devops toolchain"*.

## What's included (free)

| Skill | What it does |
|-------|--------------|
| **squidapp** | Scaffold a local app: Next.js + NestJS/Prisma + Postgres, OrbStack magic domains, Doppler-managed secrets (no committed `.env`), husky pre-commit, parallel PR CI. Multi-stage prod Dockerfiles. |
| **squidops** | Devops toolchain doctor: checks brew, git, gh, doctl, AWS CLI, gcloud, Doppler, New Relic, Cloudflare wrangler, Resend are installed **and authenticated**; offers installs and explains how to log in. |
| **squidup** | Update your installed squid skills to the latest. |
| **squidupgrade** | Unlock the full pack (deploy + monitoring + more). |

## Upgrade to the full pack

The paid pack adds the whole ship-it lifecycle:

- **squidinfra** — DigitalOcean infra (container registry, App Platform, managed Postgres)
- **squidci** — GitHub Actions CI/CD (build amd64 → push DOCR → deploy)
- **squidmon** — New Relic (APM, Browser, logs, dashboard, alerts)
- **squidpush** — real-time messaging (Pusher / self-hosted Soketi)
- **squidflow** — durable workflows / background jobs (Inngest)

Run **`squidupgrade`** in Claude (or just ask *"unlock the full squid pack"*).

## License

MIT — see [LICENSE](LICENSE).
