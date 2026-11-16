drop policy if exists "school admins can view school profiles" on public.profiles;
create policy "school admins can view school profiles"
on public.profiles for select to authenticated
using (
  school_id = (select (auth.jwt() -> 'app_metadata' ->> 'school_id')::uuid)
  and (select auth.jwt() -> 'app_metadata' ->> 'role') = 'school_admin'
);
