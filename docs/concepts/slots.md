# Slot

Slot adalah titik sambung antar extension tanpa saling mengimpor. Pembuka slot
menentukan tipe item dan urutan; penempel hanya menyumbang item.

| Slot | Dibuka oleh | Item | Penempel |
| --- | --- | --- | --- |
| `registry` | bootstrap | `KilnModule` | semua module |
| `http.interceptors` | `dio` | `HttpMiddleware` | `connectivity`, `rest_auth`, `http_retry`, `http_cache`, `logger`, `crash_report` |
| `router.routes` | `go_router` | `AppRoute` dari `app_basic` | extension komunitas |
| `app.wrappers` | `app_basic` | `AppWrapper` | `flavors`, `biometric` |

Prioritas kecil berjalan lebih dulu. Item dengan prioritas sama mempertahankan
urutan pemasangan. `OrderedSlot<T>` di `kiln_core` menyediakan API ini dan
menyimpan pemilik item untuk `remove`.

`http.interceptors` membawa `HttpMiddleware` dari `kiln_core`, bukan
`Interceptor` dio, supaya transport tetap bisa diganti.
