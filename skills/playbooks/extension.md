# Playbook: Browser extension

## When it applies
Chrome, Edge, Brave and Firefox extensions (Manifest V3).

## Stack options to research
- WXT (cross-browser, Vite-based), Plasmo, or a plain Vite + TypeScript setup.
- UI in popup / side panel / options page: plain DOM, Preact, Svelte or React (keep bundle small).
- Storage: `chrome.storage` (sync for small settings, local for larger data).

## Test tools
- Unit: Vitest with mocked `chrome.*` APIs.
- End-to-end: Playwright with the unpacked extension loaded in Chromium.
- Firefox: `web-ext run` and `web-ext lint`.
- Screenshot of popup / content-script result as proof for UI changes.

## Required project commands
Record in `AGENTS.md`: install, dev (loads unpacked), test, lint, typecheck, build (per browser), zip (store package), `web-ext lint` for Firefox.

## Security basics
- Least privilege: prefer `activeTab` and `optional_host_permissions` over broad `host_permissions`. New permissions trigger warnings and can disable the update for users.
- No remotely hosted code: all JS ships in the package. No `eval`, `new Function` or string-to-code (MV3 rule).
- Treat page content as hostile: content scripts never inject unsanitized HTML; message passing validates sender and payload.
- Secrets: never ship API keys in the extension; call your own backend.
- Strict Content Security Policy; no inline scripts in extension pages.

## Standards
- Chrome Web Store Program Policies, incl. Use of Permissions, Limited Use of user data, and Additional Requirements for Manifest V3.
- Firefox Add-on Policies (Extension Workshop); Firefox signs every add-on through AMO.
- WCAG 2.2 AA for popup and options UI.

## Before-publish checklist
- [ ] Tests, lint, typecheck, build pass for each target browser (paste output); `web-ext lint` clean for Firefox.
- [ ] Permissions list reviewed: each one is used and justified in the store form.
- [ ] No remote code, no `eval`; the zip contains only built files (no source maps with secrets, no `.env`).
- [ ] Privacy: data use disclosed in the store listing; privacy policy URL if any user data is handled.
- [ ] Version bumped in `manifest.json`.
- [ ] Store assets ready: icon sizes, screenshots, short and long descriptions.
- [ ] Tested as a fresh install and as an update from the previous version.
- [ ] Firefox: source code package ready if the build is minified or bundled (AMO review asks for it).

## Sources
- Chrome Web Store Program Policies: https://developer.chrome.com/docs/webstore/program-policies
- MV3 additional requirements: https://developer.chrome.com/docs/webstore/program-policies/mv3-requirements
- Declare permissions: https://developer.chrome.com/docs/extensions/develop/concepts/declare-permissions
- Firefox Add-on Policies: https://extensionworkshop.com/documentation/publish/add-on-policies/
- web-ext reference: https://extensionworkshop.com/documentation/develop/web-ext-command-reference/
