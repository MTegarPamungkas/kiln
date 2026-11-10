# REST auth

This extension installs `AuthRepository` without a backend SDK. All endpoints
are filled in through the prompt and can be changed without modifying feature
code.

```dart
final auth = registry.read<AuthRepository>();

final session = await auth.signIn(
  email: 'user@kiln.dev',
  password: 'password123',
);
```

## Endpoints

The `base_url` prompt plus the login, register, refresh, logout, and me paths.
`RestAuthConfig.endpoint` joins the base URL with the path so that
`https://api.kiln.dev/v1` and `/auth/login` become
`https://api.kiln.dev/v1/auth/login`.

Two optional endpoints have no prompt:

- `forgotPasswordPath`
- `verifyEmailPath`

Set both through `RestAuthConfig` in the bootstrap code if the backend provides
password reset and email verification.

## Tokens

Tokens are stored in `SecureStorage` under keys prefixed with `rest_auth.`. The
last user is also cached so the app can be opened offline; when online,
`initialize()` reloads the profile from the me endpoint.

## HTTP

When `http_pipeline` is available, the module adds two middleware:

| Priority | Middleware | Responsibility |
| --- | --- | --- |
| 10 | `AuthMiddleware` | Adds `Authorization: Bearer` to eligible backend requests |
| 11 | `UnauthorizedHandler` | Refresh, retry once, clear the session if rejected |

Both middleware are scoped to the configured backend origin. They do not attach
the token to third-party URLs and do not react to a 401 from another origin.
The credential endpoints (`login`, `register`, `refresh`, `logout`) are excluded
from bearer injection and 401 recovery, so a refresh cannot recursively wait on
itself and a bad login cannot trigger a logout loop.

See [token-refresh.md](token-refresh.md) for details of the refresh flow.
