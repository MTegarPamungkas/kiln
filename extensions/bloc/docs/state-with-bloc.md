# State dengan Bloc

Fitur memakai `Cubit`/`Bloc` dan membaca layanan dari Registry. Jangan
menyimpan Registry di global.

```dart
final class ProfileCubit extends BaseCubit<AsyncState<Profile>> {
  ProfileCubit(this.registry) : super(const AsyncInitial());

  final Registry registry;

  Future<void> load() async {
    safeEmit(const AsyncLoading());
    final result = await Result.guard(
      () => registry.read<HttpClient>().get(Uri.parse('/profile')),
    );
    result.fold(
      ok: (response) => safeEmit(AsyncData(Profile.fromJson(response.data))),
      err: (failure) => safeEmit(AsyncFailure(failure)),
    );
  }
}
```

Gunakan `BlocProvider` di widget terdekat. `SessionCubit` sudah disediakan
global lewat wrapper aplikasi.
