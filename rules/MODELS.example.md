# Model routing (example)

The `setup` skill copies one of the presets below into `local/MODELS.md` and fills in your models and accounts. `local/` is git-ignored, so your routing stays on your machine. The layers are the same for everyone; the models in them are yours to choose.

## Layers

| Layer | Job |
|---|---|
| Advisor | Second opinion on trigger cases only (GLOBAL §4). Advises; never builds. |
| Lead | Talks to the user, designs, decides, debugs, reviews every worker result, does small work itself. |
| Implementation | Code, tests and scripts for well-defined parts of a big build. |
| Bulk | Test suites, lint, mass edits, reading many files, summaries. |
| Researcher | Stack research, docs lookups, comparisons. |
| Auditor (optional) | Reviews specs, plans and diffs. Reports only, never fixes. Ideally from a different vendor than the builder; a same-vendor auditor runs in a fresh context and says it shares the builder's blind spots. |
| Fallback | Where workers run when their account is near its limit. |

## Lead effort
- xhigh (or the highest setting): kickoff, spec, plan, hard debugging, big design calls.
- medium: building from an approved plan, small tasks, questions.
- Higher effort costs more usage and time. Do not leave the lead on xhigh all day.

## Presets

### A. One vendor
Everything on one provider. Simplest and fastest; no outside review.

| Layer | Example (Claude) |
|---|---|
| Advisor | Claude Fable 5.2 |
| Lead | Claude Opus 5.5 |
| Implementation | Claude Sonnet 5.5 |
| Bulk | Claude Haiku 5.5 |
| Researcher | Claude Sonnet 5.5 |
| Auditor | none, or a strong model from the same vendor (for example Claude Fable 5.2) in a fresh context; same vendor, so shared blind spots |

### B. One vendor plus an outside auditor (recommended)
Preset A, plus an auditor from another vendor (for example Gemini 4 Neon or a GPT model through Codex). Run it async and only for high-stakes work, so a slow start never blocks you. If it hangs past its time budget (default 20 min), fall back to the advisor model and say so.

### C. Mixed vendors
Workers from several providers, picked by strength or by which account has usage left. Examples per layer:

| Layer | Claude | Gemini | OpenAI (Codex) |
|---|---|---|---|
| Advisor | Fable 5.2 | | Astra 6 / 6.2 |
| Lead | Opus 5.5 | Gemini 4 Neon | |
| Implementation | Sonnet 5.5 | Gemini 4 Hydrogen | Sol 6.1 / 6.2 |
| Bulk | Haiku 5.5 | Gemini 3.8 Flash | Luna 6 |

Before routing workers to another provider, time one child run in your host. A worker that takes minutes to start costs more than it saves.

## How workers run (by host)
- T3 Code: child threads with `delegate_task` (set the provider instance and model). Background agents use `delegate_task`, not a background native agent.
- Claude Code alone: native subagents.
- Antigravity or Codex alone: their own subagent or task feature.
- Headless CLIs (`claude -p` and the like) are for scripts and scheduled jobs. They use the same tokens as a child thread, and you cannot watch them.

## Accounts
Labels only (for example "main", "team 2"). Never put tokens, keys or passwords in this file.
