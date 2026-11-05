# CreatorVerse AI — Global Platform Blueprint

**Document status:** Living architecture and delivery blueprint  
**Product direction:** One unified CreatorVerse brand with independently navigable divisions  
**Operating principle:** Free-first, modular, secure, mobile-first, and evidence-based  
**Repository:** `Cletus-Tech/creatorverse-ai`  
**Last updated:** 5 November 2026

---

## 1. Product vision

**CreatorVerse AI — Learn. Create. Earn. Connect. Grow.**

CreatorVerse is intended to become a global digital platform that brings learning, creator services, digital commerce, referrals, property discovery, business promotion, and community into one coherent account and experience.

The divisions share identity, navigation, trust and safety standards, notifications, support, and (when safely implemented) a common financial ledger. Each division must remain modular so it can be launched, improved, paused, or expanded without destabilising the others.

### Brand architecture

Use one parent brand: **CreatorVerse AI**.

Divisions:
1. CreatorVerse Academy
2. CreatorVerse Marketplace
3. CreatorVerse Affiliate Network
4. CreatorVerse Realty
5. CreatorVerse Business
6. CreatorVerse Community

Each division may have its own visual accent and landing page, but should retain the CreatorVerse design system, account, and navigation conventions.

## 2. Product principles and constraints

- **Preserve working features:** no rewrite or destructive migration without a verified reason, backup, and migration plan.
- **Free-first:** prefer free tiers and open-source tools. Do not activate paid services, subscriptions, domains, or payment providers that incur charges without explicit owner approval.
- **No fake functionality:** every visible action must work, be clearly disabled with an explanation, or be labelled as planned.
- **Admin-managed content:** homepage content, division settings, media, pricing, and featured content should ultimately be managed through authorised admin interfaces rather than scattered hardcoded values.
- **Security by default:** enforce permissions in the database/API, not only by hiding UI controls.
- **Mobile-first:** layouts, menus, forms, cards, dialogs, and tables must work on small screens without collisions or horizontal overflow.
- **Incremental delivery:** implement one testable vertical slice at a time.
- **Transparency:** distinguish implemented, tested, deployed, and planned work.
- **Privacy and compliance:** collect only necessary data; provide clear consent, privacy, moderation, and reporting processes.

## 3. Current repository baseline (verified from repository files)

The current repository README describes a **static HTML/CSS/JavaScript site** published from `public/`, with no build step. It documents GitHub Pages and Cloudflare Pages deployment options.

Existing root files include a `MASTER_PROJECT_PLAN.md` placeholder, `PROJECT_CHANGELOG.md`, and `README.md`. The changelog describes a public shell and shared layout, category data, an introduction-video modal, and founder/social/contact data sourced from JSON. It explicitly records that some work was not browser-tested or deployed.

**Important reconciliation required:** previous project discussions refer to a Supabase-backed learning/community implementation, while the current repository README/changelog describe a static public shell. Before connecting these histories or changing production, inspect the complete repository tree, deployment target, Supabase project, database schema, and current live site. Do not assume every feature described in earlier conversations exists in the currently deployed branch.

### Baseline status

| Area | Repository evidence | Delivery status |
|---|---|---|
| Public site shell | README and changelog | Implemented in repo; browser/deployment verification required |
| Shared layout/navigation | Changelog references `layout.js` and shared shell | Implemented in repo; verify on target devices |
| Category data | Changelog references `data/categories.json` | Implemented in repo; verify |
| Founder/video/social content | Changelog references `data/site.json` | Data-driven shell; actual content may be unset |
| Academy | Prior project history indicates course infrastructure; reconcile against current tree/database | Audit required |
| Community | Prior project history indicates working community module; reconcile against current tree/database | Audit required |
| Admin/CMS | Prior project history indicates admin functions; reconcile against current tree/database | Audit required |
| Payments | Prior project history indicates manual NGN bank-transfer/USSD groundwork | Audit before enabling; no live provider assumed |
| Marketplace, affiliate, realty, business | No verified implementation in current baseline | Planned |

## 4. Platform divisions and scope

### 4.1 CreatorVerse Academy
- Course catalogue, categories, search, filters, course detail pages.
- Modules, lessons, video/resources, lesson completion, progress tracking.
- Quizzes, assignments, grading, feedback, learning paths.
- Instructor profiles and instructor permissions.
- Certificates with verifiable identifiers and completion criteria.
- Live classes/webinars and attendance records.
- Course reviews, announcements, and learner support.
- Free and paid course support; payment status must be verified server-side before granting paid access.

### 4.2 CreatorVerse Marketplace
- Seller onboarding and seller profiles.
- Service listings and digital-product listings.
- Categories, search, filters, availability, pricing, and portfolios.
- Buyer enquiries, order lifecycle, delivery evidence, revisions, cancellation, and disputes.
- Ratings/reviews tied to completed orders.
- Platform commission rules and seller balances.
- Admin moderation, listing review, refunds, and dispute handling.
- Do not represent escrow or buyer protection as active until legally and technically implemented.

### 4.3 CreatorVerse Affiliate Network
- Affiliate applications and approval.
- Unique referral codes/links and campaign attribution.
- Click, lead, conversion, reversal, and commission records.
- Commission rules, eligibility, holding periods, and payout requests.
- Fraud controls: self-referral restrictions, duplicate-event protection, suspicious activity review.
- Admin campaign management, reporting, and payout approval.
- No earnings guarantees or misleading income claims.

### 4.4 CreatorVerse Realty
- Property listings for rent, sale, land, short lets, and commercial property.
- Listing owner/agent profiles and verification workflow.
- Photos, videos, location/map data, amenities, pricing, and availability.
- Search by location, type, budget, and features.
- Enquiry, viewing/inspection requests, and communication.
- Listing expiry, moderation, report/block tools, and fraud review.
- Clear distinction between platform listing information and independently verified legal title/ownership.

### 4.5 CreatorVerse Business
- Business directory and public business pages.
- Business profile, categories, contact methods, location, hours, and media.
- Promotion/advertising campaign creation and approval.
- Sponsored placements clearly labelled.
- Leads, enquiry management, campaign metrics, and budget controls.
- Admin approval, billing records, and abuse reporting.
- Advertising must not imply endorsement or guaranteed results.

### 4.6 CreatorVerse Community
- Member profiles, posts, comments, reactions, following, and groups.
- Direct messaging and notifications, with privacy controls.
- Events, webinars, and creator showcases.
- Reporting, blocking, muting, moderation queues, and appeals.
- Spam, impersonation, harassment, and harmful-content controls.
- Community features must be age-appropriate and governed by published rules.

## 5. Shared account, roles, and permissions

Use one account identity across divisions. A person may hold multiple capabilities, but role assignment must be controlled by authorised administrators and validated on the server/database.

Proposed roles (final names and permissions must be reconciled with the existing database before migration):
- **Visitor:** browse public pages and public listings.
- **Member:** basic profile and community participation.
- **Student:** Academy enrolment and learning progress.
- **Instructor:** manage assigned courses and learner feedback.
- **Seller:** manage Marketplace listings and orders.
- **Affiliate:** access referral tools and commission statements.
- **Agent/Property manager:** manage approved Realty listings and enquiries.
- **Business owner/Advertiser:** manage business pages and campaigns.
- **Moderator:** review reports and enforce community/listing policies.
- **Support:** handle user support cases with limited access.
- **Admin:** manage assigned platform areas.
- **Super admin:** platform-wide configuration and privileged administration.

Permissions should be capability-based and scoped by division/resource. Never trust a role value supplied by a browser. Users must not be able to promote themselves. Privileged actions require audit records.

## 6. Super Admin Control Centre

A central admin experience should provide:
- Platform overview and operational health.
- User search, account status, role/capability assignment, and support history.
- Division enable/disable and configuration.
- Homepage/page section CMS with draft, preview, publish, and revision history.
- Media library with upload validation, metadata, and safe deletion/archive.
- Course, listing, campaign, and community moderation tools.
- Payment settings, manual payment verification, refunds/adjustments, and reconciliation.
- Commission, seller balance, and payout approval workflows.
- Reports, analytics, audit logs, and system settings.
- Feature flags and staged rollout controls.

Sensitive actions should require re-authentication or additional confirmation where appropriate. Admin UI controls do not replace database/API authorisation.

## 7. Shared technical architecture — target, not an instruction to rewrite immediately

### Current known baseline
The repository's README describes a static site in `public/` with vanilla HTML/CSS/JavaScript and no build step. The target hosting path documented is GitHub Pages, with Cloudflare Pages as an alternative.

### Proposed evolution
- **Frontend:** preserve the existing public site while auditing it. Consider a framework migration only after documenting routes, data dependencies, hosting constraints, and migration benefits. A gradual route/module migration is preferred over a big-bang rewrite.
- **Database/backend:** if the connected Supabase project is confirmed as the active backend, use PostgreSQL, Auth, Storage, and server-side functions/RPCs where appropriate.
- **Authorisation:** Row Level Security (RLS) for every exposed table; server-side checks for privileged actions; least-privilege service credentials kept server-side only.
- **Storage:** private buckets for private documents; public buckets only for intentionally public media; signed URLs for protected files.
- **Hosting:** retain the currently working free deployment until a tested replacement is approved. Verify provider limits and current free-tier terms before relying on them.
- **Integrations:** email, maps, analytics, search, and payment providers are optional dependencies; select only after cost, data protection, availability, and operational requirements are reviewed.

### Suggested domain boundaries
Use separate tables or clearly scoped records for each business domain, linked to a shared user identity. Avoid a single overloaded table for unrelated marketplace, property, course, and affiliate records.

## 8. Data model domains (conceptual)

These are logical domains, not SQL instructions. Inspect current tables and naming before creating anything.

| Domain | Core records |
|---|---|
| Identity | profiles, role assignments, capability grants, sessions/security events |
| CMS/media | pages, sections, content revisions, media assets |
| Academy | courses, course instructors, modules, lessons, enrolments, lesson progress, quizzes, submissions, certificates |
| Marketplace | seller profiles, listings, listing media, orders, order events, delivery, reviews, disputes |
| Affiliate | affiliate profiles, campaigns, referral codes, click events, conversions, commission ledger, payout requests |
| Realty | agent profiles, properties, property media, verification checks, enquiries, viewing requests |
| Business | business profiles, campaigns, sponsored placements, leads, campaign metrics |
| Community | posts, comments, reactions, follows, groups, memberships, messages, notifications, reports |
| Finance | payment intents, payment events, ledger accounts, ledger entries, refunds, commissions, payouts, reconciliation |
| Governance | audit logs, moderation cases, feature flags, policy acknowledgements |

### Data design rules
- Use stable UUID primary keys and foreign keys.
- Add created/updated timestamps and explicit status fields.
- Use soft-delete/archive for business records where auditability is required; define retention and deletion rules for personal data.
- Enforce unique constraints and idempotency keys for payment, conversion, and webhook events.
- Store money as integer minor units (for NGN, kobo) plus ISO currency code; never use floating-point arithmetic for balances.
- Keep an append-only financial ledger; corrections should be compensating entries, not silent edits.
- Index actual query patterns; avoid duplicate indexes and redundant RLS policies.
- Use migrations with rollback/backup strategy; never paste unreviewed destructive SQL into production.

## 9. Payments and financial operations

Initial operating context: NGN and a free-first approach. Prior project discussions describe manual Nigerian bank transfer/USSD groundwork, but current configuration and live status must be verified.

- Keep payment methods disabled until bank details, reconciliation, support process, and admin permissions are configured and tested.
- Do not activate Paystack, Flutterwave, Stripe, or any paid integration without explicit owner approval and a current cost/compliance review.
- Never mark an order/enrolment paid based only on a client-side redirect or screenshot.
- Manual payments require a reference, amount, payer details as necessary, expiry, admin verification, and audit trail.
- Separate payment intent, provider/manual payment event, ledger posting, refund, commission, and payout.
- International currencies and payment providers are later-stage work after legal, tax, settlement, chargeback, and supported-country reviews.
- Clearly publish pricing, fees, refund rules, payout timelines, and any applicable taxes before checkout.

## 10. Security, privacy, and trust

Required controls before public expansion:
- Review every RLS policy for correct ownership, role scope, and least privilege.
- Remove duplicate/overlapping policies only after proving the replacement preserves intended access.
- Validate all input on trusted server-side boundaries.
- Protect against IDOR, privilege escalation, XSS, CSRF where relevant, injection, abuse, and rate-limit bypass.
- Keep secrets out of browser bundles, source control, logs, and public configuration.
- Use secure session handling and account recovery; protect privileged accounts with MFA where supported.
- Add rate limits and abuse monitoring for login, messaging, referrals, enquiries, and uploads.
- Validate file size/type; consider malware scanning for user uploads.
- Maintain admin audit logs and incident response procedures.
- Provide privacy notice, terms, community rules, marketplace terms, affiliate terms, property listing disclaimer, refund policy, and cookie notice as applicable.
- Establish data retention, export, correction, and deletion workflows.

## 11. Design system and user experience

- Professional, modern, dark-first visual language consistent with CreatorVerse's approved identity.
- Strong typography hierarchy, clear spacing, restrained accent colours, and purposeful imagery/video.
- Shared components: navigation, cards, forms, buttons, dialogs, tabs, tables, alerts, empty states, loading states, and status badges.
- Distinct but related division accents; avoid visual fragmentation.
- Responsive breakpoints tested on narrow phones, tablets, and desktop.
- Accessible keyboard navigation, focus states, contrast, labels, and error messages.
- Prevent overlapping controls, clipped text, tiny tap targets, and horizontal scrolling.
- Never use generic emoji as a substitute for a considered icon system.
- Show clear empty/loading/error/success states; no silent failures.

## 12. Delivery roadmap and acceptance gates

### Phase 0 — Discovery and baseline (in progress)
- [ ] Reconcile repository contents, README, changelog, live deployment, and prior project history.
- [ ] Inspect full current file tree and identify actual entry points/assets/data.
- [ ] Confirm hosting provider, deployment status, and rollback method.
- [ ] Inspect connected Supabase project and table/RLS/storage/function inventory if it is the active backend.
- [ ] Review security and performance advisor findings individually.
- [ ] Test existing login, Academy, Community, admin, CMS, and payment flows.
- [ ] Produce an implementation inventory: working, partial, broken, planned.
- **Gate:** no feature rewrite until baseline and backups are documented.

### Phase 1 — Foundation and governance
- [ ] Confirm one-brand division navigation and visual system.
- [ ] Define route map, permission matrix, feature flags, error handling, and audit events.
- [ ] Restore a complete authoritative master plan (the prior root file was a placeholder).
- [ ] Establish migration, backup, test, and release procedures.
- **Gate:** approved architecture and no unresolved critical security issue.

### Phase 2 — Shared identity and admin foundation
- [ ] Reconcile existing roles and profile schema.
- [ ] Implement capability-based division access.
- [ ] Admin control centre shell and audit log.
- [ ] CMS revision/publish/restore workflow.
- [ ] Media library lifecycle and upload validation.
- **Gate:** role isolation and CMS permissions tested.

### Phase 3 — Academy completion
- [ ] Verify current course/module/lesson flows.
- [ ] Course editing, ordering, attachments, thumbnails, and publication states.
- [ ] Quizzes, assignments, grading, certificates, and instructor tools.
- [ ] Learner progress and responsive dashboard.
- **Gate:** complete student/instructor/admin test journeys.

### Phase 4 — Marketplace
- [ ] Seller onboarding and listing lifecycle.
- [ ] Search, order workflow, messaging/enquiries, delivery, reviews, disputes.
- [ ] Admin moderation and commission accounting.
- **Gate:** buyer/seller/admin journeys and ledger tests.

### Phase 5 — Affiliate Network
- [ ] Referral attribution and campaign management.
- [ ] Conversion validation, commission ledger, fraud controls, payout review.
- **Gate:** duplicate events, self-referrals, reversals, and payout calculations tested.

### Phase 6 — Realty
- [ ] Agent verification and listing management.
- [ ] Property search, enquiries, inspection requests, and moderation.
- [ ] Fraud reporting and listing expiry.
- **Gate:** mobile search and listing verification workflow tested.

### Phase 7 — Business
- [ ] Business pages/directory.
- [ ] Advertising and sponsored placements.
- [ ] Lead and campaign analytics.
- **Gate:** ad approval, disclosure, budget, and reporting tested.

### Phase 8 — Community expansion
- [ ] Verify current community functionality.
- [ ] Groups, messaging, notifications, events, and moderation improvements.
- [ ] Privacy controls, abuse reports, and block/mute tools.
- **Gate:** safety and privacy scenarios tested.

### Phase 9 — Finance and payment expansion
- [ ] Verify current manual NGN payment flow.
- [ ] Reconciliation, ledger, refunds, commissions, payouts, and reports.
- [ ] Add payment providers only after explicit approval.
- [ ] International currencies and settlement only after compliance review.
- **Gate:** financial calculations and all state transitions independently tested.

### Phase 10 — International readiness and launch
- [ ] Accessibility, performance, SEO, localisation, and timezone review.
- [ ] Legal/policy review for target markets.
- [ ] Load, security, backup/restore, and incident-response tests.
- [ ] Staged launch, monitoring, support, and rollback.
- **Gate:** release checklist signed off; no critical security or data-integrity issue.

## 13. Definition of done

A feature is not “complete” merely because a page or button exists. It is complete only when:
1. Its intended user journey works end-to-end.
2. Permissions are enforced on trusted backend boundaries.
3. Loading, empty, error, success, and edge states are handled.
4. It is responsive and keyboard-accessible.
5. Data validation and abuse cases are tested.
6. It has admin/support visibility where required.
7. It is documented and added to the changelog.
8. It has been tested in the target environment.
9. Deployment status is accurately recorded.

## 14. Immediate next actions

1. Finish Phase 0 repository and deployment inventory.
2. Reconcile current code with the live site and connected backend.
3. Confirm whether the existing Supabase project is the production backend or a development environment.
4. Review RLS advisor findings table-by-table; do not apply blanket policy changes.
5. Create a tested backup and staging strategy.
6. Select the first safe vertical slice based on actual gaps—do not begin Marketplace/Realty schema creation until identity, admin permissions, and data boundaries are clear.

---

## Decision log

| Decision | Current direction | Status |
|---|---|---|
| Brand structure | One CreatorVerse brand with six divisions | Working default; owner can revise |
| Build strategy | Incremental, preserve working features | Adopted |
| Cost | Free-first; no paid activation without approval | Adopted |
| Existing frontend | Preserve and audit static site before framework migration | Pending technical validation |
| Backend | Supabase only if confirmed as active backend | Pending technical validation |
| Currency | NGN initial context; multi-currency later | Working direction |
| Payments | Manual NGN groundwork to be audited; providers inactive until approved | Pending verification |
