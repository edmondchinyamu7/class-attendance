alter table public.profiles
  drop constraint if exists profiles_role_check;

alter table public.profiles
  add constraint profiles_role_check
  check (role in ('school_admin', 'teacher', 'parent'));

alter table public.profiles
  add column if not exists phone text;

alter table public.schools
  add column if not exists email text,
  add column if not exists admin_user_id uuid references auth.users(id) on delete set null;

create unique index if not exists schools_email_lower_uidx
  on public.schools (lower(email))
  where email is not null;

create unique index if not exists schools_admin_user_id_uidx
  on public.schools (admin_user_id)
  where admin_user_id is not null;

-- School administrators can manage records belonging only to their own school.
drop policy if exists "school admins can view school students" on public.students;
create policy "school admins can view school students"
on public.students for select to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can add school students" on public.students;
create policy "school admins can add school students"
on public.students for insert to authenticated
with check (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can update school students" on public.students;
create policy "school admins can update school students"
on public.students for update to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
)
with check (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can delete school students" on public.students;
create policy "school admins can delete school students"
on public.students for delete to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can view school attendance" on public.attendance;
create policy "school admins can view school attendance"
on public.attendance for select to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can manage school attendance" on public.attendance;
create policy "school admins can manage school attendance"
on public.attendance for all to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
)
with check (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can view school lesson notes" on public.lesson_notes;
create policy "school admins can view school lesson notes"
on public.lesson_notes for select to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can manage school lesson notes" on public.lesson_notes;
create policy "school admins can manage school lesson notes"
on public.lesson_notes for all to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
)
with check (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can view school results" on public.academic_results;
create policy "school admins can view school results"
on public.academic_results for select to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);

drop policy if exists "school admins can manage school results" on public.academic_results;
create policy "school admins can manage school results"
on public.academic_results for all to authenticated
using (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
)
with check (
  school_id::text = (select auth.jwt() -> 'app_metadata' ->> 'school_id')
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);
