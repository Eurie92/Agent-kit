---
name: playbooks
description: Library of per-project-type playbooks (stack options, test tools, security basics, before-publish checklists). Use when starting a project, picking a stack, or preparing to ship.
---

# Playbooks

A growing library, not a fixed list. A project can use several (e.g. a Discord bot with a web dashboard = bot + web). Each project lists its playbooks in `AGENTS.md`.

## Index

| Playbook | File | Covers |
|---|---|---|
| Web | `web.md` | Websites, web apps, SaaS, dashboards |
| Bot | `bot.md` | Discord and Telegram bots |
| Extension | `extension.md` | Browser extensions |
| App | `app.md` | Mobile and desktop apps |

## Using one
Read only the files you need. Project-specific needs go in the project's `AGENTS.md`, not in a shared playbook.

## No playbook fits
1. Research that project type (delegate to the Researcher in the routing file, `local/MODELS.md`; brief per GLOBAL §4: max 3 searches per job and a time budget): current official docs, common stacks, test tools, security risks, store or hosting rules.
2. Write `<type>.md` in the kit repo at `~/Desktop/Agent-kit/skills/playbooks/`, never in an installed copy (Antigravity's copies are overwritten by the installer). If you cannot write outside the project, draft it in the project's `docs/` and tell the user to move it. Use exactly these sections: When it applies · Stack options to research · Test tools · Required project commands · Security basics · Standards · Before-publish checklist · Sources. Under 120 lines. Every fact sourced.
3. Add a row to the index above.
4. Tell the user in one line that a new playbook was added. Commit it to the kit repo when the user next commits kit changes.
