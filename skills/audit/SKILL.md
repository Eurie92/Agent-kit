---
name: audit
description: Outside adversarial review of a spec, plan or diff by a model from a different vendor than the builder. Use for high-stakes work (security, auth, payments, user data), before a ship gate, or when the user says "audit".
---

# Audit

The auditor finds problems. It never fixes or implements. The builder never grades its own work.

## Pick the auditor
From the routing file (`local/MODELS.md`): the Auditor layer, from a different vendor than whoever built the work. Start it async and keep working. If no auditor is set, tell the user and offer a fresh-context review by the advisor model (same vendor, so weaker).

## Brief (send exactly this shape)

```
You are an outside auditor. Read-only: do not edit any file.
Target: <spec | plan | diff> at <paths or commit range>
What it should do: <2-5 lines from the spec, incl. acceptance criteria>
High-stakes areas: <auth, payments, data, ...>
Budget: <time, e.g. 20 min>. Max 3 web searches.
Attack it: find bugs, security holes, missing edge cases, spec gaps, standards missed,
and anything that contradicts the spec.
Return: findings ranked high / medium / low. Each: file:line (or section), what is wrong,
a concrete failing scenario, suggested direction (not code). Max 15 findings.
Say "no findings" only if you checked every high-stakes area; list what you checked.
```

## After
1. The lead verifies each finding against the code. Mark each: confirmed, rejected (with reason), unsure. An unsure high finding goes to the advisor or the user before `ship`.
2. Fix confirmed findings (or delegate). High findings block `ship` until fixed or the user accepts the risk. After fixing high findings, run one re-audit on the fix diff only.
3. Report to the user: counts by severity, what was fixed, what was rejected and why.
4. If the auditor found something a playbook or standards sheet should have caught, add it to that sheet in the kit (see the `playbooks` and `standards` skills for where).
