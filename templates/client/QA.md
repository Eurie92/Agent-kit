# QA check: <project name>
Internal. Run by us on staging before the client sees it for UAT.
Staging: <URL> · Version: <x.y.z> · Commit: <sha> · Date: <YYYY-MM-DD> · Checked by: <agent / person>

Mark each row Pass, Fail or N/A (with a reason). Every Fail is fixed and re-checked before UAT.

## 1. Scope
| # | Acceptance criterion (from docs/SPEC.md) | Result | Proof (test name, screenshot) |
|---|---|---|---|
| 1 | | | |

Every item in the signed proposal is built. Nothing outside it was added without a change request.

## 2. Automated checks
| Check | Command | Result |
|---|---|---|
| Tests | | |
| Lint and typecheck | | |
| Build | | |
| No console errors or warnings on any key screen | browser console | |
| No broken links | link checker | |

## 3. Look and feel (`standards/ui-visual-design.md`)
| Check | Result |
|---|---|
| Screens match the approved designs (tokens, spacing, type) | |
| Screenshots of every screen at 375 px and 1280 px in `docs/design/qa/` | |
| All states shown: hover, focus, pressed, loading, empty, error, disabled | |
| No placeholder or lorem ipsum; real copy, images and logo | |
| Nothing on the "Avoid" list without a reason | |

## 4. Devices and browsers
| Device / browser | Result | Notes |
|---|---|---|
| Chrome (desktop) | | |
| Safari (iPhone or Mac) | | |
| Android phone (mid-range) | | |
| Firefox or Edge | | |

## 5. Speed, SEO and launch readiness (`standards/web-production.md`, websites)
| Check | Result |
|---|---|
| Lighthouse: performance, accessibility, best practices, SEO (scores) | |
| Core Web Vitals: LCP ≤ 2.5 s, INP ≤ 200 ms, CLS ≤ 0.1 | |
| Titles, descriptions, social cards, favicon, robots.txt, sitemap.xml | |

## 6. Accessibility
| Check | Result |
|---|---|
| Keyboard only: every action reachable, focus always visible | |
| Contrast: text 4.5:1, controls and icons 3:1 | |
| Touch targets 44 px; zoom to 200% works | |
| Reduced motion on: no parallax or smooth-scroll motion | |

## 7. Forms, data and security (`standards/product-quality.md`)
| Check | Result |
|---|---|
| Every form: validation, clear errors, autofill, double-submit blocked | |
| Roles: each role sees only its own data (RLS or server checks tested) | |
| Secrets only on the server; no keys in the client bundle or repo | |
| Rate limits on login, reset, OTP and payments | |
| Payments: duplicate tap, lost signal and refund tested (if any) | |
| Password reset and account deletion tested end to end | |
| Audit run and high findings fixed (payments, logins or personal data) | |

## Result
- Pass: <n> · Fail: <n> · N/A: <n>
- Ready for client UAT: Yes / No
- Known limits to tell the client:
-
