# CreatorVerse AI — Whole-site product, UX, accessibility and security review

**Review date:** 11 November 2026  
**Reviewed source:** `Cletus-Tech/creatorverse-ai`, `main`  
**Live database:** Supabase project `xgdngnekihhnkzurhvpe` (read-only inspection, except no writes in this review)  
**Scope:** Repository tree, key public/auth/student/admin/course/community/payment/assessment source files, current Supabase advisor findings, selected live function definitions and execution grants.

## Executive summary

CreatorVerse already has substantial functionality: course discovery and purchase, learner dashboards, creator applications/interviews, admin-managed lessons and completion, assessments, administrator-issued certificates, notifications, community, direct messages/stories, profile pages and central brand controls. The main opportunity is not to add more features indiscriminately. It is to make the existing platform coherent, predictable, accessible, secure by default, fast on mobile networks and easier to operate.

The highest-priority work is:
1. Correct navigation and product journeys so ordinary learners are not sent into the retired admissions flow.
2. Complete a role-by-role security review of exposed RPCs, RLS, storage and payment confirmation.
3. Make checkout and enrolment a single trusted, idempotent server-side process with clear payment states.
4. Consolidate the old/new dashboard and design systems; remove dead or contradictory routes.
5. Establish accessibility, mobile performance, error handling, observability and automated regression checks.

This is a source/database review, not a completed browser-based accessibility audit or penetration test. Production pages could not be rendered in the available review environment. Findings below distinguish directly verified issues from items requiring browser or adversarial testing.

## Verified high-priority findings

### P0 — Product journey and navigation consistency
- `layout.js` still puts **“My Admission Status”** in the public account dropdown. This conflicts with the agreed model: normal learners choose a course, pay/enrol and start learning; the interview/application route is only for creator, instructor, teacher and exhibitor partners.
- The public nav and dashboard still expose legacy pathways and overlapping labels. The learner dashboard has an optional partner-application link, but the global account menu still points everyone to admission status.
- The repository contains both the current `dashboard.html` / `student.js` portal and a separate older standalone `student-dashboard.html` with a different purple visual system and inline CSS. This is a likely source of inconsistent branding and duplicated learner experiences; determine whether it is still linked or used before retiring it.
- Admin navigation has entries for features that may be only partially implemented (for example notifications marked “Soon” while a notification tool exists elsewhere). Every visible menu item should have a real destination and a consistent status.
- The admin shell's page router falls back to a generic “feature not built yet” panel for routes not explicitly handled. Audit every item in `NAV` against the actual route and capability; do not present placeholders as live controls.

### P0 — Payment and enrolment integrity
- The course page currently inserts a free-course enrolment directly from the browser with `sb.from('enrolments').insert(...)`. The database policy is intended to permit only the authenticated user's own enrolment in a published free course. This is workable, but the journey needs explicit duplicate, race, already-enrolled and failed-refresh states.
- Paid payment administration currently updates `payment_orders.status` directly from the browser when an administrator confirms or rejects an order. The database trigger then creates enrolment on confirmation. Verify the exact RLS policy and trigger conditions against forged status changes, duplicate confirmations, amount/currency/course mismatch, expired orders and repeated webhook delivery.
- Payment proof links are rendered as direct links in the admin. Confirm the receipt bucket is private and the link is a short-lived signed URL; do not rely on a public URL for financial evidence.
- Do not enable Paystack or any other gateway until server-side signature verification, idempotency, amount/currency verification, replay protection, refund/reversal handling and reconciliation are implemented and tested.

### P0 — Security advisor results requiring triage
The live Supabase Security Advisor reported:
- **6 RLS-enabled tables with no direct policies:** `academy_engagement_alert_state`, `academy_engagement_policies`, `academy_learning_checkins`, `academy_learning_sessions`, `academy_student_admin_actions`, `academy_student_interventions`. This may be deliberate if access is exclusively through guarded SECURITY DEFINER RPCs. Verify each table's intended access and confirm that no required client query silently fails; do not add broad policies just to silence the warning.
- **8 SECURITY DEFINER functions executable by anon** were reported. The inspected subset includes trigger functions (`cv_capture_content_revision`, `cv_log_division_revision`, `notify_academy_interview_status`) and safe boolean helpers (`cv_is_content_admin`, `is_admin`, `is_super_admin`, `is_enrolled`), plus the intentionally public certificate verifier (`verify_certificate`). Trigger functions should not be directly exposed as RPCs; revoke unnecessary direct execution. Keep the public certificate verifier only if public verification is a deliberate product requirement, and return only the minimum certificate fields.
- **51 SECURITY DEFINER functions executable by authenticated users** were reported. Many inspected admin functions check `auth.uid()` and `is_admin()` / `is_super_admin()` internally, so the advisor warning is not proof of a privilege bypass. Review every function body and its grants; require explicit role/ownership checks, fixed search paths, narrow grants and tests for student, creator, interviewer, admin and super-admin identities.
- Trigger functions should be treated separately from callable RPC endpoints. Do not mechanically revoke or alter functions until dependencies and policies are mapped.

### P1 — Database performance
- Supabase Performance Advisor reports **63 foreign-key constraints without covering indexes**. Prioritise high-traffic joins and filters: enrolments, course/module/lesson relationships, notifications, applications/interviews, payment orders, learning activity, submissions and message/conversation relationships. Add indexes only after checking existing indexes, query plans and write overhead.
- The advisor also reports the RLS/no-policy tables above; these are primarily access-design questions, not necessarily performance problems.
- Review large dashboard queries for unbounded profile, activity, messages and notification reads. Add pagination, server-side aggregates and sensible limits.

### P1 — Accessibility and inclusive interaction
- The source contains some good foundations (semantic headings/landmarks, labels in the registration/login forms, visible focus styling in the legacy student dashboard, live regions and reduced-motion support in some components), but this is not yet a consistent site-wide standard.
- Add a skip-to-content link, consistent focus visibility, keyboard-operable menus/dialogs, focus trapping/restoration for modals, Escape-to-close, clear accessible names for icon-only buttons, and correct `aria-expanded` / `aria-controls` state.
- Ensure every form control has a programmatic label, errors are linked with `aria-describedby`, invalid fields receive `aria-invalid`, and success/error feedback is announced without moving focus unexpectedly.
- Check all text, muted labels, status chips, focus rings and buttons against WCAG 2.2 AA contrast. Dark UI must not mean low-contrast gray-on-navy.
- Provide captions/transcripts for teaching video/audio, descriptive alt text for meaningful images, empty alt for decorative images, and non-colour status indicators.
- Respect `prefers-reduced-motion` across the full platform, including starfield, loader, hover and live-call effects. Ensure animation can be paused where needed.
- Test 200% zoom, 320px viewport, portrait/landscape, keyboard-only, screen reader, large text and reduced-motion settings.

### P1 — Mobile performance and resilience
- Several pages load Supabase JS dynamically from jsDelivr with unpkg fallback; fonts and icons/images are also third-party hosted. There are no visible integrity pins in the inspected script loading path. Pin and govern dependencies, use a single controlled SDK source, and establish a fallback strategy.
- Public pages use multiple remote Unsplash images and third-party icon assets. Optimise images, use responsive sizes/modern formats, lazy-load below the fold, set dimensions to prevent layout shifts and provide local fallbacks.
- The site should be tested on constrained Android devices and slower Nigerian mobile networks: reduce initial JavaScript, avoid loading community/chat/admin code where not needed, paginate feeds, and keep animations lightweight.
- Establish consistent loading, empty, offline, retry and error states. Avoid silent failures and avoid automatic full-page reload loops when realtime events fire.

### P1 — Account, privacy and trust
- Clarify the public profile visibility model: which profile fields, posts, follows, online presence, stories and portfolio assets are public, and how a user can hide or delete them.
- Add robust block/report/moderation flows and a documented response process. Confirm reported content and private messages are only visible to authorised moderators.
- Review age eligibility, consent, data retention, account deletion/export, privacy policy and terms against the actual product behaviour—especially private messages, uploaded media, interviews and student monitoring.
- Add rate limits / abuse controls for signup, password reset, posting, messaging, follows, reports, quiz submissions and public verification lookups.
- Add session expiry and safe redirect handling tests. Avoid exposing private user data in console logs, error messages, analytics or public RPC responses.

### P1 — Admin operations and governance
- Make the admin portal role-aware at both UI and database levels. Distinguish super-admin-only settings (roles, creator access, critical configuration) from ordinary admin tasks.
- Add audit history for high-impact actions: course publishing/unpublishing, price changes, payment confirmation/rejection, role changes, lesson completion/revocation, grades, certificate issue/revoke, content edits and moderation.
- Add confirmation/undo or review steps for destructive actions; prefer archive/soft-delete where appropriate. Ensure backups and a restore procedure exist before bulk edits.
- Every dashboard metric should define what it counts, use consistent date/time zones and show when data last refreshed.
- Replace generic errors with safe user-facing guidance and a trace/reference ID for support.

### P2 — Design system and brand coherence
- Consolidate old purple, newer navy/blue and one-off inline styles into one tokenised design system. The standalone `student-dashboard.html` is a clear legacy outlier.
- Define a consistent spacing scale, typography scale, colour tokens, border/radius/shadow rules, button/input/card states, breakpoints and icon system.
- Use the approved standalone 3D mark consistently, but do not bake wordmark/tagline into the mark. Ensure the mark remains legible at small sizes and has a simplified favicon variant.
- Improve the home page's information architecture: clear primary action for “Explore courses”, clear secondary action for “Become a creator/instructor”, explain what the platform offers, pricing, learning outcomes, support and trust.
- Keep the interface distinctive through the brand mark, visual language and learning experience—not excessive glow, animation, gradients or decorative clutter.

### P2 — Content and learning quality
- Standardise each course page: who it is for, prerequisites, outcomes, curriculum, duration, weekly effort, instructor/creator, sample lesson, price, support/refund terms and certificate conditions.
- Use consistent lesson structure: learning objectives, explanation, worked example, visual/diagram where useful, practical task, recap, resources and accessibility alternatives.
- Explain exactly how lesson completion is verified, how assignments are graded, what counts toward certification, and who issues certificates.
- Keep creator partner applications separate from ordinary course enrolment and explain the review/interview process only on the partner route.

## Important verified positives
- The public browser config contains a Supabase publishable key, not a service-role secret. Continue to keep service-role credentials out of browser code.
- `claim_certificate` currently raises an admin-issued-only error and has no anon/authenticated execute grant in the inspected live database.
- `admin_issue_certificate` and `admin_mark_lesson_completed` both check authenticated admin access in their function bodies.
- `get_quiz` omits answer keys from the learner payload. `submit_quiz` checks login and enrolment before scoring.
- The creator-only application migration and current UI direction reflect the agreed separation between normal learners and partner applicants.
- The current brand system uses one canonical SVG path and stores brand settings centrally.

## Recommended rebuild sequence

### Phase 0 — Safety baseline (first)
1. Freeze destructive schema changes; preserve all existing accounts, roles, enrolments, progress, attempts, submissions, payments and certificates.
2. Create a route/feature inventory with owner, audience, status, data dependencies and source file.
3. Capture current production screenshots and run role-based smoke tests before redesign.
4. Back up database and storage; define rollback procedure.
5. Add automated JS syntax, HTML validation, link checks, migration checks and secret scanning to CI.

### Phase 1 — Fix journeys and information architecture
1. Remove the generic admission-status link from the learner-facing global nav; replace with course dashboard/learning status.
2. Keep a separate “Become a CreatorVerse Partner” route for creator/instructor/teacher/exhibitor applications.
3. Consolidate the duplicate student portal after checking incoming links and historical use.
4. Audit every public, student, admin and interviewer route; remove dead links and mark genuinely planned features clearly.
5. Make purchase/enrolment status visible and understandable from course page through dashboard.

### Phase 2 — Security and payments
1. Build an RPC/function inventory including grants, SECURITY DEFINER, search_path, caller checks and data returned.
2. Verify all RLS policies and storage policies using least-privilege role matrices.
3. Make payment confirmation a narrowly authorised server-side operation with immutable audit records and idempotency.
4. Verify receipt upload is private and signed URLs expire.
5. Add rate limiting and abuse protections; run targeted security tests.

### Phase 3 — Accessibility and design system
1. Introduce a shared accessible shell, skip link, nav/dialog patterns and form/error components.
2. Consolidate typography, colours, spacing, responsive breakpoints and interaction states.
3. Remove legacy styling after route migration and visual comparison.
4. Run WCAG 2.2 AA checks with automated tools plus manual keyboard/screen-reader testing.

### Phase 4 — Performance and reliability
1. Measure Core Web Vitals on representative mobile pages.
2. Split code by route; optimise media and third-party dependencies.
3. Paginate feeds, messages and admin tables; cache only safe public data.
4. Add reliable retry/error/offline states and telemetry with privacy-safe event data.

### Phase 5 — Product polish and release
1. Improve course and lesson content templates.
2. Add admin audit/history, operational alerts and support tooling.
3. Test full journeys with separate accounts: guest, student, creator applicant, creator, interviewer, admin and super-admin.
4. Test payments in sandbox and verify all edge cases before real payments.
5. Release progressively; verify production aliases, logs, errors and rollback readiness.

## Acceptance criteria for “ready”
- No ordinary learner is routed into creator admission/interview workflows.
- A learner can discover a course, understand its outcomes/price, enrol or pay once, receive access only after valid confirmation and continue learning without admin intervention for routine steps.
- No learner can self-award verified lesson completion or issue/revoke certificates.
- Payment state, amount and enrolment are consistent and auditable under retries and concurrent requests.
- Every route and visible control works for its intended role; no dead links or misleading placeholders.
- Keyboard, screen reader, zoom, contrast, reduced motion and mobile checks pass WCAG 2.2 AA target.
- No unresolved high/critical security findings; all SECURITY DEFINER functions and storage buckets have documented access intent.
- Key pages remain usable on low-end Android devices and slower connections.
- Automated checks and role-based end-to-end regression tests pass on production candidate.

## Review limitations
- No authenticated browser session was available for visual inspection or real account testing.
- No external penetration test, payment gateway simulation, screen-reader audit or device lab run was performed.
- Supabase advisor findings are triage signals; a warning does not by itself prove an exploitable vulnerability.
- No application code, schema, RLS policy, user data or production configuration was changed as part of this review.
