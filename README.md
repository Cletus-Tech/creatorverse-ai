# CreatorVerse

CreatorVerse is currently served as a **root-level static HTML/CSS/JavaScript website**. The existing site is the legacy web client while the coordinated website and Flutter app rebuild is planned and audited.

## Current repository layout

- Root `*.html` — website pages and route entry points.
- Root `*.css` — shared design tokens, components, page and responsive styles.
- Root `*.js` — shared navigation, layout, authentication, site configuration and page behaviour.
- `assets/` — brand and interface assets, including the CreatorVerse SVG emblem.
- `documentation/` — product, brand, website, mobile, technical and audit blueprints.
- `supabase/` — database migrations and backend project assets (where present).
- `PROJECT_CHANGELOG.md` — project decisions and implementation history.

> Important: this repository does not currently use a root `package.json` or root `vercel.json`. Do not assume this is already a Next.js app or that a `public/` folder is the production output.

## Hosting

The linked Vercel project is `creatorverse-ai`, connected to this repository's `main` branch. The verified production domain is:

- `https://creatorverse-ai.vercel.app/`

Recent pushes to `main` have generated production deployments. Keep the current static site intact until a replacement application has been built, preview-tested and approved for a controlled domain cutover.

Generated Vercel deployment URLs may be covered by deployment SSO protection. Use the verified production domain for the public website.

## Development and safety rules

1. Work on the existing `main` branch; do not create parallel branches for this project.
2. Preserve existing Supabase users, profiles, courses, enrolments, progress, certificates, community data, messages, creator applications and payment records.
3. Never reset the production database as a shortcut.
4. Use additive, reversible database migrations with verification and rollback planning.
5. Keep privileged actions enforced by database policies and server-side authorization, not only by hiding UI controls.
6. Do not claim that a planned feature is live until its backend, permissions and user workflow are implemented and tested.
7. Build the website and Flutter Android/iOS clients against the same Supabase identity and data model.

## Product direction

CreatorVerse has three main divisions:

- **Digital Skills** — practical technology, creative and professional skills.
- **Academic** — secondary-school/exam support and tertiary education.
- **Campus Life** — accommodation, roommate discovery and student services.

Creator/instructor/teacher/exhibitor applications are distinct from ordinary course enrolment. Learners cannot issue or print their own certificates; certification remains subject to administrator review and issuance.

Emergency SOS is outside CreatorVerse scope and belongs to a separate project.

## Project documentation

Start with:

- `documentation/MASTER_PRODUCT_BLUEPRINT.md`
- `documentation/BRAND_AND_DESIGN_BLUEPRINT.md`
- `documentation/WEBSITE_BLUEPRINT.md`
- `documentation/MOBILE_APP_BLUEPRINT.md`
- `documentation/TECHNICAL_AND_DEVELOPMENT_BLUEPRINT.md`
- `documentation/PHASE_0_LEGACY_AUDIT.md`
- `PROJECT_CHANGELOG.md`
