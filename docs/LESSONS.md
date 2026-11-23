# Lessons (kit)

Lessons from any project that apply to every project are proposed here, then promoted into `rules/GLOBAL.md` if the user agrees.

## 2026-11-24 Slow delegated research job
User's words: "please check gemini why so slow it already 32 mins please check it ayan den yun mga gsutokong maiwasan" (English: "...please check it; those are the things I want to avoid")
What was wrong: one Gemini job got 4 playbooks with about 10 web searches. It queued 7 min, ran searches one after another (~3 min each), and 2 searches hung for 25+ min. No files were written in 35 min.
Why it got through: the brief had no search cap, no time budget, and no split into parallel jobs.
Fix (instruction): GLOBAL §4 now requires parallel jobs per topic, max 3 searches per job, and a time budget; past the budget the lead reads progress and waits, cuts scope or takes over.

## 2026-11-24 Gemini workers too slow in T3 (second time)
User's words: "hello update ko lang bakit sobrang tagal? hindi ata magandang gawin subagent si neon pang lead lang talaga siya I think kasi sobrang bagal niya talagaaa diko alam kung bakit please paki check ako bakit sobrang bagal" (English: "Just an update: why is it taking so long? Neon doesn't seem good as a subagent; I think it is really only fit to lead, because it is so slow and I don't know why. Please check for me why it is so slow.")
What was wrong: the search cap from the first lesson did not help. Every Antigravity child in T3 took 6 to 7 minutes to start (authenticate about 3 min, session about 3 min) and about 3 minutes per step, while its CPU sat idle. A 4-command boot check took 18 minutes on Gemini 4 Neon and 65 seconds on Claude. The same calls took seconds at 17:25 the day before, so the delay is in the Antigravity path (likely a network wait; IPv6 to Google timed out in a test), not the model.
Why it got through: routing put Gemini on worker layers (research, cheap implementation, bulk) without measuring start-up and per-step time in T3 first.
Fix (instruction): `rules/MODELS.md` now puts Claude on implementation, bulk and research. Gemini 4 Neon stays only as the outside auditor, started async. Gemini workers come back only when an Antigravity child starts in under 1 minute (check stated in MODELS.md).

## 2026-11-24 Too many approval questions after "finish everything"
User's words: "bakit palagi ka tanong ng tanong sinabi kona tapusin mo nga lahat eee ayoko ng ganto tanong ka ng tanong" (English: "Why do you keep asking and asking? I already told you to finish everything. I don't like this, you keep asking.")
What was wrong: the user said "finish all of it" twice, yet the agent ended the work by asking for OK to merge to main and to delete merged branches.
Why it got through: GLOBAL §8 says to ask before merging and deleting branches, and the agent did not treat "finish everything" as that approval.
Fix (instruction): `local/PREFS.md` now says "finish everything" approves every step needed (commit, push, merge, delete merged branches), and replies end with a report, not a question. Open items are listed as notes.
