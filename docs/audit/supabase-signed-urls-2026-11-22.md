# Supabase signed-URL lifetimes on a local stack

Date: 2026-11-22 (Asia/Jakarta). Closes the remaining K11 item ("live provider
verification of the signed-URL lifetimes") for Supabase. Firebase needs no
provider round trip: `FirebaseFileStorage.url` rejects a non-null `expiresIn`
with a typed failure by policy, which its unit test already covers. No commit was
made.

## Setup

The disposable local stack from the RLS pass is reused:

```bash
cd .dart_tool/k04_supabase
supabase start
supabase status -o env   # API_URL, ANON_KEY, SERVICE_ROLE_KEY
```

Both keys are the CLI's shared local defaults. The service key creates the
disposable bucket, uploads the object and signs the links; the probe also checks
that the anonymous key cannot sign without a policy. Policy-level authorization
for `storage.objects` is not the subject of this pass — the lifetime is.

## Probe (8 checks)

`tool/e2e/supabase_signed_url_probe.dart` drives the Storage API directly, so it
needs no rendered app and no Appium/device:

```powershell
$env:KILN_SUPABASE_URL = 'http://127.0.0.1:54321'
$env:KILN_SUPABASE_ANON_KEY = '<anon key>'
$env:KILN_SUPABASE_SERVICE_KEY = '<service_role key>'
dart run tool/e2e/supabase_signed_url_probe.dart
```

| Check | Result |
| --- | --- |
| Service role creates a private bucket | ok |
| Service role uploads an object | ok |
| A 3-second link is issued | ok |
| The short link serves the object before expiry | ok |
| The short link is rejected after expiry | ok |
| A one-hour link is issued | ok |
| The one-hour link serves the object | ok |
| The anonymous key alone cannot sign | ok |

Result: `8 checks, 0 failed - signed URL lifetimes hold`. The probe creates a
uniquely named bucket per run and deletes the object and bucket afterwards.

## Rendered extension test (3 tests)

`extensions/supabase/brick/__brick__/test/extensions/supabase/supabase_signed_url_test.dart`
runs the same provider check through the `supabase` client that
`supabase_flutter` re-exports, and passes the returned relative link through the
extension's own `resolveSupabaseSignedUrl`. That covers the piece a raw probe
cannot: the `/storage/v1` prefix handling in production code.

```powershell
$env:KILN_SUPABASE_LOCAL_STORAGE = '1'
$env:KILN_SUPABASE_LOCAL_URL = 'http://127.0.0.1:54321'
$env:KILN_SUPABASE_LOCAL_ANON_KEY = '<anon key>'
$env:KILN_SUPABASE_LOCAL_SERVICE_KEY = '<service_role key>'
dart run tool/verify_extensions.dart --only supabase --analyze --test
```

Result: analyzed and tested green. Skips with a reason when the variables are
absent, so generated apps and CI stay offline.

## What this proves and what it does not

- Proves: Supabase Storage issues a link for the requested lifetime, serves the
  object while it is valid, rejects it after expiry, and refuses to sign for an
  anonymous key with no storage policy. The extension's relative-URL resolution
  points at the real served path.
- Does not prove Firebase's live behaviour, because the fix is a local rejection:
  `url(expiresIn:)` never reaches the provider. No Firebase project is created.
- Signed links are bearer URLs: do not log them or store them beyond their
  lifetime. The probe prints only statuses and never the signed URL.

## Cleanup

`supabase stop --no-backup` removes the stack and the disposable bucket with it.
The probe's bucket is deleted in its `finally` block even when an assertion fails.
