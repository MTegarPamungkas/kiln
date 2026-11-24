# Row level security

`RemoteDatabase` sends requests as the signed-in user, so RLS is the only layer
that restricts data. The anon key only grants access according to the policies.

## Document table

```sql
create table public.tasks (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null default auth.uid(),
  title text not null,
  done boolean not null default false,
  created_at timestamptz not null default now()
);

alter table public.tasks enable row level security;
```

## Policies for the row owner

```sql
create policy "tasks_select_own"
  on public.tasks for select
  using (owner_id = auth.uid());

create policy "tasks_insert_own"
  on public.tasks for insert
  with check (owner_id = auth.uid());

create policy "tasks_update_own"
  on public.tasks for update
  using (owner_id = auth.uid())
  with check (owner_id = auth.uid());

create policy "tasks_delete_own"
  on public.tasks for delete
  using (owner_id = auth.uid());
```

With these policies:

- `read` for another user's row returns `null` rather than an error, because
  `SupabaseRemoteDatabase` uses `maybeSingle()`.
- `update` and `delete` for rows that are not visible return
  `Failure(remote_database.not_found)`.
- `insert` with someone else's `owner_id` fails with
  `Failure(remote_database.query_failed)` in the `authorization` category.

## Storage

Storage policies follow a per-user folder:

```sql
create policy "avatars_owner_read"
  on storage.objects for select
  using (bucket_id = 'public' and owner = auth.uid());

create policy "avatars_owner_write"
  on storage.objects for insert
  with check (bucket_id = 'public' and owner = auth.uid());
```

`FileStorage.delete` and `upload` use the same user, so `delete` and `update`
policies need to be added if the app replaces files with `upsert`.

## Realtime

RLS also applies to realtime. For `watch` to receive changes, the table must be
part of the `supabase_realtime` publication:

```sql
alter publication supabase_realtime add table public.tasks;
```

The user only receives changes to rows that pass the `select` policy.

## Verify the policies locally

A local stack can prove the matrix without a real project:

```bash
supabase start
docker exec -i supabase_db_<project> psql -U postgres -v ON_ERROR_STOP=1 \
  < tool/e2e/supabase_rls_schema.sql

export KILN_SUPABASE_URL=http://127.0.0.1:54321
export KILN_SUPABASE_ANON_KEY=<anon key from `supabase status -o env`>
dart run tool/e2e/supabase_local_rls_probe.dart
```

The probe signs up two users and checks owner-only read/write, cross-user
select/update/delete, a forged owner on insert, and anonymous access (16 checks).
The rendered extension suite carries the same matrix as an opt-in test: set
`KILN_SUPABASE_LOCAL_RLS=1` plus `KILN_SUPABASE_LOCAL_URL` and
`KILN_SUPABASE_LOCAL_ANON_KEY`, then run
`dart run tool/verify_extensions.dart --only supabase --analyze --test`. Without
those variables the test skips, so generated apps and CI stay offline.

The browser OAuth path can be exercised the same way with a local OIDC provider:
see the probe fixtures in `tool/e2e/` and the recorded run in
[the acceptance report](../../../docs/audit/supabase-local-rls-2026-11-22.md).
