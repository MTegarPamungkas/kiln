# rest_auth

`AuthRepository` on top of `HttpClient` and `SecureStorage`.

- `RestAuth` sends the email and password to the login/register endpoint,
  stores the token, then emits `AuthSession`.
- `TokenRefresher` performs a single-flight refresh: parallel requests share a
  single refresh result.
- `JwtExpiry` reads `exp` without verification in order to refresh before the
  token dies.
- `AuthMiddleware` adds the Bearer header (priority 10);
  `UnauthorizedHandler` refreshes once, retries one request, then signs out.
- `RestAccountManagement` uses the optional password reset and email
  verification endpoints.
- `RestSessionBridge` populates `SessionController` for navigation guards.

The server JSON shape is in [docs/server-contract.md](docs/server-contract.md),
the refresh flow is in [docs/token-refresh.md](docs/token-refresh.md).
