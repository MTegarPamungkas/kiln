# Row level security

`RemoteDatabase` mengirim request sebagai user yang sedang masuk, jadi RLS
adalah satu-satunya lapisan yang membatasi data. Anon key hanya memberi akses
sesuai policy.

## Tabel dokumen

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

## Policy untuk pemilik baris

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

Dengan policy ini:

- `read` untuk baris milik user lain menghasilkan `null`, bukan error, karena
  `SupabaseRemoteDatabase` memakai `maybeSingle()`.
- `update` dan `delete` untuk baris yang tidak terlihat menghasilkan
  `Failure(remote_database.not_found)`.
- `insert` dengan `owner_id` orang lain gagal dengan
  `Failure(remote_database.query_failed)` berkategori `authorization`.

## Storage

Policy storage mengikuti folder per user:

```sql
create policy "avatars_owner_read"
  on storage.objects for select
  using (bucket_id = 'public' and owner = auth.uid());

create policy "avatars_owner_write"
  on storage.objects for insert
  with check (bucket_id = 'public' and owner = auth.uid());
```

`FileStorage.delete` dan `upload` memakai user yang sama, jadi policy `delete`
dan `update` perlu ditambahkan bila aplikasi mengganti berkas dengan
`upsert`.

## Realtime

RLS juga berlaku untuk realtime. Agar `watch` menerima perubahan, tabel harus
masuk publikasi `supabase_realtime`:

```sql
alter publication supabase_realtime add table public.tasks;
```

User hanya menerima perubahan baris yang lolos policy `select`.
