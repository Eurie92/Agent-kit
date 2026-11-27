# Contributing to Agent-kit

Thanks for helping. Agent-kit is a small set of rules, skills and installers, so most contributions are a few lines of Markdown. This page tells you what fits, how to test, and how a pull request gets merged.

## What we are looking for

| Kind | Where | Good example |
|---|---|---|
| A new playbook (project type) | `skills/playbooks/<type>.md` | CLI tools, games, data pipelines, desktop apps |
| A new standards sheet (field) | `skills/standards/<field>.md` | Accessibility, payments, privacy |
| A fix to a rule or skill | `rules/GLOBAL.md`, `skills/*/SKILL.md` | A step agents keep skipping, a rule that contradicts another |
| Installer fixes | `install/` | A harness path that changed, a shell that fails |
| Support for another harness | `install/` + README | A new agent tool with a global rules file and a skills folder |
| Docs | `README.md`, `INSTALL.md` | Clearer steps, a missing how-to |

Open an issue first for anything big (a new skill, a rule change that affects every project, a new harness). Small fixes can go straight to a pull request.

## Ground rules for rule and skill text

The rules are loaded into every agent prompt, so every line costs tokens for every user.

- **Short and plain.** Plain English, short sentences, one idea per bullet. No marketing words.
- **Rules stay small.** `rules/GLOBAL.md` is always loaded; add to it only when a rule applies to every project. Anything task-specific belongs in a skill.
- **Vendor-neutral shared files.** Model names, accounts and personal style go in `local/` (git-ignored), never in `rules/` or `skills/`. Presets in `rules/MODELS.example.md` are the exception.
- **No private data.** No real names, emails, local paths, tokens or private project names.
- **Cite sources.** Playbooks and standards link to the official docs or standard they rely on.
- **Skills need front matter.** Each `skills/<name>/SKILL.md` starts with `name: <name>` and a `description:` that says when to use it. `tools/check.sh` enforces this.

## Set up

```bash
git clone https://github.com/<you>/Agent-kit
cd Agent-kit
git checkout -b feat/my-change
```

You do not need to install the kit into your own home to work on it. The tests use fake homes in a temp folder.

## Test

Run what matches your change. CI runs all of it on every pull request (Linux, macOS and Windows).

| Changed | Run |
|---|---|
| Anything | `bash tools/check.sh` (skill front matter, no `local/` files, ASCII `.ps1`, shell syntax, Markdown links, routing JSON) |
| `schemas/routing.schema.json`, `rules/routing.example.json` or `tools/validate-routing.mjs` | `node tools/validate-routing.mjs && node tools/test-validate-routing.mjs` (Node 18+, no packages) |
| `install/install.sh` | `bash install/test-install.sh` |
| `install/install.ps1` | `powershell -ExecutionPolicy Bypass -File install\test-install.ps1` |
| A rule or skill | Install your branch (`--dry-run` first), open a fresh agent thread and try the flow you changed. Paste what happened in the pull request. |

The two installers must keep the same options, behavior and messages. If you change one, change the other and add a test to both test scripts.

On Windows, `install/test-install.sh` runs in Git Bash; it turns on emulated symlinks for you.

## Pull requests

1. One topic per pull request.
2. Commit messages use [Conventional Commits](https://www.conventionalcommits.org/): `feat:`, `fix:`, `docs:`, `ci:`, `refactor:`, `test:`, `chore:`.
3. Add a line under `## [Unreleased]` in `CHANGELOG.md` for anything a user would notice.
4. Fill in the pull request template, including the test output.
5. CI must be green. A maintainer reviews, then squash-merges.

## Releases (maintainers)

1. Move the `[Unreleased]` notes in `CHANGELOG.md` to a new `## [x.y.z] - YYYY-MM-DD` section, following [SemVer](https://semver.org/) (0.x: minor for breaking changes or features, patch for fixes).
2. Merge that change to `main`.
3. Tag and push: `git tag vx.y.z && git push origin vx.y.z`. The Release workflow publishes a GitHub release with that CHANGELOG section as its notes.

## Conduct and security

- Be kind and specific. See [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md).
- Report security problems privately, as described in [SECURITY.md](SECURITY.md), not in a public issue.

By contributing, you agree that your work is released under the [MIT License](LICENSE).
