# CreatorVerse — Mobile App Blueprint
Version 1.0 | Planning baseline | 2026-11-11

## Platform
Flutter targeting Android and iOS from the beginning. Android is first build/test/release target; keep iOS dependencies, layouts and CI compatible from day one.

## Opening experience
Branded native splash with approved symbol; brief restrained loading animation/progress; restore secure session; fetch minimum configuration; route signed-in users to Home and new/unsigned users to a clean welcome/sign-in flow. Handle offline, expired session, maintenance and retry states. No emoji and no long forced intro.

## Primary navigation
Five destinations: Home, Learn, Campus, Community, Profile. Messages and notifications use consistent accessible top-level actions with unread badges. Do not overload the bottom bar.

## Screen groups
Welcome/auth/recovery; Home/discovery; Digital Skills catalogue/course/classroom/lesson/assessment/progress; Academic secondary and tertiary; Campus Life and accommodation (roommate preferences/matches, lodge search/detail, agent application, accommodation community); marketplace/study hub/errands as phased modules; community feed/profile/posts/comments/reports/blocks; inbox/conversations/stories/calls only when production-ready; notifications; settings/privacy/downloads/support; payment history and certificate wallet.

## Mobile requirements
Reachable touch controls; OS text scaling; safe areas; system back behaviour; accessibility services; secure token storage; no secrets in app; upload retry/resume; offline cache for approved resources with expiry/access rules; download storage controls; push notifications with consent/preferences; battery-aware background work.

## Release
Build and validate Android first. Run iOS builds and simulator/device checks continuously where available. Publish iOS after signing, privacy disclosures, permissions and store review requirements are satisfied.
