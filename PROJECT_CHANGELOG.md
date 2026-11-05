## 2026-11-05 — Homepage navigation and founder portrait refinement

Status: **Implemented on `main`; awaiting visual review on desktop and mobile.**

- Replaced the desktop Explore dropdown with six visible navigation links: Home, Divisions, Explore, About, Community and AI Assistant. Explore now opens the learning/discovery page; Courses remains accessible from the mobile menu and its own page.
- Preserved the existing account area and its authentication-driven Dashboard/Profile/Admin controls; no role or access logic was changed.
- Redesigned only the homepage founder portrait area: reduced it to a static circular portrait with a restrained ring/glow, compact identity caption and a small horizontal social strip. Responsive sizing keeps it within the hero artwork column.
- Left homepage copy, 3D/background artwork, division cards, course sections, footer and other page layouts unchanged.

# PROJECT_CHANGELOG

Stages: Planned · In development · Completed · Tested · Deployed

## 2026-10-31 — Phase 1: Public shell

Status: **Completed — not browser-tested, not deployed.**

Done:
- Shared header/footer (`layout.js`) on every page; mobile hamburger menu added (visible addition to the approved design, built on the existing look).
- Pages: `learn.html`, `category.html?c=slug`, `about.html`, `soon.html?p=community|resources|login|get-started`, `legal.html?p=privacy|terms`.
- Home category cards now link to `category.html`; Learn and Category pages read `data/categories.json`.
- Watch Introduction opens a modal (plays `introVideo` from `data/site.json`; shows "coming soon" if unset).
- Founder photo, social links and contact email come from `data/site.json` (empty for now; empty social icons are inert and marked "Link not set yet").

Assumptions made (confirm or reverse): kept the 7th category; kept US spelling "Monetization"; static HTML + vanilla JS; no backend yet.

Deferred: home cards are still hardcoded in `index.html` (move to data with the backend); legal pages are outlines only; Community/Resources/Login/Get Started are honest "coming soon" pages, not real features; pages must be served over http(s) (Pages/Cloudflare) because they fetch JSON, so opening the files directly from storage will not load categories.

## 2026-10-31 — Phase 0: Foundations (no visible change)

Status: **Completed** (CSS/JS split verified byte-identical to the original by script).
**Not yet Tested in a browser. Not Deployed.**

Done:
- Original landing page kept untouched in `reference/creatorverse-ai-landing.original.html`.
- Site moved to `public/`. CSS split verbatim into `assets/css/tokens.css` (the `:root` variables) and `assets/css/components.css`; JS split verbatim into `assets/js/nav.js` and `assets/js/starfield.js`. No values changed.
- GitHub Pages deploy workflow added (`.github/workflows/deploy-pages.yml`, publishes `public/`). Reason: gives a one-push build with no build tooling.
- `.gitignore` (keeps `.env` secrets out of the repo), README, this changelog.

Not done / deferred:
- Full `MASTER_PROJECT_PLAN.md` — placeholder only; original must be supplied.
- Mobile menu, working routes, footer, legal pages, About (Phase 1, needs approval for the visible menu).
- Backend, database, auth, payments, storage (Phase 2+; stack not yet approved).

## Pending decisions (from the Technical Review)
1. Backend stack (recommended: Supabase + Cloudflare R2 + Paystack)
2. Frontend: static HTML + vanilla JS (current) or a framework
3. Is the 7th card "Algorithm Analysis & Niche Selection" in the plan?
4. US (Monetization) or UK (Monetisation) spelling
5. Payment model: per-course, subscription, or both
6. Phase 1 video strategy and student upload limits
7. Approval to add a mobile hamburger menu
8. Soft-delete/archive policy vs rule 10

## Status register
| Area | Stage |
|---|---|
| Landing: nav, hero, categories (static) | Completed (not browser-tested) |
| Phase 0 foundations | Completed |
| Everything else in the plan | Planned |


## 2026-11-05 — Global ecosystem foundation: divisions hub

Status: **Implemented on feature branch; browser-tested and deployed status pending.**

Done:
- Added `divisions.html` as the first public entry point for the six-division CreatorVerse ecosystem.
- Added responsive styling in `divisions.css`.
- Added a Divisions link to the shared desktop and mobile navigation through `layout.js`.
- Academy and Community cards link to their existing pages. Marketplace, Affiliate, Realty, and Business are explicitly marked in development and have no fake action buttons.
- Preserved the existing static HTML/CSS/JavaScript architecture and did not alter Supabase schema, authentication, payments, or existing division workflows.

Not yet done:
- Browser/device testing and deployment verification.
- Full audit/reconciliation of live deployment and connected Supabase project.


## 2026-11-05 — Homepage information architecture and navigation redesign

Status: **In development — implementation on feature branch; browser testing and deployment pending.**

Planned changes:
- Rework the shared desktop navigation into a deliberate two-row layout so the primary navigation and account actions cannot collide or overlap at common desktop widths.
- Keep the existing 3D hero/visual treatment intact.
- Remove course and learning-category card sections from the landing-page rendering; direct visitors to the dedicated course catalogue at `courses.html`.
- Add a concise platform introduction, three real destination cards (Academy, creation pathway, Community), and a prominent course-catalogue call to action.
- Preserve the existing course catalogue, category pages, CMS content, authentication and division routes.

Acceptance checks still required: desktop widths around 1024–1600px, mobile/tablet menu behavior, no horizontal overflow, landing page has no course/category card grid, and course links open the existing catalogue.


## 2026-11-05 — Borderless founder visual blend

Status: **Committed to main; production deployment triggered.**

- Removed the portrait's framed-card treatment, hard border, crop and enclosing shadow.
- Changed the founder visual to a free-floating, naturally proportioned image with soft radial edge fading and restrained blue/cyan atmospheric glow.
- Kept the founder caption integrated as a subtle overlay rather than a separate card.
- Applied the same borderless treatment when the CMS portrait style is set to framed, so the visual cannot unexpectedly return to a boxed appearance.
- Responsive sizing and image blending are included for mobile.
- Browser/device visual validation remains pending.


## 2026-11-05 — Full-bleed 3D homepage artwork and navigation polish

Status: **Committed to main; Vercel deployment pending verification.**

- Corrected the target: this change applies to the admin-uploaded 3D classroom/background artwork, not the founder portrait.
- Moved the 3D artwork layer to the full homepage hero section so it is no longer confined inside the rounded, bordered hero panel.
- Removed the inner hero panel border, rounded corners, clipping and heavy card shadow when the 3D artwork is enabled.
- Added broad radial edge blending so the scene dissolves into the page background rather than ending in a visible rectangle.
- Kept the navigation as the intentional opaque, dark top layer, with a stronger backdrop and clear separation from the hero artwork.
- Renamed the navigation destinations to the shorter, cleaner “Courses” and “Learning Paths”.
- Founder portrait presentation and CMS founder image settings were not targeted by this correction.
- Browser/device visual validation remains pending.


## 2026-11-05 — Immersive CreatorVerse homepage redesign

Status: **Committed directly to main; production deployment verification pending.**

- Adopted the premium digital-agency visual direction selected by the user, while retaining CreatorVerse's dark navy and blue identity.
- Reworked the 3D hero artwork into a full-bleed background layer with a controlled blue-toned dark overlay and broad radial edge fading. The image is no longer confined to a rounded rectangular panel or clipped card.
- Kept the top navigation as a distinct opaque dark band above the hero artwork.
- Refined hero typography, call-to-action styling, proof points, founder image placement and responsive layout without changing founder CMS content.
- Replaced the generic three-card landing section with a six-division ecosystem overview. Academy and Community link to existing destinations; Marketplace, Affiliate, Realty and Business are clearly marked as in development and are not presented as working features.
- Added a focused course/divisions call-to-action section and preserved the separate course catalogue.
- No backend schema, authentication, payment, or existing Academy/Community workflows were changed.
- Visual QA across actual mobile and desktop browsers remains pending.


## 2026-11-05 — Homepage social restoration and visual enrichment

Status: **Committed directly to main; deployment verification pending.**

- Restored visible Facebook, WhatsApp Channel, TikTok and YouTube links in the homepage founder/social area instead of hiding the social row over the full-bleed hero.
- Added a dedicated Connect area in the shared footer with the same official social destinations; the existing configurable contact email slot remains available.
- Enriched the six division cards with relevant photographic artwork, layered image overlays, distinct restrained accent colours and hover treatment.
- Added more colour variation to the pathway panel and social controls while preserving the dark premium visual identity, readable contrast and responsive layouts.
- No Academy/Community workflows, database schema, authentication or payment logic changed.
- Visual QA on actual mobile and desktop browsers remains required.

 
## 2026-11-05 — Global navigation and brand identity redesign

Status: **Committed directly to main; deployment verification pending.**

- Rebuilt the shared top navigation with a stronger CreatorVerse AI brand mark, refined typography, luminous gradient accents and glass-like surfaces.
- Consolidated secondary destinations into an accessible Explore dropdown with Courses, Learning Paths, About, Community and AI Assistant.
- Added a dedicated account dropdown for Login/Get Started and signed-in Dashboard/Logout actions; Admin Panel is injected only for admin and super-admin roles.
- Redesigned the mobile navigation as a responsive discovery panel with numbered destinations and clear account actions.
- Preserved the existing mobile bottom navigation and its destinations.
- No course, community, authentication, role-permission or database workflows were intentionally changed.


## 2026-11-05 — Navigation size and transparency correction

- Reduced the homepage navigation height and brand mark sizing to reclaim vertical space.
- Removed the heavy opaque bar, large shadow and prominent top border; the compact navigation now overlays the hero with a subtle transparent glass treatment so the 3D background remains visible behind it.
- Tightened link spacing, button sizing and dropdown offsets.
- Adjusted the homepage hero's top content offset to prevent text from colliding with the compact navigation.
- Kept the navigation dropdown, account actions and mobile menu interactions intact.
