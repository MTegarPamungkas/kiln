# Set up Appwrite

Use this flow to install the backend, configure the client, and test your first
sign-in. You need an Appwrite project; Kiln does not create cloud resources.

## Install and configure

From a Kiln application:

```bash
kiln add appwrite
kiln setup appwrite
kiln doctor
```

The setup wizard asks for the API endpoint, project ID, database ID, and bucket
ID. Copy them from your Appwrite Console. Press Enter to keep a valid saved
value; the demo project ID must be replaced. The default database and bucket
names are usable only if those resources exist in your project.

To provide values without prompts:

```bash
kiln setup appwrite --yes \
  --answer endpoint=https://api.example.com/v1 \
  --answer project_id=my_project \
  --answer database_id=my_database \
  --answer bucket_id=my_bucket
```

You can also qualify an answer, for example
`--answer appwrite.project_id=my_project`. Explicit answers replace saved
values; omitted values keep their saved settings or defaults.

These four settings are public client configuration. Setup does not ask for
or accept a server API key. It saves the settings in `kiln.yaml`, regenerates
the installed Appwrite source, and updates the ownership hashes together.

## Preview or change settings later

```bash
kiln setup appwrite --answer project_id=another_project --dry-run --json
kiln setup appwrite --answer project_id=another_project --yes
```

The preview renders and checks the proposed setup without writing project
files. Applying it runs `pub get` and analysis by default. A failed verification
restores managed files, settings, and `pubspec.lock`. Use `--no-verify` only
when you intend to run those checks separately.

Setup requires the installed Appwrite version to match the CLI's bundled
version. It refuses to replace modified extension files. Back up customizations
and restore the generated files before reconfiguring. Existing features and
dependent extensions remain installed. You can undo the completed setup with
`kiln rollback` before making further edits.

## Complete the console setup

1. Add your app platforms using their actual application IDs, bundle IDs, or
   web hostnames.
2. Enable email/password authentication for the sign-in flow.
3. If using database or file features, create the configured database and
   bucket and define their schema and permissions.
4. If using OAuth, enable the chosen providers. Configure app deep links for
   authentication redirects, password reset, and email verification.

See the extension's [Appwrite setup guide](../../extensions/appwrite/docs/appwrite-setup.md)
for platform, redirect, and self-hosted development details.

`kiln doctor` reports `setup.appwrite` as failed when required local settings
are missing, invalid, or still use the demo project. It suggests the exact
setup command to run. `--fix` does not invent project IDs or credentials.

A locally configured result validates saved client settings. It does not prove
that the server is reachable, resources exist, or platform and permission
settings are correct. No server connection is made by setup or these doctor
checks. JSON setup output includes `connection_checked: false`.

## Test sign-in through Gate

In a widget below `KilnApp`, read the Gate from the app's `RegistryScope` and
use the email and password collected by your form:

```dart
final gate = RegistryScope.read<Gate>(context);
final result = await gate.signIn(email: email, password: password);
result.fold(
  ok: (session) => print('Signed in: ${session.userId}'),
  err: (failure) => print('${failure.code}: ${failure.message}'),
);
```

Import `package:kiln_core/kiln_core.dart` and your app's
`lib/app/registry_scope.dart`. Use an existing test account, or create one
through `gate.signUp(...)`. Your application owns form state, error messages,
and navigation.
