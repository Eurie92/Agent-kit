# Agent-kit

One set of rules and skills for AI coding agents, shared by Claude Code, Antigravity (Gemini) and Codex. It covers the whole flow, from a new idea to a published release, without heavy process on small jobs.

- Small bug or tweak: the agent just does it, with a failing test or a screenshot as proof.
- Real feature: pick a scope size, write a short spec, plan, build, prove.
- New project: full kickoff with stack research, then a spec and a plan.
- Release: a checklist gate and an outside audit, and nothing goes public without your "yes".
- Threads stay cheap: say `save` at the end of a session and `boot` at the start of the next one. Files carry the memory, not chat history.

## Quick start (tutorial)

Requirements: git, plus one of:
- Windows with PowerShell 5.1 or later (`install/install.ps1`). No admin rights or Developer Mode needed.
- macOS or Linux with bash (`install/install.sh`). The bash 3.2 that ships with macOS works.

**Easiest: let your agent do it.** In Claude Code, Antigravity or Codex, say:

> Install Agent-kit from https://github.com/Eurie92/Agent-kit. Follow its INSTALL.md.

The agent clones the kit to `~/Desktop/Agent-kit` and runs the `setup` skill:
- It reads your existing global rules and skills and reports any clashes.
- It asks one question at a time: tools, models and accounts, routing, auditor, chat style, lead effort, and your own always/never rules.
- It writes your answers to `local/MODELS.md` and `local/PREFS.md`. Git ignores `local/`, so your choices stay on your machine.
- It runs the installer (a dry run first) and checks the result.

To change your choices later, say `setup`.

**By hand.** On Windows (PowerShell):

```powershell
git clone https://github.com/Eurie92/Agent-kit "$HOME\Desktop\Agent-kit"
cd "$HOME\Desktop\Agent-kit"
mkdir local
copy rules\MODELS.example.md local\MODELS.md   # then edit it: pick a preset, set your models
notepad local\PREFS.md                          # chat style and personal rules (format in skills/setup/SKILL.md)
powershell -ExecutionPolicy Bypass -File install\install.ps1 -DryRun   # see what changes
powershell -ExecutionPolicy Bypass -File install\install.ps1           # do it
```

On macOS or Linux:

```bash
git clone https://github.com/Eurie92/Agent-kit ~/Desktop/Agent-kit
cd ~/Desktop/Agent-kit
mkdir -p local
cp rules/MODELS.example.md local/MODELS.md   # then edit it: pick a preset, set your models
nano local/PREFS.md                          # chat style and personal rules (format in skills/setup/SKILL.md)
bash install/install.sh --dry-run            # see what changes
bash install/install.sh                      # do it
```

Both installers take the same options: `-DryRun` / `--dry-run`, `-Harness claude,gemini` / `--harness claude,gemini`, and `-Uninstall` / `--uninstall`. The how-to table below uses the Windows names.

The installer stops, without changing anything, if `local/MODELS.md` or `local/PREFS.md` is missing. Keep the kit at `~/Desktop/Agent-kit`, because the rules and skills point there.

Then open a new agent thread in any project and say `boot`. The agent reads `AGENTS.md` and `docs/STATE.md`. If they are missing, it offers to create them from `templates/project/`. If the project has its own `CLAUDE.md`, it should contain the line `@AGENTS.md` so Claude Code loads the project rules (`kickoff` adds it).

## How-to

| I want to... | Say or do |
|---|---|
| Start a new project | New thread on your strongest model at high effort, then type `/kickoff` (Claude Code) or say `kickoff` |
| Continue work | New thread, say `boot` |
| End a session | Say `save` (also when a thread has auto-compacted twice) |
| Build a feature | Describe it. Non-trivial work triggers the `feature` flow |
| Fix a bug | Describe it. The agent writes a failing test, fixes it, then shows the test passing |
| Release | Say `ship` |
| Get an outside review | Say `audit` |
| Add a project type | Say so. The agent researches it and writes a new playbook |
| Change models, auditor or chat style | Say `setup` (or edit `local/MODELS.md` / `local/PREFS.md`, then re-run the installer) |
| Update after editing the kit | Re-run the installer (Gemini and Codex get a copy of the rules, and Gemini gets copies of the skills; Claude rules and Claude/Codex skills are live links) |
| Remove it | `install.ps1 -Uninstall` (removes only what it added; backups are in `~/.agent-kit-backups/`) |
| Install for one harness | `install.ps1 -Harness claude` (or `gemini`, `codex`) |
| Test the macOS/Linux installer | `bash install/test-install.sh` (fake homes in a temp folder). On GitHub: Actions → "install.sh tests" → Run workflow (Linux and macOS; manual only, since macOS minutes cost ten times as much on a private repo) |

## Reference

```
INSTALL.md     instructions for an agent installing the kit
rules/
  GLOBAL.md           always-on rules for every project and harness
  MODELS.example.md   model layers and routing presets to copy from
local/         your own settings, git-ignored (written by `setup`)
  MODELS.md    your model routing and accounts
  PREFS.md     your chat style and always/never rules
skills/        loaded only when needed
  setup/       interview → local/ files → install → verify
  kickoff/     idea → research → spec → plan → scaffold (manual only: /kickoff)
  feature/     scope size → spec section → plan → build → proof
  handoff/     save / boot through docs/STATE.md
  ship/        pre-publish gate
  audit/       outside review by a model from another vendor
  playbooks/   per project type: web, bot, extension, app, and more as needed
  standards/   proven standards per field, cited in specs
templates/project/
  AGENTS.md    project rules (150 lines max)
  docs/        STATE, SPEC, PLAN, DECISIONS, LESSONS, RESEARCH
install/
  install.ps1        installer for Windows
  install.sh         installer for macOS and Linux (same behavior)
  test-install.sh    tests for install.sh
docs/          this kit's own decisions and lessons
```

Where the installer wires things:

| Harness | Rules | Skills |
|---|---|---|
| Claude Code | `@` imports of `rules/GLOBAL.md`, `local/MODELS.md` and `local/PREFS.md` in `~/.claude/CLAUDE.md` | links in `~/.claude/skills/` |
| Antigravity | copy of those three files in `~/.gemini/GEMINI.md` | copies in `~/.gemini/config/skills/` (Antigravity does not follow junctions there) |
| Codex | copy of those three files in `~/.codex/AGENTS.md` (32 KiB cap) | links in `~/.agents/skills/` |

Links are directory junctions on Windows and symlinks on macOS and Linux. Antigravity gets copies on every system, to match Windows.

The installer writes only between `agent-kit:start` and `agent-kit:end` markers and updates that block in place. Your own lines in those files are kept. If the markers are broken (duplicate or unpaired), it skips the file with a warning. If a skill folder with the same name already exists and is not the kit's, it is skipped with a warning. Skills removed from the kit are unlinked or removed on the next run. Antigravity's skill copies are rebuilt from the kit, so files added inside them are lost (a backup is taken first); edit the kit, not the copies.

T3 Code runs Antigravity with a private Gemini home and links in only the skills folder. There it loads skills but no rule files: not the global ones (tested: `GEMINI.md` in the home root, `config/GEMINI.md`, `config/rules/`) and not the project's `AGENTS.md` or `.agents/rules/`. So the `handoff` skill's `boot` step, and each project's `AGENTS.md` from `templates/project/`, tell the agent to read the kit rules itself when they are missing. In T3, start every Antigravity thread with `boot`.

## Explanation

**Why layers.** Rules are always loaded, so they stay short. Skills load only when a task needs them. Project facts live in each project's `AGENTS.md`. This keeps every prompt small.

**Why size the task first.** Most work is small. Running a spec-and-plan process on a one-line fix wastes time and tokens. The rules make the agent do small things now and save the process for work that needs it.

**Why an outside auditor.** A model is a weak judge of its own work. A model from another vendor reviews specs and diffs before high-stakes releases. It only reports; it never fixes. It is optional: with one vendor only, the advisor model reviews in a fresh context instead (weaker, but better than nothing).

**Why `local/`.** Everyone has different models, accounts and taste. The shared rules stay the same for everyone; your own choices live in git-ignored files, so pulling kit updates never overwrites them and sharing the kit never leaks them.

**Why files, not long threads.** A thread that auto-compacts loses detail and costs more each turn. `save` writes the state to a 60-line file, and a fresh thread `boot`s from it.

**Model layers** (presets in `rules/MODELS.example.md`, yours in `local/MODELS.md`): an advisor for rare hard calls, the lead in your thread, implementation and bulk workers for delegated work, a researcher, and an optional outside auditor. The lead does small work itself and delegates only parallel, bulk or research work. The lead runs at extra-high effort for planning and hard bugs, and at medium for building.

## Credits

Much of the rule set is adapted, in our own words, from [Aedwon's agent workflow](https://aedwon.site/workflow): the talk rules, the org chart and escalation path, the top-down spec flow, scope sizes, the standards library, decision records, proof before done, the outside audit and the lessons process. Thanks, Aedwon.

Where this kit differs: a `setup` interview writes each user's own models and chat style; merging to main needs the user's OK; bugs skip the spec flow; the `save`/`boot` handoff comes from another friend's setup; the outside auditor is optional and runs async.

## License

MIT. See [LICENSE](LICENSE).
