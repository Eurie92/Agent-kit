---
name: kickoff
description: Full start-of-project flow from idea to approved spec and plan. Use only when the user says "kickoff" or starts a brand-new project.
disable-model-invocation: true
---

# Kickoff

Goal: from a raw idea to an approved spec, a plan, and scaffolded project docs. Run at high effort.

## Steps

1. **Recover context.** Read anything that already exists (folder, README, notes the user pasted, `docs/client/BRIEF.md` and `PROPOSAL.md` from the `client` flow). Do not ask what you can read.
2. **Brainstorm.** Ask one question at a time until you can state the intended outcome in 3 lines. Cover: who uses it, the core job, must-haves vs nice-to-haves, platforms, budget, deadline, what already exists. Offer 2-3 alternatives where the user seems unsure. Stop when the user confirms the 3-line outcome.
3. **Project type.** Use the `playbooks` skill to pick one or more playbooks. If none fits, write a new one first (that skill explains how).
4. **Fields and standards.** Name every field the project touches (not only software: e.g. payments, accessibility, game design, nutrition). Use the `standards` skill. Missing sheets get written before the spec.
5. **Stack research.** Delegate to the Researcher (see the routing file, `local/MODELS.md`): 2-3 stack options using the playbook's "Stack options to research", each with pros, cons, cost, learning curve, hosting, time to first working version. Brief per GLOBAL §4: max 3 searches per job and a time budget. Review the result; recommend one with reasons. The user picks. Save the research to `docs/RESEARCH.md`.
6. **Scope size.** Offer minimal, balanced, hardened: what each includes and rough time. Recommend one. Wait for the pick.
7. **Spec.** Write `docs/SPEC.md` from `~/Desktop/Agent-kit/templates/project/docs/SPEC.md`. Review it yourself for completeness, consistency and simplicity before showing it. For high-stakes work, have the Auditor review it. Show Part A and stop: the user approves Part A before you plan.
8. **Design (projects with a UI).** Before any feature code: design tokens (color, type, spacing, radius) and a small component set, then the 3-5 key screens with realistic content, screenshotted at 375 px and 1280 px. Follow and review them against the `standards` sheets `ui-visual-design.md` (and `web-production.md` for websites). The user approves the screens (the client too, in the `client` flow). Save screenshots under `docs/design/`.
9. **Plan.** Write `docs/PLAN.md` from the template in the same folder. Check every task against the spec; fix gaps. No user approval needed.
10. **Scaffold.** Create `AGENTS.md` and `docs/` files from `~/Desktop/Agent-kit/templates/project/` (skip any that exist). List the chosen playbooks in `AGENTS.md`. Record all decisions in `docs/DECISIONS.md`. If the project has a `CLAUDE.md`, add the line `@AGENTS.md` to it so Claude Code loads the project rules.
11. **Save.** Run the `handoff` save. Tell the user to start a new build thread (medium effort) and say "boot".

## Rules
- Do not write feature code during kickoff. Allowed: design prototypes and screens (step 8) and a throwaway spike the user asks for.
- Every open question ends as a recorded decision or an "Open" item, never a silent assumption.
