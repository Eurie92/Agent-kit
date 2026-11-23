# Spec: macOS/Linux installer and public scrub (v0.4.0)
Status: approved 2026-11-24 (scope pick: Balanced, ~2–3 h) · Branch: `feat/cross-platform`

## Part A: plain language (user approves this part)

### Outcome
The kit installs on macOS and Linux the same way it does on Windows, with one command. The tracked docs no longer name a local user path, private projects or account names, so the repo is one step closer to going public.

### In scope
- `install/install.sh`: a bash installer with the same options, behavior and messages as `install.ps1`.
- Tests for it that run in Git Bash on this PC, plus one GitHub Actions run on Linux and macOS before merge. After that run, the workflow is manual-only (about 35 of the free private-repo minutes, no ongoing use).
- README, `setup` skill and wording updates for macOS and Linux.
- D26 scrub of `docs/DECISIONS.md`.

### Out of scope
- Using `install.sh` on Windows (Git Bash). Windows keeps `install.ps1`.
- Rewriting git history, or a fresh-history copy, to remove old text and the author email (needed before going public; needs the owner's OK).
- Testing with real Claude Code, Antigravity or Codex on a Mac or Linux machine.

### Risks and tradeoffs
- macOS and Linux harness paths are assumed to match Windows (D32). If a tool keeps skills elsewhere there, the links land in the wrong folder until someone reports it.
- Git Bash only emulates symlinks, so the real symlink behavior is proven by the one Actions run, not by local tests.

### How "done" is judged
1. Given a kit with no `local/` files,
   When `install.sh` runs (without `--uninstall`),
   Then it exits 1, names the missing files and changes nothing.
2. Given `--dry-run`,
   When it runs,
   Then the home folder is byte-identical afterwards.
3. Given a fresh home,
   When `install.sh` runs twice,
   Then the second run reports "Done. Nothing to change.", the Claude block has three imports in order, the Gemini and Codex copies contain all three files, Claude and Codex skills are symlinks and Antigravity skills are marked copies.
4. Given user text and a CRLF file around an old managed block (including one written by `install.ps1`),
   When it runs,
   Then the block is replaced in place and every byte outside it is kept.
5. Given a skill added to, changed in or removed from the kit,
   When it runs,
   Then the links and copies follow, and a changed copy is backed up first.
6. Given a foreign link, a foreign folder or broken markers,
   When it runs (install or uninstall),
   Then it skips them with a message and leaves them as they are.
7. Given `--uninstall`,
   When it runs,
   Then the block, links and copies are gone, files that held only the block are deleted, user text stays, and the kit is untouched.
8. Given the tests,
   When they run in Git Bash here and once on GitHub Actions (Ubuntu with bash 5; macOS with the system bash 3.2),
   Then every check passes.
9. Given the tracked files,
   When `git grep` looks for the local user path, private project names and account labels,
   Then only `docs/LESSONS.md` quotes remain, and they hold no paths.

### Standards applied
- **POSIX shell and utilities.** Only POSIX options of awk, cp, find, ln, cksum and friends, so BSD (macOS) and GNU (Linux) tools behave the same. Source: https://pubs.opengroup.org/onlinepubs/9799919799/
- **Bash 3.2 compatibility.** macOS ships bash 3.2; no associative arrays, `mapfile` or `${var,,}`. Source: https://www.gnu.org/software/bash/manual/
- **GitHub Actions billing.** Private repos get limited free minutes and macOS minutes count ten times, so the workflow is manual-only. Source: https://docs.github.com/en/billing/managing-billing-for-your-products/managing-billing-for-github-actions/about-billing-for-github-actions
- **Least privilege for workflows.** `permissions: contents: read`. Source: https://docs.github.com/en/actions/security-for-github-actions/security-guides/security-hardening-for-github-actions

## Part B: technical notes (agent detail)

### Design
- Same flow as `install.ps1`: parse options, check `local/`, then per harness set the managed block and the skills; print a summary.
- Managed block: a line-based awk program (start/end markers counted; exit 3 when broken or duplicated), CRLF detected and kept, `cmp` decides "no change".
- Awk gets values through `ENVIRON`, not `-v` (which would expand backslashes). `-v BINMODE=3` stops Git Bash's gawk from dropping `\r`; other awks ignore it.
- Skills: `ln -s` for Claude and Codex; Antigravity gets copies with an `.agent-kit-copy` marker, compared by a sorted `cksum` signature.
- A link is ours when its target string or its physical path is the kit's skill folder.
- Backups go to a unique `~/.agent-kit-backups/<stamp>[-n]` folder.
- The workflow uses a temporary `push` trigger limited to the branch and the installer paths for the one approved run, because `workflow_dispatch` only works from the default branch. The next commit removes it.

### Edge cases
- Kit path with a space: Claude gets a copy of the rules instead of `@` imports, with a warning (same as Windows).
- Kit under the home folder: imports use `~/`.
- `--harness` accepts commas or spaces, any case; an unknown value or option exits 1.

### Security
- No network calls, no `sudo`, no `eval` of user input. Files are written only under the user's home and the temp folder.
- The workflow has read-only repo permissions and no secrets.

# Spec: setup interview and shareable config (v0.3.0, done)
Status: approved 2026-11-24 (Part A) · Scope size: balanced (~3 h)

## Part A: plain language (user approves this part)

### Outcome
Anyone can install the kit by telling their agent "install Agent-kit from <repo>". The agent interviews them one question at a time, reads the config files they already have, writes their personal settings into a local folder that git ignores, and then runs the installer. The shared rules stay vendor-neutral. Your own setup becomes all-Claude, with Gemini 4 Neon as an optional outside auditor that runs in the background.

### In scope
- A new `setup` skill, plus an `INSTALL.md` written for agents, so the install works even before any skill is installed.
- Interview, one question at a time, with a recommended answer for each:
  1. Which tools do you use?
  2. Which models and accounts do you have?
  3. Pick a routing preset.
  4. Do you want an outside auditor?
  5. Which chat style and language?
  6. How much effort should the lead use?
  7. Any "always" or "never" rules?
- Before asking, the agent reads the user's existing global rule files and skill folders, reports clashes, and asks how to resolve them. It never deletes the user's own text.
- Personal settings move to `local/` (git-ignored):
  - `local/MODELS.md` for routing;
  - `local/PREFS.md` for chat style, language and personal rules.
- The shared repo keeps `rules/MODELS.example.md`, with presets:
  - all one vendor;
  - one vendor plus an outside auditor;
  - mixed vendors.
- Your files after migration:
  - `local/MODELS.md`: Fable 5.2 advisor, Opus 5.5 lead, Sonnet 5.5 for implementation and research, Haiku 5.5 for bulk. Gemini 4 Neon is the auditor, optional, async and for high-stakes work only, with Fable 5.2 as fallback if it hangs.
  - `local/PREFS.md`: caveman chat.
- Lead effort guidance goes in the routing file: xhigh for kickoff, spec, plan and hard bugs; medium for build and small tasks.
- The installer reads the `local/` files. If they are missing, it stops, changes nothing, and points to setup.
- The README, the rules, the skills and the project template point to the new files.
- D26 is narrowed to the scrub of private paths and project names.

### Out of scope
- A macOS/Linux installer and automated installer tests in CI (hardened).
- Installing the kit anywhere other than `~/Desktop/Agent-kit`.
- The public-release scrub of the kit's own docs (D26).
- Fixing Antigravity's slow start-up. That is a network issue on this machine; an IPv4 preference is a possible system change for later, and only with your OK.

### Risks and tradeoffs
- Existing installs: after pulling this change, the installer stops until `local/` exists. This is intended, and the message says what to do.
- `local/` lives only on this machine. If the folder is lost, the setup is lost; re-running setup rebuilds it.
- The interview adds about 5 minutes to a first install.
- Gemini 4 Neon can still be slow, sometimes 6 minutes or more to start. Since it runs async and only for high-stakes work, it does not block you.

### How "done" is judged
1. Given a home folder with no kit config and no `local/` folder,
   When the installer runs,
   Then it stops with a message pointing to setup and changes nothing.
2. Given `local/MODELS.md` and `local/PREFS.md` exist,
   When the installer runs twice,
   Then the second run reports "Nothing to change". The Claude block imports `rules/GLOBAL.md`, `local/MODELS.md` and `local/PREFS.md`, and the Gemini and Codex copies contain all three.
3. Given setup has finished,
   When `git status` and `git ls-files` run in the kit,
   Then no file under `local/` appears.
4. Given a fresh Claude agent and a fake home that already has a user rule and a same-name skill folder,
   When the agent follows `INSTALL.md` with pre-filled answers,
   Then it:
   - reports both clashes;
   - lists the interview questions in order;
   - writes `local/` files that match the answers;
   - runs the installer against the fake home;
   - keeps the user's rule.
5. Given your real machine after migration,
   When a fresh Claude thread is asked for its routing,
   Then it states all-Claude workers, Neon as the optional async auditor, and caveman chat.
6. Given the old install block in `~/.claude/CLAUDE.md`,
   When the new installer runs,
   Then the block is replaced in place and nothing outside it changes.

### Standards applied
- **Twelve-Factor App, III. Config.** Keep per-deploy config apart from the shared code: local settings stay out of the repo. Source: https://12factor.net/config
- **gitignore.** Ignore local, per-machine files so they are never committed. Source: https://git-scm.com/docs/gitignore
- **OWASP Secrets Management.** Never collect or store secrets: the interview asks for account labels only, never tokens or passwords. Source: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- **Keep a Changelog, SemVer, Conventional Commits.** Version 0.3.0 is breaking for existing installs, which is still allowed under 0.x. Sources: https://keepachangelog.com/en/1.1.0/, https://semver.org/, https://www.conventionalcommits.org/

## Part B: technical notes (agent detail)

### Design
- New files:
  - `INSTALL.md` (repo root, for agents): if a user asks you to install or set up Agent-kit, clone it to `~/Desktop/Agent-kit` if it is not there, read `skills/setup/SKILL.md` and follow it.
  - `skills/setup/SKILL.md`: the interview and the steps that follow it (below).
  - `rules/MODELS.example.md`: layers, effort guidance, and the three presets.
  - `local/.gitkeep` is not used; the whole `local/` folder is ignored. Setup creates the folder.
- Setup steps:
  1. Read the existing state: `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md`, `~/.codex/AGENTS.md`, the skill folders, and any current `local/` files.
  2. Report clashes in one short list.
  3. Run the interview, one question per message, multiple choice where possible, with a recommendation.
  4. Show a summary and the files it will write, then wait for "yes".
  5. Write `local/MODELS.md` and `local/PREFS.md`.
  6. Run `install.ps1 -DryRun`, show the output, then run `install.ps1`.
  7. Verify: ask the user to open a new thread and say `boot`, or state the rules in a fresh child thread.
  - Re-running `setup` edits the existing `local/` files. It does not start over unless the user asks.
- `install.ps1`:
  - The rule sources are `rules/GLOBAL.md`, `local/MODELS.md` and `local/PREFS.md`.
  - Claude: three `@` imports.
  - Gemini and Codex: one copy that joins all three.
  - If `local/MODELS.md` or `local/PREFS.md` is missing, stop before any change and print the setup hint. `-Uninstall` skips this check.
- References to update:
  - GLOBAL §1: chat style comes from `local/PREFS.md`; the default is plain and short.
  - The GLOBAL header points to the routing file.
  - The `handoff` boot step reads the three files.
  - `templates/project/AGENTS.md`.
  - The `audit`, `kickoff` and `playbooks` skills: "the routing file (`local/MODELS.md`)".
  - The README: quick start becomes "tell your agent", the manual path stays, the layout gains `local/`, and the credits line is updated.
- Migration on this machine:
  - Move today's `rules/MODELS.md` content into `local/MODELS.md` with the new routing, and delete `rules/MODELS.md` from git.
  - Put the caveman line in `local/PREFS.md`.

### Data
`local/MODELS.md` and `local/PREFS.md` are plain Markdown and hold no secrets. Account names are labels only.

### Interfaces
- New user: "install Agent-kit from https://github.com/Eurie92/Agent-kit" or "set up Agent-kit".
- Changing the setup later: say "setup" again.
- `install.ps1` flags are unchanged.

### Edge cases
- The kit is already cloned but has no `local/`: setup runs the interview without cloning.
- The user declines all presets: setup writes a custom routing table from their answers.
- A harness is not installed: skip it (`-Harness`).
- A non-Windows user: setup says the installer is Windows-only for now, writes `local/` anyway, and gives the manual wiring steps from the README.
- An agent cannot ask questions interactively, for example a headless run: it stops and asks for the answers in a single message.

### Security
- The interview never asks for tokens, keys or passwords.
- Before writing, the installer still backs up every file it changes, as it does today.
