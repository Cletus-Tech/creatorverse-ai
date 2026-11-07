

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
