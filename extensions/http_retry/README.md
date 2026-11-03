# http_retry

Middleware retry untuk `HttpPipeline`.

Extension ini membutuhkan `http_client` dan `http_pipeline` (disediakan `dio`)
dan menempel ke slot `http.interceptors` dengan priority 20.

Fitur:

- retry hanya untuk method idempoten atau request ber-`Idempotency-Key`,
- status 408, 429, 500, 502, 503, 504,
- backoff eksponensial dengan jitter,
- `Retry-After` dalam detik atau tanggal HTTP,
- retry budget per jendela waktu,
- callback event retry/give-up.

```bash
kiln add http_retry
```
