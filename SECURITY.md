# Security

## Reporting vulnerabilities

Do not open a public issue for a vulnerability. Contact the repository
maintainers privately and include:

- the Kiln and extension versions,
- reproduction steps,
- impact and attack surface,
- a suggested fix, if you have one.

## Trust model

- `official`/`verified` extensions may use hooks; the community tier requires
  explicit approval.
- `kiln_store` verifies the archive SHA-256 and rejects path traversal.
- `kiln add` runs inside a transaction with a snapshot and rollback.
- Files edited by the user are never deleted automatically.

## Secrets

- `secret` prompts are never written to `kiln.yaml`.
- Never store server keys in a client app. `--dart-define` values can be
  extracted from the binary.
- Loggers, analytics, and crash reporters use `PiiRedactor` and
  `ConsentController`.

## Dependencies

Follow `flutter pub outdated` and review Dependabot. Do not add a new
dependency without a clear need.
