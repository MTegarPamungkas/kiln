# Supabase setup

This extension needs one Supabase project. All rendered values come from
`extension.yaml`; other values live in `SupabaseConfig.defaults`.

## 1. Get the URL and anon key

In the Supabase dashboard open **Project settings > API**:

- **Project URL** goes into the `url` prompt, for example
  `https://abcdefgh.supabase.co`.
- **anon (publishable) key** goes into the `anon_key` prompt.

Never use the **service role key** in the app. That key bypasses all RLS policies
and is for the server only.

## 2. PostgREST schema

The `schema` prompt determines the schema used by `RemoteDatabase` and realtime.
It defaults to `public`. If the tables live in another schema, expose that schema
in **Project settings > API > Exposed schemas**, then fill the prompt with its
name.

## 3. Typed configuration

`SupabaseConfig.defaults` is rendered to
`lib/extensions/supabase/supabase_config.dart`. Values that are often adjusted:

- `storageBucket` (default `public`) — the bucket for `FileStorage`.
- `authRedirectUrl` (default `kiln-auth://auth-callback`) — sent to Supabase for
  email confirmation, password reset, and OAuth.
- `signedUrlLifetime` (default 1 hour) — the validity period of
  `FileStorage.url`.
- `authTimeout` (default 5 minutes) — the limit for waiting for a session after
  OAuth.
- `usePkce` (default `true`) — the PKCE flow is required for mobile apps.
- `detectSessionInUri` (default `false`) — leave it off because the callback is
  read by `SupabaseLinkHandler` through the `DeepLinks` contract.

`SupabaseConfig.validate()` can be called early to make sure the URL, anon key,
schema, and redirect are valid. Error messages never contain the anon key.

## 4. Initialization

`SupabaseModule.ready` calls `SupabaseClientProvider.load()`, which creates the
client with `Supabase.initialize` (PKCE, auto refresh token, persistent session).
The client is shared by all gateways, so do not create a second Supabase client
in the app.

## 5. Storage bucket

`FileStorage` uses a single bucket. Create that bucket in **Storage**, then add
policies on `storage.objects` for the folders the app uses. `url()` always
returns a signed URL, so the bucket may be private.
