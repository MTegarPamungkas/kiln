# Secrets in client apps

`--dart-define` stores values in the application binary. Anyone who has the
binary can extract those values.

The rules:

- Do not store service role keys, private keys, or server passwords in a client
  application's env.
- Store only values the client is allowed to know, for example API URLs and
  public keys.
- `api_key` in this extension is marked secret so it does not appear in
  logs/debug output, not so it is safe from extraction.
- Sensitive operations must run on a server or backend such as Appwrite,
  Firebase, or Supabase with access rules.
