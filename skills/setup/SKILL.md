---
name: setup
description: Install Agent-kit for a user, or change their setup. Interviews them one question at a time, writes local/MODELS.md, local/routing.json and local/PREFS.md, runs the installer and verifies. Use when the user says "setup", "set up Agent-kit", "install Agent-kit", or wants to change their models, auditor or chat style.
---

# Setup

The shared rules stay as they are. Each user's choices go in `local/` in the kit, which git ignores. Kit folder: `~/Desktop/Agent-kit`.

## 1. Read first (no questions yet)
- **The kit.** Is it at `~/Desktop/Agent-kit`? If not, follow `INSTALL.md` step 1.
- **Existing setup.** If `local/MODELS.md`, `local/routing.json` or `local/PREFS.md` exists, this is a change, not a first install. Show the current choices, ask what to change, and skip the rest. If `local/MODELS.md` exists but `local/routing.json` does not (a setup from before the JSON file), build the JSON from the table and ask only about what the table does not say.
- **Global rule files.** Read `~/.claude/CLAUDE.md`, `~/.gemini/GEMINI.md` and `~/.codex/AGENTS.md`. Text outside the `agent-kit:start` / `agent-kit:end` markers belongs to the user.
- **Skill folders.** List `~/.claude/skills/`, `~/.gemini/config/skills/` and `~/.agents/skills/`. Note any folder with the same name as a kit skill.
- **Tools.** Note which tools are present (those folders, or the CLIs on PATH).
- **Secrets.** Never open `.env` files, credential files or tokens.

## 2. Report clashes
Show one short list, or say "no clashes" in one line.
- **A user rule that contradicts the kit.** A rule clashes if following it would break a GLOBAL rule or a kit default, including chat style and language. For example "always commit to main" or "reply in formal English". Ask the user to choose:
  - keep it: add it to `local/PREFS.md`, where it wins over the kit rules;
  - drop it: suggest the edit to their file, and let them make it.
- **A skill folder with a kit skill's name.** The installer skips it. Ask the user to choose: rename theirs, or go without the kit skill.

## 3. Interview
- Ask one question per message.
- Offer multiple choice when you can. Put the recommended option first, mark it "(recommended)" and give one line on why.
- Use the harness's question tool if it has one.
- Skip a question that step 1 already answered, and say what you found.

1. **Tools.** Which do you use: Claude Code, Antigravity, Codex, Gemini CLI? Inside T3 Code or on their own? This sets the installer's harness list.
2. **Models and accounts.** Which providers and plans do you have? Is there a second account for workers? Several accounts on one provider (for example five Antigravity accounts in T3 Code)? Then offer an account pool: workers use them in turn and move on when one hits its limit. In T3 Code, read the account ids from `orchestrator_capabilities` instead of asking. Ask for labels only, never tokens.
3. **Routing.** Pick a preset from `rules/MODELS.example.md`:
   - A: one vendor (pick this when the user wants one vendor only; the auditor, if any, is a same-vendor model in a fresh context);
   - B: one vendor plus an outside auditor (recommended when they can run a model from a second vendor, for example Gemini through Antigravity or GPT through Codex; a second account with the same vendor does not count);
   - C: mixed vendors.

   Then confirm the model for each layer.
4. **Auditor.** Which model, and when?
   - high-stakes work only, run async (recommended);
   - every feature;
   - never.
5. **Chat.** Which style: plain and short (default), caveman, or detailed? Which language or languages?
6. **Lead effort.**
   - xhigh for planning and hard bugs, medium for the rest (recommended);
   - always high.
7. **Personal rules (optional).** Anything to always or never do? For example "never use X for UI" or "always ask before adding a package".

If you cannot ask interactively (for example, a headless run), stop and ask for all the answers in one message.

## 4. Confirm
Show, then wait for "yes":
- the answers;
- the routing table (the JSON file is built from it, so it needs no separate confirmation);
- the preferences text;
- the files you will write;
- the installer command.

## 5. Write
- **`local/MODELS.md`.** Start from the chosen preset in `rules/MODELS.example.md`. Include:
  - a table with Layer, Job, Model and Runs on;
  - a "Lead effort" section;
  - the host notes that apply, for example the T3 `delegate_task` settings per provider;
  - with an account pool, an "Account pool" section: the account order, what comes after the pool, and the lead's steps (`next-account.mjs` before each delegation, `--spent` on a limit error). Copy the steps from `rules/MODELS.example.md`.

  With one account, workers share it, so leave out the Fallback row. With no auditor, write "none" in the Auditor row: `audit` then offers a fresh-context review by the advisor.
- **`local/routing.json`.** The same routing, machine-readable, so hosts such as T3 Code do not parse the Markdown table. Build it from the same answers and write it in the same step as `MODELS.md`. Format below.
- **Keep the two in sync.** Every later setup change rewrites both files from the new answers. If you edit one by hand for any reason, update the other in the same change. Never leave them different.
- **`local/PREFS.md`.** Use the format below.
- Create `local/` if it is missing. Never commit it.

## 6. Install
- **Harness list.** Build `<list>` from the Q1 answer: Claude Code → `claude`; Antigravity or Gemini CLI → `gemini`; Codex → `codex`. Join them with commas, for example `claude,gemini`. Leave the option out only if they use all three. Otherwise the installer writes files for tools they do not have.
- **Windows.** From the kit folder, run `powershell -ExecutionPolicy Bypass -File install\install.ps1 -DryRun -Harness <list>`.
- **macOS or Linux.** From the kit folder, run `bash install/install.sh --dry-run --harness <list>`.
- Show the output, then run it again without the dry-run option. Paste both outputs.

## 7. Verify
- From the kit folder, run `node tools/validate-routing.mjs` and paste the output. It must say `ok` for `local/routing.json`. With pools, also run `node tools/next-account.mjs --status` and paste it. If `node` is not installed, say so and skip this check.
- Ask the user to open a new thread and say `boot`. Or start a fresh child thread, ask it for its routing and chat style, and paste the answer. If neither is possible, check that the rule files now contain the `local/` text or imports.
- Reply with:
  - what was set;
  - where it lives;
  - how to change it later (say "setup" again).

## `local/routing.json` format
Schema: `schemas/routing.schema.json` (strict: unknown fields are errors). Example: `rules/routing.example.json`. Labels only, never tokens or keys.

```json
{
  "$schema": "../schemas/routing.schema.json",
  "version": 1,
  "updatedAt": "2026-11-27T08:00:00Z",
  "roles": {
    "advisor": { "provider": "claude", "model": "claude-fable-5-2", "effort": "medium", "runsOn": "Child thread, second account", "providerInstanceId": "claudeTeam2" },
    "lead": { "provider": "claude", "model": "claude-opus-5-5", "runsOn": "User's thread, main account" },
    "implementation": { "provider": "claude", "model": "claude-sonnet-5-5" },
    "bulk": { "provider": "claude", "model": "claude-haiku-5-5" },
    "researcher": { "provider": "claude", "model": "claude-sonnet-5-5" },
    "auditor": { "provider": "claude", "model": "claude-fable-5-2", "effort": "high" }
  },
  "leadEffort": { "planning": "xhigh", "default": "medium" },
  "excludedModels": [],
  "excludedProviders": ["gemini"],
  "fallback": { "provider": "claude", "runsOn": "Main account, native subagent", "modelOverrides": { "advisor": "claude-opus-5-5" } }
}
```

How to fill it from the answers:
- **`roles`.** One entry per row of the `MODELS.md` table. `advisor`, `lead`, `implementation`, `bulk` and `researcher` are required. Leave out `auditor` when the Auditor row says "none". `provider` is a lowercase vendor family (`claude`, `codex`, `gemini`). `model` is the model id the host sends (for example `claude-opus-5-5`), not the display name.
- **`effort`.** `low`, `medium`, `high`, `xhigh` or `max`. Write it only when the table gives one for that role.
- **`runsOn`.** Short label from the "Runs on" column. **`providerInstanceId`.** The account label the host uses, only when the host notes in `MODELS.md` give one (T3 Code: the `delegate_task` `providerInstanceId`, for example `claudeTeam2`). Leave it out when the role runs in the user's own thread.
- **`verifier`.** Leave it out. Hosts use `verifier`, then `auditor`, then `advisor`, in that order. Write it only when the user wants a verifier that differs from the auditor.
- **`leadEffort`.** From the Lead effort answer: `planning` is the high setting, `default` the other. "Always high" gives the same value in both.
- **`excludedProviders` and `excludedModels`.** From every "no X" rule (for example "No Gemini" gives `["gemini"]`). Always write both arrays, empty when there is nothing. No role or fallback may use an excluded provider or model; the validator checks this.
- **`fallback`.** From the Fallback row. Leave it out when there is one account. `modelOverrides` lists roles that use a different model there (for example Fable needs credits on the main account, so `advisor` is Opus).
- **`pools`** (optional). Only when a provider has several accounts the user wants used in turn. One entry per pool:
  - `driverKind`: the host driver (T3 Code: `driverKind` in `orchestrator_capabilities`, for example `antigravity`);
  - `accounts`: the account ids in the order to try them;
  - `addNew`: `true` so accounts added later join the end on their own;
  - `cooldownHours`: how long a spent account is skipped when the error gives no reset time (default 5);
  - `whenEmpty`: where the pool's roles go when every account is spent, with a model per pooled role.

  Each worker role on the pool gets `"pool": "<name>"` and keeps `providerInstanceId` set to the first account, for tools that do not read pools. The validator checks that the pool exists, that `whenEmpty` has a model for every pooled role, and that `fallback` has a model it can run for every worker role (add `fallback.modelOverrides` when the pool's provider differs from the fallback's).

  ```json
  "pools": {
    "antigravity": {
      "driverKind": "antigravity",
      "accounts": ["antigravity", "antigravity_2", "antigravity_antigravity_3"],
      "addNew": true,
      "cooldownHours": 5,
      "whenEmpty": { "provider": "claude", "providerInstanceId": "claudeTeam2", "models": { "implementation": "claude-sonnet-5-5", "bulk": "claude-haiku-5-5", "researcher": "claude-sonnet-5-5" } }
    }
  }
  ```
- **`updatedAt`.** The current UTC time, `YYYY-MM-DDTHH:MM:SSZ`.

**How T3 Code finds the file.** It reads `local/routing.json` in the kit folder: `$AGENT_KIT_HOME` if that environment variable is set, otherwise `~/Desktop/Agent-kit`. With no file, T3 uses its own defaults.

## `local/PREFS.md` format
```markdown
# Personal preferences

Written by the `setup` skill; git-ignored. Change it by saying "setup". These add to the global rules; where they conflict, these win (project `AGENTS.md` still wins over both).

## Chat style
- <style>. <language>.
- Files stay in normal English (GLOBAL §1).

## Always
- <rule, or "(none yet)">

## Never
- <rule, or "(none yet)">
```
