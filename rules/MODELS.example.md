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

### Account pools (several accounts for one provider)
When you have several accounts on the same host driver (for example five Antigravity accounts in T3 Code), workers can use them in turn: when one hits its usage limit, the next takes over, then a `whenEmpty` account, then the fallback.

- `local/routing.json` lists them under `pools` (order, `addNew`, `cooldownHours`, `whenEmpty`), and each worker role names its pool.
- With `addNew: true`, an account added in the host later joins the end of the pool on its own.
- The lead runs `node tools/next-account.mjs <role> --available <driverKind:id,...>` before each delegation, and `--spent <id> <role>` when a worker fails on a limit. Spent accounts are kept in `local/account-state.json` until they reset (`cooldownHours`, default 5, or the reset time from the error), so every thread skips them.
- `local/MODELS.md` gets an "Account pool" section with the order and these steps.

Example (T3 Code, Gemini 4 Hydrogen workers on Antigravity accounts, then a second Claude account):

| Order | Account | Model |
|---|---|---|
| 1–5 | Antigravity 1 to 5, then any new Antigravity account | Gemini 4 Hydrogen |
| 6 | Claude Team 2 (`whenEmpty`) | Sonnet 5.5 (implementation, research), Haiku 5.5 (bulk) |
| 7 | Main account, native subagent (`fallback`) | same Claude models |

## Machine-readable copy
`setup` also writes `local/routing.json` from the same answers, for tools that must not parse this table (T3 Code reads it to fill roles and to honor exclusions such as "no Gemini"). The two files are kept in sync: every setup change rewrites both. A starting point is `rules/routing.example.json`; the format is `schemas/routing.schema.json`, and `node tools/validate-routing.mjs` checks it.

Tools find it at `$AGENT_KIT_HOME/local/routing.json`, or `~/Desktop/Agent-kit/local/routing.json` when `AGENT_KIT_HOME` is not set.
