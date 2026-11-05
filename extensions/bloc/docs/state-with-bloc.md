# State with Bloc

Features use `Cubit`/`Bloc` and read services from the Registry. Do not store the
Registry globally.

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

Use `BlocProvider` in the nearest widget. `SessionCubit` is already provided
globally through the application wrapper.
