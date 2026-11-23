# Plan: macOS/Linux installer and public scrub (v0.4.0)

Spec: `docs/SPEC.md`, first section (scope Balanced, picked 2026-11-24). Branch: `feat/cross-platform`.

| # | Task | Verify |
|---|---|---|
| 1 | D26 scrub: D17, D18, D21 and D29 drop the local user path, private project names and account names; LESSONS keeps the owner's words | `git grep` for the user path, project names and account label finds nothing |
| 2 | `install/install.sh`: port of `install.ps1` (flags, `local/` check, managed block with CRLF, symlinks, Gemini copies, relink, prune, backups, `~` imports, space fallback, Codex size warning) | Task 3 tests |
| 3 | `install/test-install.sh`: fake-home tests for every behavior above | All checks pass in Git Bash (`MSYS=winsymlinks:sys`) |
| 4 | `.github/workflows/install-sh.yml`: Linux (bash 5) + macOS (system bash 3.2); one run from the branch via a temporary push trigger, then manual-only | Run green on both; trigger removed in the next commit |
| 5 | README, `setup` skill §6, playbooks/standards wording, CHANGELOG 0.4.0, DECISIONS D26/D31/D32, SPEC | Read-through |
| 6 | Commit and push `feat/cross-platform`; merge waits for the user's OK | `git log`, `git status` clean |

# Plan: setup interview and shareable config (v0.3.0, done)

Spec: `docs/SPEC.md`, second section (approved 2026-11-24). Branch: `feat/setup` (merged).

| # | Task | Verify |
|---|---|---|
| 1 | Move routing to git-ignored `local/MODELS.md`; add `rules/MODELS.example.md` with presets A/B/C; add `local/PREFS.md`; ignore `local/` | `git check-ignore -v local/MODELS.md` → `.gitignore` rule (case 3) |
| 2 | Installer: read `rules/GLOBAL.md` + `local/MODELS.md` + `local/PREFS.md`; stop with exit 1 and no changes if a local file is missing (not for `-Uninstall`) | Fake-home tests: case 1 (exit 1, home untouched), case 2 (3 imports, copies hold all three, second run "Nothing to change"), case 6 (old 2-import block replaced in place, outside text and CRLF kept) |
| 3 | GLOBAL header and §1 point to `local/`; chat style moves to PREFS | Read-through; case 5 |
| 4 | Point `handoff`, `kickoff`, `playbooks`, `audit` and the project `AGENTS.md` template to `local/MODELS.md`; `audit` works with no auditor | `grep` finds no `rules/MODELS.md` outside history files |
| 5 | `skills/setup/SKILL.md` and root `INSTALL.md` | Case 4: a fresh Sonnet agent installs into a fake home with pre-filled answers |
| 6 | README, CHANGELOG 0.3.0, DECISIONS (D26 narrowed, D28–D30), SPEC status | Read-through |
| 7 | Re-run the real installer twice | Second run "Nothing to change"; live Claude block has 3 imports |
| 8 | Case 5: a fresh Claude child states its routing and chat style | Child answer matches `local/` |
| 9 | Commit and push `feat/setup`; merge waits for the user's OK | `git log`, `git status` clean |
