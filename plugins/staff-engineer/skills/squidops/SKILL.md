---
name: squidops
description: Check the squidcode devops toolchain is installed AND authenticated — brew, git, gh, doctl, AWS CLI, gcloud, Doppler, New Relic CLI, Cloudflare wrangler, Resend. For each tool it confirms presence (offers a brew/npm install if missing, or lets you skip), then verifies authentication and explains how to log in or create an account when not. Use when the user says "squidops", "check my devops setup", "is my toolchain ready", "devops doctor", "set up resend/outgoing email", or before infra work that needs these CLIs.
---

# squidops

Run the doctor. It checks each tool's presence and auth, offers installs, and explains how to authenticate what's missing.

```bash
~/.claude/skills/squidops/squidops.sh
```

## What it checks

| Tool | For | Auth check |
|------|-----|------------|
| brew | installs everything else | — |
| git | version control | `user.email` set |
| gh | GitHub: PRs, reviews, repos | `gh auth status` |
| doctl | DigitalOcean: apps, droplets, DBs | `doctl account get` |
| aws | AWS: S3, EC2, Lambda, IAM | `aws sts get-caller-identity` |
| gcloud | Google Cloud: GKE, Cloud Run, GCS | active account exists |
| doppler | secrets/password manager | `doppler me` |
| newrelic | observability (create apps/dashboards via User key) | profile exists, or `NEW_RELIC_API_KEY`/`NEW_RELIC_USER_KEY` in env (e.g. via `doppler run`) |
| wrangler | Cloudflare Workers/Pages/KV/R2/D1 | `wrangler whoami` |
| resend | outgoing/transactional email — send, verify domains, API keys | `resend whoami`, or `RESEND_API_KEY` in env (e.g. via `doppler run`) |

## Behavior

- **Missing** → prints what it is + the install command, offers to install now; `y` installs, anything else skips (with a note that devops actions needing it won't work).
- **Installed but unauthenticated** → prints exactly how to log in and where to get an account.
- Non-fatal throughout: every tool is checked even if earlier ones fail. Re-run after fixing anything flagged.
- Relay any interactive prompt to the user when running this on their behalf.
