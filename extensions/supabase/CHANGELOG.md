# Changelog

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
