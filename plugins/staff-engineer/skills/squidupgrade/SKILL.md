---
name: squidupgrade
description: Upgrade from the free Staff Engineer skills to the full paid squidcode pack (squidinfra, squidci, squidmon, squidpush, squidflow). Opens the shop, saves your license to the macOS Keychain, and installs the full set; if already licensed, upgrades to the latest. Use when the user says "squidupgrade", "buy the full pack", "unlock the paid skills", "upgrade squid", or asks for deploy/infra/monitoring/CI skills they don't have yet.
---

# squidupgrade

Move from the free tier to the full paid pack.

```bash
~/.claude/skills/squidupgrade/upgrade.sh
```

- **No license** → explains what the paid pack adds, **opens the shop**, you buy + paste your license; it's saved to the macOS Keychain and the full pack installs.
- **License present** → upgrades to the latest full pack (same as a paid `squidup`).

**The full pack adds:** `squidinfra` (DigitalOcean infra), `squidci` (GitHub CI/CD), `squidmon` (New Relic), `squidpush` (real-time / Pusher), `squidflow` (durable workflows / Inngest).
