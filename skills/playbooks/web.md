# Playbook: Web

## When it applies
Websites, landing pages, web apps, SaaS, admin dashboards, bot dashboards, APIs with a web front end.

## Stack options to research
Research 2-3 current options for the project's needs; do not default blindly.
- Static or content site: Astro, Next.js static export, plain HTML + Vite.
- Full-stack app: Next.js, SvelteKit, Remix / React Router, Nuxt.
- API-only: Hono, Fastify, FastAPI.
- Data: Postgres (Supabase, Neon), SQLite (Turso, Cloudflare D1), Firebase.
- Auth: the framework's or the platform's auth library; never hand-rolled password storage.
- Hosting: Vercel, Netlify, Cloudflare Pages/Workers, a VPS. Compare free tier limits and cold starts.

## Test tools
- Unit: Vitest or Jest (JS/TS), pytest (Python).
- End-to-end and visual proof: Playwright (screenshots for UI tweaks).
- Accessibility: axe-core (via Playwright), Lighthouse.
- Performance: Lighthouse / PageSpeed Insights.

## Required project commands
Record these in the project `AGENTS.md`: install, dev, test, lint, typecheck, build, preview (production build served locally), e2e.

## Security basics (OWASP Top 10:2025)
- Access control on every server route and API, checked server-side (A01). Includes SSRF: never fetch user-supplied URLs without an allowlist.
- Safe defaults: no debug mode, no default keys, security headers (CSP, HSTS), CORS limited to known origins (A02).
- Supply chain: lockfile committed, `npm audit` / `pip-audit` clean of high issues, no unknown packages (A03).
- HTTPS only; secrets in env vars, never in client bundles; hash passwords with a proven library (A04).
- Parameterized queries; escape output; validate all input with a schema (A05).
- Auth: rate-limit login, secure + httpOnly + SameSite cookies, session expiry (A07).
- Log security events without logging secrets or personal data (A09).
- Handle errors without leaking stack traces to users (A10).

## Standards
- OWASP Top 10:2025.
- Core Web Vitals, judged at the 75th percentile: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1.
- WCAG 2.2 level AA (focus visible, target size, keyboard use, contrast, accessible auth).
- Google SEO Starter Guide for public sites (titles, descriptions, crawlable links, sitemap).

## Before-publish checklist
- [ ] Production build succeeds; tests, lint and typecheck pass (paste output).
- [ ] No secrets in the repo or client bundle; `.env*` git-ignored; production env vars set on the host.
- [ ] Every protected route checked server-side for the right user.
- [ ] Dependency audit has no high or critical issues.
- [ ] Lighthouse on key pages: Core Web Vitals in "good"; accessibility score checked; axe finds no serious issues.
- [ ] Works at phone width (375 px) and desktop; no horizontal scroll.
- [ ] Security headers present (check response headers).
- [ ] Error pages (404, 500) exist and leak nothing.
- [ ] Public site: title, meta description, Open Graph image, favicon, sitemap, robots.txt.
- [ ] Privacy policy if it collects any personal data; cookie notice if required where users live.
- [ ] Backups or export for the database; rollback path known.

## Sources
- OWASP Top 10:2025: https://owasp.org/Top10/2025/
- Core Web Vitals thresholds: https://web.dev/articles/defining-core-web-vitals-thresholds
- Web Vitals overview: https://web.dev/articles/vitals
- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- Google SEO Starter Guide: https://developers.google.com/search/docs/fundamentals/seo-starter-guide
- Playwright: https://playwright.dev/
