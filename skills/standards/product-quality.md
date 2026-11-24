# Product quality (apps and web apps)

## When it applies
Anything with accounts, forms, data or payments. Covers what makes an app feel solid: forms, state, backend safety and support. Pairs with `ui-visual-design.md` and `web-production.md`. Payments or personal data make the work high-stakes: run `audit`.

Adapted from a working developer's UI/UX checklist, checked against the sources cited.

## Feedback
- **Instant response**: the UI reacts within 100 ms of a tap (pressed state, optimistic update, or pending state). Source: https://web.dev/articles/inp
- **Skeletons for content, spinners only for short actions** (see `ui-visual-design.md`).
- **Lock submit and pay buttons after the first tap** with a pending state, and make the server ignore repeats (idempotency key, below). Source: https://docs.stripe.com/api/idempotent_requests
- **Plain labels and messages**: say the action ("Pay ₱1,500"), and errors say what happened and what to do. Source: https://www.nngroup.com/articles/error-message-guidelines/
- **App splash screen** (installed apps): only while the app truly loads, using the platform's splash (manifest `background_color` and icon, or the native launch screen). Source: https://web.dev/learn/pwa/web-app-manifest

## Forms and input
- **Validate on the client for speed and on the server for safety.** Source: https://cheatsheetseries.owasp.org/cheatsheets/Input_Validation_Cheat_Sheet.html
- **Prevent errors first**: right input types (`type="email"`, `inputmode="numeric"`), sensible defaults, constraints shown before submit. Source: https://www.nngroup.com/articles/slips/
- **Autofill on**: correct `autocomplete` tokens (`email`, `given-name`, `tel`, `current-password`, `new-password`, `one-time-code`); never block paste. Source: https://www.w3.org/TR/WCAG22/#identify-input-purpose
- **Visible labels** (not placeholder-only); errors tied to fields with `aria-describedby` and `aria-invalid`. Source: https://www.w3.org/WAI/tutorials/forms/
- **Email**: trim; compare and store a lowercased copy for lookup and duplicates; keep what the user typed for display. Source: https://www.rfc-editor.org/rfc/rfc5321
- **Names**: accept any Unicode, apostrophes, hyphens, spaces and one-word names. Source: https://www.w3.org/International/questions/qa-personal-names
- **Photo uploads**: resize on the device before upload (long side about 2048 px, quality about 0.8), keep orientation, and check type and size again on the server. Source: https://developer.mozilla.org/docs/Web/API/HTMLCanvasElement/toBlob

## State and data
- **Save progress at every step** of multi-step flows, so a refresh or lost signal does not lose work. Source: https://www.nngroup.com/articles/wizards/
- **Times**: store UTC (plus the IANA time zone for future events); show local time with `Intl.DateTimeFormat`. Source: https://developer.mozilla.org/docs/Web/JavaScript/Reference/Global_Objects/Intl/DateTimeFormat
- **Payments survive bad signal**: the payment provider's webhook is the source of truth; on reconnect the app re-reads the payment status instead of charging again. Source: https://docs.stripe.com/webhooks
- **Caching**: HTTP cache and a service worker for the shell; a query cache (for example TanStack Query) for data. Source: https://web.dev/articles/http-cache
- **Normalized database**, with indexes on what you filter by; connection pooling and caching for traffic spikes. Source: https://supabase.com/docs/guides/database/connecting-to-postgres

## Security
- **Authorization per row**: row level security (or an equal server check) on every table with user data. Source: https://supabase.com/docs/guides/database/postgres/row-level-security
- **Secrets on the server only**; a public "anon" key is fine only with RLS on. Never commit keys. Source: https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html
- **Private storage buckets**, files served by short-lived signed URLs. Source: https://supabase.com/docs/guides/storage/security/access-control
- **Rate limiting** on login, sign-up, password reset, OTP and payment endpoints. Source: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html
- **Passwords**: use a managed auth provider when possible; if you hash yourself, Argon2id (19 MiB memory, 2 iterations, 1 thread) or bcrypt cost 10+. Minimum 8 characters, no composition rules, check against breached passwords. Source: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html and https://pages.nist.gov/800-63-4/sp800-63b.html
- **Duplicate payments blocked** with idempotency keys on every payment request. Source: https://docs.stripe.com/api/idempotent_requests
- **Account deletion** that keeps records whole: soft-delete or anonymize personal data, keep financial records the law requires. Source: https://privacy.gov.ph/data-privacy-act/
- **Errors**: users see a friendly message; logs get the detail; never show stack traces. No console errors in production. Source: https://cheatsheetseries.owasp.org/cheatsheets/Error_Handling_Cheat_Sheet.html

## Onboarding and support
- **Short onboarding**: let people reach the main job fast; ask only what you need now. Source: https://www.nngroup.com/articles/mobile-app-onboarding/
- **FAQ or help page** for the top questions, and a visible contact path.
- **Test the full password reset flow** (email arrives, link expires, old sessions end) before every release. Source: https://cheatsheetseries.owasp.org/cheatsheets/Forgot_Password_Cheat_Sheet.html

## Rules worth keeping
- (none yet)
