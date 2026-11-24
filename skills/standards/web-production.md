# Web production

## When it applies
Any website or web app going live: responsiveness, speed, SEO, finishing touches and pre-launch checks. Pairs with `ui-visual-design.md` (how it looks) and `product-quality.md` (forms, data, security). The `ship` skill checks this sheet before a web release.

Adapted from a working web developer's production checklist, checked against the sources cited.

## Responsiveness
- **Content-based breakpoints, mobile first**: start at 320 px and add a breakpoint where the layout breaks. Typical ranges as a starting point: 320-479, 480-767, 768-1023, 1024-1399, 1400+. Source: https://www.w3.org/TR/WCAG22/#reflow
- **Container queries for components** that live in different widths (cards, sidebars). Source: https://developer.mozilla.org/docs/Web/CSS/CSS_containment/Container_queries
- **Fluid type and spacing with `clamp()`** and a rem term (see `ui-visual-design.md`). Source: https://www.w3.org/TR/WCAG22/#resize-text
- **Never block zoom**: no `user-scalable=no` or `maximum-scale` in the viewport tag. Source: https://www.w3.org/TR/WCAG22/#resize-text

## Performance
- **Core Web Vitals targets** (75th percentile of real users): LCP 2.5 s or less, INP 200 ms or less, CLS 0.1 or less. Check field data, not only Lighthouse. Source: https://web.dev/articles/vitals
- **Images**: `<picture>` with AVIF, then WebP, then JPEG; `srcset` and `sizes`; an image CDN (Cloudinary, imgix or the host's) with automatic format and quality. Source: https://web.dev/articles/choose-the-right-image-format
- **No layout shift**: `width` and `height` attributes or `aspect-ratio` on every image, video and embed. Source: https://web.dev/articles/optimize-cls
- **Lazy-load below the fold only**: `loading="lazy"` on images under the fold; the LCP image gets `fetchpriority="high"` and is never lazy. Source: https://web.dev/articles/lcp-lazy-loading
- **Preload sparingly**: the LCP image and the one critical font. Inline critical CSS instead of preloading stylesheets. Source: https://web.dev/articles/preload-critical-assets
- **Fonts**: self-hosted `.woff2`, subset, only the weights used (or one variable font), `font-display: swap` and a size-adjusted fallback. Source: https://web.dev/articles/font-best-practices
- **Icons as SVG** (inline or sprite); decorative ones `aria-hidden="true"`. Source: https://developer.mozilla.org/docs/Web/SVG
- **Caching**: hashed file names with `Cache-Control: public, max-age=31536000, immutable`; a service worker for offline. Do not cache images in `sessionStorage`. Source: https://web.dev/articles/http-cache
- **Heavy 3D and WebGL** (Three.js): load it lazily; show it only when the device can (`pointer: fine`, `prefers-reduced-motion: no-preference`, WebGL available, no Save-Data); otherwise a static poster image. Pause it off screen, cap the pixel ratio at 2. Source: https://developer.mozilla.org/docs/Web/CSS/@media/prefers-reduced-motion
- **Third-party scripts** load `async` or `defer`, and each one earns its place. Source: https://web.dev/articles/optimizing-content-efficiency-loading-third-party-javascript
- **No splash screen that hides content.** A first-visit intro must be under 1 s, skippable, and never the LCP element. Source: https://web.dev/articles/lcp

## Premium motion (websites)
Scroll-triggered reveals, parallax, horizontal scroll sections, stacked cards, smooth scroll (Lenis), GSAP and WebGL can make a site feel high-end. Rules:
- All of it sits behind `prefers-reduced-motion: no-preference`; reduced motion gets native scroll and simple fades.
- Horizontal scroll sections also work with a keyboard and without dragging. Source: https://www.w3.org/TR/WCAG22/#dragging-movements
- Prefer CSS scroll-driven animations; never run work on every `scroll` event; animate only `transform` and `opacity`.
- One signature moment per page beats effects everywhere. Watch INP on a mid-range phone.
Source: https://web.dev/articles/animations-guide

## SEO and sharing
- **Per page**: a unique `<title>` and meta description; `<html lang>`; one `h1`; a self-referencing absolute canonical URL. Source: https://developers.google.com/search/docs/appearance/snippet
- **Social cards**: `og:title`, `og:description`, `og:image` (1200 x 630, absolute URL), `og:url`, `twitter:card`. Source: https://ogp.me
- **Icons**: `favicon.ico`, an SVG or PNG icon (a multiple of 48 px), `apple-touch-icon` 180 px. Source: https://developers.google.com/search/docs/appearance/favicon-in-search
- **Crawling**: `robots.txt` that links the sitemap (it controls crawling, not indexing; use `noindex` to hide a page); `sitemap.xml` with canonical URLs only. Source: https://developers.google.com/search/docs/crawling-indexing/robots/intro
- **Structured data** (Person or Organization, plus the page type) instead of a `meta author` tag, which Google ignores. Source: https://developers.google.com/search/docs/appearance/structured-data/intro-structured-data
- **After launch**: verify the domain in Google Search Console (and Bing Webmaster Tools), submit the sitemap, request indexing. Rankings fade if the site is not kept up. Source: https://search.google.com/search-console/about
- **Clean URLs**: readable paths, no `.html` or query noise; 301 redirect any changed URL; a real 404 page with status 404. Source: https://developers.google.com/search/docs/crawling-indexing/url-structure

## Finishing touches
- **Scrollbars**: do not hide the page scrollbar. Style it (`scrollbar-width: thin`, `scrollbar-gutter: stable`); hide it only inside carousels that also have buttons and keyboard support. Source: https://developer.mozilla.org/docs/Web/CSS/scrollbar-width
- **Tap highlight**: `-webkit-tap-highlight-color: transparent` on custom controls only when they have their own `:active` and `:focus-visible` styles. Source: https://www.w3.org/TR/WCAG22/#focus-visible
- **Nav links**: smooth hover and underline transitions with the project's easing token (150-250 ms). Source: https://github.com/emilkowalski/skills

## Before launch
- No broken links (run a link checker); no console errors; a custom 404.
- HTTPS with HSTS; security headers (CSP, `X-Content-Type-Options`, `Referrer-Policy`). Source: https://owasp.org/www-project-secure-headers/
- Lighthouse and a real mid-range phone: Core Web Vitals in the green, accessibility score with no failures.
- Privacy and cookie notice where the law requires one (for the Philippines, RA 10173). Source: https://privacy.gov.ph/data-privacy-act/

## Rules worth keeping
- (none yet)
