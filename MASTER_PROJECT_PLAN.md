

## 2026-11-06 — CreatorVerse AI assistant workspace redesign

Status: **Implemented on `main`; deployment and browser QA pending.**

- Rebuilt the AI Assistant page as a focused, responsive workspace with a refined mode sidebar, clear conversation header, prompt starter cards and a more usable message composer.
- Retained CreatorVerse's existing dark navy theme, enhancing it with richer blue, violet, cyan and magenta accents, image-led prompt cards, readable typography and responsive mobile layouts.
- Preserved the existing General and CreatorVerse specialist modes, authenticated access, Supabase conversation/message persistence, and the existing `creatorverse-assistant` Edge Function request contract.
- Improved new-chat and mode-switch welcome states, prompt-card interactions, textarea auto-sizing and response/error handling.
- No AI provider, model, Edge Function, database schema, RLS policy, authentication or billing configuration was changed.
- Production verification must confirm the page renders correctly and both assistant modes still return responses and persist conversations.



## 2026-11-06 — Academy course discovery visual refresh

Status: **Implemented on `main`; production deployment and visual QA pending.**

- Refined the public Academy course catalogue at `courses.html` with a more expressive image-led course-card system, richer multi-colour accents, featured labels, clearer level/category metadata, stronger visual hierarchy and improved hover/focus treatment.
- Preserved the existing course data source, category filtering, search, featured sorting, course links, price display, responsive layout and admin-managed course thumbnails.
- Continued to use subject-matched fallback cover imagery when a course has no uploaded thumbnail; admin-provided thumbnails remain the first choice.
- Scoped the new visual styling to the course catalogue so the AI Assistant theme and unrelated pages are not changed.


## 2026-11-06 — CreatorVerse Connect: direct messaging and stories

Status: **Initial implementation committed to `main`; production deployment and two-account live QA pending.**

- Added a dedicated `messages.html` experience, linked from the creator account menu and mobile navigation.
- Added authenticated one-to-one conversations and persistent direct messages, with Supabase Realtime Postgres Changes for incoming messages and conversation activity ordering.
- Added live online presence using an authenticated private Realtime Presence channel; presence metadata is limited to the user's ID, display name and avatar.
- Added 24-hour text and image stories, active-story expiry filtering, story viewing and view counts. Image stories use the existing `community-media` bucket and its per-user upload path rules; image uploads are limited to supported image formats and 12 MB.
- Added RLS-protected tables: `cv_conversations`, `cv_direct_messages`, `cv_stories`, and `cv_story_views`. Conversation and message access is restricted to the two participants; message creation checks existing community blocks.
- Added the message activity trigger in the non-exposed `app_private` schema; it is not executable by `anon` or `authenticated` through the Data API.
- Existing community posts, profiles, AI Assistant and course flows were left intact.
- Current scope is one-to-one text chat, online status, and text/image stories. Attachments inside chats, voice/video calls, scheduled one-to-one classes, screen sharing, group chats, push notifications, read receipts and typing indicators are not yet implemented.
- Next communication phase: implement call invitations/signaling and one-to-one WebRTC sessions with a TURN relay for reliable cross-network connections; add scheduled private class rooms, class links, availability and optional screen sharing. Production video calling needs TURN infrastructure or a managed provider; a browser-only STUN demo is not sufficient for dependable real-world calls.
- Stories disappear from the active feed after 24 hours; expired database rows/media are not yet automatically purged.
- Verification still required: sign in as two different accounts, create a conversation, exchange messages in both directions, confirm online/offline presence, post/view stories, confirm expiry behavior and verify blocked-user restrictions.


## 2026-11-06 — Dashboard repair and cross-platform audit findings

- Dashboard must retain the CreatorVerse dark navy theme. Do not apply the Academy's light catalogue palette to the student portal.
- Mobile dashboard acceptance criteria: content spans the viewport without horizontal clipping; the welcome card and its text wrap within the screen; stats/cards collapse cleanly; no blank oversized left area.
- Messages & Stories must be directly discoverable from the mobile persistent bottom navigation as well as account dropdown and hamburger navigation.
- Security hardening applied: SECURITY INVOKER on `community_profiles`, fixed search_path on `block_role_change()`, and API EXECUTE revoked from trigger-only functions.
- Remaining audit items: enable leaked-password protection in Supabase Auth settings; review public/authenticated SECURITY DEFINER RPC grants by actual caller requirements; resolve foreign-key index and RLS performance advisories in controlled batches; inspect duplicate permissive policies and duplicate index; verify all major user journeys with two test accounts.


## 2026-11-06 — CreatorVerse Connect reliability and moderation

- Connect messaging routes must be included in the shared auth bootstrap; every protected route must load the Supabase SDK even when no previous local session key exists, then redirect unauthenticated users to login.
- Connect page must initialize exactly once, render newest messages first, prevent duplicate Realtime/render inserts, report failures clearly and remain usable on narrow mobile screens.
- Add user reporting for stories and messages. Admin moderation must be report-based: admins may review user-submitted reports and remove stories, but must not have unrestricted access to private direct-message inboxes.
- Admin moderation route: `connect-admin.html`; link from main admin navigation and Connect page for admin/super_admin roles.
- RLS table: `cv_content_reports`; users can submit reports, admins can review/update them. Story deletion is allowed for admins.
- Release QA: two separate accounts on separate sessions; test discover creator → create conversation → send/receive both directions → online/offline → story text/photo upload → story view count → report submission → admin review/status update/story removal → sign-out/unauthenticated redirect.
- Voice/video calls, group chat, attachments, typing/read receipts and scheduled one-to-one classrooms remain separate phases and must not be represented as already available.


## 2026-11-06 — CreatorVerse Connect phase 2

- Private chat attachments use a dedicated private Storage bucket `cv-chat-files`; images/PDF/plain text, 15 MB max, participant-scoped reads, user-scoped uploads and signed URLs.
- Message read receipts use a recipient-only update of `read_at`; grant authenticated users column-level UPDATE on `read_at` only. Do not grant broad message UPDATE.
- Typing indicators use private Realtime Broadcast on `cv:dm:<conversation_uuid>`, with realtime.messages SELECT/INSERT policies checking conversation membership.
- Mobile composer includes attachment control, responsive typing status, attachment label and read state.
- Acceptance test: two distinct accounts, both directions of chat, typing in one account, recipient opens chat and sender sees Seen, upload/download supported attachment, verify unrelated user cannot read signed attachment or subscribe to private conversation channel.

- Story feed is newest-first; owners can delete their own stories and associated image from the community-media bucket. Direct Messages is exposed in desktop primary navigation, mobile navigation and the account menu; Connect Moderation is available from the main admin sidebar.


## 2026-11-06 — CreatorVerse AI intelligence rebuild
- Replaced keyword-only answer composition with a real language-model integration through the authenticated Supabase Edge Function.
- Combines conversation history, mode-specific instructions and relevant published CreatorVerse knowledge before calling an OpenAI-compatible chat-completions provider.
- Server-side secrets only: AI_API_KEY (or OPENAI_API_KEY), optional AI_BASE_URL and AI_MODEL. Default model gpt-5.4-mini.
- If no key is configured, return a clear AI_PROVIDER_NOT_CONFIGURED error; never disguise keyword retrieval as model generation.
- Frontend sends up to 16 recent turns, keeps per-chat context, uses task-specific suggestion prompts and saves model responses.


## CreatorVerse AI — provider defaults
- Free-first default provider: Google Gemini OpenAI-compatible endpoint `https://generativelanguage.googleapis.com/v1beta/openai`, model `gemini-3.6-flash`.
- Store the Gemini API key as Supabase Edge Function secret `AI_API_KEY`. Never place it in frontend config or GitHub.
- Optional overrides: `AI_BASE_URL`, `AI_MODEL`; an OpenAI-compatible provider can be configured without changing client code.
- Free-tier usage and quotas are controlled by the provider and may change; monitor provider usage and never promise unlimited free inference.


## 2026-11-06 — Academy curriculum and resource population

Status: **Seeded in Supabase; admin-managed; production page verification pending.**

- Published seven structured Academy courses: YouTube Automation, AI Content Creation, TikTok Growth & Creator Monetisation, Prompt Engineering, AI Graphic Design & Visual Branding, Digital Business, and Algorithm Analysis & Niche Research.
- Each new course includes course overview, level, estimated duration, requirements, learning outcomes, three sequenced modules, nine lessons, practical workshops/assignments, quality checks and one official further-learning resource per lesson.
- Seeded 21 modules, 63 lessons and 63 resource links. All seven courses are published and free (₦0); the existing 3D Animation course was preserved.
- Resources point to official platform/help/learning destinations rather than invented downloads. Platform monetisation and recommendation policies are explicitly treated as changeable and must be checked against current official guidance.
- Existing course-admin.js controls remain the management surface: admins/super_admins can edit course metadata and flyer, publish/unpublish, rename/reorder/delete modules, edit/reorder/delete lessons, update lesson text/video, and add/remove/edit downloadable or external resources. No course content was hardcoded into the frontend.
- Admin management is available through the existing Admin Portal → Courses panel. Existing course access/enrolment rules remain in force.
- QA verified database counts per new course (3 modules, 9 lessons, 9 resources) and published status. Browser QA of student-facing catalogue, lesson rendering and admin edits remains to be completed.


## 2026-11-06 — Universal page loading gate

- Added a shared loading gate in `layout.js`, so every page using the common site layout displays a full-viewport branded loading screen while its initial page content is being prepared.
- The gate overlays the page during rendering, preventing the footer or page shell from flashing before the main content is ready.
- Reuses the existing homepage loader and applies a consistent fade-out; other pages receive the shared CreatorVerse mark, progress line and status caption.
- Gate waits for the browser load event and stable, non-placeholder main content, with a 9-second safety timeout to prevent a permanently stuck overlay. It also handles browser back/forward cache restores.
- Existing page-specific loaders remain intact and can continue handling later data refreshes; the shared gate addresses the initial page-load flash.
- Scope: pages that include `layout.js`. Standalone pages without the shared layout require explicit integration if any exist.
- QA: source-level inspection only. Production deployment and device-by-device visual verification pending.


## 2026-11-06 — Academy curriculum structure and admin controls (expanded)

- Extended the course model with editable programme length in months and expected study hours per week.
- Extended modules with stage number, stage duration and stage description; extended lessons with chapter number, estimated minutes and topic outline.
- Reworked the seven seeded Academy programmes into ordered stages and topic-specific chapter titles: YouTube Automation (4 months, 6 hours/week); AI Content Creation (3 months, 5 hours/week); TikTok Growth & Monetisation (3 months, 5 hours/week); Prompt Engineering (2 months, 5 hours/week); AI Graphic Design (3 months, 5 hours/week); Digital Business (3 months, 5 hours/week); Algorithm & Niche Research (2 months, 5 hours/week).
- Each programme contains 3 stages and 9 sequenced chapters, with chapter timings, teaching content, professional workflow, practical workshop, common mistakes, assignment and self-assessment. The 63 chapters total approximately 3,085 minutes of lesson time, excluding independent project work.
- Student course pages now display stage names, stage schedule, stage description, chapter count and estimated chapter time. Lesson view displays chapter number, estimated minutes and topic outline.
- Admin Portal → Courses now exposes programme months, weekly study hours, stage timing and description, chapter duration and topic outline, alongside existing editable teaching content/video/resources. Reordering stages updates stage numbering; new chapters receive sequence numbers and default timings.
- QA: Supabase schema and curriculum counts verified; `course-admin.js` and `lms.js` JavaScript syntax checks passed. Full browser/device and enrolment/progress flow testing remains outstanding.


## Social verification tick and compact assistant (2026-11-07)
- Verification is displayed as a small blue social-platform-style tick immediately beside the verified person's name; no "Verified", "Gold Verified" or tier wording is displayed publicly.
- Admin Portal → Students uses a simple No tick / Blue tick control. Legacy non-empty badge values are normalized visually to the same blue tick.
- The tick appears beside names on public profiles, creator discovery, community posts and comments, Connect conversations/search/stories, and the student/admin identity views.
- Replaced the page-loader text-stability heuristic with a shared network-idle gate so the footer and page shell remain hidden until initial data requests settle; the loader has a bounded safety timeout.


## 2026-11-07 — Platform identity and consistency work

- The platform owner is the single account ID `07760888-cd28-47ab-82de-e1f3757a8e2d` (the CreatorVerse owner account), distinct from ordinary administrators and other super admins.
- Owner identity uses a dedicated gold verification shield and gold name accent wherever shared identity components render; ordinary verified accounts retain the blue social tick. No public tier wording is added beside names.
- Shared account navigation now uses the profile record for the signed-in display name and avatar, with auth metadata as fallback. Student dashboard identity also hydrates from `profiles`, preventing stale auth metadata from overriding the latest profile picture.
- The floating assistant receives a self-contained responsive style sheet so its bot launcher and panel remain visible; the greeting dissolves after six seconds and also dismisses immediately on tap. The launcher remains draggable and its position persists per browser.
- Follow-on platform-wide audit remains required: standardize every profile/avatar read on the canonical `profiles` record, verify all cross-page action destinations and repair dead/placeholder controls, and test the owner identity and assistant on desktop/mobile.


## 2026-11-07 — Messaging badges and site notification centre

- Added a persistent `cv_notifications` inbox with per-user RLS, unread state and Realtime publication support.
- New direct messages, new followers, post likes and post comments create recipient notifications through private database triggers; self-actions are excluded.
- Added a standard outline-SVG bell control in the right-side account/navigation area, separate from Home/Divisions/Explore navigation.
- Added exact unread direct-message counts to desktop Messages and mobile bottom navigation, refreshing from the canonical conversation/message tables via Realtime and a 30-second fallback.
- Added dropdown preview, mark-all-read action and full Notifications page. Additional event types can reuse this notification table.
- Two-account live QA remains required for incoming messages, unread count and read-state verification.


## 2026-11-07 — Instagram and Threads social access

Status: **Implemented on `main`; production deployment and browser QA pending.**

- Added the official Cletus Tech Instagram profile (`https://www.instagram.com/cletus_tech/`) and Threads profile (`https://www.threads.com/@cletustech_ai`) to the global CreatorVerse footer social links.
- Added Instagram and Threads to the Founder Profile social-link editor in the admin portal.
- Connected footer social links to the admin-managed `founder` record in `site_content`, so non-empty changes made in the admin portal override the footer defaults on public pages.
- Kept existing Facebook, WhatsApp, TikTok and YouTube defaults intact when their optional admin fields are blank.
- Instagram and Threads open in a new tab with accessible labels; existing social channels remain available.
- Production verification should confirm the footer on desktop/mobile and test changing a social URL in Admin → Founder Profile, saving, and refreshing a public page.

- Follow-up hardening: added a small global `social-links.js` loader through `layout.js`, so admin-managed founder social URLs hydrate the footer on **every page**, not only pages that load the homepage/about content script. Blank admin fields preserve the existing default social URLs.


## 2026-11-07 — Founder social row and contact email

- Expanded the homepage founder portrait's social row to include Facebook, YouTube, TikTok, WhatsApp Channel, Instagram and Threads, positioned directly beneath the founder image.
- Added the public contact email `cletustech25@gmail.com` beneath the homepage founder social icons and in the global footer.
- Added the contact email and WhatsApp URL field to Admin Portal → Founder Profile; non-empty admin-managed social URLs and email hydrate the homepage/footer while preserving public defaults when fields are blank.
- Email links use `mailto:`. Visual desktop/mobile verification remains pending.


## 2026-11-07 — Homepage founder contact correction and native live classrooms

- Corrected the homepage founder contact action: remove the visible email-address text and show a compact Email button that opens the visitor's mail app using the founder email configured in the Founder Profile (fallback: cletustech25@gmail.com).
- Restore the founder social links to a single compact horizontal icon row beneath the founder portrait. Preserve the existing social profiles and their order; do not add a card, oval, vertical icon stack or redesign the founder section.
- Corrected the global footer contact action to a button labelled Email us, opening mailto:cletustech25@gmail.com; do not print the raw email address as the button label.
- Native CreatorVerse live communication is distinct from Zoom: build in-app one-to-one audio/video calls and temporary group live-class rooms. Hosts create a room, set its title and optional schedule, generate a shareable CreatorVerse join link, invite selected users/groups, and start/end the session. Students join within CreatorVerse without Zoom or an external meeting account.
- Live room controls: camera/microphone permissions, mute/unmute, camera on/off, participant list, host moderation (mute/remove/close room), join/leave notifications, and class/session history. Responsive mobile-first interface.
- Architecture: WebRTC media; authenticated room membership and short-lived join tokens; Supabase Realtime for room signaling/presence and persistent class metadata. Use a TURN relay for NAT traversal. For multi-person classes, use an SFU/media server (e.g. LiveKit) rather than a browser mesh that becomes unreliable as participants increase. Do not claim production-ready calling until TURN/SFU infrastructure, secrets, access controls and multi-device testing are configured.
- Keep direct messaging and stories intact. Link call actions from existing CreatorVerse Connect conversations; expose group classrooms through a dedicated Live Classes area and role-appropriate create controls.
- Current commit changes are source updates only. Production deployment and visual QA must be confirmed separately; test founder icon row and Email mailto action on phone and desktop, plus footer button and dynamic admin-managed email.


## 2026-11-07 — Academy and ecosystem image-led redesign

- Academy catalogue and course detail pages receive a polished, colourful, responsive visual refresh while preserving search, category filters, published-course loading, featured ordering, pricing, enrolment, progress, curriculum and assessment flows.
- Every published course has its own distinct topic-specific cover image stored in the existing admin-managed `courses.thumbnail_url` field: YouTube Automation, AI Content Creation, TikTok Growth & Monetisation, Prompt Engineering, AI Graphic Design, Digital Business, Algorithm & Niche Research, and 3D Animation.
- Every Academy learning category receives a corresponding relevant image in `categories.image_url`, so the Learn discovery tiles and category detail pages are image-led as well.
- Course detail pages reuse the matching course cover; fallback cover selection is keyed by course slug rather than broad keyword matching, preventing unrelated courses from sharing a generic image.
- Rebuilt the six-division page as an image-led ecosystem showcase. Academy, Community, Marketplace, Affiliate, Realty and Business each have a distinct visual, descriptive copy, feature list, status and existing destination/availability behavior. Affiliate highlights referral links, campaign tracking, conversions and commission statements.
- No course, module, lesson, enrolment, pricing, authentication or payment records were changed. Course images remain editable through the existing Admin Portal → Courses controls; category images are stored in the existing categories table.
- QA: database image URLs written and verified for all seven learning categories and all eight course records; browser rendering must be checked before production release. Source-level syntax and responsive visual QA required on the preview.


## 2026-11-07 — Academy admissions, placement, examinations and certification architecture

Status: **Architecture specification drafted on `education-build`; implementation and QA pending. No production database change or deployment.**

- Added `ACADEMY_ADMISSIONS_PLACEMENT_ASSESSMENT_SPEC.md` as the governing design for application-based admissions, five-level placement, diagnostics, recorded/live interviews, secure CBT, practical grading, progression and admin-issued certificates.
- Application submission never creates enrolment; free courses require admission approval, paid courses require admission approval plus verified payment.
- Placement levels are Beginner, Foundation, Intermediate, Advanced and Professional. A learner's selection is advisory; the academy assigns the final level from course-specific evidence.
- Recorded interviews require explicit camera/microphone permission, visible recording controls, preview/rerecord, consent records, private storage, signed playback access, retention and an alternative assessment path.
- Academic completion, exam scoring and certificate issuance must be server-authoritative; direct learner writes and self-claim certificate issuance are prohibited.
- Preserve all existing enrolments, lesson progress, quiz attempts, submissions and certificates during any later additive migration.
- Next: complete read-only schema/RLS/function/storage/data audit, then prepare a non-destructive migration and implementation plan. Do not apply to production or deploy until explicit release approval.


## 2026-11-07 — Verified current-state audit and implementation priorities

Status: **Read-only audit complete on `education-build`; remediation pending.**

- See `ACADEMY_CURRENT_STATE_AUDIT.md` for the verified current frontend/database inventory and security findings.
- Current admin portal already provides course, module/lesson, quiz/assignment, submission grading and certificate panels, but has no complete Admissions & Placement workspace.
- Critical gaps: direct learner self-enrolment for free courses, learner-controlled lesson-progress insert/delete, no server-issued exam session with timer/attempt limits, and a learner-callable certificate-claim RPC.
- Recorded admissions media must be isolated in a dedicated private storage bucket; current public media buckets are not suitable.
- Preserve all registered accounts, profiles, roles and existing academic records. Implement additive schema and audited replacement workflows; do not clear historical records.
- Continue implementation on the existing `education-build` branch and connected project only after reviewing each migration. Do not create another Supabase branch, merge to `main`, or deploy before owner approval.


## 2026-11-07 — Admissions & Placement foundation implementation

- Implementation started on the existing `education-build` branch and existing Supabase project; no additional branch/project was created.
- Added a compatibility-first, additive migration draft for Academy applications, status history, diagnostics, interview metadata, placement decisions and admin audit records. The draft preserves existing authentication and academic data.
- Added the first responsive Admissions & Placement admin workspace and wired it into the existing admin shell. Admins can search/filter applications, inspect submitted profile/evidence fields and record a status/level review with rationale and audit history.
- Admission decisions do not automatically create enrolments. A later trusted fulfilment workflow must verify free-course approval or paid-course approval plus confirmed payment before access is granted.
- The migration is not yet applied. Private interview bucket object policies and secure signed-URL handling are deliberately pending; the private bucket alone is not a complete upload/playback workflow.
- Next: build the learner application and course-specific diagnostic flow, then secure interview handling and server-authoritative admission/payment fulfilment. Continue preserving all existing accounts, roles and academic records. No merge/deployment until release approval.


### Learner admissions application flow — implementation added

- New course-specific learner application page with account email binding, personal/background details, proposed level, portfolio, goals and consent capture.
- Published diagnostic questions render dynamically by course and support text, short-text, URL and single-choice responses.
- Submission creates/updates a draft, stores diagnostic responses, changes the application to submitted and writes an application event/reference number.
- Unenrolled course CTAs now direct learners to apply instead of self-enrolling or entering payment checkout. Existing enrolled learners retain their continue-learning route.
- Admin-only reviewer notes and sensitive interview/diagnostic review fields are separated from applicant-readable data in the migration draft.
- Still pending: run the migration only after full review, secure transactional admission/payment fulfilment, interview consent/upload/signed playback, diagnostic scoring UI, and end-to-end RLS tests. No live database writes or deployment occurred.


### Course-specific diagnostic authoring

- Admissions admin now includes a course-specific question bank with question editing, response-type configuration, target level, required/active controls and publish/unpublish actions.
- Learner application forms dynamically render published diagnostic prompts and save applicant responses. Diagnostic grading is separated into an admin-only review table to prevent staff scores and feedback from leaking through learner response reads.
- JavaScript parse checks passed for the four changed application/admin/LMS scripts. Live database integration, RLS, browser and responsive QA remain pending; the migration is still unapplied.


## 2026-11-07 — Academy interview planning and evaluation workspace

- Added an interview management panel to each application review record.
- Administrators can create interview records for live, recorded-video, recorded-audio or alternative assessment; set workflow status; schedule start/end; record an IANA timezone; specify a meeting provider and reference; assign a reviewer; and capture a private score and reviewer evaluation.
- Added validation for date/time order, scheduled-session start time and non-negative scores.
- Interview records, reviewer notes, meeting references and evaluation remain in the admin-only `academy_interviews` table under the draft migration's administrator-only RLS policy. Interview metadata is not exposed to applicants in this phase.
- Added an application event and audit-log record when an interview plan is created. The UI explicitly states that recording upload is not enabled and that no recording is shared.
- Added responsive styling for the interview planning panel.
- JavaScript syntax validation passed for `admissions-admin.js`. This is source-level validation only; browser interaction, database integration and RLS tests remain pending because the admissions migration has not been applied.
- No database migration was applied, no existing student data was changed, and no production deployment or merge to `main` occurred.

**Next:** applicant-visible interview invitations and application tracking, consent-led recording capture with private signed access and retention, diagnostic response review/scoring, then secure admission/payment fulfilment.


## 2026-11-07 — Admission acceptance windows, mandatory interview appointments and learning progression

- Added an additive lifecycle migration draft: `supabase/migrations/202611070003_academy_admission_lifecycle_learning_progress.sql`. It adds time-limited admission offers, learner-visible interview invitations, append-only lesson activity events, admin-configurable level rules, learner level snapshots and level-unlock approval requests.
- Admin admissions review now includes an admission-offer composer with a required future acceptance deadline, stored with the administrator's timezone. Issuing an offer records the deadline, changes the application to `approved_pending_payment`, and appends an application event and audit entry. The offer does not itself grant course access.
- Scheduled interviews now require a start time, end time and timezone. When an invitation is published, the learner receives an appointment with exact start/end times, attendance instructions and a response window. Learners can confirm attendance or request rescheduling before the start; admins can mark the appointment attended, missed or cancelled.
- Added a learner-facing `academy-status.html` timeline for admission offers, acceptance deadlines, interview appointments, attendance responses and enrolled-course progress. Linked it from the student dashboard.
- Added the Admin > Learning Progress workspace. It reports completion percentage, completed/total lessons, last activity, inactivity bands and weekly lesson pace. Administrators can set a learner's current level with an audited reason.
- Added configurable progression thresholds per course and level: lesson completion percentage, optional quiz average, submitted assignments, active study days, publication state and whether administrator approval is required. When a learner completes a lesson, the app requests a server-side evaluation. Automatic rules can unlock levels; approval-required rules enter an administrator review queue. Learner status page also refreshes the evaluation.
- Added restricted server-side RPCs for accepting a learner's own offer before its deadline, responding to their own future interview invitation, and recalculating their own enrolled-course level. Course access remains separate and requires the verified payment/free-course fulfilment workflow.
- Added a database trigger draft to record lesson completion/reopening activity and support monitoring without trusting browser-submitted timestamps.
- JavaScript parse checks are required for all changed scripts; no browser interaction, SQL execution, RLS integration test or payment fulfilment test has been performed yet.
- The lifecycle migration remains a **draft and has not been applied** to the live Supabase project. Existing accounts, enrolments, progress and certificates remain untouched. No production deployment or merge to `main` occurred.

**Next:** complete secure server-side offer expiry/payment fulfilment and attendance enforcement, add notification delivery for admission deadlines and interview reminders, finish reviewer scoring/recording consent and retention, then test learner/admin permissions in an isolated environment before applying migrations.


### Lifecycle monitoring refinements

- Added learner-visible time remaining for each open admission acceptance window and stored the deadline timezone.
- Added an applicant-specific interview join URL to the safe invitation record; meeting join links are visible only to the invited learner and authorised admins, while private reviewer notes and recording paths remain in the admin-only interview table.
- Added admin-triggered expiry sweeps: expired admission offers are marked expired and past interview appointments without attendance confirmation are marked missed, with application event history. These sweeps run when the Admissions workspace loads; a scheduled background job is still future work.
- Added database activity capture for lesson views (rate-limited per lesson), lesson completions/reopenings, quiz attempts and assignment submissions. Admin monitoring now displays weekly lesson completions, lesson visits, assessment submissions, last activity and inactivity bands.
- Added server-side level evaluation using published admin thresholds for lesson completion, quiz average, submitted assignments and active study days. Admin overrides are respected; approval-required levels enter a review queue, and rejected requests can be resubmitted after further progress.


## 2026-11-07 — Academy notifications and retention workflow

Status: **Source implementation committed to `education-build`; no database migration applied and no production deployment.**

- Learner Academy status page now includes an in-app notifications feed for admission, interview and learning updates, with unread/read state and action links.
- Admission and interview database triggers queue immediate notifications and scheduled reminders (24-hour admission deadline reminder; 24-hour and 1-hour interview reminders). Scheduled reminders become visible when their `scheduled_for` time arrives; a background scheduler/worker is still required for reliable delivery without the learner opening the page.
- The administrator Learning Progress refresh runs an inactivity sweep and queues warnings at 8+ days and overdue alerts at 15+ days. This is currently administrator-triggered, not a fully automatic daily cron.
- Notification RLS is learner-owned, and learner updates are limited to the `read_at` column. Admins can inspect the feed.
- Push/email/SMS delivery, notification preferences, and scheduled background execution remain future work.
- Next: review the complete Academy migration set and function grants, implement trusted admission/payment fulfilment, then run role-based database and browser tests in an isolated environment before production.


## 2026-11-07 — Learner pace and progression enforcement improvements

- Learner Academy status now displays completed lessons, weekly lesson-completion pace, active study days over the last 30 days, current/highest level and the next published level's configured milestone thresholds.
- The lifecycle migration draft now recalculates progression immediately after learner lesson completions and learner quiz/assignment submissions, so admin monitoring is not dependent only on a learner opening the status page.
- The evaluator remains subject to the existing configured rule thresholds and admin-approval workflow. This is still a draft implementation until the migration is reviewed and safely applied in an isolated/staging environment.
- JavaScript syntax validation passed for the learner status, learning progress admin, admissions admin and application scripts.
- No live schema changes, account changes, data deletion, merge or deployment occurred.


## 2026-11-07 — Unified CreatorVerse administrator control board

- Confirmed the Academy Admissions & Placement and Learning Progress workspaces are modules inside the existing `admin.html` control board, not separate applications or sites.
- Kept all changes on the existing `education-build` integration branch; the single administrator navigation routes to Admissions and Learning Progress alongside existing homepage, media, courses, students, assessments, certificates and payments workspaces.
- Fixed Supabase RPC thenable handling in admissions, learner progress and lesson activity paths by normalizing RPC calls through `Promise.resolve` before attaching `.catch` handlers.
- Updated `admin.html` script cache-busting versions so browsers fetch the latest integrated admin modules rather than stale cached JavaScript.
- JavaScript syntax checks passed for the modified runtime files. This is a source-level integration step, not proof of end-to-end database compatibility.
- Live Supabase currently has no `academy_*` tables or functions. The two Academy migrations remain unapplied; a full SQL dependency/security review and safe migration execution are required before Academy data workflows can operate. Existing production data and the production branch remain untouched.


## 2026-11-09 — Student-facing engagement goals and alerts

- Added the student portal Engagement section to the unified `dashboard.html` experience, with per-course engagement status, weekly activity target/progress, lesson views, completed lessons, last activity and a direct course link.
- Added `student_get_my_engagement()`, which derives a signed-in student's report only from their own enrolments and recorded learning activity; students cannot change administrator-set course targets.
- Added a private alert-state table and deduplicated in-app engagement notifications. A status change can generate a notification, with a seven-day reminder cooldown while a warning remains active.
- Added student-facing guidance for on-track, below-target, inactive and not-started states. The UI explicitly describes learning engagement, not verified physical attendance.
- Applied the database schema/function changes to the existing Supabase project and verified the RPC using an authenticated student context. The test ran inside a rolled-back transaction so it did not create a test notification or persist test alert state.
- Added migration `supabase/migrations/202611090050_student_engagement_portal.sql`; updated student dashboard asset cache versions. Existing student records and enrolments were preserved.
- JavaScript syntax validation passed. Browser end-to-end testing as a real student remains outstanding.

- Added realtime refresh hooks for a student's own learning activity and lesson-progress changes, and enabled those tables in the existing Supabase Realtime publication. The student report refreshes when learning records change in another tab/device.

## Scheduled Learning Sessions & Check-ins
- Admins can schedule timed learning sessions against a course, with a start/end window and instructions.
- Enrolled students see upcoming/open/completed/missed sessions in their dashboard and can check in only while the session window is open.
- Missed status is derived only after a scheduled session ends without a check-in; lesson views and general inactivity are not attendance.
- Admin session overview reports enrolled, checked-in, and missed counts. This is a learning-session record, not physical classroom attendance verification.

## Student Intervention & Follow-up
- Administrators can issue student-visible intervention notices from the individual academic record, optionally linked to an enrolled course and follow-up deadline.
- Each notice records the concern, support message and required next step. Private administrator notes remain separate from student-facing interventions.
- Students can read notices and submit a response from their dashboard. Administrators can review responses and resolve the follow-up.
- Intervention records are private and accessed through authenticated, role-checked RPCs; no automatic account suspension or course removal occurs.
