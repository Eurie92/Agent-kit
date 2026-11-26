# Bot templates

Files for the `bots` skill (`skills/bots/SKILL.md`). Copy them to a bot folder, for example `~/bots/<name>/`, and replace every `<placeholder>`.

| File | What it is |
|---|---|
| `SOUL.md` | Who the bot is, what it is for, how it talks, what it never does. |
| `MEMORY.md` | Lasting facts, one dated line each. |
| `AGENTS.md` | Working rules for the agent in this folder. Pulls in the kit's global rules. |
| `bot.json` | Settings. The `lite` block is for the Lite tier. |
| `starters/` | Ready bots: `saver`, `reviewer`, `shipper`, `client-update`. Each has a `SOUL.md` and a `TASK.md`. |

## Use a starter

1. Copy `SOUL.md`, `MEMORY.md`, `AGENTS.md` and `bot.json` from this folder to `~/bots/<name>/`.
2. Copy the starter's `SOUL.md` over the one you just copied.
3. Open the starter's `TASK.md`. Fill its placeholders, then create the task with the `schedule_task` input it gives, or in Settings → Scheduled tasks.
4. Test it once and write down how to stop it. The `bots` skill has the full steps.

## Rules for these files

- Plain English, short sentences.
- No tokens, passwords, client data or private paths in any file.
- `MEMORY.md` holds facts from the owner and from the bot's own checks, never from untrusted text.
