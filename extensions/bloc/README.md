# bloc

Kiln state management based on `flutter_bloc`.

This extension is exclusive in the `state` category, provides `state_bloc`, and
adds a global `SessionCubit` through the `app.wrappers` slot. The brick also includes
the Cubit/Bloc foundation used by features:

- `BaseCubit` with `safeEmit` and `runGuarded`.
- `AsyncState` and `AsyncCubit` for load/refresh/retry.
- `AppBlocObserver` with PII redaction.
- `SessionCubit` that wraps `SessionController`.
- counter feature example.

```bash
kiln add bloc
```
