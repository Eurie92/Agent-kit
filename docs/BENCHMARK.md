# Benchmark: with Agent-kit vs without

Date: 2026-11-24 · Claude Code 2.1.329 · model Opus 5.5 (medium effort) · Windows 10, Node 24.

## Question

Does the kit make a coding agent's output better, and what does it cost in time and money?

## Method

- **Arms.** A = the user's normal setup with the kit on (rules in `~/.claude/CLAUDE.md`, kit skills). B = same machine, same model, kit off: user `CLAUDE.md` excluded with `claudeMdExcludes`, skills off with `--disable-slash-commands`. A probe run confirmed B saw no kit rules.
- **Runner.** Headless `claude -p --output-format json`, bypass permissions. Each prompt ends with "end your final message with BENCH-DONE". If the agent stopped without it, the same scripted reply was sent (approve everything, pick balanced), up to 4 times. No run needed it.
- **Tasks** (3 tasks × 2 arms × 2 reps = 12 runs, 6 at a time):
  1. **Bug fix** in `shelf`, a small Node CLI with a planted bug (unpadded dates compared as strings). The prompt mentions existing data files.
  2. **Feature**: holds (a reservation queue) in the same repo, with a stated API.
  3. **New project** from an empty folder: a `budget` CSV CLI with a stated interface.
- **Hidden tests** (outside the workspace, never shown to agents): 7, 12 and 11 tests. They cover the stated behavior plus data compatibility (old files, legacy dates), CLI exit codes and CRLF input. The untouched seed passes 1/7 and 4/12.
- **Blind judges.** Each judge saw code only (git diff vs the seed, or all files for task 3), not the agents' chat, since language and style would reveal the arm. Two rounds with swapped X/Y order to cancel position bias: Gemini 4 Neon (A shown as X), then Opus 5.5 in a fresh context on another account (B shown as X). Scores run 1–10 on correctness, tests, code quality and docs.

## Results

### Speed and cost (average of 2 runs)

| Task | Arm | Wall time | Cost | Agent turns |
|---|---|---|---|---|
| Bug fix | A (kit) | 2.1 min | $0.50 | 10 |
| Bug fix | B | 1.7 min | $0.26 | 5 |
| Feature | A (kit) | 2.3 min | $0.52 | 8 |
| Feature | B | 2.1 min | $0.37 | 7 |
| New project | A (kit) | 3.0 min | $0.70 | 15 |
| New project | B | 2.7 min | $0.55 | 14 |

A is about 10–25% slower and costs 1.3–1.9× as much. The kit's always-loaded rules are small (about 10 KB, roughly 2.5k tokens). Most of the extra cost comes from extra steps: a branch, a commit, a failing test before the fix, and proof runs.

### Hidden tests

All 12 runs passed every hidden test (7/7, 12/12, 11/11). These tasks are too easy to separate the arms on correctness alone.

### Blind judges

| Case | Judge 1 (Neon) | Judge 2 (Opus) |
|---|---|---|
| Bug fix, rep 1 | tie | A |
| Bug fix, rep 2 | A | A |
| Feature, rep 1 | A | A |
| Feature, rep 2 | B | B |
| New project, rep 1 | B | B |
| New project, rep 2 | A | A |

The judges agree on 5 of 6 cases. Overall, A wins 4 cases (3.5 by judge 1) and B wins 2.

Average scores over both judges:

| Arm | Correctness | Tests | Quality | Docs | Overall |
|---|---|---|---|---|---|
| A (kit) | 8.3 | 8.3 | 8.1 | **6.0** | 7.67 |
| B | 7.8 | 7.7 | 7.7 | **7.3** | 7.58 |

### Process

| Signal | A (kit) | B |
|---|---|---|
| Work on a feature branch | 4/4 repo tasks | 0/4 |
| Committed | 4/4 | 0/4 (changes left uncommitted) |
| Failing test shown before the bug fix | 2/2 | 0/2 |
| Asked minimal/balanced/hardened | 0 (correct: all tasks sized small) | n/a |
| Merged to main without asking | 0 | n/a |

## Findings

1. **Correctness and tests are slightly better with the kit**, mostly on data compatibility. For example, A repaired legacy dates when loading files and accepted unpadded input. The gap is small.
2. **Docs are worse with the kit.** Both of B's wins came from A missing docs: one A run left the new API out of the README's "Public API" section, and one shipped a new project with no README. The kit's "proof before done" pushes test output but says nothing about docs.
3. **The kit costs about 1.5× the money and is about 15% slower on small tasks.** The extra goes into git hygiene and proof, not reading rules.
4. **Not tested:** large multi-file features (spec with Given/When/Then, `feature` skill), multi-session handoff, delegation to worker models, and the auditor. That is where the kit should matter most, and this benchmark says nothing about it.

## Limits

- 2 reps per cell is a small sample. Treat these numbers as signals, not proof.
- The tasks are small and well specified. Hidden tests hit the ceiling.
- Arm B also lost the user's non-kit instructions (caveman style, RTK note) and all skills, not just the kit's. Arm A's chat replies were in Taglish caveman style. The judges never saw the chat.
- Two different judges, one per order, so model differences and position bias are mixed together. They agreed on 5 of 6 cases anyway.

## Suggested follow-ups

- Add docs to "proof before done": when a change adds or changes public behavior, update the README or API docs, or say why not.
- A harder round: one multi-file feature and one two-session handoff task, where specs and state files should pay off.
