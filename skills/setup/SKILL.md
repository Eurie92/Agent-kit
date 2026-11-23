---
name: setup
description: Install Agent-kit for a user, or change their setup. Interviews them one question at a time, writes local/MODELS.md and local/PREFS.md, runs the installer and verifies. Use when the user says "setup", "set up Agent-kit", "install Agent-kit", or wants to change their models, auditor or chat style.
---

# Setup

The shared rules stay as they are. Each user's choices go in `local/` in the kit, which git ignores. Kit folder: `~/Desktop/Agent-kit`.

## 1. Read first (no questions yet)
- **The kit.** Is it at `~/Desktop/Agent-kit`? If not, follow `INSTALL.md` step 1.
- **Existing setup.** If `local/MODELS.md` or `local/PREFS.md` exists, this is a change, not a first install. Show the current choices, ask what to change, and skip the rest.
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
2. **Models and accounts.** Which providers and plans do you have? Is there a second account for workers? Ask for labels only, never tokens.
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
- the routing table;
- the preferences text;
- the files you will write;
- the installer command.

## 5. Write
- **`local/MODELS.md`.** Start from the chosen preset in `rules/MODELS.example.md`. Include:
  - a table with Layer, Job, Model and Runs on;
  - a "Lead effort" section;
  - the host notes that apply, for example the T3 `delegate_task` settings per provider.

  With one account, workers share it, so leave out the Fallback row. With no auditor, write "none" in the Auditor row: `audit` then offers a fresh-context review by the advisor.
- **`local/PREFS.md`.** Use the format below.
- Create `local/` if it is missing. Never commit it.

## 6. Install
- **Harness list.** Build `<list>` from the Q1 answer: Claude Code → `claude`; Antigravity or Gemini CLI → `gemini`; Codex → `codex`. Join them with commas, for example `claude,gemini`. Leave the option out only if they use all three. Otherwise the installer writes files for tools they do not have.
- **Windows.** From the kit folder, run `powershell -ExecutionPolicy Bypass -File install\install.ps1 -DryRun -Harness <list>`.
- **macOS or Linux.** From the kit folder, run `bash install/install.sh --dry-run --harness <list>`.
- Show the output, then run it again without the dry-run option. Paste both outputs.

## 7. Verify
- Ask the user to open a new thread and say `boot`. Or start a fresh child thread, ask it for its routing and chat style, and paste the answer. If neither is possible, check that the rule files now contain the `local/` text or imports.
- Reply with:
  - what was set;
  - where it lives;
  - how to change it later (say "setup" again).

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
