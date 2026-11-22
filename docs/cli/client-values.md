# Client values from build variables

Bundled analytics, crash reporting and Supabase prompts accept `env:NAME` for
their marked values. The reference is saved unchanged; Kiln does not read a
process environment variable or resolve its value while rendering.

```sh
kiln setup analytics --answer api_key=env:CLIENT_ANALYTICS_KEY --yes
kiln setup crash_report --answer dsn=env:CLIENT_SENTRY_DSN --yes
kiln setup supabase --answer anon_key=env:CLIENT_SUPABASE_KEY --yes
```

The generated configuration uses constant `String.fromEnvironment('NAME')`.
Supply the client values to Flutter when running or building the application,
for example through your ignored build-variable JSON file:

```sh
flutter run --dart-define-from-file=client-values.local.json
flutter build apk --dart-define-from-file=client-values.local.json
```

Add that file to your application's `.gitignore` before creating it. Its JSON
keys must match the names in the references. Flutter build defines are
compile-time values; setting an ordinary shell environment variable alone does
not provide them.

An absent define yields an empty string. Analytics and crash reporting then use
their existing defaults-only/disabled behavior. Supabase reports missing client
configuration through its support/config validation. These mechanisms keep
values out of tracked setup files; values used in a Flutter client remain
extractable from the resulting application. Server or service-role credentials
must remain on a backend.

Existing literal answers continue to work. To migrate one, rerun `kiln setup`
with an `env:NAME` reference, rebuild the app with the corresponding define, and
review the diff. Previously generated files, local transaction backups and Git
history can still contain the old literal; replacing an answer does not erase
historical copies.

## Extension authors

For a string prompt marked `secret` (or `type: secret`), `buildTemplateVars`
provides a derived `<prompt>_dart` expression. Render that variable with triple
braces **without quotes** in Dart code. Literal answers become escaped Dart
strings, and `env:NAME` becomes a constant `String.fromEnvironment` expression.
Names must match `[A-Za-z_][A-Za-z0-9_]*`; malformed references are rejected
without echoing a candidate value. The ordinary prompt variable remains the
reference for compatibility with non-Dart templates. Third-party bricks must
adopt the derived expression before advertising build-variable support.
