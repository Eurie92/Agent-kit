---
name: client
description: End-to-end flow for building something for a paying client, from first message to handover. Use when the user says "client", "new client", "may client", or a client asks for an app or website.
---

# Client delivery

Goal: turn a client request into a delivered, accepted and handed-over product, with written agreement at each gate. The client sees and approves four things: the brief, the proposal, the designs and the UAT result. Everything else is internal. The client never sees a build that has not passed our own QA check.

Files live in the client's project folder: client-facing documents in `docs/client/` (templates in `~/Desktop/Agent-kit/templates/client/`), and the usual `AGENTS.md` and `docs/` files from `kickoff`.

## Phases

| # | Phase | Output | Gate (who approves) |
|---|---|---|---|
| 1 | Intake | `docs/client/BRIEF.md` | Client confirms the brief |
| 2 | Proposal | `docs/client/PROPOSAL.md` | Client picks a package, signs, pays the deposit |
| 3 | Kickoff | `docs/SPEC.md`, `docs/PLAN.md` | User approves spec Part A |
| 4 | Design | design tokens + key screens | Client approves the screens |
| 5 | Build | staging link, weekly demo | User reviews each demo |
| 6 | QA check | `docs/client/QA.md` | Every row passes; user approves sending to the client |
| 7 | UAT | `docs/client/UAT.md` | Client signs off |
| 8 | Ship | live URL | User's "yes" in `ship` |
| 9 | Handover | `docs/client/HANDOVER.md` | Client receives access, guide and training |

Do not start a phase before the previous gate passes. Record each gate (date, who, what) in `docs/DECISIONS.md` as "Locked by user" or "Locked by client".

## 1. Intake
1. Read everything the client sent (chat, mockups, screenshots). Describe a mockup screen by screen before asking anything.
2. Draft questions for the user to send the client: grouped, max 10, plain language (the user may translate). Cover: who uses it (roles), the core jobs per role, must-haves vs nice-to-haves, existing data and systems, platforms (web, phone browser, app store), deadline, budget range, who approves on the client side, branding (logo, colors).
3. Fill `BRIEF.md` from the answers. Mark guesses "Assumed" and unknowns "Open". The user sends it to the client to confirm.

## 2. Proposal
1. Offer three packages (minimal, balanced, hardened) with features, timeline and price. The user sets the prices; never invent a rate. Recommend one.
2. State what is out of scope, the number of design revision rounds, the warranty period, the payment schedule (for example 50% deposit, 50% on UAT sign-off) and how change requests are priced.
3. Fill `PROPOSAL.md`. Sending it to the client is the user's action.

## 3. Kickoff
Run the `kickoff` flow with the brief and the chosen package as input; skip questions the brief already answers. Money, member data or logins make the project high-stakes: the `audit` skill reviews the spec and the release.

## 4. Design (before any feature code)
"Clean and good-looking" is decided here, not after the build.
1. Build a design system first: color, type, spacing and radius tokens from the client's logo and brand, and one component set (buttons, inputs, cards, lists, navigation). Follow the `standards` sheets `ui-visual-design.md`, `web-production.md` (websites) and `product-quality.md` (accounts, forms, payments) and the `frontend-design` skill if installed.
2. Mobile first. Make the 3-5 key screens as a clickable prototype with realistic content (real-looking names, amounts and dates in the client's language), never lorem ipsum.
3. Screenshot each screen at 375 px and 1280 px wide. Review them yourself before the user sees them: alignment, spacing rhythm, contrast, one primary action per screen, consistent use of the tokens.
4. The user shows the screens to the client. Revisions count against the rounds in the proposal.

## 5. Build
Use the `feature` flow per feature, in plan order. Deploy every merged feature to a staging URL. Each week, give the user a short demo note: what is new, the staging link, what needs client input. Client requests outside the signed scope become change requests, never silent additions.

## 6. QA check (before the client sees it)
Our overall check that the product is complete and good enough to show. Run it on staging, on the exact version the client will test.
1. Fill `docs/client/QA.md` from the template: scope (every acceptance criterion and every proposal item), automated checks, look and feel, devices and browsers, speed and SEO (websites), accessibility, forms, data and security. Each row gets proof: command output, a screenshot or a test name.
2. Delegate the long parts (full test run, Lighthouse, screenshots of every screen, link check) to Bulk. The lead reviews every result and every screenshot.
3. Money, logins or personal data: run `audit` on this release candidate now, not only at ship.
4. Fix every Fail and re-check its row. Ready for UAT means zero open Fails; anything accepted as a known limit is listed for the client.
5. Show the user the summary (pass and fail counts, known limits, staging link). Only after the user's OK do the staging link and `UAT.md` go to the client.

## 7. UAT
1. Write `UAT.md`: one row per acceptance criterion in the spec, written as steps the client can follow on staging without help.
2. The client runs it. Bugs are fixed and re-tested; new wishes are change requests.
3. Sign-off is the client's name and date on `UAT.md`. Only then go to `ship`.
4. A fix during UAT that changes more than copy re-runs the affected QA rows before the client re-tests.

## 8. Ship
Run the `ship` skill. Also confirm: domain and HTTPS work, backups run and one restore was tested, error alerts are on, the client's admin account exists.

## 9. Handover
Fill `HANDOVER.md`: live URLs, where each account is held and who owns it (never the secret itself), admin guide, training, support contact, warranty end date, maintenance options. The final invoice goes out with the handover.

## Change requests
Anything not in the signed proposal: write a one-paragraph request with its impact on time and price. The client approves it in writing before work starts. Log it in `docs/DECISIONS.md`.

## Rules
- Never promise the client anything the user did not decide. Prices, dates and scope come from the user.
- Client documents use plain language the client can read. Technical detail stays in `docs/SPEC.md`.
- Never put client credentials, payment details or member data in the repo, chats or briefs.
