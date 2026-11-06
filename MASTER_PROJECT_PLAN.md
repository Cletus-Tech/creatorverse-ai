

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
