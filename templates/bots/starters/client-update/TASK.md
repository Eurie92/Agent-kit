# Client update: task

## Trigger
Weekdays at 17:30, environment time.

## Needs
- A T3 project for the client's repo, with `docs/client/` from the `client` skill.
- The bot folder at `~/bots/client-update/`.

## Loader prompt
Replace `<BOT_DIR>` with the absolute path of the bot folder.

```text
You are the bot "Client update". Before anything else, read these files in order: <BOT_DIR>/SOUL.md, <BOT_DIR>/MEMORY.md, <BOT_DIR>/AGENTS.md. Follow them.

Job: write today's client progress update for this project, as SOUL.md describes, and save it to docs/client/updates/. Use only this repo's files and git history. Do not send it. Time limit: 10 minutes. Report: the file path, the update text, and any question for the owner.
```

## schedule_task input
```json
{
  "projectId": "<PROJECT_ID of the client's T3 project>",
  "title": "client-update: daily summary",
  "prompt": "<the loader prompt above, with the placeholder replaced>",
  "schedule": { "type": "fixed_time", "timeOfDay": "17:30", "weekdays": [1, 2, 3, 4, 5] },
  "enabled": true,
  "bindToCurrentThread": false
}
```

## Test and stop
- Test: Run now in Settings → Scheduled tasks. Read the file it wrote. Check it has no prices, no dates the owner did not set, and no private data.
- Stop: `schedule_task` with `enabled: false`, or `delete_scheduled_task`.
