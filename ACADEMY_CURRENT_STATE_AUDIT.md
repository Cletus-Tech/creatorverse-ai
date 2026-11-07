# CreatorVerse Academy — Current Implementation & Security Audit

**Date:** 2026-11-07  
**Branch reviewed:** `education-build`  
**Database reviewed:** existing Supabase project `xgdngnekihhnkzurhvpe` (read-only audit)  
**Status:** Findings verified; remediation not yet applied.

## 1. Preservation boundary

- Existing authentication accounts and `public.profiles` must remain.
- Existing role assignments, especially `admin` and `super_admin`, must remain unchanged.
- Existing enrolments, progress, attempts and certificates are historical/test records. They are not to be cleared during this implementation without a separately reviewed, explicit reset operation.
- This audit made no database writes and did not deploy or merge anything.

## 2. Existing application architecture

The repository is a static HTML/CSS/JavaScript application using the Supabase JavaScript client from a CDN. The admin portal is assembled by `admin-shell.js`; course management is in `course-admin.js`; assessment authoring and grading are in `assess-admin.js`; student/course/lesson workflows are in `lms.js` and `assess.js`.

The current admin navigation includes Courses, Categories, Modules, Lessons, Students, Quizzes & Assignments, and Certificates. It does not yet include a complete Admissions & Placement workspace.

The current assessment authoring UI writes directly to `quizzes` and `quiz_questions`. It retrieves `correct_index` in the admin context, which is appropriate only for authorised staff. The learner-facing quiz path uses RPC functions.

## 3. Verified database security findings

### Enrolment
The current `enrolments` table has:
- Admin manage policy.
- Learner read-own policy.
- A public-role INSERT policy allowing a user to create their own enrolment when a course is published and free.
- A public-role DELETE policy allowing a user to remove their own enrolment.

This conflicts with the intended admissions-first process. The replacement must remove learner-controlled enrolment writes and grant access only through trusted admission approval and verified payment logic.

### Lesson progress
The current `lesson_progress` table has:
- Learner read-own policy.
- Learner INSERT policy when enrolled.
- Learner DELETE policy for their own progress.
- Admin manage/read policies.

This permits a learner to create or erase completion records without proving assessment mastery. The replacement must make completion server-authoritative and prevent learner writes/deletes.

### Quiz and certificate RPCs
The current public functions include:
- `get_quiz(uuid)`: returns question text and options without `correct_index`, but currently permits access to published free courses without checking enrolment/admission.
- `submit_quiz(uuid,jsonb)`: checks login, published course and enrolment, then scores and inserts an attempt. It does not enforce a server-issued timed attempt, deadline, attempt limit, or immutable attempt session.
- `claim_certificate(uuid)`: SECURITY DEFINER function callable by a learner that checks lessons/quizzes/graded assignments and inserts a certificate. Certificate issuance must instead be administrator-authorised and auditable.

The helper functions `is_admin()`, `is_super_admin()`, and `is_enrolled(uuid)` are SECURITY DEFINER functions. Any replacement must use a fixed search path, explicit execution grants, and a non-exposed schema for privileged internal functions where appropriate.

### Other existing policies
- Quiz attempts are readable by the owner or admin; the reviewed policy set did not show a direct learner INSERT policy.
- Quiz questions and quizzes are admin-write.
- Assignment submissions permit learner insertion when enrolled; admin can grade/update.
- Certificates are readable by the owner/admin and admin-updatable. A learner insert policy was not present in the reviewed policy output.

## 4. Storage inventory

Existing buckets observed:
- `community-media` — public
- `creatorverse-media` — public
- `cv-chat-files` — private
- `profile-avatars` — public
- `submissions` — private

Recorded admissions interviews must use a separate private bucket with strict per-application access and short-lived signed playback URLs. They must not be placed in the existing public media buckets.

## 5. Data model facts observed

Existing academic tables include courses, modules, lessons, enrolments, lesson_progress, quizzes, quiz_questions, quiz_attempts, assignments, submissions and certificates. The enrolment primary key is (user_id, course_id); progress primary key is (user_id, lesson_id). Existing certificate uniqueness is per user/course.

The existing `enrolments` table has no status column. The new admission/payment state should be represented explicitly rather than inferred from an enrolment row.

## 6. Implementation sequence

1. Add admissions, application history, diagnostic question/response, interview consent/metadata, placement and audit records additively.
2. Add administrator review and placement workflows.
3. Add learner application and diagnostic flows.
4. Add private interview storage policies and consent/retention controls.
5. Replace unsafe enrolment/progress/certificate pathways with reviewed server-side functions and RLS policies.
6. Add server-authoritative exam sessions, timer/attempt limits, grading and completion gates.
7. Integrate admission/placement/assessment/certificate controls into the existing admin portal.
8. Run role-based QA with preserved accounts; verify student, instructor, admin and super-admin permissions.
9. Release only after the owner approves the completed build.

## 7. Explicit non-actions

This audit did not:
- Delete or alter any auth user or profile.
- Change roles.
- Delete test enrolments, progress, attempts or certificates.
- Change RLS policies or functions.
- Create a Supabase branch or project.
- Apply migrations.
- Merge to `main` or deploy.

