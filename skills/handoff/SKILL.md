---
name: handoff
description: Save or restore project state between threads. Use when the user says "save", "boot", "handoff", "wrap up", or starts a new thread in an existing project.
---

# Handoff (save / boot)

Threads carry no memory between each other. Files do. `docs/STATE.md` is the bridge.

## save
1. Rewrite `docs/STATE.md` from scratch using the template below. Max 60 lines. Facts only.
2. If decisions were made this session, append them to `docs/DECISIONS.md` with who made them.
3. If `docs/PLAN.md` exists, tick finished tasks.
4. Commit the docs if the rest of the work is verified (GLOBAL §8): stage only the doc files you changed, by name (never `git add -A` or `.`). Otherwise leave them uncommitted and say so.
5. Reply: one line "Saved." plus the "Next" items.

## boot
1. If "Global rules (Agent-kit)" is not in your context, read `~/Desktop/Agent-kit/rules/GLOBAL.md`, `~/Desktop/Agent-kit/local/MODELS.md` and `~/Desktop/Agent-kit/local/PREFS.md` first and follow them. (Antigravity inside T3 Code loads no rule files on its own.) If the `local/` files are missing, say the kit is not set up and offer the `setup` skill.
2. Read, in order: `AGENTS.md`, `docs/STATE.md`, headings of `docs/DECISIONS.md`, open tasks in `docs/PLAN.md`. Nothing else yet.
3. Run `git status` and `git log --oneline -5` to check STATE matches reality. Flag any mismatch. A docs-only save commit on top of the "Last commit" in STATE is expected, not a mismatch.
4. Reply in 5 lines max: where we are, what is next, any blocker, then ask what to do.
5. Do not read old threads unless the user gives a link and the files miss something.

If `docs/STATE.md` is missing: say so, build it from `git log`, the code and the docs, then show it to the user.

## STATE.md template

```markdown
# State
Updated: <YYYY-MM-DD> · Branch: <branch> · Last commit: <short sha> <subject>

## Now
<1-3 lines: what the project is doing right now>

## Done this session
- ...

## Next
1. ...

## Blockers
- none

## Open decisions
- ...

## Related threads
- <link or title>: <why it matters>
```

"Last commit" is the last work commit before the save. The save commit that adds this file comes after it and is not listed.
