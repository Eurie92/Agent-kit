# Bot templates

Files for the `bots` skill (`skills/bots/SKILL.md`). Copy them to a bot folder, for example `~/bots/<name>/`, and replace every `<placeholder>`.

| File | What it is |
|---|---|
| `SOUL.md` | Who the bot is, what it is for, how it talks, what it never does. |
| `MEMORY.md` | Lasting facts, one dated line each. |
| `AGENTS.md` | Working rules for the agent in this folder. Pulls in the kit's global rules. |
| `bot.json` | Settings. The `lite` block is for the Lite tier. |
| `template.json` | Gallery template in each starter folder (`starters/<name>/template.json`) for the Full tier. |
| `starters/` | Ready bots: `saver`, `reviewer`, `shipper`, `client-update`. Each has a `SOUL.md`, `TASK.md` and `template.json`. |

## Use a starter

1. Copy `SOUL.md`, `MEMORY.md`, `AGENTS.md` and `bot.json` from this folder to `~/bots/<name>/`.
2. Copy the starter's `SOUL.md` over the one you just copied.
3. Open the starter's `TASK.md`. Fill its placeholders, then create the task with the `schedule_task` input it gives, or in Settings → Scheduled tasks.
4. Test it once and write down how to stop it. The `bots` skill has the full steps.

## Full tier (T3 Code fork with Bots)

When you run `install/install.sh` or `install/install.ps1`, the installer copies each starter's `template.json` to `<T3 home>/bots/templates/kit-<name>/template.json` (regardless of `--harness` / `-Harness`), so they appear in the T3 Code bot gallery under the **Agent-kit** category.

- `<T3 home>` is `T3CODE_HOME` if set and non-empty, otherwise `~/.t3`.
- If that folder does not exist, the installer prints one line and skips this step without error.

## Rules for these files

- Plain English, short sentences.
- No tokens, passwords, client data or private paths in any file.
- `MEMORY.md` holds facts from the owner and from the bot's own checks, never from untrusted text.
