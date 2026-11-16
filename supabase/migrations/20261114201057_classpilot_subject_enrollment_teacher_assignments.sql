-- ClassPilot: subject enrollment and teacher assignment foundation
create table if not exists public.school_subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  subject_name text not null check (length(btrim(subject_name)) between 2 and 100),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  constraint school_subjects_school_name_unique unique (school_id, subject_name),
  constraint school_subjects_id_school_unique unique (id, school_id)
);

create unique index if not exists profiles_id_school_unique on public.profiles(id, school_id);
create unique index if not exists students_id_school_unique on public.students(id, school_id);

create table if not exists public.student_subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null,
  school_subject_id uuid not null,
  created_at timestamptz not null default now(),
  constraint student_subjects_student_school_fk
    foreign key (student_id, school_id) references public.students(id, school_id) on delete cascade,
  constraint student_subjects_subject_school_fk
    foreign key (school_subject_id, school_id) references public.school_subjects(id, school_id) on delete cascade,
  constraint student_subjects_unique unique (student_id, school_subject_id)
);

create table if not exists public.teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  teacher_user_id uuid not null,
  class_name text not null check (length(btrim(class_name)) between 1 and 80),
  school_subject_id uuid not null,
  assigned_by uuid,
  created_at timestamptz not null default now(),
  constraint teacher_assignments_teacher_school_fk
    foreign key (teacher_user_id, school_id) references public.profiles(id, school_id) on delete cascade,
  constraint teacher_assignments_subject_school_fk
    foreign key (school_subject_id, school_id) references public.school_subjects(id, school_id) on delete cascade,
  constraint teacher_assignments_assigned_by_fk
    foreign key (assigned_by) references public.profiles(id) on delete set null,
  constraint teacher_assignments_unique unique (teacher_user_id, class_name, school_subject_id)
);

create index if not exists student_subjects_school_student_idx on public.student_subjects(school_id, student_id);
create index if not exists student_subjects_school_subject_idx on public.student_subjects(school_id, school_subject_id);
create index if not exists teacher_assignments_teacher_idx on public.teacher_assignments(teacher_user_id, school_id);
create index if not exists teacher_assignments_class_subject_idx on public.teacher_assignments(school_id, class_name, school_subject_id);

alter table public.school_subjects enable row level security;
alter table public.student_subjects enable row level security;
alter table public.teacher_assignments enable row level security;

grant select, insert, update, delete on public.school_subjects to authenticated;
grant select, insert, update, delete on public.student_subjects to authenticated;
grant select, insert, update, delete on public.teacher_assignments to authenticated;

drop policy if exists "school admins manage school subjects" on public.school_subjects;
create policy "school admins manage school subjects"
on public.school_subjects for all to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
)
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "teachers view assigned school subjects" on public.school_subjects;
create policy "teachers view assigned school subjects"
on public.school_subjects for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.teacher_assignments ta
    where ta.school_subject_id = school_subjects.id
      and ta.school_id = school_subjects.school_id
      and ta.teacher_user_id = (select auth.uid())
  )
);

drop policy if exists "school admins manage student subject enrollment" on public.student_subjects;
create policy "school admins manage student subject enrollment"
on public.student_subjects for all to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
)
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "teachers view assigned student subject enrollment" on public.student_subjects;
create policy "teachers view assigned student subject enrollment"
on public.student_subjects for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.teacher_assignments ta
    join public.students s on s.id = student_subjects.student_id and s.school_id = student_subjects.school_id
    where ta.teacher_user_id = (select auth.uid())
      and ta.school_id = student_subjects.school_id
      and ta.school_subject_id = student_subjects.school_subject_id
      and ta.class_name = s.class_name
  )
);

drop policy if exists "school admins manage teacher assignments" on public.teacher_assignments;
create policy "school admins manage teacher assignments"
on public.teacher_assignments for all to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
)
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "teachers view their own assignments" on public.teacher_assignments;
create policy "teachers view their own assignments"
on public.teacher_assignments for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and teacher_user_id = (select auth.uid())
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'teacher'
);

-- Teachers may see only students enrolled in a subject assigned to them for that class.
drop policy if exists "teachers can view school students" on public.students;
create policy "teachers can view assigned students"
on public.students for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'teacher'
  and exists (
    select 1 from public.student_subjects ss
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
    where ss.student_id = students.id
      and ss.school_id = students.school_id
      and ta.class_name = students.class_name
  )
);

-- Student enrollment is managed by the School Admin, not teachers.
drop policy if exists "teachers can add students to their school" on public.students;
drop policy if exists "teachers can update school students" on public.students;

-- Attendance is available to teachers only for students in their assigned class/subject cohort.
drop policy if exists "teachers can view school attendance" on public.attendance;
drop policy if exists "teachers can record school attendance" on public.attendance;
drop policy if exists "teachers can update school attendance" on public.attendance;
create policy "teachers view assigned student attendance"
on public.attendance for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    where s.id = attendance.student_id and s.school_id = attendance.school_id
  )
);
create policy "teachers record assigned student attendance"
on public.attendance for insert to authenticated
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and recorded_by = (select auth.uid())
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    where s.id = attendance.student_id and s.school_id = attendance.school_id
  )
);
create policy "teachers update assigned student attendance"
on public.attendance for update to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    where s.id = attendance.student_id and s.school_id = attendance.school_id
  )
)
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and recorded_by = (select auth.uid())
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    where s.id = attendance.student_id and s.school_id = attendance.school_id
  )
);

-- Lesson notes must match the teacher's assigned class and subject.
drop policy if exists "teachers can view school lesson notes" on public.lesson_notes;
drop policy if exists "teachers can create school lesson notes" on public.lesson_notes;
drop policy if exists "teachers can update school lesson notes" on public.lesson_notes;
create policy "teachers view assigned lesson notes"
on public.lesson_notes for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.teacher_assignments ta
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where ta.teacher_user_id = (select auth.uid())
      and ta.school_id = lesson_notes.school_id
      and ta.class_name = lesson_notes.class_name
      and sub.subject_name = lesson_notes.subject
  )
);
create policy "teachers add assigned lesson notes"
on public.lesson_notes for insert to authenticated
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and created_by = (select auth.uid())
  and exists (
    select 1 from public.teacher_assignments ta
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where ta.teacher_user_id = (select auth.uid())
      and ta.school_id = lesson_notes.school_id
      and ta.class_name = lesson_notes.class_name
      and sub.subject_name = lesson_notes.subject
  )
);
create policy "teachers update assigned lesson notes"
on public.lesson_notes for update to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.teacher_assignments ta
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where ta.teacher_user_id = (select auth.uid())
      and ta.school_id = lesson_notes.school_id
      and ta.class_name = lesson_notes.class_name
      and sub.subject_name = lesson_notes.subject
  )
)
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and created_by = (select auth.uid())
  and exists (
    select 1 from public.teacher_assignments ta
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where ta.teacher_user_id = (select auth.uid())
      and ta.school_id = lesson_notes.school_id
      and ta.class_name = lesson_notes.class_name
      and sub.subject_name = lesson_notes.subject
  )
);

-- Academic results must belong to a student enrolled in the assigned subject/class.
drop policy if exists "teachers can view school results" on public.academic_results;
drop policy if exists "teachers can add school results" on public.academic_results;
drop policy if exists "teachers can update school results" on public.academic_results;
create policy "teachers view assigned academic results"
on public.academic_results for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where s.id = academic_results.student_id
      and s.school_id = academic_results.school_id
      and sub.subject_name = academic_results.subject
  )
);
create policy "teachers add assigned academic results"
on public.academic_results for insert to authenticated
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and recorded_by = (select auth.uid())
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where s.id = academic_results.student_id
      and s.school_id = academic_results.school_id
      and sub.subject_name = academic_results.subject
  )
);
create policy "teachers update assigned academic results"
on public.academic_results for update to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where s.id = academic_results.student_id
      and s.school_id = academic_results.school_id
      and sub.subject_name = academic_results.subject
  )
)
with check (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and recorded_by = (select auth.uid())
  and exists (
    select 1 from public.students s
    join public.student_subjects ss on ss.student_id = s.id and ss.school_id = s.school_id
    join public.teacher_assignments ta
      on ta.school_subject_id = ss.school_subject_id
     and ta.school_id = ss.school_id
     and ta.teacher_user_id = (select auth.uid())
     and ta.class_name = s.class_name
    join public.school_subjects sub on sub.id = ta.school_subject_id and sub.school_id = ta.school_id
    where s.id = academic_results.student_id
      and s.school_id = academic_results.school_id
      and sub.subject_name = academic_results.subject
  )
);
