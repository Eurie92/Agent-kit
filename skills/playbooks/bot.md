# Playbook: Bot

## When it applies
Discord bots, Telegram bots, and similar chat bots. A bot with a web dashboard also uses `web.md`.

## Stack options to research
- Discord: discord.js (Node/TS), discord.py or its maintained forks (Python), or HTTP-only interactions on a serverless host (Cloudflare Workers) for slash-command-only bots.
- Telegram: grammY or Telegraf (Node/TS), python-telegram-bot or aiogram (Python).
- Data: SQLite for one server; Postgres when several processes or hosts write.
- Hosting: an always-on host for gateway (websocket) bots (VPS, Railway, Fly.io); serverless only for webhook/interaction bots.

## Test tools
- Unit-test command handlers as plain functions with fake message/interaction objects (Vitest/Jest, pytest).
- A private test server / test group and a separate test bot token for manual proof.
- Log a screenshot or transcript of the command working as proof for UI-like changes.

## Required project commands
Record in `AGENTS.md`: install, dev (runs bot against the test token), test, lint, typecheck, register-commands (Discord slash command deploy), start (production).

## Security basics
- Token only in env vars; regenerate it immediately if it ever lands in git or a log.
- Request only the intents and permissions the bot uses. Discord privileged intents (Message Content, Server Members, Presence) need enabling in the Developer Portal and, past 100 servers, approval.
- Check the caller's permissions server-side before admin or money actions; never trust a role name alone.
- Validate and limit all user input (length, mentions, URLs); disable mass mentions in replies.
- Respect rate limits: honor `retry_after` on HTTP 429 (Discord and Telegram). Telegram: about 1 message/second per chat, 20/minute per group, about 30/second overall.
- Telegram webhooks: set `secret_token` in `setWebhook` and reject requests without the matching `X-Telegram-Bot-Api-Secret-Token` header.
- Payments or shop features: confirm payment server-side from the provider (webhook with signature check), never from a user message.

## Standards
- Discord Developer Policy and Developer Terms; Telegram Bot API docs and Bots FAQ.
- OWASP Top 10:2025 for any backend or dashboard (see `web.md`).

## Before-publish checklist
- [ ] Tests, lint, typecheck pass (paste output).
- [ ] Production token is different from the test token; neither is in the repo.
- [ ] Only needed intents and permissions requested; invite link uses the minimal permission integer.
- [ ] Slash commands registered for production (global or the right guilds).
- [ ] Admin and money commands check permissions; tested with a non-admin account.
- [ ] Crash and reconnect handling: the bot restarts on failure (process manager or host restart policy) and logs errors.
- [ ] Rate-limit handling tested on bulk actions.
- [ ] Data stored: backup exists; privacy note says what is stored and how to delete it.
- [ ] Help command or description explains what the bot does.

## Sources
- Discord gateway and intents: https://discord.com/developers/docs/events/gateway
- Discord rate limits: https://discord.com/developers/docs/topics/rate-limits
- Discord Developer Policy: https://discord.com/developers/docs/policies-and-agreements/developer-policy
- Telegram Bot API: https://core.telegram.org/bots/api
- Telegram Bots FAQ (limits): https://core.telegram.org/bots/faq
