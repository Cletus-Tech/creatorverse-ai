# CreatorVerse AI — Master Project Plan

This is the authoritative index for the living CreatorVerse AI programme. It supersedes the old placeholder warning, but does not claim that planned features are already implemented.

## Product direction
**CreatorVerse AI — Learn. Create. Earn. Connect. Grow.**

Build one unified CreatorVerse brand with modular divisions:
1. CreatorVerse Academy
2. CreatorVerse Marketplace
3. CreatorVerse Affiliate Network
4. CreatorVerse Realty
5. CreatorVerse Business
6. CreatorVerse Community

Shared services: account identity, role/capability permissions, admin control centre, CMS/media, notifications, support, audit logs, and a secure financial ledger.

## Non-negotiable delivery rules
- Preserve verified working functionality; no big-bang rewrite without evidence and approval.
- Free-first. Do not activate paid plans, services, domains, or payment providers without the owner's explicit approval.
- No fake buttons or claims. Clearly label planned or disabled features.
- Enforce access control on backend/database boundaries, not only in the UI.
- Admin-manage content and settings wherever appropriate.
- Mobile-first, accessible, polished interface; no overlapping controls.
- Work in small, testable phases and update the changelog.
- Distinguish planned, implemented, tested, and deployed status.

## Current status
The repository README describes a static HTML/CSS/JavaScript website in `public/` with no build step. The changelog describes a public shell but notes that browser testing and deployment verification remain outstanding. Earlier project discussions refer to Supabase-backed Academy, Community, admin, and manual NGN payment work. These histories must be reconciled against the current branch, live deployment, and connected backend before further implementation.

## Immediate priority
**Phase 0 — Discovery and baseline audit.** Inspect the complete repository, hosting/deployment, current live experience, connected Supabase schema/RLS/storage/functions, and actual user journeys. Back up before any schema or production changes. Do not create new division schemas or rewrite the frontend until this audit is complete.

## Homepage card and social-link refinement
The six homepage division cards now use compact sizing and a horizontal image-and-copy layout on phones. Shared footer and homepage founder social links use icon-only controls with accessible labels. Desktop/mobile browser and production verification remain outstanding.

## About page redesign\nThe About page has been rebuilt as a responsive editorial-style introduction to CreatorVerse AI, its purpose, guiding principles and six-division ecosystem. Academy and Community are shown as available; the remaining divisions are labelled in development. The CMS-managed founder profile and portrait remain supported. Browser and production verification are still required.\n\n## Current homepage redesign
The homepage is being refined to keep the existing 3D hero while separating course discovery into the dedicated catalogue page. The shared navigation is being changed to a two-row desktop layout to prevent account actions and navigation links from colliding. The homepage will introduce the platform and link to Academy, Community, and Divisions without duplicating course/category cards. This work remains in development until responsive browser checks and production deployment are verified.

## Detailed specification
See [docs/CREATORVERSE-GLOBAL-MASTER-BLUEPRINT.md](docs/CREATORVERSE-GLOBAL-MASTER-BLUEPRINT.md) for the complete vision, division scope, roles, conceptual data domains, security requirements, roadmap, acceptance gates, and decision log.

## Project status vocabulary
- **Planned:** not implemented.
- **In development:** implementation underway.
- **Implemented:** code exists; not necessarily tested.
- **Tested:** defined acceptance checks passed in the target environment.
- **Deployed:** verified on the intended live deployment.

Every substantial change must update `PROJECT_CHANGELOG.md` and this plan when it changes scope, architecture, or decisions.


## Unified brand identity
The canonical CreatorVerse symbol is `assets/creatorverse-mark.svg`. All parent-brand placements must reuse this asset rather than inventing local logo variants. Approved lockups may vary in size or omit the wordmark in constrained spaces, but the underlying symbol must remain identical. Division-specific icons may identify individual divisions and must not be mistaken for alternate CreatorVerse parent logos. New pages, emails, certificates, app surfaces and favicons should adopt this same source asset.

## Search visibility and SEO foundation

- Current canonical host (until a custom domain is purchased): `https://creatorverse-ai.vercel.app/`.
- Initial technical SEO is implemented on the public homepage, About, Divisions, Courses, Learn and Community pages: unique titles/descriptions, canonical URLs, social sharing metadata and a public sitemap. Homepage includes Organization and WebSite structured data.
- Private account, admin, dashboard, assessment and utility routes use page-level `noindex, follow` directives.
- `robots.txt` points to the production sitemap. Search engine ownership verification and sitemap submission are not complete until the owner completes the Google Search Console and Bing Webmaster Tools steps.
- Next SEO milestones: verify the live deployment and crawler access; submit sitemap; inspect index coverage; create original, useful digital-skills and AI-learning resources; add public course-specific landing pages; monitor performance and migrate canonical signals carefully when a custom domain is acquired.


## Academy Explore / Learning Categories visual redesign

The Learn page (`learn.html`) now has a distinct colourful creative-education direction: editorial hero with learning photography, category search and quick topic chips, varied image-led category cards, client-side category filtering, and a clear route to the existing Courses catalogue. Category data remains dynamically loaded from the existing source and links continue to use the existing category detail route. No Academy data model, authentication, enrolment, payment, or admin permissions were changed. Implementation is committed to `main`; desktop/mobile visual QA and production verification remain pending.
