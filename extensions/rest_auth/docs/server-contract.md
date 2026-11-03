# Server contract

Parser menerima camelCase dan snake_case, serta token di level atas, di dalam
`data`, `tokens`, atau `auth`.

## Login

`POST /auth/login`

```json
{"email":"user@kiln.dev","password":"password123"}
```

Respons sukses:

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

Respons 401 dianggap kredensial salah. Status lain dipetakan oleh
`rest_auth_failure_mapper`.

## Register

`POST /auth/register` dengan `email`, `password`, dan `displayName` opsional.
Respons sama seperti login. `data.tokens` dan `data.user` juga diterima.

## Refresh

`POST /auth/refresh`

```json
{"refreshToken":"<token>"}
```

Respons minimal berisi access token baru. Bila server merotasi refresh token,
sertakan field `refreshToken`; bila tidak, refresh token lama dipertahankan.

## Logout dan me

`POST /auth/logout` memakai Bearer dan boleh mengembalikan apa saja. SignOut
tetap membersihkan token walau server gagal.

`GET /auth/me` mengembalikan objek user dengan `id`, `email`, dan nama.
