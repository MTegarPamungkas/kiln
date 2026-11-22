# Configure installed extensions

Every bundled extension supports the same setup flow. Install the capabilities
your app needs, review their settings, then run doctor:

```bash
kiln setup
kiln setup dio
kiln setup --all
kiln doctor
```

`kiln setup` lists the local configuration status of installed extensions.
`kiln setup <extension>` reviews one extension; names can be combined, such as
`kiln setup dio http_retry`. `--all` reviews the extensions already installed
in this project. It does not install the entire catalog or select competing
backends or state managers.

## Review or replace saved settings

Interactive setup follows the prompts in each `extension.yaml` and supports
text, URLs, integers, booleans, enums, and lists. Press Enter to keep a saved
value or default. Enter `!clear` to empty an optional setting or list when its
validation allows it. Type comma-separated items for lists.

To configure without prompts, use explicit answers and `--yes`:

```bash
kiln setup dio --answer base_url=https://api.example.com --yes
kiln setup dio http_retry --yes \
  --answer dio.connect_timeout=30 \
  --answer http_retry.max_attempts=5
```

Unqualified names are accepted only when they match one selected extension.
When names overlap, use `extension.name=value`. Explicit answers override
saved values. Omitted values keep saved settings or manifest defaults.

An extension without configurable prompts still reports its manual setup
steps. Its source is left in place. Unchanged settings also leave installed
files alone, including customized files.

## Preview and apply safely

```bash
kiln setup --all --dry-run --yes --json
kiln setup --all --yes
```

All selected answers are collected and validated before applying anything.
Changed extensions are rendered in a staging directory. Setup applies the
settings in `kiln.yaml`, generated source, dependencies, native patches, and
ownership hashes as one transaction. A conflict in any selected extension
prevents the entire batch from being applied.

For a changed batch, `pub get` and analysis run once by default. Verification
failure rolls back the entire batch, including settings and `pubspec.lock`.
No settings change means no regeneration or verification run. Use `--no-verify`
when you intend to check the app separately. Preview never runs verification
or writes project files. Setup does not execute extension hooks.

The installed versions must match the bundled CLI catalog. Setup preserves
versions; use `kiln upgrade` when a version change is needed. Modified managed
files block reconfiguration when their settings change. Back up your
customizations and restore the generated versions before retrying. To undo a
completed setup, use `kiln rollback` before making further edits.

## Values marked secret

Prompt fields marked `secret` are masked during interactive input, including
their saved defaults. Setup reports and doctor diagnostics omit their values.
Prefer interactive input over shell arguments for marked values, since shell
history can retain command arguments.

Masking is not encrypted storage: prompt answers are saved in `kiln.yaml` and
can be rendered into extension source, following the extension's existing
configuration model. Supply only the client-safe values described by the
extension. Server credentials belong on your backend.

## Understand the status

Doctor validates manifest prompt types, required values, allowed options, and
ranges. It also checks local relationships such as the selected fallback
locale, the Appwrite demo project ID, and the generated Firebase options file.
Errors include a command to review or replace the affected setting.

Local configuration does not prove that a service is reachable, credentials
are accepted, cloud resources exist, or a device grants permissions. Setup
prints each extension's remaining manual steps. These steps are reminders,
not confirmations that external setup has been completed. Run your app to
check runtime support and exercise the configured capability.

For Firebase, generate the options file before selecting its generated-options
mode. For Appwrite, follow the [complete setup walkthrough](setup-appwrite.md).
Extension-specific prerequisites are listed in the
[extension catalog](../extensions/catalog.md).
