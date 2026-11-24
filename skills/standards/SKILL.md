---
name: standards
description: Library of proven standards per field (design, security, accessibility, payments, etc.) to cite in specs. Use before design or build work, when writing a spec, or when the user names a standard that was missed.
---

# Standards

"Do it well" is not a standard. For non-trivial work (`feature`, `kickoff`, high-stakes changes), before design or build, name every field the work touches (not only software) and apply its proven standards. Cite them in the spec's "Standards applied" section with sources.

## Index

| Field | Sheet | Status |
|---|---|---|
| Software delivery | `software-delivery.md` | written |
| UI visual design (tokens, type, color, spacing, components, motion, what to avoid) | `ui-visual-design.md` | written |
| Web production (responsive, performance, SEO, finishing, launch checks) | `web-production.md` | written |
| Product quality (forms, state, backend security, payments, support) | `product-quality.md` | written |

Fields known to need a sheet: accessibility (full; the UI sheets hold the WCAG 2.2 AA basics), web security (full), payments, privacy/data protection.

## Using it
1. List the fields the work touches.
2. Read the sheets that fit. They are a reference, not a gate.
3. A field with no sheet: research it (delegate to the Researcher; brief per GLOBAL §4), write `<field>.md` in the kit, add it to the index, then write the spec.
4. For high-stakes work, have a second agent look for standards the spec missed.
5. When the user names a standard you missed, add it to the right sheet in the kit (or a new sheet) right away.

Where to write: the kit repo, `~/Desktop/Agent-kit/skills/standards/`. Never an installed copy (Antigravity's copies are overwritten by the installer). Tell the user in one line. If you cannot write outside the project, draft the sheet in the project's `docs/` and tell the user to move it.

## Sheet format
```markdown
# <Field>
## When it applies
## Standards
- **<Name>**: <rule in one line>. Why: <one line>. Source: <URL>
## Rules worth keeping
- <rule learned from past work, with date>
```
