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
