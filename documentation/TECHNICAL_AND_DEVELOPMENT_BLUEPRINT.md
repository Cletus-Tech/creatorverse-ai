# CreatorVerse — Technical and Development Blueprint
Version 1.0 | Proposed target architecture | 2026-11-11

## Proposed stack
Website: Next.js + TypeScript on Vercel. Mobile: Flutter for Android/iOS. Backend: Supabase PostgreSQL, Auth, Storage, Realtime and Edge Functions where appropriate. Source: GitHub monorepo. Contracts: OpenAPI/typed API contracts and generated database types. Observability: structured logs, error monitoring, audit events and privacy-conscious analytics.

## Target repository structure
apps/website
apps/mobile
packages/contracts
packages/design-tokens
supabase/migrations
supabase/functions
documentation
scripts

Current repository structure and deployment must be inspected before moving files. Do not assume this monorepo exists.

## Backend boundaries
Database constraints and RLS are the source of truth for data access. Privileged actions use server-side functions with explicit role checks. Never ship service-role keys or secrets to clients. Validate uploads, file types, sizes, ownership and access. Sensitive files use private/signed access.

## Shared services
Authentication/profile; content/catalogue; enrolment/progress; academic resources; campus/housing; community/moderation; messaging; notifications; payments; certificates; admin configuration; audit.

## Migration
Inventory schema, RLS, triggers, functions, buckets, Auth settings, user data and integrations. Produce a compatibility map. Back up before migration. Prefer additive, reversible migrations. Preserve users, enrolments, messages and certificates. Never reset production data to simplify a rebuild.

## Security
Threat-model high-risk workflows. Review RLS table-by-table and RPC-by-RPC. Validate privileged operations server-side. Rate-limit sensitive endpoints. Protect identity documents/private addresses. Enforce role changes through authorised workflows. Audit moderation, payment, certificate, verification and configuration actions. Define retention, export and deletion.

## Delivery gates
Approved flow → design → API/data contract → web implementation → app implementation → backend permissions → automated tests → manual browser/device tests → accessibility/performance/security review → release notes.
No production claim without deployment confirmation. No E2E claim without running the test.

## Phases
0. Product, brand and legacy-system audit.
1. Final logo and design system.
2. Shared backend contracts and migration plan.
3. Website/app shells, navigation, auth and session.
4. Digital Skills vertical slice across web and app.
5. Academic secondary vertical slice; approve tertiary model.
6. Campus Life and accommodation vertical slice.
7. Community, messaging and notifications.
8. Payments, certificates and administration.
9. Security, accessibility, performance and release readiness.
10. Android release; iOS release readiness and submission.

## Definition of done
Both clients use the same backend rules; access controls are tested; loading/empty/error states are designed; accessibility is reviewed; responsive/device behaviour is verified; docs are updated; deployment status is confirmed.
