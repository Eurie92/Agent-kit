---
name: feature
description: Flow for a non-trivial feature in an existing project (more than a few files, new behavior, or unclear scope). Not for bugs or small changes; do those directly.
---

# Feature

1. **Understand.** Read `AGENTS.md`, `docs/STATE.md`, and the code the feature touches. Ask only what you cannot read. Restate the outcome in 2-3 lines.
2. **Scope size.** Offer minimal, balanced, hardened with scope and rough time. Recommend one. Wait for the pick.
3. **Standards.** Name the fields the feature touches; check the `standards` skill. Add a short "Standards applied" list.
4. **Spec section.** Append a section to `docs/SPEC.md` (or create it): Part A plain-language (what changes for the user, scope, risks, how "done" is judged) and acceptance criteria as Given/When/Then; Part B technical notes. Show Part A and stop: build nothing until the user approves it.
5. **Plan.** Add tasks to `docs/PLAN.md`, each with its verify step. Check them against the spec. Delegate parallel parts per GLOBAL §4.
6. **Build.** On a feature branch: if you are on main/master, create `feat/<short-name>` first (unless `AGENTS.md` says otherwise). Implement within the approved scope. Tests for each Given/When/Then.
7. **Verify.** Run tests, lint, build. Paste the output. For UI, include a screenshot.
8. **Wrap.** Commit and push to the feature branch. Update `docs/STATE.md` (`handoff` save). Report outcome and remaining limits.

A material change to the approved scope returns to the user as a specific revision before you build it.
