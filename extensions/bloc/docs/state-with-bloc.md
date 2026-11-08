# State with Bloc

A feature is `domain/` + `data/` + `presentation/`. The bloc lives in
`presentation/` and talks only to use cases; the Registry is read in the
feature's `feature.dart`, never inside a bloc. Do not store the Registry
globally.

```dart
final class ProfileBloc extends BaseBloc<ProfileEvent, AsyncState<Profile>> {
  ProfileBloc({required this.loadProfile, required this.saveProfile})
    : super(const AsyncInitial()) {
    on<ProfileLoadRequested>(_onLoad);
    on<ProfileSaved>(_onSave);
  }

  final Future<Profile> Function() loadProfile;
  final UseCase<Profile, void> saveProfile;

  Future<void> _onLoad(
    ProfileLoadRequested event,
    Emitter<AsyncState<Profile>> emit,
  ) async {
    emit(const AsyncLoading());
    final result = await runGuarded(loadProfile);
    result.fold(
      ok: (profile) => emit(AsyncData(profile)),
      err: (failure) => emit(AsyncFailure(failure)),
    );
  }

  // `Bloc.emit` is test-only, so state leaves a handler through its Emitter.
  Future<void> _onSave(
    ProfileSaved event,
    Emitter<AsyncState<Profile>> emit,
  ) async {
    reportResult(
      await saveProfile(event.profile),
      emit,
      AsyncFailure<Profile>.new,
    );
  }
}
```

`runGuarded` turns a thrown value into an `Err`. A use case already returns a
`Result`, so it goes straight to `reportResult`, which emits only on failure:
when the domain also streams, the watched value has already replaced the state.

For a single value that is only fetched, use `AsyncBloc<T>` with its
`AsyncLoad`, `AsyncRefresh`, and `AsyncRetry` events instead of writing a bloc.
The states are `AsyncInitial`, `AsyncLoading`, `AsyncData`, and `AsyncFailure`.

Use `BlocProvider` in the screen that needs the bloc. `SessionBloc` is already
provided globally through the application wrapper.
