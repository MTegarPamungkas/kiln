# Kebijakan retry

Default:

- Maksimal 3 percobaan.
- Jeda awal 250 ms, batas 8 detik, jitter aktif.
- Status yang diulang: 408, 429, 500, 502, 503, 504.
- GET, HEAD, OPTIONS, PUT, dan DELETE dianggap idempoten.
- POST/PATCH hanya diulang bila header `Idempotency-Key` ada.
- Budget default 10 retry per menit per path.

`Retry-After` mengalahkan backoff. Bila budget habis, respons/kegagalan
dikembalikan tanpa retry.

Atur lewat prompt saat `kiln add http_retry` atau edit
`lib/extensions/http_retry/retry_settings.dart`.
