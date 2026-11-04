-- Kauthar School initial schema. Run in Supabase SQL Editor.
create extension if not exists pgcrypto;

create type public.app_role as enum ('super_admin','admin','teacher','student','parent');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text not null default '',
  phone text unique,
  role public.app_role not null default 'student',
  created_at timestamptz not null default now()
);

create table public.classes (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  stage text,
  academic_year text not null default '2026-2027',
  created_at timestamptz not null default now()
);

create table public.students (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete set null,
  full_name text not null,
  phone text,
  class_id uuid references public.classes(id) on delete set null,
  parent_profile_id uuid references public.profiles(id) on delete set null,
  parent_name text,
  parent_phone text,
  photo_path text,
  created_at timestamptz not null default now()
);

create table public.teachers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete cascade,
  full_name text not null,
  phone text,
  created_at timestamptz not null default now()
);

create table public.parents (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid unique references public.profiles(id) on delete cascade,
  full_name text not null,
  phone text,
  created_at timestamptz not null default now()
);

create table public.subjects (
  id uuid primary key default gen_random_uuid(),
  name text not null unique,
  created_at timestamptz not null default now()
);

create table public.teacher_assignments (
  id uuid primary key default gen_random_uuid(),
  teacher_profile_id uuid not null references public.profiles(id) on delete cascade,
  class_id uuid not null references public.classes(id) on delete cascade,
  subject_id uuid references public.subjects(id) on delete cascade,
  unique(teacher_profile_id,class_id,subject_id)
);

create table public.grades (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  subject_id uuid not null references public.subjects(id) on delete cascade,
  exam_name text not null,
  score numeric(5,2) not null check (score >= 0 and score <= 100),
  academic_year text not null default '2026-2027',
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.attendance (
  id uuid primary key default gen_random_uuid(),
  student_id uuid not null references public.students(id) on delete cascade,
  attendance_date date not null default current_date,
  status text not null check (status in ('present','absent','late','excused')),
  note text,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now(),
  unique(student_id,attendance_date)
);

create table public.announcements (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  body text not null default '',
  image_path text,
  published boolean not null default true,
  created_by uuid references public.profiles(id),
  created_at timestamptz not null default now()
);

create table public.news (
  id uuid primary key default gen_random_uuid(),
  title text not null,
  active boolean not null default true,
  created_at timestamptz not null default now()
);

create table public.top_students (
  id uuid primary key default gen_random_uuid(),
  student_id uuid references public.students(id) on delete cascade,
  full_name text not null,
  class_name text,
  average numeric(5,2) check (average >= 0 and average <= 100),
  photo_path text,
  academic_year text not null default '2026-2027',
  created_at timestamptz not null default now()
);

create table public.school_settings (
  id boolean primary key default true check (id),
  school_name text not null default 'مدرسة كوثر الأهلية المختلطة',
  slogan text not null default 'مدرسة كوثر: بيت العلم والإبداع',
  academic_year text not null default '2026-2027',
  logo_path text,
  created_at timestamptz not null default now()
);
insert into public.school_settings(id) values (true) on conflict do nothing;

create table public.permissions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  permission_key text not null,
  allowed boolean not null default false,
  unique(profile_id,permission_key)
);

create table public.parent_students (
  parent_profile_id uuid not null references public.profiles(id) on delete cascade,
  student_id uuid not null references public.students(id) on delete cascade,
  primary key(parent_profile_id,student_id)
);

create or replace function public.current_role()
returns public.app_role
language sql stable security definer
set search_path = public
as $$
  select role from public.profiles where id = auth.uid()
$$;

create or replace function public.is_admin()
returns boolean language sql stable security definer set search_path=public as $$
  select coalesce(public.current_role() in ('super_admin','admin'),false)
$$;

create or replace function public.is_teacher_for_student(p_student uuid)
returns boolean language sql stable security definer set search_path=public as $$
  select exists (
    select 1 from public.students s
    join public.teacher_assignments ta on ta.class_id=s.class_id
    where s.id=p_student and ta.teacher_profile_id=auth.uid()
  )
$$;

alter table public.profiles enable row level security;
alter table public.classes enable row level security;
alter table public.students enable row level security;
alter table public.teachers enable row level security;
alter table public.parents enable row level security;
alter table public.subjects enable row level security;
alter table public.teacher_assignments enable row level security;
alter table public.grades enable row level security;
alter table public.attendance enable row level security;
alter table public.announcements enable row level security;
alter table public.news enable row level security;
alter table public.top_students enable row level security;
alter table public.school_settings enable row level security;
alter table public.permissions enable row level security;
alter table public.parent_students enable row level security;

create policy "profiles self or admin read" on public.profiles for select to authenticated
using (id=auth.uid() or public.is_admin());
create policy "admin manage profiles" on public.profiles for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create policy "authenticated read classes" on public.classes for select to authenticated using (true);
create policy "admin manage classes" on public.classes for all to authenticated using(public.is_admin()) with check(public.is_admin());

create policy "student self parent or admin read" on public.students for select to authenticated
using (profile_id=auth.uid() or parent_profile_id=auth.uid() or exists(select 1 from public.parent_students ps where ps.student_id=id and ps.parent_profile_id=auth.uid()) or public.is_admin()
or (public.current_role()='teacher' and exists(select 1 from public.teacher_assignments ta where ta.class_id=students.class_id and ta.teacher_profile_id=auth.uid())));
create policy "admin manage students" on public.students for all to authenticated using(public.is_admin()) with check(public.is_admin());

create policy "teachers read self or admin" on public.teachers for select to authenticated
using(profile_id=auth.uid() or public.is_admin());
create policy "admin manage teachers" on public.teachers for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "parents read self or admin" on public.parents for select to authenticated using(profile_id=auth.uid() or public.is_admin());
create policy "admin manage parents" on public.parents for all to authenticated using(public.is_admin()) with check(public.is_admin());

create policy "authenticated read subjects" on public.subjects for select to authenticated using(true);
create policy "admin manage subjects" on public.subjects for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "teacher read own assignments or admin" on public.teacher_assignments for select to authenticated using(teacher_profile_id=auth.uid() or public.is_admin());
create policy "admin manage assignments" on public.teacher_assignments for all to authenticated using(public.is_admin()) with check(public.is_admin());

create policy "grades scoped read" on public.grades for select to authenticated using(
 public.is_admin() or exists(select 1 from public.students s where s.id=grades.student_id and (s.profile_id=auth.uid() or s.parent_profile_id=auth.uid()))
 or exists(select 1 from public.parent_students ps where ps.student_id=grades.student_id and ps.parent_profile_id=auth.uid())
 or (public.current_role()='teacher' and public.is_teacher_for_student(student_id))
);
create policy "admin or assigned teacher writes grades" on public.grades for insert to authenticated
with check(public.is_admin() or (public.current_role()='teacher' and public.is_teacher_for_student(student_id) and created_by=auth.uid()));
create policy "admin or assigned teacher updates grades" on public.grades for update to authenticated
using(public.is_admin() or (public.current_role()='teacher' and public.is_teacher_for_student(student_id)))
with check(public.is_admin() or (public.current_role()='teacher' and public.is_teacher_for_student(student_id)));
create policy "admin deletes grades" on public.grades for delete to authenticated using(public.is_admin());

create policy "attendance scoped read" on public.attendance for select to authenticated using(
 public.is_admin() or exists(select 1 from public.students s where s.id=attendance.student_id and (s.profile_id=auth.uid() or s.parent_profile_id=auth.uid()))
 or exists(select 1 from public.parent_students ps where ps.student_id=attendance.student_id and ps.parent_profile_id=auth.uid())
 or (public.current_role()='teacher' and public.is_teacher_for_student(student_id))
);
create policy "admin or assigned teacher attendance insert" on public.attendance for insert to authenticated
with check(public.is_admin() or (public.current_role()='teacher' and public.is_teacher_for_student(student_id) and created_by=auth.uid()));
create policy "admin or assigned teacher attendance update" on public.attendance for update to authenticated
using(public.is_admin() or (public.current_role()='teacher' and public.is_teacher_for_student(student_id)))
with check(public.is_admin() or (public.current_role()='teacher' and public.is_teacher_for_student(student_id)));
create policy "admin deletes attendance" on public.attendance for delete to authenticated using(public.is_admin());

create policy "published announcements read" on public.announcements for select to authenticated using(published or public.is_admin());
create policy "admin manage announcements" on public.announcements for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "active news read" on public.news for select to authenticated using(active or public.is_admin());
create policy "admin manage news" on public.news for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "top students read" on public.top_students for select to authenticated using(true);
create policy "admin manage top students" on public.top_students for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "school settings read" on public.school_settings for select to authenticated using(true);
create policy "admin manage settings" on public.school_settings for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "permissions self or admin read" on public.permissions for select to authenticated using(profile_id=auth.uid() or public.is_admin());
create policy "admin manage permissions" on public.permissions for all to authenticated using(public.is_admin()) with check(public.is_admin());
create policy "parent links self or admin read" on public.parent_students for select to authenticated using(parent_profile_id=auth.uid() or public.is_admin());
create policy "admin manage parent links" on public.parent_students for all to authenticated using(public.is_admin()) with check(public.is_admin());

-- Storage: create a private bucket named school-media in Dashboard.
-- Keep uploaded files private; add narrowly-scoped storage.objects policies after deciding
-- whether each object is public school media or private student records.
