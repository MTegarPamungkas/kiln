# Env files

This extension ships three example files:

- `env/development.example.json`
- `env/staging.example.json`
- `env/production.example.json`

Copy the files you need to a name without `.example`:

```bash
cp env/development.example.json env/development.json
```

The real files are ignored by `env/.gitignore`. Do not commit real environment
values.

Select a file via `--dart-define-from-file`:

```bash
flutter run --dart-define-from-file=env/development.json
```

The Flutter CLI also accepts a comma-separated list of files in recent versions.
Values in the file remain constants at build time; changing the file requires a
rebuild.
