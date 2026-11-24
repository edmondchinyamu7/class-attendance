-- ClassPilot starter schema for Neon Postgres.
-- Apply only to a NEW Neon database. This is separate from the historical Supabase migrations.
create extension if not exists pgcrypto;

create table if not exists schools (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  school_type text not null check (school_type in ('government','private')),
  has_boarding boolean not null default false,
  has_day boolean not null default true,
  created_at timestamptz not null default now(),
  check (has_boarding or has_day)
);

create table if not exists user_profiles (
  id uuid primary key,
  school_id uuid not null references schools(id) on delete cascade,
  full_name text not null,
  role text not null check (role in ('admin','bursar','teacher','parent')),
  phone text,
  created_at timestamptz not null default now(),
  unique (id, school_id)
);

create table if not exists students (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  admission_number text not null,
  full_name text not null,
  gender text not null check (gender in ('Male','Female','Other')),
  date_of_birth date,
  form smallint not null check (form between 1 and 4),
  stream text not null default 'A',
  student_type text not null check (student_type in ('boarding','day')),
  parent_name text,
  parent_phone text,
  village text,
  district text,
  previous_school text,
  photo_url text,
  active boolean not null default true,
  created_at timestamptz not null default now(),
  unique (school_id, admission_number),
  unique (id, school_id)
);

create table if not exists parent_student_links (
  school_id uuid not null references schools(id) on delete cascade,
  parent_user_id uuid not null,
  student_id uuid not null,
  created_at timestamptz not null default now(),
  primary key (parent_user_id, student_id),
  foreign key (parent_user_id, school_id) references user_profiles(id, school_id) on delete cascade,
  foreign key (student_id, school_id) references students(id, school_id) on delete cascade
);

create table if not exists fee_structures (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  school_type text not null check (school_type in ('government','private')),
  student_type text not null check (student_type in ('boarding','day','all')),
  fee_name text not null,
  amount_mwk bigint not null check (amount_mwk >= 0),
  academic_year integer not null,
  term smallint not null check (term between 1 and 3)
);

create table if not exists fee_payments (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null,
  amount_mwk bigint not null check (amount_mwk > 0),
  payment_method text not null check (payment_method in ('cash','airtel_money','mpamba','bank')),
  reference_number text,
  received_by uuid,
  paid_at timestamptz not null default now(),
  foreign key (student_id, school_id) references students(id, school_id) on delete cascade
);

create table if not exists subjects (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  name text not null,
  unique (school_id, name),
  unique (id, school_id)
);

create table if not exists student_results (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null,
  subject_id uuid not null,
  academic_year integer not null,
  term smallint not null check (term between 1 and 3),
  marks numeric(5,2) not null check (marks between 0 and 100),
  grade text,
  points smallint check (points between 1 and 9),
  published_at timestamptz,
  entered_by uuid,
  foreign key (student_id, school_id) references students(id, school_id) on delete cascade,
  foreign key (subject_id, school_id) references subjects(id, school_id) on delete cascade,
  unique (student_id, subject_id, academic_year, term)
);

create table if not exists attendance (
  id uuid primary key default gen_random_uuid(),
  school_id uuid not null references schools(id) on delete cascade,
  student_id uuid not null,
  attendance_date date not null,
  status text not null check (status in ('present','absent','late')),
  marked_by uuid,
  created_at timestamptz not null default now(),
  foreign key (student_id, school_id) references students(id, school_id) on delete cascade,
  unique (student_id, attendance_date)
);

create index if not exists students_school_form_idx on students(school_id, form, stream);
create index if not exists payments_school_student_idx on fee_payments(school_id, student_id, paid_at desc);
create index if not exists results_school_student_idx on student_results(school_id, student_id, academic_year, term);
create index if not exists attendance_school_date_idx on attendance(school_id, attendance_date);
