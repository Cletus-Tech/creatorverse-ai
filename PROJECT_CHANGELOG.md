

## 2026-11-06 — Academy curriculum structure and admin controls (expanded)

- Extended the course model with editable programme length in months and expected study hours per week.
- Extended modules with stage number, stage duration and stage description; extended lessons with chapter number, estimated minutes and topic outline.
- Reworked the seven seeded Academy programmes into ordered stages and topic-specific chapter titles: YouTube Automation (4 months, 6 hours/week); AI Content Creation (3 months, 5 hours/week); TikTok Growth & Monetisation (3 months, 5 hours/week); Prompt Engineering (2 months, 5 hours/week); AI Graphic Design (3 months, 5 hours/week); Digital Business (3 months, 5 hours/week); Algorithm & Niche Research (2 months, 5 hours/week).
- Each programme contains 3 stages and 9 sequenced chapters, with chapter timings, teaching content, professional workflow, practical workshop, common mistakes, assignment and self-assessment. The 63 chapters total approximately 3,085 minutes of lesson time, excluding independent project work.
- Student course pages now display stage names, stage schedule, stage description, chapter count and estimated chapter time. Lesson view displays chapter number, estimated minutes and topic outline.
- Admin Portal → Courses now exposes programme months, weekly study hours, stage timing and description, chapter duration and topic outline, alongside existing editable teaching content/video/resources. Reordering stages updates stage numbering; new chapters receive sequence numbers and default timings.
- QA: Supabase schema and curriculum counts verified; `course-admin.js` and `lms.js` JavaScript syntax checks passed. Full browser/device and enrolment/progress flow testing remains outstanding.


## 2026-11-06 — Universal page loading gate

- Added a shared loading gate in `layout.js`, so every page using the common site layout displays a full-viewport branded loading screen while its initial page content is being prepared.
- The gate overlays the page during rendering, preventing the footer or page shell from flashing before the main content is ready.
- Reuses the existing homepage loader and applies a consistent fade-out; other pages receive the shared CreatorVerse mark, progress line and status caption.
- Gate waits for the browser load event and stable, non-placeholder main content, with a 9-second safety timeout to prevent a permanently stuck overlay. It also handles browser back/forward cache restores.
- Existing page-specific loaders remain intact and can continue handling later data refreshes; the shared gate addresses the initial page-load flash.
- Scope: pages that include `layout.js`. Standalone pages without the shared layout require explicit integration if any exist.
- QA: source-level inspection only. Production deployment and device-by-device visual verification pending.


## 2026-11-06 — CreatorVerse AI assistant interface redesign

Status: **Implemented on `main`; deployment and browser QA pending.**

- Replaced the dark, basic chat panel with a professional assistant workspace: compact dark mode sidebar, dark navy conversation canvas, polished header, prompt starter cards and a clearer message composer.
- Updated typography, spacing, borders, shadows, multi-colour accents, image-led prompt cards and mobile breakpoints while retaining the original dark theme.
- Kept the existing authenticated-only route, General and CreatorVerse specialist modes, conversation/message persistence and Supabase Edge Function endpoint/payload intact.
- Added functional starter prompts to fresh conversations, textarea auto-resizing, clearer loading feedback and safer response/error handling.
- No AI model/provider, Edge Function, database schema, RLS, authentication or billing changes were made.
- Remaining checks: deploy, inspect desktop/mobile rendering, test both modes, send/receive messages, verify saved conversation/message records, and check keyboard behavior.



## 2026-11-06 — Academy course catalogue visual polish

Status: **Implemented on `main`; deployment and visual QA pending.**

- Polished the Academy course discovery page with richer image treatment, featured course badges, colourful category/level accents, clearer metadata and more refined responsive cards.
- Preserved course loading, search, category filters, featured sorting, pricing, lesson counts, course navigation and admin-managed thumbnails.
- Kept the changes scoped to the Academy catalogue; no AI Assistant theme or unrelated page styling was changed.


## 2026-11-06 — CreatorVerse Connect messaging and stories foundation

Status: **Implemented in repository and Supabase; production deployment and live multi-user QA pending.**

- Added the Messages & Stories page with a responsive dark CreatorVerse workspace, inbox, creator search, chat thread, composer, story rail, story creation and story viewer.
- Added one-to-one direct conversations and persistent messages with real-time incoming message updates through Supabase Realtime.
- Added live online status through authenticated Realtime Presence.
- Added text and image stories that remain in the active story feed for up to 24 hours, plus view tracking.
- Created RLS-enabled conversation, direct-message, story and story-view tables; restricted conversations and messages to participants and respected existing community block records for starting/sending messages.
- Reused the existing `community-media` bucket with its per-user upload policy for image stories.
- Added Messages & Stories to the account dropdown and mobile navigation.
- Video/voice calls and one-to-one class rooms are planned follow-on work, not part of this release. Reliable calls require signaling plus TURN relay infrastructure or a managed video provider; a STUN-only prototype would not be dependable.
- Expired stories are filtered out after 24 hours; automated deletion of expired story rows and media is not yet configured.
- Pending QA: test messaging and presence with two separate accounts, test story upload/view/expiry and test the block rules.


## 2026-11-06 — Dashboard mobile and theme repair + platform audit

Status: **Fixes committed to `main`; production deployment verification pending.**

- Restored the student dashboard's intended dark navy CreatorVerse theme; removed the later light-surface overrides that were overriding the dark dashboard design.
- Added defensive mobile sizing and overflow rules for the dashboard shell, content area, welcome panel, and flex/grid children to prevent the narrow clipped dashboard layout shown in the user's phone screenshot.
- Added a dedicated **Messages** entry to the persistent mobile bottom navigation, rather than leaving messaging discoverable only inside the account dropdown or hamburger menu.
- Supabase security hardening: changed `community_profiles` to SECURITY INVOKER, fixed the search_path on `block_role_change()`, and revoked API execution grants from trigger-only functions. Verified the view option, function search_path, and zero exposed execute grants for those trigger functions.
- Full platform review found remaining advisory items documented in the audit response: leaked-password protection is disabled; several intentionally callable SECURITY DEFINER RPCs remain; performance lints include unindexed foreign keys, auth RLS initplan warnings, duplicate/overlapping permissive policies, unused indexes, and one duplicate index. These need targeted review rather than unsafe blanket policy changes.
- No two-account messaging test or authenticated browser-based end-to-end dashboard test was possible in this audit pass; those remain explicit verification items.


## 2026-11-06 — CreatorVerse Connect reliability and moderation rebuild

Status: **Core fixes and moderation tools committed; deployment and live multi-account QA pending.**

- Fixed the authentication bootstrap: `messages` and the new `connect-admin` route are now explicitly included in the protected-page SDK/session loader. Previously, a signed-out visitor could land on a messaging page without the Supabase client ever being initialized, leaving the page stuck at a connection failure rather than consistently redirecting to login.
- Rebuilt the Connect client flow with one-time initialization, latest-first message loading, duplicate-message protection, clearer connection errors, online presence state, conversation search, story reporting, message reporting, and guarded story view recording.
- Refined the Connect workspace styling and mobile layout; added report controls without exposing private inboxes to administrators.
- Added RLS-protected `cv_content_reports` for user-submitted story/message reports and an admin-only policy for removing stories.
- Added a dedicated `connect-admin.html` moderation workspace. Admins can review reports, update moderation status, review active stories and remove stories. Administrators cannot browse private conversations; only user-reported message excerpts are shown.
- Verification: migration applied; source syntax and deployment build must be checked; real two-account messaging, Realtime presence, image upload, and admin moderation QA remain required.


## 2026-11-06 — CreatorVerse Connect phase 2: attachments, typing and read receipts

Status: **Database and client code committed; deployment and two-account verification pending.**

- Added private `cv-chat-files` storage bucket with a 15 MB limit and restricted MIME types (images, PDF, plain text). Upload paths are conversation/user scoped; only the two conversation participants can read files. Files are served through short-lived signed URLs, not public URLs.
- Added attachment metadata columns to direct messages.
- Added recipient-only read receipt updates. Authenticated users receive column-level UPDATE permission only for `read_at`; message content/sender/conversation cannot be edited through this permission. Sender bubbles show Sent/Seen.
- Added ephemeral typing indicators through private conversation Realtime Broadcast channels, with policies limited to the two participants.
- Added attachment selection, file validation, progress/error feedback and attachment rendering in the chat interface.
- Release QA still requires two separate authenticated accounts and actual file upload/download, typing, and read receipt checks. Voice/video calls, group chats, scheduled class rooms and push notifications remain unimplemented.


- Added direct Messages navigation on desktop, retained mobile bottom/mobile menu/account-menu access, and added owner controls to delete stories (including best-effort removal of the owner's uploaded story image).
- Final source checks passed for JavaScript syntax, all referenced DOM IDs, protected route registration, desktop/mobile Messages links and the private conversation channel name.
- A new production deployment was attempted for the latest commit but Vercel rejected deployment creation with its free API daily deployment limit (HTTP 402; retry after 24 hours). The previous READY production build therefore does not include these phase-two additions yet.


## 2026-11-06 — CreatorVerse AI intelligence rebuild
- Root cause: the active creatorverse-assistant Edge Function was not connected to any language model. It tokenised the question, searched cv_ai_knowledge, and pasted matching text into a template.
- Rebuilt the Edge Function to call an actual OpenAI-compatible language model with server-side credentials, while retaining published CreatorVerse knowledge as grounding context.
- Added general and CreatorVerse-guide instructions, bounded chat history, timeout and provider error handling, and explicit missing-key feedback.
- Updated frontend to pass recent conversation turns, retain context and use useful task-specific suggestions.
- Required setup: configure AI_API_KEY (or OPENAI_API_KEY) in Supabase Edge Function secrets. Optional AI_BASE_URL and AI_MODEL. No API key is committed to GitHub or exposed to the browser.


- Switched the default provider configuration to Google's Gemini OpenAI-compatible API and `gemini-3.6-flash` to keep the first setup free-tier-friendly. The user still needs to create a Gemini API key in AI Studio and store it as the Supabase Edge Function secret `AI_API_KEY`. Free-tier quota and model availability are subject to Google's current limits.
- Supabase Edge Function `creatorverse-assistant` deployed as active version 4. The GitHub frontend updates are committed; Vercel production has not yet been verified to include the latest `ai.js` commit.


## 2026-11-06 — Academy course content and resource launch

- Added seven published, free, admin-managed courses across the existing Academy categories: YouTube Automation; AI Content Creation; TikTok Growth & Creator Monetisation; Prompt Engineering; AI Graphic Design & Visual Branding; Digital Business; Algorithm Analysis & Niche Research.
- Populated 21 modules and 63 lessons. Each lesson contains an overview, learning outcomes, expert guidance, practical workshop, quality checklist, common mistakes and an assignment.
- Added 63 further-learning resource links to official documentation and learning destinations.
- Added learning outcomes, prerequisites, course levels and estimated durations to course records. Updated the Algorithm Analysis category description and topic tags.
- Preserved the existing 3D Animation course and existing enrolment/progress/payment schema. New courses are published at ₦0.
- Confirmed in Supabase that every new course has 3 modules, 9 lessons and 9 resources and is published.
- Course management uses the existing Admin Portal → Courses controls. Admins can edit metadata/flyers, publish/unpublish, reorder and edit modules/lessons, update lesson content/video, and manage resources. No content is hardcoded into the website.
- Remaining QA: verify catalogue cards and lesson text on desktop/mobile, test a student enrolment/lesson-completion flow, and edit/save one lesson and resource from the admin portal.


## 2026-11-06 — Compact movable assistant and verified badges

Status: **Committed to `main`; deployment and live browser QA pending.**

- Reduced the floating assistant launcher to a compact bot-face button for desktop and mobile, with a smaller greeting bubble and responsive chat panel.
- Kept the existing page-aware assistant and chat integration; the welcome copy now introduces CreatorVerse AI as the user's personal assistant and explains what it can help with.
- Enabled saved drag positioning across mobile and desktop, with edge snapping after a drag.
- Added `profiles.verified_badge` (`none`, `blue`, `green`, `gold`) and a database trigger that prevents non-super-admin users from changing badge assignments.
- Existing super-admin accounts were assigned the gold badge. Admin Portal → Students exposes badge management to super admins; gold is reserved for the owner account.
- Added badge indicators to public creator profiles, creator discovery and messaging.
- Source syntax checks passed for the updated JavaScript files. Production deployment and real-device drag/tap/overlap testing remain pending.


## 2026-11-07 — Social verification tick and loading gate repair
- Replaced public badge text/diamond labels with one compact blue social-platform-style tick beside verified names.
- Applied the icon to profile headers and follower lists, creator discovery, community post/comment authors, Connect conversations/search/stories, and student/admin identity surfaces.
- Simplified Admin Portal → Students to No tick / Blue tick; legacy badge values display as the same blue tick.
- Reworked the shared loading gate to wait for initial fetch/XHR activity to settle, wait for fonts and layout frames, and retain a bounded fallback timeout. The gate no longer relies on static text appearing stable while asynchronous page data is still loading.


## 2026-11-07 — Owner identity, shared profile rendering and assistant visibility

- Identified the CreatorVerse owner account by its unique profile ID, rather than applying owner styling to every `super_admin`.
- Added a distinct gold owner verification shield/name accent while preserving the blue verification mark for other verified users.
- Updated the signed-in account menu to render the canonical profile name and avatar (with auth metadata fallback), and prevented the Messages & Stories menu item from being relabelled as Dashboard.
- Fixed the student dashboard identity source: it now hydrates display name, avatar and verification state from `profiles`, avoiding stale `user_metadata.avatar_url` when the profile has since changed.
- Rebuilt the floating assistant stylesheet with its missing launcher/panel positioning and responsive layout. The welcome message continues to fade after six seconds or immediately when tapped; the bot button remains independently available.
- Remaining work: full cross-page profile/avatar unification, systematic broken-link/button destination audit, and authenticated mobile/desktop end-to-end QA.


## 2026-11-07 — Message unread badge and notification centre

- Created `public.cv_notifications` with per-user RLS and Realtime publication registration.
- Added private-schema triggers that create recipient notifications for direct messages, new followers, post likes and post comments; self-actions are excluded.
- Added a clean SVG bell and dropdown in the right-side site header, away from the Home/Divisions navigation.
- Added exact unread-message badges to desktop and mobile Messages navigation using `cv_conversations` and `cv_direct_messages.read_at`.
- Added `notifications.html`, unread notification counts, live refresh and mark-all-read support. Two-account QA remains outstanding.


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


## 2026-11-07 — Academy and ecosystem image-led redesign

- Reworked the Academy catalogue and course detail presentation with a richer, colourful, image-first layout, responsive cards, stronger hierarchy, clearer course metadata and refined hover/focus treatment.
- Assigned a distinct course-specific cover image to all eight published Academy courses, including the preserved 3D Animation course. Covers are saved in the existing `courses.thumbnail_url` column, keeping them editable in Admin Portal → Courses.
- Populated the seven published learning-category `image_url` values so the Learn category grid and category detail pages have relevant visual artwork.
- Replaced broad keyword-based course image fallbacks with an explicit slug-to-image map to prevent unrelated courses from sharing a generic cover.
- Rebuilt all six CreatorVerse division cards with individual relevant imagery, stronger descriptions, feature lists and a consistent image-led layout. The Affiliate division now clearly communicates referral links, campaign tracking, conversions and commission statements.
- Preserved current routes, live/in-development statuses, course filters, enrolment, progress, pricing, lesson curriculum and admin controls. No course/module/lesson structure or payment behavior was altered.
- Database verification completed: all eight course thumbnails and all seven category images are populated. Inspect course and division pages on desktop and mobile before production promotion.


## 2026-11-07 — Academy admissions and academic systems blueprint

- Added `ACADEMY_ADMISSIONS_PLACEMENT_ASSESSMENT_SPEC.md` on the private `education-build` branch.
- Defined application statuses and admin decisions, the free-vs-paid access gate, five placement levels, course-specific diagnostics, recorded interview consent/privacy controls, provider-neutral live interview requirements, server-authoritative lesson completion and CBT, practical grading, admin certificate issuance/revocation, notifications and audit.
- Explicitly prohibited learner self-enrolment, direct learner academic-completion writes, client-side answer keys and self-claim certificate issuance.
- This is a design milestone only. No production database schema/policies/functions/storage were changed, no production deployment was made, and no merge to `main` was made.
- Next milestone: inspect the complete live schema, RLS policies, grants, triggers, RPC definitions, storage policies and existing learner records; prepare a compatibility-first migration plan that preserves all existing records.


## 2026-11-07 — Existing Academy security audit completed

- Added `ACADEMY_CURRENT_STATE_AUDIT.md` after a read-only review of the existing `education-build` frontend and connected Supabase schema.
- Verified the current learner self-enrolment and lesson-progress write/delete policies, the existing quiz RPC limitations, and learner-callable `claim_certificate` SECURITY DEFINER pathway. These are remediation priorities before the new admission and assessment flow is enabled.
- Recorded the current storage bucket inventory and specified a separate private bucket for recorded admissions interviews.
- No database writes, role changes, record deletions, migrations, branch creation, production merge or deployment were performed.
- Next: implement the admissions data model and admin/learner workflows additively on `education-build`, then replace unsafe access paths with tested server-authoritative policies and functions.


## 2026-11-07 — Academy admissions workspace foundation added

- Added an additive SQL migration draft at `supabase/migrations/202611070002_academy_admissions_foundation.sql` for applications, application history, course-specific diagnostic questions/responses, interview metadata, five-level placement and an Academy audit log.
- The migration preserves existing users and academic records and defines row-level access for applicants and admins. It creates a dedicated **private** `academy-interviews` Storage bucket; object upload/playback policies remain intentionally unconfigured until secure signed-URL authorisation is implemented.
- Added `admissions-admin.js` and integrated **Admin Portal → Admissions & Placement** into the existing admin navigation. The first workspace version lists applications, filters by status/search, shows applicant/course information and lets admins record a review decision, confirmed level, rationale and internal note with event/audit records.
- The admin workspace clearly keeps admission approval separate from enrolment/payment fulfilment; it does not grant course access.
- Code is committed to `education-build` only. The migration has **not** been applied to the live Supabase project, and the new workspace will show a schema-not-ready message until the migration is reviewed and applied. No deployment, merge, account/role change or existing-record deletion occurred.
- Remaining before learner launch: complete student application/diagnostic UI, private interview upload/playback policies and consent/retention flow, transactional decision/access RPCs, payment gate, and end-to-end security tests.


## 2026-11-07 — Learner admissions application flow added

- Added `academy-apply.html`, `academy-apply.js` and `academy-apply.css` for a responsive course-specific application experience.
- Course detail CTAs for learners who are not already enrolled now route to **Apply for admission** rather than directly creating free enrolments or starting payment checkout.
- The form captures applicant identity/contact, education and experience, portfolio, motivation, goals, proposed entry level, explicit application/privacy consent and published course-specific diagnostic responses.
- Applications are created as drafts and submitted with a reference number plus a submission-history event. The form explicitly explains that an application does not itself grant course access.
- Hardened the migration draft's data separation: private reviewer notes live in an admin-only table; diagnostic reviewer scores/feedback and interview metadata are not exposed to applicants through broad row reads.
- These are source changes on `education-build`. The migration remains unapplied, and end-to-end testing against the live database has not been performed. No deployment or merge was made.


## 2026-11-07 — Course diagnostic question authoring added

- Extended Admin Portal → Admissions & Placement with a course-specific diagnostic question bank.
- Admins can select a course, create/edit questions, choose response formats (long text, short text, URL or single choice), set target level, configure required/active state, publish/unpublish and delete questions.
- Published active questions are loaded dynamically into the learner application form. Question responses are stored separately from reviewer scoring; diagnostic reviews are admin-only in the schema draft.
- Added private diagnostic review storage in the migration draft so learner response reads do not expose staff scores or feedback.
- Source-level JavaScript syntax checks passed for `academy-apply.js`, `admissions-admin.js`, `admin-shell.js` and `lms.js`. Database integration, browser interaction, mobile rendering and RLS behavior remain untested because the migration has not been applied.
