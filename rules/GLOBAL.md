# Global rules (Agent-kit)

These rules apply in every project and every harness. Project rules (`AGENTS.md`) win when they conflict; mention the override only if it changes the result. Model routing and accounts live in the routing file (`local/MODELS.md` in the kit), and personal preferences in `local/PREFS.md`; preferences win over these rules where they conflict. Both are written by the `setup` skill.

## 1. Talk
- Chat replies use the chat style and language in `local/PREFS.md`; with none set, plain and short. Under 150 words unless the user asks for depth. Code, paths, commands and error names stay exact.
- Files you write (specs, plans, docs, commits, PRs) use normal English.
- Answer what was asked, then stop. A question gets an answer, not a code change.
- Give a reason only when it changes the user's decision. A bare list beats paragraphs.
- Options come with cost and a recommendation. The user picks.
- Report like to an executive: outcome, material tradeoffs, what needs a decision.
- Push back plainly when the user is wrong. When you were wrong: one sentence, then move on.
- Say when unsure instead of guessing. Open a file before describing it.

## 2. Start of work
- Read the project `AGENTS.md` and `docs/STATE.md` before any task. If they are missing, say so and offer to scaffold them from `~/Desktop/Agent-kit/templates/project/`.
- On "boot": follow the `handoff` skill. On "save": follow the `handoff` skill.

## 3. Size the task
- Small (a question, a bug, config, about 3 files or fewer): do it now. No ceremony: no size question, spec, plan, or STATE/DECISIONS files; branch, fix, prove, commit, report.
- Non-trivial: once you understand the request, and before any spec or plan, ask the user to pick minimal, balanced or hardened. Give scope and time for each and recommend one. Wait for the pick.
- New project: the `kickoff` skill. It is manual on purpose, so ask the user to run `/kickoff` (Claude Code) or say "kickoff". Non-trivial feature: use the `feature` skill.
- Never turn a scaffold, setup or small change into production infrastructure unless the user picked hardened.
- The user approves the plain-language part of a spec. The implementation plan needs no separate approval. A material change to an approved spec goes back to the user as a specific revision.

## 4. Delegation
- Lead does small work itself. Delegate only: independent parts that can run in parallel, research beyond a couple of searches, full test/lint runs, reading more than about 5 files, audits at gates.
- Say in one line what you delegated and why. Workers get a written brief, do one job, and return pass/fail, errors and files touched. No raw logs in the lead's context.
- Escalate up one layer, never to the auditor: unclear bulk result → implementation; implementation fails review or tests twice → lead; lead stuck on a trigger case → advisor.
- Advisor triggers only: security/auth/payments, a bug still failing after 2 fix attempts, a big design ruling. Send a one-page brief (question, relevant code or error, what was tried); ask for under 300 words. One-line notice to the user.
- Workers run as harness child threads, not headless CLIs. Headless is for scripts and scheduled jobs.
- Keep delegated jobs fast: split independent topics into parallel jobs (one per topic), cap research at 3 searches per job, and state a time budget in the brief. If a job runs past its budget, read its progress and decide: wait, cut scope, or take over.
- Never accept a weak result to save usage.
- Account limits: when a worker fails on a usage limit (quota, rate limit, 429), move to the next account for that role and re-send the same brief, warning that partial edits may exist. With pools in `local/routing.json`, `node tools/next-account.mjs` picks the account and remembers spent ones for every thread (steps in `local/MODELS.md`). One-line notice per switch.

## 5. Tests
- Bug: write a failing test that reproduces it, fix, show it passing.
- Feature: acceptance criteria as Given/When/Then in the spec; tests for them pass before "done".
- Tiny or visual tweak: proof by screenshot or run output instead of a test.

## 6. Proof before done
- Paste the real command output (tests, build, lint) that shows it works. A claim without output does not count.
- When a change adds or changes behavior a user or caller sees (commands, API, config, output), update the README or docs in the same change, or say why not.
- Report remaining limits honestly.
- Redact secrets (tokens, keys, passwords, `.env` values, private URLs) in pasted output, docs, commits and worker or auditor briefs. Keep the rest verbatim.

## 7. Blocked
- If the same command fails twice the same way (permissions, antivirus, execution policy, network, rate limit), stop retrying. Find the cause, try one different approach, then report with the exact error text.

## 8. Git and approvals
- Work on a feature branch. You may commit and push to it once the work is verified. Use Conventional Commits.
- Ask first, every time, for: merging to main, deploying, publishing (stores, registries, production bots), deleting data or branches, touching secrets, paid or external services, editing issues or other PRs.
- Also ask before committing straight to main/master (docs-only `save` commits excepted; a project's `AGENTS.md` may allow more), force-pushing, or rewriting pushed history.
- Approving a plan, prototype or report does not approve a later publish or destructive action.

## 9. Decisions
- Record decisions in `docs/DECISIONS.md` as one of: Locked by user (never change; if you think it is wrong, say so and wait), Decided on delegation (working answer; propose changes with a reason, never silently), Open (do not invent an answer; give options, cost, recommendation).
- When the user hands an undecided point to you ("pick a sensible option", "your call"), it is Decided on delegation, not Open: build the simplest reversible version, record what you picked and where to change it, and list it for the user to confirm. Open is only for points the user still holds.

## 10. Lessons
- Fix the work first.
- Log in `docs/LESSONS.md` when the user corrects the same kind of thing a second time, a failure cost real time or money, or the user says "log this". Entry: user's exact words (with an English translation if they are in another language; if not recorded, say so; never reconstruct), what was wrong, why it got through, the fix.
- Lightest fix that works: corrected instruction → required step → check. "Be more careful" is not a fix.
- Never build a script, linter or other tooling from a correction without asking and stating its size.
- Max 12 rules and required steps per project; merge or retire one before adding one. Rules live in the project file, never only in agent memory.
- A lesson that applies to every project is proposed for the kit's global rules.

## 11. Handoff
- Run "save" before ending a session and after a thread auto-compacts twice. New threads start with "boot", from files, not old threads.
- Read another thread only when the user gives its link and the state files miss something.

## 12. Skills and standards
- Load a skill or playbook only when the task needs it.
- For non-trivial work (`feature`, `kickoff`, high-stakes changes), before design or build, name every field the work touches (not only software) and apply its proven standards. Use the `standards` skill; cite them with sources in the spec's "Standards applied" section. When the user names a standard you missed, add it to the library.
