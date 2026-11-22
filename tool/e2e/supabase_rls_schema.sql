-- Acceptance schema for the local Supabase RLS check (K04).
--
--   docker exec -i supabase_db_<project> psql -U postgres -v ON_ERROR_STOP=1 \
--     < tool/e2e/supabase_rls_schema.sql
--
-- Two policies are deliberately different so a test can separate "no rows
-- because of RLS" from "no rows because the table is empty":
--
--   * public.notes         - owner-only read/write (auth.uid() = user_id)
--   * public.public_notes  - anyone signed in can read, only the owner writes

create table if not exists public.notes (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

alter table public.notes enable row level security;
alter table public.notes force row level security;

drop policy if exists notes_select_own on public.notes;
create policy notes_select_own on public.notes
  for select to authenticated
  using (auth.uid() = user_id);

drop policy if exists notes_insert_own on public.notes;
create policy notes_insert_own on public.notes
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists notes_update_own on public.notes;
create policy notes_update_own on public.notes
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists notes_delete_own on public.notes;
create policy notes_delete_own on public.notes
  for delete to authenticated
  using (auth.uid() = user_id);

create table if not exists public.public_notes (
  id bigint generated always as identity primary key,
  user_id uuid not null default auth.uid() references auth.users (id) on delete cascade,
  body text not null,
  created_at timestamptz not null default now()
);

alter table public.public_notes enable row level security;
alter table public.public_notes force row level security;

drop policy if exists public_notes_select_all on public.public_notes;
create policy public_notes_select_all on public.public_notes
  for select to authenticated
  using (true);

drop policy if exists public_notes_insert_own on public.public_notes;
create policy public_notes_insert_own on public.public_notes
  for insert to authenticated
  with check (auth.uid() = user_id);

drop policy if exists public_notes_update_own on public.public_notes;
create policy public_notes_update_own on public.public_notes
  for update to authenticated
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists public_notes_delete_own on public.public_notes;
create policy public_notes_delete_own on public.public_notes
  for delete to authenticated
  using (auth.uid() = user_id);

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.notes to authenticated;
grant select on public.public_notes to authenticated;
grant insert, update, delete on public.public_notes to authenticated;
