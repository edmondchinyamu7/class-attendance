create table public.schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  created_at timestamptz not null default now()
);

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('teacher','parent')),
  school_id uuid not null references public.schools(id) on delete restrict,
  created_at timestamptz not null default now()
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_code text not null,
  full_name text not null,
  class_name text not null,
  phone text,
  parent_name text,
  parent_phone text,
  created_at timestamptz not null default now(),
  unique (school_id, student_code)
);

create table public.parent_student_links (
  parent_user_id uuid not null references auth.users(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (parent_user_id, student_id)
);

create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null,
  status text not null check (status in ('present','absent','late')),
  recorded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  unique (student_id, attendance_date)
);

create table public.lesson_notes (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  subject text not null,
  class_name text not null,
  topic text not null,
  resource_url text,
  instructions text,
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create table public.academic_results (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references public.schools(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  subject text not null,
  form text not null,
  term text not null,
  score numeric(5,2) not null check (score >= 0 and score <= 100),
  recorded_by uuid not null references auth.users(id),
  created_at timestamptz not null default now()
);

create index students_school_class_idx on public.students (school_id, class_name);
create index parent_student_links_student_idx on public.parent_student_links (student_id);
create index attendance_student_date_idx on public.attendance (student_id, attendance_date desc);
create index results_student_idx on public.academic_results (student_id);
create index lessons_school_class_idx on public.lesson_notes (school_id, class_name);

alter table public.schools enable row level security;
alter table public.profiles enable row level security;
alter table public.students enable row level security;
alter table public.parent_student_links enable row level security;
alter table public.attendance enable row level security;
alter table public.lesson_notes enable row level security;
alter table public.academic_results enable row level security;

grant select on public.schools, public.profiles, public.students, public.parent_student_links, public.attendance, public.lesson_notes, public.academic_results to authenticated;
grant insert, update, delete on public.students, public.attendance, public.lesson_notes, public.academic_results to authenticated;

create policy "school members can view their school"
on public.schools for select to authenticated
using (id::text = (select auth.jwt()->'app_metadata'->>'school_id'));

create policy "users can view their own profile"
on public.profiles for select to authenticated
using (id = (select auth.uid()));

create policy "teachers can view school students"
on public.students for select to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "parents can view linked students"
on public.students for select to authenticated
using (
  exists (
    select 1 from public.parent_student_links psl
    where psl.student_id = students.id
      and psl.parent_user_id = (select auth.uid())
  )
);

create policy "teachers can add students to their school"
on public.students for insert to authenticated
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "teachers can update school students"
on public.students for update to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
)
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "teachers can delete school students"
on public.students for delete to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "parents can view their own student links"
on public.parent_student_links for select to authenticated
using (parent_user_id = (select auth.uid()));

create policy "teachers can view school attendance"
on public.attendance for select to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "parents can view linked student attendance"
on public.attendance for select to authenticated
using (
  exists (
    select 1 from public.parent_student_links psl
    where psl.student_id = attendance.student_id
      and psl.parent_user_id = (select auth.uid())
  )
);

create policy "teachers can record school attendance"
on public.attendance for insert to authenticated
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
  and recorded_by = (select auth.uid())
);

create policy "teachers can update school attendance"
on public.attendance for update to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
)
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
  and recorded_by = (select auth.uid())
);

create policy "teachers can delete school attendance"
on public.attendance for delete to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "teachers can view school lesson notes"
on public.lesson_notes for select to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "parents can view linked class lesson notes"
on public.lesson_notes for select to authenticated
using (
  exists (
    select 1 from public.parent_student_links psl
    join public.students s on s.id = psl.student_id
    where psl.parent_user_id = (select auth.uid())
      and s.school_id = lesson_notes.school_id
      and s.class_name = lesson_notes.class_name
  )
);

create policy "teachers can create school lesson notes"
on public.lesson_notes for insert to authenticated
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
  and created_by = (select auth.uid())
);

create policy "teachers can update school lesson notes"
on public.lesson_notes for update to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
)
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
  and created_by = (select auth.uid())
);

create policy "teachers can delete school lesson notes"
on public.lesson_notes for delete to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "teachers can view school results"
on public.academic_results for select to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);

create policy "parents can view linked student results"
on public.academic_results for select to authenticated
using (
  exists (
    select 1 from public.parent_student_links psl
    where psl.student_id = academic_results.student_id
      and psl.parent_user_id = (select auth.uid())
  )
);

create policy "teachers can add school results"
on public.academic_results for insert to authenticated
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
  and recorded_by = (select auth.uid())
);

create policy "teachers can update school results"
on public.academic_results for update to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
)
with check (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
  and recorded_by = (select auth.uid())
);

create policy "teachers can delete school results"
on public.academic_results for delete to authenticated
using (
  school_id::text = (select auth.jwt()->'app_metadata'->>'school_id')
  and (select auth.jwt()->'app_metadata'->>'role') = 'teacher'
);
