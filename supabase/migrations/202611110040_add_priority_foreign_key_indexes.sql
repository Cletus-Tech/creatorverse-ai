-- Targeted covering indexes for frequently joined academy and learner workflow foreign keys.
-- These indexes are additive and do not alter existing records or access policies.
create index if not exists idx_academy_applications_reviewed_by on public.academy_applications(reviewed_by);
create index if not exists idx_academy_interviews_reviewer_id on public.academy_interviews(reviewer_id);
create index if not exists idx_academy_learning_activity_course_id on public.academy_learning_activity(course_id);
create index if not exists idx_academy_learning_activity_lesson_id on public.academy_learning_activity(lesson_id);
create index if not exists idx_academy_learning_sessions_created_by on public.academy_learning_sessions(created_by);
create index if not exists idx_academy_student_interventions_course_id on public.academy_student_interventions(course_id);
create index if not exists idx_academy_student_interventions_created_by on public.academy_student_interventions(created_by);
create index if not exists idx_cv_notifications_actor_id on public.cv_notifications(actor_id);
create index if not exists idx_enrolments_course_id on public.enrolments(course_id);
create index if not exists idx_lesson_progress_lesson_id on public.lesson_progress(lesson_id);
create index if not exists idx_lessons_module_id on public.lessons(module_id);
create index if not exists idx_modules_course_id on public.modules(course_id);
create index if not exists idx_payment_orders_course_id on public.payment_orders(course_id);
