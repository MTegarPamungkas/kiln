# kiln_testing

Fakes, contract suites, and harnesses for Kiln applications and extensions.

```dart
final registry = createTestRegistry();
final storage = InMemoryStorage();
final client = FakeHttpClient();
```

Contract suites ensure that every implementation of the same contract is
interchangeable. The harness provides `pumpApp`, `Result` matchers, async
helpers, and golden helpers.

See [docs/extensions/testing-extensions.md](../../docs/extensions/testing-extensions.md).
