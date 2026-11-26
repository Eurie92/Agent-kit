# Decisions (kit)

Kinds: Locked (by user), Delegated (by agent), Open. Made 2026-11-23 during kit planning.

| # | Decision | Status |
|---|---|---|
| D1 | Lead = Claude Opus 5.5. Gemini 4 Neon = outside auditor only, run async. Implementation = Sonnet 5.5, bulk = Haiku 5.5, research = Sonnet 5.5 (Aedwon's chain). Gemini Hydrogen and Flash paused until Antigravity in T3 starts fast (see `local/MODELS.md`). | Locked by you (revised 2026-11-24: Neon too slow as a worker in T3; routing now in D29) |
| D2 | Delegation by size rule. Small = lead does it now. Big/parallel/bulk = workers. | Locked by you |
| D3 | One thread per feature or bug batch. `save` → `docs/STATE.md`. `boot` in the next thread. | Locked by you |
| D4 | Source of truth = one GitHub repo + install script. Private first, public later. | Locked by you |
| D5 | Tests: bug = failing test first. Feature = Given/When/Then in spec, tests before "done". Tiny/UI tweak = proof by screenshot or run output. | Locked by you |
| D6 | Agent may commit + push to a feature branch once verified. Must ask before: merge to main, deploy, publish, delete data, secrets, paid services. | Locked by you |
| D7 | Before a non-trivial build, agent asks minimal / balanced / hardened with scope + time for each. | Locked by you |
| D8 | Caveman in chat. Normal English in files (specs, plans, docs, commits, PRs). | Locked by you |
| D9 | New projects get a full kickoff (brainstorm → stack research → spec → plan). | Locked by you |
| D10 | Playbooks are a growing library, not fixed types. Seeds: web, bots, browser extension, mobile/desktop app. A project can use several. If none fits, the agent researches and writes a new playbook first, then adds it to the library. | Locked by you (revised) |
| D11 | Own lean skills instead of Superpowers. Borrow its good ideas. | Locked by you |
| D12 | Audit and trim installed skills. Core global, the rest per project. | Locked by you |
| D13 | Planning effort = Opus xhigh. Normal build = Opus medium. | Locked by you (from your message) |
| D14 | Kit scope = **Balanced** (~3–4 h). | Locked by you |
| D15 | Orca no longer used → remove its hooks (Claude, Codex, Antigravity) and Orca skills, with backups. | Locked by you |
| D16 | Codex stays off in T3. Kit still writes `~/.codex/AGENTS.md` so it works if turned on later. | Locked by you |
| D17 | Repo folder = `~/Desktop/Agent-kit`. GitHub repo `Eurie92/Agent-kit`, public since 2026-11-24. | Locked by you |
| D18 | Pilot projects = two of the owner's own projects (a Discord bot and an app). | Decided on delegation (change anytime) |
| D19 | Advisor = Fable 5.2. Lead calls it on its own, only for these triggers: security/auth/payments, a bug still failing after 2 fix attempts, a big design ruling. One-line notice each time. | Locked by you |
| D20 | The whole kit is in English. Rules taken from Aedwon's workflow are rewritten in our own words, and the README credits him with a link. He is OK with it (per you). | Locked by you |
| D21 | Usage split: lead (Opus) on the main Claude account; advisor and Claude workers on a second Claude account. | Locked by you |
| D22 | Workers and advisor run as T3 child threads (`delegate_task`), not headless CLIs. Headless only for scripts and scheduled automation. | Decided on delegation |
| D23 | `kickoff` runs only when the user asks (`/kickoff` or "kickoff"). GLOBAL §3 and the README say so, to match the skill. | Decided on delegation |
| D24 | Antigravity wiring: skills are copies, not junctions (it does not follow junctions). T3 Code's Antigravity loads no rule files at all (not global ones, not the project's `AGENTS.md` or `.agents/rules/`; tested 2026-11-24), only skills. So the `handoff` boot step and the project `AGENTS.md` template tell the agent to read the kit rules when they are missing. In T3, Antigravity threads start with `boot`. | Decided on delegation |
| D25 | `handoff` boot: a docs-only save commit on top of STATE's "Last commit" is expected, not a mismatch. | Decided on delegation |
| D26 | Before the repo goes public: scrub private paths and project names from docs and lessons. Done 2026-11-24: D17, D18, D21 and D29 no longer name a local user path, private projects or account names. `docs/LESSONS.md` keeps the owner's verbatim words (GLOBAL §10 requires them) and holds no paths. History: before going public (2026-11-24) the repo was republished as one fresh commit, authored with the GitHub no-reply address, so old text and the personal email are not in the public history. A local bundle of the old history is kept outside the repo. | Done |
| D27 | v0.1.0 audit (Gemini 4 Neon, 15 findings): 12 fixed in 0.2.0 plus the translation and label parts of #15, #13 handled cheaply (`kickoff` adds `@AGENTS.md` to a project `CLAUDE.md`), #11 and the private-path part of #15 moved to D26. Rejected: forcing Windows-1252-safe text (the files are UTF-8 and read fine), and asking the user before writing a new playbook or standards sheet (a one-line notice is enough). | Decided on delegation |
| D28 | Shareable kit: personal settings live in git-ignored `local/MODELS.md` and `local/PREFS.md`. A `setup` skill interviews each user one question at a time and writes them; `INSTALL.md` tells any agent how to install. The installer refuses to run without them. Scope: Balanced (spec approved 2026-11-24). | Locked by you |
| D29 | Your routing (preset B): Claude for everything, workers included. Lead Opus 5.5 (main account); advisor Fable 5.2, implementation and research Sonnet 5.5, bulk Haiku 5.5 (all on a second Claude account). Gemini 4 Neon is an optional auditor, async, high-stakes only; if it runs past its budget, Fable 5.2 reviews in a fresh context. Replaces the routing part of D1. | Locked by you |
| D30 | Lead effort: extra-high for kickoff, spec, plan, hard bugs and big design rulings; medium for building and small tasks (matches D13). Workers stay T3 child threads (D22): running them headless saves no tokens, and Neon's slowness is start-up time (40–110 s per run) plus occasional network timeouts, not the thread wrapper. | Decided on delegation |
| D31 | macOS/Linux installer: `install/install.sh`, a bash port of `install.ps1` with the same behavior. Tests run in Git Bash on Windows (emulated symlinks) and once on GitHub Actions (Linux and macOS) before merge. The workflow is manual-only afterwards, because macOS minutes count ten times on a private repo. Scope: Balanced (picked 2026-11-24). | Locked by you |
| D32 | On macOS and Linux the installer uses the same harness paths as on Windows (`~/.gemini/config/skills` for Antigravity, `~/.agents/skills` for Codex) and still copies Antigravity skills. Not yet checked on a real Mac or Linux machine with those tools; change it if a user reports other paths. | Decided on delegation |
| D33 | Open to contributors: CI runs on every pull request and push to main (free on a public repo; replaces the manual-only workflow in D31), releases publish from `vX.Y.Z` tags with notes from CHANGELOG, and `main` requires a pull request with green CI (the owner can bypass). Contributors follow `CONTRIBUTING.md`. | Decided on delegation |
| D34 | Bots: the kit ships a `bots` skill and `templates/bots/` for the Lite tier only (a scheduled or webhook task on stock T3 Code that loads a bot folder). The Full tier (Settings → Bots) lives in a private T3 Code fork and is documented, not shipped; a shared build must drop "T3 Code" branding (T3 TRADEMARK.md). Safe defaults: owner only, Ask first, no outward action without a "yes". | Decided on delegation (change in `skills/bots/SKILL.md`) |
