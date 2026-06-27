---
name: squidup
description: Update the installed squidcode ("squid") skills to the latest version. With no license it refreshes the free Staff Engineer skills from the public repo; with a saved license it pulls the full paid pack. Use when the user says "squidup", "update squid skills", "update my skills", or "get the latest squid skills".
---

# squidup

Updates your installed squid skills in place.

```bash
~/.claude/skills/squidup/update.sh
```

- **No license** (checked in the macOS Keychain) → refreshes the **free** skills (squidops, squidapp, squidup, squidupgrade) from `github.com/squidcode/staffengineer`.
- **License present** → the **full** paid pack (via the shop — wiring lands with the licensing backend).

Marketplace users can also just run `/plugin update`. After updating, restart Claude Code (or `/reload`) to pick up changes.
