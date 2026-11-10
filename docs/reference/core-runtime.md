# Core runtime

`kiln_core` is the only package an application and every extension may import.
It contains the contracts, the error model, the registry, module bootstrap,
lifecycle, support reporting, slots, session state, consent, privacy utilities,
and small platform-neutral helpers.

It does not depend on Flutter plugins. UI belongs to the application; extensions
only provide contracts and wiring.

## Bootstrap

```dart
final registry = await KilnBootstrap.run(
  modules: <KilnModule>[const AppRoutesModule(), ...kilnModules()],
);
```

`KilnBootstrap.run` performs the following sequence:

1. Creates a private `GetItRegistry`, `SlotRegistry`, `SessionController`,
   `ConsentController`, `LifecycleController`, `SupportRegistry`, and `Clock`.
2. Registers those core services in the registry.
3. Records `unsupportedPlatform` for modules whose `platforms` do not match the
   current platform, then removes them from the graph.
4. Resolves `requires`/`optionalRequires` capabilities with `ModuleGraph`.
5. For each module in dependency order: `register`, `support`, then `ready`
   when the support probe says supported.
6. Calls `lifecycle.onReady()`.
7. On failure, disposes everything already registered in reverse order and
   rethrows the original error.

Options:

| Option | Default | Purpose |
| --- | --- | --- |
| `modules` | required | Modules to boot |
| `timeout` | 30s | Maximum time for one `ready()` |
| `supportTimeout` | 5s | Maximum time for one `support()` probe |
| `clock` | `SystemClock()` | Injectable time source |
| `onError` | null | Called before bootstrap rethrows |
| `onModuleReady` | null | Observability hook after each module |
| `capabilities` | `{}` | Host capabilities satisfied outside the module list |
| `platform` | current platform | Override for tests or server generation |

A support probe never blocks startup. Timeouts and probe errors become
`SupportState.unavailable`; `ready()` is skipped for that module.

## Registry

```dart
final storage = registry.read<Storage>();
final cache = registry.readOrNull<HttpCache>();
final isPresent = registry.isRegistered<AuthRepository>();
```

| Member | Behavior |
| --- | --- |
| `read<T>()` | Returns the registered service or throws if missing |
| `readOrNull<T>()` | Returns `null` when missing |
| `isRegistered<T>()` | Probe without resolving a lazy singleton |
| `registerSingleton<T>(value)` | One instance for the container lifetime |
| `registerLazySingleton<T>(factory)` | Creates on first read |
| `registerFactory<T>(factory)` | Creates a new instance per read |
| `unregister<T>()` | Removes the registration |
| `isReady` | Always true for the container implementation |

A missing registration is a programming error. Application features should use
`Gate.has<T>()` or `readOrNull<T>()` when a capability is optional. A service
lookup performed outside `Gate.call` can throw; the Gate wraps it.

`GetItRegistry` accepts an optional `GetIt` container, which tests can preload.

## Modules

```dart
final class AnalyticsModule extends KilnModule {
  const AnalyticsModule();

  @override
  String get id => 'analytics';

  @override
  Set<String> get provides => const <String>{'analytics'};

  @override
  Set<String> get requires => const <String>{};

  @override
  Set<String> get optionalRequires => const <String>{'flavor'};

  @override
  void register(Registry registry) {
    registry.registerSingleton<Analytics>(...);
  }

  @override
  FutureOr<SupportInfo> support(Registry registry) {
    return const SupportInfo.supported();
  }

  @override
  FutureOr<void> ready(Registry registry) {}
}
```

| Member | Meaning |
| --- | --- |
| `id` | Stable module id, also used in `SupportRegistry` |
| `provides` | Capability names this module satisfies |
| `requires` | Capabilities that must be present |
| `optionalRequires` | Capabilities used for ordering when present |
| `platforms` | Platforms this module can register on; empty means all |
| `register` | Registers contracts and wiring |
| `support` | Cheap readiness probe; must not prompt |
| `ready` | Async initialization after a supported probe |
| `dispose` | Releases owned resources on shutdown |

`ModuleGraph` rejects duplicate ids, two providers for one capability, missing
required capabilities, and cycles. It produces a deterministic dependency order.

## Lifecycle

`LifecycleController` tracks `created`, `ready`, `paused`, `resumed`, and
`disposed`. It forwards Flutter app lifecycle events to attached listeners and
owns module shutdown.

```dart
final lifecycle = registry.read<LifecycleController>();
await lifecycle.onPause();
await lifecycle.onResume();
await lifecycle.dispose();
```

- `attach(listener)` / `detach(listener)` manage `Lifecycle` listeners.
- `addDisposeCallback(callback)` registers module or core cleanup.
- `dispose()` is idempotent, runs listeners and callbacks in reverse order, and
  keeps going when one cleanup fails. The first error is rethrown after closing.
- `KilnApp` in the app template calls `lifecycle.dispose()` when the root widget
  is disposed.

## Support

`SupportInfo` is the runtime answer to "can this extension be used here?".

```dart
final support = registry.read<SupportRegistry>();
final biometric = support['biometric'];
if (biometric?.isSupported ?? false) {
  // render the biometric action
}
```

`SupportState` values: `supported`, `unsupportedPlatform`, `unsupportedDevice`,
`permissionDenied`, `notConfigured`, `unavailable`.

`SupportInfo.toFailure()` maps the state to a stable failure code. A module that
is unsupported at runtime should still register its contracts, then throw the
typed failure from calls. A module filtered out by platform is not registered at
all. See [support and devices](../extensions/support-and-devices.md).

## Slots

An `OrderedSlot<T>` is a deterministic contribution list. Lower priority runs
first; equal priorities keep insertion order; each item can carry an owner.

```dart
final routes = slots.open<AppRoute>(SlotNames.routerRoutes);
routes.add(myRoute, priority: 10, owner: 'my_feature');
routes.removeOwner('my_feature');
```

`SlotRegistry` opens and finds slots. Well-known names include
`SlotNames.httpInterceptors`, `SlotNames.routerRoutes`, and
`SlotNames.appWrappers`. Extensions communicate through slots and capabilities,
never by importing each other.

## Session and consent

```dart
final session = registry.read<SessionController>();
session.setSession(AuthSession(userId: 'u1'));
session.markUnauthenticated();

final consent = registry.read<ConsentController>();
consent.grant(ConsentCategory.analytics);
```

`SessionController` exposes `status`, `session`, `changes`, and
`sessionChanges`. `ConsentController` stores independent analytics and crash
report consent decisions. Nothing should be sent to analytics or crash reporting
before the matching consent is granted.

`PiiRedactor` masks emails, phone numbers, tokens, and other configured keys
before data reaches logs, analytics, or crash reports.

## Errors and results

Contracts throw `Failure`; `Result<T>` and `Gate` convert it to `Ok`/`Err`.

```dart
final result = Result.guard(() => client.get(uri));
final status = result.fold(
  ok: (response) => response.statusCode,
  err: (failure) => failure.kind.name,
);
```

See [Failure codes](failure-codes.md) for the full list and
[Gate](gate.md) for every typed verb.

## Utilities

| Type | Purpose |
| --- | --- |
| `Clock` / `SystemClock` / `FixedClock` | Injectable time source for tests |
| `Debouncer` | Runs the last action after calls stop |
| `RateLimiter` | Limits actions per window |
| `Disposable` | Named resource-release contract |
| `AppFlavor` | Value type for development, staging, production, or custom flavors |

Prefer injecting `Clock` from the registry instead of calling `DateTime.now()`
in testable code.
