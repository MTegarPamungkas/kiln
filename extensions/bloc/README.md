# bloc

Kiln state management based on `flutter_bloc`.

This extension is exclusive in the `state` category, provides `state_bloc`, and
adds a global `SessionBloc` through the `app.wrappers` slot. The brick installs
the Bloc foundation together with a sample feature that follows it:

- `BaseBloc` with `runGuarded` and `reportResult`; handlers emit through their
  `Emitter`, and `Bloc.emit` itself stays test-only.
- `AsyncBloc` with the sealed `AsyncBlocEvent` (`AsyncLoad`, `AsyncRefresh`,
  `AsyncRetry`) over the `AsyncState` variants in `async_state.dart`.
- `SessionBloc` that mirrors `SessionController` into the widget tree.
- `AppBlocObserver` with PII redaction.
- `bloc_transformers.dart` — `debounceEvents`, `throttleEvents`,
  `droppableEvents`, `restartableEvents`.
- `features/notes/` — a clean-architecture sample feature: `domain/`, `data/`,
  and `presentation/`, wired together in `feature.dart`.

```bash
kiln add bloc
```

## Gate

State management has no request/response verbs. The extension wires
`BlocSupport` and the session bridge into the registry; feature code drives
blocs directly and owns the UI.

## Runtime support

This extension reports platform and device readiness through `SupportRegistry`.
Unsupported calls return typed information instead of blocking startup. See
[support and devices](../../docs/extensions/support-and-devices.md) for the
probe and possible states.
