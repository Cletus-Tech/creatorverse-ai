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
