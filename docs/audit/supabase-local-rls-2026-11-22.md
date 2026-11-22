# Supabase local stack: two-user RLS and browser OAuth

Date: 2026-11-22 (Asia/Jakarta). Closes the two remaining K04 acceptance items:
a local-stack two-user/RLS test and a real browser OAuth run. No commit or
deployment was made; the local stack, mock provider and probe app are disposable
fixtures under `.dart_tool/`.

Environment: Windows, Docker 29.9.2, Supabase CLI 3.0.0 (it reports 3.2.0
available), Flutter 3.47.9 / Dart 3.13.7, Chrome 157.0.8103.79, Playwright 1.64.1
(global npm install, `channel: 'chrome'`).

## Fixture

```bash
mkdir .dart_tool/k04_supabase && cd .dart_tool/k04_supabase
supabase init
# copy the acceptance schema in as a migration
cp ../../tool/e2e/supabase_rls_schema.sql \
   supabase/migrations/20261122000100_k04_rls.sql
supabase start
```

`supabase status -o env` prints the local `API_URL`, `ANON_KEY` and
`SERVICE_ROLE_KEY`. Those are the CLI's shared local defaults, not credentials
for any real project.

Schema ([`tool/e2e/supabase_rls_schema.sql`](../../tool/e2e/supabase_rls_schema.sql)):
`notes` is owner-only for select/insert/update/delete (`auth.uid() = user_id`);
`public_notes` is readable by every signed-in user but writable only by its
owner. Both use `default auth.uid()` so a client that does not name the owner
still gets the right one, and both are `force row level security`.

## RLS matrix (16 checks)

`tool/e2e/supabase_local_rls_probe.dart` signs up two users through GoTrue,
writes through PostgREST with each user's access token, and asserts the policy
matrix. It needs no rendered app, so it is the fast iteration loop.

```powershell
$env:KILN_SUPABASE_URL = 'http://127.0.0.1:54321'
$env:KILN_SUPABASE_ANON_KEY = '<anon key from supabase status>'
dart run tool/e2e/supabase_local_rls_probe.dart
```

Result: `16 checks, 0 failed - RLS matrix holds`.

| Check | Result |
| --- | --- |
| Two signups produce distinct users | ok |
| Alice inserts a note; row is stamped with alice as owner | ok |
| Alice reads her own note | ok |
| Bob reads zero rows for alice's note (200 with no rows, not an error) | ok |
| Bob update affects zero rows | ok |
| Bob delete affects zero rows | ok |
| Alice's note survives bob's delete with its original body | ok |
| Bob insert with `user_id = alice` is refused (WITH CHECK) | ok |
| Anonymous key reads no protected rows | ok |
| Anonymous insert is refused | ok |
| Public-read note inserted by alice is visible to bob | ok |
| Bob cannot update alice's public note | ok |
| Bob's delete leaves alice's public note intact | ok |
| Alice deletes her own note and it is gone | ok |

The anonymous select returns `200 []` rather than `401`: Supabase grants table
privileges to `anon` by default, so the refusal is the policy (no policy applies
to `anon`), not a privilege error. The probe accepts either shape and separately
requires the anonymous insert to be refused.

## Rendered extension suite

The same matrix ships as an opt-in test inside the extension:
`extensions/supabase/brick/__brick__/test/extensions/supabase/supabase_local_rls_test.dart`.
It talks to GoTrue and PostgREST directly because the point is the server-side
policy, which an SDK fake cannot prove. It skips with a reason unless:

```powershell
$env:KILN_SUPABASE_LOCAL_RLS = '1'
$env:KILN_SUPABASE_LOCAL_URL = 'http://127.0.0.1:54321'
$env:KILN_SUPABASE_LOCAL_ANON_KEY = '<anon key>'
dart run tool/verify_extensions.dart --only supabase --analyze --test
```

Evidence: the rendered suite analyzed and tested green with the variables set;
the five live tests passed. Without the variables the same five report skipped
(`All tests skipped`, no failure), so generated apps and CI stay offline.

`setUpAll` is guarded by the same flag: the group's hooks run even when every
test is skipped, and an unguarded hook would try to sign up against an empty URL.

## Browser OAuth

The browser run uses a real Chrome against the local stack. Google and Apple need
real credentials, so the stack registers a **local OIDC provider as the
`keycloak` provider**: GoTrue's keycloak adapter accepts a custom issuer URL, and
the mock implements the Keycloak endpoints GoTrue calls
(`/protocol/openid-connect/auth|token|certs|userinfo`, plus discovery).

Pieces:

| File | Role |
| --- | --- |
| [`tool/e2e/supabase_mock_oidc.mjs`](../../tool/e2e/supabase_mock_oidc.mjs) | Issues auth codes, signs an RS256 `id_token`, publishes JWKS; exposes `/hits` so the driver can prove it was used. |
| [`tool/e2e/serve_supabase_oauth_app.mjs`](../../tool/e2e/serve_supabase_oauth_app.mjs) | Serves the probe app and records its JSON event reports. |
| [`tool/e2e/run_supabase_oauth.mjs`](../../tool/e2e/run_supabase_oauth.mjs) | Playwright driver; one PASS/FAIL line per assertion. |
| `.dart_tool/k04_web_oauth` | Disposable Flutter web probe built with `supabase_flutter` and the same PKCE/detect-session options as `SupabaseClientProvider`. |

Stack configuration (`supabase/config.toml` in the fixture):

```toml
site_url = "http://127.0.0.1:8088"
additional_redirect_urls = ["http://127.0.0.1:8088", "http://localhost:8088"]

[auth.external.keycloak]
enabled = true
client_id = "kiln-local"
secret = "kiln-local-secret"
url = "http://192.168.1.5:8771"
redirect_uri = "http://127.0.0.1:54321/auth/v1/callback"
skip_nonce_check = true
```

The provider URL is the host's LAN address, not `127.0.0.1`: GoTrue runs inside
Docker, where `127.0.0.1` is the container. Docker Desktop on this machine also
does not resolve `host.docker.internal`, so the mock binds `0.0.0.0` and both the
container and the browser use the LAN IP. The mock's `--issuer` must equal that
URL or the `id_token` issuer will not match.

Run:

```powershell
node tool/e2e/supabase_mock_oidc.mjs --port 8771 --issuer http://192.168.1.5:8771
node tool/e2e/serve_supabase_oauth_app.mjs --port 8088
cd .dart_tool/k04_web_oauth
flutter build web --dart-define=SUPABASE_URL=http://127.0.0.1:54321 `
  --dart-define=SUPABASE_ANON_KEY=<anon key>
cd ../..
$env:NODE_PATH = (npm root -g)   # Playwright is a global install here
node tool/e2e/run_supabase_oauth.mjs --app http://127.0.0.1:8088/ --oidc http://127.0.0.1:8771
```

The probe app has no UI to click: on load it either completes the PKCE redirect
it was sent back with or starts the provider flow. It reports events to the host
instead of rendering text, because a CanvasKit page exposes no DOM text to the
driver.

Result: `15 checks, 0 failed - browser OAuth holds`.

| Check | Result |
| --- | --- |
| Probe reported the flow started and redirected to `keycloak` | ok |
| No provider or init error | ok |
| The redirect back exchanged for a session | ok |
| Session email is the OIDC user | ok |
| Session carries an access token | ok |
| PostgREST insert under the OAuth session succeeded | ok |
| The inserted row's owner equals the session user | ok |
| Mock provider received the authorize request | ok |
| Mock provider exchanged the code (id_token verified by GoTrue) | ok |
| App sent a PKCE S256 challenge to GoTrue (challenge ≥ 43 chars) | ok |
| Browser navigated through GoTrue to the provider | ok |
| Browser returned to the app with the probe redirect | ok |
| PKCE session persisted in browser storage (`sb-*-auth-token`) | ok |

One assertion was corrected during the run: PKCE is between the app and GoTrue,
so the challenge appears on the app's `/auth/v1/authorize` request, not on
GoTrue's provider request (that leg uses the client secret). The driver now
checks the former.

## What this does and does not prove

- Proves: GoTrue issues and validates sessions against a local OIDC provider in a
  real browser; the app's PKCE challenge, redirect, code exchange, session
  persistence, and a follow-up RLS-scoped PostgREST write all work end to end;
  two-user RLS holds on insert, select, update, delete, forged owner and
  anonymous access.
- Does not prove: a real Google or Apple exchange (the provider here is a local
  stand-in). The extension maps social sign-in to `google`/`apple`, so provider
  account linking stays with K25, which needs real provider credentials.
- The browser probe uses `supabase_flutter` with the same options as
  `SupabaseClientProvider` rather than the extension's own OAuth wrapper; the
  wrapper's prior-session guard is covered by `supabase_auth_test.dart` and is
  not re-exercised here.
- The LAN IP is environment-specific; a new network address requires updating
  both the mock `--issuer` and `config.toml`.

## Cleanup

`supabase stop --no-backup`, killing the two Node fixtures, and deleting
`.dart_tool/k04_supabase`, `.dart_tool/k04_web_oauth` and `.dart_tool/k04_oauth`
remove everything this run created. Nothing was written into tracked files
except this report, the test, the probe, the schema and the fixture scripts.
