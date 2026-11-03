# Changelog

## 0.1.3

- Fix signed storage URLs: Supabase returns `/object/sign/...`, which must be
  resolved under `/storage/v1` instead of the project root.

## 0.1.2

- Add `SupabaseSupport` and prepare the client during bootstrap.
- Missing or invalid configuration is reported as `notConfigured`; client,
  session restore, and link handler failures are recorded as `unavailable`
  instead of failing startup.

## 0.1.1

- Template the generated config test with the prompted URL and schema so it
  passes for self-hosted and local Supabase stacks.

## 0.1.0

- Initial Supabase Auth repository, social sign-in with ID token or OAuth,
  account management, token provider, session bridge, and email/OAuth link
  handler.
- PostgREST query mapping for every `RemoteFilterOperator`, ordered paging, and
  CRUD with `remote_database.not_found` reporting.
- Realtime `watch` that emits the current row before changes, and storage with
  signed URLs, progress completion, and `file.not_found` mapping.
