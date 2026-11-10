# Testing applications and contracts

Kiln ships `kiln_testing` for two jobs: testing an application without a real
backend, and proving that every provider of the same contract behaves the same
way.

## Test registry

`createTestRegistry()` returns a `GetItRegistry` with a fake for every core
contract plus `Gate`, `SessionController`, `ConsentController`, `SlotRegistry`,
and `LifecycleController`.

```dart
final registry = createTestRegistry(
  storage: InMemoryStorage(),
  httpClient: FakeHttpClient(
    defaultResponse: const HttpResponse(statusCode: 200),
  ),
);
```

Overrides keep every other fake in place. A widget can read contracts through
`RegistryScope` or a `TestRegistryScope` provided by `pumpApp`.

## Fakes

| Fake | Control surface |
| --- | --- |
| `FakeHttpClient` | `onRequest`, `defaultResponse`, recorded requests |
| `InMemoryStorage` / `InMemorySecureStorage` | Map-backed reads/writes |
| `FakeAuthRepository` | Programmable session and failures |
| `FakeRemoteDatabase` | In-memory rows, queries, failures |
| `FakeFileStorage` | In-memory files, failures |
| `FakePermissions` | Per-kind status and request result |
| `FakeNotifications` | Shown/scheduled/cancelled messages and taps |
| `FakeAnalytics` | Captured events, identities, resets |
| `FakeCrashReporter` | Errors, messages, breadcrumbs, context |
| `FakeRemoteConfig` | Seed values, fail fetch, activation |
| `FakeClock` | `set`, `advance` |
| `FakeEnv` | `set` build-time values |

Fakes implement the contracts, so production code and Gate verbs run unchanged.

## Widget harness

```dart
testWidgets('renders notes', (tester) async {
  final registry = createTestRegistry(
    remoteDatabase: FakeRemoteDatabase(),
  );
  await pumpApp(tester, const NotesPage(), registry: registry);
  await pumpUntil(tester, () => find.text('Note').evaluate().isNotEmpty);
});
```

- `pumpApp` wraps the widget in `MaterialApp` and a registry scope.
- `pumpUntil` pumps frames until a condition or timeout.
- `expectEmitsInOrder` checks stream order.
- `expectGoldenWidget` wraps `matchesGoldenFile`.
- `isOk`, `isErr`, `isFailure`, and `hasCode` match `Result`/`Failure`.

## Contract suites

A provider is only interchangeable if it passes the same suite as every other
provider. Use these from an extension test or a provider test:

| Suite | Checks |
| --- | --- |
| `authRepositoryContract` | session, sign-in/up/out, invalid credentials |
| `accountManagementContract` | verification, reset, profile calls |
| `socialAuthContract` | provider sign-in and sign-out |
| `storageContract` | read/write/delete/keys/clear |
| `secureStorageContract` | secure round-trip and clear |
| `localDatabaseContract` | CRUD, query, watch |
| `remoteDatabaseContract` | CRUD, filters/order/limit, watch, missing rows |
| `paginatedRemoteDatabaseContract` | page continuations and empty pages |
| `batchRemoteDatabaseContract` | batch writes and helpers |
| `fileStorageContract` | upload/download/url/delete and progress |
| `httpClientContract` | verbs, headers, bodies, cancellation, failures |
| `connectivityContract` | status and change stream |
| `permissionsContract` | status/request/ensure/open settings |
| `notificationsContract` | permission, show/schedule/cancel, taps |
| `deepLinksContract` | initial link and stream |
| `mediaPickerContract` | camera/gallery, cancellation |
| `analyticsContract` | capture, identify, reset |
| `crashReporterContract` | errors, messages, breadcrumbs, context |
| `loggerContract` | levels, records, error/stack data |
| `remoteConfigContract` | fetch/activate, typed getters, changes |

```dart
import 'package:kiln_testing/kiln_testing.dart';
import 'package:test/test.dart';

void main() {
  remoteDatabaseContract(
    create: FakeRemoteDatabase.new,
    description: 'FakeRemoteDatabase',
  );
}
```

The suite is the executable form of
[contract behavior](../concepts/contract-behavior.md). When behavior changes,
change the page and the suite together.

## Test a provider through the real pipeline

A fake transport that bypasses middleware hides exactly the bugs that matter
(auth recursion, cache leakage, retry loops). Use a real pipeline with a fake
terminal:

```dart
final pipeline = HttpPipeline()
  ..use(AuthMiddleware(tokens, policy: policy));

final client = PipelineClient(pipeline, terminal: fakeServer);
```

The `rest_auth` extension's `rest_auth_pipeline_test.dart` is a reference:
it drives the real `AuthMiddleware`/`UnauthorizedHandler` and a fake terminal,
so an expired refresh must complete through the same pipeline.

## Extension tests

Every extension ships three levels:

- `manifest_test.dart` — schema and manifest validation.
- `render_test.dart` — golden file for rendered brick output.
- `analyze_test.dart` — `flutter analyze` on the rendered project.

Use `dart test` inside the extension folder. For the whole catalog:

```bash
dart run tool/verify_extensions.dart --test
dart run tool/verify_extensions.dart --analyze --only dio
```

See [testing extensions](../extensions/testing-extensions.md) for the extension
authoring workflow.

## Commands

```bash
# application
flutter test

# core packages
cd packages/kiln_core && dart test
cd packages/kiln_extension_sdk && dart test
cd packages/kiln_store && dart test
cd packages/kiln_cli && dart test
cd packages/kiln_testing && flutter test

# every extension manifest/render/analyze test
for extension in extensions/*; do (cd "$extension" && dart test); done
```
