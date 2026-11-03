# Slots

A slot is an attachment point between extensions without them importing each
other. The opener of a slot defines the item type and the ordering;
contributors only add items.

| Slot | Opened by | Item | Contributors |
| --- | --- | --- | --- |
| `registry` | bootstrap | `KilnModule` | all modules |
| `http.interceptors` | `dio` | `HttpMiddleware` | `connectivity`, `rest_auth`, `http_retry`, `http_cache`, `logger`, `crash_report` |
| `router.routes` | `go_router` | `AppRoute` from `app_basic` | community extensions |
| `app.wrappers` | `app_basic` | `AppWrapper` | `flavors`, `biometric` |

A lower priority runs first. Items with the same priority keep the installation
order. `OrderedSlot<T>` in `kiln_core` provides this API and tracks item owners
for `remove`.

`http.interceptors` carries `HttpMiddleware` from `kiln_core`, not dio's
`Interceptor`, so the transport stays swappable.
