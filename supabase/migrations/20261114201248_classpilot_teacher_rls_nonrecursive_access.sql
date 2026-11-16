create schema if not exists private;
revoke all on schema private from public;
grant usage on schema private to authenticated;

create or replace function private.teacher_can_access_student(
  _student_id uuid,
  _school_id uuid,
  _school_subject_id uuid default null,
  _subject_name text default null
)
returns boolean
language sql
stable
security definer
set search_path = pg_catalog, public, auth
as $$
  select
    auth.uid() is not null
    and (auth.jwt() -> 'app_metadata' ->> 'role') = 'teacher'
    and (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid = _school_id
    and exists (
      select 1
      from public.students s
      join public.student_subjects ss
        on ss.student_id = s.id and ss.school_id = s.school_id
      join public.teacher_assignments ta
        on ta.school_subject_id = ss.school_subject_id
       and ta.school_id = ss.school_id
       and ta.teacher_user_id = auth.uid()
       and ta.class_name = s.class_name
      join public.school_subjects sub
        on sub.id = ss.school_subject_id and sub.school_id = ss.school_id
      where s.id = _student_id
        and s.school_id = _school_id
        and (_school_subject_id is null or ss.school_subject_id = _school_subject_id)
        and (_subject_name is null or sub.subject_name = _subject_name)
    );
$$;

revoke all on function private.teacher_can_access_student(uuid, uuid, uuid, text) from public, anon;
grant execute on function private.teacher_can_access_student(uuid, uuid, uuid, text) to authenticated;

drop policy if exists "teachers view assigned student subject enrollment" on public.student_subjects;
create policy "teachers view assigned student subject enrollment"
on public.student_subjects for select to authenticated
using (private.teacher_can_access_student(student_id, school_id, school_subject_id, null));

drop policy if exists "teachers can view assigned students" on public.students;
create policy "teachers can view assigned students"
on public.students for select to authenticated
using (private.teacher_can_access_student(id, school_id, null, null));

drop policy if exists "teachers view assigned student attendance" on public.attendance;
create policy "teachers view assigned student attendance"
on public.attendance for select to authenticated
using (private.teacher_can_access_student(student_id, school_id, null, null));

drop policy if exists "teachers record assigned student attendance" on public.attendance;
create policy "teachers record assigned student attendance"
on public.attendance for insert to authenticated
with check (
  recorded_by = (select auth.uid())
  and private.teacher_can_access_student(student_id, school_id, null, null)
);

drop policy if exists "teachers update assigned student attendance" on public.attendance;
create policy "teachers update assigned student attendance"
on public.attendance for update to authenticated
using (private.teacher_can_access_student(student_id, school_id, null, null))
with check (
  recorded_by = (select auth.uid())
  and private.teacher_can_access_student(student_id, school_id, null, null)
);

drop policy if exists "teachers view assigned academic results" on public.academic_results;
create policy "teachers view assigned academic results"
on public.academic_results for select to authenticated
using (private.teacher_can_access_student(student_id, school_id, null, subject));

drop policy if exists "teachers add assigned academic results" on public.academic_results;
create policy "teachers add assigned academic results"
on public.academic_results for insert to authenticated
with check (
  recorded_by = (select auth.uid())
  and private.teacher_can_access_student(student_id, school_id, null, subject)
);

drop policy if exists "teachers update assigned academic results" on public.academic_results;
create policy "teachers update assigned academic results"
on public.academic_results for update to authenticated
using (private.teacher_can_access_student(student_id, school_id, null, subject))
with check (
  recorded_by = (select auth.uid())
  and private.teacher_can_access_student(student_id, school_id, null, subject)
);
