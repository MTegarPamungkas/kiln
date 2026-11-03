# bloc

State management Kiln berbasis `flutter_bloc`.

Extension ini exclusive di kategori `state`, menyediakan `state_bloc`, dan
menambahkan `SessionCubit` global lewat slot `app.wrappers`. Brick juga memuat
fondasi Cubit/Bloc yang dipakai fitur:

- `BaseCubit` dengan `safeEmit` dan `runGuarded`.
- `AsyncState` dan `AsyncCubit` untuk load/refresh/retry.
- `AppBlocObserver` dengan redaksi PII.
- `SessionCubit` yang membungkus `SessionController`.
- Contoh fitur counter.

```bash
kiln add bloc
```
