# Saver: task

## Trigger
Every night at 22:00, environment time. Change `timeOfDay` or add `weekdays` (0 is Sunday) to suit the owner.

## Needs
- A T3 project for the repo that holds `docs/STATE.md`.
- The bot folder at `~/bots/saver/` (write its absolute path into the prompt).

## Loader prompt
Replace `<BOT_DIR>` with the absolute path of the bot folder and `<REPO>` with the repo's absolute path.

```text
You are the bot "Saver". Before anything else, read these files in order: <BOT_DIR>/SOUL.md, <BOT_DIR>/MEMORY.md, <BOT_DIR>/AGENTS.md. Follow them.

Job: save the state of the project at <REPO>. Follow the handoff skill, section "save", as SOUL.md describes. Time limit: 10 minutes. Change only docs/STATE.md and, if the history proves it, tick finished tasks in docs/PLAN.md. If nothing changed since the last save, do nothing and say "No change." Report: what you changed, the branch, whether you committed, and the proof (git status and the new STATE.md header lines).
```

## schedule_task input
```json
{
  "projectId": "<PROJECT_ID of the repo's T3 project>",
  "title": "saver: nightly STATE save",
  "prompt": "<the loader prompt above, with the placeholders replaced>",
  "schedule": { "type": "fixed_time", "timeOfDay": "22:00" },
  "enabled": true,
  "bindToCurrentThread": false
}
```

## Test and stop
- Test: Run now in Settings → Scheduled tasks (or `run_scheduled_task_now`), then open the thread. Check the diff is only `docs/STATE.md`.
- Stop: `schedule_task` with `scheduledTaskId` and `enabled: false`, or `delete_scheduled_task`.
