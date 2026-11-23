## What and why

<!-- One or two sentences. Link the issue if there is one: "Closes #12". -->

## Kind of change

- [ ] New playbook or standards sheet
- [ ] Rule or skill change
- [ ] Installer change (both `install.ps1` and `install.sh`, with tests)
- [ ] Docs only
- [ ] CI or tooling

## Proof

<!-- Paste the real output. For a rule or skill change, describe the fresh-thread run you tried. -->

```
bash tools/check.sh
...
```

## Checklist

- [ ] `bash tools/check.sh` passes
- [ ] Installer changed: tests added to both test scripts, and both pass
- [ ] `CHANGELOG.md` has a line under `[Unreleased]` (skip for docs typos)
- [ ] No private data (names, emails, local paths, tokens, private project names)
- [ ] Rule text is short, plain English, and vendor-neutral
