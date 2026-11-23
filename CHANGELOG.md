# Changelog

All notable changes to this kit. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/). Versions: [SemVer](https://semver.org/).

## [Unreleased]
### Added
- `docs/BENCHMARK.md`: A/B benchmark of the kit vs no kit (3 tasks, 12 headless runs, hidden tests, two blind judges).

## [0.5.0] - 2026-11-24
### Added
- Contributor setup: `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`, `SECURITY.md` (private vulnerability reports), a pull request template, issue forms (bug, idea, new playbook or standards sheet), `CODEOWNERS` and Dependabot for GitHub Actions.
- CI (`.github/workflows/ci.yml`) on every pull request and push to main: repo checks and ShellCheck on Linux, `install.sh` tests on Linux and macOS, PSScriptAnalyzer and `install.ps1` tests on Windows.
- `install/test-install.ps1`: tests for `install.ps1` against fake homes (31 checks).
- `tools/check.sh`: skill front matter, no tracked `local/` files, ASCII-only `.ps1`, shell syntax and relative Markdown links.
- Release workflow: pushing a `vX.Y.Z` tag publishes a GitHub release with that version's CHANGELOG section.

### Changed
- README rewritten: badges, why, install options, daily-use commands with a sample session, a diagram of how it works, and a FAQ.
- The manual-only `install-sh.yml` workflow is replaced by CI (Actions minutes are free on a public repo).

## [0.4.0] - 2026-11-24
### Added
- `install/install.sh`: installer for macOS and Linux, with the same options, behavior and output as `install.ps1`. Skills are symlinks instead of junctions; Antigravity still gets copies. It runs on bash 3.2 (the macOS default) and later, with POSIX tools only.
- `install/test-install.sh`: tests for `install.sh` against fake homes in a temp folder (missing `local/`, dry run, two runs, user text and CRLF kept, relink, prune, broken markers, foreign links, uninstall, harness list, `~` imports, a kit path with a space, the Codex size warning).
- `.github/workflows/install-sh.yml`: runs those tests on Linux (bash 5) and macOS (the system bash 3.2). Manual trigger only. The one run before release passed 56 of 56 checks on both.

### Changed
- `setup` runs `install.sh` on macOS and Linux instead of wiring files by hand.
- README: macOS/Linux requirements and quick start; the wiring table names junctions (Windows) and symlinks (macOS, Linux).
- `docs/DECISIONS.md` no longer names a local user path, private projects or account names (D26).
- The repo is public. Its history starts fresh at this release.

## [0.3.0] - 2026-11-24
### Added
- `setup` skill: reads the user's existing global rules and skills, reports clashes, interviews them one question at a time (tools, models and accounts, routing, auditor, chat style, lead effort, personal rules), writes `local/`, runs the installer and verifies.
- `INSTALL.md`: instructions for an agent asked to install the kit.
- `rules/MODELS.example.md`: model layers, lead-effort guidance and three routing presets (one vendor; one vendor plus an outside auditor; mixed vendors).
- `local/MODELS.md` and `local/PREFS.md`: each user's routing and preferences, git-ignored.

### Changed
- **Breaking:** the installer needs `local/MODELS.md` and `local/PREFS.md`. If either is missing, it stops before changing anything and points to `setup`. Run `setup` (or create both files by hand) before re-running the installer.
- Model routing moved from `rules/MODELS.md` (removed) to `local/MODELS.md`. The Claude block now imports three files; the Gemini and Codex copies contain all three.
- Chat style moved from GLOBAL §1 to `local/PREFS.md`. With no preference set, chat is plain and short.
- The `audit` skill works without an auditor: it offers a fresh-context review by the advisor model.
- References to the routing file (`handoff`, `kickoff`, `playbooks`, `audit`, the project template `AGENTS.md`, README) point to `local/MODELS.md`.

### Fixed
- Installer: `-Harness claude,gemini` failed when run with `powershell -File`, because the list arrived as one string. The installer now splits on commas, ignores case and spaces, and names an unknown value.

## [0.2.0] - 2026-11-24
### Changed
- Model routing: Claude Sonnet 5.5 for implementation and research, Claude Haiku 5.5 for bulk. Gemini 4 Neon is the outside auditor only, started async. Gemini Hydrogen and Flash are paused while Antigravity children in T3 are slow.
- Installer: Antigravity gets real copies of the skills (it does not follow junctions). Old Gemini skill junctions are replaced on the next run.
- `handoff` boot and the project template `AGENTS.md`: if the kit rules are not in the agent's context, the agent reads them from `~/Desktop/Agent-kit/rules/`. Antigravity inside T3 Code loads skills but no rule files (global or project), so in T3 it starts with `boot`.
- `kickoff` is manual: the rules and README tell the user to run `/kickoff` or say "kickoff".
- `handoff` boot no longer flags the docs-only save commit as a mismatch.

### Fixed (from the v0.1.0 outside audit)
- Installer: updates the managed block in place (no duplicates, CRLF kept), skips files with broken markers, relinks dangling junctions, prunes skills removed from the kit, backs up skill copies before replacing them, uses `@` imports only when the kit path has no spaces, and warns when `~/.codex/AGENTS.md` passes 24 KB.
- `ship`: release notes and audit fixes come before the clean-state commit and the checks; a first release scans every tracked file for secrets.
- Rules: work on a feature branch; ask before committing straight to main, force-pushing or rewriting pushed history; redact secrets in output, docs and briefs; lessons keep the user's words plus an English translation; standards scoped to non-trivial work.
- `feature` and `kickoff`: stop for Part A approval; build on a feature branch; template paths point to the kit; research briefs carry the search cap and time budget; `kickoff` adds `@AGENTS.md` to a project `CLAUDE.md`.
- `audit`: time budget and search cap in the brief; unsure high findings go to the advisor or user; one re-audit of the fix diff.
- `playbooks` and `standards`: new sheets are written in the kit repo, not an installed copy.
- `handoff` save: stages only the changed doc files, by name.
- Project template `DECISIONS.md`: uses the GLOBAL §9 kinds and adds "What would change it".
- Kit lessons: English translations of the user's quotes.
- `.gitattributes`: LF line endings, except `.ps1` files, which check out with CRLF for Windows PowerShell.

## [0.1.0] - 2026-11-24
### Added
- Global rules (`rules/GLOBAL.md`) and model routing (`rules/MODELS.md`).
- Skills: kickoff, feature, handoff, ship, audit, playbooks, standards.
- Seed playbooks: web, bot, extension, app. Standards sheet: software delivery.
- Project templates: AGENTS.md and docs (STATE, SPEC, PLAN, DECISIONS, LESSONS, RESEARCH).
- Windows installer with dry run, backups, uninstall and per-harness selection.
