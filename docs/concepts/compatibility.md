# Compatibility

An extension manifest can constrain:

```yaml
compatibility:
  kiln: ">=0.1.0 <0.2.0"
  dart: ">=3.9.0"
  flutter: ">=3.35.0"
```

`kiln doctor` checks these ranges against the running CLI and Dart versions. The
resolver can also reject unsupported platforms through `platforms`.

Version rules:

- Extensions use semver.
- The lockfile records the exact version installed.
- Multi-version upgrade and the migration runner wait on the registry catalog.
- An extension's dependency constraints are written in `dependencies` and added
  to the user project's `pubspec.yaml`.
