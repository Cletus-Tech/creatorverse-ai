# CreatorVerse — Phase 0 Legacy Audit (Initial)

Date: 2026-11-11
Status: **Initial inventory completed; implementation gate remains open.**
Scope: read-only inspection of the connected GitHub repository and live Supabase project. No production data or schema was changed.

## 1. Hosting and repository reality

- Repository: `Cletus-Tech/creatorverse-ai`, default branch `main`, public, with administrator-level repository access.
- The checked-in README describes a static site in `public/`, no build step, and a GitHub Pages Actions deployment. It also describes a separate Cloudflare Pages option.
- The root `package.json` and root `vercel.json` are not present at the paths checked. The README is therefore not sufficient proof of the current production hosting configuration.
- Direct reads of several paths mentioned in earlier implementation notes (including `public/index.html` and `public/campus-life.html`) returned 404. This conflicts with the README/history and must be resolved by obtaining the actual repository tree before any source edits.
- The existing `MASTER_PROJECT_PLAN.md` and `PROJECT_CHANGELOG.md` contain extensive legacy implementation notes, including static HTML/JS page work and feature status caveats. Treat those notes as historical records, not proof that every feature is currently deployed or fully tested.
- Do not migrate, delete, rename, or overwrite the current deployment until the actual repository tree and active hosting target are confirmed.

## 2. Live Supabase inventory

Project: `xgdngnekihhnkzurhvpe`
Status: `ACTIVE_HEALTHY`
Region: `eu-west-1`
PostgreSQL: 17
Observed inventory:
- 65 tables in `public`
- 132 RLS policies
- 67 functions in `public`
- 6 Storage buckets
- 10 Auth users
- 36 recorded migrations

All 65 public tables returned by the table inventory currently report RLS enabled. This is a useful baseline, not a complete proof of safe access: policies, grants, views, triggers, functions and storage object policies still need a full review.

## 3. Existing data/features worth preserving pending validation

The database already contains meaningful live records. Examples include:
- Profiles: 10
- Courses: 9
- Modules: 22
- Lessons: 64
- Lesson resources: 63
- Enrolments: 6
- Lesson progress records: 10
- Certificates: 2
- Community posts/comments and social relationships
- Direct-message conversations/messages, stories and notifications
- Creator/instructor/teacher/exhibitor applications, interviews, reviewer invitations and audit events
- Learning activity, learner levels, live-call records and admin actions
- Site content, homepage versions and media library records

**Decision:** preserve these records. No reset or destructive schema replacement is approved. Reuse/refactor existing capabilities where their security and product behaviour meet the new blueprint; migrate only with explicit compatibility mapping and verification.

## 4. Security and performance signals requiring follow-up

The live Supabase advisor output includes:
- Multiple permissive policies for the same table/action on several tables. This can be intentional in PostgreSQL's permissive-policy model, but it increases review complexity and can create unexpected OR-combined access.
- Policy overlap reported across learning tables, profiles, homepage versions, payment orders, submissions and other resources.
- A duplicate-index finding on `community_comments`: `community_comments_post_created_idx` and `community_comments_post_idx`.
- Earlier project context records 63 foreign-key constraints without indexes; verify against the current catalog and prioritize high-traffic relations before changing anything.

Specific policy review flags:
- `profiles` has public profile SELECT and own-profile UPDATE policies. The own-profile update path must be checked against triggers/column-level grants so a user cannot self-assign privileged roles, verification badges or other protected fields.
- `payment_orders` has separate admin and user policies, including a limited owner update path. Preserve server-side payment status/amount/course entitlement guards and verify that client updates cannot approve or mutate protected fields.
- Certificate UPDATE is admin-gated in policy definitions; independently verify insert/issue paths and ensure learners cannot create or self-approve certificates.
- Creator partner applications are constrained to creator/instructor/teacher/exhibitor types in the observed insert/update policies. Keep this separate from ordinary course purchase/enrolment.
- Direct-message reads/sends are participant-bound in the inspected policies; test block enforcement, read-state updates and storage attachments separately.
- Story creation has an expiry constraint; verify the 24-hour rule, media access and cleanup process.

No security finding above is being silently changed in this audit. Each must be traced to its related trigger/function/grant and tested before remediation.

## 5. Preserve / refactor / rebuild / retire map (provisional)

| Area | Initial decision | Reason |
|---|---|---|
| Auth identities and profiles | PRESERVE + HARDEN | 10 existing accounts and shared identity are live data. Audit profile update protections and role claims. |
| Courses, modules, lessons, resources | PRESERVE + REFACTOR | Existing curriculum data is substantial; map into the new Digital Skills and Academic models without deleting legacy rows. |
| Enrolments, progress, certificates | PRESERVE + HARDEN | User learning history and certificate records must survive; enforce admin-controlled certification. |
| Creator partner applications/interviews | PRESERVE + RE-SCOPE | Keep only creator/instructor/teacher/exhibitor workflow; ordinary learners should not face admissions interviews. |
| Community, messaging, stories, notifications | PRESERVE + REFACTOR | Existing social data exists; validate end-to-end UX, realtime and moderation before reuse. |
| Homepage/CMS/media records | PRESERVE + REBUILD UI | Retain content and media references; rebuild a coherent admin-managed brand and site experience. |
| Payment settings/orders | PRESERVE + HARDEN | No payment provider migration until manual workflow and protected fields are fully verified. |
| Campus Life housing/marketplace | REBUILD BACKEND + REUSE VALID UI selectively | Current DB inventory does not yet establish a complete accommodation/agent/roommate marketplace backend. |
| Emergency SOS | RETIRE FROM CREATORVERSE SCOPE | Explicitly excluded by product direction. |
| Static website shell | REBUILD AFTER TREE/DEPLOYMENT CONFIRMATION | Current source tree and active hosting target are not yet verified. |
| Flutter mobile app | BUILD NEW | No mobile app source has been established by this inventory. |

## 6. Required next audit actions

1. Resolve the GitHub tree/path mismatch and identify the exact current production entry point, asset layout, deployment workflow, and Vercel/Pages/Cloudflare linkage.
2. Inspect profile-role protection triggers, all SECURITY DEFINER functions, exposed views, grants, storage buckets/policies and auth settings.
3. Export a schema-only snapshot and create a table-by-table data ownership/compatibility map before writing migrations.
4. Test existing website routes and critical workflows on desktop/mobile; distinguish broken, incomplete, legacy and working features.
5. Define a safe migration sequence with backups, additive schema changes, compatibility views/RPCs where useful, and rollback checkpoints.
6. Only after the above, begin the coordinated website and Flutter app foundations against the existing shared backend.

## 7. Change boundary

This audit was read-only. No SQL DDL/DML, account changes, storage mutations, source-code edits, hosting changes, or deployments were performed.

## 8. Follow-up source and database inspection (2026-11-11)

### Repository path mismatch resolved

The earlier 404s were caused by checking a stale `public/` path. The current branch has its static site files at the repository root. The root `index.html` is the current three-division landing hub and links to `digital-skills.html`, `academic.html` and `campus-life.html`. Shared CSS/JS files are also at the root (including `tokens.css`, `components.css`, `pages.css`, `responsive.css`, `division-hub.css`, `layout.js`, `nav.js`, `config.js`, `auth.js` and `site.js`).

The README is stale: it still says the deployable website is in `public/` and points to a GitHub Pages workflow that is not present at the checked path. The current homepage contains a canonical URL for `https://creatorverse-ai.vercel.app/`, which is evidence of intended Vercel production URL, but not sufficient by itself to prove the active Vercel project/domain linkage. There is no root `package.json` or `vercel.json` at the paths checked. Therefore:
- Current codebase is a root-level static HTML/CSS/JS site, not a Next.js application.
- Existing pages can be preserved as the legacy web client during the transition.
- The hosting target and production deployment settings must still be confirmed in Vercel before any cutover.
- The proposed Next.js/Flutter monorepo remains a target architecture, not the existing application.

### Database function, trigger, view and Storage review

- No public `SECURITY DEFINER` function was found with a missing function-level `search_path` setting in the inspected catalog query.
- A number of public `SECURITY DEFINER` functions intentionally pin `search_path` to `pg_catalog, public` (some also include `auth`). Their execute grants vary: many admin/user RPCs are granted to authenticated users, while internal trigger functions are service-role/postgres only. This is not automatically a vulnerability, but each client-callable privileged RPC needs a body-level authorization and ownership review. Supabase recommends preferring invoker functions and tightly restricting definer execute privileges.
- The profile table has three BEFORE UPDATE triggers protecting role and verified-badge changes (`guard_verified_badge_change`, `profiles_guard_role`, `protect_role`). This is defence in depth, but overlapping guards need to be checked for ordering and compatibility with legitimate super-admin updates.
- Both public views inspected (`academy_learner_activity_summary`, `community_profiles`) have `security_invoker=true`; grants show no anonymous access to the learner summary and public/authenticated SELECT to the community profile view. Underlying profile columns and public exposure still require data-minimization review.
- Six Storage buckets were found: private `academy-interviews`, `cv-chat-files`, `submissions`; public `community-media`, `creatorverse-media`, `profile-avatars`. Policies restrict interview files to assigned reviewers/admins and uploaders, chat attachments to participants, submissions to owner/admin reads, and avatars/community media to per-user paths. `creatorverse-media` allows admin uploads/updates/deletes and admin listing; public bucket status means object URL access is public, so only intended public assets should be stored there.
- Storage object metadata must be managed through the Storage API, not direct SQL writes.

### Priority security follow-ups

1. Inspect and test every authenticated-callable SECURITY DEFINER RPC, especially admin, admission, certificate, quiz, live-call, payment and lesson-progress functions. Confirm the caller role is checked inside the function, not merely assumed from its name or UI route.
2. Review whether `cv_is_content_admin`, `is_admin`, `is_super_admin`, `is_enrolled` and `verify_certificate` genuinely need anonymous EXECUTE; keep only intended public read/verification use cases.
3. Verify the three profile protection triggers permit authorised admin changes and reject all self-escalation attempts; add tests for ordinary user, admin and super_admin paths.
4. Review public bucket contents and MIME restrictions, especially `creatorverse-media` (currently no MIME allowlist) and `community-media`.
5. Add automated database tests for allow/deny behaviour per operation and role before changing policies. Follow Supabase's current guidance for table grants + RLS tests and function privilege review.

This follow-up remains read-only. No SQL DDL/DML or source/hosting changes were made.


### Vercel production target and privileged workflow review (2026-11-11)

Vercel was inspected read-only for project `creatorverse-ai`:
- The linked project is `prj_3thYvAZidWK9E1mssa2nw4UDZxmN`, connected to `Cletus-Tech/creatorverse-ai` and the `main` branch.
- The latest listed production deployment is READY and was created from commit `a7bb29d85795b2787fffc411b4a56b0a2f849fce` (audit documentation only).
- The project has one verified production domain: `creatorverse-ai.vercel.app`. Recent main-branch commits are generating production deployments, so Git integration is active.
- Vercel reports `framework: null`; repository inspection found no root `package.json` or `vercel.json`. This is consistent with the current root-level static site, but build/output settings and root directory still need a settings-level confirmation before migration.
- SSO protection is enabled for deployments except custom domains. The verified `creatorverse-ai.vercel.app` domain is the public production entry; generated deployment URLs may be SSO-protected. No domain or protection setting was changed.

Targeted SECURITY DEFINER function-body review:
- `is_admin()` and `is_super_admin()` derive privileges from the signed-in user's profile role. `cv_is_content_admin()` similarly checks authenticated profile roles.
- `admin_issue_certificate()` checks administrator authorization, enrolment, lesson completion, quiz passes and graded assignments before issuing. `claim_certificate()` unconditionally rejects learner self-claim, matching the admin-controlled certification requirement.
- `admin_mark_lesson_completed()` is admin-gated and checks that the learner is enrolled. This is a controlled administrative correction path, not a learner self-completion route.
- `cv_payment_order_guard()` sets amount/currency/status/reference/expiry from server-side course and payment settings on insert; protects core payment fields on learner updates; and restricts admin confirmation to active payment states. Keep this trigger intact unless a full payment regression suite proves a replacement safe.
- `accept_academy_admission_offer()` requires the authenticated offer owner, checks expiry/status, and activates free enrolment or requires payment for paid courses. It cancels remaining interview/live-call workflow after acceptance. Product direction still requires this admissions path to be limited to creator/instructor/teacher/exhibitor applications, not ordinary course buyers; verify the calling UI and application creation constraints end-to-end.
- `admin_grant_creator_access()` requires super-admin authorization, a creator/instructor/teacher/exhibitor application, approved status and a completed scored interview before assigning creator role.
- `admin_broadcast_notification()` requires admin authorization, validates content/audience and rejects external or script-like links.
- `submit_quiz()` requires authentication, a published quiz and active enrolment; computes scores server-side from stored correct answers.
- `submit_academy_interview_review()` requires admin or the assigned reviewer, validates interview state and score range before saving assessment.
- `verify_certificate()` is a public-style lookup that returns certificate identity/course/issue/revocation fields by certificate number. Confirm intended anonymous EXECUTE and ensure clients treat revoked certificates as invalid; do not expose unrelated student profile data.

Profile guard trigger review:
- The profile table has BEFORE UPDATE triggers `guard_verified_badge_change`, `profiles_guard_role` and `protect_role`.
- The role guards overlap: one requires super-admin for role changes; the second additionally blocks a super-admin from changing their own role. This layering prevents ordinary self-escalation and super-admin self-demotion through the normal authenticated path, but ordering/compatibility should be covered by explicit tests.
- Badge changes require super-admin when an authenticated user context exists. Test privileged service-side operations separately because service contexts may have a null `auth.uid()`.

No SQL, data, source code, Vercel settings or deployment actions were changed in this inspection. Remaining work: verify exact Vercel build/root-directory settings, test grants/RLS and the full role matrix, and perform browser/mobile workflow QA before migration or visual cutover.


### Follow-up: deployment readiness and Brand Studio hardening (2026-11-11)

- Verified the newest production deployment for commit `10791dd4561ca050a43e6f5b01c03327f21bbb8d` reached READY and carries the production alias `creatorverse-ai.vercel.app`.
- Inspected the existing Brand & Logo Studio. It already stores central brand settings in `site_content` and uploads artwork to the public `creatorverse-media` bucket.
- Hardened the brand upload UI: custom uploads now accept PNG/JPEG/WebP only, require matching file extension and browser MIME type, and are capped at 5 MB. The built-in local SVG emblem remains the default; custom SVG uploads are disallowed because the destination bucket is public and arbitrary SVG content should not be accepted without sanitization.
- Brand image URL settings now reject unsafe schemes and allow local asset paths or HTTPS URLs (same-origin HTTP is permitted for local development). Primary logo is required before publishing settings.
- Updated the admin page title to the public CreatorVerse brand.
- Compiled `brand-admin.js` with a JavaScript syntax check after the changes. This is a source-level check only; a live upload, storage-policy test and visual browser QA remain outstanding.

Security boundary: these changes harden the admin-side upload form but do not replace server-side Storage bucket MIME/size restrictions. Because `creatorverse-media` is public, the bucket itself still needs an independent policy/configuration review and public-object audit. Do not upload private material there.


### Read-only authorization smoke checks (2026-11-11)

- Re-checked EXECUTE privileges for selected privileged RPCs: admin certificate issuance, creator access, notification broadcast, administrative lesson completion and interview review are not executable by `anon`, but are executable by `authenticated` and rely on internal authorization checks. `claim_certificate` is not executable by either `anon` or `authenticated` in the inspected ACL. Public helper functions `is_admin`, `is_super_admin` and `cv_is_content_admin` are executable by anon/authenticated; their inspected bodies derive privilege from `auth.uid()` and profile roles.
- Executed read-only smoke checks with an empty JWT subject and an unknown UUID subject. All three role helpers returned false in both scenarios; no user/profile data was returned.
- This is not a complete role-matrix test: real learner, creator, admin and super-admin identities still need controlled authenticated-session tests, and all direct table/storage paths remain to be tested. No grants or functions were changed.
