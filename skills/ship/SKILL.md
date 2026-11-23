---
name: ship
description: Pre-publish gate before any release, deploy, store submission or production update. Use when the user says "ship", "publish", "release", "deploy", or asks if something is ready to go live.
---

# Ship

Nothing goes public without passing this gate and an explicit user "yes". Changes come first and checks last, so every check covers exactly what ships.

1. **Playbooks.** Read the playbooks listed in `AGENTS.md` (via the `playbooks` skill). If none are listed, pick them now and add them to `AGENTS.md`.
2. **Release notes.** Draft a short changelog entry (Keep a Changelog style) and bump the version (SemVer) if the project versions.
3. **Audit gate.** If the release touches security, auth, payments, user data or money, run the `audit` skill on the release diff. Fix or explicitly accept each high finding with the user.
4. **Clean state.** Commit the changes from steps 1-3. `git status` clean, on the right branch, up to date with remote.
5. **Checks.** Run the project's test, lint, typecheck and build commands. Delegate long runs to Bulk. Paste the summary output.
6. **Secrets.** Scan the diff since the last release for keys, tokens, `.env` contents and private URLs. On a first release, scan every tracked file (`git ls-files`). Confirm no `.env*` or credential file is tracked and that they are git-ignored. If a built package ships (store bundle, zip, image), check it too.
7. **Checklist.** Go through every "Before-publish checklist" item of each playbook. Mark each: pass (with proof), fail, or n/a (with reason).
8. **Ask.** Show: checks output, checklist result, audit result, release notes, exact publish command. Wait for the user's "yes". Then publish and paste the result (URL, version, store status).

Any fail stops the gate. Report what failed and the fix; do not publish around it. If anything changes after step 4, commit it and run steps 4-7 again.
