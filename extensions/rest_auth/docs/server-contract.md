# Server contract

The parser accepts camelCase and snake_case, as well as tokens at the top level,
inside `data`, `tokens`, or `auth`.

## Login

`POST /auth/login`

```json
{"email":"user@kiln.dev","password":"password123"}
```

Successful response:

```json
{
  "access_token": "<jwt>",
  "refresh_token": "<opaque>",
  "expires_in": 3600,
  "user": {
    "id": "user-1",
    "email": "user@kiln.dev",
    "display_name": "Tegar",
    "email_verified": true
  }
}
```

A 401 response is treated as invalid credentials. Other statuses are mapped by
`rest_auth_failure_mapper`.

## Register

`POST /auth/register` with `email`, `password`, and an optional `displayName`.
The response is the same as login. `data.tokens` and `data.user` are also
accepted.

## Refresh

`POST /auth/refresh`

```json
{"refreshToken":"<token>"}
```

The response contains at least the new access token. If the server rotates the
refresh token, include the `refreshToken` field; if not, the old refresh token is
kept.

## Logout and me

`POST /auth/logout` uses Bearer and may return anything. SignOut still clears the
tokens even if the server fails.

`GET /auth/me` returns the user object with `id`, `email`, and name.
