# CreatorVerse Academy — Admissions, Placement, Assessment & Certification Blueprint

**Status:** Architecture specification — draft, private development branch only.  
**Branch:** `education-build`  
**Production safety:** No production database migration, deployment, merge to `main`, or live learner-access change is authorised by this document.

## 1. Purpose and governing rules

CreatorVerse Academy is an admissions-based competency programme, not an open self-enrolment video library. A learner must be admitted, placed at an appropriate level, granted course access through the approved admission/payment path, demonstrate learning through assessments and practical work, and pass an academic review before a certificate is issued.

Non-negotiable invariants:

1. An application is not an enrolment.
2. A learner's requested level is a self-assessment only; the academy assigns the confirmed level.
3. An approved application grants access to a free course. A paid course additionally requires verified payment.
4. No learner-controlled insert, update, or delete can create enrolment, academic completion, a passed result, or a certificate.
5. Lesson completion is recorded only by trusted server-side logic after the configured requirements pass.
6. Correct answers and scoring keys never reach the learner's browser.
7. Certificates are issued only by an authorised administrator after an auditable eligibility review.
8. Existing enrolments, progress, assessment attempts and certificates must be preserved during migration.
9. All academic content, questions, rubrics, level definitions, thresholds and workflows are admin-managed and revision-aware.
10. No draft content becomes student-visible until an authorised admin explicitly publishes it.

## 2. Learner journey

Registration/sign-in → choose a course → complete application → self-select proposed level → answer course-specific diagnostic → submit recorded responses or request an alternative assessment → optional/required live interview → admin review → confirmed placement and admission decision → payment verification if paid → course access → lessons and practical work → topic CBT → stage assessment → final examination and graded capstone → academic eligibility review → admin certificate approval → certificate issuance and public verification.

Each step has a visible status, timestamp, responsible actor and next-step message. Rejected, deferred, incomplete and additional-information-requested applications must not silently become active enrolments.

## 3. Admissions

### Student application
Capture:
- Registered account email (read-only and sourced from the authenticated account).
- First, middle and last name; phone; country; state/region.
- Highest education and occupation (optional).
- Prior experience, relevant work/portfolio links, motivation and learning goals.
- Discovery/referral source.
- Exact certificate display name confirmation.
- Course ID and proposed entry level.
- Required consent acknowledgements and privacy notice version.

The application is editable only while draft or when an administrator requests more information. Submitted applications are immutable snapshots; resubmission creates a version/history entry rather than erasing the original.

### Application statuses
`draft`, `submitted`, `under_review`, `more_information_requested`, `approved_pending_payment`, `approved`, `rejected`, `withdrawn`.

Approval and access are separate decisions. Free-course admission can create an enrolment after approval. Paid-course admission creates an approved-pending-payment state; access follows verified payment only. Payment verification remains tied to the existing payment-order flow and authorised finance/admin roles.

### Admin workspace
Filter by course, status, date, proposed level and reviewer. View application history, portfolio links, diagnostic evidence, interview records and private notes. Record a decision reason and notify the applicant. All decisions are audited.

## 4. Placement and interviews

### Level framework
- **Beginner:** no meaningful prior experience; needs guided foundations.
- **Foundation:** understands basic concepts; needs structured practice.
- **Intermediate:** has working fundamentals and some practical experience.
- **Advanced:** works independently and can handle complex tasks.
- **Professional:** substantial demonstrated competence; seeks specialisation or refinement.

The learner's choice is advisory. Final placement is based on course-specific diagnostic evidence, practical work/portfolio, recorded answers and (where required) a live interview. Admin may confirm, raise or lower the proposed level and must record the rationale.

### Course-specific diagnostics
Question sets are linked to a course and optionally to a target level. Each question supports prompt, response type, order, required/optional flag, scoring rubric, maximum points, time guidance and active dates. Admins can author, edit, reorder, version and retire questions. Example YouTube Automation evidence includes channel operation, niche research, script writing, retention analysis and monetisation knowledge. Questions for other courses must test the actual skills taught by that course.

### Recorded interview studio
A student sees one prompt at a time and can record video+audio or an allowed audio-only response. The browser must explicitly request camera/microphone permission. Controls: start, pause, resume, stop, preview, discard/rerecord and submit. Show recording state and remaining time clearly. Submission is final for that attempt; any permitted retake is a new version with history.

Recording configuration is per course/interview: required/optional/disabled, response time, total duration, retake count, prompt order and permitted media type. Store consent timestamp, policy version, purpose, retention deadline and media metadata. Recordings belong in a private Storage bucket; never store public object URLs. Admin playback uses short-lived signed URLs after server-side authorisation. Provide an equivalent written/portfolio/live assessment route where a learner cannot or does not consent to recording. No covert recording.

### Live interviews
Support student interview requests and admin invitations, scheduling, timezone display, reminders, rescheduling/cancellation, room status, connection checks, camera/mic controls, private interviewer notes and scoring. Recording is off by default and requires explicit consent from all participants. The implementation must use a documented provider abstraction or reliable WebRTC infrastructure including TURN; do not ship a STUN-only demo as dependable calling. Provider, cost, data residency, retention and free-tier constraints must be reviewed before provider integration. The initial UI/data model can be provider-neutral.

### Placement admin
A dedicated Placement & Interviews area lists applications, diagnostic results, recordings, live sessions, reviewer notes, rubrics and recommended levels. Admin can assign final level, request another assessment, invite to interview, mark placement complete, or return the application for further evidence.

## 5. Learning progression and lesson completion

Replace student-authoritative “Mark as Completed” behavior. A learner may mark a lesson as studied or request assessment, but the backend controls academic completion.

Default topic sequence:
1. Open and study the lesson.
2. Complete the practical activity and submit evidence when configured.
3. Take the topic CBT.
4. Meet the pass threshold and any required assignment criteria.
5. Trusted server-side logic records topic completion.
6. Unlock the next topic.

Course admins can configure whether a topic requires CBT only, CBT plus practical submission, or another approved evidence combination. Unlock rules are evaluated server-side. Direct learner writes to completion/progress tables are not allowed. A learner cannot delete or rewrite a passed result to reset their record.

## 6. CBT and examinations

Assessment types: topic quiz, stage/module examination, and final course examination. Admin controls:
- Question bank and course/stage/topic association.
- Question type (initial release: single-answer multiple choice; later types can be added).
- Question text, options, points, explanation, difficulty and tags.
- Timer, pass mark, attempt limit, availability window and due date.
- Random question selection, option shuffle and question order.
- Publication state and version.
- Whether a passed result is required for progression.

Exam flow: server authorises an attempt and issues a time-bounded attempt ID; client receives only question text/options and safe metadata; answers are submitted against that attempt; server validates ownership, state, deadline, question membership and attempt rules; scoring occurs server-side; final result and immutable answer snapshot are stored. Expiry triggers server-side auto-submission/scoring or a clearly defined timeout outcome. Retrying or editing a submitted attempt is prohibited.

Never return `correct_index`, answer keys, scoring secrets or private rubric notes in student-facing payloads. Attempt creation, submission, scoring and completion must be protected against replay, race conditions and direct table writes.

## 7. Assignments and grading

Assignments have briefs, required deliverables, accepted file types/size limits, due dates, rubric criteria, points and resubmission policy. Learners submit text and/or private files. Admins grade with criterion-level scores, feedback, reviewer and timestamp. A required assignment must be graded and pass its configured threshold before course completion eligibility. Keep original submissions and grading history.

## 8. Certification

Eligibility is computed from authoritative records:
- Required topic assessments passed.
- Required stage examinations passed.
- Final examination passed.
- Required practical assignments graded and passed.
- Required course attendance/activities, if configured.
- No unresolved academic integrity or administrative hold.

An admin reviews the learner's academic record, confirms the approved certificate name, grade/classification and course title, then issues the certificate. Certificate numbers are unique and non-guessable. Certificate records include issue/revocation events, issuer, timestamps, verification token/URL and immutable issue snapshot. Revocation requires a reason and audit record. Public verification reveals only the minimum certificate facts necessary to validate authenticity; it must not expose student contact details, interview media, grades or private notes. Learners can download only issued, non-revoked certificates.

The existing self-claim certificate RPC must be retired or reduced to a safe read-only eligibility check; it must never issue a certificate on a learner's request.

## 9. Notifications and audit

Notify learners about application receipt, missing information, admission decision, payment requirement/verification, placement decision, interview invitations/changes, assessment availability/results, progression, grading feedback and certificate issuance/revocation. Admin dashboard notifications cover pending applications, interview reviews, grading queues and certificate reviews.

Audit actor, action, target, timestamp, reason and relevant before/after state for sensitive actions. Do not place secrets, answer keys, private interview media or unnecessary personal data in notification payloads or audit text.

## 10. Proposed data domains

Names are logical design candidates, not approved final SQL names. Final migration design must reconcile with actual live schema, constraints, triggers, grants and existing data.

- Admissions: `course_applications`, `application_history`, `application_reviews`.
- Placement: `placement_levels`, `placement_question_sets`, `placement_questions`, `placement_responses`, `placement_reviews`.
- Interviews: `interview_sessions`, `interview_prompts`, `interview_recordings`, `interview_consents`, `interview_reviews`.
- Academic delivery: extend or version `quizzes` and `quiz_questions`; `assessment_attempts` (or safely extend `quiz_attempts`); `assessment_answers`; `topic_requirements`; `lesson_completion_events`.
- Grading: extend `assignments` and `submissions` with rubric/version and grading history.
- Certification: `certificate_reviews`, `certificate_events`; preserve existing `certificates`.
- Governance: `academic_audit_log`, notification event types and admin-configurable workflow settings.

Do not create duplicate enrolment, quiz, submission or certificate systems if the existing tables can be safely extended. Prefer additive migrations and compatibility views/RPCs where required.

## 11. Security and privacy requirements

- All tables in exposed schemas require RLS and least-privilege grants.
- Role decisions must use trusted server-side role records/app metadata, never user-editable auth metadata.
- Admin actions require server-side authorisation and audit.
- SECURITY DEFINER functions require a fixed search_path, explicit authenticated actor checks, minimal grants and a documented reason; prefer SECURITY INVOKER.
- Interview storage is private, scoped by application/student and authorised reviewer; use signed URLs and retention cleanup.
- Validate MIME type, size, ownership and path server-side.
- Consent is purpose-specific and versioned; no recording until consent is captured.
- Provide retention and deletion workflows and an alternative assessment route.
- Keep private reviewer notes separate from student-visible feedback.
- Prevent student access to other applicants' records, exam keys, answer snapshots, grades or recordings.

## 12. Delivery sequence

1. **Read-only audit:** inspect repository, branch, live schema, RLS, grants, triggers, functions, storage buckets, current course/enrolment/progress/quiz/submission/certificate data and admin role model.
2. **Schema and policy design:** produce a non-destructive migration plan and data backfill/compatibility strategy; do not apply to production.
3. **Admissions foundation:** application form, status lifecycle, admin review and notifications.
4. **Placement:** configurable levels, diagnostics, recorded interview with consent/private storage and reviewer workflow.
5. **Live interview:** provider evaluation and integration only after cost/privacy decision.
6. **Academic progression:** secure assessment sessions, server-side CBT scoring, completion gates and assignment grading.
7. **Certification:** eligibility review, admin issuance, verification and revocation.
8. **Admin integration:** role-specific navigation, queues, settings, audit and exports.
9. **QA:** RLS adversarial tests, two-account journey tests, timing/attempt tests, file access tests, migration rollback/data-preservation checks, mobile and accessibility review.
10. **Release:** only after full acceptance review and explicit user approval. No deployment or production migration during this design/build phase.

## 13. Acceptance criteria

- A newly registered learner cannot self-enrol or open course lessons.
- Admin approval is required for free-course access; paid-course access additionally requires verified payment.
- Requested level never automatically becomes confirmed placement.
- Student can complete the configured diagnostic and interview or alternative assessment; unauthorised users cannot access recordings.
- Admin can review evidence, score it and assign a level with rationale.
- Student cannot write/delete academic completion or certificate records directly.
- A topic cannot complete until its configured requirements pass.
- CBT keys are never present in student API responses; timing and attempt limits are server-enforced.
- Course completion requires all configured academic criteria.
- Only authorised admin issuance creates a downloadable certificate.
- Every sensitive decision is auditable; existing learner records remain intact.
- All content and configuration can be managed from the Admin Portal without editing source code.
