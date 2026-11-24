# UI visual design

## When it applies
Any screen a person sees: websites, web apps, mobile apps, dashboards, emails. Used in the `kickoff` and `client` design step, and when reviewing any UI change.

Where sources disagree, this sheet has already picked one answer. A brief the user or client approved wins over it; record the override in `docs/DECISIONS.md`.

## Process
- **Design system before screens**: color, type, spacing, radius, shadow and motion tokens first, then one component set, then screens built only from tokens. Why: consistency comes from tokens, not from taste per screen. Source: https://www.w3.org/community/design-tokens/
- **Know the surface**: decide per screen whether it must persuade (landing page), operate (dashboard, form), or be read (docs, article). Persuade may be bold; operate and read stay calm, dense and predictable. Source: https://github.com/pbakaus/impeccable
- **Real content, both themes, all states**: design with real-looking names, numbers and dates, and show hover, focus, active, disabled, loading, empty and error states. No lorem ipsum. Source: https://github.com/pbakaus/impeccable
- **Review at 375 px and 1280 px** with screenshots, then the squint test: blur your eyes; the one primary action and the hierarchy must still read. Source: https://github.com/pbakaus/impeccable

## Typography
- **Body text 16 px minimum** (1rem), line height 1.5-1.7 for body, 1.1-1.25 for headings. Source: https://www.w3.org/WAI/WCAG22/Understanding/text-spacing
- **Line length 45-75 characters** for reading text (`max-width: 65ch`). Source: https://github.com/pbakaus/impeccable
- **Fluid sizes with clamp() and a rem term**: `font-size: clamp(1rem, 0.9rem + 0.5vw, 1.25rem)`. A vw-only middle value breaks 200% zoom. Source: https://www.w3.org/TR/WCAG22/#resize-text
- **Few families, clear steps**: one family (two at most, each with a job only it can do); a type scale with obvious size and weight steps (ratio 1.2-1.333). Source: https://github.com/pbakaus/impeccable
- **Tracking**: leave body text alone; large display text may go to -0.02 to -0.03em, never below -0.04em. Source: https://github.com/pbakaus/impeccable
- **Wrapping and numbers**: `text-wrap: balance` on headings, `pretty` on paragraphs; `font-variant-numeric: tabular-nums` in tables, prices and timers. Source: https://developer.mozilla.org/docs/Web/CSS/text-wrap
- **Light text on dark** needs a little more line height and weight than dark on light. Source: https://github.com/pbakaus/impeccable

## Color
- **Contrast (WCAG 2.2 AA)**: body text 4.5:1, large text (24 px, or 19 px bold) 3:1, icons, input borders and focus rings 3:1. Source: https://www.w3.org/TR/WCAG22/#contrast-minimum and https://www.w3.org/TR/WCAG22/#non-text-contrast
- **Semantic roles, not swatches**: tokens named by job (`bg`, `surface`, `text`, `text-muted`, `border`, `primary`, `danger`, `success`), defined in OKLCH, with less chroma near white and black. Source: https://developer.mozilla.org/docs/Web/CSS/color_value/oklch
- **One accent per view**: the primary color marks the primary action; do not spend it on decoration. Source: https://github.com/ibelick/ui-skills
- **Never color alone** to carry meaning (errors, status, charts): add text or an icon. Source: https://www.w3.org/TR/WCAG22/#use-of-color
- **Dark mode is designed, not inverted**: its own surface steps; muted text tinted from the hue, not plain grey. Source: https://github.com/pbakaus/impeccable

## Spacing and layout
- **4 px base scale**: 4, 8, 12, 16, 24, 32, 48, 64, 96. Every gap and padding uses a step. Source: https://github.com/pbakaus/impeccable
- **Group by space before boxes**: proximity first, then a divider, then a card. Never cards inside cards. Source: https://github.com/pbakaus/impeccable
- **More space above a heading than below it**; siblings spaced with `gap`. Source: https://github.com/pbakaus/impeccable
- **One elevation language**: a border or a shadow per surface, not both. Radius from tokens (cards 12-16 px, inputs and buttons a step smaller). Source: https://github.com/pbakaus/impeccable
- **Alignment**: edges, baselines and radii line up exactly; a 1-2 px miss reads as sloppy. Source: https://www.ui-skills.com/skills
- **Visual order = DOM order = focus order.** Source: https://www.w3.org/TR/WCAG22/#focus-order
- **Mobile viewport**: `min-height: 100dvh` (not `100vh`), and respect safe-area insets. Source: https://developer.mozilla.org/docs/Web/CSS/length#dynamic_viewport_units

## Components and interaction
- **Touch targets 44 x 44 px** (WCAG 2.5.8 AA minimum is 24 x 24; 44 is Apple HIG and our default). Source: https://www.w3.org/TR/WCAG22/#target-size-minimum
- **Visible focus**: `:focus-visible` outline at least 2 px, 3:1 contrast, never hidden under a sticky header. Source: https://www.w3.org/TR/WCAG22/#focus-not-obscured-minimum
- **Pressed feedback**: buttons get `:active { transform: scale(0.97) }` and a pending state while working. Removing `-webkit-tap-highlight-color` is allowed only when this feedback exists. Source: https://github.com/emilkowalski/skills
- **Labels say the action**: "Save changes", not "Submit"; errors say what went wrong and how to fix it, next to the field. Source: https://www.nngroup.com/articles/error-message-guidelines/
- **Loading**: skeletons that keep the final size for content; a spinner only inside a button or for waits under 1 s. Source: https://web.dev/articles/optimize-cls
- **Empty states** give one clear next action. Destructive actions confirm in a dialog that names the thing being deleted. Source: https://github.com/ibelick/ui-skills
- **Native and accessible primitives**: real `<button>` and `<a>`; for complex widgets one library (Radix, React Aria or Base UI), never mixed. Icon-only buttons get `aria-label`. Source: https://github.com/ibelick/ui-skills
- **Icons**: one SVG icon set with one stroke width. No emoji as icons. Source: https://github.com/pbakaus/impeccable

## Motion
- **Animate with a purpose** (feedback, state change, where something came from), and by frequency: actions done 100+ times a day get none; keyboard actions get none. Source: https://github.com/emilkowalski/skills
- **Durations**: press feedback 100-160 ms; tooltips and small popovers 125-200 ms; dropdowns 150-250 ms; modals and drawers 200-400 ms; one hero entrance per page up to 800 ms. Exits faster than entrances. Source: https://github.com/emilkowalski/skills
- **Easing tokens** (define once, do not invent more): `--ease-out: cubic-bezier(0.23, 1, 0.32, 1)` for entering and exiting; `--ease-in-out: cubic-bezier(0.77, 0, 0.175, 1)` for moving on screen; never `ease-in` on UI. Source: https://github.com/emilkowalski/skills
- **Only `transform` and `opacity`**; never `transition: all`; start from `scale(0.95)` plus `opacity: 0`, never `scale(0)`; stagger lists 30-80 ms. Source: https://web.dev/articles/animations-guide
- **Reduced motion is required**: under `prefers-reduced-motion: reduce`, drop movement (parallax, smooth-scroll libraries, slides) and keep simple fades. Moving content over 5 s needs pause. Source: https://www.w3.org/TR/WCAG22/#animation-from-interactions and https://www.w3.org/TR/WCAG22/#pause-stop-hide
- **Content visible without JavaScript**: entrance animations must not leave content hidden if a script fails. Source: https://github.com/pbakaus/impeccable

## Avoid ("AI slop" tells)
Each needs a reason in the brief to use:
- Purple or rainbow gradients, gradient text, decorative glass and blur, glow halos.
- Every section built as the same icon + heading + text card grid; nested cards.
- An eyebrow label above every heading; numbered sections as decoration.
- A thin border plus a wide soft shadow on the same card; hard offset shadows outside a deliberate neo-brutalist style.
- One default font for everything with no type scale; monospace as a "tech" costume.
- Emoji icons, filler sparklines and progress rings, noise and grid overlays with no job.
- The same fade-up entrance on every section.
Source: https://github.com/pbakaus/impeccable and https://github.com/ibelick/ui-skills

## Rules worth keeping
- (none yet)
