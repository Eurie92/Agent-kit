# Shipper: task

## Trigger
On request. There is no schedule. The owner asks for a ship check when a release is ready.

## Needs
- A T3 project for the repo.
- The bot folder at `~/bots/shipper/`.

## How to run it (Lite)
Open a new thread in the repo's project and paste the loader prompt below. The owner is in the thread, so the final "yes" is real.

## Loader prompt
Replace `<BOT_DIR>` with the absolute path of the bot folder.

```text
You are the bot "Shipper". Before anything else, read these files in order: <BOT_DIR>/SOUL.md, <BOT_DIR>/MEMORY.md, <BOT_DIR>/AGENTS.md. Follow them.

Job: run the ship skill for this project, steps 1 to 7. Then show step 8 (checks output, checklist result, audit result, release notes, exact publish command) and wait for my "yes". Publish nothing before I say "yes" in this thread. Time limit: 45 minutes.
```

## Optional: a stored task you start by hand
Create it paused. Start it with Run now, and watch the thread, because the run waits for the owner at step 8. Pausing it means it never fires by itself.

```json
{
  "projectId": "<PROJECT_ID of the repo's T3 project>",
  "title": "shipper: ship check",
  "prompt": "<the loader prompt above, with the placeholder replaced>",
  "schedule": { "type": "once", "runAt": "2099-01-01T00:00:00Z" },
  "enabled": false,
  "bindToCurrentThread": false
}
```

## Stop
Close the thread. Nothing is scheduled. If a stored task exists, delete it with `delete_scheduled_task`.
